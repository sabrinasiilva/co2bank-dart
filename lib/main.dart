import 'package:flutter/material.dart';

import 'presentation/home_screen.dart';

void main() {
  runApp(const CO2BankApp());
}

class CO2BankApp extends StatelessWidget {
  const CO2BankApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CO2Bank',
      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.green)),
      home: const HomeScreen(),
    );
  }
}
