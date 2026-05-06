import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/cyber_button.dart';
import '../widgets/cyber_text_field.dart';
import '../widgets/glitch_text.dart';
import 'dashboard_screen.dart';

class RepoConnectScreen extends StatefulWidget {
  const RepoConnectScreen({super.key});
  @override
  State<RepoConnectScreen> createState() => _RepoConnectScreenState();
}

class _RepoConnectScreenState extends State<RepoConnectScreen> {
  final _repoCtrl = TextEditingController();
  final _tokenCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  Future<void> _connect() async {
    final repo = _repoCtrl.text.trim();
    final token = _tokenCtrl.text.trim();

    if (repo.isEmpty || token.isEmpty) {
      setState(() => _error = 'All fields required');
      return;
    }
    if (!RegExp(r'^[a-zA-Z0-9_.-]+/[a-zA-Z0-9_.-]+$').hasMatch(repo)) {
      setState(() => _error = 'Use format: owner/repo-name');
      return;
    }

    setState(() { _loading = true; _error = null; });
    try {
      final result = await ApiService.setupWebhook(repo: repo, githubToken: token);
      if (result['error'] != null) {
        setState(() => _error = result['error']);
      } else if (mounted) {
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(pageBuilder: (_, _, _) => DashboardScreen(repo: repo), transitionDuration: Duration.zero),
        );
      }
    } catch (e) {
      setState(() => _error = 'Connection failed. Try again.');
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final isWide = w > 700;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: isWide ? w * 0.3 : 24, vertical: 40),
          child: Column(
            children: [
              const GlitchText('CONNECT REPOSITORY', fontSize: 20),
              const SizedBox(height: 8),
              const Text(
                'Link your GitHub repo to start monitoring commit risk',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF8B949E), fontSize: 13),
              ),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: const Color(0xFF0D1117),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: const Color(0xFF00FF41).withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CyberTextField(controller: _repoCtrl, label: 'REPOSITORY', hint: 'owner/repo-name', icon: Icons.folder_outlined),
                    const SizedBox(height: 16),
                    CyberTextField(controller: _tokenCtrl, label: 'GITHUB TOKEN', hint: 'ghp_xxxxxxxxxxxx', icon: Icons.key_outlined, obscure: true),
                    const SizedBox(height: 8),
                    const Text(
                      'Requires repo + admin:repo_hook permissions',
                      style: TextStyle(color: Color(0xFF484F58), fontSize: 11),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Row(children: [
                        const Icon(Icons.error_outline, color: Colors.redAccent, size: 14),
                        const SizedBox(width: 6),
                        Expanded(child: Text(_error!, style: const TextStyle(color: Colors.redAccent, fontSize: 13))),
                      ]),
                    ],
                    const SizedBox(height: 24),
                    CyberButton(label: 'CONNECT REPO', loading: _loading, onPressed: _connect),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
