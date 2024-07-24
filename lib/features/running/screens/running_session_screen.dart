import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:logging/logging.dart';
import 'package:provider/provider.dart';
import 'package:new_runaway/features/running/running_provider.dart';
import 'package:new_runaway/features/running/widgets/run_map.dart';
import 'package:new_runaway/features/running/screens/run_result_screen.dart';
import 'package:new_runaway/features/running/widgets/countdown_timer.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:async';
import 'package:logging/logging.dart';

class RunningSessionScreen extends StatefulWidget {
  final bool showCountdown;
  final List<LatLng>? predefinedCourse;

  const RunningSessionScreen({
    Key? key,
    this.showCountdown = true,
    this.predefinedCourse,
  }) : super(key: key);

  @override
  _RunningSessionScreenState createState() => _RunningSessionScreenState();
}

class _RunningSessionScreenState extends State<RunningSessionScreen> {
  bool _showMap = false;
  late bool _showCountdown;
  final logger = Logger('RunningSessionScreen');
  Timer? _logTimer;

  @override
  void initState() {
    super.initState();
    _startPeriodicLogging();
    _showCountdown = widget.showCountdown;
    if (!_showCountdown) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _startRunning();
      });
    }
    // 상단바 숨기기
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: []);
  }

  void _startPeriodicLogging() {
    _logTimer = Timer.periodic(Duration(minutes: 1), (timer) {
      if (mounted) {
        final runningProvider = Provider.of<RunningProvider>(context, listen: false);
        logger.info('Periodic log - Course ID: ${runningProvider.courseId}');
      }
    });
  }


  @override
  void dispose() {
    // 상단바 복원
    _logTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.of(context).pop();
        return false;
      },
      child: Scaffold(
/*        appBar: AppBar(
          title: Text('러닝'),
          leading: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ),*/
        body: SafeArea(
          child: _showCountdown
              ? CountdownTimer(onFinished: _startRunning)
              : Consumer<RunningProvider>(
            builder: (context, runningProvider, child) {
              return GestureDetector(
                onHorizontalDragEnd: (details) {
                  if (details.primaryVelocity! < 0) {
                    setState(() {
                      _showMap = true;
                    });
                  } else if (details.primaryVelocity! > 0) {
                    setState(() {
                      _showMap = false;
                    });
                  }
                },
                child: AnimatedSwitcher(
                  duration: Duration(milliseconds: 300),
                  child: _showMap
                      ? RunMap(
                    routePoints: runningProvider.routePoints,
                    predefinedCourse: runningProvider.predefinedCourse,
                  )
                      : _buildRunningStats(runningProvider),
                ),
              );
            },
          ),
        ),
      ),
    );
  }


  void _startRunning() {
    setState(() {
      _showCountdown = false;
    });
    context.read<RunningProvider>().startRunning(predefinedCourse: widget.predefinedCourse);
  }

  Widget _buildRunningStats(RunningProvider provider) {
    return Container(
      color: Color(0xFF0064FF),
      padding: EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildPaceInfo(provider),
          _buildTimeAndDistance(provider),
          _buildControlButton(provider),
        ],
      ),
    );
  }

  Widget _buildPaceInfo(RunningProvider provider) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildPaceItem('평균 페이스', provider.formatPace(provider.avgPace)),
        _buildPaceItem('현재 페이스', provider.formatPace(provider.currentPace)),
      ],
    );
  }

  Widget _buildPaceItem(String label, String value) {
    return Column(
      children: [
        Text(label, style: TextStyle(color: Colors.black87, fontSize: 16)),
        Text(value, style: TextStyle(color: Colors.black, fontSize: 24, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildTimeAndDistance(RunningProvider provider) {
    return Column(
      children: [
        Text('시간', style: TextStyle(color: Colors.black, fontSize: 20)),
        Text(
          _formatTime(provider.seconds),
          style: TextStyle(color: Colors.black, fontSize: 64, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 20),
        Text('달린 거리', style: TextStyle(color: Colors.black, fontSize: 20)),
        Text(
          '${provider.distance.toStringAsFixed(2)}',
          style: TextStyle(color: Colors.black, fontSize: 64, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildControlButton(RunningProvider provider) {
    return GestureDetector(
      onTap: provider.isRunning ? provider.pauseRunning : provider.resumeRunning,
      onLongPress: () => _stopRunning(provider),
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.black,
        ),
        child: Icon(
          provider.isRunning ? Icons.pause : Icons.play_arrow,
          size: 50,
          color: Color(0xFF0064FF),
        ),
      ),
    );
  }



  String _formatTime(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  Future<void> _stopRunning(RunningProvider provider) async {
    final sessionData = await provider.stopRunning();
    if (sessionData['sessionId'] != null && sessionData['sessionId'].isNotEmpty) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => RunResultScreen(
            sessionId: sessionData['sessionId'],
            distance: sessionData['distance'],
            duration: sessionData['duration'],
            avgPace: sessionData['avgPace'],
            currentPace: sessionData['currentPace'],
            route: sessionData['route'],
            courseId: sessionData['courseId'],  // courseId 추가
          ),
        ),
      );
    } else {
      // sessionId가 없는 경우 처리
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('러닝 세션을 종료할 수 없습니다. 다시 시도해주세요.')),
      );
      // 세션 리셋
      provider.resetSession();
    }
  }
}

