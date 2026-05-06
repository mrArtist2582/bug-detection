import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/prediction_model.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';

class CommitDetailScreen extends StatefulWidget {
  final Prediction prediction;
  const CommitDetailScreen({super.key, required this.prediction});

  @override
  State<CommitDetailScreen> createState() => _CommitDetailScreenState();
}

class _CommitDetailScreenState extends State<CommitDetailScreen> {
  List<Map<String, dynamic>> _testCases = [];
  bool _loadingSuggestions = false;
  String? _suggestionsError;
  bool _suggestionsLoaded = false;

  Prediction get p => widget.prediction;

  Color get _riskColor {
    switch (p.riskLevel) {
      case 'High': return const Color(0xFFFF4444);
      case 'Medium': return const Color(0xFFFF8C00);
      default: return const Color(0xFF00FF41);
    }
  }

  Future<void> _loadSuggestions() async {
    if (p.commitSha.isEmpty) {
      setState(() => _suggestionsError = 'No commit SHA available');
      return;
    }
    setState(() { _loadingSuggestions = true; _suggestionsError = null; });
    try {
      final token = await AuthService.getIdToken();
      debugPrint('FIREBASE_TOKEN: $token');
      final result = await ApiService.getSuggestions(p.commitSha);
      debugPrint('SUGGESTIONS_RESULT: $result');
      final cases = List<Map<String, dynamic>>.from(result['test_cases'] ?? []);
      if (cases.isEmpty) {
        setState(() => _suggestionsError = result['error'] ?? 'No test cases returned');
        return;
      }
      setState(() { _testCases = cases; _suggestionsLoaded = true; });
    } catch (e) {
      debugPrint('SUGGESTIONS_ERROR: $e');
      final msg = e.toString().contains('429')
          ? 'AI quota exceeded. Please try again in a few minutes.'
          : e.toString().replaceAll('Exception: ', '');
      setState(() => _suggestionsError = msg);
    } finally {
      setState(() => _loadingSuggestions = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final isWide = w > 800;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1117),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF00FF41)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(p.module, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
            Text(p.commitSha.length > 12 ? p.commitSha.substring(0, 12) : p.commitSha,
                style: const TextStyle(color: Color(0xFF484F58), fontSize: 11, fontFamily: 'monospace')),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: _riskColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(2),
              border: Border.all(color: _riskColor.withOpacity(0.5)),
            ),
            child: Text(p.riskLevel.toUpperCase(),
                style: TextStyle(color: _riskColor, fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 1)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(isWide ? 24 : 16),
        child: isWide
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 3, child: _leftColumn()),
                  const SizedBox(width: 20),
                  Expanded(flex: 2, child: _rightColumn()),
                ],
              )
            : Column(children: [_leftColumn(), const SizedBox(height: 20), _rightColumn()]),
      ),
    );
  }

  Widget _leftColumn() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel('COMMIT DETAILS'),
        const SizedBox(height: 10),
        _detailsCard(),
        const SizedBox(height: 20),
        _sectionLabel('RISK BREAKDOWN'),
        const SizedBox(height: 10),
        _radarCard(),
        const SizedBox(height: 20),
        _sectionLabel('LINES CHANGED'),
        const SizedBox(height: 10),
        _linesBarCard(),
      ],
    );
  }

  Widget _rightColumn() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel('RISK SCORE GAUGE'),
        const SizedBox(height: 10),
        _gaugeCard(),
        const SizedBox(height: 20),
        _sectionLabel('AI TEST SUGGESTIONS'),
        const SizedBox(height: 10),
        _testCasesCard(),
      ],
    );
  }

  Widget _sectionLabel(String label) {
    return Text(label, style: const TextStyle(color: Color(0xFF484F58), fontSize: 10, letterSpacing: 3));
  }

  Widget _detailsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          _detailRow('MODULE', p.module, Icons.folder_outlined),
          _detailRow('REPO', p.repoName, Icons.source_outlined),
          _detailRow('PUSHED BY', p.pushedBy, Icons.person_outline),
          _detailRow('COMMIT SHA', p.commitSha.length > 16 ? '${p.commitSha.substring(0, 16)}...' : p.commitSha, Icons.tag),
          _detailRow('TIMESTAMP', _formatDate(p.timestamp), Icons.access_time),
          _detailRow('FILES CHANGED', '${p.filesChanged}', Icons.insert_drive_file_outlined),
          _detailRow('LINES ADDED', '+${p.linesAdded}', Icons.add_circle_outline, valueColor: const Color(0xFF00FF41)),
          _detailRow('LINES REMOVED', '-${p.linesRemoved}', Icons.remove_circle_outline, valueColor: const Color(0xFFFF4444)),
          _detailRow('COMMIT COUNT', '${p.commitCount}', Icons.commit),
          _detailRow('CONFIDENCE', '${(p.confidence * 100).toStringAsFixed(0)}%', Icons.verified_outlined, valueColor: const Color(0xFF58A6FF)),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value, IconData icon, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 14, color: const Color(0xFF484F58)),
          const SizedBox(width: 10),
          SizedBox(
            width: 120,
            child: Text(label, style: const TextStyle(color: Color(0xFF484F58), fontSize: 11, letterSpacing: 1)),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: valueColor ?? Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _gaugeCard() {
    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Stack(
        alignment: Alignment.center,
        children: [
          PieChart(
            PieChartData(
              startDegreeOffset: 180,
              sectionsSpace: 0,
              centerSpaceRadius: 60,
              sections: [
                PieChartSectionData(
                  value: p.riskScore * 100,
                  color: _riskColor,
                  radius: 20,
                  showTitle: false,
                ),
                PieChartSectionData(
                  value: (1 - p.riskScore) * 100,
                  color: const Color(0xFF161B22),
                  radius: 20,
                  showTitle: false,
                ),
              ],
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${(p.riskScore * 100).toStringAsFixed(0)}%',
                style: TextStyle(color: _riskColor, fontSize: 28, fontWeight: FontWeight.bold),
              ),
              Text(p.riskLevel.toUpperCase(),
                  style: TextStyle(color: _riskColor, fontSize: 10, letterSpacing: 2)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _radarCard() {
    final maxVal = 10.0;
    final filesNorm = (p.filesChanged / 10).clamp(0.0, 1.0) * maxVal;
    final addedNorm = (p.linesAdded / 100).clamp(0.0, 1.0) * maxVal;
    final removedNorm = (p.linesRemoved / 100).clamp(0.0, 1.0) * maxVal;
    final riskNorm = p.riskScore * maxVal;
    final confNorm = p.confidence * maxVal;

    return Container(
      height: 220,
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: RadarChart(
        RadarChartData(
          radarShape: RadarShape.polygon,
          tickCount: 4,
          ticksTextStyle: const TextStyle(color: Colors.transparent, fontSize: 0),
          radarBorderData: const BorderSide(color: Color(0xFF161B22)),
          gridBorderData: const BorderSide(color: Color(0xFF161B22), width: 1),
          titleTextStyle: const TextStyle(color: Color(0xFF484F58), fontSize: 10),
          dataSets: [
            RadarDataSet(
              fillColor: _riskColor.withOpacity(0.15),
              borderColor: _riskColor,
              borderWidth: 2,
              entryRadius: 3,
              dataEntries: [
                RadarEntry(value: filesNorm),
                RadarEntry(value: addedNorm),
                RadarEntry(value: removedNorm),
                RadarEntry(value: riskNorm),
                RadarEntry(value: confNorm),
              ],
            ),
          ],
          getTitle: (i, _) {
            const titles = ['FILES', 'ADDED', 'REMOVED', 'RISK', 'CONF'];
            return RadarChartTitle(text: titles[i], angle: 0);
          },
        ),
      ),
    );
  }

  Widget _linesBarCard() {
    return Container(
      height: 160,
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: BarChart(
        BarChartData(
          backgroundColor: Colors.transparent,
          alignment: BarChartAlignment.spaceAround,
          maxY: (p.linesAdded > p.linesRemoved ? p.linesAdded : p.linesRemoved).toDouble() + 5,
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
                  final labels = ['ADDED', 'REMOVED', 'FILES'];
                  final colors = [const Color(0xFF00FF41), const Color(0xFFFF4444), const Color(0xFF8B949E)];
                  final i = v.toInt();
                  if (i < 0 || i >= labels.length) return const SizedBox();
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(labels[i], style: TextStyle(color: colors[i], fontSize: 9, letterSpacing: 1)),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              getTitlesWidget: (v, _) => Text('${v.toInt()}', style: const TextStyle(color: Color(0xFF484F58), fontSize: 9)),
            )),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          barGroups: [
            BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: p.linesAdded.toDouble(), color: const Color(0xFF00FF41), width: 28, borderRadius: BorderRadius.circular(2))]),
            BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: p.linesRemoved.toDouble(), color: const Color(0xFFFF4444), width: 28, borderRadius: BorderRadius.circular(2))]),
            BarChartGroupData(x: 2, barRods: [BarChartRodData(toY: p.filesChanged.toDouble(), color: const Color(0xFF8B949E), width: 28, borderRadius: BorderRadius.circular(2))]),
          ],
        ),
      ),
    );
  }

  Widget _testCasesCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!_suggestionsLoaded && !_loadingSuggestions) ...[
            const Text(
              'Get AI-powered test case suggestions based on this commit\'s risk profile.',
              style: TextStyle(color: Color(0xFF8B949E), fontSize: 12),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton.icon(
                onPressed: _loadSuggestions,
                icon: const Icon(Icons.auto_awesome, size: 16, color: Color(0xFF00FF41)),
                label: const Text('GENERATE TEST CASES', style: TextStyle(color: Color(0xFF00FF41), letterSpacing: 2, fontSize: 11)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  side: const BorderSide(color: Color(0xFF00FF41)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
                  elevation: 0,
                ),
              ),
            ),
          ] else if (_loadingSuggestions) ...[
            const Center(
              child: Column(
                children: [
                  CircularProgressIndicator(color: Color(0xFF00FF41), strokeWidth: 2),
                  SizedBox(height: 12),
                  Text('ANALYZING COMMIT...', style: TextStyle(color: Color(0xFF484F58), fontSize: 11, letterSpacing: 2)),
                ],
              ),
            ),
          ] else if (_suggestionsError != null) ...[
            Row(children: [
              const Icon(Icons.error_outline, color: Colors.redAccent, size: 14),
              const SizedBox(width: 8),
              Expanded(child: Text(_suggestionsError!, style: const TextStyle(color: Colors.redAccent, fontSize: 12))),
            ]),
            const SizedBox(height: 12),
            TextButton(
              onPressed: _loadSuggestions,
              child: const Text('RETRY', style: TextStyle(color: Color(0xFF00FF41), letterSpacing: 2)),
            ),
          ] else ...[
            Row(
              children: [
                const Icon(Icons.auto_awesome, size: 14, color: Color(0xFF00FF41)),
                const SizedBox(width: 8),
                const Text('TOP 5 SUGGESTED TEST CASES', style: TextStyle(color: Color(0xFF00FF41), fontSize: 11, letterSpacing: 1)),
              ],
            ),
            const SizedBox(height: 16),
            ..._testCases.asMap().entries.map((e) => _testCaseItem(e.key + 1, e.value)),
          ],
        ],
      ),
    );
  }

  Widget _testCaseItem(int index, Map<String, dynamic> tc) {
    final priority = tc['priority'] ?? 'Low';
    final priorityColor = priority == 'High'
        ? const Color(0xFFFF4444)
        : priority == 'Medium'
            ? const Color(0xFFFF8C00)
            : const Color(0xFF00FF41);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF060A12),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: const Color(0xFF161B22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: const Color(0xFF00FF41).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(2),
                  border: Border.all(color: const Color(0xFF00FF41).withOpacity(0.3)),
                ),
                child: Center(
                  child: Text('$index', style: const TextStyle(color: Color(0xFF00FF41), fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  tc['title'] ?? '',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: priorityColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(2),
                  border: Border.all(color: priorityColor.withOpacity(0.4)),
                ),
                child: Text(priority.toUpperCase(), style: TextStyle(color: priorityColor, fontSize: 9, letterSpacing: 1)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(tc['description'] ?? '', style: const TextStyle(color: Color(0xFF8B949E), fontSize: 12, height: 1.4)),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('EXPECTED: ', style: TextStyle(color: Color(0xFF484F58), fontSize: 10, letterSpacing: 1)),
              Expanded(
                child: Text(tc['expected'] ?? '', style: const TextStyle(color: Color(0xFF58A6FF), fontSize: 11, height: 1.4)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: const Color(0xFF0D1117),
      borderRadius: BorderRadius.circular(4),
      border: Border.all(color: const Color(0xFF161B22)),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
