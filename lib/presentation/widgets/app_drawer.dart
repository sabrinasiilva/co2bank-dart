import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/app_colors.dart';
import '../../core/token_storage.dart';
import '../../data/user_service.dart';
import '../auth/login_screen.dart';
import '../rewards/rewards_screen.dart';

class AppDrawer extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onNavigate;

  const AppDrawer({
    super.key,
    required this.currentIndex,
    required this.onNavigate,
  });

  static const _items = [
    _DrawerItem(icon: Icons.home_rounded, label: 'Início', index: 0),
    _DrawerItem(icon: Icons.receipt_long_rounded, label: 'Extrato de Transações', index: 1),
    _DrawerItem(icon: Icons.eco_rounded, label: 'Limite Ecológico', index: 2),
    _DrawerItem(icon: Icons.person_rounded, label: 'Perfil', index: 3),
  ];

  void _navigate(BuildContext context, int index) {
    Navigator.pop(context);
    onNavigate(index);
  }

  void _openRewards(BuildContext context) {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const RewardsScreen()),
    );
  }

  Future<void> _logout(BuildContext context) async {
    Navigator.pop(context);
    await TokenStorage.clear();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppColors.surface,
      child: Column(
        children: [
          _DrawerHeader(),
          const SizedBox(height: 8),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                ..._items.map(
                  (item) => _DrawerTile(
                    icon: item.icon,
                    label: item.label,
                    active: currentIndex == item.index,
                    onTap: () => _navigate(context, item.index),
                  ),
                ),
                _DrawerTile(
                  icon: Icons.star_rounded,
                  label: 'Recompensas',
                  active: false,
                  onTap: () => _openRewards(context),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          _DrawerTile(
            icon: Icons.logout_rounded,
            label: 'Sair',
            active: false,
            danger: true,
            onTap: () => _logout(context),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _DrawerHeader extends StatefulWidget {
  @override
  State<_DrawerHeader> createState() => _DrawerHeaderState();
}

class _DrawerHeaderState extends State<_DrawerHeader> {
  UserProfile? _user;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final svc = await UserService.authenticated();
    final user = await svc.getMe();
    if (mounted) setState(() => _user = user);
  }

  @override
  Widget build(BuildContext context) {
    final name = _user?.name ?? '';
    final email = _user?.email ?? '';
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

    return Container(
      width: double.infinity,
      color: AppColors.dark,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 28,
        left: 24,
        right: 24,
        bottom: 28,
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.primaryMuted.withOpacity(0.35),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primary, width: 2),
            ),
            child: Center(
              child: Text(
                initial,
                style: GoogleFonts.outfit(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name.isEmpty ? 'Carregando...' : name,
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (email.isNotEmpty)
                  Text(
                    email,
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      color: Colors.white54,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DrawerTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final bool danger;
  final VoidCallback onTap;

  const _DrawerTile({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = danger
        ? Colors.red
        : active
            ? AppColors.dark
            : AppColors.textSecondary;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      decoration: BoxDecoration(
        color: active ? AppColors.primaryMuted.withOpacity(0.3) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(icon, size: 22, color: color),
        title: Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 14,
            fontWeight: active ? FontWeight.w700 : FontWeight.w500,
            color: color,
          ),
        ),
        trailing: active
            ? Container(
                width: 4,
                height: 20,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              )
            : null,
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

class _DrawerItem {
  final IconData icon;
  final String label;
  final int index;

  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.index,
  });
}
