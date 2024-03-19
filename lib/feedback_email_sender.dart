import 'package:flutter_email_sender/flutter_email_sender.dart';
import 'package:logging/logging.dart';

class FeedbackEmailSender {
  final Logger _logger = Logger("FeedbackEmailSender");

  Future<bool> sendFeedbackEmail({
    required String subjectLine,
    required List<String> recipients,
    List<String>? attachmentPaths,
  }) async {
    try {
      final email = Email(
        body: "",
        subject: subjectLine,
        recipients: recipients,
        attachmentPaths: attachmentPaths,
      );

      await FlutterEmailSender.send(email);
    } catch (ex) {
      _logger.severe("Failed to send email.", ex, StackTrace.current);
      rethrow;
    }

    return true;
  }
}
