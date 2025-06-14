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

      fetchedEmails.add(subjectHeader?.value ?? 'No s');
    }

    setState(() {
      emails = fetchedEmails;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Recent Emails')),
      body: ListView.builder(
        itemCount: emails.length,
        itemBuilder: (context, index) {
          return ListTile(
            leading: const Icon(Icons.email),
            title: Text(emails[index]),
          );
        },
      ),
    );
  }
}
