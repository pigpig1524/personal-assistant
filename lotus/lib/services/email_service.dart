import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'package:googleapis/gmail/v1.dart' as gmail;
import '../services/google_auth_client.dart';

final logger = Logger();

class GoogleSignInService {
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  Future<GoogleSignInAccount?> getSignedInUser() async {
    return _googleSignIn.currentUser ?? await _googleSignIn.signInSilently();
  }

  Future<GoogleSignInAccount?> signIn() async {
    try {
      return await _googleSignIn.signIn();
    } catch (e) {
      return null;
    }
  }

  Future<void> signOut() => _googleSignIn.signOut();
}

class EmailService {
  final String apiUrl =
      'https://ipa-stag-496153837085.asia-northeast1.run.app/utils/email';

  Future<List<gmail.Message>> fetchEmails(GoogleSignInAccount account) async {
    final headers = await account.authHeaders;

    final client = GoogleAuthClient(headers);
    final gmailApi = gmail.GmailApi(client);

    final messagesList = await gmailApi.users.messages.list(
      'me',
      maxResults: 20,
    );

    final fetchedEmails = <gmail.Message>[];

    if (messagesList.messages != null) {
      for (var message in messagesList.messages!) {
        final msg = await gmailApi.users.messages.get(
          'me',
          message.id!,
          format: 'full',
        );
        fetchedEmails.add(msg);
      }
    }
    return fetchedEmails;
  }

  Future<Map<String, dynamic>?> detectIntent(
    String message,
    String subject,
    String content,
  ) async {
    try {
      final requestPayload = {
        "user_query": message,
        "subject": subject,
        "content": content,
      };

      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestPayload),
      );

      logger.i('Sent Payload: ${jsonEncode(requestPayload)}');
      logger.i('Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final decodedBody = utf8.decode(response.bodyBytes);
        logger.i('Response Body: $decodedBody');
        return jsonDecode(decodedBody);
      } else {
        return null;
      }
    } catch (e) {
      logger.e('Exception: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> saveDraftEmail({
    required String to,
    required String subject,
    required String body,
    required String accessToken,
  }) async {
    try {
      final rawMessage =
          '''
From: me
To: $to
Subject: $subject

$body
''';

      // Gmail API requires base64url encoding (without padding)
      final bytes = utf8.encode(rawMessage);
      final base64Email = base64UrlEncode(bytes).replaceAll('=', '');

      final draftPayload = jsonEncode({
        "message": {"raw": base64Email},
      });

      final response = await http.post(
        Uri.parse("https://gmail.googleapis.com/gmail/v1/users/me/drafts"),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
        body: draftPayload,
      );

      logger.i('Sent Payload: $draftPayload');
      logger.i('Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final decodedBody = utf8.decode(response.bodyBytes);
        logger.i('Response Body: $decodedBody');
        return jsonDecode(decodedBody);
      } else {
        logger.e('Failed to save draft: ${response.body}');
        return null;
      }
    } catch (e) {
      logger.e('Exception: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> sendEmail({
    required String to,
    required String subject,
    required String body,
    required String accessToken,
  }) async {
    try {
      final rawMessage =
          '''
From: me
To: $to
Subject: $subject

$body
''';

      // Gmail API requires base64url encoding (without padding)
      final bytes = utf8.encode(rawMessage);
      final base64Email = base64UrlEncode(bytes).replaceAll('=', '');

      final payload = jsonEncode({"raw": base64Email});

      final response = await http.post(
        Uri.parse(
          "https://gmail.googleapis.com/gmail/v1/users/me/messages/send",
        ),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
        body: payload,
      );

      logger.i('Sent Payload: $payload');
      logger.i('Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final decodedBody = utf8.decode(response.bodyBytes);
        logger.i('Response Body: $decodedBody');
        return jsonDecode(decodedBody);
      } else {
        logger.e('Failed to send email: ${response.body}');
        return null;
      }
    } catch (e) {
      logger.e('Exception: $e');
      return null;
    }
  }
}
