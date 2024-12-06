import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class PythonEnvironment {
  String? pythonPath;
  String? pipPath;
  bool _isInitialized = false;
  
  static const platform = MethodChannel('com.example.epub_to_audio/python');

  static final PythonEnvironment _instance = PythonEnvironment._internal();
  factory PythonEnvironment() => _instance;
  PythonEnvironment._internal();

  Future<bool> checkPythonVersion() async {
    if (Platform.isAndroid) return true; // Géré par Chaquopy
    
    if (pythonPath == null) return false;
    
    try {
      final result = await Process.run(pythonPath!, ['--version']);
      if (result.exitCode != 0) return false;
      
      final version = result.stdout.toString().toLowerCase();
      debugPrint('Python version: $version');
      if (!version.contains('python 3')) {
        throw Exception(
          'Version de Python incompatible: $version\n'
          'Python 3.x est requis.'
        );
      }
      return true;
    } catch (e) {
      debugPrint('Erreur lors de la vérification de la version Python: $e');
      return false;
    }
  }

  Future<String?> _findExecutable(String name) async {
    if (Platform.isAndroid) {
      return name; // Sur Android, nous utilisons Chaquopy
    }

    final commands = [
      name,
      'python3',
      'python3.10',
      'python3.11',
      '/usr/local/bin/$name',
      '/usr/bin/$name',
      '/opt/homebrew/bin/$name',
      '${Platform.environment['HOME']}/.local/bin/$name',
      '/Library/Frameworks/Python.framework/Versions/3.10/bin/$name',
      '/Library/Frameworks/Python.framework/Versions/3.11/bin/$name',
    ];

    for (final cmd in commands) {
      try {
        final result = await Process.run('which', [cmd]);
        if (result.exitCode == 0 && result.stdout.toString().trim().isNotEmpty) {
          return result.stdout.toString().trim();
        }
      } catch (_) {
        continue;
      }
    }
    return null;
  }

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      if (Platform.isAndroid) {
        // Vérifier si Chaquopy est disponible
        try {
          await platform.invokeMethod('checkPythonAvailable');
          pythonPath = 'python3';
          pipPath = 'pip3';
          _isInitialized = true;
          debugPrint('Chaquopy initialized successfully');
          return;
        } catch (e) {
          debugPrint('Error initializing Chaquopy: $e');
          throw Exception(
            'Erreur lors de l\'initialisation de Python sur Android.\n'
            'Veuillez réessayer ou redémarrer l\'application.'
          );
        }
      }

      // Pour les autres plateformes
      pythonPath = await _findExecutable('python');
      if (pythonPath == null) {
        throw Exception(
          'Python n\'est pas disponible.\n'
          'Veuillez installer Python 3.x.'
        );
      }

      if (!await checkPythonVersion()) {
        throw Exception(
          'La version de Python n\'est pas compatible.\n'
          'Python 3.x est requis.'
        );
      }

      pipPath = await _findExecutable('pip');
      if (pipPath == null) {
        try {
          final result = await Process.run(
            pythonPath!,
            ['-m', 'ensurepip', '--upgrade', '--user'],
          );
          
          if (result.exitCode != 0) {
            throw Exception(
              'pip n\'est pas disponible et l\'installation a échoué.'
            );
          }
          
          pipPath = await _findExecutable('pip');
        } catch (e) {
          debugPrint('Erreur lors de l\'installation de pip: $e');
          rethrow;
        }
      }

      if (pipPath == null) {
        throw Exception('Impossible de trouver ou d\'installer pip');
      }

      _isInitialized = true;
      debugPrint('Python environment initialized successfully');
      debugPrint('Python path: $pythonPath');
      debugPrint('Pip path: $pipPath');
    } catch (e) {
      debugPrint('Error initializing Python environment: $e');
      rethrow;
    }
  }

  Future<void> installPackage(String packageName) async {
    if (!_isInitialized) {
      throw Exception('Python environment not initialized');
    }

    try {
      if (Platform.isAndroid) {
        // Sur Android, les packages sont déjà installés via Chaquopy
        return;
      }

      debugPrint('Installing package: $packageName');
      final result = await Process.run(
        pipPath!,
        ['install', '--user', packageName],
      );

      if (result.exitCode != 0) {
        throw Exception(
          'Erreur lors de l\'installation du package $packageName:\n'
          '${result.stderr}'
        );
      }
      debugPrint('Package $packageName installed successfully');
    } catch (e) {
      debugPrint('Error installing package $packageName: $e');
      rethrow;
    }
  }

  Future<bool> isPackageInstalled(String packageName) async {
    if (!_isInitialized) {
      throw Exception('Python environment not initialized');
    }

    if (Platform.isAndroid) {
      // Sur Android, les packages sont déjà installés via Chaquopy
      return true;
    }

    try {
      final result = await Process.run(
        pipPath!,
        ['show', packageName],
      );
      return result.exitCode == 0;
    } catch (e) {
      return false;
    }
  }
}
