import 'package:google_maps_flutter/google_maps_flutter.dart';

class RunningSession {
  final String id;
  final DateTime date;
  final double distance;
  final int duration;
  final double averagePace;
  final int strength;
  final String? imagePath;
  final List<LatLng>? route;  // 새로 추가된 필드

  RunningSession({
    required this.id,
    required this.date,
    required this.distance,
    required this.duration,
    required this.averagePace,
    required this.strength,
    this.imagePath,
    this.route,  // 생성자에 route 추가
  });

  factory RunningSession.fromJson(Map<String, dynamic> json) {
    return RunningSession(
      id: json['_id'] as String,
      date: DateTime.parse(json['date']),
      distance: (json['distance'] as num).toDouble(),
      duration: (json['duration'] as num).toInt(),
      averagePace: (json['average_pace'] as num).toDouble(),
      strength: (json['strength'] as num).toInt(),
      imagePath: json['image_path'] as String?,
      route: (json['route'] as List<dynamic>?)?.map((e) =>
          LatLng(e['latitude'] as double, e['longitude'] as double)).toList(),
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
      'imagePath': imagePath,
      'route': route?.map((latLng) =>
      {'latitude': latLng.latitude, 'longitude': latLng.longitude}).toList(),
    };
  }
}