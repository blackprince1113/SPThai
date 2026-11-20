import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class LessonIconWidget extends StatelessWidget {
  final String emoji;
  final String? lottieUrl;
  final double size;
  final double? emojiSize;
  final BoxFit fit;

  const LessonIconWidget({
    super.key,
    required this.emoji,
    this.lottieUrl,
    this.size = 40.0,
    this.emojiSize,
    this.fit = BoxFit.contain,
  });

  @override
  Widget build(BuildContext context) {
    final url = lottieUrl?.trim() ?? '';
    final effectiveEmoji = emoji.trim().isNotEmpty ? emoji.trim() : '📚';
    final effectiveEmojiSize = emojiSize ?? (size * 0.6);

    if (url.isNotEmpty) {
      Widget lottieWidget;
      if (url.startsWith('assets/')) {
        lottieWidget = Lottie.asset(
          url,
          width: size,
          height: size,
          fit: fit,
          errorBuilder: (context, error, stackTrace) =>
              _buildEmoji(effectiveEmoji, effectiveEmojiSize),
        );
      } else if (url.startsWith('http://') || url.startsWith('https://')) {
        lottieWidget = Lottie.network(
          url,
          width: size,
          height: size,
          fit: fit,
          errorBuilder: (context, error, stackTrace) =>
              _buildEmoji(effectiveEmoji, effectiveEmojiSize),
          frameBuilder: (context, child, composition) {
            if (composition == null) {
              return Center(
                child: SizedBox(
                  width: size * 0.3,
                  height: size * 0.3,
                  child: const CircularProgressIndicator(strokeWidth: 2),
                ),
              );
            }
            return child;
          },
        );
      } else {
        lottieWidget = Lottie.network(
          url,
          width: size,
          height: size,
          fit: fit,
          errorBuilder: (context, error, stackTrace) =>
              _buildEmoji(effectiveEmoji, effectiveEmojiSize),
        );
      }

      return SizedBox(
        width: size,
        height: size,
        child: Center(child: lottieWidget),
      );
    }

    return _buildEmoji(effectiveEmoji, effectiveEmojiSize);
  }

  Widget _buildEmoji(String emojiText, double size) {
    return Text(
      emojiText,
      style: TextStyle(fontSize: size),
    );
  }
}
