class DiscoverItem {
  final String id;
  final String title;
  final String url;
  final String? description;
  final String? imageUrl;
  final bool isPinned;
  final DateTime date;

  DiscoverItem({
    required this.id,
    required this.title,
    required this.url,
    this.description,
    this.imageUrl,
    this.isPinned = false,
    required this.date,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'url': url,
    'description': description,
    'imageUrl': imageUrl,
    'isPinned': isPinned,
    'date': date.toIso8601String(),
  };

  factory DiscoverItem.fromMap(Map<String, dynamic> map) => DiscoverItem(
    id: map['id'] ?? '',
    title: map['title'] ?? '',
    url: map['url'] ?? '',
    description: map['description'],
    imageUrl: map['imageUrl'],
    isPinned: map['isPinned'] ?? false,
    date: DateTime.parse(map['date'] ?? DateTime.now().toIso8601String()),
  );
}
