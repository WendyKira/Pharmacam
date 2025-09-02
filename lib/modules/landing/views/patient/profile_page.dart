import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pharm/composants/custom_bottom.dart';
import 'package:pharm/utilitaires/apps_colors.dart';
import 'dart:io';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePharmPageState();
}

class _ProfilePharmPageState extends State<ProfilePage> {
  final _formKey = GlobalKey<FormState>();
  bool _isEditing = false;
  bool _isLoading = false;

  // Controllers
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _numeroController;

  // Firebase
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Profile image
  File? _profileImageFile;
  String? _profileImageUrl;

  // User data
  Map<String, dynamic>? _userData;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _loadUserData();
  }

  void _initializeControllers() {
    _nameController = TextEditingController();
    _emailController = TextEditingController();
    _numeroController = TextEditingController();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);

    try {
      User? currentUser = _auth.currentUser;
      if (currentUser != null) {
        DocumentSnapshot userDoc = await _firestore
            .collection('users')
            .doc(currentUser.uid)
            .get();

        if (userDoc.exists) {
          _userData = userDoc.data() as Map<String, dynamic>;
          _updateControllers();
        }
      }
    } catch (e) {
      _showErrorSnackBar('Erreur lors du chargement des données: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _updateControllers() {
    if (_userData != null) {
      _nameController.text = _userData!['nom'] ?? '';
      _emailController.text = _userData!['email'] ?? '';
      _numeroController.text = _userData!['numero'] ?? '';
      _profileImageUrl = _userData!['profilePicture'];
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70
    );

    if (image != null) {
      setState(() {
        _profileImageFile = File(image.path);
      });
    }
  }

  Future<String?> _uploadProfileImage(File imageFile) async {
    try {
      // Ici vous pouvez implémenter l'upload vers Firebase Storage
      // Pour l'instant, on simule un upload réussi
      await Future.delayed(const Duration(seconds: 2));
      return 'https://example.com/profile_image.jpg'; // URL simulée
    } catch (e) {
      print('Erreur upload image: $e');
      return null;
    }
  }

  Future<void> _saveProfileChanges() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      User? currentUser = _auth.currentUser;
      if (currentUser == null) return;

      Map<String, dynamic> updates = {};

      // Vérifier les changements
      if (_nameController.text.trim() != (_userData!['nom'] ?? '')) {
        updates['nom'] = _nameController.text.trim();
      }

      if (_numeroController.text.trim() != (_userData!['numero'] ?? '')) {
        updates['numero'] = _numeroController.text.trim();
      }

      // Upload nouvelle image si sélectionnée
      if (_profileImageFile != null) {
        String? imageUrl = await _uploadProfileImage(_profileImageFile!);
        if (imageUrl != null) {
          updates['profilePicture'] = imageUrl;
          _profileImageUrl = imageUrl;
        } else {
          _showErrorSnackBar('Erreur lors de l\'upload de l\'image');
          setState(() => _isLoading = false);
          return;
        }
      }

      if (updates.isEmpty) {
        _showSuccessSnackBar('Aucune modification détectée');
        setState(() {
          _isEditing = false;
          _isLoading = false;
        });
        return;
      }

      // Mise à jour dans Firestore
      await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .update(updates);

      // Mettre à jour les données locales
      _userData!.addAll(updates);

      _showSuccessSnackBar('Profil mis à jour avec succès !');

      setState(() {
        _isEditing = false;
        _profileImageFile = null;
      });

    } catch (e) {
      _showErrorSnackBar('Erreur lors de la mise à jour: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _sendPasswordResetEmail() async {
    try {
      await _auth.sendPasswordResetEmail(email: _emailController.text.trim());
      _showSuccessSnackBar('Email de réinitialisation envoyé !');
    } catch (e) {
      _showErrorSnackBar('Erreur: $e');
    }
  }

  Future<void> _signOut() async {
    try {
      await _auth.signOut();
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/login');
      }
    } catch (e) {
      _showErrorSnackBar('Erreur lors de la déconnexion: $e');
    }
  }

  Future<void> _deleteAccount() async {
    bool? confirm = await _showDeleteConfirmationDialog();
    if (confirm != true) return;

    setState(() => _isLoading = true);

    try {
      User? currentUser = _auth.currentUser;
      if (currentUser != null) {
        // Supprimer les données Firestore
        await _firestore.collection('users').doc(currentUser.uid).delete();

        // Supprimer le compte Firebase Auth
        await currentUser.delete();

        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/login');
        }
      }
    } catch (e) {
      _showErrorSnackBar('Erreur lors de la suppression: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<bool?> _showDeleteConfirmationDialog() async {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Text(
          'Supprimer le compte ?',
          style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Cette action est irréversible. Toutes vos données seront perdues.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _numeroController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _userData == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_userData == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Mon Profil'),
          backgroundColor: AppColors.error,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Données utilisateur non disponibles'),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _loadUserData,
                child: const Text('Recharger'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Mon Profil'),
        backgroundColor: AppColors.warning,
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(CupertinoIcons.pen),
              onPressed: () {
                setState(() {
                  _isEditing = true;
                  _updateControllers();
                  _profileImageFile = null;
                });
              },
            )
          else
            _isLoading
                ? const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
            )
                : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(CupertinoIcons.checkmark),
                  onPressed: _saveProfileChanges,
                ),
                IconButton(
                  icon: const Icon(CupertinoIcons.xmark),
                  onPressed: _isLoading
                      ? null
                      : () {
                    setState(() {
                      _isEditing = false;
                      _updateControllers();
                      _profileImageFile = null;
                    });
                  },
                ),
              ],
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Avatar Section
              _buildAvatarSection(),

              const SizedBox(height: 30),

              // Profile Information
              _isEditing
                  ? _buildEditableSection()
                  : _buildReadOnlySection(),

              const SizedBox(height: 30),

              // Actions (only in read-only mode)
              if (!_isEditing) ...[
                _buildSectionTitle('Actions'),
                const SizedBox(height: 15),
                _buildActionButton(
                  icon: CupertinoIcons.lock_rotation,
                  text: 'Changer le mot de passe',
                  onPressed: _sendPasswordResetEmail,
                ),
                const SizedBox(height: 10),
                _buildActionButton(
                  icon: CupertinoIcons.square_arrow_right,
                  text: 'Déconnexion',
                  color: AppColors.primary,
                  onPressed: _signOut,
                ),
                const SizedBox(height: 10),
                _buildActionButton(
                  icon: CupertinoIcons.delete,
                  text: 'Supprimer le compte',
                  color: AppColors.error,
                  onPressed: _deleteAccount,
                ),
              ],

              if (_isEditing && _isLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: CircularProgressIndicator(),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarSection() {
    return GestureDetector(
      onTap: _isEditing ? _pickImage : null,
      child: Stack(
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.3),
                  offset: const Offset(0, 4),
                  blurRadius: 12,
                ),
              ],
            ),
            child: CircleAvatar(
              radius: 60,
              backgroundColor: AppColors.surface,
              backgroundImage: _profileImageFile != null
                  ? FileImage(_profileImageFile!)
                  : (_profileImageUrl != null && _profileImageUrl!.isNotEmpty
                  ? NetworkImage(_profileImageUrl!)
                  : null) as ImageProvider?,
              child: (_profileImageFile == null &&
                  (_profileImageUrl == null || _profileImageUrl!.isEmpty))
                  ? Text(
                _getInitials(_userData!['nom'] ?? 'User'),
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              )
                  : null,
            ),
          ),
          if (_isEditing)
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  CupertinoIcons.camera,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildReadOnlySection() {
    return Column(
      children: [
        _buildSectionTitle('Informations'),
        const SizedBox(height: 15),
        _buildInfoCard('Nom complet', _userData!['nom'] ?? 'Non défini'),
        _buildInfoCard('Email', _userData!['email'] ?? 'Non défini'),
        _buildInfoCard('Téléphone', _userData!['numero'] ?? 'Non défini'),
        _buildInfoCard('Compte créé', _formatDate(_userData!['createdAt'])),
      ],
    );
  }

  Widget _buildEditableSection() {
    return Column(
      children: [
        _buildSectionTitle('Modifier les informations'),
        const SizedBox(height: 15),
        _buildEditableTextField(
          'Nom complet',
          _nameController,
          CupertinoIcons.person,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Le nom ne peut pas être vide';
            }
            if (value.trim().length < 3) {
              return 'Le nom doit contenir au moins 3 caractères';
            }
            return null;
          },
        ),
        const SizedBox(height: 15),
        _buildEditableTextField(
          'Email (non modifiable)',
          _emailController,
          CupertinoIcons.mail,
          readOnly: true,
        ),
        const SizedBox(height: 15),
        _buildEditableTextField(
          'Numéro de téléphone',
          _numeroController,
          CupertinoIcons.phone,
          keyboardType: TextInputType.phone,
          validator: (value) {
            if (value != null && value.isNotEmpty && value.length < 8) {
              return 'Numéro invalide';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title.toUpperCase(),
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
        letterSpacing: 1,
      ),
    );
  }

  Widget _buildInfoCard(String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, 2),
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          Flexible(
            child: Text(
              value,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditableTextField(
      String label,
      TextEditingController controller,
      IconData icon, {
        bool readOnly = false,
        TextInputType? keyboardType,
        String? Function(String?)? validator,
      }) {
    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      keyboardType: keyboardType,
      validator: validator,
      style: TextStyle(
        color: readOnly ? AppColors.textSecondary : AppColors.textPrimary,
      ),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.textSecondary),
        filled: true,
        fillColor: readOnly ? AppColors.background : AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.error, width: 2),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String text,
    required VoidCallback onPressed,
    Color? color,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        icon: Icon(icon),
        label: Text(text),
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color ?? AppColors.surface,
          foregroundColor: color == AppColors.error ? Colors.white : AppColors.textPrimary,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  String _getInitials(String name) {
    if (name.isEmpty) return 'U';
    List<String> parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return 'Non défini';
    try {
      if (timestamp is Timestamp) {
        DateTime date = timestamp.toDate();
        return '${date.day}/${date.month}/${date.year}';
      }
      return 'Non défini';
    } catch (e) {
      return 'Non défini';
    }
  }
}