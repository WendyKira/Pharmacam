import 'package:flutter/material.dart';
// Importez vos fichiers personnalisés
// import 'utils/app_colors.dart';
// import 'widgets/custom_button.dart';

class AjouterMedicamentScreen extends StatefulWidget {
  final Function(Medicament) onMedicamentAjoute;

  const AjouterMedicamentScreen({
    Key? key,
    required this.onMedicamentAjoute,
  }) : super(key: key);

  @override
  _AjouterMedicamentScreenState createState() => _AjouterMedicamentScreenState();
}

class _AjouterMedicamentScreenState extends State<AjouterMedicamentScreen> {
  final _formKey = GlobalKey<FormState>();

  // Contrôleurs pour les champs du formulaire
  final TextEditingController _nomCommercialController = TextEditingController();
  final TextEditingController _principesActifsController = TextEditingController();
  final TextEditingController _prixController = TextEditingController();
  final TextEditingController _laboratoireController = TextEditingController();
  final TextEditingController _conditionnementController = TextEditingController();

  // Variables pour les dropdowns
  String? _classeSelectionnee;
  String? _formeSelectionnee;

  // Listes pour les dropdowns
  final List<String> _classesMedicamenteuses = [
    'Antalgique',
    'Anti-inflammatoire',
    'Antibiotique',
    'Antispasmodique',
    'Cardiovasculaire',
    'Respiratoire',
    'Neurologique',
    'Dermatologique',
    'Gastro-entérologique',
    'Endocrinologique',
  ];

  final List<String> _formesMedicamenteuses = [
    'Comprimé',
    'Gélule',
    'Sirop',
    'Solution injectable',
    'Pommade',
    'Crème',
    'Gouttes',
    'Spray',
    'Suppositoire',
    'Patch',
  ];

  @override
  void dispose() {
    _nomCommercialController.dispose();
    _principesActifsController.dispose();
    _prixController.dispose();
    _laboratoireController.dispose();
    _conditionnementController.dispose();
    super.dispose();
  }

  void _enregistrerMedicament() {
    if (_formKey.currentState!.validate()) {
      // Créer un nouveau médicament avec toutes les informations
      MedicamentComplet nouveauMedicament = MedicamentComplet(
        nomCommercial: _nomCommercialController.text,
        principesActifs: _principesActifsController.text,
        prix: double.parse(_prixController.text),
        classeMedicamenteuse: _classeSelectionnee!,
        forme: _formeSelectionnee!,
        laboratoire: _laboratoireController.text,
        conditionnement: _conditionnementController.text,
        disponible: false,
      );

      // Convertir en Medicament simple pour la liste principale
      Medicament medicamentSimple = Medicament(
        nom: _nomCommercialController.text,
        prix: double.parse(_prixController.text),
        disponible: false,
      );

      widget.onMedicamentAjoute(medicamentSimple);

      // Afficher un message de confirmation
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Médicament ajouté avec succès !'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );

      Navigator.of(context).pop();
    }
  }

  void _annuler() {
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Ajouter un Médicament',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.blue[800], // Remplacez par AppColors.primary si disponible
        elevation: 2,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: _annuler,
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Informations du Médicament',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              SizedBox(height: 24),

              // Nom commercial
              _buildTextField(
                controller: _nomCommercialController,
                label: 'Nom Commercial *',
                hint: 'Ex: Doliprane, Efferalgan...',
                icon: Icons.medication,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Le nom commercial est obligatoire';
                  }
                  return null;
                },
              ),

              SizedBox(height: 16),

              // Principes actifs
              _buildTextField(
                controller: _principesActifsController,
                label: 'Principes Actifs *',
                hint: 'Ex: Paracétamol 500mg',
                icon: Icons.science,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Les principes actifs sont obligatoires';
                  }
                  return null;
                },
              ),

              SizedBox(height: 16),

              // Prix
              _buildTextField(
                controller: _prixController,
                label: 'Prix Privé (€) *',
                hint: '0.00',
                icon: Icons.euro,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Le prix est obligatoire';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Veuillez entrer un prix valide';
                  }
                  return null;
                },
              ),

              SizedBox(height: 16),

              // Classe médicamenteuse
              _buildDropdown(
                value: _classeSelectionnee,
                label: 'Classe Médicamenteuse *',
                items: _classesMedicamenteuses,
                icon: Icons.category,
                onChanged: (String? value) {
                  setState(() {
                    _classeSelectionnee = value;
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return 'Veuillez sélectionner une classe médicamenteuse';
                  }
                  return null;
                },
              ),

              SizedBox(height: 16),

              // Forme
              _buildDropdown(
                value: _formeSelectionnee,
                label: 'Forme *',
                items: _formesMedicamenteuses,
                icon: Icons.medical_services,
                onChanged: (String? value) {
                  setState(() {
                    _formeSelectionnee = value;
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return 'Veuillez sélectionner une forme';
                  }
                  return null;
                },
              ),

              SizedBox(height: 16),

              // Laboratoire
              _buildTextField(
                controller: _laboratoireController,
                label: 'Laboratoire *',
                hint: 'Ex: Sanofi, Pfizer...',
                icon: Icons.business,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Le laboratoire est obligatoire';
                  }
                  return null;
                },
              ),

              SizedBox(height: 16),

              // Conditionnement
              _buildTextField(
                controller: _conditionnementController,
                label: 'Conditionnement *',
                hint: 'Ex: Boîte de 20 comprimés',
                icon: Icons.inventory,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Le conditionnement est obligatoire';
                  }
                  return null;
                },
              ),

              SizedBox(height: 32),

              // Boutons d'action
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _annuler,
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 16.0),
                        side: BorderSide(color: Colors.grey[400]!),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'Annuler',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _enregistrerMedicament,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[600], // Remplacez par AppColors.primary
                        padding: EdgeInsets.symmetric(vertical: 16.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 2,
                      ),
                      child: Text(
                        'Enregistrer',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: Colors.blue[600]),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.blue[600]!, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red[600]!, width: 2),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        filled: true,
        fillColor: Colors.grey[50],
      ),
    );
  }

  Widget _buildDropdown({
    required String? value,
    required String label,
    required List<String> items,
    required IconData icon,
    required ValueChanged<String?> onChanged,
    String? Function(String?)? validator,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      onChanged: onChanged,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.blue[600]),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.blue[600]!, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red[600]!, width: 2),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        filled: true,
        fillColor: Colors.grey[50],
      ),
      items: items.map((String item) {
        return DropdownMenuItem<String>(
          value: item,
          child: Text(item),
        );
      }).toList(),
    );
  }
}

// Classe étendue pour stocker toutes les informations du médicament
class MedicamentComplet {
  String nomCommercial;
  String principesActifs;
  double prix;
  String classeMedicamenteuse;
  String forme;
  String laboratoire;
  String conditionnement;
  bool disponible;

  MedicamentComplet({
    required this.nomCommercial,
    required this.principesActifs,
    required this.prix,
    required this.classeMedicamenteuse,
    required this.forme,
    required this.laboratoire,
    required this.conditionnement,
    this.disponible = false,
  });

  // Convertir en Medicament simple pour la liste principale
  Medicament toMedicamentSimple() {
    return Medicament(
      nom: nomCommercial,
      prix: prix,
      disponible: disponible,
    );
  }
}

// Modification du FloatingActionButton dans votre écran principal
class PharmacyScreenModifie extends StatefulWidget {
  @override
  _PharmacyScreenModifieState createState() => _PharmacyScreenModifieState();
}

class _PharmacyScreenModifieState extends State<PharmacyScreenModifie> {
  String nomPharmacie = "Pharmacie Central";

  List<Medicament> medicaments = [
    Medicament(nom: "Paracétamol 500mg", prix: 2.50),
    Medicament(nom: "Ibuprofène 400mg", prix: 3.20),
    Medicament(nom: "Aspirine 100mg", prix: 1.80),
  ];

  void _ajouterNouveauMedicament() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AjouterMedicamentScreen(
          onMedicamentAjoute: (Medicament nouveauMedicament) {
            setState(() {
              medicaments.add(nouveauMedicament);
            });
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          nomPharmacie,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.blue[800], // Remplacez par AppColors.primary
        elevation: 2,
        centerTitle: true,
      ),
      body: Container(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Liste des Médicaments',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: medicaments.length,
                itemBuilder: (context, index) {
                  return Card(
                    margin: EdgeInsets.symmetric(vertical: 8.0),
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  medicaments[index].nom,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey[800],
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  '${medicaments[index].prix.toStringAsFixed(2)} €',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.green[700],
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Column(
                              children: [
                                Text(
                                  medicaments[index].disponible ? 'Disponible' : 'Indisponible',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: medicaments[index].disponible
                                        ? Colors.green[700]
                                        : Colors.red[700],
                                  ),
                                ),
                                Switch(
                                  value: medicaments[index].disponible,
                                  onChanged: (bool value) {
                                    setState(() {
                                      medicaments[index].disponible = value;
                                    });
                                  },
                                  activeColor: Colors.green,
                                  inactiveTrackColor: Colors.grey[300],
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            flex: 1,
                            child: Column(
                              children: [
                                IconButton(
                                  icon: Icon(Icons.edit, color: Colors.blue[600]),
                                  onPressed: () {
                                    // Logique de modification existante
                                  },
                                  tooltip: 'Modifier',
                                ),
                                IconButton(
                                  icon: Icon(Icons.delete, color: Colors.red[600]),
                                  onPressed: () {
                                    // Logique de suppression existante
                                  },
                                  tooltip: 'Supprimer',
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _ajouterNouveauMedicament,
        backgroundColor: Colors.blue[600], // Remplacez par AppColors.primary
        child: Icon(Icons.add, color: Colors.white),
        tooltip: 'Ajouter un médicament',
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.3),
              spreadRadius: 1,
              blurRadius: 5,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Modifications enregistrées avec succès !'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 2),
              ),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green[600], // Remplacez par AppColors.success
            padding: EdgeInsets.symmetric(vertical: 16.0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            elevation: 2,
          ),
          child: Text(
            'Enregistrer les modifications',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

// Classe Medicament originale (gardée pour compatibilité)
class Medicament {
  String nom;
  double prix;
  bool disponible;

  Medicament({
    required this.nom,
    required this.prix,
    this.disponible = false,
  });
}