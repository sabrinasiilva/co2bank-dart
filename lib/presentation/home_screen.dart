import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('CO2Bank')),
      body: const Center(
        child: Text('Carteira inteligente com limite ecológico'),
      ),
    );
  }
}
