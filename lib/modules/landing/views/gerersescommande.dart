import 'package:flutter/material.dart';
import 'package:pharm/utilitaires/apps_colors.dart';
import 'package:pharm/composants/custom_bottom.dart';

class OrderPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Gérer les Commandes'),
        backgroundColor: AppColors.warning,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shopping_cart, size: 100, color: AppColors.warning.withOpacity(0.5)),
            SizedBox(height: 20),
            Text(
              'Gérer les Commandes',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text('Commandez vos médicaments et suivez vos commandes'),
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
