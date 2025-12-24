import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/ai_chat_service.dart';
import '../services/firebase_data_service.dart';
import '../config/ai_chat_config.dart';

/// Trendyol tarzı AI Chat Bot Widget
/// Sağ alt köşede floating button, açıldığında chat penceresi
class AIChatWidget extends StatefulWidget {
  const AIChatWidget({super.key});

  @override
  State<AIChatWidget> createState() => _AIChatWidgetState();
}

class _AIChatWidgetState extends State<AIChatWidget> {
  final AIChatService _chatService = AIChatService();
  final FirebaseDataService _dataService = FirebaseDataService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _messageController = TextEditingController();
  final FocusNode _messageFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, String>> _messages = [];
  bool _isOpen = false;
  bool _isLoading = false;
  bool _welcomeMessageShown = false;

  @override
  void initState() {
    super.initState();
  }

  /// Kullanıcı adını al ve hoş geldin mesajını göster
  Future<void> _showWelcomeMessage() async {
    if (_welcomeMessageShown) return;
    
    String userName = 'Kullanıcı';
    
    try {
      final user = _auth.currentUser;
      if (user != null) {
        // Önce Firestore'dan kullanıcı profilini al
        try {
          final userProfile = await _dataService.getUserProfile()
              .timeout(const Duration(seconds: 3));
          
          if (userProfile != null && userProfile['fullName'] != null) {
            final fullName = userProfile['fullName'].toString().trim();
            if (fullName.isNotEmpty) {
              // İlk adı al (boşluktan önceki kısım)
              userName = fullName.split(' ').first;
            }
          }
        } catch (e) {
          // Firestore'dan alınamazsa FirebaseAuth'tan al
          if (user.displayName != null && user.displayName!.isNotEmpty) {
            userName = user.displayName!.split(' ').first;
          } else if (user.email != null) {
            userName = user.email!.split('@')[0];
          }
        }
      }
    } catch (e) {
      // Hata durumunda varsayılan isim kullan
    }

    if (mounted && !_welcomeMessageShown) {
      setState(() {
    _messages.add({
      'role': 'assistant',
          'content': 'Merhaba $userName! 👋\n\nHoşgeldiniz! Ben ${AIChatConfig.botName}. Size nasıl yardımcı olabilirim?\n\n• Ürün bilgisi\n• Sipariş durumu\n• Kargo takibi\n• Genel sorular',
        });
        _welcomeMessageShown = true;
    });
      _scrollToBottom();
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _messageFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty || _isLoading) return;

    // Kullanıcı mesajını ekle
    setState(() {
      _messages.add({
        'role': 'user',
        'content': message,
      });
      _isLoading = true;
    });
    _messageController.clear();
    _scrollToBottom();
    
    // TextField'ı tekrar focus'ta tut
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _messageFocusNode.requestFocus();
    });

    try {
      // AI'dan yanıt al
      final response = await _chatService.sendMessage(
        message: message,
        conversationHistory: _messages
            .where((m) => m['role'] != 'system')
            .map((m) => {'role': m['role']!, 'content': m['content']!})
            .toList(),
      );

      setState(() {
        _messages.add({
          'role': 'assistant',
          'content': response,
        });
        _isLoading = false;
      });
      _scrollToBottom();
      
      // TextField'ı tekrar focus'ta tut (setState sonrası)
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _messageFocusNode.canRequestFocus) {
          _messageFocusNode.requestFocus();
        }
      });
    } catch (e, stackTrace) {
      debugPrint('❌ Chat widget hatası: $e');
      debugPrint('Stack trace: $stackTrace');
      
      setState(() {
        _messages.add({
          'role': 'assistant',
          'content': 'Üzgünüm, bir hata oluştu. Lütfen tekrar deneyin. 😊',
        });
        _isLoading = false;
      });
      _scrollToBottom();
      
      // TextField'ı tekrar focus'ta tut
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _messageFocusNode.requestFocus();
      });
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Floating Chat Button (sağ alt köşe)
        if (!_isOpen)
          Positioned(
            bottom: 20,
            right: 20,
            child: _buildFloatingButton(),
          ),
        // Chat Window (açık olduğunda)
        if (_isOpen)
          Positioned(
            bottom: 20,
            right: 20,
            child: _buildChatWindow(),
          ),
      ],
    );
  }

  Widget _buildFloatingButton() {
    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(30),
      color: const Color(0xFFFF6000), // Trendyol turuncu
      child: InkWell(
        onTap: () {
          setState(() {
            _isOpen = true;
            // Chat penceresi açıldığında TextField'ı focus'ta tut
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _messageFocusNode.requestFocus();
            });
          });
          // Chat açıldığında hoş geldin mesajını göster
          _showWelcomeMessage();
        },
        borderRadius: BorderRadius.circular(30),
        child: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            color: const Color(0xFFFF6000),
          ),
          child: Stack(
            children: [
              const Center(
                child: Icon(
                  Icons.chat_bubble_outline,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              // Yeni mesaj göstergesi (isteğe bağlı)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: const BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChatWindow() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;
    
    return Material(
      elevation: 16,
      borderRadius: BorderRadius.circular(16),
      color: Colors.white,
      child: Container(
        width: isMobile ? screenWidth - 40 : 400,
        height: isMobile ? screenWidth * 0.8 : 600,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            // Header
            _buildHeader(),
            // Messages
            Expanded(
              child: _buildMessagesList(),
            ),
            // Input
            _buildInputArea(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFF6000),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.smart_toy,
              color: Color(0xFFFF6000),
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AIChatConfig.botName,
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Çevrimiçi',
                  style: GoogleFonts.inter(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () {
              setState(() {
                _isOpen = false;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMessagesList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _messages.length + (_isLoading ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _messages.length) {
          // Loading indicator
          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF6000)),
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        final message = _messages[index];
        final isUser = message['role'] == 'user';

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            mainAxisAlignment:
                isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isUser) ...[
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF6000),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.smart_toy,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: isUser
                        ? const Color(0xFFFF6000)
                        : const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    message['content'] ?? '',
                    style: GoogleFonts.inter(
                      color: isUser ? Colors.white : const Color(0xFF1A1A1A),
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                ),
              ),
              if (isUser) ...[
                const SizedBox(width: 8),
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0E0E0),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.person,
                    color: Color(0xFF666666),
                    size: 18,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        border: Border(
          top: BorderSide(
            color: Colors.grey.withOpacity(0.2),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              focusNode: _messageFocusNode,
              decoration: InputDecoration(
                hintText: 'Mesajınızı yazın...',
                hintStyle: GoogleFonts.inter(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(
                    color: Colors.grey.withOpacity(0.3),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(
                    color: Colors.grey.withOpacity(0.3),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: const BorderSide(
                    color: Color(0xFFFF6000),
                    width: 2,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              style: GoogleFonts.inter(fontSize: 14),
              maxLines: null,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 8),
          Material(
            color: const Color(0xFFFF6000),
            borderRadius: BorderRadius.circular(24),
            child: InkWell(
              onTap: _isLoading ? null : _sendMessage,
              borderRadius: BorderRadius.circular(24),
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  color: _isLoading
                      ? Colors.grey[400]
                      : const Color(0xFFFF6000),
                ),
                child: const Icon(
                  Icons.send,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

