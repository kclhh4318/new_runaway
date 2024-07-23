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

  void resetSession() {
    logger.info('Resetting session');
    _isRunning = false;
    _seconds = 0;
    _distance = 0.0;
    _avgPace = 0.0;
    _currentPace = 0.0;
    _routePoints = [];
    _sessionId = null;
    _predefinedCourse = null;  // 이 줄을 추가합니다
    _timer?.cancel();
    _positionStream?.cancel();
    logger.info('Session reset complete');
  }

  Future<void> startRunning({List<LatLng>? predefinedCourse}) async {
    if (_isRunning) return;

    try {
      final response = await _apiService.startRunningSession();
      _sessionId = response['session_id'];
      logger.info('Started running session with ID: $_sessionId');

      _predefinedCourse = predefinedCourse;  // 이 줄을 추가합니다
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

  void resumeRunning() {
    _isRunning = true;
    _startTimer();
    _positionStream?.resume();
    notifyListeners();
  }

  Future<void> stopRunning() async {
    if (!_isRunning || _sessionId == null) return;

    _isRunning = false;
    _timer?.cancel();
    _positionStream?.cancel();

    final sessionData = {
      "distance": _distance,
      "seconds": _seconds,
      "avgPace": _avgPace,
      "currentPace": _currentPace,
      "routePoints": _routePoints.map((point) => {
        "latitude": point.latitude,
        "longitude": point.longitude
      }).toList(),
    };

    try {
      print('Attempting to end running session with ID: $_sessionId'); // 디버그용 로그
      await _apiService.endRunningSession(_sessionId!, sessionData);
      print('Successfully ended running session'); // 디버그용 로그
    } catch (e) {
      print('Error ending running session: $e');
    }

    resetSession();
    notifyListeners();
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
      }
      _routePoints.add(LatLng(position.latitude, position.longitude));
      _updatePace();
      notifyListeners();
    });
  }

  void _updatePace() {
    if (_distance > 0) {
      _avgPace = _seconds / _distance / 60; // minutes per km
      if (_routePoints.length >= 2) {
        final lastTwoPoints = _routePoints.sublist(_routePoints.length - 2);
        final lastDistance = Geolocator.distanceBetween(
          lastTwoPoints[0].latitude, lastTwoPoints[0].longitude,
          lastTwoPoints[1].latitude, lastTwoPoints[1].longitude,
        );
        _currentPace = (1 / (lastDistance / 1000)) / 60; // minutes per km
      }
    }
  }

  Future<void> endRunningSession({
    required double distance,
    required int duration,
    required double avgPace,
    required List<LatLng> route,
  }) async {
    logger.info('Entering endRunningSession method');
    logger.info('Session ID: $_sessionId');
    logger.info('Distance: $distance, Duration: $duration, AvgPace: $avgPace, Route points: ${route.length}');

    if (_sessionId == null) {
      logger.warning('Session ID is null. Cannot end session.');
      return;
    }

    final sessionData = {
      "distance": distance,
      "seconds": duration,
      "avgPace": avgPace,
      "routePoints": route.map((point) => {
        "latitude": point.latitude,
        "longitude": point.longitude
      }).toList(),
    };

    logger.info('Prepared session data: $sessionData');

    try {
      logger.info('Attempting to end running session with ID: $_sessionId');
      await _apiService.endRunningSession(_sessionId!, sessionData);
      logger.info('Successfully ended running session');
    } catch (e) {
      logger.severe('Error ending running session: $e');
    } finally {
      resetSession();
      notifyListeners();
    }
  }

  String formatPace(double pace) {
    if (pace.isInfinite || pace.isNaN) return '00:00';
    final minutes = pace.toInt();
    final seconds = ((pace - minutes) * 60).toInt();
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}