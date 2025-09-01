import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pharm/utilitaires/apps_colors.dart';
import 'package:pharm/composants/custom_bottom.dart';
import 'dart:io';

// Modèle de données pour une ordonnance
class Ordonnance {
  final String id;
  final String date;
  final String fileName;
  final String filePath;

  Ordonnance({
    required this.id,
    required this.date,
    required this.fileName,
    required this.filePath,
  });
}

// Page pour gérer les ordonnances
class GererOrdonnancesPage extends StatefulWidget {
  const GererOrdonnancesPage({super.key});

  @override
  State<GererOrdonnancesPage> createState() => _GererOrdonnancesPageState();
}

class _GererOrdonnancesPageState extends State<GererOrdonnancesPage> {
  // Données simulées pour l'historique des ordonnances
  List<Ordonnance> _ordonnances = [
    Ordonnance(
      id: 'ORD001',
      date: '2025-08-20',
      fileName: 'ordonnance_001.jpg',
      filePath: 'path/to/ordonnance_001.jpg',
    ),
    Ordonnance(
      id: 'ORD002',
      date: '2025-08-18',
      fileName: 'ordonnance_002.pdf',
      filePath: 'path/to/ordonnance_002.pdf',
    ),
    Ordonnance(
      id: 'ORD003',
      date: '2025-08-15',
      fileName: 'ordonnance_003.jpg',
      filePath: 'path/to/ordonnance_003.jpg',
    ),
  ];

  // Instance de ImagePicker
  final ImagePicker _picker = ImagePicker();

  // Fonction pour ouvrir la galerie et sélectionner une image
  Future<void> _enregistrerOrdonnance() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() {
          _ordonnances.add(Ordonnance(
            id: 'ORD${_ordonnances.length + 1}'.padLeft(6, '0'),
            date: DateTime.now().toString().split(' ')[0],
            fileName: image.name,
            filePath: image.path,
          ));
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Ordonnance ${image.name} enregistrée avec succès',
              style: TextStyle(color: AppColors.textPrimary),
            ),
            backgroundColor: AppColors.success,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Aucune image sélectionnée',
              style: TextStyle(color: AppColors.textPrimary),
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Erreur lors de la sélection : $e',
            style: TextStyle(color: AppColors.textPrimary),
          ),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  // Fonction pour envoyer une ordonnance
  void _envoyerOrdonnance(Ordonnance ordonnance) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Ordonnance ${ordonnance.id} envoyée avec succès',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        backgroundColor: AppColors.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Mes Ordonnances',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        backgroundColor: AppColors.primary,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_rounded,
            color: AppColors.textPrimary,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Bouton pour enregistrer une nouvelle ordonnance
          Container(
            margin: const EdgeInsets.all(16.0),
            child: CustomButton(
              text: 'Enregistrer une ordonnance',
              onPressed: () => _enregistrerOrdonnance(),
              backgroundColor: AppColors.primary,
              textColor: AppColors.surface,
              width: double.infinity,
              height: 50,
            ),
          ),
          // Section Liste des ordonnances
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              'Historique des ordonnances',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Expanded(
            child: _ordonnances.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: _ordonnances.length,
              itemBuilder: (context, index) {
                final ordonnance = _ordonnances[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 16.0),
                  color: AppColors.surface,
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ID: ${ordonnance.id}',
                          style: TextStyle(color: AppColors.textPrimary),
                        ),
                        Text(
                          'Date: ${ordonnance.date}',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                        Text(
                          'Fichier: ${ordonnance.fileName}',
                          style: TextStyle(color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: 16.0),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            CustomButton(
                              text: 'Voir l\'ordonnance',
                              onPressed: () => _voirOrdonnance(ordonnance),
                              backgroundColor: AppColors.primary,
                              textColor: AppColors.surface,
                              width: 150,
                              height: 40,
                            ),
                            CustomButton(
                              text: 'Envoyer',
                              onPressed: () => _envoyerOrdonnance(ordonnance),
                              backgroundColor: AppColors.secondary,
                              textColor: AppColors.surface,
                              width: 150,
                              height: 40,
                            ),
                          ],
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
    );
  }

  // Widget pour afficher l'état vide
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.description_outlined,
              size: 80,
              color: AppColors.textTertiary,
            ),
            const SizedBox(height: 20),
            Text(
              'Aucune ordonnance enregistrée',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Utilisez le bouton ci-dessus pour ajouter une ordonnance',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // Fonction pour afficher une ordonnance
  void _voirOrdonnance(Ordonnance ordonnance) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(
          'Ordonnance ${ordonnance.id}',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Fichier: ${ordonnance.fileName}',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            ordonnance.filePath.endsWith('.jpg') || ordonnance.filePath.endsWith('.png')
                ? Image.file(
              File(ordonnance.filePath),
              height: 200,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Text(
                'Impossible de charger l\'image',
                style: TextStyle(color: AppColors.error),
              ),
            )
                : Text(
              'Aperçu non disponible pour ce format',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Fermer',
              style: TextStyle(color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }
}