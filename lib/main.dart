import 'package:flutter/material.dart';

void main() {
  runApp(const IppoApp());
}

/// Root widget. Routing and dependency wiring are added in the app shell.
class IppoApp extends StatelessWidget {
  const IppoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ippo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
      ),
      home: const Scaffold(
        body: Center(
          child: Text('一歩', style: TextStyle(fontSize: 64)),
        ),
      ),
    );
  }
}
