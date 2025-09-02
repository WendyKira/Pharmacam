import 'package:flutter/material.dart';
import 'package:pharm/composants/custom_bottom.dart';
import 'package:pharm/utilitaires/apps_colors.dart';

class ListesMedicamentsPage extends StatefulWidget {
  @override
  _ListesMedicamentsPageState createState() => _ListesMedicamentsPageState();
}

class _ListesMedicamentsPageState extends State<ListesMedicamentsPage> {
  List<Medicine> medicines = [
    Medicine(
      name: "Paracétamol 500mg",
      price: "750 FCFA",
      isAvailable: true,
      description: "Antalgique et antipyrétique utilisé pour traiter la douleur et la fièvre. Boîte de 20 comprimés.",
      pharmacies: ["Pharmacie du Centre", "Pharmacie de la Paix", "Pharmacie Moderne"],
      manufacturer: "Laboratoires CIPLA",
      dosage: "500mg par comprimé",
      indication: "Douleurs légères à modérées, fièvre",
    ),
    Medicine(
      name: "Amoxicilline 500mg",
      price: "2.500 FCFA",
      isAvailable: true,
      description: "Antibiotique à large spectre de la famille des pénicillines. Boîte de 12 gélules.",
      pharmacies: ["Pharmacie Centrale", "Pharmacie du Marché"],
      manufacturer: "GSK Cameroun",
      dosage: "500mg par gélule",
      indication: "Infections bactériennes",
    ),
    Medicine(
      name: "Doliprane 1000mg",
      price: "1.200 FCFA",
      isAvailable: false,
      description: "Paracétamol dosé à 1000mg pour adultes. Boîte de 8 comprimés effervescents.",
      pharmacies: [],
      manufacturer: "Sanofi",
      dosage: "1000mg par comprimé",
      indication: "Douleurs intenses, fièvre forte",
    ),
    Medicine(
      name: "Aspirine 500mg",
      price: "650 FCFA",
      isAvailable: true,
      description: "Anti-inflammatoire non stéroïdien (AINS). Boîte de 20 comprimés.",
      pharmacies: ["Pharmacie du Centre", "Pharmacie Moderne", "Pharmacie de l'Espoir"],
      manufacturer: "Bayer",
      dosage: "500mg par comprimé",
      indication: "Douleurs, inflammation, fièvre",
    ),
    Medicine(
      name: "Vitamine C 1000mg",
      price: "3.500 FCFA",
      isAvailable: true,
      description: "Complément alimentaire en vitamine C. Boîte de 30 comprimés effervescents.",
      pharmacies: ["Pharmacie Centrale", "Pharmacie de la Santé"],
      manufacturer: "Upsa Cameroun",
      dosage: "1000mg par comprimé",
      indication: "Carence en vitamine C, fatigue",
    ),
    Medicine(
      name: "Ibuprofen 400mg",
      price: "1.800 FCFA",
      isAvailable: true,
      description: "Anti-inflammatoire non stéroïdien. Boîte de 20 comprimés pelliculés.",
      pharmacies: ["Pharmacie du Centre", "Pharmacie Moderne"],
      manufacturer: "Pfizer Cameroun",
      dosage: "400mg par comprimé",
      indication: "Douleurs, inflammation",
    ),
    Medicine(
      name: "Sirop contre la toux",
      price: "2.200 FCFA",
      isAvailable: false,
      description: "Sirop expectorant pour toux grasse. Flacon de 125ml avec gobelet doseur.",
      pharmacies: [],
      manufacturer: "Laboratoires Biogaran",
      dosage: "15ml, 3 fois par jour",
      indication: "Toux productive",
    ),
    Medicine(
      name: "Oméprazole 20mg",
      price: "4.500 FCFA",
      isAvailable: true,
      description: "Inhibiteur de la pompe à protons. Boîte de 14 gélules gastro-résistantes.",
      pharmacies: ["Pharmacie Centrale", "Pharmacie de la Paix"],
      manufacturer: "Mylan Cameroun",
      dosage: "20mg par gélule",
      indication: "Ulcères, reflux gastro-œsophagien",
    ),
    Medicine(
      name: "Loratadine 10mg",
      price: "2.800 FCFA",
      isAvailable: true,
      description: "Antihistaminique non sédatif. Boîte de 10 comprimés.",
      pharmacies: ["Pharmacie du Marché", "Pharmacie de l'Espoir"],
      manufacturer: "Teva Cameroun",
      dosage: "10mg par comprimé",
      indication: "Allergies, rhinite allergique",
    ),
    Medicine(
      name: "Metformine 850mg",
      price: "3.200 FCFA",
      isAvailable: true,
      description: "Antidiabétique oral. Boîte de 30 comprimés pelliculés sécables.",
      pharmacies: ["Pharmacie Centrale", "Pharmacie de la Santé", "Pharmacie Moderne"],
      manufacturer: "Merck Cameroun",
      dosage: "850mg par comprimé",
      indication: "Diabète de type 2",
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Médicaments publics',
          style: TextStyle(
            color: AppColors.surface,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.primaryLight,
        elevation: 0,
        iconTheme: IconThemeData(color: AppColors.surface),
      ),
      body: SingleChildScrollView(
        physics: BouncingScrollPhysics(),
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête avec statistiques
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.textTertiary.withOpacity(0.1),
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatCard("Total", "${medicines.length}", AppColors.success),
                  Container(width: 1, height: 40, color: AppColors.textTertiary.withOpacity(0.3)),
                  _buildStatCard("Disponibles", "${medicines.where((m) => m.isAvailable).length}", AppColors.success),
                  Container(width: 1, height: 40, color: AppColors.textTertiary.withOpacity(0.3)),
                  _buildStatCard("Rupture", "${medicines.where((m) => !m.isAvailable).length}", AppColors.success),
                ],
              ),
            ),

            SizedBox(height: 20),

            Text(
              'Médicaments disponibles',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),

            SizedBox(height: 12),

            // Liste des médicaments
            ListView.separated(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: medicines.length,
              separatorBuilder: (context, index) => SizedBox(height: 12),
              itemBuilder: (context, index) {
                return _buildMedicineCard(medicines[index]);
              },
            ),

            SizedBox(height: 100), // Espace pour éviter le chevauchement
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textTertiary,
          ),
        ),
      ],
    );
  }

  Widget _buildMedicineCard(Medicine medicine) {
    return GestureDetector(
      onTap: () => _showMedicineDetails(medicine),
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: medicine.isAvailable
                ? AppColors.success.withOpacity(0.3)
                : AppColors.error.withOpacity(0.3),
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.textTertiary.withOpacity(0.1),
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Icône du médicament
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: medicine.isAvailable
                    ? AppColors.success.withOpacity(0.1)
                    : AppColors.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.medication,
                color: medicine.isAvailable ? AppColors.success : AppColors.error,
                size: 24,
              ),
            ),

            SizedBox(width: 16),

            // Informations du médicament
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    medicine.name,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    medicine.price,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryLight,
                    ),
                  ),
                  SizedBox(height: 4),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: medicine.isAvailable
                          ? AppColors.success.withOpacity(0.1)
                          : AppColors.error.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      medicine.isAvailable ? 'Disponible' : 'Rupture de stock',
                      style: TextStyle(
                        fontSize: 12,
                        color: medicine.isAvailable ? AppColors.error : AppColors.surfaceSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Flèche
            Icon(
              Icons.arrow_forward_ios,
              color: AppColors.textTertiary,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  void _showMedicineDetails(Medicine medicine) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SingleChildScrollView(
            controller: scrollController,
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Indicateur de glissement
                Center(
                  child: Container(
                    width: 20,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.textTertiary.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                SizedBox(height: 20),

                // En-tête du médicament
                Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: medicine.isAvailable
                            ? AppColors.success.withOpacity(0.1)
                            : AppColors.error.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.medication_liquid,
                        color: medicine.isAvailable ? AppColors.success : AppColors.error,
                        size: 30,
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            medicine.name,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            medicine.price,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primaryLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 24),

                // Statut de disponibilité
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: medicine.isAvailable
                        ? AppColors.success.withOpacity(0.1)
                        : AppColors.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        medicine.isAvailable ? Icons.check_circle : Icons.cancel,
                        color: medicine.isAvailable ? AppColors.success : AppColors.error,
                      ),
                      SizedBox(width: 8),
                      Text(
                        medicine.isAvailable ? 'Médicament disponible' : 'Rupture de stock',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: medicine.isAvailable ? AppColors.success : AppColors.error,
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 20),

                // Description
                _buildDetailSection("Description", medicine.description),
                _buildDetailSection("Fabricant", medicine.manufacturer),
                _buildDetailSection("Dosage", medicine.dosage),
                _buildDetailSection("Indication", medicine.indication),

                // Pharmacies disponibles
                if (medicine.isAvailable && medicine.pharmacies.isNotEmpty) ...[
                  SizedBox(height: 16),
                  Text(
                    'Pharmacies disponibles',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 8),
                  ...medicine.pharmacies.map((pharmacy) => Container(
                    margin: EdgeInsets.only(bottom: 8),
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.textTertiary.withOpacity(0.2)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.local_pharmacy, color: AppColors.secondaryLight, size: 20),
                        SizedBox(width: 8),
                        Text(
                          pharmacy,
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  )).toList(),
                ],

                SizedBox(height: 30),

                // Bouton Commander
                if (medicine.isAvailable)
                  CustomButton(
                    text: 'Commander ce médicament',
                    onPressed: () {
                      Navigator.pop(context);
                      _showOrderConfirmation(medicine);
                    },
                  )
                else
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.textTertiary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Médicament indisponible',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: AppColors.textTertiary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),

                SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailSection(String title, String content) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          SizedBox(height: 4),
          Text(
            content,
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  void _showOrderConfirmation(Medicine medicine) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(
          'Commande confirmée',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Votre commande pour ${medicine.name} a été ajoutée au panier.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          CustomButton(
            text: 'OK',
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}

class Medicine {
  final String name;
  final String price;
  final bool isAvailable;
  final String description;
  final List<String> pharmacies;
  final String manufacturer;
  final String dosage;
  final String indication;

  Medicine({
    required this.name,
    required this.price,
    required this.isAvailable,
    required this.description,
    required this.pharmacies,
    required this.manufacturer,
    required this.dosage,
    required this.indication,
  });
}