// lib/models/application.dart
class InternshipApplication {
  final String id;
  final String internId;
  final String internshipId;
  final String status;
  final double? gpa;
  final String? aboutMe;
  final List<String>? documents;
  final String? createdAt;

  const InternshipApplication({
    required this.id,
    required this.internId,
    required this.internshipId,
    required this.status,
    this.gpa,
    this.aboutMe,
    this.documents,
    this.createdAt,
  });

  bool get isPending => status == 'pending';
  bool get isAccepted => status == 'accepted';
  bool get isRejected => status == 'rejected';

  factory InternshipApplication.fromJson(Map<String, dynamic> json) =>
      InternshipApplication(
        id: json['id'] as String,
        internId: json['internId'] as String,
        internshipId: json['internshipId'] as String,
        status: json['status'] as String? ?? 'pending',
        gpa: (json['gpa'] as num?)?.toDouble(),
        aboutMe: json['aboutMe'] as String?,
        documents: (json['documents'] as List?)
            ?.map((e) => e.toString())
            .toList(),
        createdAt: json['createdAt'] as String?,
      );
}
