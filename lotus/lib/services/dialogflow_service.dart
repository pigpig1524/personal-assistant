import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';

final logger = Logger();

class DialogflowService {
  final String apiUrl = 'https://ipa-stag-496153837085.asia-northeast1.run.app/api/detectIntent';

  Future<String?> detectIntent(String message) async {
    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "session_id": "test",
          "user_query": message,
        }),
      );

      logger.i('🔎 Payload gửi đi: ${jsonEncode({
        "session_id": "test",
        "user_query": message,
      })}');

      logger.i('📥 Response Status: ${response.statusCode}');
      logger.i('📥 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return json['response'] ?? "No reply";
      } else {
        return null;
      }
    } catch (e) {
      logger.i('❌ Exception: $e');
      return null;
    }
  }


}
