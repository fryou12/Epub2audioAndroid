import 'dart:io';
import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math' as math;
import 'package:path/path.dart' as path;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:dotted_border/dotted_border.dart';
import '../widgets/app_drawer.dart';
import '../services/epub_processor.dart';
import '../providers/tts_provider.dart';
import '../services/conversion_service.dart';
import '../services/chapter_conversion_service.dart';
import '../providers/conversion_settings_provider.dart';
import '../models/chapter.dart';
import 'package:flutter/services.dart';

class DotPattern extends CustomPainter {
  final Color dotColor;
  final double spacing;
  final double dotSize;

  DotPattern({
    required this.dotColor,
    this.spacing = 24,
    this.dotSize = 2,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = dotColor
      ..style = PaintingStyle.fill;

    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(
          Offset(x, y),
          dotSize / 2,
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> with SingleTickerProviderStateMixin {
  String? _selectedFilePath;
  String? _selectedDirectoryPath;
  List<Chapter> _chapters = [];
  bool _isProcessing = false;
  bool _isConverting = false;
  int _currentChapterIndex = -1;
  final EpubProcessor _epubProcessor = EpubProcessor();
  late final AnimationController _rotationController;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  String? _getFileName(String? filePath) {
    if (filePath == null) return null;
    return path.basename(filePath);
  }

  String? _getDirectoryName(String? dirPath) {
    if (dirPath == null) return null;
    return path.basename(dirPath);
  }

  String _formatChapterNumber(int number) {
    // Ajoute un zéro devant les nombres de 1 à 9
    return number.toString().padLeft(2, '0');
  }

  Future<bool> _requestStoragePermissions() async {
    if (Platform.isAndroid) {
      // Pour Android 11 (API 30) et supérieur
      if (await Permission.manageExternalStorage.status.isGranted) {
        return true;
      }

      // Demander la permission MANAGE_EXTERNAL_STORAGE
      final status = await Permission.manageExternalStorage.request();
      if (status.isGranted) {
        return true;
      }

      // Si la permission est refusée définitivement
      if (status.isPermanentlyDenied) {
        if (context.mounted) {
          final openSettings = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Permissions requises'),
              content: const Text(
                'Cette application nécessite l\'accès au stockage pour sauvegarder les fichiers audio. '
                'Veuillez activer les permissions dans les paramètres.'
              ),
              actions: [
                TextButton(
                  child: const Text('Annuler'),
                  onPressed: () => Navigator.of(context).pop(false),
                ),
                TextButton(
                  child: const Text('Ouvrir les paramètres'),
                  onPressed: () => Navigator.of(context).pop(true),
                ),
              ],
            ),
          );

          if (openSettings == true) {
            await openAppSettings();
          }
        }
        return false;
      }
      return false;
    }
    return true;
  }

  Future<String?> _pickEpubFile(BuildContext context) async {
    if (!await _requestStoragePermissions()) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Permission d\'accès au stockage requise'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return null;
    }

    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['epub'],
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          _selectedFilePath = result.files.single.path!;
        });
        return result.files.single.path!;
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la sélection du fichier: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
    return null;
  }

  Future<String?> _pickExportDirectory(BuildContext context) async {
    if (!await _requestStoragePermissions()) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Permission d\'accès au stockage requise'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return null;
    }

    try {
      String? result = await FilePicker.platform.getDirectoryPath();
      
      if (result != null) {
        setState(() {
          _selectedDirectoryPath = result;
        });
        return result;
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la sélection du dossier: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
    return null;
  }

  Future<void> _processEpubFile() async {
    if (_selectedFilePath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez d\'abord sélectionner un fichier ePub'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isProcessing = true;
      _chapters = [];
    });

    try {
      final chapters = await _epubProcessor.processEpubFile(_selectedFilePath!);
      setState(() {
        _chapters = chapters;
      });
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de l\'analyse du fichier: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  static const platform = MethodChannel('com.example.epub_to_audio/service');

  Future<void> _startConversion() async {
    try {
      await platform.invokeMethod('startConversionService');
    } catch (e) {
      print('Erreur lors du démarrage du service de conversion: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du démarrage de la conversion: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _stopConversion() async {
    try {
      await platform.invokeMethod('stopConversionService');
    } catch (e) {
      print('Erreur lors de l\'arrêt du service de conversion: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de l\'arrêt de la conversion: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _convertToAudio() async {
    // Vérifier le dossier de destination avant de commencer
    if (!await _checkDestinationDirectory()) {
      return;
    }

    setState(() {
      _isConverting = true;
      _currentChapterIndex = 0;
    });

    try {
      final ttsService = ref.read(ttsServiceProvider);
      if (ttsService == null) {
        throw Exception('Service TTS non disponible');
      }

      final selectedVoice = ref.read(selectedVoiceProvider);
      if (selectedVoice == null) {
        throw Exception('Aucune voix sélectionnée');
      }

      // Récupérer le nombre maximum de chapitres simultanés depuis les paramètres
      final settings = ref.read(conversionSettingsProvider.notifier).state;
      final maxConcurrent = settings.maxConcurrentChapters.toInt();

      // Créer le service de conversion
      final conversionService = ChapterConversionService(
        ttsService: ttsService,
        outputDirectory: _selectedDirectoryPath!,
        chapters: _chapters,
        onProgressUpdate: (progress) {
          if (mounted) {
            setState(() {
              _currentChapterIndex = (_chapters.length * progress / 100).round() - 1;
            });
          }
        },
        onError: (error) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(error),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        maxConcurrentConversions: ref.read(conversionSettingsProvider).maxConcurrentConversions,
      );

      // Démarrer la conversion
      await _startConversion();
      await conversionService.startConversion();

      if (mounted && _isConverting) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Conversion terminée avec succès !'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la conversion: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isConverting = false;
        });
      }
    }
  }

  Future<bool> _checkDestinationDirectory() async {
    if (_selectedDirectoryPath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner un dossier de destination'),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }

    // Vérifier les permissions avant de continuer
    if (!await _requestStoragePermissions()) {
      return false;
    }

    try {
      final directory = Directory(_selectedDirectoryPath!);
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }

      final files = await directory.list().toList();
      
      if (files.isNotEmpty) {
        final audioFiles = files.where((file) => 
          file.path.toLowerCase().endsWith('.mp3') ||
          file.path.toLowerCase().endsWith('.wav')
        ).toList();
        
        if (audioFiles.isNotEmpty) {
          if (!context.mounted) return false;
          
          final result = await showDialog<bool>(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text('Attention'),
                content: Text(
                  'Le dossier de destination contient déjà ${audioFiles.length} fichier(s) audio.\n'
                  'Voulez-vous continuer et écraser les fichiers existants ?'
                ),
                actions: <Widget>[
                  TextButton(
                    child: const Text('Non'),
                    onPressed: () {
                      Navigator.of(context).pop(false);
                    },
                  ),
                  TextButton(
                    child: const Text('Oui'),
                    onPressed: () {
                      Navigator.of(context).pop(true);
                    },
                  ),
                ],
              );
            },
          );
          
          if (result != true) {
            return false;
          }

          // Supprimer les fichiers existants après confirmation
          for (final file in audioFiles) {
            try {
              if (await File(file.path).exists()) {
                await File(file.path).delete();
              }
            } catch (e) {
              debugPrint('Erreur lors de la suppression du fichier ${file.path}: $e');
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Impossible de supprimer le fichier: ${file.path}'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
              return false;
            }
          }
        }
      }
      
      return true;
    } catch (e) {
      debugPrint('Erreur lors de la vérification du dossier: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de l\'accès au dossier: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return false;
    }
  }

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;
    final textColor = brightness == Brightness.light
        ? Colors.black
        : Colors.white;
    final backgroundColor = brightness == Brightness.light
        ? Colors.grey[100]
        : Colors.grey[900];

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: backgroundColor,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(39 + MediaQuery.of(context).padding.top),
        child: Column(
          children: [
            Container(
              color: brightness == Brightness.light
                  ? Colors.grey[300]
                  : Colors.grey[800],
              child: SafeArea(
                bottom: false,
                child: Container(
                  height: 0,
                ),
              ),
            ),
            Container(
              color: brightness == Brightness.light
                  ? Colors.grey[200]
                  : Colors.grey[850],
              child: Column(
                children: [
                  AppBar(
                    toolbarHeight: 39,
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    leading: Transform.translate(
                      offset: const Offset(0, -8.5),
                      child: IconButton(
                        icon: Icon(
                          Icons.menu,
                          color: textColor,
                          size: 24,
                        ),
                        onPressed: () {
                          _scaffoldKey.currentState?.openDrawer();
                        },
                      ),
                    ),
                    titleSpacing: 0,
                    title: Transform.translate(
                      offset: const Offset(0, -8.5),
                      child: Padding(
                        padding: EdgeInsets.only(
                          left: -MediaQuery.of(context).size.width * 0.12,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.menu_book_outlined,
                              size: 24,
                              color: textColor,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'ePub vers Audio',
                              style: TextStyle(
                                color: textColor,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Icon(
                              Icons.speaker,
                              size: 24,
                              color: textColor,
                            ),
                          ],
                        ),
                      ),
                    ),
                    centerTitle: true,
                  ),
                  Container(
                    height: 1,
                    color: Theme.of(context).brightness == Brightness.light
                        ? Colors.grey[300]
                        : Colors.grey[700],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      drawer: const AppDrawer(),
      body: Stack(
        children: [
          Positioned(
            top: -(39 + MediaQuery.of(context).padding.top),
            left: 0,
            right: 0,
            bottom: 8,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: DottedBorder(
                color: textColor,
                strokeWidth: 2,
                borderType: BorderType.RRect,
                radius: const Radius.circular(12),
                padding: const EdgeInsets.all(16),
                child: Stack(
                  children: [
                    // Motif de points
                    Positioned.fill(
                      child: CustomPaint(
                        painter: DotPattern(
                          dotColor: brightness == Brightness.light
                              ? Colors.grey[500]!.withOpacity(0.4)
                              : Colors.grey[700]!.withOpacity(0.5),
                          spacing: 24,
                          dotSize: 2,
                        ),
                      ),
                    ),
                    // Contenu existant
                    Column(
                      children: [
                        SizedBox(height: 39 + MediaQuery.of(context).padding.top - 16),
                        // Première rangée : Boutons Fichier/Dossier et noms de fichiers
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Colonne des boutons Fichier et Dossier
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ElevatedButton.icon(
                                  onPressed: () async {
                                    final selectedFile = await _pickEpubFile(context);
                                    if (selectedFile != null) {
                                      setState(() {
                                        _selectedFilePath = selectedFile;
                                      });
                                    }
                                  },
                                  icon: Icon(Icons.file_upload, color: textColor),
                                  label: Text('Fichier', style: TextStyle(color: textColor)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: brightness == Brightness.light ? Colors.white : Colors.grey[800],
                                    elevation: 2,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                ElevatedButton.icon(
                                  onPressed: () async {
                                    final selectedDirectory = await _pickExportDirectory(context);
                                    if (selectedDirectory != null) {
                                      setState(() {
                                        _selectedDirectoryPath = selectedDirectory;
                                      });
                                    }
                                  },
                                  icon: Icon(Icons.folder, color: textColor),
                                  label: Text('Dossier', style: TextStyle(color: textColor)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: brightness == Brightness.light ? Colors.white : Colors.grey[800],
                                    elevation: 2,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 16),
                            // Colonne des noms de fichier/dossier
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  if (_selectedFilePath != null)
                                    Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                                      child: Text(
                                        _getFileName(_selectedFilePath) ?? '',
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(color: textColor),
                                      ),
                                    ),
                                  if (_selectedDirectoryPath != null)
                                    Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                                      child: Text(
                                        _getDirectoryName(_selectedDirectoryPath) ?? '',
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(color: textColor),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Rangée des boutons Analyser et Convertir
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ElevatedButton.icon(
                              onPressed: _processEpubFile,
                              icon: _isProcessing 
                                ? RotationTransition(
                                    turns: _rotationController,
                                    child: Icon(Icons.refresh, color: textColor),
                                  )
                                : Icon(Icons.analytics, color: textColor),
                              label: Text('Analyser', style: TextStyle(color: textColor)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: brightness == Brightness.light ? Colors.white : Colors.grey[800],
                                elevation: 2,
                              ),
                            ),
                            const SizedBox(width: 16),
                            ElevatedButton.icon(
                              onPressed: _chapters.isNotEmpty && !_isConverting ? _convertToAudio : null,
                              icon: _isConverting
                                ? RotationTransition(
                                    turns: _rotationController,
                                    child: Icon(Icons.refresh, color: textColor),
                                  )
                                : Icon(Icons.music_note, color: textColor),
                              label: Text('Convertir', style: TextStyle(color: textColor)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: brightness == Brightness.light ? Colors.white : Colors.grey[800],
                                elevation: 2,
                                disabledBackgroundColor: brightness == Brightness.light 
                                    ? Colors.grey[300] 
                                    : Colors.grey[700],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Zone des chapitres
                        if (_chapters.isNotEmpty)
                          Expanded(
                            child: Stack(
                              children: [
                                // Liste des chapitres
                                ListView.builder(
                                  itemCount: _chapters.length,
                                  itemBuilder: (context, index) {
                                    final chapter = _chapters[index];
                                    final isCurrentChapter = index == _currentChapterIndex && _isConverting;
                                    return Card(
                                      color: isCurrentChapter 
                                        ? (brightness == Brightness.light ? Colors.grey[200] : Colors.grey[800])
                                        : (brightness == Brightness.light ? Colors.white : Colors.grey[850]),
                                      child: ListTile(
                                        leading: Text(
                                          _formatChapterNumber(index + 1),
                                          style: TextStyle(
                                            color: textColor,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        title: Text(
                                          chapter.title,
                                          style: TextStyle(color: textColor),
                                        ),
                                        subtitle: Text(
                                          chapter.content.substring(0, math.min(100, chapter.content.length)),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            color: brightness == Brightness.light 
                                                ? Colors.grey[700] 
                                                : Colors.grey[400],
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                // Shaders
                                Positioned(
                                  top: 0,
                                  left: 0,
                                  right: 0,
                                  height: 32,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          brightness == Brightness.light
                                              ? Colors.white
                                              : Colors.grey[900]!,
                                          brightness == Brightness.light
                                              ? Colors.white.withOpacity(0.0)
                                              : Colors.grey[900]!.withOpacity(0.0),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  bottom: 0,
                                  left: 0,
                                  right: 0,
                                  height: 32,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.bottomCenter,
                                        end: Alignment.topCenter,
                                        colors: [
                                          brightness == Brightness.light
                                              ? Colors.white
                                              : Colors.grey[900]!,
                                          brightness == Brightness.light
                                              ? Colors.white.withOpacity(0.0)
                                              : Colors.grey[900]!.withOpacity(0.0),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
