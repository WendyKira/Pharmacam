import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pharm/composants/custom_bottom.dart';
import 'package:pharm/utilitaires/apps_colors.dart';

class ListesMedicamentsPage extends StatefulWidget {
  @override
  _ListesMedicamentsPageState createState() => _ListesMedicamentsPageState();
}

class _ListesMedicamentsPageState extends State<ListesMedicamentsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Pharmacies & Produits',
          style: TextStyle(
            color: AppColors.surface,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.primaryLight,
        elevation: 0,
        iconTheme: IconThemeData(color: AppColors.surface),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .where('role', isEqualTo: 'Pharmacie')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
                child: CircularProgressIndicator(color: AppColors.primaryLight));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text("Aucune pharmacie trouvée"));
          }

          var pharmacies = snapshot.data!.docs;

          return ListView.separated(
            padding: EdgeInsets.all(16),
            itemCount: pharmacies.length,
            separatorBuilder: (context, index) => SizedBox(height: 12),
            itemBuilder: (context, index) {
              var pharmacie = pharmacies[index];
              String nom = pharmacie['nom'];
              String adresse = pharmacie['adresse'];
              String horaires = pharmacie['horaires'];

              // Récupérer un produit de la sous-collection "produits"
              return FutureBuilder<QuerySnapshot>(
                future: pharmacie.reference
                    .collection('produits')
                    .limit(1)
                    .get(), // juste un produit pour aperçu
                builder: (context, produitSnapshot) {
                  String? produitname;
                  int? price;

                  if (produitSnapshot.hasData &&
                      produitSnapshot.data!.docs.isNotEmpty) {
                    var produit = produitSnapshot.data!.docs.first;
                    produitname = produit['name'];
                    price = produit['price'];
                  }

                  return _buildPharmacyCard(
                    nom: nom,
                    adresse: adresse,
                    horaires: horaires,
                    produit: produitname != null ? "$produitname - $price" : null,
                    onVoirPlus: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ListeProduitsPage(
                            pharmacieRef: pharmacie.reference,
                            pharmacieNom: nom,
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildPharmacyCard({
    required String nom,
    required String adresse,
    required String horaires,
    String? produit,
    required VoidCallback onVoirPlus,
  }) {
    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("⭐ Produit en vitrine : $produit",
              style: TextStyle(color: AppColors.primaryLight)),
          SizedBox(height: 12),
          if (produit != null)
            Text(nom,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary)),
          SizedBox(height: 4),
          Text("📍 $adresse", style: TextStyle(color: AppColors.textSecondary)),
          SizedBox(height: 4),
          Text("🕒 $horaires", style: TextStyle(color: AppColors.textSecondary)),
          SizedBox(height: 8),
          CustomButton(text: "Voir plus", onPressed: onVoirPlus),
        ],
      ),
    );
  }
}

class ListeProduitsPage extends StatelessWidget {
  final DocumentReference pharmacieRef;
  final String pharmacieNom;

  ListeProduitsPage({required this.pharmacieRef, required this.pharmacieNom});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text("Produits - $pharmacieNom"),
        backgroundColor: AppColors.primaryLight,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: pharmacieRef.collection('produits').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return Center(child: CircularProgressIndicator());

          var produits = snapshot.data!.docs;

          return ListView.separated(
            padding: EdgeInsets.all(16),
            itemCount: produits.length,
            separatorBuilder: (context, index) => SizedBox(height: 12),
            itemBuilder: (context, index) {
              var produit = produits[index];
              return Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(produit['nom'],
                        style: TextStyle(
                            fontSize: 40, fontWeight: FontWeight.bold)),
                    SizedBox(height: 4),
                    Text("💊 Format: ${produit['format']}"),
                    Text("📦 Conditionnement: ${produit['conditionnement']}"),
                    SizedBox(height: 4),
                    Text("💵 Prix: ${produit['prix']}",
                        style: TextStyle(color: AppColors.primaryLight)),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
