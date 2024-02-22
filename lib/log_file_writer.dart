import 'dart:io';

import 'package:date_format/date_format.dart';
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class LogFileWriter {
  final Level printLevel;
  final String appName;
  final Directory? directory;

  late final File _logFile;
  late final IOSink _logWriter;
  final bool _initialized = false;

  String get filePath => _logFile.path;
  File get logFile => _logFile;
  bool get initialized => _initialized;

  LogFileWriter({
    required this.printLevel,
    required this.appName,
    this.directory,
  });

  Future<void> initialize() async {
    if (!kIsWeb) {
      final tempDirectory = directory ?? await getTemporaryDirectory();
      final fileName = _formatDateTimeForLogFileName(DateTime.now());
      final path = p.join(tempDirectory.path, fileName);

      _logFile = File(path);
      _logWriter = _logFile.openWrite();
    }

    Logger.root.onRecord.listen((record) {
      if (record.level >= printLevel) {
        final log =
            "${record.time} [${record.loggerName}] ${record.level.name} - ${record.message}${(record.error == null ? "" : " - ${record.error}")}${(record.stackTrace == null ? "" : "\n${record.stackTrace}\n\n")}";

        if (!kIsWeb) {
          _logWriter.writeln(log);
        }

        debugPrint("${_getColorCodeByLogLevel(record.level)}$log");
      }
    });
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

  String _formatDateTimeForLogFileName(DateTime dateTime) =>
      "${appName}_${formatDate(
        dateTime.toUtc(),
        [yyyy, '-', mm, '-', dd, '--', H, '-', nn, '-', s],
      )}.txt";

  Future<File> copyLogFileTo(String path) async {
    return _logFile.copy(path);
  }
}
