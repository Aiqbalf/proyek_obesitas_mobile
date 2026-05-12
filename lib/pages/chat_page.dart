import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api_service.dart';

class ChatPage extends StatefulWidget {
  final bool embedded;
  const ChatPage({super.key, this.embedded = false});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  // ── Palette ──
  static const Color _green900  = Color(0xFF064E3B);
  static const Color _green700  = Color(0xFF047857);
  static const Color _green500  = Color(0xFF10B981);
  static const Color _green100  = Color(0xFFD1FAE5);
  static const Color _green50   = Color(0xFFF0FDF4);
  static const Color _neutral50  = Color(0xFFF9FAFB);
  static const Color _neutral100 = Color(0xFFF3F4F6);
  static const Color _neutral200 = Color(0xFFE5E7EB);
  static const Color _neutral400 = Color(0xFF9CA3AF);
  static const Color _neutral600 = Color(0xFF4B5563);
  static const Color _neutral900 = Color(0xFF111827);

  final TextEditingController _inputCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();

  List<Map<String, String>> _messages = [];
  bool _isLoading = false;

  // ── Suggested questions ──
  final List<String> _suggestions = [
    '🥗 Tips diet sehat',
    '⚖️ Apa itu obesitas?',
    '🏃 Olahraga untuk turun berat',
    '📊 BMI normal berapa?',
  ];

  @override
  void dispose() {
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendMessage([String? quickText]) async {
    final text = (quickText ?? _inputCtrl.text).trim();
    if (text.isEmpty) return;

    HapticFeedback.lightImpact();
    setState(() {
      _messages.add({'role': 'user', 'text': text});
      _isLoading = true;
    });
    _inputCtrl.clear();
    _scrollToBottom();

    final result = await ApiService.chat(text);

    setState(() {
      _isLoading = false;
      if (result['status'] == 200) {
        _messages.add({'role': 'bot', 'text': result['data']['reply'] ?? 'Tidak ada respon'});
      } else {
        _messages.add({'role': 'bot', 'text': result['data']['message'] ?? 'Terjadi kesalahan'});
      }
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ── Message bubble ──
  Widget _bubble(Map<String, String> msg) {
    final isUser = msg['role'] == 'user';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Bot avatar
          if (!isUser) ...[
            Container(
              width: 32, height: 32,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [_green500, _green700],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.smart_toy_rounded, color: Colors.white, size: 17),
            ),
            const SizedBox(width: 8),
          ],

          // Bubble
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.72,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isUser ? _green700 : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(isUser ? 20 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: isUser
                        ? _green700.withOpacity(0.25)
                        : Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Text(
                msg['text'] ?? '',
                style: TextStyle(
                  fontSize: 14,
                  color: isUser ? Colors.white : _neutral900,
                  height: 1.45,
                ),
              ),
            ),
          ),

          // User avatar
          if (isUser) ...[
            const SizedBox(width: 8),
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                color: _neutral200,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.person_rounded, color: _neutral600, size: 18),
            ),
          ],
        ],
      ),
    );
  }

  // ── Typing indicator ──
  Widget _typingIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 32, height: 32,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [_green500, _green700],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.smart_toy_rounded, color: Colors.white, size: 17),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
                bottomRight: Radius.circular(20),
                bottomLeft: Radius.circular(4),
              ),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 3))],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (i) => _dot(i)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dot(int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 500 + index * 150),
      builder: (_, v, __) => Container(
        margin: const EdgeInsets.symmetric(horizontal: 3),
        width: 7, height: 7,
        decoration: BoxDecoration(
          color: _green500.withOpacity(0.4 + 0.6 * v),
          shape: BoxShape.circle,
        ),
      ),
    );
  }

  // ── Empty state ──
  Widget _emptyState() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80, height: 80,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [_green100, _green50],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.smart_toy_rounded, color: _green700, size: 40),
            ),
            const SizedBox(height: 16),
            const Text('Halo! Saya SiObe 👋',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: _neutral900, letterSpacing: -0.3)),
            const SizedBox(height: 8),
            const Text('Asisten kesehatan virtual Anda.\nTanyakan apa saja seputar kesehatan & gizi.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: _neutral400, height: 1.5)),
            const SizedBox(height: 28),
            // Suggestion chips
            Wrap(
              spacing: 8, runSpacing: 10,
              alignment: WrapAlignment.center,
              children: _suggestions.map((s) => GestureDetector(
                onTap: () => _sendMessage(s),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: _neutral200),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6, offset: const Offset(0, 2))],
                  ),
                  child: Text(s, style: const TextStyle(fontSize: 13, color: _neutral600, fontWeight: FontWeight.w500)),
                ),
              )).toList(),
            ),
          ],
        ),
      ),
    );
  }

  // ── Input bar ──
  Widget _inputBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: _neutral200, width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: _neutral50,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: _neutral200),
                ),
                child: TextField(
                  controller: _inputCtrl,
                  maxLines: 4,
                  minLines: 1,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _sendMessage(),
                  style: const TextStyle(fontSize: 14, color: _neutral900),
                  decoration: const InputDecoration(
                    hintText: 'Tanya tentang kesehatan...',
                    hintStyle: TextStyle(color: _neutral400, fontSize: 14),
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    border: InputBorder.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _sendMessage,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 46, height: 46,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_green500, _green700],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _neutral50,
      appBar: AppBar(
        automaticallyImplyLeading: !widget.embedded,
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
        ),
        leadingWidth: widget.embedded ? 0 : 56,
        title: Row(
          children: [
            Container(
              width: 36, height: 36,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [_green500, _green700],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.smart_toy_rounded, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('SiObe Assistant',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: _neutral900, letterSpacing: -0.3)),
                Row(
                  children: [
                    Container(
                      width: 7, height: 7,
                      decoration: const BoxDecoration(color: _green500, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 5),
                    const Text('Online', style: TextStyle(fontSize: 11, color: _neutral400, fontWeight: FontWeight.w500)),
                  ],
                ),
              ],
            ),
          ],
        ),
        actions: [
          if (_messages.isNotEmpty)
            GestureDetector(
              onTap: () => setState(() => _messages.clear()),
              child: Container(
                margin: const EdgeInsets.only(right: 12),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: _neutral100, borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.delete_outline_rounded, size: 18, color: _neutral600),
              ),
            ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: _neutral200),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? _emptyState()
                : ListView.builder(
                    controller: _scrollCtrl,
                    padding: const EdgeInsets.fromLTRB(12, 16, 12, 16),
                    itemCount: _messages.length + (_isLoading ? 1 : 0),
                    itemBuilder: (_, i) {
                      if (_isLoading && i == _messages.length) return _typingIndicator();
                      return _bubble(_messages[i]);
                    },
                  ),
          ),
          _inputBar(),
        ],
      ),
    );
  }
}