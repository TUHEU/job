class Application {
  final String id;
  final String jobSeekerId;
  final String jobId;
  final String status; // 'pending', 'accepted', 'rejected'
  final DateTime appliedAt;

  Application({
    required this.id,
    required this.jobSeekerId,
    required this.jobId,
    required this.status,
    required this.appliedAt,
  });

  factory Application.fromJson(Map<String, dynamic> json) {
    return Application(
      id: json['id'],
      jobSeekerId: json['jobSeekerId'],
      jobId: json['jobId'],
      status: json['status'],
      appliedAt: DateTime.parse(json['appliedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'jobSeekerId': jobSeekerId,
      'jobId': jobId,
      'status': status,
      'appliedAt': appliedAt.toIso8601String(),
    };
  }
}
