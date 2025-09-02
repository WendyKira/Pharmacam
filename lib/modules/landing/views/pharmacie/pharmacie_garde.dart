import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../utilitaires/apps_colors.dart';

/// ---------------------------------------------------------------------------
/// GardePage
/// - Marquer "je suis de garde" (début/fin + note)
/// - Voir les autres pharmacies en garde
/// Firestore:
///   - users/{uid} : onDuty(bool), dutyStart(Timestamp), dutyEnd(Timestamp)
///   - gardes/{uid} : { uid, nom, ville, adresse, telephone, startAt, endAt, isActive, createdAt, updatedAt }
/// ---------------------------------------------------------------------------

class GardePage extends StatefulWidget {
  const GardePage({super.key});

  @override
  State<GardePage> createState() => _GardePageState();
}

enum DutyFilter { all, now, upcoming }

class _GardePageState extends State<GardePage> {
  final TextEditingController _searchCtrl = TextEditingController();
  DutyFilter _filter = DutyFilter.now; // par défaut: en ce moment
  bool _onlyMyCity = true;

  User? _user;
  DocumentReference<Map<String, dynamic>>? _userDoc;
  CollectionReference<Map<String, dynamic>>? _gardesCol;

  Map<String, dynamic>? _me; // données du user (nom, ville, adresse, telephone…)
  bool _loadingMe = true;
  bool _iAmOnDuty = false;
  Timestamp? _myDutyStart;
  Timestamp? _myDutyEnd;

  final Set<String> _busyIds = {}; // pour actions dans la liste

  @override
  void initState() {
    super.initState();
    _initPaths();
    _searchCtrl.addListener(() => setState(() {}));
  }

  Future<void> _initPaths() async {
    final u = FirebaseAuth.instance.currentUser;
    _user = u;
    if (u == null) {
      setState(() {
        _loadingMe = false;
      });
      return;
    }
    _userDoc = FirebaseFirestore.instance.collection('users').doc(u.uid);
    _gardesCol = FirebaseFirestore.instance.collection('gardes');

    // charge profil
    final snap = await _userDoc!.get();
    _me = snap.data() ?? {};
    _iAmOnDuty = (_me?['onDuty'] == true);

// Récupère proprement les Timestamps
    final ds = _me?['dutyStart'];
    final de = _me?['dutyEnd'];

    _myDutyStart = ds is Timestamp ? ds : null;
    _myDutyEnd   = de is Timestamp ? de : null;



    setState(() => _loadingMe = false);
  }

  // ------------------------------- UI helpers -------------------------------
  String _fmt(Timestamp? ts) {
    if (ts == null) return '--';
    final d = ts.toDate();
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    final yy = d.year.toString();
    final hh = d.hour.toString().padLeft(2, '0');
    final mi = d.minute.toString().padLeft(2, '0');
    return '$dd/$mm/$yy $hh:$mi';
  }

  // ------------------------------ Declare/Stop ------------------------------
  Future<void> _openDeclareSheet() async {
    if (_userDoc == null || _gardesCol == null) return;

    DateTime start = DateTime.now();
    DateTime end = start.add(const Duration(hours: 12));
    final notesCtrl = TextEditingController();

    bool saving = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) {
        final bottom = MediaQuery.of(context).viewInsets.bottom;

        Future<void> pickStart() async {
          final d = await showDatePicker(
            context: context,
            initialDate: start,
            firstDate: DateTime.now().subtract(const Duration(days: 1)),
            lastDate: DateTime.now().add(const Duration(days: 30)),
          );
          if (d == null) return;
          final t = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(start));
          if (t == null) return;
          setState(() => start = DateTime(d.year, d.month, d.day, t.hour, t.minute));
        }

        Future<void> pickEnd() async {
          final d = await showDatePicker(
            context: context,
            initialDate: end,
            firstDate: DateTime.now().subtract(const Duration(days: 1)),
            lastDate: DateTime.now().add(const Duration(days: 45)),
          );
          if (d == null) return;
          final t = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(end));
          if (t == null) return;
          setState(() => end = DateTime(d.year, d.month, d.day, t.hour, t.minute));
        }

        Future<void> save() async {
          if (end.isBefore(start)) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                backgroundColor: Colors.red.shade700,
                behavior: SnackBarBehavior.floating,
                content: const Text('La date de fin doit être après la date de début.'),
              ),
            );
            return;
          }
          setState(() => saving = true);
          try {
            final nowTs = FieldValue.serverTimestamp();
            // 1) Mettre à jour le user
            await _userDoc!.update({
              'onDuty': true,
              'dutyStart': Timestamp.fromDate(start),
              'dutyEnd': Timestamp.fromDate(end),
              'dutyUpdatedAt': nowTs,
              'dutyNotes': notesCtrl.text.trim(),
            });

            // 2) Upsert dans gardes/{uid}
            final me = _me ?? {};
            await _gardesCol!.doc(_user!.uid).set({
              'uid': _user!.uid,
              'nom': me['nom'] ?? me['name'] ?? 'Pharmacie',
              'ville': me['ville'] ?? me['city'] ?? '',
              'adresse': me['adresse'] ?? me['address'] ?? '',
              'telephone': me['telephone'] ?? me['phone'] ?? '',
              'startAt': Timestamp.fromDate(start),
              'endAt': Timestamp.fromDate(end),
              'isActive': true,
              'notes': notesCtrl.text.trim(),
              'createdAt': nowTs,
              'updatedAt': nowTs,
            }, SetOptions(merge: true));

            // refresh dans l'écran
            _iAmOnDuty = true;
            _myDutyStart = Timestamp.fromDate(start);
            _myDutyEnd = Timestamp.fromDate(end);

            if (!mounted) return;
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                backgroundColor: Colors.black87,
                behavior: SnackBarBehavior.floating,
                content: Text('Garde déclarée'),
              ),
            );
            setState(() {});
          } catch (e) {
            setState(() => saving = false);
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                backgroundColor: Colors.red.shade700,
                behavior: SnackBarBehavior.floating,
                content: Text('Erreur: $e'),
              ),
            );
          }
        }

        InputDecoration _dec(String hint) => InputDecoration(
          hintText: hint,
          filled: true,
          fillColor: Colors.grey.shade50,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppColors.primary),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        );

        TextStyle _label = const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Colors.black87);

        return Padding(
          padding: EdgeInsets.only(bottom: bottom),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 46, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(100))),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                      child: Icon(Icons.local_hospital_rounded, color: AppColors.primary, size: 20),
                    ),
                    const SizedBox(width: 12),
                    const Text('Déclarer une garde', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.black87)),
                  ],
                ),
                const SizedBox(height: 16),

                Align(alignment: Alignment.centerLeft, child: Text('Début', style: _label)),
                const SizedBox(height: 6),
                InkWell(
                  onTap: pickStart,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    height: 48,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.centerLeft,
                    child: Row(
                      children: [
                        Icon(Icons.schedule_rounded, color: Colors.grey.shade600, size: 18),
                        const SizedBox(width: 8),
                        Text(_fmt(Timestamp.fromDate(start)), style: const TextStyle(fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                Align(alignment: Alignment.centerLeft, child: Text('Fin', style: _label)),
                const SizedBox(height: 6),
                InkWell(
                  onTap: pickEnd,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    height: 48,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.centerLeft,
                    child: Row(
                      children: [
                        Icon(Icons.event_rounded, color: Colors.grey.shade600, size: 18),
                        const SizedBox(width: 8),
                        Text(_fmt(Timestamp.fromDate(end)), style: const TextStyle(fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                Align(alignment: Alignment.centerLeft, child: Text('Note (optionnel)', style: _label)),
                const SizedBox(height: 6),
                TextField(
                  controller: notesCtrl,
                  decoration: _dec('Ex: Garde de nuit, joindre le numéro d’urgence…'),
                  maxLines: 2,
                ),

                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: saving ? null : () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: BorderSide(color: Colors.grey.shade300),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Annuler'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: saving ? null : save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: saving
                            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Text('Enregistrer', style: TextStyle(fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _stopDuty() async {
    if (_userDoc == null || _gardesCol == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(10)),
              child: Icon(Icons.highlight_off_rounded, color: Colors.red.shade600, size: 20),
            ),
            const SizedBox(width: 12),
            const Text('Arrêter la garde'),
          ],
        ),
        content: const Text('Confirmer la fin de votre garde maintenant ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Annuler', style: TextStyle(color: Colors.grey.shade700)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600, foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Arrêter'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      await _userDoc!.update({
        'onDuty': false,
        'dutyEnd': FieldValue.serverTimestamp(),
        'dutyUpdatedAt': FieldValue.serverTimestamp(),
      });
      // supprimer doc global
      await _gardesCol!.doc(_user!.uid).delete();

      _iAmOnDuty = false;
      _myDutyEnd = Timestamp.now();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.black87,
          behavior: SnackBarBehavior.floating,
          content: Text('Garde arrêtée'),
        ),
      );
      setState(() {});
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          content: Text('Erreur: $e'),
        ),
      );
    }
  }

  // ------------------------------- LISTE AUTRES ------------------------------
  Query<Map<String, dynamic>> _baseOthersQuery() {
    // Pharmacies dont la garde n'est pas terminée
    Query<Map<String, dynamic>> q = _gardesCol!;
    q = q.where('endAt', isGreaterThan: Timestamp.now());
    if (_onlyMyCity && (_me?['ville'] != null && _me!['ville'].toString().isNotEmpty)) {
      q = q.where('ville', isEqualTo: _me!['ville'].toString());
    }
    q = q.orderBy('endAt'); // les plus proches de la fin en premier
    return q;
  }

  bool _matchFilterClientSide(Map<String, dynamic> data) {
    // On complète côté client pour "En ce moment" vs "À venir"
    final now = DateTime.now();
    final start = (data['startAt'] is Timestamp) ? (data['startAt'] as Timestamp).toDate() : null;
    final end = (data['endAt'] is Timestamp) ? (data['endAt'] as Timestamp).toDate() : null;

    bool pass = true;
    if (_filter == DutyFilter.now) {
      pass = (start == null || start.isBefore(now) || start.isAtSameMomentAs(now));
    } else if (_filter == DutyFilter.upcoming) {
      pass = (start != null && start.isAfter(now));
    }
    // Recherche
    final term = _searchCtrl.text.trim().toLowerCase();
    if (term.isNotEmpty) {
      final nom = (data['nom'] ?? '').toString().toLowerCase();
      final ville = (data['ville'] ?? '').toString().toLowerCase();
      final adr = (data['adresse'] ?? '').toString().toLowerCase();
      pass = pass && (nom.contains(term) || ville.contains(term) || adr.contains(term));
    }
    return pass;
  }

  // --------------------------------- BUILD ----------------------------------
  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_user == null) {
      return _shell(
        Center(
          child: Text('Veuillez vous connecter pour gérer la garde.',
              style: TextStyle(color: Colors.grey.shade700)),
        ),
      );
    }
    if (_loadingMe) {
      return _shell(const Center(child: CircularProgressIndicator()));
    }

    return _shell(
      Column(
        children: [
          // Bandeau "ma garde"
          _myDutyCard(),

          const SizedBox(height: 16),

          // Liste des autres en garde (stream)
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _baseOthersQuery().snapshots(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snap.hasError) {
                  return Center(
                    child: Text('Erreur: ${snap.error}',
                        style: TextStyle(color: Colors.red.shade700)),
                  );
                }

                final docs = (snap.data?.docs ?? [])
                    .where((d) => d.id != _user!.uid) // exclure moi
                    .where((d) => _matchFilterClientSide(d.data()))
                    .toList();

                if (docs.isEmpty) {
                  return Center(
                    child: Text(
                      _searchCtrl.text.isEmpty
                          ? 'Personne en garde pour ce filtre.'
                          : 'Aucune garde ne correspond à "${_searchCtrl.text}".',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.only(top: 12),
                  itemBuilder: (_, i) => _gardeCard(docs[i]),
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemCount: docs.length,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------- SHELL (header + filtres) -----------------
  Widget _shell(Widget body) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Bandeau top
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2)),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.local_hospital_rounded, color: AppColors.primary, size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Garde',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.black87),
                  ),
                  const Spacer(),
                  // Toggle action rapide
                  if (_iAmOnDuty)
                    ElevatedButton.icon(
                      onPressed: _stopDuty,
                      icon: const Icon(Icons.stop_circle_rounded, size: 18),
                      label: const Text('Arrêter'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade600,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                    )
                  else
                    ElevatedButton.icon(
                      onPressed: _openDeclareSheet,
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const Text('Déclarer une garde'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),

              // Recherche + filtres
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: TextField(
                        controller: _searchCtrl,
                        decoration: InputDecoration(
                          hintText: 'Rechercher (nom, ville, adresse)…',
                          hintStyle: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.w400),
                          prefixIcon: Icon(Icons.search_rounded, color: Colors.grey.shade400, size: 20),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Filtres
              Align(
                alignment: Alignment.centerLeft,
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _filterChip('En ce moment', DutyFilter.now),
                    _filterChip('À venir', DutyFilter.upcoming),
                    _filterChip('Toutes', DutyFilter.all),
                    _toggleCityChip(),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Corps
        Expanded(child: body),
      ],
    );
  }

  Widget _filterChip(String label, DutyFilter v) {
    final selected = _filter == v;
    return InkWell(
      borderRadius: BorderRadius.circular(100),
      onTap: () => setState(() => _filter = v),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.primary.withOpacity(0.08),
          borderRadius: BorderRadius.circular(100),
          boxShadow: selected
              ? [BoxShadow(color: AppColors.primary.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 2))]
              : null,
        ),
        child: Text(label, style: TextStyle(color: selected ? Colors.white : AppColors.primary, fontWeight: FontWeight.w600, fontSize: 12)),
      ),
    );
  }

  Widget _toggleCityChip() {
    return InkWell(
      borderRadius: BorderRadius.circular(100),
      onTap: () => setState(() => _onlyMyCity = !_onlyMyCity),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: _onlyMyCity ? AppColors.primary : AppColors.primary.withOpacity(0.08),
          borderRadius: BorderRadius.circular(100),
          boxShadow: _onlyMyCity ? [BoxShadow(color: AppColors.primary.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 2))] : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.location_city_rounded, size: 14, color: _onlyMyCity ? Colors.white : AppColors.primary),
            const SizedBox(width: 6),
            Text(
              _onlyMyCity ? 'Ma ville uniquement' : 'Toutes les villes',
              style: TextStyle(color: _onlyMyCity ? Colors.white : AppColors.primary, fontWeight: FontWeight.w600, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  // ------------------------------- MES INFOS DE GARDE -----------------------
  Widget _myDutyCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: _iAmOnDuty ? AppColors.primary.withOpacity(0.15) : Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),
            child: Icon(_iAmOnDuty ? Icons.check_circle_rounded : Icons.info_rounded,
                color: _iAmOnDuty ? AppColors.primary : Colors.grey.shade600, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_iAmOnDuty ? 'Vous êtes de garde' : 'Vous n’êtes pas de garde',
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Colors.black87)),
                const SizedBox(height: 6),
                if (_iAmOnDuty)
                  Text('Du ${_fmt(_myDutyStart)} au ${_fmt(_myDutyEnd)}', style: TextStyle(color: Colors.grey.shade700))
                else
                  Text('Cliquez sur “Déclarer une garde” pour vous signaler.',
                      style: TextStyle(color: Colors.grey.shade700)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          if (_iAmOnDuty)
            OutlinedButton.icon(
              onPressed: _stopDuty,
              icon: const Icon(Icons.stop_circle_rounded, size: 16),
              label: const Text('Arrêter'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                side: BorderSide(color: Colors.red.shade300),
                foregroundColor: Colors.red.shade700,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            )
          else
            ElevatedButton.icon(
              onPressed: _openDeclareSheet,
              icon: const Icon(Icons.add_rounded, size: 16),
              label: const Text('Déclarer'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary, foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
            ),
        ],
      ),
    );
  }

  // ------------------------------- CARTE AUTRE GARDE ------------------------
  Widget _gardeCard(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data();

    final nom = (d['nom'] ?? 'Pharmacie').toString();
    final ville = (d['ville'] ?? '').toString();
    final adresse = (d['adresse'] ?? '').toString();
    final tel = (d['telephone'] ?? '').toString();
    final start = d['startAt'] is Timestamp ? d['startAt'] as Timestamp : null;
    final end = d['endAt'] is Timestamp ? d['endAt'] as Timestamp : null;
    final note = (d['notes'] ?? '').toString();

    // État "à venir" vs "en ce moment"
    final now = DateTime.now();
    final isUpcoming = (start != null && start.toDate().isAfter(now));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(isUpcoming ? Icons.schedule_rounded : Icons.nightlight_round,
                color: AppColors.primary, size: 22),
          ),
          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Nom + ville
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        nom,
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Colors.black87),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: isUpcoming ? Colors.orange.withOpacity(0.12) : AppColors.primary.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Text(
                        isUpcoming ? 'À venir' : 'En garde',
                        style: TextStyle(
                          color: isUpcoming ? Colors.orange.shade800 : AppColors.primary,
                          fontWeight: FontWeight.w700, fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  children: [
                    _miniInfo(Icons.location_on_rounded, [ville, adresse].where((e) => e.isNotEmpty).join(' • ')),
                    if (tel.isNotEmpty) _miniInfo(Icons.phone_rounded, tel),
                  ],
                ),
                const SizedBox(height: 8),
                Text('Du ${_fmt(start)} au ${_fmt(end)}', style: TextStyle(color: Colors.grey.shade700)),
                if (note.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(note, style: TextStyle(color: Colors.grey.shade600)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniInfo(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.06),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.primary),
          const SizedBox(width: 6),
          Text(text, style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.w600, fontSize: 12)),
        ],
      ),
    );
  }
}
