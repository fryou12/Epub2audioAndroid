import 'package:flutter/material.dart';

class AppColors {
  // Thème Sombre
  static const darkTheme = AppThemeColors(
    // Arrière-plan de l'en-tête
    headerBackground: Color.fromARGB(255, 62, 62, 62),
    // Arrière-plan du drawer
    drawerBackground: Color.fromARGB(255, 49, 49, 49),
    // Arrière-plan des conteneurs pointillés
    containerBackground: Color.fromARGB(255, 57, 57, 57),
    // Arrière-plan des boutons
    buttonBackground: Color(0xFF424242),
    // Arrière-plan des boutons désactivés
    buttonBackgroundDisabled: Color(0xFF616161), 
    // Arrière-plan transparent
    transparentBackground: Color.fromARGB(255, 100, 100, 100),
    // Arrière-plan général
    background: Color.fromARGB(255, 49, 49, 49),

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
    sliderInactiveColor: Color(0x4DFFFFFF),
    // Couleur de l'overlay
    overlayColor: Color(0x1FFFFFFF),
    // Couleur pour les bordures pointillées
    dottedBorderColor: Color.fromARGB(255, 165, 165, 165),
    
    // Accent et Actions
    // Couleur d'accentuation principale
    primaryAccent: Color.fromARGB(255, 100, 100, 100),
    // Couleur d'accentuation secondaire
    secondaryAccent: Color.fromARGB(255, 200, 200, 200),

    // Surface background main
    surface: Color.fromARGB(255, 120, 120, 120),
    surfaceText: Color.fromARGB(255, 206, 206, 206),
    onSurface: Color.fromARGB(255, 179, 179, 179),

    // Couleurs des tuiles de chapitre
    chapterTileBackground: Color.fromARGB(255, 57, 57, 57),
    chapterTileBorder: Color.fromARGB(255, 62, 62, 62),
    chapterTileTitle: Color.fromARGB(255, 206, 206, 206),
    chapterTileText: Color.fromARGB(179, 117, 117, 117),
    chapterTileWordCount: Color.fromARGB(188, 148, 147, 147),
  );

  // Thème Clair
  static const lightTheme = AppThemeColors(
    // Arrière-plan de l'en-tête
    headerBackground: Color.fromARGB(255, 186, 186, 186),
    // Arrière-plan du drawer
    drawerBackground: Color.fromARGB(255, 232, 232, 232),
    // Arrière-plan des conteneurs pointillés
    containerBackground: Color.fromARGB(255, 220, 220, 220),
    // Arrière-plan des boutons
    buttonBackground: Color.fromARGB(255, 239, 239, 239),
    // Arrière-plan des boutons désactivés
    buttonBackgroundDisabled: Color.fromARGB(255, 191, 191, 191), // Colors.grey[300]
    // Arrière-plan transparent
    transparentBackground: Color.fromARGB(126, 169, 169, 169),
    // Arrière-plan général
    background: Color.fromARGB(255, 255, 255, 255),

    // Couleurs du texte et des icônes
    // Texte principal
    primaryText: Color(0xFF212121),
    // Texte secondaire
    secondaryText: Color(0xFF757575),
    // Couleur des icônes
    iconColor: Color.fromARGB(255, 54, 54, 54),
    // Couleur des icônes désactivées
    disabledIconColor: Color.fromARGB(255, 65, 65, 65),

   
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
    primaryAccent: Color.fromARGB(255, 100, 100, 100),
    // Couleur d'accentuation secondaire
    secondaryAccent: Color.fromARGB(255, 200, 200, 200),

    // Surface background main
    surface: Color.fromARGB(255, 210, 210, 210),
    surfaceText: Color(0xFF212121),
    onSurface: Color.fromARGB(255, 54, 54, 54),

    // Couleurs des tuiles de chapitre
    chapterTileBackground: Color.fromARGB(255, 255, 255, 255),
    chapterTileBorder: Color.fromARGB(255, 230, 230, 230),
    chapterTileTitle: Color(0xFF212121),
    chapterTileText: Color(0xFF757575),
    chapterTileWordCount: Color(0xFFAAAAAA),
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
  final Color background;

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

  final Color surface;
  final Color surfaceText;
  final Color onSurface;

  final Color chapterTileBackground;
  final Color chapterTileBorder;
  final Color chapterTileTitle;
  final Color chapterTileText;
  final Color chapterTileWordCount;

  const AppThemeColors({
    required this.headerBackground,
    required this.drawerBackground,
    required this.containerBackground,
    required this.buttonBackground,
    required this.buttonBackgroundDisabled,
    required this.transparentBackground,
    required this.background,
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
    required this.surface,
    required this.surfaceText,
    required this.onSurface,
    required this.chapterTileBackground,
    required this.chapterTileBorder,
    required this.chapterTileTitle,
    required this.chapterTileText,
    required this.chapterTileWordCount,
  });
}
