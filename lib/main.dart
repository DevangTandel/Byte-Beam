import 'package:flutter/material.dart';

void main() {
  runApp(const ByteBeamApp());
}

/// Root application widget. Wiring for router, theme, and DI comes later.
class ByteBeamApp extends StatelessWidget {
  /// Creates the root application widget.
  const ByteBeamApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ByteBeam',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const Scaffold(
        body: Center(child: Text('ByteBeam')),
      ),
    );
  }
}
