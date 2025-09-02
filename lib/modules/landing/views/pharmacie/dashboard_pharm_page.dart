import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../../composants/custom_bottom.dart';
import '../../../../utilitaires/apps_colors.dart';


import '../loginphar.dart'; // <-- import pour redirection

class PharmacieDashboardPage extends StatefulWidget {
  const PharmacieDashboardPage({Key? key}) : super(key: key);

  @override
  State<PharmacieDashboardPage> createState() => _PharmacieDashboardState();
}

class _PharmacieDashboardState extends State<PharmacieDashboardPage> {
  final TextEditingController _searchController = TextEditingController();
  int _selectedIndex = 0;

  String pharmacieEmail = "";
  String? pharmaciePhotoUrl;
  String? pharmacieName; // si tu stockes le nom dans Firestore

  @override
  void initState() {
    super.initState();
    _loadPharmacie();
  }

  /// Récupération des infos admin depuis Firebase
  Future<void> _loadPharmacie() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        pharmacieEmail = user.email ?? "Inconnu";
      });

      // Charger les infos supplémentaires depuis Firestorev
      DocumentSnapshot<Map<String, dynamic>> snapshot = await FirebaseFirestore.instance
          .collection("pharmacie")
          .doc(user.uid)
          .get();

      if (snapshot.exists) {
        setState(() {
          pharmaciePhotoUrl = snapshot.data()?["photoUrl"];
          pharmacieName = snapshot.data()?["name"];
        });
      }
    }
  }

  /// Sélectionner une nouvelle photo depuis la galerie et mettre à jour Firestore + Storage
  Future<void> _selectProfilePhoto() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      File file = File(pickedFile.path);

      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        try {
          // Upload vers Firebase Storage
          final ref = FirebaseStorage.instance.ref().child("pharmacie_profiles").child("${user.uid}.jpg");
          await ref.putFile(file);

          String downloadUrl = await ref.getDownloadURL();

          // Mise à jour Firestore
          await FirebaseFirestore.instance.collection("pharmacie").doc(user.uid).update({
            "photoUrl": downloadUrl,
          });

          setState(() {
            pharmaciePhotoUrl = downloadUrl;
          });
        } catch (e) {
          debugPrint("Erreur upload photo: $e");
        }
      }
    }
  }


  /// Supprimer photo de profil
  Future<void> _removeProfilePhoto() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance.collection("pharmacie").doc(user.uid).update({
        "photoUrl": FieldValue.delete(),
      });
      setState(() {
        pharmaciePhotoUrl = null;
      });
    }
  }

  /// Déconnexion (confirmation + redirection vers la page de login en vidant l'historique)
  Future<void> _handleLogout(BuildContext context) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Déconnexion'),
        content: const Text('Êtes-vous sûr de vouloir vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          CustomButton(
            text: 'Déconnexion',
            onPressed: () async {
              Navigator.pop(context); // ferme la boîte de dialogue
              await FirebaseAuth.instance.signOut();

              if (mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const LoginPharPage(), // redirection vers login
                  ),
                      (route) => false, // supprime tout l'historique de navigation
                );
              }
            },
            backgroundColor: Colors.red,
          ),
        ],
      ),
    );
  }

  /// Initiales à partir du nom ou email
  String _getInitials() {
    if (pharmacieName != null && pharmacieName!.isNotEmpty) {
      List<String> parts = pharmacieName!.split(" ");
      if (parts.length >= 2) {
        return "${parts[0][0].toUpperCase()}${parts[1][0].toUpperCase()}";
      } else {
        return pharmacieName!.substring(0, 2).toUpperCase();
      }
    }
    if (pharmacieEmail.isNotEmpty) {
      String name = pharmacieEmail.split('@')[0];
      return name.length >= 2 ? name.substring(0, 2).toUpperCase() : name.toUpperCase();
    }
    return "AD";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        children: [
          // Sidebar
          Container(
            width: 280,
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(2, 0),
                ),
              ],
            ),
            child: _buildSidebar(),
          ),
          // Main Content
          Expanded(
            child: Column(
              children: [
                _buildHeader(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    return Column(
      children: [
        const SizedBox(height: 20),
        // Profil Pharmacie
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: GestureDetector(
            onTap: _handleProfilePhotoChange,
            child: Row(
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: AppColors.primary,
                      backgroundImage: pharmaciePhotoUrl != null ? NetworkImage(pharmaciePhotoUrl!) : null,
                      child: pharmaciePhotoUrl == null
                          ? Text(
                        _getInitials(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      )
                          : null,
                    ),
                    Positioned(
                      bottom: -2,
                      right: -2,
                      child: Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(Icons.edit, color: Colors.white, size: 8),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pharmacieEmail,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Pharmacie',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),

        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: [
              _buildMenuItem(0, Icons.dashboard_outlined, 'Dashboard'),
              _buildMenuItem(1, Icons.list, ' Listes des produits '),
              _buildMenuItem(2, Icons.shopping_cart, ' Listes des commandes '),
              _buildMenuItem(3, Icons.hourglass_bottom_outlined, ' Pharmacies de garde '),
              _buildMenuItem(4, Icons.smart_toy, ' Assistant IA '),
              _buildMenuItem(6, Icons.settings_outlined, 'Paramètres'),
            ],
          ),
        ),

        Container(
          padding: const EdgeInsets.all(16),
          child: CustomButton(
            text: 'Déconnexion',
            onPressed: () => _handleLogout(context),
            backgroundColor: Colors.red.shade50,
            textColor: Colors.red,
            icon: Icons.logout,
          ),
        ),
      ],
    );
  }

  Widget _buildMenuItem(int index, IconData icon, String title) {
    final isSelected = _selectedIndex == index;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: ListTile(
        leading: Icon(
          icon,
          color: isSelected ? AppColors.primary : Colors.grey.shade600,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isSelected ? AppColors.primary : Colors.grey.shade700,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        selected: isSelected,
        selectedTileColor: AppColors.primary.withOpacity(0.08),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        onTap: () {
          setState(() {
            _selectedIndex = index;
          });
          // Redirection vers les pages correspondantes
          switch (index) {
            case 0:
              Navigator.pushNamed(context, '/dashboard');
              break;
            case 1:
              Navigator.pushNamed(context, '/listes_produits');
              break;
            case 2:
              Navigator.pushNamed(context, '/listes_commandes');
              break;
            case 3:
              Navigator.pushNamed(context, '/pharmacies_garde');
              break;
            case 4:
              Navigator.pushNamed(context, '/assistants_IA');
              break;
            case 6:
              Navigator.pushNamed(context, '/parametres');
              break;
          }
        },
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Row(
          children: [
            const Spacer(),

            Container(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.local_pharmacy,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'PHARMACAM',
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Notifications
          ],
        ),
      ),
    );
  }

  /// Gestion du choix photo
  void _handleProfilePhotoChange() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Photo de profil'),
        content: const Text('Choisir une nouvelle photo de profil'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          CustomButton(
            text: 'Galerie',
            onPressed: () {
              Navigator.pop(context);
              _selectProfilePhoto();
            },
            backgroundColor: AppColors.primary,
          ),
          if (pharmaciePhotoUrl != null)
            CustomButton(
              text: 'Supprimer',
              onPressed: () {
                Navigator.pop(context);
                _removeProfilePhoto();
              },
              backgroundColor: Colors.red,
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
