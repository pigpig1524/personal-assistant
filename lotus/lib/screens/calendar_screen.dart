import 'dart:convert';
import 'package:lotus/constants.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'login_screen.dart';

class CalendarScreen extends StatefulWidget {
  final String accessToken;
  const CalendarScreen({required this.accessToken, super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  List<dynamic> events = [];
  bool isLoading = true;
  String? error;

   Future<void> signOut() async {
    try {
      await FirebaseAuth.instance.signOut();
      final GoogleSignIn googleSignIn = GoogleSignIn();
      if (await googleSignIn.isSignedIn()) {
        await googleSignIn.signOut();
      }

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        logger.i('Error signout: $e');
      }
    }
  }

  @override
  void initState() {
    super.initState();
    fetchCalendarEvents();
  }

  Future<void> fetchCalendarEvents() async {
    try {
      final response = await http.get(
        Uri.parse('https://www.googleapis.com/calendar/v3/calendars/primary/events'),
        headers: {
          'Authorization': 'Bearer ${widget.accessToken}',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          events = data['items'] ?? [];
          isLoading = false;
        });
      } else {
        setState(() {
          error = 'Lỗi khi lấy sự kiện: ${response.statusCode}';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        error = 'Lỗi: $e';
        isLoading = false;
      });
    }
  }

  String formatDate(String? dateTime) {
    if (dateTime == null) return 'Không có ngày';
    DateTime dt;
    try {
      dt = DateTime.parse(dateTime).toLocal();
      return "${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}";
    } catch (_) {
      return dateTime;
    }
  }

  @override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: const Text('Google Calendar Events'),
    ),
    body: isLoading
        ? const Center(child: CircularProgressIndicator())
        : error != null
            ? Center(child: Text(error!))
            : events.isEmpty
                ? const Center(child: Text('Chưa có sự kiện nào trong lịch.'))
                : Column(
                    children: [
                      Expanded(
                        child: ListView.builder(
                          itemCount: events.length,
                          itemBuilder: (context, index) {
                            final event = events[index];
                            final title = event['summary'] ?? 'Không có tiêu đề';
                            final start = event['start']?['dateTime'] ?? event['start']?['date'] ?? '';
                            final end = event['end']?['dateTime'] ?? event['end']?['date'] ?? '';
                            return ListTile(
                              title: Text(title),
                              subtitle: Text('Từ: ${formatDate(start)}\nĐến: ${formatDate(end)}'),
                              isThreeLine: true,
                            );
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: ElevatedButton(
                          onPressed: signOut,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: peri,
                            minimumSize: const Size(double.infinity, 48),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24.0),
                            ),
                          ),
                          child: const Text("Sign Out", style: auth1body),
                        ),
                      ),
                    ],
                  ),
  );
}

}
