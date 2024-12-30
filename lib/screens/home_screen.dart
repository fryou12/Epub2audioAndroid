import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../widgets/app_drawer.dart';
import '../widgets/dotted_container.dart';
import '../widgets/chapter_list.dart';
import '../constants/colors.dart';
import '../services/epub_service.dart';
import '../models/chapter.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? selectedFilePath;
  String? selectedDirectoryPath;
  List<Chapter> chapters = [];
  bool isAnalyzing = false;
  String? error;

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['epub'],
      );

      if (result != null) {
        setState(() {
          selectedFilePath = result.files.single.path;
          chapters = [];
          error = null;
        });
      }
    } catch (e) {
      setState(() {
        error = 'Erreur lors de la sélection du fichier: $e';
      });
    }
  }

  Future<void> _pickDirectory() async {
    try {
      String? result = await FilePicker.platform.getDirectoryPath();

      if (result != null) {
        setState(() {
          selectedDirectoryPath = result;
          error = null;
        });
      }
    } catch (e) {
      setState(() {
        error = 'Erreur lors de la sélection du dossier: $e';
      });
    }
  }

  Future<void> _analyzeEpub() async {
    if (selectedFilePath == null || selectedDirectoryPath == null) return;

    setState(() {
      isAnalyzing = true;
      error = null;
    });

    try {
      final extractedChapters = await EpubService.extractChapters(selectedFilePath!);
      if (extractedChapters.isEmpty) {
        throw Exception('Aucun chapitre trouvé dans le fichier EPUB');
      }

      await EpubService.saveChapters(extractedChapters, selectedDirectoryPath!);

      setState(() {
        chapters = extractedChapters;
        isAnalyzing = false;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        isAnalyzing = false;
      });
    }
  }

  String _getFileName() {
    if (selectedFilePath == null) return '';
    return selectedFilePath!.split('/').last;
  }

  String _getDirectoryName() {
    if (selectedDirectoryPath == null) return '';
    return selectedDirectoryPath!.split('/').last;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkTheme.drawerBackground,
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.darkTheme.headerBackground,
            border: const Border(
              bottom: BorderSide(
                color: Colors.white,
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
                icon: const Icon(Icons.menu, color: Colors.white),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
            ),
            title: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.menu_book_outlined, color: Colors.white, size: 24),
                SizedBox(width: 8),
                Text(
                  'ePub vers Audio',
                  style: TextStyle(color: Colors.white),
                ),
                SizedBox(width: 8),
                Icon(Icons.volume_up, color: Colors.white, size: 24),
              ],
            ),
          ),
        ),
      ),
      drawer: const AppDrawer(),
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
                      Wrap(
                        spacing: 8,
                        children: [
                          ElevatedButton.icon(
                            icon: const Icon(Icons.file_present_outlined, color: Colors.white),
                            label: Text(
                              selectedFilePath != null ? _getFileName() : 'Fichier',
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Colors.white),
                            ),
                            onPressed: _pickFile,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey[800],
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: [
                          ElevatedButton.icon(
                            icon: const Icon(Icons.folder_outlined, color: Colors.white),
                            label: Text(
                              selectedDirectoryPath != null ? _getDirectoryName() : 'Dossier',
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Colors.white),
                            ),
                            onPressed: _pickDirectory,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey[800],
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          ElevatedButton.icon(
                            icon: const Icon(Icons.analytics_outlined, color: Colors.white),
                            label: Text(isAnalyzing ? 'Analyse...' : 'Analyser'),
                            onPressed: (selectedFilePath != null && selectedDirectoryPath != null && !isAnalyzing)
                                ? _analyzeEpub
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey[800],
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            ),
                          ),
                          if (chapters.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            ElevatedButton.icon(
                              icon: const Icon(Icons.music_note_outlined, color: Colors.white),
                              label: const Text('Convertir'),
                              onPressed: () {},
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.grey[800],
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                  if (error != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red[900]!.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red[900]!),
                      ),
                      child: Text(
                        error!,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                  if (chapters.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Text(
                      'Chapitres',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ChapterList(chapters: chapters),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
