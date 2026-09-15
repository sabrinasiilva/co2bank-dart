import 'package:flutter/material.dart';

import '../data/co2bank_api.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _api = Co2BankApi();
  late Future<bool> _healthCheck;

  @override
  void initState() {
    super.initState();
    _healthCheck = _api.checkHealth();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('CO2Bank')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Carteira inteligente com limite ecológico'),
            const SizedBox(height: 16),
            FutureBuilder<bool>(
              future: _healthCheck,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const CircularProgressIndicator();
                }
                final connected = snapshot.data == true;
                return Text(
                  connected ? 'Backend conectado ✅' : 'Backend indisponível ❌',
                  style: TextStyle(color: connected ? Colors.green : Colors.red),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
