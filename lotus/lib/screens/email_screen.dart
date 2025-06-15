import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:lotus/constants.dart';
import 'package:googleapis/gmail/v1.dart' as gmail;
import '../services/google_auth_client.dart';
import 'email_list_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EmailScreen extends StatefulWidget {
  const EmailScreen({super.key});

  @override
  State<EmailScreen> createState() => _EmailScreenState();
}

class _EmailScreenState extends State<EmailScreen> {
  User? user;
  String? photoUrl;

  List<gmail.Message> emails = [];
  List<String> selectedEmailSubjects = [];
  List<gmail.Message> selectedEmails = [];
  final maxEmailsInput = 3;

  bool isLoading = true; // Add loading state

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
    user = FirebaseAuth.instance.currentUser;
    photoUrl = user?.photoURL;
    fetchEmails();
  }

  void _navigateToEmailSelection() async {
    final selected = await Navigator.push<List<gmail.Message>>(
      context,
      MaterialPageRoute(
        builder: (_) => EmailListScreen(
          title: 'Select Emails',
          emails: emails,
          isSelectionMode: true,
        ),
      ),
    );

    if (selected != null) {
      setState(() {
        selectedEmails = selected;

        // Extract just the subject for displaying
        selectedEmailSubjects = selected
            .map(
              (e) =>
                  e.payload?.headers
                      ?.firstWhere(
                        (h) => h.name?.toLowerCase() == 'subject',
                        orElse: () => gmail.MessagePartHeader(
                          name: '',
                          value: 'No Subject',
                        ),
                      )
                      .value ??
                  'No Subject',
            )
            .toList();
      });
    }
  }

  Future<void> fetchEmails() async {
    setState(() {
      isLoading = true;
    });

    final account = await _googleSignIn.signIn();
    final headers = await account?.authHeaders;
    if (headers == null) {
      setState(() {
        isLoading = false;
      });
      return;
    }

    final client = GoogleAuthClient(headers);
    final gmailApi = gmail.GmailApi(client);

    final messagesList = await gmailApi.users.messages.list(
      'me',
      maxResults: 20,
    );

    final fetchedEmails = <gmail.Message>[];

    for (var message in messagesList.messages ?? []) {
      final msg = await gmailApi.users.messages.get(
        'me',
        message.id!,
        format: 'full',
      );
      fetchedEmails.add(msg);
    }

    setState(() {
      emails = fetchedEmails;
      isLoading = false;  // Loading finished
    });
  }

  // ... rest of your code ...

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: white,
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Email Management'),
        backgroundColor: magnolia,
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
      body: Column(
        children: [
          const SizedBox(height: 16),
          Center(
            child: ElevatedButton(
              onPressed: _navigateToEmailSelection,
              style: ElevatedButton.styleFrom(
                backgroundColor: purpleblue,
                foregroundColor: white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
              child: const Text('Select Emails'),
            ),
          ),
          const SizedBox(height: 16),
          if (selectedEmailSubjects.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Selected Emails:', style: emailTxttStyle1),
                  ...selectedEmailSubjects
                      .take(maxEmailsInput)
                      .map(
                        (subject) => Text('- $subject', style: emailTxttStyle2),
                      ),
                ],
              ),
            ),
          const Divider(),
          if (selectedEmailSubjects.length >= maxEmailsInput)
            const Expanded(child: EmailChatWidget())
          else
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                'Please select at most three emails first.',
                style: emailTxttStyle1,
              ),
            ),
        ],
      ),
    );
  }
}


class EmailChatWidget extends StatefulWidget {
  const EmailChatWidget({super.key});

  @override
  State<EmailChatWidget> createState() => _EmailChatWidgetState();
}

class _EmailChatWidgetState extends State<EmailChatWidget> {
  final List<Map<String, String>> chatMessages = [];
  final TextEditingController _chatController = TextEditingController();

  void sendMessage(String text) {
    setState(() {
      chatMessages.add({'sender': 'You', 'message': text});
    });

    _generateBotReply(text);
    _chatController.clear();
  }

  void _generateBotReply(String userMessage) {
    final botReply = 'Echo: $userMessage';

    setState(() {
      chatMessages.add({'sender': 'Lotus', 'message': botReply});
    });
  }

  void _voiceChat() {
    // TODO: Implement voice chat logic
    print('Voice chat activated');
  }

  Widget _buildChatBubble(Map<String, String> message) {
    final isUser = message['sender'] == 'You';
    final String? userAvatarUrl = FirebaseAuth.instance.currentUser?.photoURL;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Row(
        mainAxisAlignment: isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser)
            const CircleAvatar(
              radius: 18,
              backgroundImage: AssetImage(
                'assets/images/robot_dark_avatar.png',
              ),
            ),
          if (!isUser) const SizedBox(width: 8),
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(
                gradient: isUser ? chatusergradient : chatbotgradient,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                  bottomLeft: Radius.circular(isUser ? 12 : 0),
                  bottomRight: Radius.circular(isUser ? 0 : 12),
                ),
              ),
              child: Text(message['message'] ?? '', style: chatbody),
            ),
          ),
          if (isUser) const SizedBox(width: 8),
          if (isUser)
            CircleAvatar(
              radius: 18,
              backgroundImage: userAvatarUrl != null
                  ? NetworkImage(userAvatarUrl)
                  : const AssetImage('assets/images/default_avt.png')
                        as ImageProvider,
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: chatMessages.length,
            itemBuilder: (context, index) {
              return _buildChatBubble(chatMessages[index]);
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _chatController,
                  decoration: const InputDecoration(
                    hintText: 'Type your request/ question.',
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(24)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  if (_chatController.text.trim().isNotEmpty) {
                    sendMessage(_chatController.text.trim());
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(6.0),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: purpleblue,
                    ),
                    child: const Icon(Icons.send, color: white),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Center(
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: _voiceChat,
            child: Container(
              padding: const EdgeInsets.all(6.0),
              child: Image.asset(
                'assets/images/robot_dark.png',
                height: 60,
                width: 60,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}
