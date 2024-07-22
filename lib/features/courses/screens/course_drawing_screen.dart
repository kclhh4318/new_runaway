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
            onTap: _isDrawingMode ? _addPoint : null,
          ),
          if (_isDrawingMode)
            Container(
              color: Colors.white.withOpacity(0.3),
              child: Center(child: Text('드로잉 모드')),
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

  void _toggleDrawingMode() {
    setState(() {
      _isDrawingMode = !_isDrawingMode;
      if (!_isDrawingMode) {
        _updatePolyline();
      }
    });
  }

  void _addPoint(LatLng point) {
    setState(() {
      _points.add(point);
      _updatePolyline();
    });
  }

  void _clearDrawing() {
    setState(() {
      _points.clear();
      _updatePolyline();
    });
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

  void _finishDrawing() {
    final courseProvider = Provider.of<CourseProvider>(context, listen: false);
    courseProvider.analyzeAndRecommendCourse(_points);
    Navigator.pushNamed(context, '/course_analysis_result');
  }
}