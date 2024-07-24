import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:new_runaway/features/courses/course_provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:new_runaway/features/running/screens/running_session_screen.dart';
import 'package:new_runaway/features/running/widgets/countdown_timer.dart';
import 'package:new_runaway/features/running/running_provider.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

class CourseAnalysisResultScreen extends StatelessWidget {

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
                ? GoogleMap(
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
                final courseProvider = Provider.of<CourseProvider>(context, listen: false);
                final completer = Completer<GoogleMapController>();
                completer.complete(controller);
                courseProvider.setMapController(completer);
                _fitBounds(controller, recommendedCourse.points);
              },
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
                Text('코스 설명: ${recommendedCourse?.description ?? ""}',
                    style: TextStyle(fontSize: 16)),
                SizedBox(height: 8),
                Text('안전 팁: ${recommendedCourse?.safetyTips ?? ""}',
                    style: TextStyle(fontSize: 16)),
                SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: recommendedCourse != null
                          ? () {
                        final runningProvider = Provider.of<RunningProvider>(context, listen: false);
                        runningProvider.startRunning(predefinedCourse: recommendedCourse.points);
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (context) => RunningSessionScreen(
                              showCountdown: true,
                              predefinedCourse: recommendedCourse.points,
                            ),
                          ),
                        );
                      }
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

  void _showCountdownAndStartRunning(BuildContext context, List<LatLng> coursePoints) async {
    final courseProvider = Provider.of<CourseProvider>(context, listen: false);

    // 지도 이미지를 캡처하여 Base64로 인코딩
    final controller = await courseProvider.mapController?.future;
    final Uint8List? imageBytes = await controller?.takeSnapshot();
    final String base64Image = base64Encode(imageBytes!);

    // 코스 생성 API 호출
    try {
      final courseData = await courseProvider.createCourse(coursePoints, base64Image);
      print('Course created successfully: $courseData');
    } catch (e) {
      print('Failed to create course: $e');
      // 에러 처리 (예: 사용자에게 알림)
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => Scaffold(
          body: CountdownTimer(
            onFinished: () {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => RunningSessionScreen(
                    showCountdown: false,
                    predefinedCourse: coursePoints,
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}