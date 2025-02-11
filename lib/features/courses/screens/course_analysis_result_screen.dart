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
import '../../../models/recommended_course.dart';

class CourseAnalysisResultScreen extends StatefulWidget {
  final RecommendedCourse initialCourse;

  CourseAnalysisResultScreen({required this.initialCourse});

  @override
  _CourseAnalysisResultScreenState createState() => _CourseAnalysisResultScreenState();
}

class _CourseAnalysisResultScreenState extends State<CourseAnalysisResultScreen> {
  final logger = Logger('CourseAnalysisResultScreen');
  final GlobalKey _globalKey = GlobalKey();
  late RecommendedCourse _currentCourse;

  @override
  void initState() {
    super.initState();
    _currentCourse = widget.initialCourse;
  }

  @override
  Widget build(BuildContext context) {
    final courseProvider = Provider.of<CourseProvider>(context);

    return Scaffold(
      appBar: AppBar(title: Text('코스 분석 결과'), backgroundColor: Colors.white,),
      body: Column(
        children: [
          Expanded(
            child: RepaintBoundary(
              key: _globalKey,
              child: GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: _calculateCenter(_currentCourse.points),
                  zoom: 14.0,
                ),
                polylines: {
                  Polyline(
                    polylineId: PolylineId('recommended_course'),
                    points: _currentCourse.points,
                    color: Colors.blue,
                    width: 5,
                  ),
                },
                onMapCreated: (GoogleMapController controller) {
                  _fitBounds(controller, _currentCourse.points);
                },
              ),
            ),
          ),
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('총 거리: ${_currentCourse.distance.toStringAsFixed(2)} km',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                Text('코스 설명: ${_currentCourse.description.split('.').first}',
                    style: TextStyle(fontSize: 16)),
                SizedBox(height: 8),
                Text('안전 팁: ${_currentCourse.safetyTips.isNotEmpty ? _currentCourse.safetyTips.first : ""}',
                    style: TextStyle(fontSize: 16)),
                SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: () => _showCountdownAndStartRunning(context, _currentCourse.points),
                      child: Text('RUN!'),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white, backgroundColor: Color(0xFF0064FF),
                      ),
                      onPressed: () => _reanalyzeCourse(context, courseProvider),
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

  Future<void> _reanalyzeCourse(BuildContext context, CourseProvider courseProvider) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            content: Row(
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 20),
                Text("코스를 재분석 중이다모..."),
              ],
            ),
          );
        },
      );

      await courseProvider.reanalyze(_currentCourse.points);
      Navigator.of(context).pop(); // 로딩 다이얼로그 닫기

      setState(() {
        _currentCourse = courseProvider.recommendedCourse!;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('코스가 재분석되었습니다.')),
      );
    } catch (e) {
      Navigator.of(context).pop(); // 로딩 다이얼로그 닫기
      logger.severe('Failed to reanalyze course: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('코스 재분석에 실패했습니다: $e')),
      );
    }
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
      // 코스 생성 API 호출 (course_type을 1로 설정, 다른 사람의 코스를 사용하므로)
      final courseId = await courseProvider.createCourse(coursePoints, base64Image, 1);
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
      ui.Image image = await boundary.toImage(pixelRatio: 1.0);
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      Uint8List pngBytes = byteData!.buffer.asUint8List();
      print('Captured PNG size: ${pngBytes.length} bytes');
      print('First 10 bytes of captured image: ${pngBytes.sublist(0, 10)}');
      return pngBytes;
    } catch (e) {
      logger.severe('Error capturing PNG: $e');
      return Uint8List(0);
    }
  }
}