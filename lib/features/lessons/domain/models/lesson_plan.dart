import 'package:superthai/features/lessons/domain/models/lesson_step_data.dart';

class LessonPlan {
  final String id;
  final String title;
  final String category;
  final String categoryEmoji;
  final String emoji;
  final String? lottieUrl;
  final List<LessonStepData> steps;
  final String? creatorId;
  final DateTime? createdAt;
  final int index;

  LessonPlan({
    required this.id,
    required this.title,
    required this.category,
    this.categoryEmoji = '🎯',
    this.emoji = '📚',
    this.lottieUrl,
    required this.steps,
    this.creatorId,
    this.createdAt,
    this.index = 0,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'category': category,
    'categoryEmoji': categoryEmoji,
    'emoji': emoji,
    'lottieUrl': lottieUrl,
    'steps': steps.map((s) => s.toMap()).toList(),
    'creatorId': creatorId,
    'createdAt': createdAt?.toIso8601String(),
    'index': index,
  };

  factory LessonPlan.fromMap(Map<String, dynamic> map) {
    return LessonPlan(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      category: map['category'] ?? '',
      categoryEmoji: map['categoryEmoji'] ?? '🎯',
      emoji: map['emoji'] ?? '📚',
      lottieUrl: map['lottieUrl'] as String?,
      steps: (map['steps'] as List? ?? [])
          .map((s) => LessonStepData.fromMap(Map<String, dynamic>.from(s)))
          .toList(),
      creatorId: map['creatorId'],
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : null,
      index: map['index'] ?? 0,
    );
  }
}
