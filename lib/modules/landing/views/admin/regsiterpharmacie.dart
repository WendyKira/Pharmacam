import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// --- Page d'enregistrement d'une pharmacie ---
class PharmacieRegisterPage extends StatefulWidget {
  const PharmacieRegisterPage({Key? key}) : super(key: key);

  @override
  _PharmacieRegisterPageState createState() => _PharmacieRegisterPageState();
}

class _PharmacieRegisterPageState extends State<PharmacieRegisterPage> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final TextEditingController _nomController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _telephoneController = TextEditingController();
  final TextEditingController _adresseController = TextEditingController();
  final TextEditingController _villeController = TextEditingController();
  final TextEditingController _responsableController = TextEditingController();
  final TextEditingController _horairesController = TextEditingController();
  final TextEditingController _numeroDurgenceController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  bool _loading = false;

  Future<void> _enregistrerPharmacie() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      // Vérifier correspondance des mots de passe
      if (_passwordController.text.trim() != _confirmController.text.trim()) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Les mots de passe ne correspondent pas")),
        );
        setState(() => _loading = false);
        return;
      }

      // 1️⃣ Création du compte Firebase Authentication
      UserCredential userCredential =
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // Récupérer l'UID du nouveau compte
      String uid = userCredential.user!.uid;

      // 2️⃣ Enregistrement des infos dans Firestore
      await FirebaseFirestore.instance.collection("users").doc(uid).set({
        "uid": uid,
        "nom": _nomController.text.trim(),
        "email": _emailController.text.trim(),
        "telephone": _telephoneController.text.trim(),
        "adresse": _adresseController.text.trim(),
        "ville": _villeController.text.trim(),
        "responsable": _responsableController.text.trim(),
        "horaires": _horairesController.text.trim(),
        "numeroDurgence": _numeroDurgenceController.text.trim(),
        "role": "Pharmacie",
        "statut": "Actif",
        "date_creation": DateTime.now(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Pharmacie enregistrée avec succès")),
      );

      Navigator.pop(context); // retour vers la gestion des utilisateurs
    } on FirebaseAuthException catch (e) {
      String message = "";
      if (e.code == 'email-already-in-use') {
        message = "Cet email est déjà utilisé";
      } else if (e.code == 'weak-password') {
        message = "Le mot de passe est trop faible";
      } else {
        message = "Erreur Auth: ${e.message}";
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur : $e")),
      );
    }

    setState(() => _loading = false);
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Enregistrer une Pharmacie"),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildTextField(_nomController, "Nom de la pharmacie"),
              _buildTextField(_responsableController, "Nom du responsable"),
              _buildTextField(_emailController, "Email"),
              _buildTextField(_telephoneController, "Téléphone"),
              _buildTextField(_adresseController, "Adresse"),
              _buildTextField(_villeController, "Ville"),
              _buildTextField(_horairesController, "horaires"),
              _buildTextField(_numeroDurgenceController, "numeroDurgence"),
              _buildPasswordField(_passwordController, "Mot de passe", _obscurePassword, () => setState(() => _obscurePassword = !_obscurePassword)),
              _buildPasswordField(_confirmController, "Confirmer Mot de passe", _obscureConfirmPassword, () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword)),
              SizedBox(height: 20),
              _loading
                  ? CircularProgressIndicator(color: Colors.teal)
                  : ElevatedButton.icon(
                onPressed: _enregistrerPharmacie,
                icon: Icon(Icons.save),
                label: Text("Enregistrer"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        validator: (value) =>
        value == null || value.isEmpty ? "Champ obligatoire" : null,
      ),
    );
  }

  Widget _buildPasswordField(TextEditingController controller, String label, bool obscureText, VoidCallback onToggle) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          suffixIcon: IconButton(
            icon: Icon(obscureText ? Icons.visibility : Icons.visibility_off),
            onPressed: onToggle,
          ),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) return "Champ obligatoire";
          if (value.length < 6) return "Mot de passe doit contenir au moins 6 caractères";
          return null;
        },
      ),
    );
  }
}