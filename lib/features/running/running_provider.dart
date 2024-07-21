import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mapbox_gl/mapbox_gl.dart';

class RunningProvider with ChangeNotifier {
  bool _isRunning = false;
  int _seconds = 0;
  double _distance = 0.0;
  double _avgPace = 0.0;
  double _currentPace = 0.0;
  List<LatLng> _routePoints = [];

  Timer? _timer;
  StreamSubscription<Position>? _positionStream;

  bool get isRunning => _isRunning;
  int get seconds => _seconds;
  double get distance => _distance;
  double get avgPace => _avgPace;
  double get currentPace => _currentPace;
  List<LatLng> get routePoints => _routePoints;

  void startRunning() {
    _isRunning = true;
    _startTimer();
    _startLocationTracking();
    notifyListeners();
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

  void stopRunning() {
    _isRunning = false;
    _timer?.cancel();
    _positionStream?.cancel();
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
      locationSettings: LocationSettings(
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
        _distance += distance / 1000; // Convert to km
      }
      _routePoints.add(LatLng(position.latitude, position.longitude));
      _updatePace();
      notifyListeners();
    });
  }

  void _updatePace() {
    if (_distance > 0) {
      final avgPaceSeconds = (_seconds / _distance);
      _avgPace = avgPaceSeconds;

      if (_routePoints.length >= 2) {
        final lastTwoPoints = _routePoints.sublist(_routePoints.length - 2);
        final lastDistance = Geolocator.distanceBetween(
          lastTwoPoints[0].latitude, lastTwoPoints[0].longitude,
          lastTwoPoints[1].latitude, lastTwoPoints[1].longitude,
        );
        final currentPaceSeconds = (1 / (lastDistance / 1000));
        _currentPace = currentPaceSeconds;
      }
    }
  }

  String _formatPace(double pace) {
    final paceInSeconds = pace.toInt();
    final minutes = paceInSeconds ~/ 60;
    final remainingSeconds = paceInSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }
}
