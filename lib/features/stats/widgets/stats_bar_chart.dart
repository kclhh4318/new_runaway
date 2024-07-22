import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class StatsBarChart extends StatelessWidget {
  final String selectedPeriod;
  final DateTime selectedDate;

  const StatsBarChart({
    Key? key,
    required this.selectedPeriod,
    required this.selectedDate,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final data = _getDummyData();
    final maxY = data.reduce((a, b) => a > b ? a : b);
    final interval = _calculateInterval(maxY);

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxY + interval,
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            tooltipBgColor: Colors.blueAccent,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              return BarTooltipItem(
                '${rod.toY.round()} km',
                const TextStyle(color: Colors.white),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (double value, TitleMeta meta) {
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    _getBottomTitles(value),
                    style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                );
              },
              reservedSize: 30,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value % interval == 0) {
                  return Text(
                    '${value.toInt()}km',
                    style: TextStyle(fontSize: 8),
                  );
                }
                return Text('');
              },
              reservedSize: 30,
              interval: interval,
            ),
          ),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        barGroups: _getBarGroups(data),
        gridData: FlGridData(
          show: true,
          drawHorizontalLine: true,
          horizontalInterval: interval,
          drawVerticalLine: false,
        ),
      ),
    );
  }

  List<double> _getDummyData() {
    switch (selectedPeriod) {
      case '주':
        return [10, 15, 30, 25, 40, 35, 20];
      case '월':
        return List.generate(31, (index) => (index % 2 == 0) ? 20.0 + index : 0);
      case '년':
        return [10, 150, 30, 80, 60, 70, 90, 100, 110, 120, 130, 140];
      case '전체':
        return [100, 200, 150, 300];
      default:
        return [];
    }
  }

  List<BarChartGroupData> _getBarGroups(List<double> data) {
    return List.generate(data.length, (index) {
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: data[index],
            color: Colors.blue,
            width: 12,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      );
    });
  }

  double _calculateInterval(double maxY) {
    if (maxY <= 50) return 10;
    if (maxY <= 100) return 20;
    if (maxY <= 200) return 50;
    return 100;
  }

  String _getBottomTitles(double value) {
    final intValue = value.toInt();
    switch (selectedPeriod) {
      case '주':
        return ['일', '월', '화', '수', '목', '금', '토'][intValue];
      case '월':
        if (intValue % 7 == 0) {
          return '${intValue + 1}일';
        }
        return '';
      case '년':
        return ['1월', '2월', '3월', '4월', '5월', '6월', '7월', '8월', '9월', '10월', '11월', '12월'][intValue];
      case '전체':
        final years = [2021, 2022, 2023, 2024];
        if (intValue < years.length) {
          return years[years.length - 1 - intValue].toString();
        }
        return '';
      default:
        return '';
    }
  }
}