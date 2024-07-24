import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:new_runaway/config/app_config.dart';
import 'package:new_runaway/services/api_service.dart';
import 'package:new_runaway/services/token_service.dart';
import 'package:new_runaway/services/storage_service.dart';
import 'package:new_runaway/utils/logger.dart';
import 'package:new_runaway/features/courses/screens/course_drawing_screen.dart';
import 'package:new_runaway/features/running/screens/running_session_screen.dart';
import 'package:new_runaway/features/stats/widgets/period_selector.dart';
import 'package:new_runaway/features/stats/widgets/stats_bar_chart.dart';
import 'package:new_runaway/features/running/running_provider.dart';
import 'package:new_runaway/models/running_session.dart';
import 'package:new_runaway/services/api_service.dart';
import 'package:new_runaway/services/storage_service.dart';

import 'all_runs_screen.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({Key? key}) : super(key: key);

  @override
  _StatsScreenState createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _showRunningButtons = true;
  String _selectedPeriod = '년';
  DateTime _selectedDate = DateTime.now();

  double _totalDistance = 0;
  int _totalDuration = 0;
  double _averagePace = 0;
  int _totalRuns = 0;
  double _averageDistance = 0;

  final ApiService _apiService = ApiService();
  final StorageService _storageService = StorageService();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
    _fetchStats();
  }

  void _scrollListener() {
    if (_scrollController.offset > 100 && _showRunningButtons) {
      setState(() => _showRunningButtons = false);
    } else if (_scrollController.offset <= 100 && !_showRunningButtons) {
      setState(() => _showRunningButtons = true);
    }
  }

  Future<void> _fetchStats() async {
    try {
      final userId = await _storageService.getUserId();
      if (userId == null) {
        throw Exception('User ID not found');
      }
      final response = await _apiService.getStats(_selectedPeriod, userId);
      print('API response: $response'); // 디버깅을 위한 로깅

      setState(() {
        _totalDistance = response[_selectedPeriod == '전체' ? 'totally' : _selectedPeriod.toLowerCase()]['distance'];
        _totalDuration = response[_selectedPeriod == '전체' ? 'totally' : _selectedPeriod.toLowerCase()]['duration'];
        _averagePace = response[_selectedPeriod == '전체' ? 'totally' : _selectedPeriod.toLowerCase()]['average_pace'];
        _totalRuns = response[_selectedPeriod == '전체' ? 'totally' : _selectedPeriod.toLowerCase()]['count'];
        _averageDistance = _totalRuns == 0 ? 0 : _totalDistance / _totalRuns;
      });
    } catch (e) {
      // 에러 핸들링
      print('통계 정보를 가져오지 못했습니다: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ApiService>(
      builder: (context, apiService, child) {
        return Scaffold(
          backgroundColor: Colors.white,
          body: Stack(
            children: [
              SafeArea(
                child: CustomScrollView(
                  controller: _scrollController,
                  slivers: [
                    SliverToBoxAdapter(child: _buildTotalStats()),
                    SliverToBoxAdapter(
                      child: PeriodSelector(
                        initialPeriod: _selectedPeriod,
                        onPeriodSelected: (period) {
                          setState(() {
                            _selectedPeriod = period;
                            _fetchStats(); // 새로운 기간 선택 시 데이터 가져오기
                          });
                        },
                      ),
                    ),
                    if (_selectedPeriod != '전체' && _selectedPeriod != '주')
                      SliverToBoxAdapter(child: _buildDateFilter()),
                    SliverToBoxAdapter(child: _buildStatsChart()),
                    SliverToBoxAdapter(child: _buildCourseStatistics()),
                    SliverToBoxAdapter(child: _buildRecentRuns(context, apiService)),
                    SliverToBoxAdapter(child: _buildMyDrawnCourses()),
                  ],
                ),
              ),
              _buildRunningButtons(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTotalStats() {
    return Container(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '총 킬로미터',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          Row(
            children: [
              Text(
                _totalDistance.toStringAsFixed(2),
                style: TextStyle(
                  height: 1.2,
                  fontSize: 50,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Giants',
                  fontStyle: FontStyle.italic,
                ),
              ),
              SizedBox(width: 6),
              Baseline(
                baseline: 45,
                baselineType: TextBaseline.alphabetic,
                child: Text(
                  'km',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Text(
            '총 시간',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          Text(
            _formatDuration(_totalDuration),
            style: TextStyle(
              height: 1.2,
              fontSize: 50,
              fontWeight: FontWeight.bold,
              fontFamily: 'Giants',
              fontStyle: FontStyle.italic,
            ),
          ),
          SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '평균 페이스',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    _formatPace(_averagePace),
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '평균 거리',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '${_averageDistance.toStringAsFixed(2)} km',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '총 런닝 횟수',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '$_totalRuns 회',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }


  Widget _buildDateFilter() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Text(_selectedPeriod == '월간' ? '월 선택: ' : '년 선택: '),
          TextButton(
            onPressed: () async {
              final DateTime? picked = await showDatePicker(
                context: context,
                initialDate: _selectedDate,
                firstDate: DateTime(2000),
                lastDate: DateTime.now(),
              );
              if (picked != null && picked != _selectedDate) {
                setState(() {
                  _selectedDate = picked;
                });
              }
            },
            child: Text(
              _selectedPeriod == '월간'
                  ? '${_selectedDate.year}년 ${_selectedDate.month}월'
                  : '${_selectedDate.year}년',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsChart() {
    return Container(
      height: 200,
      padding: EdgeInsets.all(16),
      child: StatsBarChart(
        selectedPeriod: _selectedPeriod,
        selectedDate: _selectedDate,
      ),
    );
  }

  Widget _buildCourseStatistics() {
    return Container(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('코스 통계', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildCourseStatItem('코스 그리기로 달린 횟수', '15'),
              _buildCourseStatItem('코스 추천으로 달린 횟수', '8'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCourseStatItem(String label, String value) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        Text(label, style: TextStyle(fontSize: 14, color: Colors.grey)),
      ],
    );
  }

  Widget _buildRecentRuns(BuildContext context, ApiService apiService) {
    return Container(
      padding: EdgeInsets.all(16),
      child: FutureBuilder<String?>(
        future: StorageService().getUserId(),
        builder: (context, userIdSnapshot) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('최근 러닝', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => AllRunsScreen()),
                      );
                    },
                    child: Text('더보기'),
                  ),
                ],
              ),
              SizedBox(height: 10),
              if (!userIdSnapshot.hasData || userIdSnapshot.data == null)
                _buildEmptyRecentRuns()
              else
                _buildRecentRunsList(context, apiService, userIdSnapshot.data!),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyRecentRuns() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('최근 러닝', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        SizedBox(height: 10),
        Text('최근 러닝 기록이 없습니다.'),
      ],
    );
  }

  Widget _buildRecentRunsList(BuildContext context, ApiService apiService, String userId) {
    return FutureBuilder<List<RunningSession>>(
      future: apiService.getRecentRuns(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingRecentRuns();
        } else if (snapshot.hasError) {
          return _buildErrorRecentRuns(snapshot.error.toString());
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildEmptyRecentRuns();
        } else {
          return Column(
            children: snapshot.data!.take(3).map((run) => _buildRecentRunItem(
              run.date.toString().substring(0, 10),
              '${run.distance.toStringAsFixed(2)} km',
              _formatDuration(run.duration),
              _formatPace(run.averagePace),
              run.strength,
            )).toList(),
          );
        }
      },
    );
  }

  Widget _buildRecentRunItem(String date, String distance, String time, String pace, int strength) {
    String badgeImage;
    if (strength >= 1 && strength <= 3) {
      badgeImage = 'assets/images/strength1-3.png';
    } else if (strength >= 4 && strength <= 6) {
      badgeImage = 'assets/images/strength4-6.png';
    } else if (strength >= 7 && strength <= 9) {
      badgeImage = 'assets/images/strength7-9.png';
    } else if (strength == 10) {
      badgeImage = 'assets/images/strength10.png';
    } else {
      badgeImage = ''; // 기본값을 설정하거나 필요에 따라 다르게 처리
    }

    return Container(
      margin: EdgeInsets.only(bottom: 10),
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          Row(
            children: [
              // 컨테이너는 코스 이미지로 추후에 대체
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(date, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                    SizedBox(height: 5),
                    Text('총 킬로미터', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    Text(
                      distance,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 19,
                        fontFamily: 'Giants',
                        height: 1.2, // 위아래 자간 설정
                      ),
                    ),
                    SizedBox(height: 5),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('시간', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            Text(time, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, height: 1.2,))
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('평균 페이스', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            Text(pace, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, height: 1.2)),
                          ],
                        ),
                        SizedBox(width: 13), // 평균 페이스를 왼쪽으로 이동시키기 위해 간격 조정
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          Positioned(
            top: 0,
            right: 0,
            child: Image.asset(
              badgeImage, // 뱃지 이미지 경로
              width: 45,
              height: 45,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMyDrawnCourses() {
    return Container(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('내가 그린 코스', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(5, (index) => _buildCourseItem(index)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCourseItem(int index) {
    return Padding(
      padding: const EdgeInsets.only(right: 10.0),
      child: Column(
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          SizedBox(height: 5),
          Text(
            // '${index + 1}234명', // 이 텍스트는 각 항목에 고유한 인덱스를 추가하여 다르게 표시할 수 있습니다.
            '1111명',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRunningButtons() {
    return Consumer<RunningProvider>(
      builder: (context, runningProvider, child) {
        return Positioned(
          bottom: 20,
          left: 20,
          right: 20,
          child: AnimatedOpacity(
            opacity: _showRunningButtons ? 1.0 : 0.0,
            duration: Duration(milliseconds: 200),
            child: IgnorePointer(
              ignoring: !_showRunningButtons,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  if (runningProvider.isRunning)
                    InkWell(
                      onTap: _showRunningButtons ? () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => RunningSessionScreen(showCountdown: false)),
                        );
                      } : null,
                      child: Image.asset(
                        'assets/images/start_run_btn.png',
                        width: 100,
                        height: 100,
                      ),
                    )
                  else
                    ...[
                      InkWell(
                        onTap: _showRunningButtons ? () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => CourseDrawingScreen()),
                          );
                        } : null,
                        child: Image.asset(
                          'assets/images/map_drawing_btn.png',
                          width: 100,
                          height: 100,
                        ),
                      ),
                      InkWell(
                        onTap: _showRunningButtons ? () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => RunningSessionScreen()),
                          );
                        } : null,
                        child: Image.asset(
                          'assets/images/start_run_btn.png',
                          width: 100,
                          height: 100,
                        ),
                      ),
                    ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _formatDuration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  String _formatPace(double paceInSeconds) {
    final minutes = paceInSeconds ~/ 60;
    final seconds = (paceInSeconds % 60).toInt();
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  Widget _buildLoadingRecentRuns() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('최근 러닝', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        SizedBox(height: 10),
        Center(child: CircularProgressIndicator()),
      ],
    );
  }

  Widget _buildErrorRecentRuns(String error) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('최근 러닝', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        SizedBox(height: 10),
        Text('Error: $error'),
      ],
    );
  }

}
