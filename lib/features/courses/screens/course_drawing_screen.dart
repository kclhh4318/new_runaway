import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:new_runaway/features/courses/course_provider.dart';
import 'package:geolocator/geolocator.dart';

class CourseDrawingScreen extends StatefulWidget {
  const CourseDrawingScreen({Key? key}) : super(key: key);

  @override
  _CourseDrawingScreenState createState() => _CourseDrawingScreenState();
}

class _CourseDrawingScreenState extends State<CourseDrawingScreen> {
  GoogleMapController? _mapController;
  Set<Polyline> _polylines = {};
  List<LatLng> _points = [];
  bool _isDrawingMode = false;
  List<Widget> _nearbyCourseThumbnails = [];
  LatLng? _currentLocation;
  List<Offset> _sketchPoints = [];

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _loadNearbyCourseThumbnails();
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
    } catch (e) {
      print("Error getting current location: $e");
    }
  }

  void _loadNearbyCourseThumbnails() {
    // 임시 더미 데이터
    setState(() {
      _nearbyCourseThumbnails = List.generate(
        5,
            (index) => AspectRatio(
          aspectRatio: 1,
          child: Container(
            margin: EdgeInsets.only(right: 8),
            color: Colors.grey[300],
            child: Center(child: Text('코스 ${index + 1}')),
          ),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('코스 그리기')),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _currentLocation ?? LatLng(37.5665, 126.9780),
              zoom: 14.0,
            ),
            onMapCreated: (GoogleMapController controller) {
              _mapController = controller;
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
                      child: Text(_isDrawingMode ? '드로잉 종료' : '드로잉 시작'),
                    ),
                    if (_isDrawingMode)
                      ElevatedButton(
                        onPressed: _clearDrawing,
                        child: Text('다시 그리기'),
                      ),
                    ElevatedButton(
                      onPressed: _finishDrawing,
                      child: Text('완료'),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                Container(
                  height: 100,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: _nearbyCourseThumbnails,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      RenderBox renderBox = context.findRenderObject() as RenderBox;
      Offset localPosition = renderBox.globalToLocal(details.localPosition);
      _sketchPoints.add(localPosition);
    });
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

  void _convertSketchToLatLng() {
    if (_mapController == null) return;

    _points.clear();
    for (Offset point in _sketchPoints) {
      _mapController!.getLatLng(ScreenCoordinate(
        x: point.dx.toInt(),
        y: point.dy.toInt(),
      )).then((LatLng latlng) {
        setState(() {
          _points.add(latlng);
          _updatePolyline();
        });
      });
    }
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

  Future<void> _finishDrawing() async {
    _convertSketchToLatLng();
    final courseProvider = Provider.of<CourseProvider>(context, listen: false);
    await courseProvider.analyzeAndRecommendCourse(_points);
    Navigator.pushNamed(context, '/course_analysis_result');
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
