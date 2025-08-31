import 'package:flutter/material.dart';
import 'package:pharm/utilitaires/apps_colors.dart';
import 'package:pharm/composants/custom_bottom.dart';


class PharmaciesPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Liste des Pharmacies'),
        backgroundColor: AppColors.secondaryLight,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.local_pharmacy, size: 100, color: AppColors.secondaryLight.withOpacity(0.5)),
            SizedBox(height: 20),
            Text(
              'Liste des Pharmacies',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text('Trouvez une pharmacie près de vous'),
            SizedBox(height: 20),
            CustomButton(
              text: 'Retour à l\'accueil',
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }
}
