import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../modules/landing/views/patient/home_page.dart';
import '../modules/landing/views/patient/map_page.dart';
import '../modules/landing/views/patient/message_page.dart';
import '../modules/landing/views/patient/profile_page.dart';
import '../modules/landing/views/patient/setting_page.dart';
import '../utilitaires/apps_colors.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    HomePage(),
    MessagesPage(),
    MapPage(),
    ProfilePage(),
    SettingsPage(),
  ];
  void change (int index){
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        onTap: change,
        selectedItemColor: AppColors.primaryLight,
        unselectedItemColor: AppColors.textTertiary,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Accueil',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.message),
            label: 'Messages',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.location_on),
            label: 'Localisation',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profil',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Paramettre',
          ),
        ],
      ),
    );
  }
}
