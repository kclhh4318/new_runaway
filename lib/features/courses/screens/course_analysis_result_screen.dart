import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:convert';
import 'package:flutter/rendering.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:provider/provider.dart';
import 'package:new_runaway/features/courses/course_provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:new_runaway/features/running/screens/running_session_screen.dart';
import 'package:new_runaway/features/running/running_provider.dart';
import 'package:flutter/rendering.dart';

import '../../../utils/logger.dart';
import '../../../models/course.dart'; // 추가된 부분
class CourseAnalysisResultScreen extends StatelessWidget {
  final logger = Logger('CourseAnalysisResultScreen');
  final GlobalKey _globalKey = GlobalKey();
  final Course course; // 추가된 부분

  CourseAnalysisResultScreen({required this.course}); // 추가된 부분

  @override
  Widget build(BuildContext context) {
    final courseProvider = Provider.of<CourseProvider>(context);
    final recommendedCourse = courseProvider.recommendedCourse;

    return Scaffold(
      appBar: AppBar(title: Text('코스 분석 결과')),
      body: Column(
        children: [
          Expanded(
            child: recommendedCourse != null
                ? RepaintBoundary(
              key: _globalKey,
              child: GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: _calculateCenter(recommendedCourse.points),
                  zoom: 14.0,
                ),
                polylines: {
                  Polyline(
                    polylineId: PolylineId('recommended_course'),
                    points: recommendedCourse.points,
                    color: Colors.blue,
                    width: 5,
                  ),
                },
                onMapCreated: (GoogleMapController controller) {
                  _fitBounds(controller, recommendedCourse.points);
                },
              ),
            )
                : Center(child: CircularProgressIndicator()),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('총 거리: ${courseProvider.totalDistance.toStringAsFixed(2)} km',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                Text('코스 설명: ${recommendedCourse?.description.split('.').first ?? ""}',
                    style: TextStyle(fontSize: 16)),
                SizedBox(height: 8),
                Text('안전 팁: ${recommendedCourse?.safetyTips.isNotEmpty == true ? recommendedCourse!.safetyTips.first : ""}',
                    style: TextStyle(fontSize: 16)),
                SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: recommendedCourse != null
                          ? () => _showCountdownAndStartRunning(context, recommendedCourse.points)
                          : null,
                      child: Text('GO!'),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        await courseProvider.reanalyze();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('코스가 재분석되었습니다.')),
                        );
                      },
                      child: Text('재분석'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  LatLng _calculateCenter(List<LatLng> points) {
    if (points.isEmpty) return LatLng(37.5665, 126.9780); // 기본값: 서울

    double sumLat = 0, sumLng = 0;
    for (var point in points) {
      sumLat += point.latitude;
      sumLng += point.longitude;
    }
    return LatLng(sumLat / points.length, sumLng / points.length);
  }

  void _fitBounds(GoogleMapController controller, List<LatLng> points) {
    if (points.isEmpty) return;

    double minLat = points[0].latitude;
    double maxLat = points[0].latitude;
    double minLng = points[0].longitude;
    double maxLng = points[0].longitude;

    for (var point in points) {
      if (point.latitude < minLat) minLat = point.latitude;
      if (point.latitude > maxLat) maxLat = point.latitude;
      if (point.longitude < minLng) minLng = point.longitude;
      if (point.longitude > maxLng) maxLng = point.longitude;
    }

    controller.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat, minLng),
          northeast: LatLng(maxLat, maxLng),
        ),
        50.0, // 패딩
      ),
    );
  }

  Future<void> _showCountdownAndStartRunning(BuildContext context, List<LatLng> coursePoints) async {
    final courseProvider = Provider.of<CourseProvider>(context, listen: false);
    final runningProvider = Provider.of<RunningProvider>(context, listen: false);

    // 이미지 데이터를 base64로 인코딩
    final Uint8List pngBytes = await _capturePng();
    final String base64Image = base64Encode(pngBytes);

    try {
      logger.info('Attempting to create course');
      // 코스 생성 API 호출 (course_type을 0으로 설정, 필요에 따라 변경 가능)
      final courseId = await courseProvider.createCourse(coursePoints, base64Image, 0);
      logger.info('Course created successfully. Course ID: $courseId');

      if (courseId != null && courseId.isNotEmpty) {
        runningProvider.setCourseId(courseId);
        logger.info('Course ID set in RunningProvider: $courseId');
      } else {
        logger.warning('Course ID is null or empty after course creation');
      }

      // 러닝 세션 시작
      runningProvider.startRunning(predefinedCourse: coursePoints);

      // 러닝 세션 화면으로 이동
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => RunningSessionScreen(
            showCountdown: true,
            predefinedCourse: coursePoints,
          ),
        ),
      );
    } catch (e) {
      logger.severe('Failed to create course: $e');
      // 에러 처리
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('코스 생성에 실패했습니다: $e')),
      );
    }
  }

  Future<Uint8List> _capturePng() async {
    try {
      RenderRepaintBoundary boundary = _globalKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData!.buffer.asUint8List();
    } catch (e) {
      logger.severe('Error capturing PNG: $e');
      return Uint8List(0);
    }
  }
}