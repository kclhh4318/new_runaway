import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:new_runaway/features/courses/course_provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:new_runaway/services/api_service.dart';
import 'package:new_runaway/models/recommended_course.dart';
import 'package:new_runaway/models/course.dart'; // Course 클래스를 import
import 'package:new_runaway/features/courses/screens/course_analysis_result_screen.dart';

class CourseDrawingScreen extends StatefulWidget {
  const CourseDrawingScreen({Key? key}) : super(key: key);

  @override
  _CourseDrawingScreenState createState() => _CourseDrawingScreenState();
}

class _CourseDrawingScreenState extends State<CourseDrawingScreen> {
  final Completer<GoogleMapController> _mapController = Completer();
  Set<Polyline> _polylines = {};
  List<LatLng> _points = [];
  bool _isDrawingMode = false;
  LatLng? _currentLocation;
  List<Offset> _sketchPoints = [];
  LatLngBounds? _lastBounds;
  final ApiService _apiService = ApiService();
  List<RecommendedCourse> _recommendedCourses = []; // 수정된 부분

  @override
  void initState() {
    super.initState();
    _getCurrentLocation().then((_) => _loadRecommendedCourses());
  }

  Future<void> _loadRecommendedCourses() async {
    if (_currentLocation == null) return;
    try {
      final courses = await _apiService.getLatestCourses(
          _currentLocation!.latitude,
          _currentLocation!.longitude
      );
      setState(() {
        _recommendedCourses = courses.map((course) => convertCourseToRecommendedCourse(course)).toList();
      });
    } catch (e) {
      print('추천 코스를 불러오는 데 실패했다모: $e');
      setState(() {
        _recommendedCourses = []; // 빈 리스트로 설정
      });
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever) {
        return;
      }
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
      });
      _moveToCurrentLocation();
    } catch (e) {
      print("현재 위치를 가져오는 데 실패했다모: $e");
    }
  }

  Future<void> _moveToCurrentLocation() async {
    if (_currentLocation == null) return;
    final GoogleMapController controller = await _mapController.future;
    controller.animateCamera(CameraUpdate.newLatLng(_currentLocation!));
  }

  void _showCourseConfirmationDialog(RecommendedCourse course) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('이 코스로 달려보시겠습니까?'),
        content: Text('거리: ${course.distance.toStringAsFixed(2)} km'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('아니오'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CourseAnalysisResultScreen(course: course),
                ),
              );
            },
            child: Text('예'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('코스 그리기'), backgroundColor: Colors.white,),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _currentLocation ?? LatLng(37.5665, 126.9780),
              zoom: 14.0,
            ),
            onMapCreated: (GoogleMapController controller) {
              _mapController.complete(controller);
              _moveToCurrentLocation();
            },
            polylines: _polylines,
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
          ),
          if (_isDrawingMode)
            GestureDetector(
              onPanUpdate: _onPanUpdate,
              onPanEnd: _onPanEnd,
              child: CustomPaint(
                painter: SketchPainter(_sketchPoints),
                size: Size.infinite,
              ),
            ),
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ElevatedButton(
                      onPressed: _toggleDrawingMode,
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Color(0xFF0064FF), backgroundColor: Colors.white, // 폰트색
                      ),
                      child: Text(_isDrawingMode ? '드로잉 종료' : '드로잉 시작'),
                    ),
                    if (_isDrawingMode)
                      ElevatedButton(
                        onPressed: _clearDrawing,
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Color(0xFF0064FF), backgroundColor: Colors.white, // 폰트색
                        ),
                        child: Text('다시 그리기')
                      ),
                    SizedBox(width: 24),
                    ElevatedButton(
                      onPressed: _finishDrawing,
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white, backgroundColor: Color(0xFF0064FF), // 폰트색
                      ),
                      child: Text('완료'),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                Container(
                  height: 100,
                  child: _recommendedCourses.isEmpty
                      ? Center(child: Text("아직 주변에 코스그리기를 통해 달린 사람이 없다모!"))
                      : ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _recommendedCourses.length,
                    itemBuilder: (context, index) {
                      final course = _recommendedCourses[index];
                      return GestureDetector(
                        onTap: () => _showCourseConfirmationDialog(course),
                        child: Container(
                          width: 100,
                          margin: EdgeInsets.only(right: 10),
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '${course.distance.toStringAsFixed(2)} km',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              SizedBox(height: 4),
                              Text(
                                '추천 ${course.pointsOfInterest.length}', // 추천 수를 포인트 오브 인터레스트 수로 대체
                                style: TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          if (_currentLocation == null)
            Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }

  void _onPanUpdate(DragUpdateDetails details) async {
    if (!_mapController.isCompleted) return;
    RenderBox renderBox = context.findRenderObject() as RenderBox;
    Offset localPosition = renderBox.globalToLocal(details.localPosition);

    setState(() {
      _sketchPoints.add(localPosition);
    });

    if (_lastBounds == null || _sketchPoints.length % 10 == 0) {
      final GoogleMapController controller = await _mapController.future;
      _lastBounds = await controller.getVisibleRegion();
    }
  }

  void _onPanEnd(DragEndDetails details) {
    // 스케치가 끝났을 때 호출되지만, 여기서는 아무 작업도 하지 않습니다.
  }

  void _toggleDrawingMode() {
    setState(() {
      _isDrawingMode = !_isDrawingMode;
      if (!_isDrawingMode) {
        _convertSketchToLatLng();
      } else {
        _clearDrawing();
      }
    });
  }

  void _clearDrawing() {
    setState(() {
      _sketchPoints.clear();
      _points.clear();
      _updatePolyline();
    });
  }

  void _convertSketchToLatLng() async {
    if (_lastBounds == null) return;

    _points.clear();
    for (var point in _sketchPoints) {
      double percentageX = point.dx / context.size!.width;
      double percentageY = point.dy / context.size!.height;

      double lngDiff = _lastBounds!.northeast.longitude - _lastBounds!.southwest.longitude;
      double latDiff = _lastBounds!.northeast.latitude - _lastBounds!.southwest.latitude;

      double longitude = _lastBounds!.southwest.longitude + (lngDiff * percentageX);
      double latitude = _lastBounds!.northeast.latitude - (latDiff * percentageY);

      _points.add(LatLng(latitude, longitude));
    }
    _updatePolyline();
  }

  void _updatePolyline() {
    _polylines.clear();
    _polylines.add(Polyline(
      polylineId: PolylineId('drawn_course'),
      points: _points,
      color: Colors.black,
      width: 5,
    ));
  }

  void _finishDrawing() async {
    _convertSketchToLatLng();
    if (_points.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('코스를 그려주세요모!'))
      );
      return;
    }

    final courseProvider = Provider.of<CourseProvider>(context, listen: false);

    // 로딩 다이얼로그 표시
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 20),
              Text("코스를 분석 중이다모..."),
            ],
          ),
        );
      },
    );

    try {
      await courseProvider.analyzeAndRecommendCourse(_points);

      // 로딩 다이얼로그 닫기
      Navigator.of(context).pop();

      final recommendedCourse = courseProvider.recommendedCourse;
      if (recommendedCourse != null) {
        // 분석 결과 화면으로 이동
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CourseAnalysisResultScreen(course: recommendedCourse), // RecommendedCourse 객체 전달
          ),
        );
      }
    } catch (e) {
      // 로딩 다이얼로그 닫기
      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('코스 분석에 실패했다모: $e'))
      );
    }
  }
}

class SketchPainter extends CustomPainter {
  final List<Offset> points;

  SketchPainter(this.points);

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()
      ..color = Colors.black
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 4.0;

    for (int i = 0; i < points.length - 1; i++) {
      canvas.drawLine(points[i], points[i + 1], paint);
    }
  }

  @override
  bool shouldRepaint(SketchPainter oldDelegate) => true;
}

// Course 객체를 RecommendedCourse 객체로 변환하는 메서드
RecommendedCourse convertCourseToRecommendedCourse(Course course) {
  return RecommendedCourse(
    points: [], // 필요한 경우 실제 데이터를 채워야 합니다.
    distance: course.distance,
    description: '', // 필요한 경우 실제 데이터를 채워야 합니다.
    safetyTips: [], // 필요한 경우 실제 데이터를 채워야 합니다.
    pointsOfInterest: [], // 필요한 경우 실제 데이터를 채워야 합니다.
  );
}
