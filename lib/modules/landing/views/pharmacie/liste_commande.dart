import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../utilitaires/apps_colors.dart';

/// ---------------------------------------------------------------------------
/// GestionCommandesPage
/// Chemin Firestore : users/{uid}/commandes
/// Champs attendus (recommandés):
///   - code: String (ex: CMD-20250902-0001)
///   - clientName: String
///   - clientPhone: String
///   - address: String
///   - items: List<Map>{ productId, name, qty(num), price(num), total(num) }
///   - total: num
///   - paymentMethod: String (ex: Cash, Mobile Money)
///   - status: String ∈ { En attente, Validée, Préparée, Expédiée, Livrée, Annulée }
///   - notes: String
///   - createdAt: Timestamp
///   - validatedAt / updatedAt: Timestamp (optionnel)
/// ---------------------------------------------------------------------------

class GestionCommandesPage extends StatefulWidget {
  const GestionCommandesPage({super.key});

  @override
  State<GestionCommandesPage> createState() => _GestionCommandesPageState();
}

enum OrderFilter {
  all,
  pending,   // En attente
  validated, // Validée
  prepared,  // Préparée
  shipped,   // Expédiée
  delivered, // Livrée
  canceled,  // Annulée
}

const List<String> kOrderStatuses = [
  'En attente',
  'Validée',
  'Préparée',
  'Expédiée',
  'Livrée',
  'Annulée',
];

class _GestionCommandesPageState extends State<GestionCommandesPage> {
  final TextEditingController _searchCtrl = TextEditingController();
  OrderFilter _filter = OrderFilter.all;

  final Set<String> _busy = {}; // ids en cours d'action (validate/delete/update)
  User? _user;
  CollectionReference<Map<String, dynamic>>? _ordersCol;

  @override
  void initState() {
    super.initState();
    _initUserAndPath();
    _searchCtrl.addListener(() => setState(() {}));
  }

  Future<void> _initUserAndPath() async {
    final u = FirebaseAuth.instance.currentUser;
    setState(() {
      _user = u;
      if (u != null) {
        _ordersCol = FirebaseFirestore.instance
            .collection('users')
            .doc(u.uid)
            .collection('commandes');
      }
    });
  }

  Query<Map<String, dynamic>>? _baseQuery() {
    if (_ordersCol == null) return null;
    Query<Map<String, dynamic>> q = _ordersCol!;
    switch (_filter) {
      case OrderFilter.pending:
        q = q.where('status', isEqualTo: 'En attente');
        break;
      case OrderFilter.validated:
        q = q.where('status', isEqualTo: 'Validée');
        break;
      case OrderFilter.prepared:
        q = q.where('status', isEqualTo: 'Préparée');
        break;
      case OrderFilter.shipped:
        q = q.where('status', isEqualTo: 'Expédiée');
        break;
      case OrderFilter.delivered:
        q = q.where('status', isEqualTo: 'Livrée');
        break;
      case OrderFilter.canceled:
        q = q.where('status', isEqualTo: 'Annulée');
        break;
      case OrderFilter.all:
        break;
    }
    q = q.orderBy('createdAt', descending: true);
    return q;
  }

  bool _matchesSearch(Map<String, dynamic> data) {
    final term = _searchCtrl.text.trim().toLowerCase();
    if (term.isEmpty) return true;
    final code = (data['code'] ?? '').toString().toLowerCase();
    final client = (data['clientName'] ?? '').toString().toLowerCase();
    final phone = (data['clientPhone'] ?? '').toString().toLowerCase();
    return code.contains(term) || client.contains(term) || phone.contains(term);
  }

  Future<void> _updateStatus(String id, String newStatus) async {
    if (_ordersCol == null) return;
    setState(() => _busy.add(id));
    try {
      await _ordersCol!.doc(id).update({
        'status': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
        if (newStatus == 'Validée') 'validatedAt': FieldValue.serverTimestamp(),
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.black87,
          behavior: SnackBarBehavior.floating,
          content: Text('Statut mis à jour: $newStatus'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          content: Text('Erreur: $e'),
        ),
      );
    } finally {
      if (mounted) setState(() => _busy.remove(id));
    }
  }

  Future<void> _validateOrder(String id, String currentStatus) async {
    if (currentStatus == 'Validée') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.black87,
          behavior: SnackBarBehavior.floating,
          content: Text('Commande déjà validée.'),
        ),
      );
      return;
    }
    await _updateStatus(id, 'Validée');
  }

  Future<void> _deleteOrder(String id) async {
    if (_ordersCol == null) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.delete_rounded, color: Colors.red.shade600, size: 20),
            ),
            const SizedBox(width: 12),
            const Text('Supprimer la commande'),
          ],
        ),
        content: const Text('Cette action est définitive. Confirmer la suppression ?'),
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
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    setState(() => _busy.add(id));
    try {
      await _ordersCol!.doc(id).delete();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.black87,
          behavior: SnackBarBehavior.floating,
          content: Text('Commande supprimée'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          content: Text('Erreur: $e'),
        ),
      );
    } finally {
      if (mounted) setState(() => _busy.remove(id));
    }
  }

  Future<void> _openOrderDetails(QueryDocumentSnapshot<Map<String, dynamic>> doc) async {
    final data = doc.data();
    final id = doc.id;
    final formKey = GlobalKey<FormState>();

    String status = (data['status'] ?? 'En attente').toString();
    final notesCtrl = TextEditingController(text: data['notes']?.toString() ?? '');

    bool saving = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) {
        final bottom = MediaQuery.of(context).viewInsets.bottom;
        final createdAt = data['createdAt'];
        String dateStr = '';
        try {
          if (createdAt is Timestamp) {
            final d = createdAt.toDate();
            dateStr =
            '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year} '
                '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
          }
        } catch (_) {}
        final items = (data['items'] is List)
            ? List<Map<String, dynamic>>.from(data['items'])
            : <Map<String, dynamic>>[];
        final total = (data['total'] is num) ? (data['total'] as num) : null;

        return Padding(
          padding: EdgeInsets.only(bottom: bottom),
          child: StatefulBuilder(
            builder: (context, setSheetState) {
              Future<void> save() async {
                if (!formKey.currentState!.validate()) return;
                setSheetState(() => saving = true);
                try {
                  await _ordersCol!.doc(id).update({
                    'status': status,
                    'notes': notesCtrl.text.trim(),
                    'updatedAt': FieldValue.serverTimestamp(),
                  });
                  if (!mounted) return;
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      backgroundColor: Colors.black87,
                      behavior: SnackBarBehavior.floating,
                      content: Text('Commande mise à jour'),
                    ),
                  );
                } catch (e) {
                  setSheetState(() => saving = false);
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
                contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              );

              TextStyle _label = const TextStyle(
                  fontWeight: FontWeight.w700, fontSize: 13, color: Colors.black87);

              Widget _chip(String text, {Color? bg, Color? fg}) => Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: bg ?? AppColors.primary.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(text,
                    style: TextStyle(
                        color: fg ?? Colors.grey.shade700,
                        fontWeight: FontWeight.w600,
                        fontSize: 12)),
              );

              return Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                child: SingleChildScrollView(
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 46,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(100),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Header
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(Icons.shopping_bag_rounded,
                                  color: AppColors.primary, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(data['code']?.toString() ?? 'Commande',
                                      style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w800,
                                          color: Colors.black87)),
                                  const SizedBox(height: 4),
                                  Text(dateStr,
                                      style: TextStyle(
                                          color: Colors.grey.shade600)),
                                ],
                              ),
                            ),
                            _chip(
                              data['status']?.toString() ?? 'En attente',
                              bg: _statusBg(data['status']?.toString()),
                              fg: _statusFg(data['status']?.toString()),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Client + Paiement
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Align(
                                      alignment: Alignment.centerLeft,
                                      child: Text('Client', style: _label)),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      Icon(Icons.person_rounded,
                                          size: 16,
                                          color: Colors.grey.shade700),
                                      const SizedBox(width: 6),
                                      Expanded(
                                          child: Text(
                                              data['clientName']?.toString() ??
                                                  '--',
                                              style: const TextStyle(
                                                  fontWeight:
                                                  FontWeight.w600))),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      Icon(Icons.phone_rounded,
                                          size: 16,
                                          color: Colors.grey.shade700),
                                      const SizedBox(width: 6),
                                      Text(data['clientPhone']?.toString() ??
                                          '--'),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      Icon(Icons.location_on_rounded,
                                          size: 16,
                                          color: Colors.grey.shade700),
                                      const SizedBox(width: 6),
                                      Expanded(
                                          child: Text(
                                              data['address']?.toString() ??
                                                  '--')),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Align(
                                      alignment: Alignment.centerLeft,
                                      child: Text('Paiement', style: _label)),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      Icon(Icons.payments_rounded,
                                          size: 16,
                                          color: Colors.grey.shade700),
                                      const SizedBox(width: 6),
                                      Expanded(
                                          child: Text(
                                              data['paymentMethod']
                                                  ?.toString() ??
                                                  '—')),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      Icon(Icons.attach_money_rounded,
                                          size: 16,
                                          color: Colors.grey.shade700),
                                      const SizedBox(width: 6),
                                      Text(
                                        (total is num)
                                            ? '${total.toStringAsFixed(0)} XAF'
                                            : '--',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w700),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Items
                        Align(
                            alignment: Alignment.centerLeft,
                            child: Text('Articles', style: _label)),
                        const SizedBox(height: 8),
                        if (items.isEmpty)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Text('Aucun article',
                                style:
                                TextStyle(color: Colors.grey.shade600)),
                          )
                        else
                          Column(
                            children: items.map((it) {
                              final name = (it['name'] ?? '--').toString();
                              final qty = (it['qty'] is num)
                                  ? (it['qty'] as num)
                                  : null;
                              final price = (it['price'] is num)
                                  ? (it['price'] as num)
                                  : null;
                              final lineTotal = (it['total'] is num)
                                  ? (it['total'] as num)
                                  : (qty != null && price != null
                                  ? qty * price
                                  : null);
                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.03),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.medication_rounded,
                                        color: AppColors.primary, size: 20),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                        children: [
                                          Text(name,
                                              style: const TextStyle(
                                                  fontWeight:
                                                  FontWeight.w700)),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              _chip('Qté: ${qty ?? '--'}'),
                                              const SizedBox(width: 8),
                                              _chip('PU: ${price != null ? '${price.toStringAsFixed(0)} XAF' : '--'}'),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      lineTotal != null
                                          ? '${lineTotal.toStringAsFixed(0)} XAF'
                                          : '--',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w800),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        const SizedBox(height: 16),

                        // Statut + Notes
                        Align(
                            alignment: Alignment.centerLeft,
                            child: Text('Statut', style: _label)),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<String>(
                          value: kOrderStatuses.contains(status)
                              ? status
                              : 'En attente',
                          items: kOrderStatuses
                              .map((e) => DropdownMenuItem(
                              value: e, child: Text(e)))
                              .toList(),
                          onChanged: (v) =>
                              setSheetState(() => status = v ?? status),
                          decoration: _dec('Sélectionner'),
                        ),
                        const SizedBox(height: 12),

                        Align(
                            alignment: Alignment.centerLeft,
                            child: Text('Note', style: _label)),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: notesCtrl,
                          decoration: _dec(
                              'Ex: Appeler le client avant livraison…'),
                          maxLines: 3,
                        ),

                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed:
                                saving ? null : () => Navigator.pop(context),
                                style: OutlinedButton.styleFrom(
                                  padding:
                                  const EdgeInsets.symmetric(vertical: 14),
                                  side: BorderSide(
                                      color: Colors.grey.shade300),
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                      BorderRadius.circular(12)),
                                ),
                                child: const Text('Fermer'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: saving ? null : save,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  padding:
                                  const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                ),
                                child: saving
                                    ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white),
                                )
                                    : const Text('Enregistrer',
                                    style: TextStyle(
                                        fontWeight: FontWeight.w700)),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_user == null) {
      return _buildScaffoldBody(
        Center(
          child: Text('Veuillez vous connecter pour voir vos commandes.',
              style: TextStyle(color: Colors.grey.shade700)),
        ),
      );
    }

    final query = _baseQuery();
    if (query == null) {
      return _buildScaffoldBody(
          const Center(child: CircularProgressIndicator()));
    }

    return _buildScaffoldBody(
      StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: query.snapshots(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(
                child: Text('Erreur: ${snap.error}',
                    style: TextStyle(color: Colors.red.shade700)));
          }

          final docs =
          (snap.data?.docs ?? []).where((d) => _matchesSearch(d.data())).toList();

          if (docs.isEmpty) {
            return Center(
              child: Text(
                _searchCtrl.text.isEmpty
                    ? 'Aucune commande.'
                    : 'Aucune commande ne correspond à "${_searchCtrl.text}".',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.only(top: 12),
            itemBuilder: (_, i) => _buildOrderCard(docs[i]),
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemCount: docs.length,
          );
        },
      ),
    );
  }

  /// Envelope: bandeau (titre + recherche + filtres) + contenu
  Widget _buildScaffoldBody(Widget body) {
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
              BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2)),
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
                    child: Icon(Icons.shopping_bag_rounded,
                        color: AppColors.primary, size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Commandes',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Colors.black87),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Recherche
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
                          hintText: 'Rechercher (code, client, téléphone)…',
                          hintStyle: TextStyle(
                            color: Colors.grey.shade500,
                            fontWeight: FontWeight.w400,
                          ),
                          prefixIcon: Icon(Icons.search_rounded,
                              color: Colors.grey.shade400, size: 20),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
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
                    _buildFilterChip('Tous', OrderFilter.all),
                    _buildFilterChip('En attente', OrderFilter.pending),
                    _buildFilterChip('Validées', OrderFilter.validated),
                    _buildFilterChip('Préparées', OrderFilter.prepared),
                    _buildFilterChip('Expédiées', OrderFilter.shipped),
                    _buildFilterChip('Livrées', OrderFilter.delivered),
                    _buildFilterChip('Annulées', OrderFilter.canceled),
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

  Widget _buildFilterChip(String label, OrderFilter value) {
    final selected = _filter == value;
    return InkWell(
      borderRadius: BorderRadius.circular(100),
      onTap: () => setState(() => _filter = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary
              : AppColors.primary.withOpacity(0.08),
          borderRadius: BorderRadius.circular(100),
          boxShadow: selected
              ? [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : AppColors.primary,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildOrderCard(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    final id = doc.id;

    final code = (data['code'] ?? 'Commande').toString();
    final status = (data['status'] ?? 'En attente').toString();
    final client = (data['clientName'] ?? '--').toString();
    final phone = (data['clientPhone'] ?? '--').toString();
    final pay = (data['paymentMethod'] ?? '—').toString();
    final total = (data['total'] is num) ? (data['total'] as num) : null;

    // Date courte
    String dateStr = '';
    try {
      final ts = data['createdAt'];
      if (ts is Timestamp) {
        final d = ts.toDate();
        dateStr =
        '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year} '
            '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
      }
    } catch (_) {}

    final isPending = status == 'En attente';
    final isBusy = _busy.contains(id);

    return Container
      (
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Picto
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.receipt_long_rounded,
                color: AppColors.primary, size: 22),
          ),
          const SizedBox(width: 14),

          // Infos principales
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Code + date + statut
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        code,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          color: Colors.black87,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    _statusPill(status),
                  ],
                ),
                const SizedBox(height: 6),
                Text(dateStr, style: TextStyle(color: Colors.grey.shade600)),
                const SizedBox(height: 8),

                // Client + paiement
                Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  children: [
                    _infoBadge(Icons.person_rounded, client),
                    _infoBadge(Icons.phone_rounded, phone),
                    _infoBadge(Icons.payments_rounded, pay),
                    _infoBadge(Icons.attach_money_rounded,
                        total != null ? '${total.toStringAsFixed(0)} XAF' : '--'),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(width: 16),

          // Actions
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Lignes d'actions
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Valider
                  ElevatedButton.icon(
                    onPressed: (!isPending || isBusy)
                        ? null
                        : () => _validateOrder(id, status),
                    icon: isBusy
                        ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.verified_rounded, size: 16),
                    label: const Text('Valider'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Détails
                  OutlinedButton.icon(
                    onPressed: isBusy ? null : () => _openOrderDetails(doc),
                    icon: const Icon(Icons.visibility_rounded, size: 16),
                    label: const Text('Détails'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      side: BorderSide(color: Colors.grey.shade300),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Menu (suppression + raccourcis de statut)
                  PopupMenuButton<String>(
                    onSelected: (v) {
                      if (v == 'delete') {
                        _deleteOrder(id);
                      } else if (kOrderStatuses.contains(v)) {
                        _updateStatus(id, v);
                      }
                    },
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    itemBuilder: (context) => [
                      const PopupMenuItem<String>(
                        value: 'header1',
                        enabled: false,
                        child: Text('Changer le statut',
                            style: TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 12)),
                      ),
                      const PopupMenuDivider(height: 8),
                      ...kOrderStatuses
                          .where((s) => s != status)
                          .map((s) => PopupMenuItem<String>(
                        value: s,
                        child: Text(s),
                      )),
                      const PopupMenuDivider(height: 8),
                      PopupMenuItem<String>(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_rounded,
                                size: 18, color: Colors.red.shade600),
                            const SizedBox(width: 8),
                            const Text('Supprimer'),
                          ],
                        ),
                      ),
                    ],
                    icon: Icon(Icons.more_vert_rounded,
                        color: Colors.grey.shade700),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- helpers UI ---

  Widget _infoBadge(IconData icon, String text) {
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
          Text(
            text,
            style: TextStyle(
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusPill(String s) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: _statusBg(s),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        s,
        style: TextStyle(
          color: _statusFg(s),
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }

  Color _statusBg(String? s) {
    switch (s) {
      case 'En attente':
        return Colors.orange.withOpacity(0.12);
      case 'Validée':
        return AppColors.primary.withOpacity(0.12);
      case 'Préparée':
        return Colors.indigo.withOpacity(0.12);
      case 'Expédiée':
        return Colors.purple.withOpacity(0.12);
      case 'Livrée':
        return Colors.green.withOpacity(0.12);
      case 'Annulée':
        return Colors.red.withOpacity(0.12);
      default:
        return AppColors.primary.withOpacity(0.10);
    }
  }

  Color _statusFg(String? s) {
    switch (s) {
      case 'En attente':
        return Colors.orange.shade800;
      case 'Validée':
        return AppColors.primary;
      case 'Préparée':
        return Colors.indigo.shade700;
      case 'Expédiée':
        return Colors.purple.shade700;
      case 'Livrée':
        return Colors.green.shade700;
      case 'Annulée':
        return Colors.red.shade700;
      default:
        return AppColors.primary;
    }
  }
}
