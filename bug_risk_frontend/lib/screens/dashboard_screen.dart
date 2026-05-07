// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import '../models/prediction_model.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../widgets/glitch_text.dart';
import 'login_screen.dart';
import 'charts_screen.dart';
import 'commit_detail_screen.dart';

class DashboardScreen extends StatefulWidget {
  final String repo;
  const DashboardScreen({super.key, required this.repo});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<Prediction> _predictions = [];
  bool _loading = true;
  String? _error;
  String _filter = 'All';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final data = await ApiService.fetchPredictions();
      setState(() => _predictions = data);
    } catch (e) {
      setState(() => _error = 'Failed to load. Is the server awake?');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _logout() async {
    await AuthService.signOut();
    if (mounted) {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(pageBuilder: (_, _, _) => const LoginScreen(), transitionDuration: Duration.zero),
      );
    }
  }

  List<Prediction> get _filtered => _filter == 'All'
      ? _predictions
      : _predictions.where((p) => p.riskLevel == _filter).toList();

  Color _riskColor(String level) {
    switch (level) {
      case 'High': return const Color(0xFFFF4444);
      case 'Medium': return const Color(0xFFFF8C00);
      default: return const Color(0xFF00FF41);
    }
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final isWide = w > 900;
    final high = _predictions.where((p) => p.riskLevel == 'High').length;
    final medium = _predictions.where((p) => p.riskLevel == 'Medium').length;
    final low = _predictions.where((p) => p.riskLevel == 'Low').length;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      body: Column(
        children: [
          _topBar(isWide),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF00FF41)))
                : _error != null
                    ? _errorView()
                    : RefreshIndicator(
                        color: const Color(0xFF00FF41),
                        backgroundColor: const Color(0xFF0D1117),
                        onRefresh: _load,
                        child: CustomScrollView(
                          slivers: [
                            SliverToBoxAdapter(
                              child: Padding(
                                padding: EdgeInsets.all(isWide ? 24 : 16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 24),
                                    const Text('OVERVIEW', style: TextStyle(color: Color(0xFF484F58), fontSize: 10, letterSpacing: 3)),
                                    const SizedBox(height: 10),
                                    isWide
                                        ? Row(children: [
                                            _summaryCard('HIGH RISK', high, const Color(0xFFFF4444)),
                                            const SizedBox(width: 16),
                                            _summaryCard('MEDIUM RISK', medium, const Color(0xFFFF8C00)),
                                            const SizedBox(width: 16),
                                            _summaryCard('LOW RISK', low, const Color(0xFF00FF41)),
                                            const SizedBox(width: 16),
                                            _summaryCard('TOTAL', _predictions.length, const Color(0xFF58A6FF)),
                                          ])
                                        : Column(children: [
                                            Row(children: [
                                              _summaryCard('HIGH', high, const Color(0xFFFF4444)),
                                              const SizedBox(width: 12),
                                              _summaryCard('MEDIUM', medium, const Color(0xFFFF8C00)),
                                            ]),
                                            const SizedBox(height: 12),
                                            Row(children: [
                                              _summaryCard('LOW', low, const Color(0xFF00FF41)),
                                              const SizedBox(width: 12),
                                              _summaryCard('TOTAL', _predictions.length, const Color(0xFF58A6FF)),
                                            ]),
                                          ]),
                                    const SizedBox(height: 28),
                                    const Text('FILTER BY RISK', style: TextStyle(color: Color(0xFF484F58), fontSize: 10, letterSpacing: 3)),
                                    const SizedBox(height: 10),
                                    _filterRow(),
                                    const SizedBox(height: 16),
                                    Row(
                                      children: [
                                        const Text('COMMIT RECORDS', style: TextStyle(color: Color(0xFF484F58), fontSize: 10, letterSpacing: 3)),
                                        const SizedBox(width: 10),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF00FF41).withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(2),
                                            border: Border.all(color: const Color(0xFF00FF41).withOpacity(0.3)),
                                          ),
                                          child: Text(
                                            '${_filtered.length}',
                                            style: const TextStyle(color: Color(0xFF00FF41), fontSize: 10, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            SliverPadding(
                              padding: EdgeInsets.symmetric(horizontal: isWide ? 24 : 16),
                              sliver: isWide
                                  ? SliverGrid(
                                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: 2,
                                        crossAxisSpacing: 12,
                                        mainAxisSpacing: 12,
                                        mainAxisExtent: 200,
                                      ),
                                      delegate: SliverChildBuilderDelegate(
                                        (ctx, i) => GestureDetector(
                                          onTap: () => Navigator.push(context, PageRouteBuilder(
                                            pageBuilder: (_, _, _) => CommitDetailScreen(prediction: _filtered[i]),
                                            transitionDuration: Duration.zero,
                                          )),
                                          child: _predictionCard(_filtered[i]),
                                        ),
                                        childCount: _filtered.length,
                                      ),
                                    )
                                  : SliverGrid(
                                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: 1,
                                        mainAxisSpacing: 12,
                                        mainAxisExtent: 200,
                                      ),
                                      delegate: SliverChildBuilderDelegate(
                                        (ctx, i) => GestureDetector(
                                          onTap: () => Navigator.push(context, PageRouteBuilder(
                                            pageBuilder: (_, _, _) => CommitDetailScreen(prediction: _filtered[i]),
                                            transitionDuration: Duration.zero,
                                          )),
                                          child: _predictionCard(_filtered[i]),
                                        ),
                                        childCount: _filtered.length,
                                      ),
                                    ),
                            ),
                            const SliverToBoxAdapter(child: SizedBox(height: 32)),
                          ],
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _topBar(bool isWide) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: isWide ? 24 : 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1117),
        border: Border(bottom: BorderSide(color: const Color(0xFF00FF41).withOpacity(0.2))),
      ),
      child: Row(
        children: [
          const Icon(Icons.bug_report, color: Color(0xFF00FF41), size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const GlitchText('BUG RISK ANALYZER', fontSize: 14),
                Text(
                  widget.repo,
                  style: const TextStyle(color: Color(0xFF58A6FF), fontSize: 11, letterSpacing: 1),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.bar_chart, color: Color(0xFF00FF41), size: 20),
            onPressed: () => Navigator.push(
              context,
              PageRouteBuilder(
                pageBuilder: (_, _, _) => ChartsScreen(predictions: _predictions),
                transitionDuration: Duration.zero,
              ),
            ),
            tooltip: 'Analytics',
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF8B949E), size: 20),
            onPressed: _load,
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.power_settings_new, color: Color(0xFF8B949E), size: 20),
            onPressed: _logout,
            tooltip: 'Logout',
          ),
        ],
      ),
    );
  }

  Widget _summaryCard(String label, int count, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF0D1117),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: color.withOpacity(0.3)),
          boxShadow: [BoxShadow(color: color.withOpacity(0.05), blurRadius: 12)],
        ),
        child: Column(
          children: [
            Text('$count', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(color: Color(0xFF8B949E), fontSize: 10, letterSpacing: 1)),
          ],
        ),
      ),
    );
  }

  Widget _filterRow() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: ['All', 'High', 'Medium', 'Low'].map((f) {
          final selected = _filter == f;
          final color = f == 'High'
              ? const Color(0xFFFF4444)
              : f == 'Medium'
                  ? const Color(0xFFFF8C00)
                  : f == 'Low'
                      ? const Color(0xFF00FF41)
                      : const Color(0xFF58A6FF);
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => setState(() => _filter = f),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: selected ? color.withOpacity(0.1) : Colors.transparent,
                  borderRadius: BorderRadius.circular(2),
                  border: Border.all(color: selected ? color : const Color(0xFF30363D)),
                ),
                child: Text(
                  f.toUpperCase(),
                  style: TextStyle(
                    color: selected ? color : const Color(0xFF8B949E),
                    fontSize: 11,
                    letterSpacing: 2,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _predictionCard(Prediction p) {
    final color = _riskColor(p.riskLevel);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1117),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: const Color(0xFF161B22)),
        boxShadow: [BoxShadow(color: color.withOpacity(0.04), blurRadius: 12)],
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: 3, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            p.module,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(2),
                            border: Border.all(color: color.withOpacity(0.5)),
                          ),
                          child: Text(
                            p.riskLevel.toUpperCase(),
                            style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 1),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _riskBar(p.riskScore, color),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 12,
                      runSpacing: 6,
                      children: [
                        _chip(Icons.insert_drive_file_outlined, '${p.filesChanged} FILES', const Color(0xFF8B949E)),
                        _chip(Icons.add_circle_outline, '+${p.linesAdded} ADDED', const Color(0xFF00FF41)),
                        _chip(Icons.remove_circle_outline, '-${p.linesRemoved} REMOVED', const Color(0xFFFF4444)),
                        _chip(Icons.verified_outlined, '${(p.confidence * 100).toStringAsFixed(0)}% CONF', const Color(0xFF58A6FF)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(children: [
                          const Icon(Icons.person_outline, size: 11, color: Color(0xFF58A6FF)),
                          const SizedBox(width: 4),
                          Text(p.pushedBy, style: const TextStyle(color: Color(0xFF58A6FF), fontSize: 11)),
                        ]),
                        Row(children: [
                          const Icon(Icons.access_time, size: 11, color: Color(0xFF484F58)),
                          const SizedBox(width: 4),
                          Text(_formatDate(p.timestamp), style: const TextStyle(color: Color(0xFF484F58), fontSize: 10)),
                        ]),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _riskBar(double score, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('RISK SCORE', style: TextStyle(color: Color(0xFF484F58), fontSize: 9, letterSpacing: 1)),
            Text('${(score * 100).toStringAsFixed(0)}%', style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: LinearProgressIndicator(
            value: score,
            backgroundColor: const Color(0xFF161B22),
            valueColor: AlwaysStoppedAnimation(color),
            minHeight: 4,
          ),
        ),
      ],
    );
  }

  Widget _chip(IconData icon, String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(color: color, fontSize: 11)),
      ],
    );
  }

  Widget _errorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.wifi_off, color: Color(0xFFFF4444), size: 48),
          const SizedBox(height: 12),
          Text(_error!, style: const TextStyle(color: Color(0xFF8B949E))),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: _load,
            style: OutlinedButton.styleFrom(side: const BorderSide(color: Color(0xFF00FF41))),
            child: const Text('RETRY', style: TextStyle(color: Color(0xFF00FF41), letterSpacing: 2)),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
