import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class _ChatMessage {
  final String text;
  final bool isUser;

  const _ChatMessage({required this.text, required this.isUser});
}

class AiAssistantScreen extends StatefulWidget {
  const AiAssistantScreen({super.key});

  @override
  State<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends State<AiAssistantScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();

  final List<_ChatMessage> _messages = const [
    _ChatMessage(
      text: 'Здравствуйте! Я AI-ассистент ESEP.\nПомогу вам оценить недвижимость.',
      isUser: false,
    ),
    _ChatMessage(
      text: 'Хочу оценить квартиру в Алматы',
      isUser: true,
    ),
    _ChatMessage(
      text: 'Отлично! Подскажите:\n• Площадь?\n• Сколько комнат?\n• Этаж?\n• Состояние ремонта?',
      isUser: false,
    ),
    _ChatMessage(
      text: '85 м², 3 комнаты, 12 этаж',
      isUser: true,
    ),
    _ChatMessage(
      text: 'Спасибо! Загрузите документы на объект, и я подготовлю предварительную оценку.',
      isUser: false,
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // ── White header strip ──
            Container(
              padding: const EdgeInsets.fromLTRB(24, 16, 20, 14),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(
                  bottom: BorderSide(color: AppColors.border, width: 1),
                ),
              ),
              child: Row(
                children: [
                  const Text(
                    'AI АССИСТЕНТ',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: AppColors.success,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'Онлайн',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: AppColors.success,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.more_vert_rounded,
                    size: 18,
                    color: AppColors.textHint,
                  ),
                ],
              ),
            ),

            // ── Messages ──
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  return _buildMessage(_messages[index], index);
                },
              ),
            ),

            // ── White input strip ──
            Container(
              padding: const EdgeInsets.fromLTRB(20, 10, 16, 14),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(
                  top: BorderSide(color: AppColors.border, width: 1),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: AppColors.border,
                          width: 1,
                        ),
                      ),
                      child: TextField(
                        controller: _controller,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                        ),
                        decoration: const InputDecoration(
                          hintText: 'Сообщение...',
                          hintStyle: TextStyle(color: AppColors.textHint),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 14),
                        ),
                        maxLines: null,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(
                      color: AppColors.accent,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.send_rounded,
                      size: 17,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessage(_ChatMessage msg, int index) {
    final isUser = msg.isUser;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 250 + (index * 40)),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 8 * (1 - value)),
            child: child,
          ),
        );
      },
      child: Padding(
        padding: EdgeInsets.only(
          left: isUser ? 64 : 0,
          right: isUser ? 0 : 64,
          bottom: 10,
        ),
        child: Align(
          alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              color: isUser ? AppColors.accent : AppColors.paper,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(6),
                topRight: const Radius.circular(6),
                bottomLeft: Radius.circular(isUser ? 6 : 2),
                bottomRight: Radius.circular(isUser ? 2 : 6),
              ),
            ),
            child: Text(
              msg.text,
              style: TextStyle(
                fontSize: 14,
                height: 1.55,
                color: isUser ? Colors.white : AppColors.textPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
