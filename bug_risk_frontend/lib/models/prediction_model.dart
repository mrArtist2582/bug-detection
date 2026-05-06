class Prediction {
  final String id;
  final String repoName;
  final String commitSha;
  final String pushedBy;
  final String module;
  final int filesChanged;
  final int linesAdded;
  final int linesRemoved;
  final int commitCount;
  final double riskScore;
  final String riskLevel;
  final double confidence;
  final DateTime timestamp;

  Prediction({
    required this.id,
    required this.repoName,
    required this.commitSha,
    required this.pushedBy,
    required this.module,
    required this.filesChanged,
    required this.linesAdded,
    required this.linesRemoved,
    required this.commitCount,
    required this.riskScore,
    required this.riskLevel,
    required this.confidence,
    required this.timestamp,
  });

  factory Prediction.fromJson(Map<String, dynamic> json) {
    return Prediction(
      id: json['_id'] ?? '',
      repoName: json['repo_name'] ?? 'unknown',
      commitSha: json['commit_sha'] ?? '',
      pushedBy: json['pushed_by'] ?? 'unknown',
      module: json['module'] ?? 'unknown',
      filesChanged: json['files_changed'] ?? 0,
      linesAdded: json['lines_added'] ?? 0,
      linesRemoved: json['lines_removed'] ?? 0,
      commitCount: json['commit_count'] ?? 0,
      riskScore: (json['risk_score'] as num).toDouble(),
      riskLevel: json['risk_level'] ?? 'Low',
      confidence: (json['confidence'] as num).toDouble(),
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}
