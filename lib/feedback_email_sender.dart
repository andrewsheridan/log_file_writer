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

  Future<bool> sendFeedbackEmail() async {
    try {
      final email = Email(
        body: "",
        subject: subjectLine,
        recipients: [recipient],
        attachmentPaths: [_logFileWriter.filePath],
      );

      await FlutterEmailSender.send(email);
    } catch (ex) {
      _logger.severe(
          "Failed to send email via email client.", ex, StackTrace.current);
      try {
        final uri = Uri(
          scheme: "mailto",
          path: recipient,
          query: _encodeQueryParameters(<String, String>{
            'subject': subjectLine,
          }),
        );
        await launchUrl(uri);
      } catch (ex) {
        _logger.severe(
          "Failed to send email via link.",
          ex,
        );
        rethrow;
      }
    }

    return true;
  }
}
