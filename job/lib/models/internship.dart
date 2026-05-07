class Internship {
  String id;
  String title;
  String description;
  String companyId;
  String companyName;
  String location;
  String field;
  List<String> requirements;
  DateTime deadline;
  bool isActive;

  Internship({
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
  });

  factory Internship.fromJson(Map<String, dynamic> json) {
    return Internship(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      companyId: json['companyId'],
      companyName: json['companyName'],
      location: json['location'],
      field: json['field'],
      requirements: List<String>.from(json['requirements']),
      deadline: DateTime.parse(json['deadline']),
      isActive: json['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'companyId': companyId,
      'companyName': companyName,
      'location': location,
      'field': field,
      'requirements': requirements,
      'deadline': deadline.toIso8601String(),
      'isActive': isActive,
    };
  }
}
