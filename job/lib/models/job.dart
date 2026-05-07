class Job {
  String id;
  String title;
  String description;
  String employerId;
  List<String> requirements;

  Job({
    required this.id,
    required this.title,
    required this.description,
    required this.employerId,
    required this.requirements,
  });

  factory Job.fromJson(Map<String, dynamic> json) {
    return Job(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      employerId: json['employerId'],
      requirements: List<String>.from(json['requirements']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'employerId': employerId,
      'requirements': requirements,
    };
  }
}
