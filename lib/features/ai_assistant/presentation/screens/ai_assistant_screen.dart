import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/theme/theme.dart';
import '../../../../localization/app_localizations.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class AIAssistantScreen extends ConsumerStatefulWidget {
  const AIAssistantScreen({super.key});

  @override
  ConsumerState<AIAssistantScreen> createState() => _AIAssistantScreenState();
}

class _AIAssistantScreenState extends ConsumerState<AIAssistantScreen> with TickerProviderStateMixin {
  final List<Map<String, dynamic>> _messages = [];
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  late AnimationController _ambientGlowController;
  bool _isTyping = false;
  bool _isListening = false;
  String _activeMode = 'Konsumen'; // 'Konsumen' | 'UMKM' | 'Gudang'
  String _typingMessage = 'Menganalisis pertanyaan...';

  @override
  void initState() {
    super.initState();
    _ambientGlowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    )..repeat();
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;
    if (_isTyping) return;

    setState(() {
      _messages.add({'isUser': true, 'text': text});
      _isTyping = true;
      _typingMessage = 'Menganalisis pertanyaan...';
    });
    _textController.clear();
    _scrollToBottom();

    // Dynamic thinking/loading state rotation
    int loadingStep = 0;
    final List<String> loadingPhrases = [
      'Menganalisis pertanyaan...',
      'Mencari informasi...',
      'Menyiapkan jawaban...',
    ];
    
    final timer = Timer.periodic(const Duration(seconds: 3), (t) {
      if (!mounted || !_isTyping) {
        t.cancel();
        return;
      }
      loadingStep = (loadingStep + 1) % loadingPhrases.length;
      setState(() {
        _typingMessage = loadingPhrases[loadingStep];
      });
    });

    final startTime = DateTime.now();
    debugPrint('🤖 AI ASSISTANT [FRONTEND]: Question: "$text"');
    debugPrint('🤖 AI ASSISTANT [FRONTEND]: Request Start at $startTime');

    try {
      String endpoint = '/ai/chat';
      Map<String, dynamic> body = {'message': text};
      bool isPostWithBody = true;

      if (_activeMode == 'Gudang') {
        final lowerText = text.toLowerCase();
        if (lowerText.contains('komunitas') || lowerText.contains('usulan') || lowerText.contains('permintaan') || lowerText.contains('demand')) {
          endpoint = '/ai/community';
          isPostWithBody = false;
        } else if (lowerText.contains('pengadaan') || lowerText.contains('restok') || lowerText.contains('stok kritis') || lowerText.contains('stoknya hampir habis')) {
          endpoint = '/ai/inventory';
          isPostWithBody = false;
        } else if (lowerText.contains('anomali') || lowerText.contains('audit') || lowerText.contains('mencurigakan') || lowerText.contains('anomaly')) {
          endpoint = '/ai/anomaly';
          isPostWithBody = false;
        } else {
          endpoint = '/ai/management';
        }
      }

      debugPrint('🤖 AI ASSISTANT [FRONTEND]: Target Endpoint = $endpoint');

      final dio = ref.read(dioProvider);
      final response = await dio.post(
        endpoint,
        data: isPostWithBody ? body : null,
        options: Options(
          connectTimeout: const Duration(seconds: 20),
          receiveTimeout: const Duration(seconds: 20),
        ),
      );

      final endTime = DateTime.now();
      final duration = endTime.difference(startTime).inMilliseconds;
      debugPrint('🤖 AI ASSISTANT [FRONTEND]: Request End at $endTime');
      debugPrint('🤖 AI ASSISTANT [FRONTEND]: Duration: ${duration}ms');
      debugPrint('🤖 AI ASSISTANT [FRONTEND]: HTTP status: ${response.statusCode}');

      String aiResponse = '';
      if (response.data != null) {
        final Map<String, dynamic> responseMap = response.data as Map<String, dynamic>;
        aiResponse = responseMap['response'] ?? responseMap['data'] ?? '';
      }

      if (aiResponse.isEmpty) {
        aiResponse = 'Maaf, layanan AI tidak mengembalikan jawaban. Silakan coba kembali beberapa saat lagi.';
      }

      // Add a blank AI message first, then simulate typing/streaming effect
      setState(() {
        _isTyping = false;
        _messages.add({'isUser': false, 'text': ''});
      });
      _scrollToBottom();

      final int messageIndex = _messages.length - 1;
      int charIndex = 0;
      Timer.periodic(const Duration(milliseconds: 15), (t) {
        if (!mounted) {
          t.cancel();
          return;
        }
        charIndex += 4; // Add 4 characters at a time for smooth but snappy typing
        if (charIndex >= aiResponse.length) {
          charIndex = aiResponse.length;
          t.cancel();
        }
        setState(() {
          _messages[messageIndex] = {
            'isUser': false,
            'text': aiResponse.substring(0, charIndex),
          };
        });
        _scrollToBottom();
      });
    } on DioException catch (e) {
      final endTime = DateTime.now();
      final duration = endTime.difference(startTime).inMilliseconds;
      debugPrint('🤖 AI ASSISTANT [FRONTEND]: Request Failed with DioException at $endTime');
      debugPrint('🤖 AI ASSISTANT [FRONTEND]: Duration: ${duration}ms');
      debugPrint('🤖 AI ASSISTANT [FRONTEND]: Exception Type: ${e.type}');
      debugPrint('🤖 AI ASSISTANT [FRONTEND]: Status Code: ${e.response?.statusCode}');
      debugPrint('🤖 AI ASSISTANT [FRONTEND]: Error Message: ${e.message}');
      debugPrint('🤖 AI ASSISTANT [FRONTEND]: Response Body: ${e.response?.data}');

      String errorMessage = 'Maaf, layanan AI sedang mengalami gangguan. Silakan coba kembali beberapa saat lagi.';
      
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        errorMessage = 'AI sedang sibuk. Silakan coba beberapa saat lagi.';
      } else if (e.response?.statusCode == 401 || e.response?.statusCode == 403) {
        errorMessage = 'Akses ditolak. Silakan periksa kembali login akun Anda.';
      } else if (e.response?.statusCode == 429) {
        errorMessage = 'Terlalu banyak permintaan. Silakan tunggu beberapa saat lagi.';
      } else if (e.response?.statusCode == 404) {
        errorMessage = 'Layanan AI tidak ditemukan. Silakan hubungi admin.';
      } else if (e.response?.statusCode == 500 || e.response?.statusCode == 503) {
        errorMessage = 'Maaf, layanan AI sedang mengalami gangguan. Silakan coba kembali beberapa saat lagi.';
      } else if (e.error is SocketException) {
        errorMessage = 'Koneksi internet terputus. Harap periksa jaringan Anda.';
      }

      setState(() {
        _isTyping = false;
        _messages.add({'isUser': false, 'text': errorMessage});
      });
      _scrollToBottom();
    } catch (e) {
      final endTime = DateTime.now();
      final duration = endTime.difference(startTime).inMilliseconds;
      debugPrint('🤖 AI ASSISTANT [FRONTEND]: Request Failed with Generic Exception: $e');
      debugPrint('🤖 AI ASSISTANT [FRONTEND]: Duration: ${duration}ms');

      setState(() {
        _isTyping = false;
        _messages.add({
          'isUser': false,
          'text': 'Maaf, layanan AI sedang mengalami gangguan. Silakan coba kembali beberapa saat lagi.'
        });
      });
      _scrollToBottom();
    } finally {
      timer.cancel();
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: AppAnimation.normal,
          curve: AppAnimation.defaultCurve,
        );
      }
    });
  }

  void _startVoiceListening() {
    setState(() {
      _isListening = true;
    });
    // Simulate voice-to-text input after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted || !_isListening) return;
      setState(() {
        _isListening = false;
      });
      String speechText = '';
      if (_activeMode == 'Konsumen') {
        speechText = 'rekomendasi produk terlaris minggu ini';
      } else if (_activeMode == 'UMKM') {
        speechText = 'rekomendasi produk usaha warung';
      } else {
        speechText = 'produk yang stoknya hampir habis';
      }
      _textController.text = speechText;
      _sendMessage(speechText);
    });
  }

  void _cancelVoiceListening() {
    setState(() {
      _isListening = false;
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _ambientGlowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final userName = user?.name ?? 'Anggota';
    final isEmpty = _messages.isEmpty;

    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          // 1. Futuristic Ambient Glowing Background
          Positioned.fill(
            child: _AnimatedAmbientGlow(controller: _ambientGlowController),
          ),

          // Tech Grid Overlay
          Positioned.fill(
            child: CustomPaint(
              painter: _TechGridPainter(),
            ),
          ),

          // 2. Main Contents Stack
          Positioned.fill(
            child: Column(
              children: [
                // Dynamic App Bar matching the mockup
                _buildDynamicAppBar(isEmpty, userName),

                // Mode Selector Bar (Futuristic design)
                if (user?.role != null &&
                    user?.role != 'CUSTOMER' &&
                    user?.role != 'COURIER')
                  _buildModeSelectorBar(),

                // Chat body / Message list
                Expanded(
                  child: isEmpty
                      ? _buildFuturisticEmptyState()
                      : _buildMessageList(),
                ),

                // Typing indicator
                if (_isTyping)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.sm,
                    ),
                    child: Row(
                      children: [
                        const SizedBox(width: AppSpacing.xs),
                        _TypingDots(),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          _typingMessage,
                          style: AppTypography.captionSmall.copyWith(
                            color: const Color(0xFF6B7280),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),

                // Text Input Area
                _buildInputArea(),
              ],
            ),
          ),

          // 3. Futuristic Voice Soundwave Overlay
          if (_isListening)
            Positioned.fill(
              child: _ListeningWaveOverlay(
                onCancel: _cancelVoiceListening,
                activeMode: _activeMode,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDynamicAppBar(bool showWelcome, String userName) {
    if (showWelcome) {
      return Container(
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 16,
          left: 20,
          right: 20,
          bottom: 20,
        ),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFD32F2F), Color(0xFFC62828)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(32),
            bottomRight: Radius.circular(32),
          ),
        ),
        child: Row(
          children: [
            // Green status dot
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Color(0xFF22C55E),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'AI ASSISTANT',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                  SizedBox(height: 1),
                  Text(
                    'KOPDES MERAH PUTIH',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            // Clock / History icon button
            _buildHeaderButton(
              icon: Icons.history_toggle_off_rounded,
              onTap: () {},
            ),
            const SizedBox(width: 8),
            // Sparkling stars icon button (glowing white container with red star icon)
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {},
                  borderRadius: BorderRadius.circular(12),
                  child: const Center(
                    child: Icon(Icons.auto_awesome_rounded, color: Color(0xFFD32F2F), size: 20),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      // Chat mode App Bar with back button on red background
      return Container(
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 16,
          left: 20,
          right: 20,
          bottom: 20,
        ),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFD32F2F), Color(0xFFC62828)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(32),
            bottomRight: Radius.circular(32),
          ),
        ),
        child: Row(
          children: [
            _buildHeaderButton(
              icon: Icons.chevron_left_rounded,
              onTap: () {
                setState(() {
                  _messages.clear();
                });
              },
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'KOPDES AI Chat',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 1),
                  Text(
                    'Asisten Virtual Koperasi',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            _buildHeaderButton(
              icon: Icons.delete_sweep_outlined,
              iconColor: Colors.white,
              onTap: () {
                setState(() {
                  _messages.clear();
                });
              },
            ),
          ],
        ),
      );
    }
  }

  Widget _buildHeaderButton({
    required IconData icon,
    required VoidCallback onTap,
    Color iconColor = Colors.white,
    Color backgroundColor = const Color(0x26FFFFFF),
    Color borderColor = const Color(0x1AFFFFFF),
  }) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 1.2),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Center(
            child: Icon(icon, color: iconColor, size: 20),
          ),
        ),
      ),
    );
  }

  Widget _buildModeSelectorBar() {
    final List<Map<String, dynamic>> modes = [
      {'name': 'Konsumen', 'icon': Icons.shopping_bag_outlined, 'desc': 'Kebutuhan Belanja'},
      {'name': 'UMKM', 'icon': Icons.storefront_rounded, 'desc': 'Analisis Warung'},
      {'name': 'Gudang', 'icon': Icons.inventory_2_outlined, 'desc': 'Stok & Koperasi'},
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6).withOpacity(0.85),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: modes.map((mode) {
          final isSelected = _activeMode == mode['name'];
          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _activeMode = mode['name'];
                  _messages.clear(); // Clear chat to match mode context
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutBack,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : [],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      mode['icon'],
                      size: 16,
                      color: isSelected ? AppColors.primary : const Color(0xFF6B7280),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      mode['name'],
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                        color: isSelected ? const Color(0xFF1F2937) : const Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildFuturisticEmptyState() {
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final userName = user?.name ?? 'Anggota';

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      children: [
        // 1. Welcome Message & Orbital AI Logo Row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Halo $userName',
                      style: const TextStyle(
                        color: Color(0xFF1F2937),
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      '👋',
                      style: TextStyle(fontSize: 22),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  'Ada yang bisa saya bantu hari ini?',
                  style: TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            // Custom Concentric Rings AI Logo
            _buildOrbitalAILogo(),
          ],
        ),

        // 2. KOPDES AI Assistant Card with Mascot
        _buildAIAssistantBannerCard(),

        // 3. Rekomendasi & Bantuan Header
        Row(
          children: const [
            Icon(Icons.lightbulb_outline_rounded, color: Color(0xFFF59E0B), size: 18),
            SizedBox(width: 8),
            Text(
              'Rekomendasi & Bantuan',
              style: TextStyle(
                color: Color(0xFF1F2937),
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // 4. Suggestions grid
        _buildCategorizedSuggestions(),
        const SizedBox(height: 24),

        // 5. Coba tanyakan ini Header
        Row(
          children: const [
            Icon(Icons.auto_awesome_rounded, color: Color(0xFF6B7280), size: 16),
            SizedBox(width: 8),
            Text(
              'Coba tanyakan ini',
              style: TextStyle(
                color: Color(0xFF1F2937),
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // 6. Suggestions pills
        _buildPromptPills(),
      ],
    );
  }

  Widget _buildOrbitalAILogo() {
    return SizedBox(
      width: 110,
      height: 110,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer ring 2
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFFD32F2F).withOpacity(0.04),
                width: 1,
              ),
            ),
          ),
          // Outer ring 1
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFFD32F2F).withOpacity(0.08),
                width: 1.5,
              ),
            ),
          ),
          // Center Orb
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFFEF4444), Color(0xFFD32F2F)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFD32F2F).withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Center(
              child: Icon(
                Icons.auto_awesome_rounded,
                color: Colors.white,
                size: 24,
               ),
            ),
          ),
          // Positioned orbit dots to mimic mockup
          Positioned(
            top: 12,
            right: 20,
            child: Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: Color(0xFF8B5CF6), // Purple dot
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: 18,
            right: 14,
            child: Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: Color(0xFF3B82F6), // Blue dot
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            left: 6,
            top: 45,
            child: Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: Color(0xFFEC4899), // Pink dot
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAIAssistantBannerCard() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF3F4F6), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Info Column
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: Color(0xFFFFF0F3),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.home_work_outlined,
                        color: Color(0xFFD32F2F),
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'KOPDES AI Assistant',
                      style: TextStyle(
                        color: Color(0xFF1F2937),
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Text(
                  'Tanyakan rekomendasi produk desa terlaris, ketersediaan promo diskon, atau cek status pengiriman pesanan belanja Anda.',
                  style: TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Cute Robot mascot image
          Image.asset(
            'assets/images/onboarding/ai_coop_assistant.png',
            height: 90,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return const Icon(Icons.smart_toy_outlined, size: 64, color: Color(0xFFD32F2F));
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCategorizedSuggestions() {
    final suggestions = _getSuggestionsForMode();
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.5,
      ),
      itemCount: suggestions.length,
      itemBuilder: (context, index) {
        final sug = suggestions[index];
        return _buildPremiumSuggestionCard(sug);
      },
    );
  }

  Widget _buildPremiumSuggestionCard(Map<String, dynamic> sug) {
    final Color primaryColor = sug['color'] as Color;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF3F4F6), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.015),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _sendMessage(sug['query'] as String),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left Icon inside soft colored background
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    sug['icon'] as IconData,
                    color: primaryColor,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 10),
                // Text Column
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              sug['title'] as String,
                              style: const TextStyle(
                                color: Color(0xFF1F2937),
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          // Red chevron right icon
                          Container(
                            padding: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(
                              color: Color(0xFFFFF0F3),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.chevron_right_rounded,
                              color: Color(0xFFD32F2F),
                              size: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Expanded(
                        child: Text(
                          sug['desc'] as String,
                          style: const TextStyle(
                            color: Color(0xFF6B7280),
                            fontSize: 9.5,
                            fontWeight: FontWeight.w500,
                            height: 1.35,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPromptPills() {
    final List<Map<String, String>> pills = [
      {
        'label': 'Produk terlaris minggu ini',
        'icon': '🔥',
        'query': 'Rekomendasi produk terlaris minggu ini',
      },
      {
        'label': 'Promo diskon terbaru',
        'icon': '％',
        'query': 'Apa saja produk yang sedang promo?',
      },
      {
        'label': 'Status pesanan saya',
        'icon': '📦',
        'query': 'Cek status pesanan saya',
      },
      {
        'label': 'Rekomendasi produk sehat',
        'icon': '🌱',
        'query': 'Rekomendasi belanja sehat',
      },
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: pills.map((pill) {
        return GestureDetector(
          onTap: () => _sendMessage(pill['query']!),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFF3F4F6), width: 1.1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.01),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  pill['icon']!,
                  style: const TextStyle(fontSize: 12),
                ),
                const SizedBox(width: 6),
                Text(
                  pill['label']!,
                  style: const TextStyle(
                    color: Color(0xFF4B5563),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  List<Map<String, dynamic>> _getSuggestionsForMode() {
    if (_activeMode == 'Konsumen') {
      return [
        {
          'title': 'Terlaris Desa',
          'desc': 'Cari produk terlaris di pasar desa saat ini.',
          'icon': Icons.trending_up_rounded,
          'color': const Color(0xFFEF4444),
          'query': 'Rekomendasi produk terlaris minggu ini',
        },
        {
          'title': 'Promo Spesial',
          'desc': 'Daftar produk diskon & penawaran menarik.',
          'icon': Icons.discount_outlined,
          'color': const Color(0xFFF59E0B),
          'query': 'Apa saja produk yang sedang promo?',
        },
        {
          'title': 'Rekomendasi Belanja',
          'desc': 'Rekomendasi belanja sehat untuk keluarga.',
          'icon': Icons.verified_user_rounded,
          'color': const Color(0xFF10B981),
          'query': 'Rekomendasi belanja sehat',
        },
        {
          'title': 'Status Pesanan',
          'desc': 'Lacak posisi pengiriman barang aktif.',
          'icon': Icons.local_shipping_rounded,
          'color': const Color(0xFF3B82F6),
          'query': 'Cek status pesanan saya',
        },
      ];
    } else if (_activeMode == 'UMKM') {
      return [
        {
          'title': 'Stok Usaha Warung',
          'desc': 'Rekomendasi barang wajib ada di warung.',
          'icon': Icons.storefront_rounded,
          'color': const Color(0xFF8B5CF6),
          'query': 'Rekomendasi produk untuk usaha warung kelontong',
        },
        {
          'title': 'Analisis Pasar',
          'desc': 'Ketahui tren kebutuhan belanja warga.',
          'icon': Icons.analytics_outlined,
          'color': const Color(0xFFEC4899),
          'query': 'Analisis pasar desa minggu ini',
        },
      ];
    } else {
      return [
        {
          'title': 'Stok Kritis',
          'desc': 'Daftar barang gudang yang hampir habis.',
          'icon': Icons.warning_amber_rounded,
          'color': const Color(0xFFF59E0B),
          'query': 'Produk apa yang stoknya hampir habis?',
        },
        {
          'title': 'Laporan Ringkas',
          'desc': 'Mutasi barang masuk & keluar koperasi.',
          'icon': Icons.receipt_long_outlined,
          'color': const Color(0xFF3B82F6),
          'query': 'Minta laporan ringkas penjualan gudang',
        },
      ];
    }
  }

  Widget _buildMessageList() {
    return ListView.builder(
      controller: _scrollController,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final msg = _messages[index];
        final isUser = msg['isUser'] as bool;
        final String text = msg['text'] as String;

        return _MessageRow(text: text, isUser: isUser);
      },
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.85),
        border: const Border(
          top: BorderSide(color: Color(0xFFE5E7EB), width: 1),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Microphone button
            GestureDetector(
              onTap: _startVoiceListening,
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFE5E7EB), width: 1.0),
                ),
                child: const Icon(
                  Icons.mic_none_rounded,
                  color: Color(0xFF4B5563),
                  size: 20,
                ),
              ),
            ),
            const SizedBox(width: 10),

            // Text input field
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFFE5E7EB), width: 1.1),
                ),
                child: TextField(
                  controller: _textController,
                  style: const TextStyle(
                    color: Color(0xFF1F2937),
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: const InputDecoration(
                    hintText: 'Tulis pesan atau tanyakan sesuatu...',
                    hintStyle: TextStyle(
                      color: Color(0xFF9CA3AF),
                      fontSize: 13.5,
                      fontWeight: FontWeight.w500,
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    fillColor: Colors.transparent,
                    filled: false,
                  ),
                  onSubmitted: _sendMessage,
                ),
              ),
            ),
            const SizedBox(width: 10),

            // Send Button
            GestureDetector(
              onTap: () => _sendMessage(_textController.text),
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFD32F2F),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFD32F2F).withOpacity(0.24),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(
                    Icons.send_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── BACKGROUND AMBIENT GLOW ───

class _AnimatedAmbientGlow extends StatelessWidget {
  final Animation<double> controller;

  const _AnimatedAmbientGlow({required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final angle = controller.value * 2 * math.pi;
        final xOffset1 = 60 * math.sin(angle);
        final yOffset1 = 40 * math.cos(angle);
        final xOffset2 = 50 * math.cos(angle + math.pi / 2);
        final yOffset2 = 60 * math.sin(angle + math.pi / 2);

        return Stack(
          children: [
            // Top Right Orb (Primary Red Glow)
            Positioned(
              top: -80 + yOffset1,
              right: -80 + xOffset1,
              child: Container(
                width: 280,
                height: 280,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.primary.withOpacity(0.09),
                      AppColors.primary.withOpacity(0.0),
                    ],
                  ),
                ),
              ),
            ),

            // Bottom Left Orb (Futuristic Purple/Blue Glow)
            Positioned(
              bottom: -60 + yOffset2,
              left: -80 + xOffset2,
              child: Container(
                width: 320,
                height: 320,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF8B5CF6).withOpacity(0.07),
                      const Color(0xFF8B5CF6).withOpacity(0.0),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _TechGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF1F2937).withOpacity(0.015)
      ..strokeWidth = 0.8;

    const double step = 32.0;

    for (double i = 0; i < size.width; i += step) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    for (double i = 0; i < size.height; i += step) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─── FUTURISTIC AI CORE ORB ───

class FuturisticAICore extends StatefulWidget {
  const FuturisticAICore({super.key});

  @override
  State<FuturisticAICore> createState() => _FuturisticAICoreState();
}

class _FuturisticAICoreState extends State<FuturisticAICore> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final scaleValue = 0.94 + 0.06 * math.sin(_controller.value * 2 * math.pi * 2);

        return Stack(
          alignment: Alignment.center,
          children: [
            // Glowing outer shadow ring
            Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.08),
                    blurRadius: 24,
                    spreadRadius: 8,
                  ),
                ],
              ),
            ),

            // Rotating orbits CustomPainter
            SizedBox(
              width: 100,
              height: 100,
              child: CustomPaint(
                painter: _AICoreOrbitsPainter(angle: _controller.value * 2 * math.pi),
              ),
            ),

            // Inner Pulsing Core
            Transform.scale(
              scale: scaleValue,
              child: Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, Color(0xFFEC4899)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: Colors.white,
                  size: 26,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _AICoreOrbitsPainter extends CustomPainter {
  final double angle;

  _AICoreOrbitsPainter({required this.angle});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paintRing1 = Paint()
      ..color = AppColors.primary.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final paintRing2 = Paint()
      ..color = const Color(0xFF8B5CF6).withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // Draw static helper circles
    canvas.drawCircle(center, 40, paintRing1);
    canvas.drawCircle(center, 48, paintRing2);

    // Draw orbiting neon nodes (Ring 1)
    final nodePaint1 = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.fill;
    final nodeX1 = center.dx + 40 * math.cos(angle);
    final nodeY1 = center.dy + 40 * math.sin(angle);
    canvas.drawCircle(Offset(nodeX1, nodeY1), 3.5, nodePaint1);

    // Draw orbiting neon nodes (Ring 2 - Reverse)
    final nodePaint2 = Paint()
      ..color = const Color(0xFF8B5CF6)
      ..style = PaintingStyle.fill;
    final nodeX2 = center.dx + 48 * math.cos(-angle * 1.5);
    final nodeY2 = center.dy + 48 * math.sin(-angle * 1.5);
    canvas.drawCircle(Offset(nodeX2, nodeY2), 3.0, nodePaint2);
  }

  @override
  bool shouldRepaint(covariant _AICoreOrbitsPainter oldDelegate) {
    return oldDelegate.angle != angle;
  }
}

// ─── CATEGORIZED SUGGESTION CARD ───

class _SuggestionCard extends StatelessWidget {
  final String title;
  final String desc;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _SuggestionCard({
    required this.title,
    required this.desc,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.72),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE5E7EB), width: 1.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: color,
                size: 16,
              ),
            ),
            const SizedBox(height: 8),
            // Title
            Text(
              title,
              style: const TextStyle(
                color: Color(0xFF1F2937),
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            // Description
            Expanded(
              child: Text(
                desc,
                style: const TextStyle(
                  color: Color(0xFF9CA3AF),
                  fontSize: 9.5,
                  fontWeight: FontWeight.w500,
                  height: 1.25,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── CHAT BUBBLE ROW & LIST ITEM PARSER ───

class _MessageRow extends StatelessWidget {
  final String text;
  final bool isUser;

  const _MessageRow({required this.text, required this.isUser});

  @override
  Widget build(BuildContext context) {
    debugPrint('🤖 AI ASSISTANT [UI]: _MessageRow build. isUser: $isUser, text: "$text"');
    try {
      if (isUser) {
        return _buildUserBubble(context);
      } else {
        return _buildAIBubble(context);
      }
    } catch (e, stack) {
      debugPrint('❌ AI ASSISTANT [UI]: Error building _MessageRow: $e\n$stack');
      return Align(
        alignment: Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12, right: 30),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.red.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.red.shade200),
          ),
          child: Text(
            'Layout Error: $e',
            style: TextStyle(color: Colors.red.shade900, fontSize: 12),
          ),
        ),
      );
    }
  }

  Widget _buildUserBubble(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12, left: 40),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.primary, Color(0xFFF44336)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomLeft: Radius.circular(16),
            bottomRight: Radius.circular(2),
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.12),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w600,
            height: 1.45,
          ),
        ),
      ),
    );
  }

  Widget _buildAIBubble(BuildContext context) {
    // 1. Detect if the message contains list items that can be parsed as products
    final List<Map<String, String>> parsedProducts = _parseProducts(text);
    final String cleanText = _stripProductLines(text);
    
    final bool isError = cleanText.contains('gangguan') || 
                         cleanText.contains('terputus') || 
                         cleanText.contains('ditolak') || 
                         cleanText.contains('sibuk') ||
                         cleanText.contains('tidak ditemukan') ||
                         cleanText.contains('Layout Error');

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12, right: 30),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Shiny futuristic AI Avatar
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, Color(0xFFEC4899)],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.2),
                    blurRadius: 6,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: const Icon(
                Icons.auto_awesome,
                color: Colors.white,
                size: 14,
              ),
            ),
            const SizedBox(width: 10),

            // Message Bubble Card
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isError ? const Color(0xFFFEF2F2) : const Color(0xFFF3F4F6),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(2),
                        topRight: Radius.circular(16),
                        bottomLeft: Radius.circular(16),
                        bottomRight: Radius.circular(16),
                      ),
                      border: Border(
                        left: BorderSide(color: isError ? const Color(0xFFEF4444) : AppColors.primary, width: 3.5),
                        top: const BorderSide(color: Color(0xFFE5E7EB), width: 0.6),
                        right: const BorderSide(color: Color(0xFFE5E7EB), width: 0.6),
                        bottom: const BorderSide(color: Color(0xFFE5E7EB), width: 0.6),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.01),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      cleanText,
                      style: TextStyle(
                        color: isError ? const Color(0xFF991B1B) : const Color(0xFF1F2937),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        height: 1.5,
                      ),
                    ),
                  ),

                  // Render horizontal parsed products list
                  if (parsedProducts.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 80,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        itemCount: parsedProducts.length,
                        itemBuilder: (context, idx) {
                          final item = parsedProducts[idx];
                          return _ParsedProductCard(
                            name: item['name'] ?? '',
                            price: item['price'] ?? '',
                            tagline: item['desc'] ?? '',
                          );
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Parses bullet items: "• **Madu Hutan Alami Lestari** — Rp 85.000 (Madu hutan...)"
  List<Map<String, String>> _parseProducts(String text) {
    final List<Map<String, String>> products = [];
    final lines = text.split('\n');

    for (final line in lines) {
      if (line.trim().startsWith('•') || line.trim().startsWith('-')) {
        final RegExp regex = RegExp(r'[•-]\s*\*\*(.*?)\*\*\s*—\s*(Rp\s*\d+(?:\.\d+)*)(?:\s*\((.*?)\))?');
        final match = regex.firstMatch(line);
        if (match != null) {
          products.add({
            'name': match.group(1) ?? '',
            'price': match.group(2) ?? '',
            'desc': match.group(3) ?? 'Produk Unggulan',
          });
        }
      }
    }
    return products;
  }

  // Returns the text without the product bullet lines to avoid duplication
  String _stripProductLines(String text) {
    final lines = text.split('\n');
    final List<String> cleanLines = [];
    bool inList = false;

    for (final line in lines) {
      final trimmed = line.trim();
      final RegExp regex = RegExp(r'[•-]\s*\*\*(.*?)\*\*\s*—\s*(Rp\s*\d+(?:\.\d+)*)');
      if (regex.hasMatch(trimmed)) {
        if (!inList) {
          cleanLines.add('\nBerikut produk rekomendasi KOPDES:');
          inList = true;
        }
      } else {
        cleanLines.add(line);
      }
    }
    return cleanLines.join('\n').trim();
  }
}

// ─── RICH PARSED PRODUCT CARD WIDGET ───

class _ParsedProductCard extends StatelessWidget {
  final String name;
  final String price;
  final String tagline;

  const _ParsedProductCard({
    required this.name,
    required this.price,
    required this.tagline,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      margin: const EdgeInsets.only(right: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Image placeholder icon
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primaryTint,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.shopping_basket_rounded,
              color: AppColors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),

          // Detail texts
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: Color(0xFF1F2937),
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  tagline,
                  style: const TextStyle(
                    color: Color(0xFF9CA3AF),
                    fontSize: 8.5,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      price,
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: AppColors.primary,
                      size: 8,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── VOICE LISTENING SOUNDWAVE OVERLAY ───

class _ListeningWaveOverlay extends StatefulWidget {
  final VoidCallback onCancel;
  final String activeMode;

  const _ListeningWaveOverlay({required this.onCancel, required this.activeMode});

  @override
  State<_ListeningWaveOverlay> createState() => _ListeningWaveOverlayState();
}

class _ListeningWaveOverlayState extends State<_ListeningWaveOverlay> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withOpacity(0.85),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          const Spacer(),
          // Glowing voice orb
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.4),
                  blurRadius: 32,
                  spreadRadius: 10,
                ),
              ],
            ),
            child: const Icon(
              Icons.mic_rounded,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Mendengarkan...',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Bicarakan kebutuhan ${widget.activeMode.toLowerCase()} Anda',
            style: const TextStyle(
              color: Colors.white60,
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),

          // Wavy lines animation
          SizedBox(
            height: 120,
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                return CustomPaint(
                  painter: _VoiceWavePainter(progress: _controller.value),
                  child: Container(),
                );
              },
            ),
          ),
          const SizedBox(height: 24),

          // Cancel button
          GestureDetector(
            onTap: widget.onCancel,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white12,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white24, width: 1),
              ),
              child: const Text(
                'Batal',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(height: 48),
        ],
      ),
    );
  }
}

class _VoiceWavePainter extends CustomPainter {
  final double progress;

  _VoiceWavePainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint1 = Paint()
      ..color = AppColors.primary.withOpacity(0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final paint2 = Paint()
      ..color = const Color(0xFF8B5CF6).withOpacity(0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final path1 = Path();
    final path2 = Path();

    final midY = size.height / 2;
    path1.moveTo(0, midY);
    path2.moveTo(0, midY);

    for (double x = 0; x <= size.width; x++) {
      // Sine wave equations
      final wave1 = 25 * math.sin((x * 2.5 * math.pi / size.width) + (progress * 2 * math.pi));
      final wave2 = 18 * math.sin((x * 4 * math.pi / size.width) - (progress * 2 * math.pi));

      // Fade-out waves at boundaries
      final scale = math.sin(x * math.pi / size.width);

      path1.lineTo(x, midY + wave1 * scale);
      path2.lineTo(x, midY + wave2 * scale);
    }

    canvas.drawPath(path1, paint1);
    canvas.drawPath(path2, paint2);
  }

  @override
  bool shouldRepaint(covariant _VoiceWavePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

// ─── TYPING DOTS LOADER ───

class _TypingDots extends StatefulWidget {
  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final delay = i * 0.25;
            final val = (_controller.value - delay).clamp(0.0, 1.0);
            final scale = 1.0 + 0.5 * (1 - (val * 2 - 1).abs());

            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 2.5),
              width: 5,
              height: 5,
              transform: Matrix4.diagonal3Values(scale, scale, 1.0),
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
            );
          }),
        );
      },
    );
  }
}
