class Lesson {
  const Lesson({
    required this.id,
    required this.title,
    required this.isCompleted,
  });

  factory Lesson.fromJson(Map<String, Object?> json) => Lesson(
    id: json['id']! as int,
    title: json['title']! as String,
    isCompleted: json['isCompleted']! as bool,
  );

  final int id;
  final String title;
  final bool isCompleted;

  Lesson completed() => Lesson(id: id, title: title, isCompleted: true);

  Map<String, Object?> toJson() => {
    'id': id,
    'title': title,
    'isCompleted': isCompleted,
  };
}
