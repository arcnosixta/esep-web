import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/chat_message.dart';
import '../utils/chat_image.dart';
import '../services/openrouter_service.dart';
import '../services/supabase_service.dart';
import '../theme/app_colors.dart';

class AiChatScreen extends StatefulWidget {
  const AiChatScreen({super.key});

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final _focusNode = FocusNode();
  final _picker = ImagePicker();

  final List<ChatMessage> _messages = [];
  bool _isStreaming = false;
  StreamSubscription<String>? _streamSubscription;

  final List<String> _pendingImagePaths = [];
  final List<String> _pendingImageBase64 = [];

  String? _conversationId;
  List<Map<String, dynamic>> _conversations = [];
  bool _loadingHistory = false;

  static const _quickQuestions = [
    'Начать оценку',
    'Нет документов',
    'Как это работает?',
  ];

  static const _textTemplates = [
    'Квартира, Абая 150, 3-комн, 85 м², 5/9, косметический ремонт',
    'Дом, ул. Достык 25, 120 м², 2 этаж, чистовая отделка',
    'Участок, с. Калкаман, 10 соток, ИЖС',
  ];

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) _loadConversations();
    });
  }

  @override
  void dispose() {
    _streamSubscription?.cancel();
    _controller.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _loadConversations() async {
    try {
      debugPrint('[AI] Loading conversations, userId: ${SupabaseService.userId}');
      final list = await SupabaseService.getConversations();
      debugPrint('[AI] Loaded ${list.length} conversations');
      if (mounted) setState(() => _conversations = list);
    } catch (e) {
      debugPrint('[AI] Load conversations error: $e');
    }
  }

  Future<void> _loadConversation(String id) async {
    setState(() => _loadingHistory = true);
    try {
      final result = await SupabaseService.getConversation(id);
      if (result.isEmpty || !mounted) return;
      final data = result.first;
      final rawMessages = data['messages'] as List<dynamic>;
      setState(() {
        _conversationId = id;
        _messages.clear();
        for (final m in rawMessages) {
          _messages.add(ChatMessage(
            text: m['text'] ?? '',
            role: m['role'] == 'user' ? MessageRole.user : MessageRole.assistant,
            timestamp: DateTime.tryParse(m['timestamp'] ?? '') ?? DateTime.now(),
            imagePaths: List<String>.from(m['imagePaths'] ?? []),
          ));
        }
        _loadingHistory = false;
      });
      _scrollToBottom();
    } catch (e) {
      if (mounted) setState(() => _loadingHistory = false);
    }
  }

  Future<void> _saveConversation() async {
    if (_messages.isEmpty) return;
    final apiMessages = _messages
        .where((m) => !m.isStreaming)
        .map((m) {
          return {
            'role': m.role == MessageRole.user ? 'user' : 'assistant',
            'text': m.text,
            'timestamp': m.timestamp.toIso8601String(),
            'imagePaths': m.imagePaths,
          };
        })
        .toList();

    final firstUserMsg = _messages
        .where((m) => m.role == MessageRole.user && m.text.isNotEmpty)
        .map((m) => m.text)
        .firstOrNull;
    final title = (firstUserMsg?.length ?? 0) > 40
        ? '${firstUserMsg!.substring(0, 40)}...'
        : (firstUserMsg ?? 'Новый чат');

    try {
      if (_conversationId != null) {
        debugPrint('[AI] Updating conversation: $_conversationId');
        await SupabaseService.updateConversation(
          id: _conversationId!,
          title: title,
          messages: apiMessages,
        );
      } else {
        debugPrint('[AI] Creating new conversation');
        _conversationId = await SupabaseService.createConversation(
          title: title,
          messages: apiMessages,
        );
        debugPrint('[AI] Created conversation: $_conversationId');
      }
      await _loadConversations();
    } catch (e) {
      debugPrint('[AI] Save conversation error: $e');
    }
  }

  void _newChat() {
    setState(() {
      _conversationId = null;
      _messages.clear();
      _pendingImagePaths.clear();
      _pendingImageBase64.clear();
    });
  }

  void _showHistorySheet() {
    final c = AppColors.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: c.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: c.muted,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'История чатов',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: c.textPrimary,
                      ),
                    ),
                    Text(
                      '${_conversations.length}',
                      style: TextStyle(
                        fontSize: 13,
                        color: c.textHint,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (_conversations.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Text(
                      'Пока нет сохранённых чатов',
                      style: TextStyle(fontSize: 14, color: c.textHint),
                    ),
                  )
                else
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: _conversations.length,
                      separatorBuilder: (_, _) => Divider(height: 1, color: c.border),
                      itemBuilder: (context, index) {
                        final conv = _conversations[index];
                        final isActive = conv['id'] == _conversationId;
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(
                            Icons.chat_bubble_outline_rounded,
                            color: isActive ? c.accent : c.textHint,
                            size: 20,
                          ),
                          title: Text(
                            conv['title'] ?? 'Чат',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                              color: isActive ? c.accent : c.textPrimary,
                            ),
                          ),
                          subtitle: Text(
                            _formatConvDate(conv['updated_at']),
                            style: TextStyle(fontSize: 11, color: c.textHint),
                          ),
                          trailing: IconButton(
                            icon: Icon(Icons.delete_outline_rounded, size: 18, color: c.error),
                            onPressed: () async {
                              await SupabaseService.deleteConversation(conv['id']);
                              if (isActive) _newChat();
                              await _loadConversations();
                              if (ctx.mounted) Navigator.pop(ctx);
                            },
                          ),
                          onTap: () {
                            Navigator.pop(ctx);
                            _loadConversation(conv['id']);
                          },
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatConvDate(dynamic iso) {
    if (iso == null) return '';
    final dt = DateTime.tryParse(iso.toString());
    if (dt == null) return '';
    final now = DateTime.now();
    if (dt.day == now.day && dt.month == now.month && dt.year == now.year) {
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    }
    return '${dt.day}.${dt.month}.${dt.year}';
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

  Future<void> _pickImage(ImageSource source) async {
    final picked = await _picker.pickImage(
      source: source,
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 85,
    );
    if (picked == null) return;

    final bytes = await picked.readAsBytes();
    final b64 = base64Encode(bytes);

    setState(() {
      if (!kIsWeb && picked.path.isNotEmpty) {
        _pendingImagePaths.add(picked.path);
      }
      _pendingImageBase64.add(b64);
    });
  }

  void _removePendingImage(int index) {
    setState(() {
      _pendingImagePaths.removeAt(index);
      _pendingImageBase64.removeAt(index);
    });
  }

  void _showImageSourceSheet() {
    final canUseCamera = !kIsWeb && defaultTargetPlatform != TargetPlatform.linux;
    final c = AppColors.of(context);

    showModalBottomSheet(
      context: context,
      backgroundColor: c.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: c.muted,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Добавить фото',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: c.textPrimary,
                  ),
                ),
                const SizedBox(height: 20),
                if (canUseCamera)
                  _imageSourceOption(
                    Icons.camera_alt_rounded,
                    'Камера',
                    () {
                      Navigator.pop(ctx);
                      _pickImage(ImageSource.camera);
                    },
                  ),
                if (canUseCamera) const SizedBox(height: 8),
                _imageSourceOption(
                  Icons.photo_library_rounded,
                  'Галерея',
                  () {
                    Navigator.pop(ctx);
                    _pickImage(ImageSource.gallery);
                  },
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _imageSourceOption(IconData icon, String label, VoidCallback onTap) {
    final c = AppColors.of(context);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: c.inputFill,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: c.accent, size: 22),
            const SizedBox(width: 14),
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: c.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendMessage(String text) async {
    final hasText = text.trim().isNotEmpty;
    final hasImages = _pendingImageBase64.isNotEmpty;
    if ((!hasText && !hasImages) || _isStreaming) return;

    final userMessage = ChatMessage(
      text: text.trim(),
      role: MessageRole.user,
      timestamp: DateTime.now(),
      imagePaths: List.from(_pendingImagePaths),
      imageBase64: List.from(_pendingImageBase64),
    );

    setState(() {
      _messages.add(userMessage);
      _controller.clear();
      _pendingImagePaths.clear();
      _pendingImageBase64.clear();
      _isStreaming = true;
      _messages.add(
        ChatMessage(
          text: '',
          role: MessageRole.assistant,
          timestamp: DateTime.now(),
          isStreaming: true,
        ),
      );
    });
    _scrollToBottom();

    final assistantIndex = _messages.length - 1;
    final buffer = StringBuffer();

    try {
      _streamSubscription = OpenRouterService.streamCompletion(
        messages: _messages.sublist(0, _messages.length - 1),
      ).listen(
        (chunk) {
          buffer.write(chunk);
          if (mounted) {
            setState(() {
              _messages[assistantIndex] = _messages[assistantIndex].copyWith(
                text: buffer.toString(),
              );
            });
            _scrollToBottom();
          }
        },
        onDone: () {
          if (mounted) {
            setState(() {
              _messages[assistantIndex] = _messages[assistantIndex].copyWith(
                isStreaming: false,
              );
              _isStreaming = false;
            });
            _saveConversation();
          }
        },
        onError: (e) {
          if (mounted) {
            final msg = e.toString();
            final isNetwork = msg.contains('SocketException') ||
                msg.contains('Connection') ||
                msg.contains('timeout');
            setState(() {
              _messages[assistantIndex] = ChatMessage(
                text: isNetwork
                    ? 'Нет подключения к интернету. Проверьте сеть и попробуйте ещё раз.'
                    : 'Ошибка: ${msg.length > 200 ? '${msg.substring(0, 200)}...' : msg}',
                role: MessageRole.assistant,
                timestamp: DateTime.now(),
              );
              _isStreaming = false;
            });
          }
        },
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages[assistantIndex] = ChatMessage(
            text: 'Не удалось отправить запрос: ${e.toString()}',
            role: MessageRole.assistant,
            timestamp: DateTime.now(),
          );
          _isStreaming = false;
        });
      }
    }
  }

  bool get _canSend => !_isStreaming && (_controller.text.trim().isNotEmpty || _pendingImageBase64.isNotEmpty);

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);

    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar(
        backgroundColor: c.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leadingWidth: 88,
        leading: Row(
          children: [
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: Icon(Icons.arrow_back_rounded, color: c.textPrimary, size: 22),
              tooltip: 'Назад',
            ),
            IconButton(
              onPressed: () => Scaffold.of(context).openDrawer(),
              icon: Icon(Icons.menu_rounded, color: c.textPrimary, size: 22),
              tooltip: 'Меню',
            ),
          ],
        ),
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [c.accent, c.accentLight],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(9),
              ),
              child: const Center(
                child: Text(
                  'AI',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'AI-ассистент ESEP',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: c.textPrimary,
                    ),
                  ),
                  Text(
                    _conversationId != null ? 'Сохранён' : 'Новый чат',
                    style: TextStyle(
                      fontSize: 11,
                      color: _conversationId != null ? c.success : c.textHint,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: c.border),
        ),
      ),
      drawer: Drawer(
        backgroundColor: c.surface,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Меню',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: c.textPrimary,
                  ),
                ),
                const SizedBox(height: 20),
                _MenuTile(
                  icon: Icons.add_comment_outlined,
                  label: 'Новый чат',
                  onTap: () {
                    Navigator.pop(context);
                    _newChat();
                  },
                ),
                const SizedBox(height: 8),
                _MenuTile(
                  icon: Icons.history_rounded,
                  label: 'История',
                  onTap: () {
                    Navigator.pop(context);
                    _showHistorySheet();
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _loadingHistory
                ? Center(child: CircularProgressIndicator(color: c.accent))
                : _messages.isEmpty
                    ? _buildCompactEmptyState(c)
                    : _buildMessageList(),
          ),
          if (_pendingImagePaths.isNotEmpty || _pendingImageBase64.isNotEmpty)
            _buildImagePreview(),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildCompactEmptyState(AppColors c) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
      children: [
        Text(
          'Как хотите начать?',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: c.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Пришлите фото или опишите объект текстом.',
          style: TextStyle(fontSize: 14, color: c.textSecondary, height: 1.4),
        ),
        const SizedBox(height: 18),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _quickQuestions.map((q) {
            return _ChipButton(
              label: q,
              onTap: () => _sendMessage(q),
            );
          }).toList(),
        ),
        const SizedBox(height: 18),
        ..._textTemplates.map((t) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _TemplateTile(text: t, onTap: () => _sendMessage(t)),
            )),
      ],
    );
  }

  Widget _buildMessageList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final msg = _messages[index];
        final isUser = msg.role == MessageRole.user;

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment:
                isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: [
              if (!isUser) ...[
                _buildAvatar(),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: isUser
                    ? _buildUserBubble(msg)
                    : _buildAssistantBubble(msg),
              ),
              if (isUser) ...[
                const SizedBox(width: 8),
                _buildUserAvatar(),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildAvatar() {
    final c = AppColors.of(context);
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [c.accent, c.accentLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(9),
      ),
      child: const Center(
        child: Text(
          'AI',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  Widget _buildUserAvatar() {
    final c = AppColors.of(context);
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: c.gold,
        borderRadius: BorderRadius.circular(9),
      ),
      child: const Center(
        child: Icon(Icons.person_rounded, color: Colors.white, size: 16),
      ),
    );
  }

  Widget _buildUserBubble(ChatMessage msg) {
    final c = AppColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (msg.imagePaths.isNotEmpty || msg.imageBase64.isNotEmpty) _buildImageGrid(msg),
        if (msg.text.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: c.accent,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              msg.text,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: Colors.white,
                height: 1.35,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildAssistantBubble(ChatMessage msg) {
    final c = AppColors.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.border),
      ),
      child: msg.text.isEmpty && msg.isStreaming
          ? _buildTypingIndicator()
          : Text.rich(
              _parseFormatting(msg.text),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: c.textPrimary,
                height: 1.45,
              ),
            ),
    );
  }

  Widget _buildImageGrid(ChatMessage msg) {
    final count = msg.imagePaths.length > msg.imageBase64.length
        ? msg.imagePaths.length
        : msg.imageBase64.length;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: List.generate(count, (i) {
          final path = i < msg.imagePaths.length ? msg.imagePaths[i] : '';
          final base64 = i < msg.imageBase64.length ? msg.imageBase64[i] : '';
          return ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: chatImage(
              path: path,
              base64: base64,
              width: 110,
              height: 110,
              fit: BoxFit.cover,
            ),
          );
        }),
      ),
    );
  }

  TextSpan _parseFormatting(String text) {
    final c = AppColors.of(context);
    final spans = <TextSpan>[];
    final lines = text.split('\n');

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];

      if (line.startsWith('• ') || line.startsWith('- ')) {
        spans.add(TextSpan(children: [
          TextSpan(text: '  ', style: TextStyle(color: c.accent)),
          TextSpan(text: line),
        ]));
      } else if (line.startsWith('**') && line.endsWith('**')) {
        spans.add(TextSpan(
          text: line.replaceAll('**', ''),
          style: const TextStyle(fontWeight: FontWeight.w700),
        ));
      } else {
        spans.add(TextSpan(text: line));
      }

      if (i < lines.length - 1) {
        spans.add(const TextSpan(text: '\n'));
      }
    }

    return TextSpan(children: spans);
  }

  Widget _buildTypingIndicator() {
    return const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _Dot(delay: 0),
        SizedBox(width: 4),
        _Dot(delay: 150),
        SizedBox(width: 4),
        _Dot(delay: 300),
      ],
    );
  }

  Widget _buildImagePreview() {
    final c = AppColors.of(context);
    final count = _pendingImagePaths.length > _pendingImageBase64.length
        ? _pendingImagePaths.length
        : _pendingImageBase64.length;
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: count,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          return Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: chatImage(
                  path: _pendingImagePaths[index],
                  base64: _pendingImageBase64[index],
                  width: 56,
                  height: 56,
                  fit: BoxFit.cover,
                ),
              ),
              Positioned(
                top: 2,
                right: 2,
                child: GestureDetector(
                  onTap: () => _removePendingImage(index),
                  child: Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      color: c.error,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      size: 11,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildInputArea() {
    final c = AppColors.of(context);
    final canSend = _canSend;
    return Container(
      padding: EdgeInsets.only(
        left: 12,
        right: 12,
        top: 10,
        bottom: MediaQuery.of(context).padding.bottom + 10,
      ),
      decoration: BoxDecoration(
        color: c.surface,
        border: Border(top: BorderSide(color: c.border, width: 1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _showImageSourceSheet,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: c.inputFill,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: c.inputBorder),
              ),
              child: Icon(
                Icons.photo_camera_rounded,
                color: c.textSecondary,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              constraints: const BoxConstraints(minHeight: 40),
              decoration: BoxDecoration(
                color: c.inputFill,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: c.inputBorder),
              ),
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                maxLines: 4,
                minLines: 1,
                textInputAction: TextInputAction.newline,
                style: TextStyle(
                  fontSize: 14,
                  color: c.textPrimary,
                ),
                decoration: InputDecoration(
                  hintText: 'Сообщение...',
                  hintStyle: TextStyle(color: c.textHint, fontSize: 14),
                  border: InputBorder.none,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                ),
                onChanged: (_) {
                  if (mounted) setState(() {});
                },
                onSubmitted: (_) => canSend ? _sendMessage(_controller.text) : null,
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: canSend ? () => _sendMessage(_controller.text) : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: canSend ? c.gold : c.muted,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: _isStreaming
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(
                        Icons.arrow_upward_rounded,
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

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _MenuTile({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: c.inputFill,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: c.accent, size: 20),
            const SizedBox(width: 14),
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: c.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChipButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _ChipButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: c.accent.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: c.accent.withValues(alpha: 0.2)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: c.accent,
          ),
        ),
      ),
    );
  }
}

class _TemplateTile extends StatelessWidget {
  final String text;
  final VoidCallback onTap;

  const _TemplateTile({required this.text, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: c.border),
        ),
        child: Text(
          text,
          style: TextStyle(fontSize: 13, color: c.textSecondary, height: 1.4),
        ),
      ),
    );
  }
}

class _Dot extends StatefulWidget {
  final int delay;
  const _Dot({required this.delay});

  @override
  State<_Dot> createState() => _DotState();
}

class _DotState extends State<_Dot> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _anim = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _controller.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return AnimatedBuilder(
      animation: _anim,
      builder: (context, _) {
        return Opacity(
          opacity: _anim.value,
          child: Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: c.accent,
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }
}
