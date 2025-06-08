import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lotus/constants.dart';
import 'package:lotus/services/dialogflow_service.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'onboarding.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({Key? key}) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final DialogflowService _dialogflowService = DialogflowService();
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, String>> _messages = [];
  final ScrollController _scrollController = ScrollController();

  bool _isVoiceInput = false;
  bool _isListening = false;
  bool _isLoading = false; 
  String? _errorMessage;   
  late stt.SpeechToText _speech;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
  }

  void _toggleListening() async {
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
            _errorMessage = "Không thể nhận diện giọng nói. Vui lòng thử lại!";
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
          _errorMessage = "Thiết bị không hỗ trợ nhận diện giọng nói.";
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
      _isLoading = false;
      _errorMessage = null;
      _isVoiceInput = false;
    });
    _controller.clear();
    _scrollToBottom();

    final response = await _dialogflowService.detectIntent(text);
    setState(() {
      if (response != null) {
        _messages.add({'role': 'assistant', 'content': response});
      } else {
        _messages.add({'role': 'assistant', 'content': 'Xin lỗi, tôi không hiểu.'});
      }
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      child: Row(
        children: [
          IconButton(
            icon: Icon(_isListening
                ? Icons.stop
                : (_isVoiceInput ? Icons.mic : Icons.keyboard)),
            onPressed: () {
              if (_isVoiceInput) {
                _toggleListening();
              } else {
                setState(() {
                  _isVoiceInput = !_isVoiceInput;
                  _errorMessage = null;
                });
              }
            },
            tooltip: _isListening
                ? "Dừng ghi âm"
                : (_isVoiceInput ? "Chuyển sang bàn phím" : "Nhập bằng giọng nói"),
          ),
          Expanded(
            child: TextField(
              controller: _controller,
              onSubmitted: (_) => _sendMessage(),
              enabled: !_isLoading,
              decoration: const InputDecoration(
                hintText: 'Nhập tin nhắn...',
                filled: true,
                fillColor: Color(0xFFF5F5F5),
                contentPadding: EdgeInsets.symmetric(horizontal: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(24)),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          _isLoading
              ? const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: (_controller.text.trim().isEmpty || _isLoading)
                      ? null
                      : _sendMessage,
                ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String? userAvatarUrl = FirebaseAuth.instance.currentUser?.photoURL;

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text(' '),
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
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(12),
              itemCount: _messages.length,
              itemBuilder: (context, index) => _buildMessage(_messages[index]),
            ),
          ),
          _buildInputBar(),
        ],
      ),
    );
  }
}
