import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../core/colors.dart';
import 'dashboard.dart';
import 'stadistics.dart';
import 'profile.dart';
import '../transactions/create_transactions.dart';
import '../categories/create_category.dart';
import '../presupuestos/create_presupuesto.dart';

class MainLayout extends StatefulWidget {
  final Map<String, dynamic> user;

  const MainLayout({super.key, required this.user});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _currentIndex = 0;
  late List<Widget> _screens;
  late GlobalKey<State<DashboardScreen>> _dashboardKey;

  @override
  void initState() {
    super.initState();
    _dashboardKey = GlobalKey<State<DashboardScreen>>();
    _screens = [
      DashboardScreen(key: _dashboardKey, user: widget.user),
      StadisticsScreen(user: widget.user),
      ProfileScreen(user: widget.user),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background(context),
      body: _screens[_currentIndex],
      bottomNavigationBar: _buildBottomNav(context),
      floatingActionButton: _buildAddButton(context),
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground(context),
        border: Border(
          top: BorderSide(
            color: AppColors.textSecondary(context).withValues(alpha: 0.1),
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildNavItem(
                index: 0,
                icon: Icons.dashboard_rounded,
                label: 'Dashboard',
                context: context,
              ),
              _buildNavItem(
                index: 1,
                icon: Icons.bar_chart_rounded,
                label: 'Estadísticas',
                context: context,
              ),
              _buildNavItem(
                index: 2,
                icon: Icons.person_rounded,
                label: 'Perfil',
                context: context,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required String label,
    required BuildContext context,
  }) {
    final isActive = _currentIndex == index;
    final color = isActive
        ? AppColors.primary(context)
        : AppColors.textSecondary(context);

    return SizedBox(
      width: 100,
      child: GestureDetector(
        onTap: () {
          setState(() => _currentIndex = index);
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: color,
              size: 28,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 12),
      child: FloatingActionButton(
        onPressed: () => _showAddMenu(context),
        backgroundColor: AppColors.primary(context),
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Icon(Icons.add, color: Colors.white, size: 32),
      ),
    );
  }

  void _showAddMenu(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) => _buildAddMenuDialog(context),
    );
  }

  Widget _buildAddMenuDialog(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardBackground(context),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildMenuOption(
              context: context,
              icon: 'assets/svgs/placeholder.svg',
              label: 'Registrar Movimiento',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        CreateTransactionScreen(user: widget.user),
                  ),
                ).then((_) => (_dashboardKey.currentState as dynamic)?.loadData());
              },
            ),
            const SizedBox(height: 12),
            _buildMenuOption(
              context: context,
              icon: 'assets/svgs/placeholder.svg',
              label: 'Crear Categoría',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        CreateCategoryScreen(user: widget.user),
                  ),
                ).then((_) => (_dashboardKey.currentState as dynamic)?.loadData());
              },
            ),
            const SizedBox(height: 12),
            _buildMenuOption(
              context: context,
              icon: 'assets/svgs/placeholder.svg',
              label: 'Definir Presupuesto',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        CreatePresupuestoScreen(user: widget.user),
                  ),
                ).then((_) => (_dashboardKey.currentState as dynamic)?.loadData());
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuOption({
    required BuildContext context,
    required String icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: AppColors.background(context),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            SvgPicture.asset(
              icon,
              width: 24,
              height: 24,
              colorFilter: ColorFilter.mode(
                AppColors.textPrimary(context),
                BlendMode.srcIn,
              ),
            ),
            const SizedBox(width: 16),
            Text(
              label,
              style: TextStyle(
                color: AppColors.textPrimary(context),
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
