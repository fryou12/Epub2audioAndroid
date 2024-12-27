import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'services/tts_service.dart';
import 'widgets/settings_page.dart';
import 'widgets/tts_drawer.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EPUB to Audio',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2196F3),
          primary: const Color(0xFF2196F3),
          secondary: const Color(0xFF03A9F4),
        ),
        useMaterial3: true,
      ),
      home: const MyHomePage(),
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
  bool _showSettings = false;
  String? _selectedFilePath;
  bool _isProcessing = false;
  bool _isAnalyzing = false;

  @override
  void initState() {
    super.initState();
    _initializeTTS();
  }

  Future<void> _initializeTTS() async {
    await _ttsService.initialize();
  }

  void _handleVoiceSelected(String voice) {
    _ttsService.setVoice(voice);
    Navigator.pop(context);
  }

  void _handleSettingsPressed() {
    setState(() {
      _showSettings = true;
    });
    Navigator.pop(context);
  }

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['epub'],
    );

    if (result != null) {
      setState(() {
        _selectedFilePath = result.files.single.path;
        _isAnalyzing = false;
        _isProcessing = false;
      });
    }
  }

  Future<void> _analyzeBook() async {
    if (_selectedFilePath == null) return;

    setState(() {
      _isAnalyzing = true;
    });

    try {
      // Logique d'analyse du livre
      await Future.delayed(const Duration(seconds: 2)); // Simulation
    } finally {
      setState(() {
        _isAnalyzing = false;
      });
    }
  }

  Future<void> _processBook() async {
    if (_selectedFilePath == null) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      // Logique de traitement du livre
      await Future.delayed(const Duration(seconds: 2)); // Simulation
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.white),
          onPressed: () {
            Scaffold.of(context).openDrawer();
          },
        ),
        title: Row(
          children: [
            const Icon(Icons.book, color: Colors.white),
            const SizedBox(width: 10),
            Text(
              _showSettings ? 'Paramètres' : 'EPUB to Audio',
              style: const TextStyle(color: Colors.white),
            ),
          ],
        ),
        actions: [
          if (!_showSettings)
            IconButton(
              icon: const Icon(Icons.settings, color: Colors.white),
              onPressed: () {
                setState(() {
                  _showSettings = true;
                });
              },
            ),
        ],
      ),
      drawer: TTSDrawer(
        onVoiceSelected: _handleVoiceSelected,
        onSettingsPressed: _handleSettingsPressed,
      ),
      body: _showSettings
          ? const SettingsPage()
          : Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    Colors.white,
                  ],
                ),
              ),
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Card(
                        elevation: 8,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(
                            color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                            width: 2,
                            style: BorderStyle.solid,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            children: [
                              if (_selectedFilePath == null) ...[
                                const Icon(
                                  Icons.upload_file,
                                  size: 64,
                                  color: Colors.blue,
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'Sélectionnez un fichier EPUB pour commencer',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 24),
                                ElevatedButton.icon(
                                  onPressed: _pickFile,
                                  icon: const Icon(Icons.file_upload),
                                  label: const Text(
                                    'Choisir un fichier',
                                    style: TextStyle(fontSize: 16),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 24,
                                      vertical: 16,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                  ),
                                ),
                              ] else ...[
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.description,
                                      size: 24,
                                      color: Colors.blue,
                                    ),
                                    const SizedBox(width: 8),
                                    Flexible(
                                      child: Text(
                                        'Fichier : ${_selectedFilePath!.split('/').last}',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 24),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  children: [
                                    ElevatedButton.icon(
                                      onPressed: _pickFile,
                                      icon: const Icon(Icons.file_upload),
                                      label: const Text('Changer'),
                                      style: ElevatedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 20,
                                          vertical: 12,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(30),
                                        ),
                                      ),
                                    ),
                                    ElevatedButton.icon(
                                      onPressed: _isAnalyzing ? null : _analyzeBook,
                                      icon: _isAnalyzing
                                          ? const SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                              ),
                                            )
                                          : const Icon(Icons.analytics),
                                      label: Text(_isAnalyzing ? 'Analyse...' : 'Analyser'),
                                      style: ElevatedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 20,
                                          vertical: 12,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(30),
                                        ),
                                      ),
                                    ),
                                    ElevatedButton.icon(
                                      onPressed: _isProcessing ? null : _processBook,
                                      icon: _isProcessing
                                          ? const SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                              ),
                                            )
                                          : const Icon(Icons.play_arrow),
                                      label: Text(_isProcessing ? 'Conversion...' : 'Convertir'),
                                      style: ElevatedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 20,
                                          vertical: 12,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(30),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  @override
  void dispose() {
    _ttsService.dispose();
    super.dispose();
  }
}
