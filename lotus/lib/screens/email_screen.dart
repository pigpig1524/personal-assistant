import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/gmail/v1.dart' as gmail;
import 'package:http/http.dart' as http;

class GoogleAuthClient extends http.BaseClient {
  final Map<String, String> _headers;
  final http.Client _client = http.Client();

  GoogleAuthClient(this._headers);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    return _client.send(request..headers.addAll(_headers));
  }
}

class EmailScreen extends StatefulWidget {
  const EmailScreen({super.key});

  @override
  State<EmailScreen> createState() => _EmailScreenState();
}

class _EmailScreenState extends State<EmailScreen> {
  List<String> emails = [];
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: <String>[
      gmail.GmailApi.gmailReadonlyScope,
      'email',
      'https://www.googleapis.com/auth/userinfo.profile',
    ],
  );

  List<Map<String, String>> chatMessages = [];

  final TextEditingController _chatController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchEmails();
  }

  Future<void> fetchEmails() async {
    final account = await _googleSignIn.signIn();
    final headers = await account?.authHeaders;
    if (headers == null) return;

    final client = GoogleAuthClient(headers);
    final gmailApi = gmail.GmailApi(client);

    final messagesList = await gmailApi.users.messages.list('me', maxResults: 3);
    final fetchedEmails = <String>[];

    for (var message in messagesList.messages ?? []) {
      final msg = await gmailApi.users.messages.get('me', message.id!);
      final subjectHeader = msg.payload?.headers
              ?.firstWhere((h) => h.name == 'Subject', orElse: () => gmail.MessagePartHeader(name: '', value: 'No Subject'));

      fetchedEmails.add(subjectHeader?.value ?? 'No Subject');
    }

    setState(() {
      emails = fetchedEmails;
    });
  }

  void sendMessage(String text) {
    setState(() {
      chatMessages.add({'sender': 'You', 'message': text});
      chatMessages.add({'sender': 'Bot', 'message': 'Echo: $text'}); // Replace with AI logic
    });
    _chatController.clear();
  }

  void navigateTo(String title) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EmailListScreen(title: title, emails: emails),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Email Dashboard')),
      body: Column(
        children: [
          // Buttons for navigation
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                onPressed: () => navigateTo('Sent Emails'),
                child: const Text('Sent Emails'),
              ),
              ElevatedButton(
                onPressed: () => navigateTo('Received Emails'),
                child: const Text('Received Emails'),
              ),
            ],
          ),
          const Divider(),
          const Text('AI Chatbot', style: TextStyle(fontWeight: FontWeight.bold)),
          // Chatbot Area
          Expanded(
            child: Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: chatMessages.length,
                    itemBuilder: (context, index) {
                      final message = chatMessages[index];
                      return ListTile(
                        title: Text('${message['sender']}: ${message['message']}'),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _chatController,
                          decoration: const InputDecoration(hintText: 'Type a message'),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.send),
                        onPressed: () {
                          if (_chatController.text.trim().isNotEmpty) {
                            sendMessage(_chatController.text.trim());
                          }
                        },
                      )
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class EmailListScreen extends StatefulWidget {
  final String title;
  final List<String> emails;

  const EmailListScreen({super.key, required this.title, required this.emails});

  @override
  State<EmailListScreen> createState() => _EmailListScreenState();
}

class _EmailListScreenState extends State<EmailListScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: ListView.builder(
        itemCount: widget.emails.length,
        itemBuilder: (context, index) {
          return ListTile(
            leading: const Icon(Icons.email),
            title: Text(widget.emails[index]),
          );
        },
      ),
    );
  }
}
