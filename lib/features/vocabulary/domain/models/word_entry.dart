import 'package:superthai/features/lessons/domain/models/example_sentence.dart';

class WordEntry {
  final String id;
  final String thai;
  final String phonetic;
  final String english;
  final String category;
  final String imageUrl;
  final List<ExampleSentence> examples;
  final bool isCustom;
  final String? creatorId;

  WordEntry({
    required this.id,
    required this.thai,
    required this.phonetic,
    required this.english,
    required this.category,
    this.imageUrl = '',
    this.examples = const [],
    this.isCustom = false,
    this.creatorId,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'thai': thai,
    'phonetic': phonetic,
    'english': english,
    'category': category,
    'imageUrl': imageUrl,
    'examples': examples.map((e) => e.toMap()).toList(),
    'isCustom': isCustom,
    'creatorId': creatorId,
  };

  factory WordEntry.fromMap(Map<String, dynamic> map) {
    return WordEntry(
      id: map['id'] ?? map['wordId'] ?? '',
      thai: map['thai'] ?? '',
      phonetic: map['phonetic'] ?? '',
      english: map['english'] ?? '',
      category: map['category'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      examples: (map['examples'] as List? ?? [])
          .map((e) => ExampleSentence.fromMap(Map<String, dynamic>.from(e)))
          .toList(),
      isCustom: map['isCustom'] ?? false,
      creatorId: map['creatorId'],
    );
  }

  String get stableId {
    if (id.isNotEmpty && id != 'temp') return id;
    return '${thai}_$english'.hashCode.abs().toString();
  }
}
