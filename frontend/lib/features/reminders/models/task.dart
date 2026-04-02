/// Reminder task model — ready for Riverpod/backend.
class Task {
  Task({
    required this.id,
    required this.title,
    required this.category,
    required this.time,
    required this.frequency,
    required this.isoTime,
    this.daysOfWeek = const[],
    this.isDone = false,
    this.isFeatured = false,
  });

  final String id;
  final String title;
  final String category; // 'WORK' | 'HEALTH' | 'SHIZUKI' | 'SOCIAL'
  final String time;
  final String frequency;
  final String isoTime;
  final List<String> daysOfWeek;
  bool isDone;
  bool isFeatured;

  factory Task.fromJson(Map<String, dynamic> json) {
    final tStr = json['scheduledTime'] as String?;
    String timeStr = '--:--';
    String finalIso = '';
    
    if (tStr != null) {
      finalIso = tStr;
      final t = DateTime.parse(tStr).toLocal();
      timeStr = '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
    }
    
    final days = (json['daysOfWeek'] as List?)?.map((e) => e.toString()).toList() ??[];
    
    // LOGIC FIX: Try to read the category from the JSON first. 
    // If it's null or missing, THEN fallback to 'SHIZUKI'.
    final parsedCategory = (json['category'] as String?)?.toUpperCase() ?? 'SHIZUKI';

    return Task(
      id: json['_id'] as String? ?? json['id'] as String? ?? '',
      title: json['message'] as String? ?? 'Empty Task',
      category: parsedCategory, 
      time: timeStr,
      isoTime: finalIso,
      frequency: days.isNotEmpty ? 'Weekly' : 'Once',
      daysOfWeek: days,
      isDone: json['isCompleted'] as bool? ?? false,
      isFeatured: false,
    );
  }
}