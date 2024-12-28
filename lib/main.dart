import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'widgets/app_drawer.dart';
import 'widgets/dotted_container.dart';
import 'constants/colors.dart';
import 'services/tts_service.dart';
import 'providers/theme_provider.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final themeProvider = ThemeProvider();
  await themeProvider.loadThemePreference();
  AppColors.current = themeProvider.isDarkTheme ? AppColors.darkTheme : AppColors.lightTheme;
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: themeProvider),
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
          title: 'EPUB to Audio',
          theme: themeProvider.isDarkTheme ? ThemeData.dark() : ThemeData.light(),
          home: MyHomePage(),
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
  /// TODO: Use this field in your widget tree
  final _ttsService = TTSService(); 

  /// TODO: Use this field in your widget tree
  final bool _showSettings = false; 

  String? _selectedFilePath;
  String? _selectedDirectoryPath;

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
      debugPrint('Erreur lors de la sélection du fichier: $e');
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
      debugPrint('Erreur lors de la sélection du dossier: $e');
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
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.current.headerBackground,
            border: Border(
              bottom: BorderSide(
                color: AppColors.current.dividerColor,
                width: 1,
              ),
            ),
          ),
          child: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            centerTitle: true,
            leading: Builder(
              builder: (context) => IconButton(
                icon: Icon(
                  Icons.menu,
                  color: AppColors.current.iconColor,
                ),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
            ),
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.menu_book_outlined, 
                  color: AppColors.current.iconColor, 
                  size: 24
                ),
                const SizedBox(width: 8),
                Text(
                  'ePub vers Audio',
                  style: TextStyle(
                    color: AppColors.current.primaryText,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.volume_up, 
                  color: AppColors.current.iconColor, 
                  size: 24
                ),
              ],
            ),
          ),
        ),
      ),
      drawer: AppDrawer(),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.only(
              left: 8.0,
              right: 8.0,
              bottom: 8.0,
            ),
            child: Center(
              child: SizedBox(
                width: MediaQuery.of(context).size.width - 16,
                child: const DottedContainer(),
              ),
            ),
          ),
          SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                16,
                kToolbarHeight + MediaQuery.of(context).padding.top + 16,
                16,
                16,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
                              minimumSize: const Size(100, 40),
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
                                maxLines: 1,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
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
                              minimumSize: const Size(100, 40),
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
                                maxLines: 1,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            ElevatedButton.icon(
                              icon: Icon(Icons.analytics_outlined, color: AppColors.current.iconColor),
                              label: Text(
                                'Analyser',
                                style: TextStyle(color: AppColors.current.primaryText),
                              ),
                              onPressed: _selectedFilePath != null ? () {
                                _ttsService.speak('Analyzing file...');
                              } : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.current.buttonBackground,
                                foregroundColor: AppColors.current.primaryText,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                minimumSize: const Size(100, 40),
                              ).copyWith(
                                backgroundColor: MaterialStateProperty.resolveWith<Color?>(
                                  (Set<MaterialState> states) {
                                    if (states.contains(MaterialState.disabled)) {
                                      return AppColors.current.buttonBackground.withOpacity(0.75);
                                    }
                                    return AppColors.current.buttonBackground;
                                  },
                                ),
                              ),
                            ),
                            ElevatedButton.icon(
                              icon: Icon(Icons.audiotrack_outlined, color: AppColors.current.iconColor),
                              label: Text(
                                'Convertir',
                                style: TextStyle(color: AppColors.current.primaryText),
                              ),
                              onPressed: _selectedDirectoryPath != null ? () {
                                if (_showSettings) {
                                  showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: Text('Settings'),
                                      content: Text('Settings content goes here'),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.of(context).pop(),
                                          child: Text('Close'),
                                        ),
                                      ],
                                    ),
                                  );
                                } else {
                                  _ttsService.speak('Proceeding with action...');
                                }
                              } : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.current.buttonBackground,
                                foregroundColor: AppColors.current.primaryText,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                minimumSize: const Size(100, 40),
                              ).copyWith(
                                backgroundColor: MaterialStateProperty.resolveWith<Color?>(
                                  (Set<MaterialState> states) {
                                    if (states.contains(MaterialState.disabled)) {
                                      return AppColors.current.buttonBackground.withOpacity(0.75);
                                    }
                                    return AppColors.current.buttonBackground;
                                  },
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
        ],
      ),
    );
  }
}
