import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import 'package:logger/logger.dart';
import 'package:path/path.dart' as path;
import 'dart:convert';

final logger = Logger();

class OcrService {
  final String apiUrl = 'https://ipa-stag-496153837085.asia-northeast1.run.app/utils/ocr';

  Future<Map<String, dynamic>?> recognizeText(File imageFile) async {
    try {
      final mimeType = lookupMimeType(imageFile.path);
      if (mimeType == null) {
        logger.e("Không xác định được mime type của ảnh.");
        return null;
      }
      final mimeParts = mimeType.split('/');

      final request = http.MultipartRequest('POST', Uri.parse(apiUrl));
      request.files.add(
        await http.MultipartFile.fromPath(
          'image', 
          imageFile.path,
          contentType: MediaType(mimeParts[0], mimeParts[1]),
        ),
      );

      logger.i("Đang gửi ảnh OCR: ${path.basename(imageFile.path)}");
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      logger.i('OCR Status: ${response.statusCode}');
      logger.i('OCR Body: ${response.body}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        logger.e('OCR failed: ${response.statusCode} ${response.body}');
        return null;
      }
    } catch (e) {
      logger.e('OCR Exception: $e');
      return null;
    }
  }
}
