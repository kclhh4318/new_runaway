import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:new_runaway/config/app_config.dart';
import 'package:new_runaway/services/api_service.dart';
import 'package:new_runaway/services/storage_service.dart';
import 'package:new_runaway/features/courses/screens/course_drawing_screen.dart';
import 'package:new_runaway/features/running/screens/running_session_screen.dart';
import 'package:new_runaway/features/stats/widgets/period_selector.dart';
import 'package:new_runaway/features/stats/widgets/stats_bar_chart.dart';
import 'package:new_runaway/features/running/running_provider.dart';
import 'package:new_runaway/models/running_session.dart';
import 'package:new_runaway/models/course.dart';
import 'package:new_runaway/models/stats.dart';
import 'package:new_runaway/widgets/course_painter.dart';
import '../../../services/auth_service.dart';
import '../../onboarding/screens/start_page.dart';
import 'all_runs_screen.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({Key? key}) : super(key: key);

  @override
  _StatsScreenState createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _showRunningButtons = true;
  String _selectedPeriod = '전체';
  DateTime _selectedDate = DateTime.now();
  String? userId;

  Stats? _statsData;
  List<RunningSession> _recentRuns = [];
  List<Course> _myDrawnCourses = [];

  final ApiService _apiService = ApiService();
  final StorageService _storageService = StorageService();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
    _loadUserId();
    _fetchAllData();
  }

  Future<void> _loadUserId() async {
    final id = await _storageService.getUserId();
    setState(() {
      userId = id;
    });
  }

  void _scrollListener() {
    if (_scrollController.offset > 100 && _showRunningButtons) {
      setState(() => _showRunningButtons = false);
    } else if (_scrollController.offset <= 100 && !_showRunningButtons) {
      setState(() => _showRunningButtons = true);
    }
  }

  Future<void> _fetchAllData() async {
    try {
      final userId = await _storageService.getUserId();
      if (userId == null) {
        throw Exception('User ID not found');
      }

      final stats = await _apiService.getStats(_selectedPeriod, userId);
      final recentRuns = await _apiService.getRecentRuns(userId);
      final myDrawnCourses = await _apiService.getMyDrawnCourses(userId);

      setState(() {
        _statsData = Stats.fromJson(stats[_selectedPeriod == '전체' ? 'totally' : _selectedPeriod.toLowerCase()]);
        _recentRuns = recentRuns;
        _myDrawnCourses = myDrawnCourses;
      });
    } catch (e) {
      print('Error fetching data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ApiService>(
      builder: (context, apiService, child) {
        return Scaffold(
          appBar: AppBar(
            title: Text('통계'),
            backgroundColor: Colors.white,
            actions: [
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'logout') {
                    _logout();
                  }
                },
                itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                  PopupMenuItem<String>(
                    value: 'logout',
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,

                      ),
                      child: Text('로그아웃'),
                    ),
                  ),
                ],
              ),
            ],
          ),
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
                            _fetchAllData();
                          });
                        },
                      ),
                    ),
                    if (_selectedPeriod != '전체' && _selectedPeriod != '주')
                      SliverToBoxAdapter(child: _buildDateFilter()),
                    SliverToBoxAdapter(child: _buildStatsChart()),
                    SliverToBoxAdapter(child: _buildRecentRuns()),
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
    if (_statsData == null) {
      return Center(child: CircularProgressIndicator());
    }

    return Container(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('총 킬로미터', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          Text(
            '${_statsData!.distance.toStringAsFixed(2)} km',
            style: TextStyle(fontSize: 50, fontWeight: FontWeight.bold, fontFamily: 'Giants', fontStyle: FontStyle.italic),
          ),
          SizedBox(height: 16),
          Text('총 시간', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          Text(
            _formatDuration(_statsData!.duration),
            style: TextStyle(fontSize: 50, fontWeight: FontWeight.bold, fontFamily: 'Giants', fontStyle: FontStyle.italic),
          ),
          SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatItem('평균 페이스', _formatPace(_statsData!.averagePace)),
              _buildStatItem('평균 거리', '${(_statsData!.distance / _statsData!.count).toStringAsFixed(2)} km'),
              _buildStatItem('총 런닝 횟수', '${_statsData!.count} 회'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ],
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
        userId: userId ?? '',
      ),
    );
  }

  Widget _buildRecentRuns() {
    return Container(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('최근 러닝', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              TextButton(
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => AllRunsScreen()));
                },
                child: Text('더보기'),
              ),
            ],
          ),
          SizedBox(height: 10),
          Column(
            children: _recentRuns.take(3).map((run) => _buildRecentRunItem(run)).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentRunItem(RunningSession run) {
    return Container(
      margin: EdgeInsets.only(bottom: 10),
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: Row(
        children: [
          Container(
            width: 100,
            height: 100,
            child: CustomPaint(
              painter: CoursePainter(run.route ?? []),
              size: Size(100, 100),
            ),
          ),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(run.date.toString().split(' ')[0], style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                Text('총 킬로미터', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                Text('${run.distance.toStringAsFixed(2)} km', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 19, fontFamily: 'Giants', height: 1.2)),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('시간', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        Text(_formatDuration(run.duration), style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, height: 1.2)),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('평균 페이스', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        Text(_formatPace(run.averagePace), style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, height: 1.2)),
                      ],
                    ),
                  ],
                ),
              ],
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
              children: _myDrawnCourses.map((course) => _buildCourseItem(course)).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCourseItem(Course course) {
    List<LatLng> routePoints = _convertToLatLngList(course.routeCoordinate);
    return Padding(
      padding: const EdgeInsets.only(right: 10.0),
      child: Column(
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.blue),
            ),
            child: CustomPaint(
              painter: CoursePainter(routePoints),
              size: Size(100, 100),
            ),
          ),
          SizedBox(height: 5),
          Text(
            '${course.recommendationCount ?? 0}명',
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.normal),
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

  List<LatLng> _convertToLatLngList(Map<String, dynamic>? routeCoordinate) {
    if (routeCoordinate == null || !routeCoordinate.containsKey('coordinates')) {
      return [];
    }

    List<dynamic> coordinates = routeCoordinate['coordinates'];
    return coordinates.map((point) {
      if (point is List && point.length >= 2) {
        return LatLng(point[1], point[0]);
      }
      return LatLng(0, 0);
    }).toList();
  }

  Future<void> _logout() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final success = await authService.logout();
    if (success) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => StartPage()),
            (Route<dynamic> route) => false,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('로그아웃에 실패했습니다. 다시 시도해주세요.')),
      );
    }
  }
}