import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

class SafeLogger {
  static final SafeLogger _instance = SafeLogger._internal();
  factory SafeLogger() => _instance;
  SafeLogger._internal();

  final List<String> _logBuffer = [];
  Timer? _saveTimer;
  File? _logFile;
  final _logController = StreamController<String>.broadcast();

  /// Use this method instead of print()
  void log(String message, {String type = 'LOG'}) {
    // 1. Send to console
    debugPrint(message, wrapWidth: 1024);

    // 2. Add to buffer
    _logMessage('[$type] $message');
  }

  Future<void> initialize() async {
    // Initialize log file
    await _initLogFile();

    // Set up periodic saving
    _saveTimer = Timer.periodic(const Duration(seconds: 10), (_) => _saveLogsToFile());

    // Capture Flutter errors
    FlutterError.onError = (details) {
      log('${details.exception}\n${details.stack}', type: 'FLUTTER ERROR');
      _saveLogsToFile();
    };

    // Capture Dart errors
    PlatformDispatcher.instance.onError = (error, stack) {
      log('$error\n$stack', type: 'DART ERROR');
      _saveLogsToFile();
      return true;
    };

    log('Logger initialized', type: 'SYSTEM');
  }

  void _logMessage(String message) {
    final timestamp = DateTime.now().toIso8601String();
    _logBuffer.add('$timestamp $message');
    _logController.add('$timestamp $message');
  }

  Future<void> _initLogFile() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final logDir = Directory('${directory.path}/logs');

      if (!await logDir.exists()) {
        await logDir.create(recursive: true);
      }

      final dateStr = DateTime.now().toIso8601String().replaceAll(':', '-');
      _logFile = File('${logDir.path}/logs_$dateStr.txt');

      // Write header
      await _logFile!.writeAsString('''
=== LOG START ===
App Started: ${DateTime.now()}
Device: ${Platform.operatingSystem} ${Platform.operatingSystemVersion}
Flutter: ${Platform.version}

''');
    } catch (e) {
      debugPrint('Failed to initialize logger: $e');
    }
  }

  Future<void> _saveLogsToFile() async {
    if (_logBuffer.isEmpty || _logFile == null) return;

    try {
      await _logFile!.writeAsString(
          _logBuffer.join('\n') + '\n',
          mode: FileMode.append
      );
      _logBuffer.clear();
    } catch (e) {
      debugPrint('Failed to save logs: $e');
    }
  }

  Future<void> dispose() async {
    await _saveLogsToFile();
    _saveTimer?.cancel();
    await _logController.close();
  }
}