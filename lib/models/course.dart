// lib/models/course.dart 파일을 다음과 같이 수정합니다.

import 'package:mongo_dart/mongo_dart.dart';

class Course {
  final ObjectId id;
  final ObjectId? createdBy;
  final List<int> route;
  final Map<String, dynamic> routeCoordinate;
  final double distance;
  final bool courseType;
  final int recommendationCount;
  final DateTime createdAt;

  Course({
    required this.id,
    this.createdBy,
    required this.route,
    required this.routeCoordinate,
    required this.distance,
    required this.courseType,
    required this.recommendationCount,
    required this.createdAt,
  });

  factory Course.fromJson(Map<String, dynamic> json) {
    return Course(
      id: ObjectId.fromHexString(json['id']),
      createdBy: json['created_by'] != null ? ObjectId.fromHexString(json['created_by']) : null,
      route: List<int>.from(json['route']),
      routeCoordinate: json['route_coordinate'],
      distance: json['distance'].toDouble(),
      courseType: json['course_type'],
      recommendationCount: json['recommendation_count'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}