# ePub to Audio

Une application Flutter pour convertir des fichiers ePub en fichiers audio en utilisant la synthèse vocale.

## Fonctionnalités

- Interface utilisateur moderne et intuitive
- Sélection de fichiers ePub
- Sélection du dossier de sortie
- Analyse du contenu ePub
- Conversion en audio
- Paramètres personnalisables

## Structure du projet

```
lib/
  ├── constants/
  │   └── colors.dart
  ├── screens/
  │   └── home_screen.dart
  ├── widgets/
  │   ├── app_drawer.dart
  │   └── dotted_container.dart
  └── main.dart
```

## Dépendances

Les principales dépendances du projet sont :

- Flutter SDK
- file_picker (pour la sélection de fichiers)
- flutter_riverpod (pour la gestion d'état)
- path_provider (pour la gestion des chemins)
- epub_parser (pour l'analyse des fichiers ePub)
- flutter_tts (pour la synthèse vocale)
- just_audio (pour la lecture audio)

## Installation

1. Clonez le dépôt
2. Exécutez `flutter pub get` pour installer les dépendances
3. Lancez l'application avec `flutter run`

## Licence

Ce projet est sous licence MIT.
