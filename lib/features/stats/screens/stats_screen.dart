import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:new_runaway/models/stats.dart';
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
import 'package:new_runaway/widgets/course_painter.dart';
import '../../../models/course.dart';
import '../../../services/auth_service.dart';
import '../../../utils/logger.dart';
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
  final StorageService _storageService = StorageService();
  String? userId;
  String _username = '';

  double _totalDistance = 0;
  int _totalDuration = 0;
  double _averagePace = 0;
  int _totalRuns = 0;
  double _averageDistance = 0;
  String _userId = '';

  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
    _fetchStats();
    _fetchUserId();
    _loadUserId();
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

  Future<void> _fetchStats() async {
    try {
      final userId = await _storageService.getUserId();
      if (userId == null) {
        throw Exception('User ID not found');
      }
      final response = await _apiService.getStats(_selectedPeriod, userId);
      print('API response: $response'); // 디버깅을 위한 로깅

      final statsKey = _selectedPeriod == '전체' ? 'totally' : (_selectedPeriod == '주' ? 'weekly' : (_selectedPeriod == '월' ? 'monthly' : 'yearly'));
      if (!response.containsKey(statsKey) || response[statsKey] == null) {
        // 통계를 사용할 수 없는 경우 기본 값을 사용합니다.
        setState(() {
          _totalDistance = 0;
          _totalDuration = 0;
          _averagePace = 0;
          _totalRuns = 0;
          _averageDistance = 0;
        });
        return;
      }

      final statsData = response[statsKey];
      print('Stats data: $statsData'); // 디버깅을 위한 로깅

      final stats = Stats.fromJson(statsData ?? {});
      print('Parsed stats: $stats'); // 디버깅을 위한 로깅

      setState(() {
        _totalDistance = stats.distance;
        _totalDuration = stats.duration;
        _averagePace = stats.averagePace;
        _totalRuns = stats.count;
        _averageDistance = _totalRuns == 0 ? 0 : _totalDistance / _totalRuns;
        print('State updated:');
        print('_totalDistance: $_totalDistance');
        print('_totalDuration: $_totalDuration');
        print('_averagePace: _averagePace');
        print('_totalRuns: _totalRuns');
        print('_averageDistance: _averageDistance');
      });
    } catch (e) {
      // 에러 핸들링
      print('통계 정보를 가져오지 못했습니다: $e');
    }
  }

  Future<void> _fetchUserId() async {
    final userId = await _storageService.getUserId();
    setState(() {
      _userId = userId ?? '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ApiService>(
      builder: (context, apiService, child) {
        return Scaffold(
          appBar: AppBar(
            title: Text('통계'),
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            actions: [
              PopupMenuButton<String>(
                onSelected: (value) async {
                  if (value == 'logout') {
                    await _logout();
                  }
                },
                itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                  PopupMenuItem<String>(
                    value: 'profile',
                    child: Text('프로필: $_username'),
                  ),
                  PopupMenuItem<String>(
                    value: 'logout',
                    child: Text('로그아웃'),
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
                            print('Selected period: $_selectedPeriod');
                            _fetchStats();
                          });
                        },
                      ),
                    ),
                    if (_selectedPeriod != '전체' && _selectedPeriod != '주')
                      SliverToBoxAdapter(child: _buildDateFilter()),
                    SliverToBoxAdapter(
                      child: Container(
                        height: 200,
                        padding: EdgeInsets.all(16),
                        child: StatsBarChart(
                          selectedPeriod: _selectedPeriod,
                          selectedDate: _selectedDate,
                          userId: _userId,
                        ),
                      ),
                    ),
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
        userId: _userId,
      ),
    );
  }

  Widget _buildCourseStatistics() {
    return FutureBuilder<String?>(
      future: StorageService().getUserId(),
      builder: (context, userIdSnapshot) {
        if (!userIdSnapshot.hasData || userIdSnapshot.data == null) {
          return Center(child: Text('User ID not found'));
        }

        return FutureBuilder<Map<String, int>>(
          future: _fetchCourseStatistics(userIdSnapshot.data!),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('데이터가 없습니다. 지금 당장 런닝을 시작해보세요!', style: TextStyle(fontSize: 16)));
            } else {
              final data = snapshot.data!;
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
                        _buildCourseStatItem('코스 그리기로 달린 횟수', data['drawCourseCount'].toString()),
                        _buildCourseStatItem('코스 추천으로 달린 횟수', data['recommendedCourseCount'].toString()),
                      ],
                    ),
                  ],
                ),
              );
            }
          },
        );
      },
    );
  }

  Future<void> _logout() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    await authService.logout();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => StartPage()),
          (Route<dynamic> route) => false,
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
            children: snapshot.data!.take(3).map((run) => _buildRecentRunItem(run)).toList(),
          );
        }
      },
    );
  }

  Widget _buildRecentRunItem(RunningSession run) {
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
              Container(
                width: 100,
                height: 100,
                child: run.route != null && run.route!.isNotEmpty
                    ? CustomPaint(
                  painter: CoursePainter(run.route!),
                  size: Size(100, 100),
                )
                    : Container(color: Colors.grey[300]),
              ),
              SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(run.date.toString().split(' ')[0], style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                    SizedBox(height: 5),
                    Text('총 킬로미터', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    Text(
                      '${run.distance.toStringAsFixed(2)} km',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 19,
                        fontFamily: 'Giants',
                        height: 1.2,
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
                            Text(_formatDuration(run.duration), style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, height: 1.2,))
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('평균 페이스', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            Text(_formatPace(run.averagePace), style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, height: 1.2)),
                          ],
                        ),
                        SizedBox(width: 13),
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
              _getStrengthBadgeImage(run.strength),
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
          FutureBuilder<List<Course>>(
            future: _apiService.getMyDrawnCourses(userId ?? ''),
            builder: (context, snapshot) {
              logger.info('Fetching drawn courses for user ID: $userId');

              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                logger.severe('Error fetching drawn courses: ${snapshot.error}');
                return Text('에러가 발생했습니다: ${snapshot.error}');
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                logger.info('No drawn courses found for user ID: $userId');
                return Text('아직 그린 코스가 없습니다.');
              } else {
                logger.info('Fetched ${snapshot.data!.length} drawn courses for user ID: $userId');
                logger.info('Course IDs: ${snapshot.data!.map((c) => c.id).join(", ")}');
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: snapshot.data!.map((course) => _buildCourseItem(course)).toList(),
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCourseItem(Course course) {
    List<LatLng> points = _convertToLatLngList(course.routeCoordinate);

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
            child: points.isNotEmpty
                ? CustomPaint(
              painter: CoursePainter(points),
              size: Size(100, 100),
            )
                : Center(child: Text('No route')),
          ),
          SizedBox(height: 5),
          Text(
            '${course.recommendationCount ?? 0}명',
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
        Center(child: CircularProgressIndicator()),
      ],
    );
  }

  String _getStrengthBadgeImage(int strength) {
    if (strength >= 1 && strength <= 3) {
      return 'assets/images/strength1-3.png';
    } else if (strength >= 4 && strength <= 6) {
      return 'assets/images/strength4-6.png';
    } else if (strength >= 7 && strength <= 9) {
      return 'assets/images/strength7-9.png';
    } else if (strength == 10) {
      return 'assets/images/strength10.png';
    } else {
      return 'assets/images/default_strength.png';
    }
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

  Future<Map<String, int>> _fetchCourseStatistics(String userId) async {
    final drawCourseCountResponse = await http.get(Uri.parse('${AppConfig.apiBaseUrl}/courses/count/$userId/0'));
    final recommendedCourseCountResponse = await http.get(Uri.parse('${AppConfig.apiBaseUrl}/courses/count/$userId/1'));

    if (drawCourseCountResponse.statusCode == 200 && recommendedCourseCountResponse.statusCode == 200) {
      final drawCourseCount = int.parse(drawCourseCountResponse.body);
      final recommendedCourseCount = int.parse(recommendedCourseCountResponse.body);
      return {
        'drawCourseCount': drawCourseCount,
        'recommendedCourseCount': recommendedCourseCount,
      };
    } else {
      throw Exception('Failed to load course statistics');
    }
  }
}
