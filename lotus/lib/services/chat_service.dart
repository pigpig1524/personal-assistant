import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:lotus/services/dialogflow_service.dart';
import 'package:lotus/services/calendar_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logger/logger.dart';
import 'package:mime/mime.dart';
import 'dart:io';
import 'package:http_parser/http_parser.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

final logger = Logger();

class ChatService {
  final DialogflowService _dialogflowService = DialogflowService();
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'https://www.googleapis.com/auth/calendar.events'],
  );

  Future<String?> _loadAccessToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('access_token');
    } catch (e, stackTrace) {
      logger.e('Error loading token: $e', stackTrace: stackTrace);
      return null;
    }
  }

  Future<String?> _refreshAccessToken() async {
    try {
      GoogleSignInAccount? googleUser = _googleSignIn.currentUser;
      googleUser ??= await _googleSignIn.signInSilently();

      if (googleUser == null) {
        logger.w("Silent sign-in failed, attempting manual sign-in");
        googleUser = await _googleSignIn.signIn();
        if (googleUser == null) {
          logger.w("Manual sign-in failed");
          return null;
        }
      }

      final googleAuth = await googleUser.authentication;
      final newAccessToken = googleAuth.accessToken;

      if (newAccessToken != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('access_token', newAccessToken);
        logger.i("Access token refreshed");
        return newAccessToken;
      } else {
        logger.w("Error refreshing access token");
        return null;
      }
    } catch (e, stackTrace) {
      logger.e('Error refreshing token: $e', stackTrace: stackTrace);
      return null;
    }
  }

  // Chuyển đổi định dạng ngày từ "dd-MM-yyyy HH:mm:ss" sang ISO 8601
  String _convertToIso8601(String dateTimeStr) {
    try {
      final inputFormat = DateFormat('dd-MM-yyyy HH:mm:ss');
      final dateTime = inputFormat.parse(dateTimeStr);
      final outputFormat = DateFormat("yyyy-MM-dd'T'HH:mm:ss'+07:00'");
      return outputFormat.format(dateTime);
    } catch (e, stackTrace) {
      logger.e('Error converting date $dateTimeStr to ISO 8601: $e', stackTrace: stackTrace);
      return dateTimeStr; // Fallback
    }
  }

  void pickAndSendImage({
    required List<Map<String, String>> messages,
    required Function(bool) onLoading,
    required Function(String?) onError,
    required VoidCallback scrollToBottom,
  }) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      final imageFile = File(pickedFile.path);

      // Log thông tin file
      final mimeType = lookupMimeType(imageFile.path);
      final fileSize = await imageFile.length();
      logger.i('Selected image: path=${imageFile.path}, mimeType=$mimeType, size=$fileSize bytes');

      // Kiểm tra định dạng hình ảnh
      if (mimeType == null || !['image/jpeg', 'image/png'].contains(mimeType)) {
        final errorMsg = 'Chỉ hỗ trợ định dạng JPEG hoặc PNG.';
        logger.w(errorMsg);
        onError(errorMsg);
        return;
      }

      // Kiểm tra tệp tồn tại
      if (!await imageFile.exists()) {
        final errorMsg = 'Không thể truy cập hình ảnh.';
        logger.w(errorMsg);
        onError(errorMsg);
        return;
      }

      messages.add({
        'role': 'user',
        'content': '',
        'image': imageFile.path,
      });
      onLoading(true);
      onError(null);

      try {
        final request = http.MultipartRequest(
          'POST',
          Uri.parse('https://ipa-stag-496153837085.asia-northeast1.run.app/utils/ocr'),
        );

        // Thêm file với key 'file'
        final fileName = imageFile.path.split('/').last;
        request.files.add(
          http.MultipartFile(
            'file',
            imageFile.readAsBytes().asStream(),
            fileSize,
            filename: fileName,
            contentType: MediaType.parse(mimeType),
          ),
        );

        // Log request
        logger.i('Sending OCR request: URL=${request.url}, fileKey=file, fileName=$fileName, headers=${request.headers}');

        final response = await request.send();
        final responseBody = await response.stream.bytesToString();

        // Log response
        logger.i('OCR response: statusCode=${response.statusCode}, headers=${response.headers}, body=$responseBody');

        if (response.statusCode == 200) {
          try {
            final decoded = json.decode(responseBody);
            final responseText = decoded['response'] as String?;
            final intent = decoded['intent'] as String?;
            final action = decoded['action'] as String?;
            final data = decoded['data'] as List<dynamic>?;

            // Hiển thị response trong chat
            if (responseText != null && responseText.isNotEmpty) {
              logger.i('Displaying agent response: $responseText');
              messages.add({
                'role': 'assistant',
                'content': responseText,
                'image': imageFile.path,
              });
            } else {
              final errorMsg = 'Phản hồi không chứa response hợp lệ: $decoded';
              logger.w(errorMsg);
              messages.add({
                'role': 'assistant',
                'content': 'Không nhận được phản hồi từ API.',
              });
              onError(errorMsg);
            }

            // Tạo sự kiện nếu intent là CALENDAR và action là CREATE_EVENT
            if (intent == 'CALENDAR' && action == 'CREATE_EVENT' && data != null && data.isNotEmpty) {
              final accessToken = await _loadAccessToken();
              if (accessToken == null) {
                final errorMsg = 'Token không hợp lệ, vui lòng đăng nhập lại.';
                logger.w(errorMsg);
                messages.add({
                  'role': 'assistant',
                  'content': errorMsg,
                });
                onError(errorMsg);
                return;
              }

              final calendarService = CalendarService();
              int successCount = 0;
              for (var event in data) {
                final summary = event['summary'] as String?;
                final startDate = event['start'] as String?;
                final endDate = event['end'] as String?;
                final location = event['location'] as String?;
                final description = event['description'] as String?;

                if (summary != null && startDate != null && endDate != null) {
                  try {
                    final success = await calendarService.createEvent(
                      accessToken: accessToken,
                      title: summary,
                      startDate: _convertToIso8601(startDate),
                      endDate: _convertToIso8601(endDate),
                      location: location,
                      description: description,
                      onTokenExpired: _refreshAccessToken,
                    );

                    if (success) {
                      successCount++;
                      logger.i('Created event: $summary');
                    } else {
                      logger.w('Failed to create event: $summary');
                    }
                  } catch (e, stackTrace) {
                    logger.e('Error creating event $summary: $e', stackTrace: stackTrace);
                  }
                } else {
                  logger.w('Invalid event data: $event');
                }
              }

              messages.add({
                'role': 'assistant',
                'content': successCount > 0
                    ? 'Đã tạo thành công $successCount sự kiện!'
                    : 'Không thể tạo bất kỳ sự kiện nào. Vui lòng kiểm tra dữ liệu.',
              });
            }
          } catch (e, stackTrace) {
            final errorMsg = 'Lỗi phân tích JSON phản hồi từ API: $e, response=$responseBody';
            logger.e(errorMsg, stackTrace: stackTrace);
            messages.add({
              'role': 'assistant',
              'content': 'Lỗi xử lý phản hồi từ API.',
            });
            onError(errorMsg);
          }
        } else {
          final errorMsg = 'Gửi ảnh thất bại (mã ${response.statusCode}): $responseBody';
          logger.w(errorMsg);
          messages.add({
            'role': 'assistant',
            'content': 'Gửi ảnh thất bại (mã ${response.statusCode}).',
          });
          onError(errorMsg);
        }
      } catch (e, stackTrace) {
        final errorMsg = 'Lỗi kết nối đến API: $e';
        logger.e(errorMsg, stackTrace: stackTrace);
        messages.add({
          'role': 'assistant',
          'content': 'Lỗi kết nối đến API. Vui lòng thử lại.',
        });
        onError(errorMsg);
      }

      onLoading(false);
      scrollToBottom();
    } else {
      logger.w('No image selected by user');
    }
  }

  void sendMessage({
    required String text,
    required List<Map<String, String>> messages,
    required Function(bool) onLoading,
    required Function(String?) onError,
    required VoidCallback scrollToBottom,
    required TextEditingController controller,
  }) async {
    if (text.trim().isEmpty) {
      controller.clear();
      return;
    }

    messages.add({'role': 'user', 'content': text});
    onLoading(true);
    onError(null);
    controller.clear();

    try {
      final result = await _dialogflowService.detectIntent(text);

      if (result != null) {
        final responseText = result['response'];
        final intent = result['intent'];
        final action = result['action'];
        final data = result['data'];

        messages.add({'role': 'assistant', 'content': responseText});

        if (intent == 'CALENDAR' && action == 'CREATE_EVENT' && data != null) {
          final accessToken = await _loadAccessToken();
          if (accessToken != null &&
              data['start_date'] != null &&
              data['end_date'] != null &&
              (data['title'] != null || data['summary'] != null)) {
            final startDate = data['start_date'].replaceAll(RegExp(r'\+.*$'), '');
            final endDate = data['end_date'].replaceAll(RegExp(r'\+.*$'), '');

            final calendarService = CalendarService();
            final success = await calendarService.createEvent(
              accessToken: accessToken,
              title: data['title'] ?? data['summary'],
              startDate: startDate,
              endDate: endDate,
              onTokenExpired: _refreshAccessToken,
            );

            messages.add({
              'role': 'assistant',
              'content': success
                  ? 'Sự kiện "${data['title'] ?? data['summary']}" đã được tạo thành công!'
                  : 'Không thể tạo sự kiện. Vui lòng kiểm tra thông tin.',
            });
          } else {
            final errorMsg = 'Thiếu thông tin sự kiện hoặc token không hợp lệ.';
            logger.w(errorMsg);
            messages.add({
              'role': 'assistant',
              'content': errorMsg,
            });
            onError(errorMsg);
          }
        }
      } else {
        messages.add({'role': 'assistant', 'content': 'Xin lỗi, tôi không hiểu.'});
      }
    } catch (e, stackTrace) {
      final errorMsg = 'Lỗi kết nối đến Dialogflow: $e';
      logger.e(errorMsg, stackTrace: stackTrace);
      messages.add({
        'role': 'assistant',
        'content': 'Lỗi kết nối đến Dialogflow. Vui lòng thử lại.',
      });
    }

    onLoading(false);
    scrollToBottom();
  }
}