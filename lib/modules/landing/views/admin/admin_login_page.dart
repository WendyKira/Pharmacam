import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pharm/composants/custom_bottom.dart';
import 'package:pharm/utilitaires/apps_colors.dart';

class AdminLoginPage extends StatefulWidget {
  const AdminLoginPage({super.key});

  @override
  State<AdminLoginPage> createState() => _AdminLoginPageState();
}

class _AdminLoginPageState extends State<AdminLoginPage>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loginAsAdmin() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        // Connexion avec Firebase Auth
        UserCredential userCredential = await _auth.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        User? user = userCredential.user;
        if (user != null) {
          // Vérifier si l'utilisateur est administrateur
          DocumentSnapshot adminDoc = await _firestore
              .collection('users')
              .doc(user.uid)
              .get();

          if (adminDoc.exists) {
            Map<String, dynamic> userData = adminDoc.data() as Map<String, dynamic>;

            // Vérifier le rôle d'administrateur
            if (userData['role'] == 'admin' || userData['isAdmin'] == true) {
              if (mounted) {
                // Navigation vers le dashboard admin
                Navigator.pushReplacementNamed(context, '/admin_dashboard');

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Bienvenue Administrateur!'),
                    backgroundColor: Colors.green,
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            } else {
              // L'utilisateur n'est pas administrateur
              await _auth.signOut();
              if (mounted) {
                _showErrorDialog('Accès refusé', 'Vous n\'avez pas les privilèges administrateur.');
              }
            }
          } else {
            // Compte utilisateur non trouvé dans Firestore
            await _auth.signOut();
            if (mounted) {
              _showErrorDialog('Erreur', 'Compte administrateur non trouvé.');
            }
          }
        }
      } on FirebaseAuthException catch (e) {
        String errorMessage = 'Erreur de connexion';

        switch (e.code) {
          case 'user-not-found':
            errorMessage = 'Aucun compte trouvé avec cet email';
            break;
          case 'wrong-password':
            errorMessage = 'Mot de passe incorrect';
            break;
          case 'invalid-email':
            errorMessage = 'Format d\'email invalide';
            break;
          case 'user-disabled':
            errorMessage = 'Ce compte a été désactivé';
            break;
          case 'too-many-requests':
            errorMessage = 'Trop de tentatives. Veuillez réessayer plus tard';
            break;
        }

        if (mounted) {
          _showErrorDialog('Erreur de connexion', errorMessage);
        }
      } catch (e) {
        if (mounted) {
          _showErrorDialog('Erreur', 'Une erreur inattendue s\'est produite');
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: AppColors.error,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'OK',
              style: TextStyle(color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.lightGreen.shade100,
              Colors.lightGreen.shade200,
              Colors.green.shade50,
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 40),

                      // Logo et titre administrateur
                      _buildAdminHeader(),

                      const SizedBox(height: 50),

                      // Carte de connexion
                      _buildLoginCard(),

                      const SizedBox(height: 30),

                      // Informations de sécurité
                      _buildSecurityInfo(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAdminHeader() {
    return Column(
      children: [
        // Icône admin avec animation
        TweenAnimationBuilder(
          duration: const Duration(milliseconds: 1500),
          tween: Tween<double>(begin: 0, end: 1),
          builder: (context, double value, child) {
            return Transform.scale(
              scale: value,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      Colors.green.shade600,
                      Colors.green.shade400,
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.withOpacity(0.3),
                      offset: const Offset(0, 10),
                      blurRadius: 25,
                    ),
                  ],
                ),
                child: const Icon(
                  CupertinoIcons.shield_fill,
                  size: 60,
                  color: Colors.white,
                ),
              ),
            );
          },
        ),

        const SizedBox(height: 24),

        Text(
          'ADMINISTRATION',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.green.shade800,
            letterSpacing: 2.0,
          ),
        ),

        const SizedBox(height: 8),

        Text(
          'Espace Pharmaceutique Sécurisé',
          style: TextStyle(
            fontSize: 16,
            color: Colors.green.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildLoginCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.1),
            offset: const Offset(0, 10),
            blurRadius: 30,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Connexion Administrateur',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.green.shade700,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 30),

          // Champ email
          _buildStyledTextField(
            'Email Administrateur',
            controller: _emailController,
            icon: CupertinoIcons.mail_solid,
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Veuillez entrer votre email administrateur';
              }
              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                return 'Format d\'email invalide';
              }
              return null;
            },
          ),

          const SizedBox(height: 20),

          // Champ mot de passe
          _buildStyledTextField(
            'Mot de passe',
            controller: _passwordController,
            icon: CupertinoIcons.lock,
            isPassword: true,
            obscureText: _obscurePassword,
            onTogglePassword: () {
              setState(() => _obscurePassword = !_obscurePassword);
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Veuillez entrer votre mot de passe';
              }
              if (value.length < 6) {
                return 'Mot de passe trop court';
              }
              return null;
            },
          ),

          const SizedBox(height: 30),

          // Bouton de connexion
          CustomButton(
            text: _isLoading ? 'Connexion...' : 'Se connecter',
            onPressed: _isLoading ? null : _loginAsAdmin,
          ),
        ],
      ),
    );
  }

  Widget _buildStyledTextField(
      String hint, {
        bool isPassword = false,
        bool obscureText = false,
        VoidCallback? onTogglePassword,
        required TextEditingController controller,
        IconData? icon,
        TextInputType? keyboardType,
        String? Function(String?)? validator,
      }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.05),
            offset: const Offset(0, 4),
            blurRadius: 15,
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        validator: validator,
        style: TextStyle(color: Colors.green.shade800),
        decoration: InputDecoration(
          labelText: hint,
          hintText: 'Entrez $hint',
          prefixIcon: icon != null
              ? Icon(icon, color: Colors.grey)
              : null,
          suffixIcon: isPassword
              ? IconButton(
            icon: Icon(
              obscureText ? CupertinoIcons.eye_slash : CupertinoIcons.eye,
              color: Colors.grey,
            ),
            onPressed: onTogglePassword,
          )
              : null,
          filled: true,
          fillColor: Colors.grey.shade200,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(
              color: Colors.green.shade600,
              width: 2,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(
              color: Colors.red,
              width: 2,
            ),
          ),
          hintStyle: TextStyle(color: Colors.white54),
        ),
      ),
    );
  }

  Widget _buildSecurityInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: Colors.green.shade200,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            CupertinoIcons.info_circle_fill,
            color: Colors.green.shade600,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Accès Sécurisé',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade800,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Cette interface est réservée aux administrateurs autorisés uniquement.',
                  style: TextStyle(
                    color: Colors.green.shade600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}