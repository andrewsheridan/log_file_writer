import 'package:flutter/foundation.dart';
import 'package:flutter_email_sender/flutter_email_sender.dart';
import 'package:log_file_writer/log_file_writer.dart';
import 'package:logging/logging.dart';
import 'package:url_launcher/url_launcher.dart';

class FeedbackEmailSender {
  final Logger _logger = Logger("FeedbackEmailSender");
  final LogFileWriter _logFileWriter;
  final String subjectLine;
  final String recipient;

  FeedbackEmailSender({
    required LogFileWriter logFileWriter,
    required this.subjectLine,
    required this.recipient,
  }) : _logFileWriter = logFileWriter;

  String? _encodeQueryParameters(Map<String, String> params) {
    return params.entries
        .map((MapEntry<String, String> e) =>
            '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');
  }

  Uri mailToUri(bool attachLogs) => Uri(
        scheme: "mailto",
        path: recipient,
        query: _encodeQueryParameters(<String, String>{
          'subject': subjectLine,
          if (attachLogs) 'body': _logFileWriter.truncatedHistory(),
        }),
      );

  Future<void> sendFeedbackEmail({required bool attachLogs}) async {
    if (!kIsWeb) {
      try {
        final email = Email(
          body: "",
          subject: subjectLine,
          recipients: [recipient],
          attachmentPaths:
              attachLogs && !kIsWeb ? [_logFileWriter.filePath] : [],
        );

        await FlutterEmailSender.send(email);

        return;
      } catch (ex) {
        _logger.severe(
            "Failed to send email via email client.", ex, StackTrace.current);
      }
    }

    try {
      final uri = mailToUri(attachLogs);
      // if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.platformDefault);
      // }
      // throw ("Cannot launch mailto URI.");
    } catch (ex) {
      _logger.severe(
        "Failed to send email via link.",
        ex,
      );
      rethrow;
    }
  }
}
