import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/prediction_model.dart';

class ChartsScreen extends StatefulWidget {
  final List<Prediction> predictions;
  const ChartsScreen({super.key, required this.predictions});

  @override
  State<ChartsScreen> createState() => _ChartsScreenState();
}

class _ChartsScreenState extends State<ChartsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<Prediction> get _sorted =>
      [...widget.predictions]..sort((a, b) => a.timestamp.compareTo(b.timestamp));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1117),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF00FF41)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('ANALYTICS', style: TextStyle(color: Color(0xFF00FF41), letterSpacing: 3, fontSize: 16)),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF00FF41),
          labelColor: const Color(0xFF00FF41),
          unselectedLabelColor: const Color(0xFF484F58),
          labelStyle: const TextStyle(fontSize: 11, letterSpacing: 2),
          tabs: const [
            Tab(text: 'LINE'),
            Tab(text: 'HISTOGRAM'),
            Tab(text: 'OGIVE'),
          ],
        ),
      ),
      body: widget.predictions.isEmpty
          ? const Center(
              child: Text('NO DATA AVAILABLE', style: TextStyle(color: Color(0xFF484F58), letterSpacing: 3)),
            )
          : TabBarView(
              controller: _tabController,
              children: [
                _buildLineChart(),
                _buildHistogram(),
                _buildOgive(),
              ],
            ),
    );
  }

  // ── LINE CHART ── risk score over time
  Widget _buildLineChart() {
    final data = _sorted;
    final spots = data.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value.riskScore);
    }).toList();

    return _chartContainer(
      title: 'RISK SCORE OVER TIME',
      subtitle: 'Each point represents a commit',
      child: LineChart(
        LineChartData(
          backgroundColor: const Color(0xFF0D1117),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: true,
            getDrawingHorizontalLine: (_) => FlLine(color: const Color(0xFF161B22), strokeWidth: 1),
            getDrawingVerticalLine: (_) => FlLine(color: const Color(0xFF161B22), strokeWidth: 1),
          ),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              axisNameWidget: const Text('RISK SCORE', style: TextStyle(color: Color(0xFF484F58), fontSize: 9, letterSpacing: 1)),
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 36,
                getTitlesWidget: (v, _) => Text(v.toStringAsFixed(1), style: const TextStyle(color: Color(0xFF484F58), fontSize: 9)),
              ),
            ),
            bottomTitles: AxisTitles(
              axisNameWidget: const Text('COMMIT INDEX', style: TextStyle(color: Color(0xFF484F58), fontSize: 9, letterSpacing: 1)),
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (v, _) => Text('${v.toInt()}', style: const TextStyle(color: Color(0xFF484F58), fontSize: 9)),
              ),
            ),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(
            show: true,
            border: Border.all(color: const Color(0xFF161B22)),
          ),
          minY: 0,
          maxY: 1,
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: const Color(0xFF00FF41),
              barWidth: 2,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, _, _, _) {
                  final color = spot.y >= 0.7
                      ? const Color(0xFFFF4444)
                      : spot.y >= 0.4
                          ? const Color(0xFFFF8C00)
                          : const Color(0xFF00FF41);
                  return FlDotCirclePainter(radius: 4, color: color, strokeWidth: 0);
                },
              ),
              belowBarData: BarAreaData(
                show: true,
                color: const Color(0xFF00FF41).withOpacity(0.05),
              ),
            ),
          ],
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (_) => const Color(0xFF161B22),
              getTooltipItems: (spots) => spots.map((s) {
                final p = data[s.x.toInt()];
                return LineTooltipItem(
                  '${p.module}\nScore: ${p.riskScore}\n${p.riskLevel}',
                  TextStyle(
                    color: s.bar.color,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  // ── HISTOGRAM ── count of commits per risk level
  Widget _buildHistogram() {
    final high = widget.predictions.where((p) => p.riskLevel == 'High').length;
    final medium = widget.predictions.where((p) => p.riskLevel == 'Medium').length;
    final low = widget.predictions.where((p) => p.riskLevel == 'Low').length;
    final maxY = [high, medium, low].reduce((a, b) => a > b ? a : b).toDouble() + 1;

    return _chartContainer(
      title: 'COMMITS BY RISK LEVEL',
      subtitle: 'Distribution of risk across all commits',
      child: BarChart(
        BarChartData(
          backgroundColor: const Color(0xFF0D1117),
          alignment: BarChartAlignment.spaceAround,
          maxY: maxY,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) => FlLine(color: const Color(0xFF161B22), strokeWidth: 1),
          ),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (v, _) {
                  const labels = ['HIGH', 'MEDIUM', 'LOW'];
                  final colors = [const Color(0xFFFF4444), const Color(0xFFFF8C00), const Color(0xFF00FF41)];
                  final i = v.toInt();
                  if (i < 0 || i >= labels.length) return const SizedBox();
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(labels[i], style: TextStyle(color: colors[i], fontSize: 10, letterSpacing: 1)),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              axisNameWidget: const Text('COMMITS', style: TextStyle(color: Color(0xFF484F58), fontSize: 9, letterSpacing: 1)),
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 32,
                getTitlesWidget: (v, _) => Text('${v.toInt()}', style: const TextStyle(color: Color(0xFF484F58), fontSize: 9)),
              ),
            ),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: true, border: Border.all(color: const Color(0xFF161B22))),
          barGroups: [
            _barGroup(0, high.toDouble(), const Color(0xFFFF4444)),
            _barGroup(1, medium.toDouble(), const Color(0xFFFF8C00)),
            _barGroup(2, low.toDouble(), const Color(0xFF00FF41)),
          ],
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => const Color(0xFF161B22),
              getTooltipItem: (group, _, rod, _) {
                const labels = ['High', 'Medium', 'Low'];
                return BarTooltipItem(
                  '${labels[group.x]}\n${rod.toY.toInt()} commits',
                  const TextStyle(color: Colors.white, fontSize: 11),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  BarChartGroupData _barGroup(int x, double y, Color color) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: color,
          width: 40,
          borderRadius: const BorderRadius.only(topLeft: Radius.circular(3), topRight: Radius.circular(3)),
          backDrawRodData: BackgroundBarChartRodData(
            show: true,
            toY: y + 1,
            color: color.withOpacity(0.05),
          ),
        ),
      ],
    );
  }

  // ── OGIVE ── cumulative risk score over commits
  Widget _buildOgive() {
    final data = _sorted;
    double cumulative = 0;
    final spots = data.asMap().entries.map((e) {
      cumulative += e.value.riskScore;
      return FlSpot(e.key.toDouble(), cumulative);
    }).toList();

    return _chartContainer(
      title: 'CUMULATIVE RISK (OGIVE)',
      subtitle: 'Accumulated risk score across commits',
      child: LineChart(
        LineChartData(
          backgroundColor: const Color(0xFF0D1117),
          gridData: FlGridData(
            show: true,
            getDrawingHorizontalLine: (_) => FlLine(color: const Color(0xFF161B22), strokeWidth: 1),
            getDrawingVerticalLine: (_) => FlLine(color: const Color(0xFF161B22), strokeWidth: 1),
          ),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              axisNameWidget: const Text('CUMULATIVE SCORE', style: TextStyle(color: Color(0xFF484F58), fontSize: 9, letterSpacing: 1)),
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (v, _) => Text(v.toStringAsFixed(1), style: const TextStyle(color: Color(0xFF484F58), fontSize: 9)),
              ),
            ),
            bottomTitles: AxisTitles(
              axisNameWidget: const Text('COMMIT INDEX', style: TextStyle(color: Color(0xFF484F58), fontSize: 9, letterSpacing: 1)),
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (v, _) => Text('${v.toInt()}', style: const TextStyle(color: Color(0xFF484F58), fontSize: 9)),
              ),
            ),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: true, border: Border.all(color: const Color(0xFF161B22))),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: const Color(0xFF58A6FF),
              barWidth: 2,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFF58A6FF).withOpacity(0.15),
                    const Color(0xFF58A6FF).withOpacity(0.0),
                  ],
                ),
              ),
            ),
          ],
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (_) => const Color(0xFF161B22),
              getTooltipItems: (spots) => spots.map((s) {
                final p = data[s.x.toInt()];
                return LineTooltipItem(
                  '${p.module}\nCumulative: ${s.y.toStringAsFixed(2)}',
                  const TextStyle(color: Color(0xFF58A6FF), fontSize: 11, fontWeight: FontWeight.bold),
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _chartContainer({required String title, required String subtitle, required Widget child}) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 2)),
          const SizedBox(height: 4),
          Text(subtitle, style: const TextStyle(color: Color(0xFF484F58), fontSize: 11)),
          const SizedBox(height: 20),
          Container(
            height: 320,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF0D1117),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: const Color(0xFF161B22)),
            ),
            child: child,
          ),
          const SizedBox(height: 20),
          _legend(),
        ],
      ),
    );
  }

  Widget _legend() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1117),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: const Color(0xFF161B22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('LEGEND', style: TextStyle(color: Color(0xFF484F58), fontSize: 10, letterSpacing: 3)),
          const SizedBox(height: 12),
          Row(
            children: [
              _legendItem('HIGH RISK', const Color(0xFFFF4444), 'Score ≥ 0.7'),
              const SizedBox(width: 24),
              _legendItem('MEDIUM RISK', const Color(0xFFFF8C00), 'Score 0.4–0.7'),
              const SizedBox(width: 24),
              _legendItem('LOW RISK', const Color(0xFF00FF41), 'Score < 0.4'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _legendItem(String label, Color color, String range) {
    return Row(
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
            Text(range, style: const TextStyle(color: Color(0xFF484F58), fontSize: 9)),
          ],
        ),
      ],
    );
  }
}
