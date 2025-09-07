import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../modules/landing/views/patient/home_page.dart';
import '../modules/landing/views/patient/map_page.dart';
import '../modules/landing/views/patient/message_page.dart';
import '../modules/landing/views/patient/setting_page.dart';
import '../utilitaires/apps_colors.dart';
import 'package:flutter/services.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen>
    with TickerProviderStateMixin {
  int _currentIndex = 0;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  final List<Widget> _pages = [
    HomePage(),
    MessagesPage(),
    MapPage(),
    SettingsPage(), // ✅ Profil supprimé
  ];

  // Données des onglets avec icônes modernes
  final List<NavigationItem> _navigationItems = [
    NavigationItem(
      icon: Icons.home_rounded,
      activeIcon: Icons.home_rounded,
      label: 'Accueil',
      color: AppColors.primaryLight,
    ),
    NavigationItem(
      icon: Icons.chat_bubble_outline_rounded,
      activeIcon: Icons.chat_bubble_rounded,
      label: 'Messages',
      color: AppColors.primaryLight,
    ),
    NavigationItem(
      icon: Icons.location_on_outlined,
      activeIcon: Icons.location_on_rounded,
      label: 'Localisation',
      color: AppColors.primaryLight,
    ),
    NavigationItem(
      icon: Icons.settings_outlined,
      activeIcon: Icons.settings_rounded,
      label: 'Paramètres',
      color: AppColors.primaryLight,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _changeTab(int index) {
    if (index != _currentIndex) {
      setState(() {
        _currentIndex = index;
      });

      // Animation de feedback
      _animationController.forward().then((_) {
        _animationController.reverse();
      });

      // Vibration légère pour le feedback haptique
      HapticFeedback.selectionClick();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 20,
              offset: Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          top: false, // ✅ évite le décalage inutile
          child: SizedBox(
            height: 80,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(_navigationItems.length, (index) {
                final item = _navigationItems[index];
                final isActive = index == _currentIndex;

                return GestureDetector(
                  onTap: () => _changeTab(index),
                  child: AnimatedContainer(
                    duration: Duration(milliseconds: 250),
                    curve: Curves.easeInOut,
                    padding: EdgeInsets.symmetric(
                      horizontal: isActive ? 16 : 8,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isActive
                          ? item.color.withOpacity(0.1)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Icône avec animation
                        AnimatedBuilder(
                          animation: _animationController,
                          builder: (context, child) {
                            return Transform.scale(
                              scale: isActive &&
                                  _animationController.isAnimating
                                  ? _scaleAnimation.value
                                  : 1.0,
                              child: Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isActive
                                      ? item.color.withOpacity(0.2)
                                      : Colors.transparent,
                                ),
                                child: Icon(
                                  isActive ? item.activeIcon : item.icon,
                                  size: 20,
                                  color: isActive
                                      ? item.color
                                      : AppColors.textTertiary,
                                ),
                              ),
                            );
                          },
                        ),

                        SizedBox(height: 4),

                        // Label avec animation
                        AnimatedDefaultTextStyle(
                          duration: Duration(milliseconds: 200),
                          style: TextStyle(
                            fontSize: isActive ? 11 : 10,
                            fontWeight:
                            isActive ? FontWeight.w600 : FontWeight.w500,
                            color: isActive
                                ? item.color
                                : AppColors.textTertiary,
                          ),
                          child: Text(
                            item.label,
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),

                        // Indicateur actif
                        AnimatedContainer(
                          duration: Duration(milliseconds: 200),
                          width: isActive ? 20 : 0,
                          height: 2,
                          margin: EdgeInsets.only(top: 2),
                          decoration: BoxDecoration(
                            color: isActive ? item.color : Colors.transparent,
                            borderRadius: BorderRadius.circular(1),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

// Classe pour les données de navigation
class NavigationItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final Color color;

  NavigationItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.color,
  });
}
