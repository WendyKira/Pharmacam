
// lib/services/firebase_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../modules/produits_models.dart';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Collection de produits
  CollectionReference get _produitsCollection =>
      _firestore.collection('produits');

  // Collection des pharmacies
  CollectionReference get _pharmaciesCollection =>
      _firestore.collection('pharmacies');

  // Ajouter un produit
  Future<String> ajouterProduit(ProduitModel produit) async {
    try {
      DocumentReference docRef = await _produitsCollection.add(produit.toMap());
      return docRef.id;
    } catch (e) {
      throw Exception('Erreur lors de l\'ajout du produit: $e');
    }
  }

  // Récupérer tous les produits
  Stream<List<ProduitModel>> obtenirProduits() {
    return _produitsCollection
        .orderBy('dateAjout', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ProduitModel.fromMap(
          doc.data() as Map<String, dynamic>,
          doc.id
      ))
          .toList();
    });
  }

  // Supprimer un produit
  Future<void> supprimerProduit(String produitId) async {
    try {
      await _produitsCollection.doc(produitId).delete();
    } catch (e) {
      throw Exception('Erreur lors de la suppression: $e');
    }
  }

  // Mettre à jour un produit
  Future<void> mettreAJourProduit(String produitId, ProduitModel produit) async {
    try {
      await _produitsCollection.doc(produitId).update(produit.toMap());
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour: $e');
    }
  }

  // Récupérer le nom de la pharmacie connectée
  Future<String> obtenirNomPharmacie() async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        DocumentSnapshot pharmacieDoc =
        await _pharmaciesCollection.doc(user.uid).get();

        if (pharmacieDoc.exists) {
          Map<String, dynamic> data = pharmacieDoc.data() as Map<String, dynamic>;
          return data['nom'] ?? 'Pharmacie';
        }
      }
      return 'Pharmacie';
    } catch (e) {
      return 'Pharmacie';
    }
  }
}