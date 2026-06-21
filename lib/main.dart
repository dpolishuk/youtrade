import 'package:flutter/material.dart';

void main() {
  runApp(const YouTradeApp());
}

class YouTradeApp extends StatelessWidget {
  const YouTradeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'YouTrade',
      home: Scaffold(body: Center(child: Text('YouTrade'))),
    );
  }
}
