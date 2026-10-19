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

  static QuestionType fromString(String? key) {
    if (key == null || key.isEmpty) return QuestionType.flashcard;
    final normalized = normalizeStoredKey(key).trim().toLowerCase();
    for (final type in QuestionType.values) {
      if (type.typeKey.toLowerCase() == normalized ||
          type.name.toLowerCase() == normalized) {
        return type;
      }
    }
    return QuestionType.flashcard;
  }

  static String normalizeStoredKey(String key) {
    switch (key.trim().toLowerCase()) {
      case 'fill blank':
      case 'fillblank':
        return QuestionType.completeSentence.typeKey;
      case 'english meaning':
      case 'englishmeaning':
        return QuestionType.meaning.typeKey;
      default:
        for (final type in QuestionType.values) {
          if (type.typeKey.toLowerCase() == key.trim().toLowerCase() ||
              type.name.toLowerCase() == key.trim().toLowerCase()) {
            return type.typeKey;
          }
        }
        return key;
    }
  }
}
