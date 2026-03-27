/// Reminder task model — UI-only, ready for Riverpod/backend later.
class Task {
  Task({
    required this.id,
    required this.title,
    required this.category,
    required this.time,
    required this.frequency,
    this.isDone = false,
    this.isFeatured = false,
  });

  final String id;
  final String title;
  final String category; // 'WORK' | 'HEALTH' | 'MORA' | 'SOCIAL'
  final String time;
  final String frequency;
  bool isDone;
  bool isFeatured;
}
