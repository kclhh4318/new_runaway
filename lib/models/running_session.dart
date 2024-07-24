class RunningSession {
  final String id;
  final DateTime date;
  final double distance;
  final int duration;
  final double averagePace;
  final int strength;
  final String? imagePath; // 여기에 imagePath 속성을 추가합니다.

  RunningSession({
    required this.id,
    required this.date,
    required this.distance,
    required this.duration,
    required this.averagePace,
    required this.strength,
    this.imagePath, // 생성자에 imagePath를 추가합니다.
  });

  factory RunningSession.fromJson(Map<String, dynamic> json) {
    return RunningSession(
      id: json['_id'] as String,
      date: DateTime.parse(json['date']),
      distance: (json['distance'] as num).toDouble(),
      duration: (json['duration'] as num).toInt(),
      averagePace: (json['average_pace'] as num).toDouble(),
      strength: (json['strength'] as num).toInt(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'distance': distance,
      'duration': duration,
      'averagePace': averagePace,
      'strength': strength,
    };
  }
}