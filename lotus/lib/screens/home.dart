import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'chat_screen.dart';
import 'calendar_screen.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  User? user;
  String? photoUrl;

  @override
  void initState() {
    super.initState();
    user = FirebaseAuth.instance.currentUser;
    photoUrl = user?.photoURL;
  }

  @override
  Widget build(BuildContext context) {
    final displayName = user?.displayName ?? 'Jennie';

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hello, $displayName!',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1D1617),
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          "Let's make today a nice day!",
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF7B6F72),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // CircleAvatar(
                  //   radius: 25,
                  //   backgroundImage: photoUrl != null
                  //       ? NetworkImage(photoUrl!)
                  //       : const AssetImage('assets/images/default_avatar.png') as ImageProvider,
                  //   child: photoUrl == null ? const Icon(Icons.account_circle, size: 50) : null,
                  // ),
                ],
              ),
              
              const SizedBox(height: 30),
              
              const Center(
                child: Text(
                  'Productivity',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1D1617),
                  ),
                ),
              ),
              
              const SizedBox(height: 20),
              
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F8F8),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Communication',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1D1617),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '(Gmail) Re: Expenses report',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF7B6F72),
                      ),
                    ),
                    const Text(
                      '(Outlook) Review confirmed',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF7B6F72),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const ChatScreen()),
                          );
                        },
                        child: const Text(
                          'View more',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF92A3FD),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F8F8),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Schedule',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1D1617),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Coachella W1 Rehearsal at 1PM',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF7B6F72),
                      ),
                    ),
                    const Text(
                      'Empire Polo Club in Indio, California, US',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF7B6F72),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: GestureDetector(
                        onTap: () async {
                          try {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const CalendarScreen(accessToken: ''),
                              ),
                            );
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error: $e')),
                            );
                          }
                        },
                        child: const Text(
                          'View more',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF92A3FD),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F8F8),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Transport',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1D1617),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Indio, California, US',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF7B6F72),
                      ),
                    ),
                    const Text(
                      'This area is currently busier than usual.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF7B6F72),
                      ),
                    ),
                    const Text(
                      'Would you like me to book a Grab car?',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF7B6F72),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: GestureDetector(
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Transport feature coming soon!')),
                          );
                        },
                        child: const Text(
                          'View more',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF92A3FD),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                margin: const EdgeInsets.only(bottom: 30),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F8F8),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Today Target',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1D1617),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Target checked!')),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF92A3FD),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      ),
                      child: const Text(
                        'Check',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              Center(
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ChatScreen()),
                    );
                  },
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFFEEA4CE), Color(0xFFC58BF2)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.smart_toy,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 20),
              
              Center(
                child: Container(
                  width: 134,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(2.5),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}