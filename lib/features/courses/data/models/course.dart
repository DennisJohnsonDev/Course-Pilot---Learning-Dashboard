class Course {
  const Course({
    required this.id,
    required this.title,
    required this.instructor,
    required this.progress,
    required this.lessons,
  });

  factory Course.fromJson(Map<String, Object?> json) => Course(
    id: json['id']! as int,
    title: json['title']! as String,
    instructor: json['instructor']! as String,
    progress: json['progress']! as int,
    lessons: json['lessons']! as int,
  );

  final int id;
  final String title;
  final String instructor;

  /// Percentage from 0 to 100.
  final int progress;
  final int lessons;

  Map<String, Object?> toJson() => {
    'id': id,
    'title': title,
    'instructor': instructor,
    'progress': progress,
    'lessons': lessons,
  };
}
