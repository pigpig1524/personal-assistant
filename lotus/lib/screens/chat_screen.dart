import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:lotus/constants.dart';
import 'package:lotus/screens/home_screen.dart';
import 'package:lotus/services/dialogflow_service.dart';
import 'package:lotus/services/calendar_service.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logger/logger.dart';

final logger = Logger();

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final DialogflowService _dialogflowService = DialogflowService();
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, String>> _messages = [];
  final ScrollController _scrollController = ScrollController();
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['https://www.googleapis.com/auth/calendar.events'],
  );

  bool _isVoiceInput = false;
  bool _isListening = false;
  bool _isLoading = false;
  bool _showKeyboardInput = false;
  String? _errorMessage;
  bool _keyboardVisible = false;

  late stt.SpeechToText _speech;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
  }

  Future<String?> _loadAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  Future<String?> _refreshAccessToken() async {
    GoogleSignInAccount? googleUser = _googleSignIn.currentUser;
    googleUser ??= await _googleSignIn.signInSilently();

    if (googleUser == null) {
      logger.w("Không thể đăng nhập lại silently");
      setState(() {
        _errorMessage = 'Vui lòng đăng nhập lại để tạo sự kiện.';
      });
      return null;
    }

    final googleAuth = await googleUser.authentication;
    final newAccessToken = googleAuth.accessToken;

    if (newAccessToken != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('access_token', newAccessToken);
      logger.i("Access token đã được làm mới");
      return newAccessToken;
    } else {
      logger.w("Lỗi khi làm mới access token");
      setState(() {
        _errorMessage = 'Không thể làm mới token.';
      });
      return null;
    }
  }

  void _toggleListening() async {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
    if (!_isListening) {
      bool available = await _speech.initialize(
        onStatus: (status) {
          if (status == 'done') {
            setState(() => _isListening = false);
          }
        },
        onError: (error) {
          setState(() {
            _isListening = false;
            _errorMessage = 'Không thể nhận diện giọng nói. Vui lòng thử lại!';
          });
        },
      );

      if (available) {
        setState(() {
          _isListening = true;
          _errorMessage = null;
        });
        _speech.listen(
          onResult: (result) {
            setState(() {
              _controller.text = result.recognizedWords;
            });
            if (result.finalResult) {
              _sendMessage();
            }
          },
        );
      } else {
        setState(() {
          _errorMessage = 'Thiết bị không hỗ trợ nhận diện giọng nói.';
        });
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  void _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isLoading) return;

    setState(() {
      _messages.add({'role': 'user', 'content': text});
      _isLoading = true;
      _errorMessage = null;
      _isVoiceInput = false;
      _showKeyboardInput = false;
      _keyboardVisible = false;
    });
    _controller.clear();
    _scrollToBottom();

    final result = await _dialogflowService.detectIntent(text);

    if (result != null) {
      final responseText = result['response'];
      final intent = result['intent'];
      final action = result['action'];
      final data = result['data'];

      setState(() {
        _messages.add({'role': 'assistant', 'content': responseText});
      });
      if (intent == 'CALENDAR' && action == 'CREATE_EVENT' && data != null) {
        final accessToken = await _loadAccessToken();
        if (accessToken != null &&
            data['start_date'] != null &&
            data['end_date'] != null &&
            (data['title'] != null || data['summary'] != null)) {
          final startDate = data['start_date'].replaceAll(RegExp(r'\+.*$'), '');
          final endDate = data['end_date'].replaceAll(RegExp(r'\+.*$'), '');

          final calendarService = CalendarService();
          final success = await calendarService.createEvent(
            accessToken: accessToken,
            title: data['title'] ?? data['summary'],
            startDate: startDate,
            endDate: endDate,
            onTokenExpired: _refreshAccessToken,
          );

          setState(() {
            _messages.add({
              'role': 'assistant',
              'content': success
                  ? 'Sự kiện "${data['title'] ?? data['summary']}" đã được tạo thành công!'
                  : 'Không thể tạo sự kiện. Vui lòng kiểm tra thông tin.',
            });
          });
        } else {
          setState(() {
            _messages.add({
              'role': 'assistant',
              'content': 'Thiếu thông tin hoặc không thể lấy access token.',
            });
          });
        }
      }
    } else {
      setState(() {
        _messages.add({'role': 'assistant', 'content': 'Xin lỗi, tôi không hiểu.'});
      });
    }

    setState(() {
      _isLoading = false;
    });

    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Widget _buildMessage(Map<String, String> message) {
    final isUser = message['role'] == 'user';
    final String? userAvatarUrl = FirebaseAuth.instance.currentUser?.photoURL;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser)
            const CircleAvatar(
              radius: 18,
              backgroundImage: AssetImage('assets/images/bot_avatar.png'),
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
              child: Text(message['content'] ?? '', style: chatbody),
            ),
          ),
          if (isUser) const SizedBox(width: 8),
          if (isUser)
            CircleAvatar(
              radius: 18,
              backgroundImage: userAvatarUrl != null
                  ? NetworkImage(userAvatarUrl)
                  : const AssetImage('assets/images/default_avt.png') as ImageProvider,
            ),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    if (_isListening) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 40),
        child: Center(
          child: Column(
            children: [
              const Text(
                "I'm listening...",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.indigo),
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: _toggleListening,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: pautegradient,
                  ),
                  child: const Icon(Icons.pause, color: Colors.white, size: 30),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_showKeyboardInput) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                onSubmitted: (_) => _sendMessage(),
                decoration: InputDecoration(
                  hintText: 'Message...',
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _sendMessage,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFB9B5F8),
                ),
                child: const Icon(Icons.send, color: Colors.white),
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: () {
              // TODO: handle +
            },
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.deepPurple.shade100),
              ),
              child: const Icon(Icons.add, color: Colors.deepPurple),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () {
              setState(() {
                _isVoiceInput = true;
                _showKeyboardInput = false;
                _toggleListening();
              });
            },
            child: Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFF92A3FD),
              ),
              child: const Icon(Icons.mic, color: Colors.white, size: 30),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () {
              setState(() {
                _isVoiceInput = false;
                _showKeyboardInput = true;
              });
            },
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.deepPurple.shade100),
              ),
              child: const Icon(Icons.keyboard, color: Colors.deepPurple),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final displayName = user?.displayName ?? 'User';
    final String? userAvatarUrl = user?.photoURL;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final isKeyboardVisible = bottomInset > 0;

    if (isKeyboardVisible && !_keyboardVisible) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });
    }
    _keyboardVisible = isKeyboardVisible;

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text(' '),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => HomeScreen()),
            );
          },
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: CircleAvatar(
              radius: 20,
              backgroundImage: userAvatarUrl != null
                  ? NetworkImage(userAvatarUrl)
                  : const AssetImage('assets/images/default_avt.png') as ImageProvider,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          if (_errorMessage != null)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          Expanded(
            child: _messages.isEmpty
                ? Align(
                    alignment: Alignment.topCenter,
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 60.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Text(
                              "Hello, $displayName!",
                              style: homeHeadingTxtStyle1,
                            ),
                            const SizedBox(height: 20),
                            const Text(
                              "How can I assist you today?",
                              style: homeHeadingTxtStyle2,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 30),
                            Image.asset(
                              "assets/images/robot2.png",
                              height: 184,
                              width: 163,
                              fit: BoxFit.cover,
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                : GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      if (_showKeyboardInput) {
                        FocusScope.of(context).unfocus();
                        setState(() {
                          _showKeyboardInput = false;
                          _isVoiceInput = false;
                        });
                      }
                    },
                    child: ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(12),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) => _buildMessage(_messages[index]),
                    ),
                  ),
          ),
          _buildInputBar(),
        ],
      ),
    );
  }
}