import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lotus/constants.dart';
import 'package:lotus/services/chat_service.dart';
import 'package:lotus/services/speech_service.dart';
import 'package:lotus/widgets/message_widget.dart';
import 'package:lotus/widgets/input_bar_widget.dart';
import 'package:lotus/utils/utils.dart';
import 'package:lotus/screens/home_screen.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({Key? key}) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ChatService _chatService = ChatService();
  final SpeechService _speechService = SpeechService();
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, String>> _messages = [];
  final ScrollController _scrollController = ScrollController();

  bool _isVoiceInput = false;
  bool _isListening = false;
  bool _isLoading = false;
  bool _showKeyboardInput = false;
  String? _errorMessage;
  bool _keyboardVisible = false;

  @override
  void initState() {
    super.initState();
    _speechService.initialize(
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
        scrollToBottom(_scrollController);
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
                              style: onboardingheading,
                            ),
                            const SizedBox(height: 20),
                            const Text(
                              "How can I assist you today?",
                              style: onboardingbody,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 30),
                            Image.asset(
                              "assets/images/robot3.png",
                              height: 184,
                              width: 183,
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
                      itemBuilder: (context, index) => buildMessage(context, _messages[index]),
                    ),
                  ),
          ),
          buildInputBar(
            context: context,
            controller: _controller,
            isListening: _isListening,
            isVoiceInput: _isVoiceInput,
            showKeyboardInput: _showKeyboardInput,
            isLoading: _isLoading,
            onSendMessage: () {
              _chatService.sendMessage(
                text: _controller.text,
                messages: _messages,
                onLoading: (isLoading) => setState(() => _isLoading = isLoading),
                onError: (error) => setState(() => _errorMessage = error),
                scrollToBottom: () => scrollToBottom(_scrollController),
                controller: _controller, // Truyền controller
              );
            },
            onPickImage: () {
              _chatService.pickAndSendImage(
                messages: _messages,
                onLoading: (isLoading) => setState(() => _isLoading = isLoading),
                onError: (error) => setState(() => _errorMessage = error),
                scrollToBottom: () => scrollToBottom(_scrollController),
              );
            },
            onToggleListening: () {
              _speechService.toggleListening(
                controller: _controller,
                isListening: _isListening,
                onListeningChanged: (isListening) => setState(() => _isListening = isListening),
                onError: (error) => setState(() => _errorMessage = error),
                onSendMessage: () {
                  _chatService.sendMessage(
                    text: _controller.text,
                    messages: _messages,
                    onLoading: (isLoading) => setState(() => _isLoading = isLoading),
                    onError: (error) => setState(() => _errorMessage = error),
                    scrollToBottom: () => scrollToBottom(_scrollController),
                    controller: _controller, // Truyền controller
                  );
                },
                scrollController: _scrollController,
              );
            },
            onToggleKeyboard: () {
              setState(() {
                _isVoiceInput = false;
                _showKeyboardInput = true;
              });
            },
          ),
        ],
      ),
    );
  }
}