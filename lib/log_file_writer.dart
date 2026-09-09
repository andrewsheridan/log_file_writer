import 'dart:collection';
import 'dart:io';

import 'package:date_format/date_format.dart';
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class LogFileWriter extends ChangeNotifier {
  final Level writeToFileLevel;
  final Level printToConsoleLevel;
  final Level inMemoryLevel;
  final String appName;
  final List<String> _history = [];

  late final File _logFile;
  late final IOSink _logWriter;
  final bool _initialized = false;
  final Logger _logger = Logger("LogFileWriter");

  String get filePath => _logFile.path;
  File get logFile => _logFile;
  bool get initialized => _initialized;
  UnmodifiableListView<String> get history => UnmodifiableListView(_history);
  String recentHistory({int count = 10}) {
    if (history.length <= count) return history.join("\n");

    final output = StringBuffer();
    for (int i = 1; i <= count; i++) {
      output.writeln(history[history.length - i]);
    }

    return output.toString();
  }

  String truncatedHistory({int characterCount = 1200}) {
    final output = history.join("\n");

    if (output.length <= characterCount) return output;

    return output.substring(output.length - characterCount);
  }

  LogFileWriter({
    required this.writeToFileLevel,
    required this.printToConsoleLevel,
    required this.inMemoryLevel,
    required this.appName,
  });

  Future<void> initialize() async {
    Logger.root.level = Level.ALL;
    Logger.root.onRecord.listen(_onNewLog);

    // AppLifecycleListener(
    //   onExitRequested: () async {
    //     _logger.info("Exit requested. Closing log file.");
    //     await _logWriter.flush();
    //     await _logWriter.close();
    //     return AppExitResponse.exit;
    //   },
    // );

    if (!kIsWeb) {
      try {
        final tempDirectory = await getTemporaryDirectory();
        final fileName = formatDateTimeForLogFileName(DateTime.now());
        final path = p.join(tempDirectory.path, fileName);

        _logFile = File(path);
        _logWriter = _logFile.openWrite();
      } catch (ex) {
        _logger.severe("Failed to initialize log file.", ex);
      }
    }
  }

  void _onNewLog(LogRecord record) {
    if (record.level < writeToFileLevel && record.level < printToConsoleLevel) {
      return;
    }

    final logNoStackTrace =
        "${record.time} [${record.loggerName}] ${record.level.name} - ${record.message}${(record.error == null ? "" : " - ${record.error}")}";
    final log =
        "$logNoStackTrace${(record.stackTrace == null ? "" : "\n${record.stackTrace}\n\n")}";

    if (!kIsWeb && record.level >= writeToFileLevel) {
      _logWriter.writeln(log);
    }

    if (record.level >= printToConsoleLevel) {
      debugPrint("${_getColorCodeByLogLevel(record.level)}$log");
    }

    if (record.level >= inMemoryLevel) {
      _history.add(logNoStackTrace);
      notifyListeners();
    }
  }

  static String _getColorCodeByLogLevel(Level level) {
    // Reset:   \x1B[0m
    // Black:   \x1B[30m
    // White:   \x1B[37m
    // Red:     \x1B[31m
    // Green:   \x1B[32m
    // Yellow:  \x1B[33m
    // Blue:    \x1B[34m
    // Cyan:    \x1B[36m

    if (level >= Level.SEVERE) return "\x1B[31m";
    if (level >= Level.WARNING) return "\x1B[33m";
    if (level >= Level.INFO) return "\x1B[32m";
    if (level >= Level.FINE) return "\x1B[36m";

    return "\x1B[0m";
  }

  String formatDateTimeForLogFileName(DateTime dateTime) =>
      "${appName}_${formatDate(
        dateTime.toUtc(),
        [yyyy, '-', mm, '-', dd, '--', H, '-', nn, '-', s],
      )}.txt";

  Future<File> copyLogFileTo(String path) async {
    return _logFile.copy(path);
  }
}
