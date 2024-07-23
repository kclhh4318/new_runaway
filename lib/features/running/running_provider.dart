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

  void resumeRunning() {
    _isRunning = true;
    _startTimer();
    _positionStream?.resume();
    notifyListeners();
  }

  Future<Map<String, dynamic>> stopRunning() async {
    if (!_isRunning || _sessionId == null) return {};

    _isRunning = false;
    _timer?.cancel();
    _positionStream?.cancel();

    final sessionData = {
      "sessionId": _sessionId,
      "distance": _distance,
      "duration": _seconds,
      "avgPace": _avgPace,
      "currentPace": _currentPace,
      "route": _routePoints,
    };

    logger.info('Stopping running session. Data prepared for result screen: $sessionData');

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

  String formatPace(double pace) {
    if (pace.isInfinite || pace.isNaN) return '00:00';
    final minutes = pace.toInt();
    final seconds = ((pace - minutes) * 60).toInt();
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}
