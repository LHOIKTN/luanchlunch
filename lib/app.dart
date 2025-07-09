import 'package:flutter/material.dart';
import 'features/home/home_screen.dart';

class LunchGameApp extends StatelessWidget {
  const LunchGameApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '급식실 게임',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
} 