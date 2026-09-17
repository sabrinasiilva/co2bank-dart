import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/app_colors.dart';
import 'home/home_tab.dart';
import 'transactions/transactions_tab.dart';
import 'co2/co2_tab.dart';
import 'profile/profile_tab.dart';
import 'widgets/app_drawer.dart';

class Shell extends StatefulWidget {
  const Shell({super.key});

  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  int _currentIndex = 0;

  static const _tabs = [
    HomeTab(),
    TransactionsTab(),
    Co2Tab(),
    ProfileTab(),
  ];

  static const _navItems = [
    BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Início'),
    BottomNavigationBarItem(icon: Icon(Icons.receipt_long_rounded), label: 'Extrato'),
    BottomNavigationBarItem(icon: Icon(Icons.eco_rounded), label: 'CO2'),
    BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: 'Perfil'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      drawer: AppDrawer(
        currentIndex: _currentIndex,
        onNavigate: (i) => setState(() => _currentIndex = i),
      ),
      body: IndexedStack(index: _currentIndex, children: _tabs),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        type: BottomNavigationBarType.fixed,
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.dark,
        unselectedItemColor: AppColors.gray,
        selectedLabelStyle: GoogleFonts.outfit(
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: GoogleFonts.outfit(fontSize: 11),
        elevation: 0,
        items: _navItems,
      ),
    );
  }
}
