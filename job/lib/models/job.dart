// lib/models/job.dart
// NOTE: This model is currently NOT used in the app.
// The app uses Internship model instead.
// Keep this only if you plan to add separate job listings feature.

class Job {
  final String id;
  final String title;
  final String description;
  final String employerId;
  final List<String> requirements;

  const Job({
    required this.id,
    required this.title,
    required this.description,
    required this.employerId,
    required this.requirements,
  });

  factory Job.fromJson(Map<String, dynamic> json) => Job(
    id: json['id'] as String,
    title: json['title'] as String,
    description: json['description'] as String,
    employerId: json['employerId'] as String,
    requirements: (json['requirements'] as List<dynamic>)
        .map((e) => e.toString())
        .toList(),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'employerId': employerId,
    'requirements': requirements,
  };
}
