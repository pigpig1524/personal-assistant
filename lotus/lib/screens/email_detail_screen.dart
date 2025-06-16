import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:googleapis/gmail/v1.dart' as gmail;
import 'package:intl/intl.dart';
import 'package:lotus/constants.dart';

class EmailDetailScreen extends StatelessWidget {
  final gmail.Message email;

  const EmailDetailScreen({super.key, required this.email});

  String _getHeader(String name) {
    return email.payload?.headers
            ?.firstWhere(
              (h) => (h.name?.toLowerCase() ?? '') == name.toLowerCase(),
              orElse: () => gmail.MessagePartHeader(name: '', value: ''),
            )
            .value ??
        '';
  }

  String _decodeBase64(String? data) {
    if (data == null || data.isEmpty) return 'No content';
    try {
      var normalized = data.replaceAll('-', '+').replaceAll('_', '/');
      return utf8.decode(base64Url.decode(normalized));
    } catch (_) {
      return 'Failed to decode content';
    }
  }

  @override
  Widget build(BuildContext context) {
    final subject = _getHeader('Subject');
    final from = _getHeader('From');
    final date = _getHeader('Date');

    DateTime? parsedDate;
    try {
      parsedDate = DateFormat(
        "EEE, dd MMM yyyy HH:mm:ss zzz",
        'en_US',
      ).parse(date);
    } catch (_) {}

    final formattedDate = parsedDate != null
        ? DateFormat.yMMMd().add_jm().format(parsedDate)
        : 'Unknown Date';

    final parts = email.payload?.parts;
    String body = '';

    if (parts != null && parts.isNotEmpty) {
      final plainTextPart = parts.firstWhere(
        (p) => p.mimeType == 'text/plain',
        orElse: () => parts.first,
      );
      body = _decodeBase64(plainTextPart.body?.data);
    } else {
      body = _decodeBase64(email.payload?.body?.data);
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Email Detail")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Title:',
                  style: emailTxttStyle1,
                ),
                Text(subject, style: emailTxttStyle2),
              ],
            ),
            const SizedBox(height: 12),
            RichText(
              text: TextSpan(
                style: emailTxttStyle2,
                children: [
                  const TextSpan(
                    text: 'From: ',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(text: from),
                ],
              ),
            ),
            const SizedBox(height: 12),
            RichText(
              text: TextSpan(
                style: emailTxttStyle2,
                children: [
                  const TextSpan(
                    text: 'Date: ',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(text: formattedDate),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Content:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(body),
          ],
        ),
      ),
    );
  }
}
