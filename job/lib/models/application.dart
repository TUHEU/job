class InternshipApplication {
  String id;
  String internId;
  String internshipId;
  String status;
  double? gpa;
  String? aboutMe;
  List<String>? documents; // URLs or paths to uploaded files

  InternshipApplication({
    required this.id,
    required this.internId,
    required this.internshipId,
    required this.status,
    this.gpa,
    this.aboutMe,
    this.documents,
  });

  factory InternshipApplication.fromJson(Map<String, dynamic> json) {
    return InternshipApplication(
      id: json['id'],
      internId: json['internId'],
      internshipId: json['internshipId'],
      status: json['status'],
      gpa: json['gpa']?.toDouble(),
      aboutMe: json['aboutMe'],
      documents: json['documents'] != null
          ? List<String>.from(json['documents'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'internId': internId,
      'internshipId': internshipId,
      'status': status,
      'gpa': gpa,
      'aboutMe': aboutMe,
      'documents': documents,
    };
  }
}
