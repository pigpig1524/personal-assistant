import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';

final logger = Logger();

class CalendarService {
  Future<bool> createEvent({
    required String accessToken,
    required String title,
    required String startDate,
    required String endDate,
    String timeZone = 'Asia/Ho_Chi_Minh',
    Future<String?> Function()? onTokenExpired,
  }) async {
    final url = 'https://www.googleapis.com/calendar/v3/calendars/primary/events';
    final body = {
      'summary': title,
      'start': {'dateTime': startDate, 'timeZone': timeZone},
      'end': {'dateTime': endDate, 'timeZone': timeZone},
    };

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );

      logger.i('Event tạo: $body');
      logger.i('Response ${response.statusCode}: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else if (response.statusCode == 401 && onTokenExpired != null) {
        final newToken = await onTokenExpired();
        if (newToken != null) {
          final retryResponse = await http.post(
            Uri.parse(url),
            headers: {
              'Authorization': 'Bearer $newToken',
              'Content-Type': 'application/json',
            },
            body: jsonEncode(body),
          );
          logger.i('Retry Response ${retryResponse.statusCode}: ${retryResponse.body}');
          return retryResponse.statusCode == 200 || retryResponse.statusCode == 201;
        }
        logger.e('API error: ${jsonDecode(response.body)['error']['message']}');
        return false;
      } else {
        logger.e('API error: ${jsonDecode(response.body)['error']['message']}');
        return false;
      }
    } catch (e) {
      logger.e('Lỗi khi tạo sự kiện: $e');
      return false;
    }
  }
}