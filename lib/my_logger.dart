import 'dart:io';
import 'package:flutter/widgets.dart';
import 'package:logging/logging.dart';
import 'package:path_provider/path_provider.dart';

// A custom logger class for managing application logs.
class MyLogger {
  final Logger _logger;
  late File _logFile;
  final bool printToConsole; //parameter to control printing to console

  // Constructor for MyLogger class.
  MyLogger(String name, {this.printToConsole = true}) : _logger = Logger(name) {
    hierarchicalLoggingEnabled = true;
    _logger.level = Level.ALL;

    // Asynchronously get the external storage directory and set up the log file.
    getApplicationDocumentsDirectory().then((directory) {
      _logFile = File('${directory.path}/$name.log');
      print('File is stored at - ${directory.path}');

      // Load existing logs from the log file.
      _loadExistingLogs();

      // Listen for log records and save them to the log file.
      _logger.onRecord.listen((record) {
        _saveLogRecord(record);
      });
    });

    // Add an observer to handle app lifecycle changes.
    WidgetsBinding.instance.addObserver(_AppLifecycleObserver(this));
  }

  // Load existing logs from the log file if it exists.
  void _loadExistingLogs() {
    if (_logFile.existsSync()) {
      try {
        _logFile.readAsString().then((contents) {
          _logger.info('Loaded previous logs:\n$contents');
        });
      } catch (e) {
        _logger.warning('Failed to load existing logs: $e');
      }
    }
  }

  // Asynchronously save a log record to the log file.
  Future<void> _saveLogRecord(LogRecord record) async {
    if (printToConsole) {
      // Log to the console
      print('${record.loggerName}: ${record.time}: ${record.message}');
    }

    try {
      await _logFile.writeAsString(
        '${record.loggerName}: ${record.time}: ${record.message}\n',
        mode: FileMode.append,
      );
    } catch (e) {
      _logger.warning('Failed to save log record: $e');
    }
  }

  // Log a message with fine level.
  void fine(String message) {
    _logger.fine(message);
  }

  // Log a message with info level.
  void info(String message) {
    _logger.info(message);
  }

  // Log a message with warning level.
  void warning(String message) {
    _logger.warning(message);
  }

  // Log a message with severe level.
  void severe(String message) {
    _logger.severe(message);
  }
}

// Observer class to handle app lifecycle changes.
class _AppLifecycleObserver with WidgetsBindingObserver {
  final MyLogger _logger;

  // Constructor for _AppLifecycleObserver.
  _AppLifecycleObserver(this._logger);

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // If the app is detached (exiting), log a message.
    if (state == AppLifecycleState.detached) {
      _logger._saveLogRecord(LogRecord(Level.INFO, '', 'App is exiting'));
    }
  }
}
