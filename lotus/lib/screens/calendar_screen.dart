import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:lotus/constants.dart';
import 'login_screen.dart';
import 'onboarding.dart';
import 'package:logger/logger.dart';


final logger = Logger();
class CalendarScreen extends StatefulWidget {
  final String accessToken;
  const CalendarScreen({required this.accessToken, super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  List<dynamic> allEvents = [];
  List<dynamic> selectedDayEvents = [];
  Map<DateTime, List> eventsMap = {};
  bool isLoading = true;
  String? error;

  User? user;
  String? photoUrl;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    user = FirebaseAuth.instance.currentUser;
    photoUrl = user?.photoURL;
    fetchCalendarEvents();
  }

  Future<void> fetchCalendarEvents() async {
    try {
      final response = await http.get(
        Uri.parse(
            'https://www.googleapis.com/calendar/v3/calendars/primary/events?orderBy=startTime&singleEvents=true'),
        headers: {
          'Authorization': 'Bearer ${widget.accessToken}',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          allEvents = data['items'] ?? [];
          eventsMap = {};
          for (var event in allEvents) {
            final start = event['start']?['dateTime'] ?? event['start']?['date'];
            if (start == null) continue;

            final eventDate = DateTime.parse(start).toLocal();
            final dateKey = DateTime(eventDate.year, eventDate.month, eventDate.day);

            eventsMap.putIfAbsent(dateKey, () => []).add(event);
          }
          isLoading = false;
          filterEventsForSelectedDay();
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

  void filterEventsForSelectedDay() {
    final selected = _selectedDay!;
    setState(() {
      selectedDayEvents = eventsMap[DateTime(selected.year, selected.month, selected.day)] ?? [];
    });
  }

  String formatDate(String? dateTime) {
    if (dateTime == null) return 'Không có ngày';
    try {
      final dt = DateTime.parse(dateTime).toLocal();
      return "${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}";
    } catch (_) {
      return dateTime;
    }
  }

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
      logger.i('Error signout: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Schedule'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => OnboardingScreen()),
          );
          },
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: CircleAvatar(
              radius: 20,
              backgroundImage: photoUrl != null
                  ? NetworkImage(photoUrl!)
                  : const AssetImage('assets/images/default_avatar.png') as ImageProvider,
              child: photoUrl == null ? const Icon(Icons.account_circle, size: 40) : null,
            ),
          ),
        ],
      ),

      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? Center(child: Text(error!))
              : Column(
                  children: [
                    TableCalendar(
                      firstDay: DateTime.utc(2020, 1, 1),
                      lastDay: DateTime.utc(2030, 12, 31),
                      focusedDay: _focusedDay,
                      selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                      onDaySelected: (selectedDay, focusedDay) {
                        setState(() {
                          _selectedDay = selectedDay;
                          _focusedDay = focusedDay;
                          filterEventsForSelectedDay();
                        });
                      },
                      eventLoader: (day) {
                        final key = DateTime(day.year, day.month, day.day);
                        return eventsMap[key] ?? [];
                      },
                      calendarStyle: const CalendarStyle(
                        todayDecoration: BoxDecoration(
                          color: Colors.blueAccent,
                          shape: BoxShape.circle,
                        ),
                        selectedDecoration: BoxDecoration(
                          color: Colors.orange,
                          shape: BoxShape.circle,
                        ),
                        markerDecoration: BoxDecoration(
                          color: Colors.redAccent,
                          shape: BoxShape.circle,
                        ),
                        markerSize: 6,
                      ),
                      headerStyle: const HeaderStyle(
                        formatButtonVisible: false,
                        titleCentered: true,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: selectedDayEvents.isEmpty
                          ? const Center(child: Text('There are no events scheduled for this day.', style: eventheading) )
                          : ListView.builder(
                              itemCount: selectedDayEvents.length,
                              itemBuilder: (context, index) {
                                final event = selectedDayEvents[index];
                                final title = event['summary'] ?? 'Untitled Event';
                                final start = event['start']?['dateTime'] ?? event['start']?['date'];
                                final end = event['end']?['dateTime'] ?? event['end']?['date'];
                                return ListTile(
                                  title: Text(title, style: eventheading),
                                  subtitle: Text('From: ${formatDate(start)}\nTo: ${formatDate(end)}', style: eventbody),
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
