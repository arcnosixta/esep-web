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
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(
                  bottom: BorderSide(color: AppColors.border, width: 0.5),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      gradient: AppColors.accentGradient,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Center(
                      child: Text(
                        'AI',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ESEP AI',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        'Онлайн',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.success,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.more_vert_rounded, size: 20),
                    color: AppColors.textHint,
                    onPressed: () {},
                  ),
                ],
              ),
            ),
            // Messages
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  return _buildMessage(_messages[index], index);
                },
              ),
            ),
            // Input
            _buildInput(),
          ],
        ),
      ),
    );
  }

  Widget _buildMessage(_ChatMessage msg, int index) {
    return TweenAnimationWidget<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 300 + (index * 50)),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 10 * (1 - value)),
            child: child,
          ),
        );
      },
      child: Align(
        alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: msg.isUser ? AppColors.accent : AppColors.surface,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(18),
              topRight: const Radius.circular(18),
              bottomLeft: Radius.circular(msg.isUser ? 18 : 4),
              bottomRight: Radius.circular(msg.isUser ? 4 : 18),
            ),
            boxShadow: [
              BoxShadow(
                color: (msg.isUser ? AppColors.accent : Colors.black)
                    .withValues(alpha: 0.15),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            msg.text,
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: msg.isUser
                  ? Colors.white
                  : AppColors.textPrimary.withValues(alpha: 0.9),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInput() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border, width: 0.5)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.inputFill,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.inputBorder, width: 0.5),
              ),
              child: TextField(
                controller: _controller,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                ),
                decoration: const InputDecoration(
                  hintText: 'Сообщение...',
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 13),
                ),
                maxLines: null,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              gradient: AppColors.buttonGradient,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: AppColors.accentGlow,
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: IconButton(
              icon: const Icon(Icons.send_rounded, size: 18),
              color: Colors.white,
              onPressed: () {},
            ),
          ),
        ],
      ),
    );
  }
}

class TweenAnimationWidget<T> extends StatelessWidget {
  final Tween<T> tween;
  final Duration duration;
  final Curve curve;
  final Widget Function(BuildContext, T, Widget?) builder;
  final Widget? child;

  const TweenAnimationWidget({
    super.key,
    required this.tween,
    required this.duration,
    this.curve = Curves.linear,
    required this.builder,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<T>(
      tween: tween,
      duration: duration,
      curve: curve,
      builder: builder,
      child: child,
    );
  }
}
