import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../utilitaires/apps_colors.dart';

/// ---------------------------------------------------------------------------
/// ListesProduitsPage
/// Firestore: users/{uid}/produits
/// Champs: name, price, principesActifs, classeMedic, format, laboratoire,
///         conditionnement, isActive, stock, imageUrl?, createdAt
/// ---------------------------------------------------------------------------

class ListesProduitsPage extends StatefulWidget {
  const ListesProduitsPage({super.key});
  @override
  State<ListesProduitsPage> createState() => _ListesProduitsPageState();
}

enum ProductFilter { all, active, inactive }

// ---------------------- Prédefs (options dropdown) ----------------------
// Classes médicamenteuses (curation inspirée ATC/EML OMS)
const List<String> kClasseMedicOptions = [
  // Anti-infectieux
  'Antibiotiques – Pénicillines',
  'Antibiotiques – Céphalosporines',
  'Antibiotiques – Macrolides',
  'Antibiotiques – Tétracyclines',
  'Antibiotiques – Quinolones',
  'Antituberculeux',
  'Antifongiques',
  'Antiviraux',
  'Antipaludéens',
  'Anthelminthiques / Antiparasitaires',
  // Douleur/Inflammation
  'Antalgiques (Analgésiques)',
  'AINS (anti-inflammatoires non stéroïdiens)',
  'Corticoïdes (systémiques)',
  // Respiratoire / Allergies
  'Bronchodilatateurs (SABA/LABA)',
  'Corticoïdes inhalés',
  'Antihistaminiques',
  // Cardiovasculaire / Sang
  'Antihypertenseurs',
  'Diurétiques',
  'Anticoagulants / Antiagrégants',
  // Métabolisme / Gastro
  'Antidiabétiques oraux',
  'Insulines',
  'Anti-ulcéreux / IPP',
  // Système nerveux
  'Antidépresseurs',
  'Antipsychotiques',
  'Anxiolytiques / Sédatifs',
  // Divers
  'Dermatologie (topiques)',
  'Ophtalmologie / ORL (collyres, sprays)',
  'Gynéco-obstétrique (contraceptifs)',
  'Vitamines / Minéraux',
  'Vaccins',
];

// Formats (formes pharmaceutiques)
const List<String> kFormatOptions = [
  'Comprimé',
  'Gélule',
  'Sirop',
  'Suspension buvable',
  'Gouttes orales',
  'Poudre pour solution orale',
  'Solution injectable',
  'Suspension injectable',
  'Poudre pour injection',
  'Crème',
  'Pommade',
  'Gel',
  'Lotion',
  'Collyre (gouttes ophtalmiques)',
  'Spray nasal',
  'Inhalateur',
  'Suppositoire',
  'Patch transdermique',
];

// Conditionnements usuels
const List<String> kConditionnementOptions = [
  'Boîte de 10 comprimés',
  'Boîte de 16 comprimés',
  'Boîte de 30 comprimés',
  'Blister x10',
  'Flacon 60 mL',
  'Flacon 100 mL',
  'Flacon 150 mL',
  'Tube 15 g',
  'Tube 30 g',
  'Ampoule 1 mL',
  'Ampoule 5 mL',
  'Sachet unidose',
  'Flacon-pulvérisateur',
];

class _ListesProduitsPageState extends State<ListesProduitsPage> {
  final TextEditingController _searchCtrl = TextEditingController();
  ProductFilter _filter = ProductFilter.all;

  final Set<String> _loadingIds = {};
  User? _user;
  CollectionReference<Map<String, dynamic>>? _productsCol;

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
        _productsCol = FirebaseFirestore.instance
            .collection('users')      // << collection users (pluriel)
            .doc(u.uid)               // << doc de l'utilisateur connecté
            .collection('produits');  // << sous-collection
      }
    });
  }

  Query<Map<String, dynamic>>? _baseQuery() {
    if (_productsCol == null) return null;
    Query<Map<String, dynamic>> q = _productsCol!;
    switch (_filter) {
      case ProductFilter.active:
        q = q.where('isActive', isEqualTo: true);
        break;
      case ProductFilter.inactive:
        q = q.where('isActive', isEqualTo: false);
        break;
      case ProductFilter.all:
        break;
    }
    q = q.orderBy('createdAt', descending: true);
    return q;
  }

  bool _matchesSearch(Map<String, dynamic> data) {
    final term = _searchCtrl.text.trim().toLowerCase();
    if (term.isEmpty) return true;
    final name = (data['name'] ?? '').toString().toLowerCase();
    final classe = (data['classeMedic'] ?? '').toString().toLowerCase();
    final lab = (data['laboratoire'] ?? '').toString().toLowerCase();
    final format = (data['format'] ?? '').toString().toLowerCase();
    return name.contains(term) || classe.contains(term) || lab.contains(term) || format.contains(term);
  }

  Future<void> _toggleActivation(String docId, bool currentValue) async {
    if (_productsCol == null) return;
    setState(() => _loadingIds.add(docId));
    try {
      await _productsCol!.doc(docId).update({'isActive': !currentValue});
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.black87,
          behavior: SnackBarBehavior.floating,
          content: Text(!currentValue ? 'Produit activé' : 'Produit désactivé'),
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
      if (mounted) setState(() => _loadingIds.remove(docId));
    }
  }

  Future<void> _deleteProduct(String docId) async {
    if (_productsCol == null) return;
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
            const Text('Supprimer le produit'),
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

    try {
      await _productsCol!.doc(docId).delete();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.black87,
          behavior: SnackBarBehavior.floating,
          content: Text('Produit supprimé'),
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
    }
  }

  Future<void> _openProductForm({QueryDocumentSnapshot<Map<String, dynamic>>? doc}) async {
    final data = doc?.data();
    final isEdit = doc != null;

    final nameCtrl = TextEditingController(text: data?['name']?.toString() ?? '');
    final priceCtrl = TextEditingController(text: data?['price']?.toString() ?? '');
    final principesCtrl = TextEditingController(text: data?['principesActifs']?.toString() ?? '');
    final laboCtrl = TextEditingController(text: data?['laboratoire']?.toString() ?? '');
    final classeInit = data?['classeMedic']?.toString() ?? '';
    final formatInit = data?['format']?.toString() ?? '';
    final condInit = data?['conditionnement']?.toString() ?? '';

    // Dropdown states
    String? classeValue = kClasseMedicOptions.contains(classeInit) ? classeInit : (classeInit.isEmpty ? null : 'Autre…');
    String? formatValue = kFormatOptions.contains(formatInit) ? formatInit : (formatInit.isEmpty ? null : 'Autre…');
    String? condValue   = kConditionnementOptions.contains(condInit) ? condInit : (condInit.isEmpty ? null : 'Autre…');

    final classeAutreCtrl = TextEditingController(text: (!kClasseMedicOptions.contains(classeInit)) ? classeInit : '');
    final formatAutreCtrl = TextEditingController(text: (!kFormatOptions.contains(formatInit)) ? formatInit : '');
    final condAutreCtrl   = TextEditingController(text: (!kConditionnementOptions.contains(condInit)) ? condInit : '');

    final formKey = GlobalKey<FormState>();
    bool saving = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) {
        final bottom = MediaQuery.of(context).viewInsets.bottom;
        return Padding(
          padding: EdgeInsets.only(bottom: bottom),
          child: StatefulBuilder(
            builder: (context, setSheetState) {
              Future<void> save() async {
                if (!formKey.currentState!.validate()) return;
                if (_productsCol == null) return;
                setSheetState(() => saving = true);
                try {
                  final priceVal = double.tryParse(priceCtrl.text.trim()) ?? 0.0;

                  final classe = (classeValue == 'Autre…')
                      ? classeAutreCtrl.text.trim()
                      : (classeValue ?? '').trim();
                  final format = (formatValue == 'Autre…')
                      ? formatAutreCtrl.text.trim()
                      : (formatValue ?? '').trim();
                  final cond = (condValue == 'Autre…')
                      ? condAutreCtrl.text.trim()
                      : (condValue ?? '').trim();

                  final payload = <String, dynamic>{
                    'name': nameCtrl.text.trim(),
                    'price': priceVal,
                    'principesActifs': principesCtrl.text.trim(),
                    'classeMedic': classe,
                    'format': format,
                    'laboratoire': laboCtrl.text.trim(),
                    'conditionnement': cond,
                    'isActive': data?['isActive'] ?? true,
                    'stock': data?['stock'] ?? 0,
                  };

                  if (isEdit) {
                    await _productsCol!.doc(doc!.id).update(payload);
                  } else {
                    await _productsCol!.add({
                      ...payload,
                      'isActive': true,
                      'stock': 0,
                      'createdAt': FieldValue.serverTimestamp(),
                    });
                  }
                  if (!mounted) return;
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: Colors.black87,
                      behavior: SnackBarBehavior.floating,
                      content: Text(isEdit ? 'Produit mis à jour' : 'Produit ajouté'),
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
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              );

              TextStyle _label = const TextStyle(
                fontWeight: FontWeight.w700, fontSize: 13, color: Colors.black87,
              );

              Widget _gap([double h = 12]) => SizedBox(height: h);

              return Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 46, height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(100),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(isEdit ? Icons.edit_rounded : Icons.add_rounded,
                                color: AppColors.primary, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            isEdit ? 'Modifier le produit' : 'Nouveau produit',
                            style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w800, color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      Form(
                        key: formKey,
                        child: Column(
                          children: [
                            Align(alignment: Alignment.centerLeft, child: Text('Nom commercial', style: _label)),
                            _gap(6),
                            TextFormField(
                              controller: nameCtrl,
                              decoration: _dec('Ex: Paracétamol 500 mg'),
                              validator: (v) => (v == null || v.trim().isEmpty) ? 'Champ requis' : null,
                            ),
                            _gap(),

                            Align(alignment: Alignment.centerLeft, child: Text('Prix (XAF)', style: _label)),
                            _gap(6),
                            TextFormField(
                              controller: priceCtrl,
                              keyboardType: TextInputType.number,
                              decoration: _dec('Ex: 1500'),
                              validator: (v) {
                                final d = double.tryParse((v ?? '').trim());
                                if (d == null) return 'Entrez un nombre';
                                if (d < 0) return 'Doit être positif';
                                return null;
                              },
                            ),
                            _gap(),

                            Align(alignment: Alignment.centerLeft, child: Text('Principes actifs', style: _label)),
                            _gap(6),
                            TextFormField(
                              controller: principesCtrl,
                              decoration: _dec('Ex: Paracetamolum'),
                              maxLines: 2,
                            ),
                            _gap(),

                            // Classe médicamenteuse
                            Align(alignment: Alignment.centerLeft, child: Text('Classe médicamenteuse', style: _label)),
                            _gap(6),
                            DropdownButtonFormField<String>(
                              value: classeValue,
                              items: [
                                ...kClasseMedicOptions.map((e) => DropdownMenuItem(value: e, child: Text(e))),
                                const DropdownMenuItem(value: 'Autre…', child: Text('Autre…')),
                              ],
                              onChanged: (v) => setSheetState(() => classeValue = v),
                              decoration: _dec('Sélectionner'),
                            ),
                            if (classeValue == 'Autre…') ...[
                              _gap(10),
                              TextFormField(
                                controller: classeAutreCtrl,
                                decoration: _dec('Saisir la classe'),
                                validator: (v) => (v == null || v.trim().isEmpty) ? 'Requis si “Autre…”' : null,
                              ),
                            ],
                            _gap(),

                            // Format
                            Align(alignment: Alignment.centerLeft, child: Text('Format', style: _label)),
                            _gap(6),
                            DropdownButtonFormField<String>(
                              value: formatValue,
                              items: [
                                ...kFormatOptions.map((e) => DropdownMenuItem(value: e, child: Text(e))),
                                const DropdownMenuItem(value: 'Autre…', child: Text('Autre…')),
                              ],
                              onChanged: (v) => setSheetState(() => formatValue = v),
                              decoration: _dec('Sélectionner'),
                            ),
                            if (formatValue == 'Autre…') ...[
                              _gap(10),
                              TextFormField(
                                controller: formatAutreCtrl,
                                decoration: _dec('Saisir le format'),
                                validator: (v) => (v == null || v.trim().isEmpty) ? 'Requis si “Autre…”' : null,
                              ),
                            ],
                            _gap(),

                            // Laboratoire
                            Align(alignment: Alignment.centerLeft, child: Text('Laboratoire', style: _label)),
                            _gap(6),
                            TextFormField(
                              controller: laboCtrl,
                              decoration: _dec('Ex: Sanofi, GSK…'),
                            ),
                            _gap(),

                            // Conditionnement
                            Align(alignment: Alignment.centerLeft, child: Text('Conditionnement', style: _label)),
                            _gap(6),
                            DropdownButtonFormField<String>(
                              value: condValue,
                              items: [
                                ...kConditionnementOptions.map((e) => DropdownMenuItem(value: e, child: Text(e))),
                                const DropdownMenuItem(value: 'Autre…', child: Text('Autre…')),
                              ],
                              onChanged: (v) => setSheetState(() => condValue = v),
                              decoration: _dec('Sélectionner'),
                            ),
                            if (condValue == 'Autre…') ...[
                              _gap(10),
                              TextFormField(
                                controller: condAutreCtrl,
                                decoration: _dec('Saisir le conditionnement'),
                                validator: (v) => (v == null || v.trim().isEmpty) ? 'Requis si “Autre…”' : null,
                              ),
                            ],

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
                                        ? const SizedBox(
                                      width: 18, height: 18,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                    )
                                        : const Text('Enregistrer', style: TextStyle(fontWeight: FontWeight.w700)),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
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
          child: Text('Veuillez vous connecter pour voir vos produits.',
              style: TextStyle(color: Colors.grey.shade700)),
        ),
      );
    }

    final query = _baseQuery();
    if (query == null) {
      return _buildScaffoldBody(const Center(child: CircularProgressIndicator()));
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
              child: Text('Erreur: ${snap.error}', style: TextStyle(color: Colors.red.shade700)),
            );
          }

          final docs = (snap.data?.docs ?? [])
              .where((d) => _matchesSearch(d.data()))
              .toList();

          if (docs.isEmpty) {
            return Center(
              child: Text(
                _searchCtrl.text.isEmpty
                    ? 'Aucun produit trouvé.'
                    : 'Aucun produit ne correspond à "${_searchCtrl.text}".',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.only(top: 12),
            itemBuilder: (_, i) => _buildProductCard(docs[i]),
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemCount: docs.length,
          );
        },
      ),
    );
  }

  /// Enveloppe : bandeau (titre + recherche + filtres + bouton Nouveau) + contenu
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
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              // Titre
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.medication_rounded,
                        color: AppColors.primary, size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Produits',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Colors.black87,
                    ),
                  ),
                  const Spacer(),
                  // Bouton Nouveau
                  ElevatedButton.icon(
                    onPressed: () => _openProductForm(),
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('Nouveau'),
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
                          hintText: 'Rechercher un produit…',
                          hintStyle: TextStyle(
                            color: Colors.grey.shade500,
                            fontWeight: FontWeight.w400,
                          ),
                          prefixIcon: Icon(Icons.search_rounded,
                              color: Colors.grey.shade400, size: 20),
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
                    _buildFilterChip('Tous', ProductFilter.all),
                    _buildFilterChip('Actifs', ProductFilter.active),
                    _buildFilterChip('Inactifs', ProductFilter.inactive),
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

  Widget _buildFilterChip(String label, ProductFilter value) {
    final selected = _filter == value;
    return InkWell(
      borderRadius: BorderRadius.circular(100),
      onTap: () => setState(() => _filter = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.primary.withOpacity(0.08),
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

  Widget _buildProductCard(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    final id = doc.id;

    final name = (data['name'] ?? 'Sans titre').toString();
    final price = data['price'];
    final stock = data['stock'];
    final img = data['imageUrl'];
    final isActive = (data['isActive'] is bool) ? data['isActive'] as bool : true;

    final priceStr = (price is num) ? '${price.toStringAsFixed(0)} XAF' : '--';
    final stockStr = (stock is num) ? stock.toString() : '--';

    return Container(
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
          _buildProductImage(img),
          const SizedBox(width: 16),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Nom + menu
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: Colors.black87,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    PopupMenuButton<String>(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      onSelected: (value) {
                        if (value == 'edit') {
                          _openProductForm(doc: doc);
                        } else if (value == 'delete') {
                          _deleteProduct(id);
                        }
                      },
                      itemBuilder: (_) => [
                        PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit_rounded, size: 18, color: Colors.grey.shade800),
                              const SizedBox(width: 8),
                              const Text('Modifier'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete_rounded, size: 18, color: Colors.red.shade600),
                              const SizedBox(width: 8),
                              const Text('Supprimer'),
                            ],
                          ),
                        ),
                      ],
                      icon: Icon(Icons.more_vert_rounded, color: Colors.grey.shade700),
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                // Badges info
                Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  children: [
                    _miniBadge(Icons.sell_rounded, priceStr),
                    _miniBadge(Icons.inventory_2_rounded, 'Stock: $stockStr'),
                    if ((data['classeMedic'] ?? '').toString().isNotEmpty)
                      _miniBadge(Icons.category_rounded, data['classeMedic'].toString()),
                    if ((data['format'] ?? '').toString().isNotEmpty)
                      _miniBadge(Icons.widgets_rounded, data['format'].toString()),
                    if ((data['conditionnement'] ?? '').toString().isNotEmpty)
                      _miniBadge(Icons.all_inbox_rounded, data['conditionnement'].toString()),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(width: 16),

          // Activer / Désactiver
          SizedBox(
            height: 40,
            child: _buildActivationButton(
              id: id,
              isActive: isActive,
              onPressed: _loadingIds.contains(id) ? null : () => _toggleActivation(id, isActive),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductImage(String? url) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 64,
        height: 64,
        color: Colors.grey.shade100,
        child: url == null || url.isEmpty
            ? Icon(Icons.medication_liquid_rounded,
            color: AppColors.primary.withOpacity(0.8), size: 28)
            : Image.network(
          url,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Icon(
            Icons.broken_image_rounded, color: Colors.grey.shade400, size: 28,
          ),
        ),
      ),
    );
  }

  Widget _miniBadge(IconData icon, String text) {
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

  Widget _buildActivationButton({
    required String id,
    required bool isActive,
    required VoidCallback? onPressed,
  }) {
    final isLoading = _loadingIds.contains(id);

    final bg = isActive ? Colors.white : AppColors.primary;
    final fg = isActive ? Colors.red.shade600 : Colors.white;
    final border = isActive ? Colors.red.shade200 : AppColors.primary;

    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: isLoading
          ? SizedBox(
        width: 16,
        height: 16,
        child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(fg)),
      )
          : Icon(isActive ? Icons.visibility_off_rounded : Icons.visibility_rounded, size: 16, color: fg),
      label: Text(isActive ? 'Désactiver' : 'Activer',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: fg)),
      style: ElevatedButton.styleFrom(
        backgroundColor: bg,
        foregroundColor: fg,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: border),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
    );
  }
}
