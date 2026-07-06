// lib/widgets/sales_chart.dart

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class SalesChart extends StatelessWidget {
  final List<Map<String, dynamic>> salesData;
  final String chartType;

  const SalesChart({
    super.key,
    required this.salesData,
    this.chartType = 'daily',
  });

  @override
  Widget build(BuildContext context) {
    final groupedData = _groupSalesData();

    if (groupedData.isEmpty) {
      return Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: const Padding(
          padding: EdgeInsets.all(32),
          child: Center(
            child: Text('No sales data available for this period'),
          ),
        ),
      );
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Sales Overview',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _getChartSubtitle(),
                    style: TextStyle(fontSize: 12, color: Colors.blue.shade700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 300,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: _getMaxValue(),
                  barTouchData: BarTouchData(
                    enabled: true,
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        return BarTooltipItem(
                          '${groupedData[group.x].keys.first}\n',
                          const TextStyle(color: Colors.white),
                          children: [
                            TextSpan(
                              text: 'UGX ${rod.toY.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index >= 0 && index < groupedData.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                groupedData[index].keys.first,
                                style: const TextStyle(fontSize: 10),
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }
                          return const Text('');
                        },
                        reservedSize: 50,
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            'UGX ${(value / 1000).toStringAsFixed(0)}K',
                            style: const TextStyle(fontSize: 10),
                          );
                        },
                        reservedSize: 60,
                      ),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  gridData: const FlGridData(show: true),
                  borderData: FlBorderData(show: false),
                  barGroups: List.generate(groupedData.length, (index) {
                    final data = groupedData[index];
                    final value = data.values.first;
                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: value,
                          color: Colors.blue,
                          width: 30,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ],
                    );
                  }),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Map<String, double>> _groupSalesData() {
    final Map<String, double> grouped = {};

    for (var sale in salesData) {
      String key;
      final dateStr = sale['sale_date'] ?? DateTime.now().toIso8601String();
      final date = DateTime.parse(dateStr);

      switch (chartType) {
        case 'daily':
          key = DateFormat('MMM dd').format(date);
          break;
        case 'weekly':
          key = 'Week ${((date.day - 1) ~/ 7) + 1}';
          break;
        case 'monthly':
          key = DateFormat('MMM yyyy').format(date);
          break;
        default:
          key = DateFormat('MMM dd').format(date);
      }

      final total = (sale['total_price'] ?? 0).toDouble();
      grouped[key] = (grouped[key] ?? 0) + total;
    }

    return grouped.entries.map((e) => {e.key: e.value}).toList();
  }

  double _getMaxValue() {
    final values = _groupSalesData().map((e) => e.values.first);
    if (values.isEmpty) return 100000;
    final max = values.reduce((a, b) => a > b ? a : b);
    return max * 1.1;
  }

  String _getChartSubtitle() {
    switch (chartType) {
      case 'daily':
        return 'Daily Sales';
      case 'weekly':
        return 'Weekly Sales';
      case 'monthly':
        return 'Monthly Sales';
      default:
        return 'Sales Overview';
    }
  }
}
