import 'dart:io';
import 'dart:typed_data'; // 이 부분을 수정합니다.
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';
import 'package:new_runaway/features/running/running_provider.dart';
import 'package:new_runaway/features/running/widgets/run_map.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:new_runaway/services/api_service.dart';
import 'package:path_provider/path_provider.dart'; // 이 부분을 추가합니다.
import '../../../utils/logger.dart';

class RunResultScreen extends StatefulWidget {
  final String sessionId;
  final double distance;
  final int duration;
  final double avgPace;
  final double currentPace;
  final List<LatLng> route;
  final String courseId;

  const RunResultScreen({
    Key? key,
    required this.sessionId,
    required this.distance,
    required this.duration,
    required this.avgPace,
    required this.currentPace,
    required this.route,
    required this.courseId,
  }) : super(key: key);

  @override
  _RunResultScreenState createState() => _RunResultScreenState();
}

class _RunResultScreenState extends State<RunResultScreen> {
  int _runningIntensity = 5;
  final ApiService _apiService = ApiService();
  final GlobalKey _globalKey = GlobalKey(); // 글로벌 키 추가

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // 화면이 렌더링 된 후에 필요한 초기 작업을 수행할 수 있습니다.
    });
  }




  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        return await _showExitConfirmationDialog() ?? false;
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          title: const Text('러닝 결과'),
          leading: IconButton(
            icon: const Icon(Icons.home),
            onPressed: _showExitConfirmationDialog,
          ),
        ),
        backgroundColor: Colors.white,
        body: SingleChildScrollView(
          child: Column(
            children: [
              _buildResultItem('날짜', '${DateTime.now().toString().split(' ')[0]}'),
              _buildResultItem('거리', '${widget.distance.toStringAsFixed(2)} km'),
              _buildResultItem('시간', _formatTime(widget.duration)),
              _buildResultItem('평균 페이스', _formatPace(widget.avgPace)),
              Container(
                height: 300,
                child: RunMap(routePoints: widget.route),
              ),
              _buildRunningIntensity(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 18)),
          Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  void _updateIntensity(Offset localPosition, RenderBox box) {
    double localDx = box.globalToLocal(localPosition).dx;
    int newIntensity = ((localDx / box.size.width) * 10).round();
    if (newIntensity < 1) newIntensity = 1;
    if (newIntensity > 10) newIntensity = 10;
    setState(() {
      _runningIntensity = newIntensity;
    });
  }

  Future<String> saveImage(Uint8List bytes, String sessionId) async {
    final directory = await getApplicationDocumentsDirectory();
    final imagePath = '${directory.path}/$sessionId.png';
    File imageFile = File(imagePath);
    await imageFile.writeAsBytes(bytes.toList()); // Uint8List를 List<int>로 변환
    return imagePath;
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

  Widget _buildRunningIntensity() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('러닝 강도', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          GestureDetector(
            onTapUp: (details) {
              RenderBox box = context.findRenderObject() as RenderBox;
              _updateIntensity(details.globalPosition, box);
            },
            onPanUpdate: (details) {
              RenderBox box = context.findRenderObject() as RenderBox;
              _updateIntensity(details.globalPosition, box);
            },
            child: Container(
              height: 100, // 막대의 높이를 늘려 직사각형으로 만듦
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: Colors.grey[300],
              ),
              child: Stack(
                children: [
                  FractionallySizedBox(
                    widthFactor: _runningIntensity / 10,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: _getIntensityColor(_runningIntensity),
                      ),
                    ),
                  ),
                  Center(
                    child: Text(
                      _runningIntensity.toString(),
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 24, // 글자 크기를 키움
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getIntensityColor(int intensity) {
    if (intensity >= 1 && intensity <= 3) {
      return Color(0xFF9FC5FF);
    } else if (intensity >= 4 && intensity <= 6) {
      return Color(0xFF5698FF);
    } else if (intensity >= 7 && intensity <= 9) {
      return Color(0xFF0064FF);
    } else if (intensity == 10) {
      return Color(0xFFFF5200);
    } else {
      return Color(0xFF0064FF); // 기본 색상
    }
  }

  String _formatTime(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  String _formatPace(double pace) {
    final paceInSeconds = pace.toInt();
    final minutes = paceInSeconds ~/ 60;
    final seconds = paceInSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  Future<bool?> _showExitConfirmationDialog() async {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(10.0)), // 모서리를 둥글게 설정
        ),
        title: const Text('러닝 세션 종료'),
        content: const Text('메인 화면으로 돌아가시겠습니까? 이 작업은 러닝 세션을 종료하고 결과를 저장합니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소', style: TextStyle(color: Colors.black),),
          ),
          TextButton(
            onPressed: () async {
              await _endRunningSession();
              Navigator.of(context).pop(true);
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            child: const Text('확인', style: TextStyle(color: Colors.black),),
          ),
        ],
      ),
    );
  }

  Future<void> _endRunningSession() async {
    final Uint8List pngBytes = await _capturePng();
    final imagePath = await saveImage(pngBytes, widget.sessionId);
    final sessionData = {
      "distance": widget.distance,
      "duration": widget.duration,
      "average_pace": widget.avgPace,
      "current_pace": widget.currentPace,
      "route": widget.route.map((point) => {
        "latitude": point.latitude,
        "longitude": point.longitude
      }).toList(),
      "strength": _runningIntensity,
      "course_id": widget.courseId,
      "course_type": 1,  // 다른 사람의 코스로 달렸을 때 1로 설정
    };

    logger.info('Ending running session');
    logger.info('Session ID: ${widget.sessionId}');
    logger.info('Session data: $sessionData');

    try {
      final runningProvider = Provider.of<RunningProvider>(context, listen: false);
      logger.info('Ending running session. Session ID: ${widget.sessionId}, Course ID: ${runningProvider.courseId}');
      await _apiService.endRunningSession(widget.sessionId, sessionData, runningProvider.courseId ?? '');
      logger.info('Successfully ended running session');
      logger.info('Final Course ID sent to server: ${runningProvider.courseId}');
      runningProvider.resetSession();
    } catch (e) {
      logger.severe('Error ending running session: $e');
      // 여기에 에러 처리 로직을 추가할 수 있습니다.
    }
  }
}
