class Stats {
  final double distance;
  final int duration;
  final double averagePace;
  final int count;

  Stats({
    required this.distance,
    required this.duration,
    required this.averagePace,
    required this.count,
  });

  factory Stats.fromJson(Map<String, dynamic> json) {
    return Stats(
      distance: (json['distance'] ?? 0).toDouble(),
      duration: json['duration'] ?? 0,
      averagePace: (json['average_pace'] ?? 0).toDouble(),
      count: json['count'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'distance': distance,
      'duration': duration,
      'average_pace': averagePace,
      'count': count,
    };
  }
}
