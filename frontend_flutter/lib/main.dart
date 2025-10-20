import 'package:flutter/material.dart';
import 'screens/health_screen.dart';
import 'screens/parks_screen.dart';
import 'screens/routes_screen.dart';

void main() {
  runApp(const AiSafariApp());
}

class AiSafariApp extends StatelessWidget {
  const AiSafariApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI Safari',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const HealthScreen(),
        '/parks': (context) => const ParksScreen(),
        '/routes': (context) => const RoutesScreen(),
      },
    );
  }
}


