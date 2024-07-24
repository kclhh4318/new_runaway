import 'package:mongo_dart/mongo_dart.dart';

class Course {
  final ObjectId id;
  final String route;  // base64 encoded image
  final ObjectId? createdBy;
  final Map<String, dynamic>? routeCoordinate;
  final double? distance;
  final int? courseType;
  final int? recommendationCount;
  final DateTime? createdAt;

  Course({
    required this.id,
    required this.route,
    this.createdBy,
    this.routeCoordinate,
    this.distance,
    this.courseType,
    this.recommendationCount,
    this.createdAt,
  });

  factory Course.fromJson(Map<String, dynamic> json) {
    return Course(
      id: ObjectId.fromHexString(json['_id']),
      route: json['route'],
      createdBy: json['created_by'] != null ? ObjectId.fromHexString(json['created_by']) : null,
      routeCoordinate: json['route_coordinate'],
      distance: json['distance']?.toDouble(),
      courseType: json['course_type'],  // int 타입으로 받음
      recommendationCount: json['recommendation_count'],
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
    );
  }

  // 추가된 getter
  bool get isRecommendedCourse => courseType == 1;
}