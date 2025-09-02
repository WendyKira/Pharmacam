import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

// Palette de couleurs de l'application
class AppColors {
  // Couleurs primaires - Design moderne et soft
  static const Color primary = Color(0xFF53BA63);
  static const Color primaryLight = Color(0xFF31B642);
  static const Color primaryDark = Color(0xFF28C605);

  // Couleurs secondaires
  static const Color secondary = Color(0xFF6FB35C);
  static const Color secondaryLight = Color(0xFF497830);
  static const Color secondaryDark = Color(0xFF2A5C18);

  // Couleurs neutres
  static const Color background = Color(0xFFEFF3EC);
  static const Color surface = Color(0xFFCCCCCC);
  static const Color surfaceSecondary = Color(0xFFEC2C2C);

  // Couleurs de texte
  static const Color textPrimary = Color(0xFF000000);
  static const Color textSecondary = Color(0xFFA19E9E);
  static const Color textTertiary = Color(0xFF615F5F);

  // Couleurs d'état
  static const Color success = Color(0xFF34C759);
  static const Color warning = Color(0xFF42CD30);
  static const Color error = Color(0xFF058F07);

  // Couleurs avec opacité pour les effets
  static Color primaryWithOpacity(double opacity) => primary.withOpacity(opacity);
  static Color secondaryWithOpacity(double opacity) => secondary.withOpacity(opacity);
}

