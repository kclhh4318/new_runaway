import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:new_runaway/features/courses/screens/course_drawing_screen.dart';
import 'package:new_runaway/features/running/screens/running_session_screen.dart';
import 'package:new_runaway/features/stats/widgets/period_selector.dart';
import 'package:new_runaway/features/stats/widgets/stats_bar_chart.dart';
import 'package:new_runaway/features/running/running_provider.dart';

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

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
  }

  void _scrollListener() {
    if (_scrollController.offset > 100 && _showRunningButtons) {
      setState(() => _showRunningButtons = false);
    } else if (_scrollController.offset <= 100 && !_showRunningButtons) {
      setState(() => _showRunningButtons = true);
    }
  }


  @override
  Widget build(BuildContext context) {
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
                      });
                    },
                  ),
                ),
                if (_selectedPeriod != '전체' && _selectedPeriod != '주')
                  SliverToBoxAdapter(child: _buildDateFilter()),
                SliverToBoxAdapter(child: _buildStatsChart()),
                SliverToBoxAdapter(child: _buildCourseStatistics()),
                SliverToBoxAdapter(child: _buildRecentRuns()),
                SliverToBoxAdapter(child: _buildMyDrawnCourses()),
              ],
            ),
          ),
          _buildRunningButtons(),
        ],
      ),
    );
  }


  Widget _buildTotalStats() {
    return Container(
      padding: EdgeInsets.all(16),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '총 킬로미터',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          Row(
            children: [
              Text(
                '99,999',
                style: TextStyle(
                  height: 1.2,
                  fontSize: 55,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Giants',
                  fontStyle: FontStyle.italic,
                ),
              ),
              SizedBox(width: 6), // km 텍스트와 거리 사이의 간격
              Baseline(
                baseline: 45, // 텍스트의 베이스라인 위치 조정
                baselineType: TextBaseline.alphabetic,
                child: Text(
                  'km',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16), // 총 킬로미터와 총 시간 사이의 간격
          Text(
            '총 시간',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          Text(
            '999:99',
            style: TextStyle(
              height: 1.2,
              fontSize: 55,
              fontWeight: FontWeight.bold,
              fontFamily: 'Giants',
              fontStyle: FontStyle.italic,
            ),
          ),
          SizedBox(height: 16), // 총 시간과 추가 정보 사이의 간격
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
                    '05:30',
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
                    '05 km',
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
                    '959 회',
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
                child: Text('더 보기', style: TextStyle(color: Colors.black54)),
                onPressed: () {
                  // TODO: Navigate to all running records screen
                },
              ),
            ],
          ),
          SizedBox(height: 10),
          _buildRecentRunItem('24.07.19', '8.11 km', '1:35:18', '05:30'),
          _buildRecentRunItem('24.07.18', '6.5 km', '1:15:30', '05:45'),
          _buildRecentRunItem('24.07.17', '10.2 km', '1:55:40', '05:20'),
        ],
      ),
    );
  }

  Widget _buildRecentRunItem(String date, String distance, String time, String pace) {
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
              'assets/images/strength10.png', // 뱃지 이미지 경로
              width: 27,
              height: 27,
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
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                if (runningProvider.isRunning)
                  InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => RunningSessionScreen(showCountdown: false)),
                      );
                    },
                    child: Image.asset(
                      'assets/images/start_run_btn.png', // 실제 이미지 경로로 변경
                      width: 100, // 이미지 크기 조정
                      height: 100,
                    ),
                  )
                else
                  ...[
                    InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => CourseDrawingScreen()),
                        );
                      },
                      child: Image.asset(
                        'assets/images/map_drawing_btn.png', // 실제 이미지 경로로 변경
                        width: 100, // 이미지 크기 조정
                        height: 100,
                      ),
                    ),
                    InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => RunningSessionScreen()),
                        );
                      },
                      child: Image.asset(
                        'assets/images/start_run_btn.png', // 실제 이미지 경로로 변경
                        width: 100, // 이미지 크기 조정
                        height: 100,
                      ),
                    ),
                  ],
              ],
            ),
          ),
        );
      },
    );
  }
}