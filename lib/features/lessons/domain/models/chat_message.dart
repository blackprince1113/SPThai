class ChatMessage {
  final String text;
  final String translation;
  final String phonetic;
  final bool isLeft;
  final String? audioUrl;

  ChatMessage({
    required this.text,
    required this.translation,
    this.phonetic = '',
    required this.isLeft,
    this.audioUrl,
  });

  Map<String, dynamic> toMap() => {
    'text': text,
    'translation': translation,
    'phonetic': phonetic,
    'isLeft': isLeft,
    'audioUrl': audioUrl,
  };

  factory ChatMessage.fromMap(Map<String, dynamic> map) => ChatMessage(
    text: map['text'] ?? '',
    translation: map['translation'] ?? '',
    phonetic: map['phonetic'] ?? '',
    isLeft: map['isLeft'] ?? true,
    audioUrl: map['audioUrl'],
  );
}
