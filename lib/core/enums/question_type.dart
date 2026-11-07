import 'package:flutter/material.dart';

enum QuestionType {
  flashcard(
    typeKey: 'Flashcard',
    displayName: 'Flashcard',
    description: 'Show word and meaning',
    icon: Icons.amp_stories_rounded,
  ),
  fourChoice(
    typeKey: 'Four Choice',
    displayName: 'Four Choice',
    description: 'Multiple choice question',
    icon: Icons.quiz_rounded,
  ),
  completeSentence(
    typeKey: 'Complete Sentence',
    displayName: 'Complete Sentence',
    description: 'Type the missing word',
    icon: Icons.text_fields_rounded,
  ),
  meaning(
    typeKey: 'Meaning',
    displayName: 'Meaning',
    description: 'Translate and type',
    icon: Icons.translate_rounded,
  ),
  speaking(
    typeKey: 'Speaking',
    displayName: 'Speaking',
    description: 'Practice pronunciation',
    icon: Icons.mic_rounded,
  ),
  listening(
    typeKey: 'Listening',
    displayName: 'Listening',
    description: 'Listen and identify',
    icon: Icons.headphones_rounded,
  ),
  listeningChoice(
    typeKey: 'Listening Choice',
    displayName: 'Listening Choice',
    description: 'Listen and choose 4 choices',
    icon: Icons.hearing_rounded,
  ),
  sentenceOrder(
    typeKey: 'Sentence Order',
    displayName: 'Sentence Order',
    description: 'Arrange words in order',
    icon: Icons.sort_rounded,
  ),
  vowelFill(
    typeKey: 'Vowel Fill',
    displayName: 'Vowel Fill',
    description: 'Fill the missing vowel',
    icon: Icons.spellcheck_rounded,
  ),
  infoNote(
    typeKey: 'Info Note',
    displayName: 'Info Note',
    description: 'Image and detailed text',
    icon: Icons.article_rounded,
  ),
  conversation(
    typeKey: 'Conversation',
    displayName: 'Conversation',
    description: 'Interactive chat dialogue',
    icon: Icons.forum_rounded,
  ),
  sentenceExample(
    typeKey: 'Sentence Example',
    displayName: 'Sentence Example',
    description: 'Show sentence and meaning',
    icon: Icons.notes_rounded,
  );

  final String typeKey;
  final String displayName;
  final String description;
  final IconData icon;

  const QuestionType({
    required this.typeKey,
    required this.displayName,
    required this.description,
    required this.icon,
  });

  static QuestionType? tryFromString(String? key) {
    if (key == null || key.trim().isEmpty) return null;

    final trimmed = key.trim();
    final normalized =
        trimmed.toLowerCase().replaceAll('_', '').replaceAll(' ', '');

    for (final type in QuestionType.values) {
      final typeKeyNorm =
          type.typeKey.toLowerCase().replaceAll('_', '').replaceAll(' ', '');
      final nameNorm = type.name.toLowerCase();
      if (normalized == typeKeyNorm || normalized == nameNorm) {
        return type;
      }
    }

    switch (normalized) {
      case 'multiplechoice':
      case 'fourchoice':
        return QuestionType.fourChoice;
      case 'completesentense':
      case 'fillblank':
      case 'completesentence':
        return QuestionType.completeSentence;
      case 'englishmeaning':
        return QuestionType.meaning;
      case 'info':
      case 'culturenote':
      case 'infonote':
        return QuestionType.infoNote;
      case 'vowelfill':
        return QuestionType.vowelFill;
      case 'listeningchoice':
        return QuestionType.listeningChoice;
      case 'sentenceorder':
        return QuestionType.sentenceOrder;
      case 'sentenceexample':
        return QuestionType.sentenceExample;
      default:
        return null;
    }
  }

  static QuestionType fromString(String? key) {
    return tryFromString(key) ?? QuestionType.flashcard;
  }

  static String normalizeStoredKey(String key) {
    final type = tryFromString(key);
    if (type != null) {
      return type.typeKey;
    }
    return key;
  }
}
