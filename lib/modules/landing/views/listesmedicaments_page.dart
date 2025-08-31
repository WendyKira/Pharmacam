import 'package:flutter/material.dart';

import '../../../composants/custom_bottom.dart';
import '../../../utilitaires/apps_colors.dart';

class Medication {
  final String id;
  final String name;
  final String genericName;
  final String category;
  final String form;
  final String laboratory;
  final String usage;
  final String priceRange;
  final String dosage;
  final String indication;
  final List<PharmacyStock> pharmacyStocks;

  Medication({
    required this.id,
    required this.name,
    required this.genericName,
    required this.category,
    required this.form,
    required this.laboratory,
    required this.usage,
    required this.priceRange,
    required this.dosage,
    required this.indication,
    required this.pharmacyStocks,
  });
}

class PharmacyStock {
  final String pharmacyId;
  final String pharmacyName;
  final String pharmacyLocation;
  final StockStatus status;
  final int quantity;
  final String lastUpdated;

  PharmacyStock({
    required this.pharmacyId,
    required this.pharmacyName,
    required this.pharmacyLocation,
    required this.status,
    required this.quantity,
    required this.lastUpdated,
  });
}

enum StockStatus { available, limited, unavailable }

class MedicamentsPage extends StatefulWidget {
  const MedicamentsPage({Key? key}) : super(key: key);

  @override
  State<MedicamentsPage> createState() => _MedicationsPageState();
}

class _MedicationsPageState extends State<MedicamentsPage> with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = '';
  String _selectedStock = '';
  List<Medication> _filteredMedications = [];
  bool _isLoading = false;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final List<String> _categories = [
    'Analgésiques',
    'Antibiotiques',
    'Antipaludéens',
    'Cardiovasculaires',
    'Respiratoires',
    'Digestifs',
    'Dermatologiques',
  ];

  final List<Medication> _medications = [
    Medication(
      id: '1',
      name: 'Paracétamol 500mg',
      genericName: 'Acétaminophène',
      category: 'Analgésiques',
      form: 'Comprimés pelliculés',
      laboratory: 'LABOREX - Cameroun',
      usage: 'Douleur légère à modérée, fièvre',
      dosage: '500mg - 1 à 2 comprimés toutes les 6h',
      indication: 'Adultes et enfants > 15 ans',
      priceRange: '150 - 350 FCFA',
      pharmacyStocks: [
        PharmacyStock(pharmacyId: '1', pharmacyName: 'Pharmacie Centrale Yaoundé', pharmacyLocation: 'Centre-ville, Yaoundé', status: StockStatus.available, quantity: 150, lastUpdated: '2h'),
        PharmacyStock(pharmacyId: '2', pharmacyName: 'Pharmacie du Rond-Point', pharmacyLocation: 'Rond-Point Nlongkak', status: StockStatus.limited, quantity: 25, lastUpdated: '4h'),
        PharmacyStock(pharmacyId: '3', pharmacyName: 'Pharmacie Populaire', pharmacyLocation: 'Mfoundi, Yaoundé', status: StockStatus.available, quantity: 89, lastUpdated: '1h'),
      ],
    ),
    Medication(
      id: '2',
      name: 'Ibuprofène 400mg',
      genericName: 'Anti-inflammatoire non stéroïdien',
      category: 'Analgésiques',
      form: 'Comprimés enrobés',
      laboratory: 'NOVARTIS - Cameroun',
      usage: 'Inflammation, douleurs articulaires et musculaires',
      dosage: '400mg - 1 comprimé 3 fois/jour',
      indication: 'Adultes, avec repas',
      priceRange: '400 - 850 FCFA',
      pharmacyStocks: [
        PharmacyStock(pharmacyId: '1', pharmacyName: 'Pharmacie Centrale Yaoundé', pharmacyLocation: 'Centre-ville, Yaoundé', status: StockStatus.available, quantity: 75, lastUpdated: '3h'),
        PharmacyStock(pharmacyId: '2', pharmacyName: 'Pharmacie du Rond-Point', pharmacyLocation: 'Rond-Point Nlongkak', status: StockStatus.unavailable, quantity: 0, lastUpdated: '6h'),
        PharmacyStock(pharmacyId: '4', pharmacyName: 'Pharmacie Saint-Michel', pharmacyLocation: 'Mvog-Mbi', status: StockStatus.limited, quantity: 12, lastUpdated: '2h'),
      ],
    ),
    Medication(
      id: '3',
      name: 'Amoxicilline 500mg',
      genericName: 'Pénicilline A (β-lactamine)',
      category: 'Antibiotiques',
      form: 'Gélules',
      laboratory: 'GSK - Cameroun',
      usage: 'Infections bactériennes diverses',
      dosage: '500mg - 1 gélule 3 fois/jour pendant 7-10 jours',
      indication: 'Sur prescription médicale uniquement',
      priceRange: '800 - 1600 FCFA',
      pharmacyStocks: [
        PharmacyStock(pharmacyId: '1', pharmacyName: 'Pharmacie Centrale Yaoundé', pharmacyLocation: 'Centre-ville, Yaoundé', status: StockStatus.available, quantity: 200, lastUpdated: '1h'),
        PharmacyStock(pharmacyId: '2', pharmacyName: 'Pharmacie du Rond-Point', pharmacyLocation: 'Rond-Point Nlongkak', status: StockStatus.available, quantity: 45, lastUpdated: '2h'),
        PharmacyStock(pharmacyId: '3', pharmacyName: 'Pharmacie Populaire', pharmacyLocation: 'Mfoundi, Yaoundé', status: StockStatus.limited, quantity: 18, lastUpdated: '5h'),
      ],
    ),
    Medication(
      id: '4',
      name: 'Artéméther + Luméfantrine',
      genericName: 'Coartem® (Antipaludique ACT)',
      category: 'Antipaludéens',
      form: 'Comprimés dispersibles',
      laboratory: 'NOVARTIS - Suisse/Cameroun',
      usage: 'Traitement du paludisme simple à P. falciparum',
      dosage: 'Selon poids corporel - 6 doses sur 3 jours',
      indication: 'Enfants > 5kg et adultes',
      priceRange: '2500 - 4200 FCFA',
      pharmacyStocks: [
        PharmacyStock(pharmacyId: '1', pharmacyName: 'Pharmacie Centrale Yaoundé', pharmacyLocation: 'Centre-ville, Yaoundé', status: StockStatus.available, quantity: 89, lastUpdated: '30min'),
        PharmacyStock(pharmacyId: '2', pharmacyName: 'Pharmacie du Rond-Point', pharmacyLocation: 'Rond-Point Nlongkak', status: StockStatus.available, quantity: 67, lastUpdated: '1h'),
        PharmacyStock(pharmacyId: '3', pharmacyName: 'Pharmacie Populaire', pharmacyLocation: 'Mfoundi, Yaoundé', status: StockStatus.limited, quantity: 23, lastUpdated: '3h'),
        PharmacyStock(pharmacyId: '5', pharmacyName: 'Pharmacie de l\'Unité', pharmacyLocation: 'Bastos, Yaoundé', status: StockStatus.available, quantity: 112, lastUpdated: '45min'),
      ],
    ),
    Medication(
      id: '5',
      name: 'Artésunate + Amodiaquine',
      genericName: 'ASAQ (Thérapie Combinée Artémisinine)',
      category: 'Antipaludéens',
      form: 'Comprimés co-blistérés',
      laboratory: 'SANOFI - France/Cameroun',
      usage: 'Traitement du paludisme simple, alternative au Coartem',
      dosage: '1 comprimé/jour pendant 3 jours',
      indication: 'Adultes et enfants > 6 mois',
      priceRange: '2000 - 3800 FCFA',
      pharmacyStocks: [
        PharmacyStock(pharmacyId: '1', pharmacyName: 'Pharmacie Centrale Yaoundé', pharmacyLocation: 'Centre-ville, Yaoundé', status: StockStatus.available, quantity: 134, lastUpdated: '2h'),
        PharmacyStock(pharmacyId: '3', pharmacyName: 'Pharmacie Populaire', pharmacyLocation: 'Mfoundi, Yaoundé', status: StockStatus.available, quantity: 78, lastUpdated: '1h'),
        PharmacyStock(pharmacyId: '6', pharmacyName: 'Pharmacie du Marché', pharmacyLocation: 'Marché Central', status: StockStatus.limited, quantity: 15, lastUpdated: '4h'),
      ],
    ),
    Medication(
      id: '6',
      name: 'Lisinopril 10mg',
      genericName: 'Inhibiteur de l\'Enzyme de Conversion (IEC)',
      category: 'Cardiovasculaires',
      form: 'Comprimés sécables',
      laboratory: 'MERCK - Allemagne/Cameroun',
      usage: 'Hypertension artérielle, insuffisance cardiaque',
      dosage: '10mg - 1 comprimé/jour le matin',
      indication: 'Traitement de longue durée sous surveillance',
      priceRange: '1500 - 3200 FCFA',
      pharmacyStocks: [
        PharmacyStock(pharmacyId: '1', pharmacyName: 'Pharmacie Centrale Yaoundé', pharmacyLocation: 'Centre-ville, Yaoundé', status: StockStatus.available, quantity: 67, lastUpdated: '2h'),
        PharmacyStock(pharmacyId: '2', pharmacyName: 'Pharmacie du Rond-Point', pharmacyLocation: 'Rond-Point Nlongkak', status: StockStatus.limited, quantity: 19, lastUpdated: '5h'),
        PharmacyStock(pharmacyId: '7', pharmacyName: 'Pharmacie Essos', pharmacyLocation: 'Essos, Yaoundé', status: StockStatus.available, quantity: 43, lastUpdated: '3h'),
      ],
    ),
    Medication(
      id: '7',
      name: 'Salbutamol 100μg/dose',
      genericName: 'Ventoline® (β2-agoniste)',
      category: 'Respiratoires',
      form: 'Aérosol doseur (200 doses)',
      laboratory: 'GSK - Royaume-Uni/Cameroun',
      usage: 'Asthme, bronchospasme, BPCO',
      dosage: '1-2 bouffées selon besoin, max 8/jour',
      indication: 'Bronchodilatateur de crise',
      priceRange: '3000 - 5500 FCFA',
      pharmacyStocks: [
        PharmacyStock(pharmacyId: '1', pharmacyName: 'Pharmacie Centrale Yaoundé', pharmacyLocation: 'Centre-ville, Yaoundé', status: StockStatus.limited, quantity: 12, lastUpdated: '6h'),
        PharmacyStock(pharmacyId: '2', pharmacyName: 'Pharmacie du Rond-Point', pharmacyLocation: 'Rond-Point Nlongkak', status: StockStatus.available, quantity: 28, lastUpdated: '1h'),
        PharmacyStock(pharmacyId: '8', pharmacyName: 'Pharmacie Biyem-Assi', pharmacyLocation: 'Biyem-Assi', status: StockStatus.unavailable, quantity: 0, lastUpdated: '12h'),
      ],
    ),
    Medication(
      id: '8',
      name: 'Oméprazole 20mg',
      genericName: 'Inhibiteur de la pompe à protons (IPP)',
      category: 'Digestifs',
      form: 'Gélules gastro-résistantes',
      laboratory: 'TEVA - Israël/Cameroun',
      usage: 'Ulcère gastrique, RGO, protection gastrique',
      dosage: '20mg - 1 gélule le matin à jeun',
      indication: 'Traitement de 4 à 8 semaines',
      priceRange: '1200 - 2800 FCFA',
      pharmacyStocks: [
        PharmacyStock(pharmacyId: '1', pharmacyName: 'Pharmacie Centrale Yaoundé', pharmacyLocation: 'Centre-ville, Yaoundé', status: StockStatus.available, quantity: 95, lastUpdated: '1h'),
        PharmacyStock(pharmacyId: '3', pharmacyName: 'Pharmacie Populaire', pharmacyLocation: 'Mfoundi, Yaoundé', status: StockStatus.available, quantity: 67, lastUpdated: '2h'),
        PharmacyStock(pharmacyId: '9', pharmacyName: 'Pharmacie Mokolo', pharmacyLocation: 'Mokolo, Yaoundé', status: StockStatus.limited, quantity: 21, lastUpdated: '7h'),
      ],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _filteredMedications = _medications;
    _searchController.addListener(_filterMedications);

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _filterMedications() {
    setState(() {
      _filteredMedications = _medications.where((medication) {
        final searchTerm = _searchController.text.toLowerCase();
        final matchesSearch = medication.name.toLowerCase().contains(searchTerm) ||
            medication.genericName.toLowerCase().contains(searchTerm) ||
            medication.usage.toLowerCase().contains(searchTerm);

        final matchesCategory = _selectedCategory.isEmpty ||
            medication.category == _selectedCategory;

        final matchesStock = _selectedStock.isEmpty || _hasMatchingStock(medication);

        return matchesSearch && matchesCategory && matchesStock;
      }).toList();
    });
  }

  bool _hasMatchingStock(Medication medication) {
    switch (_selectedStock) {
      case 'available':
        return medication.pharmacyStocks
            .any((stock) => stock.status == StockStatus.available);
      case 'limited':
        return medication.pharmacyStocks
            .any((stock) => stock.status == StockStatus.limited);
      case 'unavailable':
        return medication.pharmacyStocks
            .every((stock) => stock.status == StockStatus.unavailable);
      default:
        return true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background, // Remplacé le gradient par une couleur unie
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.textPrimary.withOpacity(0.1),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: _buildSearchSection(),
            ),
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(25),
                    topRight: Radius.circular(25),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.textPrimary.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: _buildMedicationsList(),
              ),
            ),
            Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.textPrimary.withOpacity(0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: _buildStatsBar(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        decoration: BoxDecoration(
          color: AppColors.surface,
          boxShadow: [
            BoxShadow(
              color: AppColors.textPrimary.withOpacity(0.1),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(
                    Icons.arrow_back_ios_rounded,
                    color: AppColors.textPrimary,
                    size: 20, // Ajusté pour une meilleure proportion
                  ),
                ),
                const Expanded(
                  child: Column(
                    children: [
                      Text(
                        '💊 Liste de Médicaments',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: 6),
                    ],
                  ),
                ),
                const SizedBox(width: 20),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: AppColors.primary),
          ),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Rechercher un médicament, substance active...',
              hintStyle: TextStyle(color: AppColors.textSecondary),
              prefixIcon: Icon(Icons.search_rounded, color: AppColors.textSecondary),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                icon: Icon(Icons.clear_rounded, color: AppColors.textSecondary),
                onPressed: () {
                  _searchController.clear();
                  _filterMedications();
                },
              )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildFilterDropdown(
                hint: 'Catégorie',
                value: _selectedCategory.isEmpty ? null : _selectedCategory,
                items: _categories,
                onChanged: (value) {
                  setState(() {
                    _selectedCategory = value ?? '';
                  });
                  _filterMedications();
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildFilterDropdown(
                hint: 'Disponibilité',
                value: _selectedStock.isEmpty ? null : _selectedStock,
                items: const ['available', 'limited', 'unavailable'],
                itemLabels: const ['Disponible', 'Stock limité', 'Non disponible'],
                onChanged: (value) {
                  setState(() {
                    _selectedStock = value ?? '';
                  });
                  _filterMedications();
                },
              ),
            ),
          ],
        ),
        if (_searchController.text.isNotEmpty || _selectedCategory.isNotEmpty || _selectedStock.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${_filteredMedications.length} médicament(s) trouvé(s)',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (_searchController.text.isNotEmpty || _selectedCategory.isNotEmpty || _selectedStock.isNotEmpty)
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _searchController.clear();
                        _selectedCategory = '';
                        _selectedStock = '';
                      });
                      _filterMedications();
                    },
                    child: const Text('Effacer filtres'),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildFilterDropdown({
    required String hint,
    required String? value,
    required List<String> items,
    List<String>? itemLabels,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary),
      ),
      child: DropdownButtonFormField<String>(
        value: value,
        hint: Text(
          hint,
          style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
        ),
        decoration: const InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        items: [
          DropdownMenuItem<String>(
            value: '',
            child: Text('Tous les ${hint.toLowerCase()}s'),
          ),
          ...items.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            final label = itemLabels?[index] ?? item;
            return DropdownMenuItem<String>(
              value: item,
              child: Text(label),
            );
          }),
        ],
        onChanged: onChanged,
        dropdownColor: AppColors.background,
        style: TextStyle(color: AppColors.textPrimary),
      ),
    );
  }

  Widget _buildMedicationsList() {
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : _filteredMedications.isEmpty
        ? _buildEmptyState()
        : ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _filteredMedications.length,
      itemBuilder: (context, index) {
        return AnimatedContainer(
          duration: Duration(milliseconds: 200 + (index * 100)),
          curve: Curves.easeOutCubic,
          child: _buildMedicationCard(_filteredMedications[index], index),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 80,
              color: AppColors.textTertiary,
            ),
            const SizedBox(height: 20),
            Text(
              'Aucun médicament trouvé',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Essayez de modifier vos critères de recherche',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Recherchez à nouveau',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMedicationCard(Medication medication, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 8),
            spreadRadius: 0,
          ),
        ],
        border: Border.all(
          color: Colors.grey.shade100,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 5,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _getCategoryColor(medication.category),
                  _getCategoryColor(medication.category).withOpacity(0.6),
                ],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            medication.name,
                            style: const TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            medication.genericName,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _getCategoryColor(medication.category).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(
                          color: _getCategoryColor(medication.category).withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        medication.category,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _getCategoryColor(medication.category),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _buildInfoGrid([
                  {'icon': Icons.medication_rounded, 'label': 'Forme', 'value': medication.form},
                  {'icon': Icons.business_rounded, 'label': 'Laboratoire', 'value': medication.laboratory},
                  {'icon': Icons.healing_rounded, 'label': 'Indication', 'value': medication.usage},
                  {'icon': Icons.schedule_rounded, 'label': 'Dosage', 'value': medication.dosage},
                ]),
                const SizedBox(height: 20),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.local_pharmacy_rounded,
                          size: 18,
                          color: Colors.grey.shade700,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Disponibilité en pharmacies:',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: medication.pharmacyStocks
                          .map((stock) => _buildPharmacyStatusChip(stock))
                          .toList(),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CustomButton(
                      text: 'Voir détails',
                      onPressed: () => _showMedicationDetails(medication),
                      backgroundColor: AppColors.primary,
                      textColor: AppColors.background,
                      width: 120,
                      height: 45,
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Prix indicatif',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Text(
                          medication.priceRange,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoGrid(List<Map<String, dynamic>> infos) {
    return Column(
      children: [
        for (int i = 0; i < infos.length; i += 2) ...[
          Row(
            children: [
              Expanded(
                child: _buildInfoItem(
                  infos[i]['icon'],
                  infos[i]['label'],
                  infos[i]['value'],
                ),
              ),
              if (i + 1 < infos.length) ...[
                const SizedBox(width: 16),
                Expanded(
                  child: _buildInfoItem(
                    infos[i + 1]['icon'],
                    infos[i + 1]['label'],
                    infos[i + 1]['value'],
                  ),
                ),
              ],
            ],
          ),
          if (i + 2 < infos.length) const SizedBox(height: 12),
        ],
      ],
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.textTertiary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.textTertiary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 16,
                color: AppColors.primary,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textPrimary,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'analgésiques':
        return AppColors.success;
      case 'antibiotiques':
        return AppColors.error;
      case 'antipaludéens':
        return AppColors.warning;
      case 'cardiovasculaires':
        return AppColors.secondaryDark;
      case 'respiratoires':
        return AppColors.secondary;
      case 'digestifs':
        return AppColors.primary;
      default:
        return AppColors.textTertiary;
    }
  }

  Widget _buildPharmacyStatusChip(PharmacyStock stock) {
    Color backgroundColor;
    Color textColor;
    Color dotColor;

    switch (stock.status) {
      case StockStatus.available:
        backgroundColor = AppColors.success.withOpacity(0.1);
        textColor = AppColors.success;
        dotColor = AppColors.success;
        break;
      case StockStatus.limited:
        backgroundColor = AppColors.warning.withOpacity(0.1);
        textColor = AppColors.warning;
        dotColor = AppColors.warning;
        break;
      case StockStatus.unavailable:
        backgroundColor = AppColors.error.withOpacity(0.1);
        textColor = AppColors.error;
        dotColor = AppColors.error;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: dotColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: dotColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                stock.pharmacyName,
                style: TextStyle(
                  color: textColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (stock.status != StockStatus.unavailable)
                Text(
                  '${stock.quantity} unités • ${stock.lastUpdated}',
                  style: TextStyle(
                    color: textColor.withOpacity(0.7),
                    fontSize: 10,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('${_medications.length}+', 'Médicaments\nréférencés'),
          _buildStatItem('25+', 'Pharmacies\npartenaires'),
          _buildStatItem('${_categories.length}', 'Catégories\nprincipales'),
          _buildStatItem('24/7', 'Mise à jour\nen temps réel'),
        ],
      ),
    );
  }

  Widget _buildStatItem(String number, String label) {
    return Column(
      children: [
        Text(
          number,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 11,
            color: AppColors.textSecondary,
            height: 1.2,
          ),
        ),
      ],
    );
  }

  void _showMedicationDetails(Medication medication) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(25),
              topRight: Radius.circular(25),
            ),
          ),
          child: Column(
            children: [
              Container(
                width: 50,
                height: 5,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.textTertiary,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(24),
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                medication.name,
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                medication.genericName,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: AppColors.textSecondary,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: _getCategoryColor(medication.category).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: _getCategoryColor(medication.category),
                            ),
                          ),
                          child: Text(
                            medication.category,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: _getCategoryColor(medication.category),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    _buildDetailSection('📋 Informations générales', [
                      {'label': 'Forme pharmaceutique', 'value': medication.form},
                      {'label': 'Laboratoire', 'value': medication.laboratory},
                      {'label': 'Dosage recommandé', 'value': medication.dosage},
                      {'label': 'Indication thérapeutique', 'value': medication.indication},
                    ]),
                    const SizedBox(height: 24),
                    _buildDetailSection('💊 Usage et posologie', [
                      {'label': 'Indications', 'value': medication.usage},
                      {'label': 'Prix indicatif', 'value': medication.priceRange},
                    ]),
                    const SizedBox(height: 24),
                    _buildPharmaciesSection(medication.pharmacyStocks),
                    const SizedBox(height: 32),
                    Row(
                      children: [
                        Expanded(
                          child: CustomButton(
                            text: 'Localiser pharmacies',
                            onPressed: () => _locatePharmacies(medication),
                            backgroundColor: AppColors.primary,
                            textColor: AppColors.surface,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: CustomButton(
                            text: 'Ajouter aux favoris',
                            onPressed: () => _addToFavorites(medication),
                            backgroundColor: AppColors.surface,
                            textColor: AppColors.primary,
                            borderColor: AppColors.primary,
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
      ),
    );
  }

  Widget _buildDetailSection(String title, List<Map<String, String>> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.textTertiary,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.textTertiary),
          ),
          child: Column(
            children: items
                .map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 100,
                    child: Text(
                      item['label']!,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      item['value']!,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ))
                .toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildPharmaciesSection(List<PharmacyStock> stocks) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '🏪 Disponibilité en pharmacies',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        ...stocks.map((stock) => Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.textTertiary),
            boxShadow: [
              BoxShadow(
                color: AppColors.textPrimary.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      stock.pharmacyName,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      stock.pharmacyLocation,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildStatusIndicator(stock.status),
                        const SizedBox(width: 12),
                        if (stock.status != StockStatus.unavailable) ...[
                          Text(
                            '${stock.quantity} unités',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '• Mis à jour il y a ${stock.lastUpdated}',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              CustomButton(
                text: 'Appeler',
                onPressed: () => _callPharmacy(stock),
                backgroundColor: AppColors.primary,
                textColor: AppColors.surface,
                width: 80,
                height: 36,
              ),
            ],
          ),
        )),
      ],
    );
  }

  Widget _buildStatusIndicator(StockStatus status) {
    String text;
    Color color;

    switch (status) {
      case StockStatus.available:
        text = 'Disponible';
        color = AppColors.success;
        break;
      case StockStatus.limited:
        text = 'Stock limité';
        color = AppColors.warning;
        break;
      case StockStatus.unavailable:
        text = 'Non disponible';
        color = AppColors.error;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  void _locatePharmacies(Medication medication) {
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Localisation des pharmacies pour ${medication.name}'),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  void _addToFavorites(Medication medication) {
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${medication.name} ajouté aux favoris'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  void _callPharmacy(PharmacyStock stock) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Appel de ${stock.pharmacyName}...'),
        backgroundColor: AppColors.error,
      ),
    );
  }
}