class Stats {
  final double totalDistance;
  final int totalDuration;
  final double averagePace;
  final int totalRuns;

  Stats({
    required this.totalDistance,
    required this.totalDuration,
    required this.averagePace,
    required this.totalRuns,
  });

  factory Stats.fromJson(Map<String, dynamic> json) {
    return Stats(
      totalDistance: json['totalDistance'].toDouble(),
      totalDuration: json['totalDuration'],
      averagePace: json['averagePace'].toDouble(),
      totalRuns: json['totalRuns'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalDistance': totalDistance,
      'totalDuration': totalDuration,
      'averagePace': averagePace,
      'totalRuns': totalRuns,
    };
  }
}