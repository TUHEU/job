class Job {
  final String id;
  final String title;
  final String description;
  final String employerId;
  final List<String> requirements;
  final DateTime createdAt;

  Job({
    required this.id,
    required this.title,
    required this.description,
    required this.employerId,
    required this.requirements,
    required this.createdAt,
  });

  factory Job.fromJson(Map<String, dynamic> json) {
    return Job(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      employerId: json['employerId'],
      requirements: List<String>.from(json['requirements']),
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'employerId': employerId,
      'requirements': requirements,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
