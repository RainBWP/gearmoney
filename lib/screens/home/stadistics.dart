import 'package:flutter/material.dart';
import '../../core/colors.dart';
import '../../core/utils/transactions_calculator.dart';
import '../../components/money_display.dart';

class StadisticsScreen extends StatefulWidget {
  final Map<String, dynamic> user;

  const StadisticsScreen({super.key, required this.user});

  @override
  State<StadisticsScreen> createState() => _StadisticsScreenState();
}

class _StadisticsScreenState extends State<StadisticsScreen> {
  late int _selectedYear;
  List<Map<String, int>> _monthlyData = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _selectedYear = DateTime.now().year;
    _loadYearlyData();
  }

  Future<void> _loadYearlyData() async {
    setState(() => _isLoading = true);

    try {
      final int userId = (widget.user['id'] is int)
          ? widget.user['id'] as int
          : int.tryParse('${widget.user['id']}') ?? 1;

      final data = await TransactionsCalculator.getResumenMensualPorAnio(
        userId: userId,
        year: _selectedYear,
      );

      if (mounted) {
        setState(() {
          _monthlyData = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  List<String> _getMonthNames() {
    return [
      'Enero',
      'Febrero',
      'Marzo',
      'Abril',
      'Mayo',
      'Junio',
      'Julio',
      'Agosto',
      'Septiembre',
      'Octubre',
      'Noviembre',
      'Diciembre',
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background(context),
      body: SafeArea(
        child: _isLoading
            ? Center(
                child: CircularProgressIndicator(
                  color: AppColors.primary(context),
                ),
              )
            : ListView(
                padding: const EdgeInsets.all(32),
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'Estadísticas',
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary(context),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.cardBackground(context),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            GestureDetector(
                              onTap: () {
                                setState(() => _selectedYear--);
                                _loadYearlyData();
                              },
                              child: Icon(
                                Icons.chevron_left,
                                color: AppColors.primary(context),
                              ),
                            ),
                            SizedBox(
                              width: 60,
                              child: Text(
                                _selectedYear.toString(),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary(context),
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                setState(() => _selectedYear++);
                                _loadYearlyData();
                              },
                              child: Icon(
                                Icons.chevron_right,
                                color: AppColors.primary(context),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  ..._buildMonthCards(),
                ],
              ),
      ),
    );
  }

  List<Widget> _buildMonthCards() {
    final monthNames = _getMonthNames();
    final widgets = <Widget>[];

    for (int i = 0; i < _monthlyData.length; i++) {
      final month = _monthlyData[i];
      final ingresos = month['ingresos'] ?? 0;
      final gastos = month['gastos'] ?? 0;
      final saldo = month['saldo'] ?? 0;

      widgets.add(
        Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.cardBackground(context),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                monthNames[i],
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary(context),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ingresos',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary(context),
                        ),
                      ),
                      const SizedBox(height: 4),
                      MoneyDisplay(
                        amount: ingresos,
                        color: AppColors.income(context),
                        sizeFont: 16,
                        iconAtLeft: null,
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Gastos',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary(context),
                        ),
                      ),
                      const SizedBox(height: 4),
                      MoneyDisplay(
                        amount: gastos,
                        color: AppColors.expense(context),
                        sizeFont: 16,
                        iconAtLeft: null,
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Saldo',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary(context),
                        ),
                      ),
                      const SizedBox(height: 4),
                      MoneyDisplay(
                        amount: saldo,
                        color: saldo >= 0
                            ? AppColors.income(context)
                            : AppColors.expense(context),
                        sizeFont: 16,
                        iconAtLeft: null,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    return widgets;
  }
}
