import 'package:flutter_email_sender/flutter_email_sender.dart';
import 'package:log_file_writer/log_file_writer.dart';
import 'package:logging/logging.dart';

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
      _logger.severe("Failed to send email.", ex, StackTrace.current);
      rethrow;
    }

    return true;
  }
}
