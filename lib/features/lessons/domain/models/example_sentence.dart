class ExampleSentence {
  final String sentence;
  final String gapAnswer;

  ExampleSentence({required this.sentence, required this.gapAnswer});

  Map<String, dynamic> toMap() => {
    'sentence': sentence,
    'gapAnswer': gapAnswer,
  };

  factory ExampleSentence.fromMap(Map<String, dynamic> map) => ExampleSentence(
    sentence: map['sentence'] ?? '',
    gapAnswer: map['gapAnswer'] ?? '',
  );
}
