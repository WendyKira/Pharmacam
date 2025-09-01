import 'package:flutter/material.dart';
import 'package:pharm/modules/landing/views/listespharmacies_page.dart';
import 'package:pharm/utilitaires/apps_colors.dart';
import 'package:pharm/composants/custom_bottom.dart';

// Modèle de données pour une commande
class Commande {
  final String id;
  final String date;
  final String statut;
  final String medicament;
  final String pharmacie;
  final double montant;

  Commande({
    required this.id,
    required this.date,
    required this.statut,
    required this.medicament,
    required this.pharmacie,
    required this.montant,
  });
}

// Page pour gérer les commandes
class GererCommandePage extends StatefulWidget {
  const GererCommandePage({super.key});

  @override
  State<GererCommandePage> createState() => _GererCommandePageState();
}

class _GererCommandePageState extends State<GererCommandePage> {
  // Données simulées pour l'historique des commandes
  List<Commande> _commandes = [
    Commande(
      id: 'CMD001',
      date: '2025-08-20',
      statut: 'En cours',
      medicament: 'Paracétamol 500mg',
      pharmacie: 'Pharmacie Centrale Yaoundé',
      montant: 350.0,
    ),
    Commande(
      id: 'CMD002',
      date: '2025-08-18',
      statut: 'Livrée',
      medicament: 'Ibuprofène 400mg',
      pharmacie: 'Pharmacie du Rond-Point',
      montant: 850.0,
    ),
    Commande(
      id: 'CMD003',
      date: '2025-08-15',
      statut: 'Annulée',
      medicament: 'Amoxicilline 500mg',
      pharmacie: 'Pharmacie Populaire',
      montant: 1600.0,
    ),
  ];

  // Fonction pour annuler une commande
  void _annulerCommande(String id) {
    setState(() {
      _commandes = _commandes.map((cmd) {
        if (cmd.id == id) {
          return Commande(
            id: cmd.id,
            date: cmd.date,
            statut: 'Annulée',
            medicament: cmd.medicament,
            pharmacie: cmd.pharmacie,
            montant: cmd.montant,
          );
        }
        return cmd;
      }).toList();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Commande annulée avec succès', style: TextStyle(color: AppColors.textPrimary)),
        backgroundColor: AppColors.success,
      ),
    );
  }

  // Fonction pour modifier une commande
  void _modifierCommande(String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('Modifier Commande', style: TextStyle(color: AppColors.textPrimary)),
        content: Text(
          'Implémentez ici la logique de modification (ex: changer quantité, etc.).',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Fermer', style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }

  // Fonction pour passer une nouvelle commande (redirige vers liste de pharmacies)
  void _passerCommande() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ListesPharmaciesPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Gérer Commandes', style: TextStyle(color: AppColors.textPrimary)),
        backgroundColor: AppColors.primary,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_rounded, color: AppColors.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Bouton pour passer une nouvelle commande
          Container(
            margin: const EdgeInsets.all(16.0),
            child: CustomButton(
              text: 'Passer une nouvelle commande',
              onPressed: () => _passerCommande(),
              backgroundColor: AppColors.primary,
              textColor: AppColors.surface,
              width: double.infinity,
              height: 50,
            ),
          ),
          // Section Historique des commandes
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              'Historique des commandes',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: _commandes.length,
              itemBuilder: (context, index) {
                final commande = _commandes[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 16.0),
                  color: AppColors.surface,
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12),),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('ID: ${commande.id}', style: TextStyle(color: AppColors.textPrimary)),
                        Text('Date: ${commande.date}', style: TextStyle(color: AppColors.textSecondary)),
                        Text('Statut: ${commande.statut}', style: TextStyle(color: _getStatutColor(commande.statut))),
                        Text('Médicament: ${commande.medicament}', style: TextStyle(color: AppColors.textPrimary)),
                        Text('Pharmacie: ${commande.pharmacie}', style: TextStyle(color: AppColors.textPrimary)),
                        Text('Montant: ${commande.montant} FCFA', style: TextStyle(color: AppColors.textPrimary)),
                        const SizedBox(height: 16.0),
                        if (commande.statut != 'Annulée' && commande.statut != 'Livrée') ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              CustomButton(
                                text: 'Annuler',
                                onPressed: () => _annulerCommande(commande.id),
                                backgroundColor: AppColors.error,
                                textColor: AppColors.surface,
                                width: 120,
                                height: 40,
                              ),
                              CustomButton(
                                text: 'Modifier',
                                onPressed: () => _modifierCommande(commande.id),
                                backgroundColor: AppColors.primary,
                                textColor: AppColors.surface,
                                width: 120,
                                height: 40,
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Fonction pour obtenir la couleur du statut
  Color _getStatutColor(String statut) {
    switch (statut) {
      case 'En cours':
        return AppColors.warning;
      case 'Livrée':
        return AppColors.success;
      case 'Annulée':
        return AppColors.error;
      default:
        return AppColors.textPrimary;
    }
  }
}

// Page placeholder pour liste de pharmacies (à implémenter si nécessaire)
class PharmaciesPage extends StatelessWidget {
  const PharmaciesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Liste de Pharmacies', style: TextStyle(color: AppColors.textPrimary)),
        backgroundColor: AppColors.primary,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_rounded, color: AppColors.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: Text(
          'Interface Liste de Pharmacies',
          style: TextStyle(color: AppColors.textPrimary, fontSize: 18),
        ),
      ),
    );
  }
}