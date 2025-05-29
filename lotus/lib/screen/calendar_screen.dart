import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

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
                  : ListView.builder(
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
    );
  }
}
