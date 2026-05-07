class User {
  final String id;
  final String name;
  final String email;
  final String type; // 'jobseeker' or 'employer'
  final String? company;
  final List<String>? skills;
  final String? cvPath;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.type,
    this.company,
    this.skills,
    this.cvPath,
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
    };
  }
}
