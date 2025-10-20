import 'package:flutter/material.dart';
import '../services/api_client.dart';

class ParksScreen extends StatefulWidget {
  const ParksScreen({super.key});

  @override
  State<ParksScreen> createState() => _ParksScreenState();
}

class _ParksScreenState extends State<ParksScreen> {
  final _api = ApiClient();
  List<dynamic> _parks = [];
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
      final res = await _api.parks();
      setState(() {
        _parks = res;
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
      appBar: AppBar(title: const Text('Parks')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : ListView.separated(
                  itemCount: _parks.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final p = _parks[index] as Map<String, dynamic>;
                    return ListTile(
                      title: Text(p['name']?.toString() ?? 'Park'),
                      subtitle: Text(p['description']?.toString() ?? ''),
                    );
                  },
                ),
    );
  }
}


