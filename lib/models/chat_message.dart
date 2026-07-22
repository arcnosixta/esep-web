enum MessageRole { user, assistant, system }

class ChatMessage {
  final String text;
  final MessageRole role;
  final DateTime timestamp;
  final bool isStreaming;
  final List<String> imagePaths;
  final List<String> imageBase64;

  const ChatMessage({
    required this.text,
    required this.role,
    required this.timestamp,
    this.isStreaming = false,
    this.imagePaths = const [],
    this.imageBase64 = const [],
  });

  ChatMessage copyWith({
    String? text,
    bool? isStreaming,
    List<String>? imagePaths,
    List<String>? imageBase64,
  }) {
    return ChatMessage(
      text: text ?? this.text,
      role: role,
      timestamp: timestamp,
      isStreaming: isStreaming ?? this.isStreaming,
      imagePaths: imagePaths ?? this.imagePaths,
      imageBase64: imageBase64 ?? this.imageBase64,
    );
  }

  bool get hasImages => imageBase64.isNotEmpty;

  Map<String, dynamic> toApiFormat() {
    if (!hasImages) {
      return {
        'role': role == MessageRole.user ? 'user' : 'assistant',
        'content': text,
      };
    }

    final content = <Map<String, dynamic>>[];

    if (text.isNotEmpty) {
      content.add({'type': 'text', 'text': text});
    }

    for (final b64 in imageBase64) {
      content.add({
        'type': 'image_url',
        'image_url': {'url': 'data:image/jpeg;base64,$b64'},
      });
    }

    return {
      'role': role == MessageRole.user ? 'user' : 'assistant',
      'content': content,
    };
  }
}
