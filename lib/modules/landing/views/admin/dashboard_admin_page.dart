import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import '../../../../composants/custom_bottom.dart';
import '../../../../utilitaires/apps_colors.dart';
import '../loginphar.dart'; // ✅ import de la page login

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({Key? key}) : super(key: key);

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboardPage> {
  final TextEditingController _searchController = TextEditingController();
  int _selectedIndex = 0;

  String adminEmail = "";
  String? adminPhotoUrl;
  String? adminName; // si tu stockes le nom dans Firestore

  @override
  void initState() {
    super.initState();
    _loadAdminData();
  }

  /// Récupération des infos admin depuis Firebase
  Future<void> _loadAdminData() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        adminEmail = user.email ?? "Inconnu";
      });

      // Charger les infos supplémentaires depuis Firestore
      DocumentSnapshot<Map<String, dynamic>> snapshot =
      await FirebaseFirestore.instance.collection("admins").doc(user.uid).get();

      if (snapshot.exists) {
        setState(() {
          adminPhotoUrl = snapshot.data()?["photoUrl"];
          adminName = snapshot.data()?["name"];
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
          final ref =
          FirebaseStorage.instance.ref().child("admin_profiles").child("${user.uid}.jpg");
          await ref.putFile(file);

          String downloadUrl = await ref.getDownloadURL();

          await FirebaseFirestore.instance.collection("admins").doc(user.uid).update({
            "photoUrl": downloadUrl,
          });

          setState(() {
            adminPhotoUrl = downloadUrl;
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
      await FirebaseFirestore.instance.collection("admins").doc(user.uid).update({
        "photoUrl": FieldValue.delete(),
      });
      setState(() {
        adminPhotoUrl = null;
      });
    }
  }

  /// Déconnexion
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
                    builder: (_) => const LoginPharPage(), // ✅ redirection login
                  ),
                      (route) => false, // supprime tout l’historique
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
    if (adminName != null && adminName!.isNotEmpty) {
      List<String> parts = adminName!.split(" ");
      if (parts.length >= 2) {
        return "${parts[0][0].toUpperCase()}${parts[1][0].toUpperCase()}";
      } else {
        return adminName!.substring(0, 2).toUpperCase();
      }
    }
    if (adminEmail.isNotEmpty) {
      String name = adminEmail.split('@')[0];
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
        // Profil Admin
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
                      backgroundImage: adminPhotoUrl != null ? NetworkImage(adminPhotoUrl!) : null,
                      child: adminPhotoUrl == null
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
                        adminEmail,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Administrateur',
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
              _buildMenuItem(1, Icons.people_outline, 'Gestion Utilisateurs'),
              _buildMenuItem(2, Icons.campaign_outlined, 'Gestion Annonces'),
              _buildMenuItem(3, Icons.notifications_outlined, 'Notifications'),
              _buildMenuItem(6, Icons.settings_outlined, 'Paramètres'),
            ],
          ),
        ),

        Container(
          padding: const EdgeInsets.all(16),
          child: CustomButton(
            text: 'Déconnexion',
            onPressed: () => _handleLogout(context), // ✅ utilise la nouvelle logique
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
          switch (index) {
            case 0:
              Navigator.pushNamed(context, '/dashboard');
              break;
            case 1:
              Navigator.pushNamed(context, '/gestion_utilisateurs');
              break;
            case 2:
              Navigator.pushNamed(context, '/gestion_annonces');
              break;
            case 3:
              Navigator.pushNamed(context, '/notifications');
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
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'PHARMACAM',
                    style: TextStyle(
                      fontSize: 35,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            IconButton(
              onPressed: () {},
              icon: Stack(
                children: [
                  Icon(Icons.notifications_outlined, color: Colors.grey.shade600),
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
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
          if (adminPhotoUrl != null)
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
