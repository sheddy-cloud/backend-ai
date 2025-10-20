import 'package:flutter/material.dart';
import '../services/api_client.dart';

class HealthScreen extends StatefulWidget {
  const HealthScreen({super.key});

  @override
  State<HealthScreen> createState() => _HealthScreenState();
}

class _HealthScreenState extends State<HealthScreen> {
  final _api = ApiClient();
  Map<String, dynamic>? _health;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await _api.health();
      setState(() {
        _health = res;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AI Safari - Health')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_loading) const LinearProgressIndicator(),
            const SizedBox(height: 16),
            if (_error != null)
              Text(_error!, style: const TextStyle(color: Colors.red)),
            if (_health != null) ...[
              Text('Status: ${_health!['status'] ?? _health!['message'] ?? 'unknown'}'),
              Text('Version: ${_health!['version'] ?? ''}'),
              Text('Time: ${_health!['timestamp'] ?? ''}'),
            ],
            const Spacer(),
            Wrap(spacing: 12, children: [
              ElevatedButton(
                onPressed: () => Navigator.pushNamed(context, '/parks'),
                child: const Text('Parks'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pushNamed(context, '/routes'),
                child: const Text('Safari Routes'),
              ),
              IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
            ]),
          ],
        ),
      ),
    );
  }
}


