class RunningSession {
  final String id;
  final DateTime date;
  final double distance;
  final int duration;
  final double averagePace;

  RunningSession({
    required this.id,
    required this.date,
    required this.distance,
    required this.duration,
    required this.averagePace,
  });

  factory RunningSession.fromJson(Map<String, dynamic> json) {
    return RunningSession(
      id: json['id'],
      date: DateTime.parse(json['date']),
      distance: json['distance'].toDouble(),
      duration: json['duration'],
      averagePace: json['averagePace'].toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'distance': distance,
      'duration': duration,
      'averagePace': averagePace,
    };
  }
}