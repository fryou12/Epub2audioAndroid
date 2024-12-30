import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'widgets/app_drawer.dart';
import 'constants/colors.dart';
import 'services/tts_service.dart';
import 'services/epub_service.dart';
import 'models/chapter.dart';
import 'providers/theme_provider.dart';
import 'providers/extractor_provider.dart';
import 'package:provider/provider.dart';
import 'widgets/dotted_container.dart';
import 'widgets/chapter_tiles.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => ExtractorProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'ePub to Audio',
          theme: themeProvider.isDarkTheme ? ThemeData.dark() : ThemeData.light(),
          home: const MyHomePage(),
        );
      },
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final TTSService _ttsService = TTSService();
  String? _selectedFilePath;
  String? _selectedDirectoryPath;
  bool _isAnalyzing = false;
  List<Chapter> _extractedChapters = [];

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['epub'],
      );

      if (result != null) {
        setState(() {
          _selectedFilePath = result.files.single.path;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la sélection du fichier: ${e.toString()}')),
      );
    }
  }

  Future<void> _pickDirectory() async {
    try {
      String? result = await FilePicker.platform.getDirectoryPath();

      if (result != null) {
        setState(() {
          _selectedDirectoryPath = result;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la sélection du dossier: ${e.toString()}')),
      );
    }
  }

  String _getFileName() {
    if (_selectedFilePath == null) return '';
    return _selectedFilePath!.split('/').last;
  }

  String _getDirectoryName() {
    if (_selectedDirectoryPath == null) return '';
    return _selectedDirectoryPath!.split('/').last;
  }

  Future<void> _analyzeEpub() async {
    if (_selectedFilePath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner un fichier ePub')),
      );
      return;
    }

    if (_selectedDirectoryPath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner un dossier de sortie')),
      );
      return;
    }

    // Request storage permissions
    if (Platform.isAndroid) {
      final status = await Permission.storage.request();
      if (!status.isGranted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Permission de stockage requise pour analyser le fichier')),
        );
        return;
      }
    }

    setState(() {
      _isAnalyzing = true;
      _extractedChapters = [];
    });

    try {
      final chapters = await EpubService.extractChapters(_selectedFilePath!);

      setState(() {
        _extractedChapters = chapters;
      });

      await EpubService.saveChapters(chapters, _selectedDirectoryPath!);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Analyse terminée avec succès')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de l\'analyse: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isAnalyzing = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _loadThemePreference(); // Load the theme preference
  }

  void _loadThemePreference() async {
    await ThemeProvider().loadThemePreference();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: AppColors.current.headerBackground,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          appBarTheme: AppBarTheme(
            backgroundColor: AppColors.current.headerBackground,
            systemOverlayStyle: SystemUiOverlayStyle(
              statusBarColor: AppColors.current.headerBackground,
              statusBarIconBrightness: Brightness.light,
              statusBarBrightness: Brightness.dark,
            ),
          ),
        ),
        child: Scaffold(
          backgroundColor: AppColors.current.background,
          appBar: PreferredSize(
            preferredSize: Size.fromHeight(kToolbarHeight),
            child: AppBar(
              backgroundColor: AppColors.current.headerBackground,
              elevation: 0,
              centerTitle: true,
              flexibleSpace: Container(
                decoration: BoxDecoration(
                  color: AppColors.current.headerBackground,
                ),
              ),
              title: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.menu_book_outlined,
                    color: AppColors.current.iconColor,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  const Text('ePub to Audio'),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.volume_up,
                    color: AppColors.current.iconColor,
                    size: 24,
                  ),
                ],
              ),
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(0.5),
                child: Container(
                  height: 0.5,
                  color: AppColors.current.dividerColor,
                ),
              ),
            ),
          ),
          drawer: const AppDrawer(),
          body: Stack(
            children: [
              Positioned(
                top: -MediaQuery.of(context).padding.top,
                left: 8,
                right: 8,
                bottom: 8,
                child: const DottedContainer(),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),
                      // Bouton Fichier
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          ElevatedButton.icon(
                            icon: Icon(
                              Icons.file_present_outlined,
                              color: AppColors.current.iconColor,
                            ),
                            label: Text(
                              'Fichier',
                              style: TextStyle(
                                color: AppColors.current.primaryText,
                              ),
                            ),
                            onPressed: _pickFile,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.current.buttonBackground,
                              foregroundColor: AppColors.current.primaryText,
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (_selectedFilePath != null)
                            Expanded(
                              child: Text(
                                _getFileName(),
                                style: TextStyle(
                                  color: AppColors.current.primaryText,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Bouton Dossier
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          ElevatedButton.icon(
                            icon: Icon(
                              Icons.folder_outlined,
                              color: AppColors.current.iconColor,
                            ),
                            label: Text(
                              'Dossier',
                              style: TextStyle(
                                color: AppColors.current.primaryText,
                              ),
                            ),
                            onPressed: _pickDirectory,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.current.buttonBackground,
                              foregroundColor: AppColors.current.primaryText,
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (_selectedDirectoryPath != null)
                            Expanded(
                              child: Text(
                                _getDirectoryName(),
                                style: TextStyle(
                                  color: AppColors.current.primaryText,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Boutons Analyser et Convertir
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton.icon(
                            icon: Icon(
                              Icons.analytics_outlined,
                              color: AppColors.current.iconColor,
                            ),
                            label: Text(
                              'Analyser',
                              style: TextStyle(
                                color: AppColors.current.primaryText,
                              ),
                            ),
                            onPressed: _selectedFilePath != null ? _analyzeEpub : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.current.buttonBackground,
                              foregroundColor: AppColors.current.primaryText,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          ElevatedButton.icon(
                            icon: Icon(
                              Icons.audiotrack_outlined,
                              color: AppColors.current.iconColor,
                            ),
                            label: Text(
                              'Convertir',
                              style: TextStyle(
                                color: AppColors.current.primaryText,
                              ),
                            ),
                            onPressed: _selectedDirectoryPath != null ? () {
                              // TODO: Implement conversion
                            } : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.current.buttonBackground,
                              foregroundColor: AppColors.current.primaryText,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Section des chapitres
                      Expanded(
                        child: Column(
                          children: [
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              alignment: Alignment.center,
                              child: Text(
                                'Chapitres',
                                style: TextStyle(
                                  color: AppColors.current.primaryText,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            if (_extractedChapters.isNotEmpty)
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.only(
                                    left: 16,
                                    right: 16,
                                    bottom: 16,
                                  ),
                                  child: ChapterTiles(chapters: _extractedChapters),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}