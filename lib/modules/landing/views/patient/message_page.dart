import 'package:flutter/material.dart';
import 'package:pharm/utilitaires/apps_colors.dart';

class MessagesPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Messages'),
        backgroundColor: AppColors.success,

      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.message, size: 100, color: AppColors.success.withOpacity(0.5)),
            SizedBox(height: 20),
            Text(
              'Messages',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text('Vos conversations et notifications'),
          ],
        ),
      ),
    );
  }
}