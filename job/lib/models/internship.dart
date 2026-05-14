// lib/models/internship.dart
class Internship {
  final String id;
  final String title;
  final String description;
  final String companyId;
  final String companyName;
  final String location;
  final String field;
  final List<String> requirements;
  final DateTime deadline;
  final bool isActive;
  final int? matchScore;
  final int views;
  final int applicationsCount;

  const Internship({
    required this.id,
    required this.title,
    required this.description,
    required this.companyId,
    required this.companyName,
    required this.location,
    required this.field,
    required this.requirements,
    required this.deadline,
    this.isActive = true,
    this.matchScore,
    this.views = 0,
    this.applicationsCount = 0,
  });

  int get daysLeft => deadline.difference(DateTime.now()).inDays;
  bool get isExpired => daysLeft < 0;
  String get deadlineLabel => isExpired ? 'Closed' : '$daysLeft days left';

  factory Internship.fromJson(Map<String, dynamic> json) => Internship(
    id: json['id'] as String,
    title: json['title'] as String,
    description: json['description'] as String? ?? '',
    companyId: json['companyId'] as String? ?? '',
    companyName: json['companyName'] as String? ?? 'Unknown',
    location: json['location'] as String? ?? '',
    field: json['field'] as String? ?? '',
    requirements: (json['requirements'] as List? ?? [])
        .map((e) => e.toString())
        .toList(),
    deadline: DateTime.parse(json['deadline'] as String),
    isActive: json['isActive'] as bool? ?? true,
    matchScore: json['matchScore'] as int?,
    views: json['views'] as int? ?? 0,
    applicationsCount: json['applicationsCount'] as int? ?? 0,
  );
}
