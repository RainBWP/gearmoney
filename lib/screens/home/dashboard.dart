import 'package:flutter/material.dart';
import '../../core/colors.dart';
import '../../core/database/db_helper.dart';
import '../../core/utils/transactions_calculator.dart';
import '../../components/money_display.dart';
import '../../components/transaction_card_small.dart';
import '../../components/budget_card_small.dart';
// import '../transactions/create_transactions.dart';
import '../categories/category_list.dart';

class DashboardScreen extends StatefulWidget {
  final Map<String, dynamic> user;

  const DashboardScreen({super.key, required this.user});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int saldo = 0;
  int totalIngresos = 0;
  int totalGastos = 0;
  List<Map<String, dynamic>> movimientos = [];
  List<Map<String, dynamic>> presupuestos = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final dbh = DatabaseHelper.instance;

    final allMov = await dbh.readMovimientos();
    final int userId = (widget.user['id'] is int)
        ? widget.user['id'] as int
        : int.tryParse('${widget.user['id']}') ?? 1;
    // filter by usuario_id
    final userMov = allMov.where((m) => m['usuario_id'] == userId).toList();

    final ingresos = await TransactionsCalculator.getTotalIngresosUltimoMes(
      userId: userId,
    );
    final gastos = await TransactionsCalculator.getTotalGastosUltimoMes(
      userId: userId,
    );

    // budgets
    final db = await dbh.database;
    final pres = await db.query(
      'Presupuestos',
      where: 'usuario_id = ?',
      whereArgs: [userId],
      orderBy: 'id ASC',
    );

    if (!mounted) return;

    setState(() {
      totalIngresos = ingresos;
      totalGastos = gastos;
      saldo = ingresos - gastos;
      movimientos = userMov;
      presupuestos = pres;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background(context),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(32),
          children: [
            Text(
              'Hola, ${widget.user['nombre']}!',
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w600,
                color: AppColors.primary(context),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.cardBackground(context).withValues(alpha: 0),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  MoneyDisplay(
                    amount: saldo,
                    color: AppColors.textPrimary(context),
                    sizeFont: 40,
                    iconAtLeft: null,
                  ),
                  const SizedBox(height: 12),
                  MoneyDisplay(
                    amount: totalIngresos,
                    color: AppColors.success(context),
                    sizeFont: 24,
                    iconAtLeft: 'assets/svgs/up-trend-svgrepo-com.svg',
                  ),
                  const SizedBox(height: 8),
                  MoneyDisplay(
                    amount: totalGastos,
                    color: AppColors.alert(context),
                    sizeFont: 24,
                    iconAtLeft: 'assets/svgs/down-trend-round-svgrepo-com.svg',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.cardBackground(context),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Historial',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary(context),
                          ),
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: AppColors.textSecondary(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ..._buildMovimientos(),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          CategoryListScreen(user: widget.user),
                    ),
                  ).then((_) => _loadData());
                },
                icon: Icon(Icons.category, color: AppColors.textPrimary(context)),
                label: Text('Gestionar Categorías', 
                  style: TextStyle(fontSize: 16, 
                    fontWeight: FontWeight.w600, 
                    color: AppColors.textPrimary(context)
                    ),
                    textAlign: TextAlign.left,),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.cardBackground(context),
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  alignment: Alignment.centerLeft,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.cardBackground(context),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Presupuestos',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary(context),
                          ),
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: AppColors.textSecondary(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ..._buildPresupuestos(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildMovimientos() {
    final List<Widget> items = [];
    final count = movimientos.length;
    final take = count >= 3 ? 3 : 3; // always show 3 slots

    for (int i = 0; i < take; i++) {
      if (i < count) {
        final m = movimientos[i];
        final name = m['nombre'] ?? '';
        final fechaStr = m['fecha'] ?? '';
        DateTime d;
        try {
          d = DateTime.parse(fechaStr);
        } catch (_) {
          d = DateTime.now();
        }
        final isIngreso = (m['is_ingreso'] == 1);
        final cant = (m['cantidad'] is int)
            ? m['cantidad'] as int
            : int.tryParse('${m['cantidad']}') ?? 0;

        items.add(
          TransactionCardSmall(
            amount: cant,
            isIncome: isIngreso,
            name: name,
            date: d,
          ),
        );
      } else {
        items.add(TransactionCardSmall());
      }
    }

    return items;
  }

  List<Widget> _buildPresupuestos() {
    final List<Widget> items = [];
    final count = presupuestos.length;
    final take = count >= 2 ? 2 : count;

    for (int i = 0; i < take; i++) {
      final p = presupuestos[i];
      final name = p['nombre'] ?? '';
      final monto = (p['monto'] is int)
          ? p['monto'] as int
          : int.tryParse('${p['monto']}') ?? 0;
      items.add(BudgetCardSmall(name: name, amount: monto));
    }

    return items;
  }
}
