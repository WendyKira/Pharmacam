import 'package:flutter/material.dart';
import 'package:pharm/composants/custom_bottom.dart';
import 'package:pharm/utilitaires/apps_colors.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ListesPharmaciesPage extends StatefulWidget {
  const ListesPharmaciesPage({Key? key}) : super(key: key);

  @override
  State<ListesPharmaciesPage> createState() => _ListesPharmaciesPageState();
}

class _ListesPharmaciesPageState extends State<ListesPharmaciesPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showPharmacyDetails(BuildContext context, Pharmacy pharmacy) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => MedicamentsBottomSheet(pharmacy: pharmacy),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        title: const Text(
          'Gestion des Pharmacies',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorWeight: 3,
          tabs: const [
            Tab(text: 'Pharmacies Inscrites'),
            Tab(text: 'Pharmacies de Garde'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Pharmacies inscrites
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection("users")
                .where("role", isEqualTo: "Pharmacie")
                .where("statut", isEqualTo: "Actif")
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(child: Text("Aucune pharmacie inscrite"));
              }

              final pharmacies = snapshot.data!.docs.map((doc) {
                return Pharmacy(
                  id: doc.id.hashCode,
                  nom: doc['nom'] ?? "",
                  adresse: doc['adresse'] ?? "",
                  telephone: doc['telephone'] ?? "",
                  horaires: doc['horaires'] ?? "Non défini",
                  proprietaire: doc['responsable'] ?? "",
                  status: doc['statut'] ?? "inconnu",
                  medicaments: [], // ⚡ à remplir si tu ajoutes une sous-collection
                );
              }).toList();

              return PharmacyListView(
                pharmacies: pharmacies,
                isGuard: false,
                onPharmacyTap: (pharmacy) =>
                    _showPharmacyDetails(context, pharmacy),
              );
            },
          ),

          // Pharmacies de garde
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection("users")
                .where("role", isEqualTo: "Pharmacie")
                .where("statut", isEqualTo: "Garde")
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(child: Text("Aucune pharmacie de garde"));
              }

              final pharmacies = snapshot.data!.docs.map((doc) {
                return Pharmacy(
                  id: doc.id.hashCode,
                  nom: doc['nom'] ?? "",
                  adresse: doc['adresse'] ?? "",
                  telephone: doc['telephone'] ?? "",
                  horaires: doc['horaires'] ?? "Non défini",
                  proprietaire: doc['responsable'] ?? "",
                  status: "garde",
                  dateGarde: doc['date_garde'], // si tu stockes une période
                  medicaments: [],
                );
              }).toList();

              return PharmacyListView(
                pharmacies: pharmacies,
                isGuard: true,
                onPharmacyTap: (pharmacy) =>
                    _showPharmacyDetails(context, pharmacy),
              );
            },
          ),
        ],
      ),
    );
  }
}


class PharmacyListView extends StatelessWidget {
  final List<Pharmacy> pharmacies;
  final bool isGuard;
  final Function(Pharmacy) onPharmacyTap;

  const PharmacyListView({
    Key? key,
    required this.pharmacies,
    required this.isGuard,
    required this.onPharmacyTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [

        // Liste des pharmacies
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: pharmacies.length + (isGuard ? 1 : 0),
            itemBuilder: (context, index) {
              if (isGuard && index == pharmacies.length) {
                return _buildGuardInfoCard();
              }
              return PharmacyCard(
                pharmacy: pharmacies[index],
                isGuard: isGuard,
                onTap: () => onPharmacyTap(pharmacies[index]),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildGuardInfoCard() {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red[50],
        border: Border.all(color: Colors.red[200]!),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info, color: Colors.red[700]),
              const SizedBox(width: 8),
              Text(
                'Information importante',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.red[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Les pharmacies de garde sont disponibles 24h/24 ou durant les week-ends. '
                'Elles disposent de médicaments d\'urgence et peuvent facturer des frais '
                'supplémentaires pour les services de garde.',
            style: TextStyle(
              fontSize: 16,
              color: Colors.red[700],
            ),
          ),
        ],
      ),
    );
  }
}

class PharmacyCard extends StatelessWidget {
  final Pharmacy pharmacy;
  final bool isGuard;
  final VoidCallback onTap;

  const PharmacyCard({
    Key? key,
    required this.pharmacy,
    required this.isGuard,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isGuard ? Colors.red : AppColors.primary,
          width: 2,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En-tête avec nom et badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      pharmacy.nom,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  if (isGuard)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.red[100],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.shield, size: 16, color: Colors.red[600]),
                          const SizedBox(width: 4),
                          Text(
                            'DE GARDE',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.red[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),

              // Informations de la pharmacie
              _buildInfoRow(Icons.location_on, pharmacy.adresse),
              const SizedBox(height: 8),
              _buildInfoRow(Icons.phone, pharmacy.telephone),
              const SizedBox(height: 8),
              _buildInfoRow(Icons.access_time, pharmacy.horaires),

              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),

              // Propriétaire et date de garde
              Text(
                'Propriétaire: ${pharmacy.proprietaire}',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                ),
              ),
              if (isGuard && pharmacy.dateGarde != null) ...[
                const SizedBox(height: 4),
                Text(
                  'Période de garde: ${pharmacy.dateGarde}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.red[600],
                  ),
                ),
              ],

              const SizedBox(height: 16),

              // Bouton pour voir les médicaments
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'Cliquer pour voir les médicaments →',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isGuard ? Colors.red[600] : AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
            ),
          ),
        ),
      ],
    );
  }
}

class MedicamentsBottomSheet extends StatelessWidget {
  final Pharmacy pharmacy;

  const MedicamentsBottomSheet({
    Key? key,
    required this.pharmacy,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isGuard = pharmacy.status == 'garde';
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      height: screenHeight * 0.7,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(25),
        ),
      ),
      child: Column(
        children: [
          // Poignée de glissement
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[400],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // En-tête de la pharmacie
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: isGuard
                    ? [AppColors.secondary, AppColors.secondary] // ou les noms que vous avez définis
                    : [AppColors.primary, AppColors.primaryDark],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(25),
                topRight: Radius.circular(25),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        pharmacy.nom,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (isGuard)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.shield, size: 16, color: Colors.white),
                            const SizedBox(width: 4),
                            const Text(
                              'DE GARDE',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  pharmacy.adresse,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                ),
                if (isGuard && pharmacy.dateGarde != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Période de garde: ${pharmacy.dateGarde}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Contenu scrollable
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // En-tête des médicaments
                  Row(
                    children: [
                      Icon(
                        Icons.medication,
                        color: Colors.green[600],
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Médicaments disponibles (${pharmacy.medicaments.length})',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Grille des médicaments
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.85,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: pharmacy.medicaments.length,
                    itemBuilder: (context, index) {
                      return MedicamentCard(
                        medicament: pharmacy.medicaments[index],
                        isGuard: isGuard,
                      );
                    },
                  ),

                  const SizedBox(height: 24),

                  // Informations de contact
                  Card(
                    color: isGuard ? Colors.red[50] : Colors.blue[50],
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Informations de contact',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isGuard ? Colors.red[800] : Colors.blue[800],
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildContactInfo('Téléphone', pharmacy.telephone),
                          _buildContactInfo('Horaires', pharmacy.horaires),
                          _buildContactInfo('Propriétaire', pharmacy.proprietaire),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactInfo(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(fontSize: 14, color: Colors.black87),
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }
}

class MedicamentCard extends StatelessWidget {
  final Medicament medicament;
  final bool isGuard;

  const MedicamentCard({
    Key? key,
    required this.medicament,
    required this.isGuard,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final stockLevel = medicament.stock / 200;
    final isLowStock = medicament.stock < 50;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isGuard && medicament.urgence
              ? Colors.red[300]!
              : Colors.grey[300]!,
          width: isGuard && medicament.urgence ? 2 : 1,
        ),
      ),
      color: isGuard && medicament.urgence ? Colors.red[50] : Colors.grey[50],
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête avec nom et badge urgence
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    medicament.nom,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (isGuard && medicament.urgence)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      'URGENCE',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // Informations du médicament
            Text(
              'Stock: ${medicament.stock} unités',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.black87,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Prix: ${medicament.prix}',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.black87,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),

            // Barre de stock
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  height: 6,
                  decoration: BoxDecoration(
                    color: isLowStock ? Colors.red[200] : Colors.green[200],
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: stockLevel.clamp(0.0, 1.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isLowStock ? Colors.red : Colors.green,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isLowStock ? 'Stock faible' : 'Stock disponible',
                  style: TextStyle(
                    fontSize: 10,
                    color: isLowStock ? Colors.red[600] : Colors.green[600],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Modèles de données
class Pharmacy {
  final int id;
  final String nom;
  final String adresse;
  final String telephone;
  final String horaires;
  final String proprietaire;
  final String status;
  final String? dateGarde;
  final List<Medicament> medicaments;

  Pharmacy({
    required this.id,
    required this.nom,
    required this.adresse,
    required this.telephone,
    required this.horaires,
    required this.proprietaire,
    required this.status,
    this.dateGarde,
    required this.medicaments,
  });
}

class Medicament {
  final String nom;
  final int stock;
  final String prix;
  final bool urgence;

  Medicament({
    required this.nom,
    required this.stock,
    required this.prix,
    this.urgence = false,
  });
}