import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:pharm/modules/landing/views/admin/dashboard_admin_page.dart';
import 'package:pharm/modules/landing/views/admin/gererutilisateurs.dart';
import 'package:pharm/modules/landing/views/loginphar.dart';
import 'package:pharm/modules/landing/views/patient/gerer_ordonnances.dart';
import 'package:pharm/modules/landing/views/patient/landing_page.dart';
import 'package:pharm/modules/landing/views/pharmacie/dashboard_pharm_page.dart';
import 'composants/screenmanage.dart';
import 'firebase_options.dart';
import 'modules/landing/views/patient/login_page.dart';
import 'modules/landing/views/patient/map_page.dart';
import 'modules/landing/views/patient/listesmedicaments_page.dart';
import 'modules/landing/views/patient/message_page.dart';
import 'modules/landing/views/patient/gerersescommande.dart';
import 'modules/landing/views/patient/listespharmacies_page.dart';
import 'modules/landing/views/pharmacie/listes_produits.dart';

import 'modules/landing/views/patient/setting_page.dart';

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
  options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
       fontFamily: "Poppins"
      ),
      home: LoginPharPage(),
      routes: {
    '/medicaments': (context) => ListesMedicamentsPage(),
    '/pharmacies': (context) => ListesPharmaciesPage(),
    '/commandes': (context) => GererCommandePage(),
    '/messages': (context) => MessagesPage(),
    '/location': (context) => MapPage(),
    '/settings': (context) => SettingsPage(),
        '/admin_dashboard': (context) => AdminDashboardPage(),
        '/gestion_utilisateurs': (context) => UserManagementPage(),


    '/login': (context) => LoginPage(),
    '/screenmange': (context) => MainScreen(),
        '/ordonnance': (context) => GererOrdonnancesPage(),
      },
    );
  }
}

