import 'package:flutter/material.dart';
import 'package:pharm/composants/custom_bottom.dart';
import 'package:pharm/utilitaires/apps_colors.dart';
import 'login_page.dart';
import 'visite_page.dart';

class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Opacity(
              opacity: 0.8,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryWithOpacity(0.15),
                      offset: const Offset(0, 10),
                      blurRadius: 25,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.asset("assets/images/imge2.png"),
                ),
              ),
            ),
            SizedBox(
              height: 20,
            ),
            Text("Bienvenue dans votre nouvelle application PHARMACAM",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            SizedBox(height: 20,),
            Text("Localisez vos pharmacies en temps réel, vérifiez la disponibilité des médicaments et commandez-les facilement. Gagnez du temps et de l'énergie en cliquant sur commencer.   ",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
              ),
            ),

            SizedBox(
              height: 80,
            ),

            Row(
              children: [
                CustomButton(text: "Commencer", onPressed: (){
                  Navigator.pushReplacementNamed(context, '/login');
                }, width: 160,),
                SizedBox(
                  width: 15,
                ),
                CustomButton(text: "Visiter", onPressed: (){
                  Navigator.push(context, MaterialPageRoute(builder: (context) => VisitePage()),);
                }, isPrimary: false, width: 160,),

              ],
            ),
          ],
        ),
      ),
    );
  }
}