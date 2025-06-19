import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:lotus/constants.dart';
import 'package:googleapis/gmail/v1.dart' as gmail;
import 'package:lotus/screens/email_list_screen.dart';
import 'package:lotus/services/email_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';

class EmailScreen extends StatefulWidget {
  const EmailScreen({super.key});

  @override
  State<EmailScreen> createState() => _EmailScreenState();
}

class _EmailScreenState extends State<EmailScreen> {
  User? user;
  String? photoUrl;

  String? _accessToken;
  List<gmail.Message> emails = [];

  gmail.Message? selectedEmail;
  String? selectedEmailSubject;
  String? selectedEmailBody;
  String? fromAddress;

  bool isLoading = true;

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: <String>[
      gmail.GmailApi.gmailReadonlyScope,
      'email',
      'https://www.googleapis.com/auth/userinfo.profile',
    ],
  );

  final EmailService emailService = EmailService();
  final List<Map<String, String>> chatMessages = [];
  final TextEditingController _chatController = TextEditingController();

  @override
  void initState() {
    super.initState();
    user = FirebaseAuth.instance.currentUser;
    photoUrl = user?.photoURL;
    fetchEmails();
  }

  Future<void> fetchEmails() async {
    setState(() {
      isLoading = true;
    });

    final account = await _googleSignIn.signIn();
    final auth = await account?.authentication;

    if (auth == null || auth.accessToken == null) {
      setState(() {
        isLoading = false;
      });
      return;
    }

    _accessToken = auth.accessToken;

    if (account == null) {
      setState(() {
        isLoading = false;
      });
      return;
    }

    final fetchedEmails = await emailService.fetchEmails(account);

    setState(() {
      emails = fetchedEmails;
      isLoading = false;
    });
  }

  String _decodeBase64(String data) {
    final normalized = data.replaceAll('-', '+').replaceAll('_', '/');
    return utf8.decode(base64.decode(normalized));
  }

  String? _extractEmailBody(gmail.MessagePart? payload) {
    if (payload == null) return null;

    if (payload.parts != null) {
      for (var part in payload.parts!) {
        if (part.mimeType == 'text/plain' && part.body?.data != null) {
          return _decodeBase64(part.body!.data!);
        }
      }
    }

    // Fallback to main body
    if (payload.body?.data != null) {
      return _decodeBase64(payload.body!.data!);
    }

    return null;
  }

  String? _getHeader(List<gmail.MessagePartHeader>? headers, String name) {
    if (headers == null) return null;
    return headers
        .firstWhere(
          (h) => h.name?.toLowerCase() == name.toLowerCase(),
          orElse: () => gmail.MessagePartHeader(name: '', value: ''),
        )
        .value;
  }

  Future<void> _selectEmailFromList() async {
    if (emails.isEmpty) return;

    final selected = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EmailListScreen(
          title: 'Select an Email',
          emails: emails,
          isSelectionMode: true,
        ),
      ),
    );

    if (selected != null &&
        selected is List<gmail.Message> &&
        selected.isNotEmpty) {
      final email = selected.first;

      final subject =
          email.payload?.headers
              ?.firstWhere(
                (h) => h.name?.toLowerCase() == 'subject',
                orElse: () =>
                    gmail.MessagePartHeader(name: '', value: 'No Subject'),
              )
              .value ??
          'No Subject';

      final bodyData = _extractEmailBody(email.payload);
      final body = bodyData ?? 'No content';

      final rawFrom = _getHeader(email.payload?.headers, 'From') ?? '';
      final from = extractEmailAddress(rawFrom);

      setState(() {
        selectedEmail = email;
        selectedEmailSubject = subject;
        selectedEmailBody = body;
        fromAddress = from;
        chatMessages.clear();
      });
    }
  }

  String extractEmailAddress(String fromHeader) {
    final emailRegex = RegExp(r'<(.+?)>');
    final match = emailRegex.firstMatch(fromHeader);
    if (match != null && match.groupCount > 0) {
      return match.group(1)!; // email inside <>
    } else {
      // If no <>, might be just the email or something else
      return fromHeader;
    }
  }

  void sendMessage(String text) {
    setState(() {
      chatMessages.add({'sender': 'You', 'message': text});
    });

    _generateBotReply(text);
    _chatController.clear();
  }

  void _generateBotReply(String userMessage) async {
    setState(() {
      chatMessages.add({'sender': 'Lotus', 'message': 'Thinking...'});
    });

    final indexOfThinking = chatMessages.length - 1;

    final result = await emailService.detectIntent(
      userMessage,
      selectedEmailSubject ?? 'No Subject',
      selectedEmailBody ?? 'No content',
    );

    if (!mounted) return;

    chatMessages.removeAt(indexOfThinking);

    if (result != null) {
      final action = result['action'];
      final response = result['response'];

      if (action == 'AUTOMATIC_RESPOND' && response is Map) {
        final subject = response['subject'] ?? '';
        final content = response['content'] ?? '';

        // Show dialog
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Send Suggested Email'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: 'To: ',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        TextSpan(text: fromAddress),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: 'Subject: ',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        TextSpan(text: subject),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: 'Content:\n',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  SizedBox(
                    height: 160, // Set the height you want
                    child: SingleChildScrollView(child: Text(content)),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  child: const Text('Cancel'),
                  onPressed: () {
                    Navigator.of(context).pop();
                    setState(() {
                      chatMessages.add({
                        'sender': 'Lotus',
                        'message': 'Action cancelled.',
                      });
                    });
                  },
                ),
                TextButton(
                  child: const Text('Save Draft'),
                  onPressed: () {
                    Navigator.of(context).pop();
                    emailService.saveDraftEmail(
                      to: fromAddress ?? '',
                      subject: subject,
                      body: content,
                      accessToken: _accessToken!,
                    );
                    setState(() {
                      chatMessages.add({
                        'sender': 'Lotus',
                        'message': 'Draft saved successfully.',
                      });
                    });
                  },
                ),
                ElevatedButton(
                  child: const Text('Send'),
                  onPressed: () {
                    Navigator.of(context).pop();
                    emailService.sendEmail(
                      to: fromAddress ?? '',
                      subject: subject,
                      body: content,
                      accessToken: _accessToken!,
                    );
                    setState(() {
                      chatMessages.add({
                        'sender': 'Lotus',
                        'message': 'Email sent successfully.',
                      });
                    });
                  },
                ),
              ],
            );
          },
        );
      } else if (action == 'EMAIL_CLASSIFICATION' ||
          action == 'EMAIL_SUMMARIZATION') {
        setState(() {
          chatMessages.add({
            'sender': 'Lotus',
            'message': response?.toString() ?? 'No response received.',
          });
        });
      } else {
        setState(() {
          chatMessages.add({
            'sender': 'Lotus',
            'message':
                response?.toString() ??
                'Unrecognized action or empty response.',
          });
        });
      }
    } else {
      setState(() {
        chatMessages.add({
          'sender': 'Lotus',
          'message': 'Sorry, something went wrong.',
        });
      });
    }
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
    return Scaffold(
      backgroundColor: white,
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Email Management'),
        backgroundColor: magnolia,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Emails',
            onPressed: fetchEmails,
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: CircleAvatar(
              radius: 20,
              backgroundImage: photoUrl != null
                  ? NetworkImage(photoUrl!)
                  : const AssetImage('assets/images/default_avatar.png')
                        as ImageProvider,
              child: photoUrl == null
                  ? const Icon(Icons.account_circle, size: 40)
                  : null,
            ),
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: black))
          : Column(
              children: [
                const SizedBox(height: 16),
                Center(
                  child: ElevatedButton(
                    onPressed: _selectEmailFromList,
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
                    child: const Text('Emails'),
                  ),
                ),
                const SizedBox(height: 16),
                if (selectedEmailSubject != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Selected Email:', style: emailTxttStyle1),
                        Text('- $selectedEmailSubject', style: emailTxttStyle2),
                      ],
                    ),
                  ),
                const Divider(),
                if (selectedEmailSubject == '')
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(
                      'Please select your email first.',
                      style: emailTxttStyle1,
                    ),
                  )
                else
                  Expanded(
                    child: Column(
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
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
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
                                      borderRadius: BorderRadius.all(
                                        Radius.circular(24),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              InkWell(
                                borderRadius: BorderRadius.circular(60),
                                onTap: () {
                                  if (_chatController.text.trim().isNotEmpty) {
                                    sendMessage(_chatController.text.trim());
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(12.0),
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
                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }
}
