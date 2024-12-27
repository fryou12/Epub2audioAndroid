import 'package:flutter/material.dart';

class AppColors {
  // Thème Sombre
  static const darkTheme = AppThemeColors(
    // Arrière-plan de l'en-tête
    headerBackground: Color.fromARGB(255, 62, 62, 62),
    // Arrière-plan du drawer
    drawerBackground: Color.fromARGB(255, 93, 93, 93),
    // Arrière-plan des conteneurs
    containerBackground: Color.fromARGB(255, 140, 138, 138),
    // Arrière-plan des boutons
    buttonBackground: Color(0xFF424242),
    // Arrière-plan des boutons désactivés
    buttonBackgroundDisabled: Color(0xFF616161), // Colors.grey[700]
    // Arrière-plan transparent
    transparentBackground: Color.fromARGB(158, 70, 63, 63),

    // Couleurs du texte et des icônes
    // Texte principal
    primaryText: Color.fromARGB(255, 206, 206, 206),
    // Texte secondaire
    secondaryText: Color.fromARGB(179, 117, 117, 117),
    // Couleur des icônes
    iconColor: Color.fromARGB(255, 255, 255, 255),
    // Couleur des icônes désactivées
    disabledIconColor: Color.fromARGB(188, 148, 147, 147),

    // Éléments d'interface
    // Couleur des séparateurs
    dividerColor: Color.fromARGB(255, 165, 165, 165),
    // Couleur de survol
    hoverColor: Color(0x1FFFFFFF),
    // Couleur active du curseur
    sliderActiveColor: Colors.white,
    // Couleur inactive du curseur
    sliderInactiveColor: Color(0x4DFFFFFF), // Colors.white.withOpacity(0.3)
    // Couleur de l'overlay
    overlayColor: Color(0x1FFFFFFF), // Colors.white.withOpacity(0.1)
    // Couleur pour les bordures pointillées
    dottedBorderColor: Color.fromARGB(255, 165, 165, 165), // Colors.white.withOpacity(0.2)
    
    // Accent et Actions
    // Couleur d'accentuation principale
    primaryAccent: Color.fromARGB(255, 187, 188, 189),
    // Couleur d'accentuation secondaire
    secondaryAccent: Color.fromARGB(255, 152, 152, 152),
  );

  // Thème Clair
  static const lightTheme = AppThemeColors(
    // Arrière-plan de l'en-tête
    headerBackground: Color.fromARGB(245, 186, 186, 186),
    // Arrière-plan du drawer
    drawerBackground: Color.fromARGB(255, 209, 213, 216),
    // Arrière-plan des conteneurs
    containerBackground: Color.fromARGB(255, 174, 174, 174),
    // Arrière-plan des boutons
    buttonBackground: Color.fromARGB(255, 239, 239, 239),
    // Arrière-plan des boutons désactivés
    buttonBackgroundDisabled: Color.fromARGB(255, 191, 191, 191), // Colors.grey[300]
    // Arrière-plan transparent
    transparentBackground: Color.fromARGB(126, 169, 169, 169),

    // Couleurs du texte et des icônes
    // Texte principal
    primaryText: Color(0xFF212121),
    // Texte secondaire
    secondaryText: Color(0xFF757575),
    // Couleur des icônes
    iconColor: Color.fromARGB(255, 54, 54, 54),
    // Couleur des icônes désactivées
    disabledIconColor: Color.fromARGB(255, 65, 65, 65),

    // Éléments d'interface
    // Couleur des séparateurs
    dividerColor: Color.fromARGB(141, 54, 54, 54),
    // Couleur de survol
    hoverColor: Color(0x1F000000),
    // Couleur active du curseur
    sliderActiveColor: Colors.black,
    // Couleur inactive du curseur
    sliderInactiveColor: Color(0x4D9E9E9E), // Colors.grey[400].withOpacity(0.3)
    // Couleur de l'overlay
    overlayColor: Color(0x1FEEEEEE), // Colors.grey[200].withOpacity(0.1)
    // Couleur pour les bordures pointillées
    dottedBorderColor: Color.fromARGB(141, 54, 54, 54), // Colors.black.withOpacity(0.2)
    
    // Accent et Actions
    // Couleur d'accentuation principale
    primaryAccent: Color.fromARGB(255, 238, 234, 230),
    // Couleur d'accentuation secondaire
    secondaryAccent: Color.fromARGB(255, 209, 221, 226),
  );

  // Thème actif (à définir selon le thème choisi)
  static AppThemeColors current = lightTheme;
}

// Classe pour regrouper les couleurs du thème
class AppThemeColors {
  final Color headerBackground;
  final Color drawerBackground;
  final Color containerBackground;
  final Color buttonBackground;
  final Color buttonBackgroundDisabled;
  final Color transparentBackground;
  final Color primaryText;
  final Color secondaryText;
  final Color iconColor;
  final Color disabledIconColor;
  final Color dividerColor;
  final Color hoverColor;
  final Color sliderActiveColor;
  final Color sliderInactiveColor;
  final Color overlayColor;
  final Color dottedBorderColor;
  final Color primaryAccent;
  final Color secondaryAccent;

  const AppThemeColors({
    required this.headerBackground,
    required this.drawerBackground,
    required this.containerBackground,
    required this.buttonBackground,
    required this.buttonBackgroundDisabled,
    required this.transparentBackground,
    required this.primaryText,
    required this.secondaryText,
    required this.iconColor,
    required this.disabledIconColor,
    required this.dividerColor,
    required this.hoverColor,
    required this.sliderActiveColor,
    required this.sliderInactiveColor,
    required this.overlayColor,
    required this.dottedBorderColor,
    required this.primaryAccent,
    required this.secondaryAccent,
  });
}
