import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' show LatLng;
import 'package:new_runaway/services/api_service.dart';
import '../../utils/logger.dart';

class RunningProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  bool _isRunning = false;
  int _seconds = 0;
  double _distance = 0.0;
  double _avgPace = 0.0;
  double _currentPace = 0.0;
  List<LatLng> _routePoints = [];
  List<LatLng>? _predefinedCourse;
  String? _sessionId;
  String? _courseId;
  List<double> _recentDistances = [];
  List<int> _recentTimes = [];
  final int _recentDataCount = 5; // 현재 페이스 계산을 위한 최근 데이터 개수

  Timer? _timer;
  StreamSubscription<Position>? _positionStream;

  bool get isRunning => _isRunning;
  int get seconds => _seconds;
  double get distance => _distance;
  double get avgPace => _avgPace;
  double get currentPace => _currentPace;
  List<LatLng> get routePoints => _routePoints;
  String? get sessionId => _sessionId;
  List<LatLng>? get predefinedCourse => _predefinedCourse;
  String? get courseId => _courseId;

  void resetSession() {
    logger.info('Resetting session');
    _isRunning = false;
    _seconds = 0;
    _distance = 0.0;
    _avgPace = 0.0;
    _currentPace = 0.0;
    _routePoints = [];
    _sessionId = null;
    _predefinedCourse = null;
    _timer?.cancel();
    _positionStream?.cancel();
    logger.info('Session reset complete');
    notifyListeners();
  }

  Future<void> startRunning({List<LatLng>? predefinedCourse}) async {
    if (_isRunning) return;

    try {
      final response = await _apiService.startRunningSession();
      _sessionId = response['session_id'];
      logger.info('Started running session with ID: $_sessionId');
      logger.info('Starting running session. Course ID: $_courseId');

      _predefinedCourse = predefinedCourse;
      _isRunning = true;
      _startTimer();
      _startLocationTracking();
      notifyListeners();
    } catch (e) {
      logger.severe('Error starting running session: $e');
      resetSession();
    }
  }

  void pauseRunning() {
    _isRunning = false;
    _timer?.cancel();
    _positionStream?.pause();
    notifyListeners();
  }

  void setCourseId(String id) {
    _courseId = id;
    logger.info('Course ID set in RunningProvider: $_courseId');
    notifyListeners();
  }

  void resumeRunning() {
    _isRunning = true;
    _startTimer();
    _positionStream?.resume();
    notifyListeners();
  }

  Future<Map<String, dynamic>> stopRunning() async {
    _isRunning = false;
    _timer?.cancel();
    _positionStream?.cancel();

    final sessionData = {
      "sessionId": _sessionId ?? '',
      "distance": _distance,
      "duration": _seconds,
      "avgPace": _avgPace,
      "currentPace": _currentPace,
      "route": _routePoints,
      "courseId": _courseId,  // courseId 추가
    };

    logger.info('Stopping running session. Data prepared for result screen: $sessionData');
    logger.info('Course ID at session end: $_courseId');

    return sessionData;
  }

  void _startTimer() {
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      _seconds++;
      _updatePace();
      notifyListeners();
    });
  }

  void _startLocationTracking() {
    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
      ),
    ).listen((Position position) {
      if (_routePoints.isNotEmpty) {
        final lastPoint = _routePoints.last;
        final newPoint = LatLng(position.latitude, position.longitude);
        final distance = Geolocator.distanceBetween(
          lastPoint.latitude, lastPoint.longitude,
          newPoint.latitude, newPoint.longitude,
        );
        _distance += distance / 1000;

        // 최근 거리 데이터 업데이트
        _recentDistances.add(distance);
        if (_recentDistances.length > _recentDataCount) {
          _recentDistances.removeAt(0);
        }

        // 최근 시간 데이터 업데이트
        _recentTimes.add(1); // 위치 업데이트 간격을 1초로 가정
        if (_recentTimes.length > _recentDataCount) {
          _recentTimes.removeAt(0);
        }
      }
      _routePoints.add(LatLng(position.latitude, position.longitude));
      _updatePace();
      notifyListeners();
    });
  }

  void _updatePace() {
    if (_distance > 0) {
      // 평균 페이스 계산 (분/km)
      _avgPace = _seconds / (_distance / 1000);

      // 현재 페이스 계산
      if (_recentDistances.length >= _recentDataCount) {
        double recentDistance = _recentDistances.reduce((a, b) => a + b);
        int recentTime = _recentTimes.reduce((a, b) => a + b);
        _currentPace = recentTime / (recentDistance / 1000);
      }
    }
  }

  String formatPace(double pace) {
    if (pace.isInfinite || pace.isNaN) return '00:00';
    final minutes = pace ~/ 60;
    final seconds = (pace % 60).toInt();
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}
