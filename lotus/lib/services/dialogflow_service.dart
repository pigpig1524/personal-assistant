import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import 'package:firebase_auth/firebase_auth.dart';

final userId = FirebaseAuth.instance.currentUser?.uid;
final logger = Logger();

class DialogflowService {
  final String apiUrl = 'https://ipa-stag-496153837085.asia-northeast1.run.app/api/detectIntent';

  Future<Map<String, dynamic>?> detectIntent(String message) async {
    try {
      final payload = {
        "user_id": userId,
        "user_query": message,
      };

      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      logger.i('Payload gửi đi: ${jsonEncode(payload)}');
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
}
