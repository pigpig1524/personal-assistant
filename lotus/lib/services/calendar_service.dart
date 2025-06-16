import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import 'dart:convert';

final logger = Logger();

class CalendarService {
  Future<bool> createEvent({
    required String accessToken,
    required String title,
    required String startDate,
    required String endDate,
    String? location,
    String? description,
    required Future<String?> Function() onTokenExpired,
  }) async {
    try {
      final url = Uri.parse('https://www.googleapis.com/calendar/v3/calendars/primary/events');
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'summary': title,
          'location': location,
          'description': description,
          'start': {
            'dateTime': startDate,
            'timeZone': 'Asia/Ho_Chi_Minh',
          },
          'end': {
            'dateTime': endDate,
            'timeZone': 'Asia/Ho_Chi_Minh',
          },
        }),
      );

      if (response.statusCode == 200) {
        logger.i('Event created successfully: $title');
        return true;
      } else if (response.statusCode == 401) {
        logger.w('Token expired, attempting to refresh');
        final newAccessToken = await onTokenExpired();
        if (newAccessToken != null) {
          return await createEvent(
            accessToken: newAccessToken,
            title: title,
            startDate: startDate,
            endDate: endDate,
            location: location,
            description: description,
            onTokenExpired: onTokenExpired,
          );
        } else {
          logger.w('Failed to refresh token');
          return false;
        }
      } else {
        logger.w('Failed to create event: ${response.statusCode}, body: ${response.body}');
        return false;
      }
    } catch (e, stackTrace) {
      logger.e('Error creating event: $e', stackTrace: stackTrace);
      return false;
    }
  }
}