import 'package:flutter/material.dart';

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

class ListesProduits extends StatefulWidget {
  @override
  _ListesProduitsState createState() => _ListesProduitsState();
}

class _ListesProduitsState extends State<ListesProduits> {
  String nomPharmacie = "Pharmacie Central";

  List<Medicament> medicaments = [
    Medicament(nom: "Paracétamol 500mg", prix: 2.50),
    Medicament(nom: "Ibuprofène 400mg", prix: 3.20),
    Medicament(nom: "Aspirine 100mg", prix: 1.80),
    Medicament(nom: "Amoxicilline 1g", prix: 8.50),
    Medicament(nom: "Doliprane 1g", prix: 4.10),
    Medicament(nom: "Ventoline", prix: 12.30),
  ];

  void _modifierMedicament(int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        TextEditingController nomController =
        TextEditingController(text: medicaments[index].nom);
        TextEditingController prixController =
        TextEditingController(text: medicaments[index].prix.toString());

        return AlertDialog(
          title: Text('Modifier le médicament'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nomController,
                decoration: InputDecoration(labelText: 'Nom du médicament'),
              ),
              SizedBox(height: 10),
              TextField(
                controller: prixController,
                decoration: InputDecoration(labelText: 'Prix (€)'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  medicaments[index].nom = nomController.text;
                  medicaments[index].prix = double.tryParse(prixController.text) ?? medicaments[index].prix;
                });
                Navigator.of(context).pop();
              },
              child: Text('Enregistrer'),
            ),
          ],
        );
      },
    );
  }

  void _supprimerMedicament(int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirmer la suppression'),
          content: Text('Êtes-vous sûr de vouloir supprimer ${medicaments[index].nom} ?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  medicaments.removeAt(index);
                });
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: Text('Supprimer', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _enregistrerModifications() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Modifications enregistrées avec succès !'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
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
        backgroundColor: Colors.blue[800],
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
                          // Informations du médicament
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

                          // Switch de disponibilité
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

                          // Actions (Modifier/Supprimer)
                          Expanded(
                            flex: 1,
                            child: Column(
                              children: [
                                IconButton(
                                  icon: Icon(Icons.edit, color: Colors.blue[600]),
                                  onPressed: () => _modifierMedicament(index),
                                  tooltip: 'Modifier',
                                ),
                                IconButton(
                                  icon: Icon(Icons.delete, color: Colors.red[600]),
                                  onPressed: () => _supprimerMedicament(index),
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
          onPressed: _enregistrerModifications,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green[600],
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
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            medicaments.add(
              Medicament(
                nom: "Nouveau médicament",
                prix: 0.0,
                disponible: false,
              ),
            );
          });
        },
        backgroundColor: Colors.blue[600],
        child: Icon(Icons.add, color: Colors.green),
        tooltip: 'Ajouter un médicament',
      ),
    );
  }
}

// Classe pour la navigation si besoin d'autres écrans
class NavigationHelper {
  static void naviguerVers(BuildContext context, Widget destination) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => destination),
    );
  }
}

// Widget réutilisable pour les cartes de médicaments
class MedicamentCard extends StatelessWidget {
  final Medicament medicament;
  final VoidCallback onModifier;
  final VoidCallback onSupprimer;
  final ValueChanged<bool> onDisponibiliteChanged;

  const MedicamentCard({
    Key? key,
    required this.medicament,
    required this.onModifier,
    required this.onSupprimer,
    required this.onDisponibiliteChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
                    medicament.nom,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '${medicament.prix.toStringAsFixed(2)} €',
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
                    medicament.disponible ? 'Disponible' : 'Indisponible',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: medicament.disponible
                          ? Colors.green[700]
                          : Colors.red[700],
                    ),
                  ),
                  Switch(
                    value: medicament.disponible,
                    onChanged: onDisponibiliteChanged,
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
                    onPressed: onModifier,
                    tooltip: 'Modifier',
                  ),
                  IconButton(
                    icon: Icon(Icons.delete, color: Colors.red[600]),
                    onPressed: onSupprimer,
                    tooltip: 'Supprimer',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}