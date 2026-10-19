import 'package:uuid/uuid.dart';
import 'package:superthai/core/enums/question_type.dart';
import 'package:superthai/features/lessons/domain/models/chat_message.dart';
import 'package:superthai/features/lessons/domain/models/example_sentence.dart';
import 'package:superthai/features/vocabulary/domain/models/word_entry.dart';

class LessonStepData {
  final String id;
  String type;
  String thai;
  String phonetic;
  String english;
  String question;
  String answer;
  String imageUrl;
  List<String> choices;
  List<ChatMessage>? conversation;
  bool wasConverted = false;
  final bool needsIdMigration;

  LessonStepData({
    String? id,
    required this.type,
    this.thai = '',
    this.phonetic = '',
    this.english = '',
    this.question = '',
    this.answer = '',
    this.imageUrl = '',
    List<String>? choices,
    this.conversation,
    this.wasConverted = false,
    this.needsIdMigration = false,
  }) : id = (id == null || id.isEmpty) ? const Uuid().v4() : id,
       choices = choices ?? [];

  QuestionType get questionType => QuestionType.fromString(type);
  set questionType(QuestionType qType) => type = qType.typeKey;

  Map<String, dynamic> toMap() => {
    'id': id,
    'type': type,
    'thai': thai,
    'phonetic': phonetic,
    'english': english,
    'question': question,
    'answer': answer,
    'imageUrl': imageUrl,
    'choices': choices,
    'conversation': conversation?.map((c) => c.toMap()).toList(),
  };

  factory LessonStepData.fromMap(Map<String, dynamic> map) {
    final rawType = (map['type'] ?? 'flashcard').toString();
    final type = QuestionType.normalizeStoredKey(rawType);
    final legacyType = rawType.trim().toLowerCase();
    final migrated =
        legacyType == 'fill blank' ||
        legacyType == 'fillblank' ||
        legacyType == 'english meaning' ||
        legacyType == 'englishmeaning';

    return LessonStepData(
      id: map['id']?.toString(),
      type: type,
      thai: map['thai'] ?? '',
      phonetic: map['phonetic'] ?? '',
      english: map['english'] ?? '',
      question: map['question'] ?? '',
      answer: map['answer'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      choices: List<String>.from(map['choices'] ?? []),
      conversation: (map['conversation'] as List?)
          ?.map((c) => ChatMessage.fromMap(Map<String, dynamic>.from(c)))
          .toList(),
      wasConverted: migrated,
      needsIdMigration: (map['id']?.toString() ?? '').isEmpty,
    );
  }

  WordEntry toWordEntry() => WordEntry(
    id: 'temp',
    thai: thai,
    phonetic: phonetic,
    english: english,
    imageUrl: imageUrl,
    category: 'temp',
  );

  ExampleSentence toExampleSentence() =>
      ExampleSentence(sentence: question, gapAnswer: answer);
}
