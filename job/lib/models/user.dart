class User {
  String id;
  String name;
  String email;
  String type; // 'intern' or 'company'
  String? company;
  List<String>? skills;
  String? cvPath;
  double? gpa;
  String? aboutMe;
  String? educationHistory;
  List<String>? documents; // URLs or paths

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.type,
    this.company,
    this.skills,
    this.cvPath,
    this.gpa,
    this.aboutMe,
    this.educationHistory,
    this.documents,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      type: json['type'],
      company: json['company'],
      skills: json['skills'] != null ? List<String>.from(json['skills']) : null,
      cvPath: json['cvPath'],
      gpa: json['gpa']?.toDouble(),
      aboutMe: json['aboutMe'],
      educationHistory: json['educationHistory'],
      documents: json['documents'] != null
          ? List<String>.from(json['documents'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'type': type,
      'company': company,
      'skills': skills,
      'cvPath': cvPath,
      'gpa': gpa,
      'aboutMe': aboutMe,
      'educationHistory': educationHistory,
      'documents': documents,
    };
  }
}
