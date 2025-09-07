import 'package:flutter/material.dart';
import 'package:pharm/composants/custom_bottom.dart';
import 'package:pharm/utilitaires/apps_colors.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart'; // ✅ pour lancer les appels
import 'package:pharm/modules/landing/views/patient/modepaiement_page.dart';

// 🆕 Import de la page de mode de paiement

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
      isDismissible: true,
      enableDrag: true,
      builder: (context) => MedicamentsBottomSheet(pharmacy: pharmacy),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1E293B),
        elevation: 0,
        title: const Text(
          'Pharmacies',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1E293B),
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: AppColors.primary,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              indicatorPadding: const EdgeInsets.all(2),
              labelColor: Colors.white,
              unselectedLabelColor: const Color(0xFF64748B),
              labelStyle: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
              unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
              tabs: const [
                Tab(text: 'Toutes les Pharmacies'),
                Tab(text: 'Pharmacies de Garde'),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // ====== Pharmacies inscrites (users) ======
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection("users")
                .where("role", isEqualTo: "Pharmacie")
                .where("statut", isEqualTo: "Actif")
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(strokeWidth: 3),
                      SizedBox(height: 16),
                      Text(
                        'Chargement des pharmacies...',
                        style: TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                );
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.local_pharmacy_outlined,
                        size: 64,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        "Aucune pharmacie inscrite",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                );
              }

              final pharmacies = snapshot.data!.docs.map((doc) {
                return Pharmacy(
                  id: doc.id.hashCode,
                  docId: doc.id,
                  nom: doc['nom'] ?? "",
                  adresse: doc['adresse'] ?? "",
                  telephone: doc['numeroDurgence'] ?? "", // 🔥 mis à jour
                  horaires: doc['horaires'] ?? "Non défini",
                  proprietaire: doc['responsable'] ?? "",
                  status: doc['statut'] ?? "inconnu",
                  medicaments: [],
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

          // ====== Pharmacies de garde (gardes) ======
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection("gardes").snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(strokeWidth: 3),
                      SizedBox(height: 16),
                      Text(
                        'Chargement des pharmacies de garde...',
                        style: TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                );
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.local_hospital_outlined,
                        size: 64,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        "Aucune pharmacie de garde",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                );
              }

              final pharmacies = snapshot.data!.docs.map((doc) {
                return Pharmacy(
                  id: doc.id.hashCode,
                  docId: doc.id,
                  nom: doc['nom'] ?? "",
                  adresse: doc['adresse'] ?? "",
                  telephone: doc['numeroDurgence'] ?? "",
                  horaires: doc['horaires'] ?? "Non défini",
                  proprietaire: doc['responsable'] ?? "",
                  status: "garde",
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

// ========== Widgets réutilisables ==========
class PharmacyListView extends StatelessWidget {
  final List<Pharmacy> pharmacies;
  final bool isGuard;
  final void Function(Pharmacy) onPharmacyTap;

  const PharmacyListView({
    Key? key,
    required this.pharmacies,
    required this.isGuard,
    required this.onPharmacyTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: pharmacies.length,
      itemBuilder: (context, index) {
        final pharmacy = pharmacies[index];
        return PharmacyCard(
          pharmacy: pharmacy,
          isGuard: isGuard,
          onTap: () => onPharmacyTap(pharmacy),
        );
      },
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
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isGuard
                            ? const Color(0xFFEF4444).withOpacity(0.1)
                            : AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        isGuard ? Icons.local_hospital : Icons.local_pharmacy,
                        color:
                        isGuard ? const Color(0xFFEF4444) : AppColors.primary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            pharmacy.nom,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          const SizedBox(height: 4),
                          if (isGuard)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEF4444),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'PHARMACIE DE GARDE',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.grey[400],
                      size: 16,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      color: Colors.grey[500],
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        pharmacy.adresse,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.access_time_outlined,
                      color: Colors.grey[500],
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      pharmacy.horaires,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ========== BottomSheet Médicaments ==========
class MedicamentsBottomSheet extends StatelessWidget {
  final Pharmacy pharmacy;

  const MedicamentsBottomSheet({
    Key? key,
    required this.pharmacy,
  }) : super(key: key);

  // ✅ Correction : récupération de numeroDurgence depuis Firestore
  Future<void> _callPharmacy(String docId, BuildContext context) async {
    try {
      final snapshot =
      await FirebaseFirestore.instance.collection('users').doc(docId).get();

      if (!snapshot.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Pharmacie introuvable")),
        );
        return;
      }

      final data = snapshot.data() as Map<String, dynamic>;
      final String numeroDurgence = data['numeroDurgence'] ?? '';

      if (numeroDurgence.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Numéro d'urgence non défini")),
        );
        return;
      }

      final Uri callUri = Uri(scheme: "tel", path: numeroDurgence);
      if (await canLaunchUrl(callUri)) {
        await launchUrl(callUri);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Impossible de lancer l'appel")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isGuard = pharmacy.status == 'garde';
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      height: screenHeight * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: isGuard
                  ? const Color(0xFFEF4444).withOpacity(0.05)
                  : AppColors.primary.withOpacity(0.05),
              border: Border(
                bottom: BorderSide(
                  color: Colors.grey.withOpacity(0.1),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isGuard
                        ? const Color(0xFFEF4444).withOpacity(0.1)
                        : AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.medication_outlined,
                    color: isGuard ? const Color(0xFFEF4444) : AppColors.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pharmacy.nom,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Médicaments disponibles',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ✅ Bouton contacter (modifié)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton.icon(
              onPressed: () => _callPharmacy(pharmacy.docId, context), // 🔥
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              icon: const Icon(Icons.phone, color: Colors.white),
              label: const Text(
                "Contacter",
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          ),

          // Liste des médicaments ACTIFS uniquement
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(pharmacy.docId)
                  .collection('produits')
                  .where('isActive', isEqualTo: true) // 🔥 NOUVEAU FILTRE
                  .snapshots(),
              builder: (context, medsSnap) {
                if (medsSnap.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(strokeWidth: 3),
                  );
                }
                if (!medsSnap.hasData || medsSnap.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.medication_outlined,
                            size: 64, color: Colors.grey),
                        const SizedBox(height: 16),
                        const Text(
                          "Aucun médicament disponible",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final produitsDocs = medsSnap.data!.docs;
                final meds = produitsDocs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final nom = data['name'] ?? "";
                  final format = data['format'] ?? "";
                  final conditionnement = data['conditionnement'] ?? "";
                  final prix = data['price'] ?? 0;
                  final urgence = data['urgence'] ?? false;

                  final displayNom = [nom, format, conditionnement]
                      .where((e) => e.toString().trim().isNotEmpty)
                      .join(" — ");

                  return MedicamentData(
                    id: doc.id,
                    nom: displayNom,
                    prix: prix,
                    urgence: urgence,
                    pharmacyDocId: pharmacy.docId,
                  );
                }).toList();

                return ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: meds.length,
                  itemBuilder: (context, index) {
                    return MedicamentCard(
                      medicament: meds[index],
                      isGuard: isGuard,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class MedicamentCard extends StatelessWidget {
  final MedicamentData medicament;
  final bool isGuard;

  const MedicamentCard({
    Key? key,
    required this.medicament,
    required this.isGuard,
  }) : super(key: key);

  void _handleOrder(BuildContext context, MedicamentData medicament) {
    // Animation de feedback
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              Icons.check_circle,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Commande ajoutée : ${medicament.nom}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );

    // Ici vous pouvez ajouter votre logique de commande
    // Par exemple : ajouter au panier, envoyer à Firestore, etc.
    print('Commander: ${medicament.nom} - ${medicament.prix} FCFA');
    print('Pharmacy ID: ${medicament.pharmacyDocId}');
    print('Product ID: ${medicament.id}');
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isGuard
              ? const Color(0xFFEF4444).withOpacity(0.1)
              : Colors.grey.withOpacity(0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
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
                        medicament.nom,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${medicament.prix} FCFA',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                if (isGuard && medicament.urgence)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'URGENT',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            // 🆕 Bouton Commander soft
            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                onPressed: () => _handleOrder(context, medicament),
                style: TextButton.styleFrom(
                  backgroundColor: isGuard
                      ? const Color(0xFFEF4444).withOpacity(0.08)
                      : AppColors.primary.withOpacity(0.08),
                  foregroundColor: isGuard
                      ? const Color(0xFFEF4444)
                      : AppColors.primary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: isGuard
                          ? const Color(0xFFEF4444).withOpacity(0.2)
                          : AppColors.primary.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                ),
                icon: Icon(
                  Icons.shopping_cart_outlined,
                  size: 18,
                  color: isGuard
                      ? const Color(0xFFEF4444)
                      : AppColors.primary,
                ),
                label: Text(
                  'Commander',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isGuard
                        ? const Color(0xFFEF4444)
                        : AppColors.primary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ====== Models ======

class Pharmacy {
  final int id;
  final String docId;
  final String nom;
  final String adresse;
  final String telephone;
  final String horaires;
  final String proprietaire;
  final String status;
  final List<Medicament> medicaments;

  Pharmacy({
    required this.id,
    required this.docId,
    required this.nom,
    required this.adresse,
    required this.telephone,
    required this.horaires,
    required this.proprietaire,
    required this.status,
    required this.medicaments,
  });
}

class Medicament {
  final String nom;
  final String prix;
  final bool urgence;

  Medicament({
    required this.nom,
    required this.prix,
    this.urgence = false,
  });
}

// 🆕 Nouveau modèle pour les données complètes du médicament
class MedicamentData {
  final String id;
  final String nom;
  final int prix;
  final bool urgence;
  final String pharmacyDocId;

  MedicamentData({
    required this.id,
    required this.nom,
    required this.prix,
    required this.pharmacyDocId,
    this.urgence = false,
  });
}