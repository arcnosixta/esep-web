import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';

import '../models/chat_message.dart';
import '../utils/chat_image.dart';
import '../services/openrouter_service.dart';
import '../services/report_service.dart';
import '../services/supabase_service.dart';
import '../theme/app_colors.dart';
import '../utils/formatters.dart';
import '../navigation/app_navigator.dart';
import '../utils/iin_validator.dart';
import '../widgets/option_button.dart';
import 'payment_screen.dart';
import 'profile_screen.dart';

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

  /// Последняя структурированная оценка от ИИ (из блока [ESTIMATE]).
  EstimateData? _lastEstimate;
  bool _creatingApplication = false;

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
    // Delay to ensure Supabase auth is ready after navigation
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
        .map((m) => {
          'role': m.role == MessageRole.user ? 'user' : 'assistant',
          'text': m.text,
          'timestamp': m.timestamp.toIso8601String(),
          'imagePaths': m.imagePaths,
        })
        .toList();

    // Auto-title from first user message
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
                      itemBuilder: (_, i) {
                        final conv = _conversations[i];
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
                  'Добавить фото (страховка / объект)',
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
                text: _stripEstimateBlock(buffer.toString()),
              );
            });
            _scrollToBottom();
          }
        },
        onDone: () {
          if (mounted) {
            final full = buffer.toString();
            // Парсим оценку ДО очистки текста от JSON-маркеров.
            final estimate = OpenRouterService.extractEstimate(full);
            setState(() {
              _messages[assistantIndex] = _messages[assistantIndex].copyWith(
                text: _stripEstimateBlock(full),
                isStreaming: false,
              );
              _isStreaming = false;
              _lastEstimate = estimate;
            });
            _scrollToBottom();
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

  /// Убирает блок [ESTIMATE]...[/ESTIMATE] из текста ответа ИИ.
  /// Закрытый блок вырезается целиком; незакрытый хвост обрезается.
  String _stripEstimateBlock(String text) {
    var cleaned = text.replaceAll(
      RegExp(r'\[ESTIMATE\][\s\S]*?\[/ESTIMATE\]', caseSensitive: false),
      '',
    );
    final start = cleaned.toLowerCase().indexOf('[estimate]');
    if (start >= 0) cleaned = cleaned.substring(0, start);
    return cleaned.trim();
  }

  /// Создаёт объект + заявку (source='ai') и открывает оплату.
  Future<void> _startPayment(EstimateData e) async {
    if (_creatingApplication) return;
    setState(() => _creatingApplication = true);
    try {
      // Идентификация клиента: ИИН/БИН обязателен (в профиле).
      final profile = await SupabaseService.getProfile();
      final idNumber = (profile?['iin'] ?? profile?['bin'] ?? '').toString();
      final idOk = idNumber.isNotEmpty && IinValidator.validate(idNumber).valid;
      if (!mounted) return;
      if (!idOk) {
        setState(() => _creatingApplication = false);
        await _showIinRequiredDialog();
        return;
      }

      final property = await SupabaseService.addProperty(
        type: _dbTypeFromEstimate(e.propertyType),
        address: e.address,
        area: e.area ?? 0,
        rooms: e.rooms,
        floor: e.floor,
        totalFloors: e.totalFloors,
        condition: e.condition,
      );
      final app = await SupabaseService.createApplication(
        propertyId: property['id'],
        source: 'ai',
        estimatedPrice: e.priceMid,
      );

      // Фото объекта (до 10) из переписки → storage + applications.photo_urls.
      // Оценщик сможет удалять/добавлять фото при редактировании отчёта.
      try {
        final photos = _collectConversationPhotos();
        if (photos.isNotEmpty) {
          final paths = <String>[];
          for (var i = 0; i < photos.length && i < 10; i++) {
            try {
              final path = await SupabaseService.uploadReportPhoto(
                bytes: photos[i],
                applicationId: app['id'].toString(),
                index: i,
              );
              paths.add(path);
            } catch (photoErr) {
              debugPrint('[AI] photo upload error: $photoErr');
            }
          }
          if (paths.isNotEmpty) {
            await SupabaseService.updateApplicationPhotos(app['id'].toString(), paths);
          }
        }
      } catch (photoErr) {
        debugPrint('[AI] photos processing error: $photoErr');
      }

      // Создаём черновик отчёта (draft) сразу при создании заявки —
      // в нём будут храниться данные и PDF, статус обновится после оплаты/подписи.
      try {
        final reportRow = await SupabaseService.createReport(
          applicationId: app['id'],
          reportNumber: await ReportService.nextReportNumber(),
        );
        debugPrint('[AI] report draft created: ${reportRow['id']}');
      } catch (reportErr) {
        debugPrint('[AI] createReport error: $reportErr');
      }

      // Генерируем ПРЕДВАРИТЕЛЬНЫЙ PDF (с водяным знаком) и загружаем —
      // клиент видит предпросмотр, официальный появится после оплаты.
      try {
        final reportData = await ReportService.generateReportData(
          propertyType: e.propertyType,
          address: e.address,
          area: e.area ?? 0,
          rooms: e.rooms ?? 0,
          floor: e.floor ?? 0,
          totalFloors: e.totalFloors ?? 0,
          condition: e.condition,
          yearBuilt: e.yearBuilt ?? 0,
          clientName: (profile?['full_name'] ?? '').toString(),
          clientIin: idNumber,
          clientIsOrg: (profile?['client_type'] ?? 'person') == 'org',
        );
        if (reportData != null) {
          final filled = ReportService.fillCompanyData(reportData);
          final pdfBytes = await ReportService.generatePdf(filled, preview: true);
          final url = await ReportService.uploadReportPdf(pdfBytes, app['id']);
          debugPrint('[AI] preview PDF uploaded: $url');
        }
      } catch (pdfErr) {
        debugPrint('[AI] preview PDF error: $pdfErr');
      }

      if (!mounted) return;
      setState(() => _creatingApplication = false);
      AppNavigator.push(
        context,
        PaymentScreen(applicationId: app['id']),
      );
    } catch (err) {
      if (!mounted) return;
      setState(() => _creatingApplication = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Не удалось создать заявку: $err')),
      );
    }
  }

  /// Собрать байты всех фото из пользовательских сообщений сессии (до 10).
  List<Uint8List> _collectConversationPhotos() {
    final out = <Uint8List>[];
    for (final m in _messages) {
      if (m.role != MessageRole.user) continue;
      for (final b64 in m.imageBase64) {
        if (out.length >= 10) return out;
        try {
          out.add(base64Decode(b64));
        } catch (_) {}
      }
    }
    return out;
  }

  /// Диалог: для заказа нужен ИИН/БИН в профиле.
  Future<void> _showIinRequiredDialog() async {
    final c = AppColors.of(context);
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Нужен ИИН/БИН'),
        content: Text(
          'Для заказа оценки вы должны быть идентифицированы. '
          'Укажите ИИН (физлицо) или БИН и наименование (юрлицо) в профиле — '
          'это займёт минуту.',
          style: TextStyle(color: c.textSecondary, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Позже', style: TextStyle(color: c.textSecondary)),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              AppNavigator.push(ctx, const ProfileScreen());
            },
            child: const Text('Заполнить профиль'),
          ),
        ],
      ),
    );
  }

  String _dbTypeFromEstimate(String t) {
    return switch (t.toLowerCase()) {
      'дом' => 'house',
      'земля' || 'участок' => 'land',
      'коммерческая' || 'коммерция' => 'commercial',
      _ => 'apartment',
    };
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar(
        backgroundColor: c.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 20,
            color: c.textPrimary,
          ),
        ),
        leadingWidth: 40,
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [c.accent, c.accentLight],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Center(
                child: Text(
                  'AI',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI-ассистент',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: c.textPrimary,
                  ),
                ),
                Text(
                  _conversationId != null ? 'Сохранён' : 'Новый чат',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                    color: _conversationId != null ? c.success : c.textHint,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _newChat,
            icon: Icon(Icons.add_comment_outlined, color: c.textSecondary, size: 22),
            tooltip: 'Новый чат',
          ),
          IconButton(
            onPressed: _showHistorySheet,
            icon: Icon(Icons.history_rounded, color: c.textSecondary, size: 22),
            tooltip: 'История',
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: c.border),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _loadingHistory
                ? Center(child: CircularProgressIndicator(color: c.accent))
                : _messages.isEmpty
                    ? _buildEmptyState()
                    : _buildMessageList(),
          ),
          if (_pendingImagePaths.isNotEmpty) _buildImagePreview(),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final c = AppColors.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [c.accent, c.accentLight],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: c.accent.withValues(alpha: 0.2),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Center(
                child: Text(
                  'AI',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 2,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Оценка недвижимости',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: c.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Два способа получить оценку:\n📸 Отправьте фото или ✍️ опишите текстом',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: c.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),

            // ── Mode 1: Photos ──
            _buildSectionHeader('📸 С фото', c),
            const SizedBox(height: 8),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: c.accent.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: c.accent.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.description_rounded, color: c.accent, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'Страховка',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: c.accent,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: c.gold.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: c.gold.withValues(alpha: 0.25)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.home_rounded, color: c.gold, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'Фото объекта',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: c.gold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // ── Mode 2: Text templates ──
            _buildSectionHeader('✍️ Без документов — текстом', c),
            const SizedBox(height: 8),
            Column(
              children: _textTemplates.map((t) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: GestureDetector(
                    onTap: () => _sendMessage(t),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: c.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: c.border),
                      ),
                      child: Text(
                        t,
                        style: TextStyle(
                          fontSize: 13,
                          color: c.textSecondary,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 24),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _quickQuestions.map((q) {
                return GestureDetector(
                  onTap: () => _sendMessage(q),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: c.accent.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: c.accent.withValues(alpha: 0.2)),
                    ),
                    child: Text(
                      q,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: c.accent,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, AppColors c) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: c.textHint,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  Widget _buildMessageList() {
    final showEstimate = _lastEstimate != null && !_isStreaming;
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      itemCount: _messages.length + (showEstimate ? 1 : 0),
      itemBuilder: (context, index) {
        if (showEstimate && index >= _messages.length) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _buildEstimateCard(_lastEstimate!),
          );
        }
        final msg = _messages[index];
        final isUser = msg.role == MessageRole.user;

        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment:
                isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: [
              if (!isUser) _buildAvatar(),
              if (!isUser) const SizedBox(width: 10),
              Flexible(
                child: isUser
                    ? _buildUserBubble(msg)
                    : _buildAssistantBubble(msg),
              ),
              if (isUser) const SizedBox(width: 10),
              if (isUser) _buildUserAvatar(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEstimateCard(EstimateData e) {
    final c = AppColors.of(context);
    final low = e.priceLow ?? e.priceMid ?? 0;
    final high = e.priceHigh ?? e.priceMid ?? 0;
    final areaText = e.area != null ? '${e.area!.round()} м²' : '';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.accent.withValues(alpha: 0.35), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.calculate_rounded, size: 20, color: c.accent),
              const SizedBox(width: 8),
              Text(
                'ПРЕДВАРИТЕЛЬНАЯ ОЦЕНКА',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.0,
                  color: c.accent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (e.address.isNotEmpty)
            Text(
              e.address,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: c.textPrimary,
              ),
            ),
          if (e.address.isNotEmpty || areaText.isNotEmpty)
            const SizedBox(height: 4),
          if (areaText.isNotEmpty)
            Text(
              '$areaText · ${e.condition.isEmpty ? 'состояние не указано' : e.condition}',
              style: TextStyle(fontSize: 13, color: c.textSecondary),
            ),
          const SizedBox(height: 14),
          Text(
            low == high ? formatTenge(low) : '${formatTenge(low)} — ${formatTenge(high)}',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: c.textPrimary,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 14),
          // Дисклеймер: оценка предварительная, официальный отчёт — после оплаты.
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: c.gold.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline_rounded, size: 15, color: c.gold),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Это предварительная оценка, не официальный документ. '
                    'Официальный подписанный отчёт — после оплаты заявки.',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: c.textSecondary,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          OptionButton(
            text: _creatingApplication
                ? 'Создание заявки…'
                : '💳 Оплатить официальный отчёт',
            icon: Icons.payments_rounded,
            onTap: _creatingApplication ? null : () => _startPayment(e),
          ),
          const SizedBox(height: 8),
          Text(
            'После оплаты заявка уйдёт оценщику — он подготовит и подпишет официальный отчёт.',
            style: TextStyle(fontSize: 12, color: c.textSecondary, height: 1.35),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    final c = AppColors.of(context);
    return Container(
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
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: c.gold,
        borderRadius: BorderRadius.circular(9),
      ),
      child: const Center(
        child: Icon(Icons.person_rounded, color: Colors.white, size: 18),
      ),
    );
  }

  Widget _buildUserBubble(ChatMessage msg) {
    final c = AppColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (msg.imagePaths.isNotEmpty || msg.imageBase64.isNotEmpty)
          _buildImageGrid(msg),
        if (msg.text.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: c.accent,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              msg.text,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w400,
                color: Colors.white,
                height: 1.4,
              ),
            ),
          )
              .animate()
              .fadeIn(duration: 250.ms)
              .slideY(begin: 0.1, curve: Curves.easeOutCubic),
      ],
    );
  }

  Widget _buildAssistantBubble(ChatMessage msg) {
    final c = AppColors.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.border),
      ),
      child: msg.text.isEmpty && msg.isStreaming
          ? _buildTypingIndicator()
          : Text.rich(
              _parseFormatting(msg.text),
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w400,
                color: c.textPrimary,
                height: 1.5,
              ),
            ),
    )
        .animate()
        .fadeIn(duration: 250.ms)
        .slideY(begin: 0.1, curve: Curves.easeOutCubic);
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
            borderRadius: BorderRadius.circular(12),
            child: chatImage(
              path: path,
              base64: base64,
              width: 120,
              height: 120,
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
    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _pendingImagePaths.length > _pendingImageBase64.length
            ? _pendingImagePaths.length
            : _pendingImageBase64.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          return Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: chatImage(
                  path: _pendingImagePaths[index],
                  base64: _pendingImageBase64[index],
                  width: 64,
                  height: 64,
                  fit: BoxFit.cover,
                ),
              ),
              Positioned(
                top: 2,
                right: 2,
                child: GestureDetector(
                  onTap: () => _removePendingImage(index),
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: c.error,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      size: 12,
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
            onTap: _showImageSourceSheet,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: c.inputFill,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: c.inputBorder),
              ),
              child: Icon(
                Icons.photo_camera_rounded,
                color: c.textSecondary,
                size: 21,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              constraints: const BoxConstraints(minHeight: 44),
              decoration: BoxDecoration(
                color: c.inputFill,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: c.inputBorder),
              ),
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                maxLines: 4,
                minLines: 1,
                textInputAction: TextInputAction.newline,
                style: TextStyle(
                  fontSize: 15,
                  color: c.textPrimary,
                ),
                decoration: InputDecoration(
                  hintText: 'Адрес, тип объекта или вопрос...',
                  hintStyle: TextStyle(color: c.textHint),
                  border: InputBorder.none,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                onSubmitted: _sendMessage,
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _isStreaming
                ? null
                : () => _sendMessage(_controller.text),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _isStreaming ||
                        (_controller.text.trim().isEmpty &&
                            _pendingImageBase64.isEmpty)
                    ? c.muted
                    : c.accent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: _isStreaming
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(
                        Icons.arrow_upward_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
              ),
            ),
          ),
        ],
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
