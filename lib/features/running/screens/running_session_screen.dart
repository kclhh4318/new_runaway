import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:new_runaway/features/running/running_provider.dart';
import 'package:new_runaway/features/running/widgets/countdown_timer.dart';
import 'package:new_runaway/features/running/widgets/running_stats_display.dart';
import 'package:new_runaway/features/running/widgets/pause_stop_button.dart';
import 'package:new_runaway/features/running/widgets/run_map.dart';
import 'package:new_runaway/features/running/screens/run_result_screen.dart';

class RunningSessionScreen extends StatefulWidget {
  const RunningSessionScreen({Key? key}) : super(key: key);

  @override
  _RunningSessionScreenState createState() => _RunningSessionScreenState();
}

class _RunningSessionScreenState extends State<RunningSessionScreen> {
  bool _showCountdown = true;
  bool _showMap = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                    ? RunMap(routePoints: runningProvider.routePoints)
                    : Column(
                  children: [
                    RunningStatsDisplay(
                      isRunning: runningProvider.isRunning,
                      seconds: runningProvider.seconds,
                      distance: runningProvider.distance,
                      avgPace: runningProvider.avgPace,
                      currentPace: runningProvider.currentPace,
                    ),
                    Expanded(child: Container()),
                    PauseStopButton(
                      isRunning: runningProvider.isRunning,
                      onPause: runningProvider.pauseRunning,
                      onResume: runningProvider.resumeRunning,
                      onStop: _stopRunning,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _startRunning() {
    setState(() {
      _showCountdown = false;
    });
    context.read<RunningProvider>().startRunning();
  }

  void _stopRunning() {
    context.read<RunningProvider>().stopRunning();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const RunResultScreen(),
      ),
    );
  }
}