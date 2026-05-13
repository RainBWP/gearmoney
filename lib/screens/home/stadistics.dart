import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/colors.dart';
import '../../core/database/db_helper.dart';
import '../../components/money_display.dart';

class StadisticsScreen extends StatefulWidget {
  final Map<String, dynamic> user;

  const StadisticsScreen({super.key, required this.user});

  @override
  State<StadisticsScreen> createState() => _StadisticsScreenState();
}

class _StadisticsScreenState extends State<StadisticsScreen> {
  bool _isLoading = true;
  bool _showAnnualView = false;

  // Period filter
  DateTimeRange _selectedPeriod = DateTimeRange(
    start: DateTime.now().subtract(Duration(days: 30)),
    end: DateTime.now(),
  );

  // Data
  List<Map<String, dynamic>> _transactions = [];
  List<Map<String, dynamic>> _categories = [];

  // Annual data
  int _selectedYear = DateTime.now().year;
  List<Map<String, dynamic>> _monthlyDataAnnual = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final int userId = (widget.user['id'] is int)
          ? widget.user['id'] as int
          : int.tryParse('${widget.user['id']}') ?? 1;

      final allTransactions = await DatabaseHelper.instance.readMovimientos();
      final userTransactions = allTransactions
          .where((t) => t['usuario_id'] == userId)
          .toList();

      final categories = await DatabaseHelper.instance.readCategorias(userId);

      if (mounted) {
        setState(() {
          _transactions = userTransactions;
          _categories = categories;
          _isLoading = false;
        });

        if (_showAnnualView) {
          await _loadAnnualData();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    }
  }

  Future<void> _loadAnnualData() async {
    final monthlyData = <Map<String, int>>[];

    for (int month = 1; month <= 12; month++) {
      final startDate = DateTime(_selectedYear, month, 1);
      final endDate = DateTime(_selectedYear, month + 1, 0);

      final monthTransactions = _getTransactionsInPeriod(
        DateTimeRange(start: startDate, end: endDate),
      );

      final ingresos = monthTransactions
          .where((t) => t['is_ingreso'] == 1)
          .fold(0, (sum, t) => sum + ((t['cantidad'] as int? ?? 0)));

      final gastos = monthTransactions
          .where((t) => t['is_ingreso'] != 1)
          .fold(0, (sum, t) => sum + ((t['cantidad'] as int? ?? 0)));

      monthlyData.add({
        'ingresos': ingresos,
        'gastos': gastos,
        'saldo': ingresos - gastos,
      });
    }

    setState(() => _monthlyDataAnnual = monthlyData);
  }

  List<Map<String, dynamic>> _getTransactionsInPeriod(DateTimeRange period) {
    return _transactions.where((t) {
      try {
        final dt = DateTime.parse(t['fecha'] as String);
        return !dt.isBefore(period.start) &&
            !dt.isAfter(
              DateTime(
                period.end.year,
                period.end.month,
                period.end.day,
                23,
                59,
                59,
              ),
            );
      } catch (_) {
        return false;
      }
    }).toList();
  }

  Color _hexToColor(String hex) {
    try {
      var h = hex.replaceAll('#', '');
      if (h.length == 6) h = 'FF$h';
      return Color(int.parse(h, radix: 16));
    } catch (_) {
      return Colors.grey;
    }
  }

  Future<void> _selectPeriod() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _selectedPeriod,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: AppColors.primary(context),
              onPrimary:
                  Colors.black, // Color del texto sobre el circulo de seleccion
              surface: AppColors.background(context),
              onSurface: AppColors.textPrimary(context),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && mounted) {
      setState(() {
        _selectedPeriod = picked;
        _showAnnualView = false;
      });
    }
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
            : Column(
                children: [
                  _buildHeader(),
                  Expanded(
                    child: _showAnnualView
                        ? _buildAnnualView()
                        : _buildPeriodView(),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Estadísticas',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary(context),
                ),
              ),
              IconButton(
                onPressed: () {
                  setState(() {
                    _showAnnualView = !_showAnnualView;
                  });
                  if (_showAnnualView) {
                    _loadAnnualData();
                  }
                },
                icon: Icon(
                  _showAnnualView
                      ? Icons.calendar_today
                      : Icons.calendar_view_month,
                  color: AppColors.primary(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (!_showAnnualView)
            GestureDetector(
              onTap: _selectPeriod,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: AppColors.cardBackground(context),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${DateFormat('dd/MM/yy').format(_selectedPeriod.start)} - ${DateFormat('dd/MM/yy').format(_selectedPeriod.end)}',
                      style: TextStyle(
                        color: AppColors.textPrimary(context),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Icon(
                      Icons.edit_calendar,
                      color: AppColors.primary(context),
                      size: 20,
                    ),
                  ],
                ),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.cardBackground(context),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: () {
                      setState(() => _selectedYear--);
                      _loadAnnualData();
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
                      _loadAnnualData();
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
    );
  }

  Widget _buildPeriodView() {
    final periodTransactions = _getTransactionsInPeriod(_selectedPeriod);

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      children: [
        _buildSummaryCard(periodTransactions),
        const SizedBox(height: 16),
        _buildCategoryPieChart(periodTransactions),
        const SizedBox(height: 16),
        _buildPaymentMethodBreakdown(periodTransactions),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildSummaryCard(List<Map<String, dynamic>> transactions) {
    final ingresos = transactions
        .where((t) => t['is_ingreso'] == 1)
        .fold(0, (sum, t) => sum + ((t['cantidad'] as int? ?? 0)));

    final gastos = transactions
        .where((t) => t['is_ingreso'] != 1)
        .fold(0, (sum, t) => sum + ((t['cantidad'] as int? ?? 0)));

    final saldo = ingresos - gastos;

    final numIngresos = transactions.where((t) => t['is_ingreso'] == 1).length;
    final numGastos = transactions.where((t) => t['is_ingreso'] != 1).length;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBackground(context),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Resumen del periodo',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary(context),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    MoneyDisplay(
                      amount: ingresos,
                      color: AppColors.income(context),
                      sizeFont: 24,
                      iconAtLeft: 'assets/svgs/up-trend-svgrepo-com.svg',
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$numIngresos transacciones',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary(context),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    MoneyDisplay(
                      amount: gastos,
                      color: AppColors.expense(context),
                      sizeFont: 24,
                      iconAtLeft:
                          'assets/svgs/down-trend-round-svgrepo-com.svg',
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$numGastos transacciones',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary(context),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(
            color: AppColors.textSecondary(context).withValues(alpha: 0.2),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Saldo restante',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary(context),
                ),
              ),
              MoneyDisplay(
                amount: saldo,
                color: saldo >= 0
                    ? AppColors.income(context)
                    : AppColors.expense(context),
                sizeFont: 20,
                iconAtLeft: null,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryPieChart(List<Map<String, dynamic>> transactions) {
    final expenses = transactions.where((t) => t['is_ingreso'] != 1).toList();

    if (expenses.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.cardBackground(context),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Text(
            'No hay gastos en este periodo',
            style: TextStyle(color: AppColors.textSecondary(context)),
          ),
        ),
      );
    }

    // Group by category
    final categoryTotals = <int, int>{};
    for (var t in expenses) {
      final catId = (t['categoria_id'] as int? ?? 0);
      final amount = (t['cantidad'] as int? ?? 0);
      categoryTotals[catId] = (categoryTotals[catId] ?? 0) + amount;
    }

    final total = categoryTotals.values.fold(0, (sum, amount) => sum + amount);

    // Create pie segments
    final segments = <Map<String, dynamic>>[];
    for (var entry in categoryTotals.entries) {
      final cat = _categories.firstWhere(
        (c) => c['id'] == entry.key,
        orElse: () => {
          'nombre': 'Sin categoría',
          'color': '#999999',
          'icono': '📁',
        },
      );

      segments.add({
        'categoryId': entry.key,
        'amount': entry.value,
        'percentage': total > 0 ? (entry.value / total) : 0.0,
        'name': cat['nombre'] ?? 'Sin categoría',
        'color': _hexToColor(cat['color'] as String? ?? '#999999'),
        'icon': cat['icono'] ?? '📁',
      });
    }

    segments.sort((a, b) => (b['amount'] as int).compareTo(a['amount'] as int));

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBackground(context),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Gastos por categoría',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary(context),
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: SizedBox(
              width: 200,
              height: 200,
              child: CustomPaint(painter: _PieChartPainter(segments: segments)),
            ),
          ),
          const SizedBox(height: 24),
          ...segments.map(
            (seg) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: seg['color'] as Color,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      seg['icon'] as String,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      seg['name'] as String,
                      style: TextStyle(
                        color: AppColors.textPrimary(context),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      MoneyDisplay(
                        amount: seg['amount'] as int,
                        color: AppColors.textPrimary(context),
                        sizeFont: 14,
                        iconAtLeft: null,
                      ),
                      Text(
                        '${((seg['percentage'] as double) * 100).toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary(context),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodBreakdown(List<Map<String, dynamic>> transactions) {
    final methodLabels = ['Efectivo', 'Tarjeta', 'Transferencia'];
    final methodTotals = <int, Map<String, int>>{
      0: {'ingresos': 0, 'gastos': 0},
      1: {'ingresos': 0, 'gastos': 0},
      2: {'ingresos': 0, 'gastos': 0},
    };

    for (var t in transactions) {
      final method = (t['metodo_pago'] as int? ?? 0);
      final amount = (t['cantidad'] as int? ?? 0);
      final isIngreso = t['is_ingreso'] == 1;

      if (isIngreso) {
        methodTotals[method]!['ingresos'] =
            (methodTotals[method]!['ingresos'] ?? 0) + amount;
      } else {
        methodTotals[method]!['gastos'] =
            (methodTotals[method]!['gastos'] ?? 0) + amount;
      }
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBackground(context),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Desglose por método de pago',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary(context),
            ),
          ),
          const SizedBox(height: 16),
          ...methodTotals.entries.map((entry) {
            final method = entry.key;
            final ingresos = entry.value['ingresos'] ?? 0;
            final gastos = entry.value['gastos'] ?? 0;
            final saldo = ingresos - gastos;

            if (ingresos == 0 && gastos == 0) return const SizedBox.shrink();

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.background(context),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    methodLabels[method],
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
                          MoneyDisplay(
                            amount: ingresos,
                            color: AppColors.income(context),
                            sizeFont: 14,
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
                          MoneyDisplay(
                            amount: gastos,
                            color: AppColors.expense(context),
                            sizeFont: 14,
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
                          MoneyDisplay(
                            amount: saldo,
                            color: saldo >= 0
                                ? AppColors.income(context)
                                : AppColors.expense(context),
                            sizeFont: 14,
                            iconAtLeft: null,
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildAnnualView() {
    final monthNames = [
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

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      itemCount: 12,
      itemBuilder: (context, index) {
        final monthData = index < _monthlyDataAnnual.length
            ? _monthlyDataAnnual[index]
            : {'ingresos': 0, 'gastos': 0, 'saldo': 0};

        final ingresos = monthData['ingresos'] ?? 0;
        final gastos = monthData['gastos'] ?? 0;
        final saldo = monthData['saldo'] ?? 0;

        // Get top 3 categories for this month
        final monthStart = DateTime(_selectedYear, index + 1, 1);
        final monthEnd = DateTime(_selectedYear, index + 2, 0);
        final monthTransactions = _getTransactionsInPeriod(
          DateTimeRange(start: monthStart, end: monthEnd),
        );

        final topCategories = _getTopCategories(monthTransactions, 3);

        return GestureDetector(
          onTap: () {
            setState(() {
              _showAnnualView = false;
              _selectedPeriod = DateTimeRange(start: monthStart, end: monthEnd);
            });
          },
          child: Container(
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
                  monthNames[index],
                  style: TextStyle(
                    fontSize: 18,
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
                        MoneyDisplay(
                          amount: ingresos,
                          color: AppColors.income(context),
                          sizeFont: 14,
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
                        MoneyDisplay(
                          amount: gastos,
                          color: AppColors.expense(context),
                          sizeFont: 14,
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
                        MoneyDisplay(
                          amount: saldo,
                          color: saldo >= 0
                              ? AppColors.income(context)
                              : AppColors.expense(context),
                          sizeFont: 14,
                          iconAtLeft: null,
                        ),
                      ],
                    ),
                  ],
                ),
                if (topCategories.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Divider(
                    color: AppColors.textSecondary(
                      context,
                    ).withValues(alpha: 0.2),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Top 3 categorías',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary(context),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...topCategories.map(
                    (cat) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: cat['color'] as Color,
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              cat['icon'] as String,
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              cat['name'] as String,
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textPrimary(context),
                              ),
                            ),
                          ),
                          MoneyDisplay(
                            amount: cat['amount'] as int,
                            color: AppColors.textSecondary(context),
                            sizeFont: 12,
                            iconAtLeft: null,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  List<Map<String, dynamic>> _getTopCategories(
    List<Map<String, dynamic>> transactions,
    int limit,
  ) {
    final expenses = transactions.where((t) => t['is_ingreso'] != 1).toList();

    if (expenses.isEmpty) return [];

    final categoryTotals = <int, int>{};
    for (var t in expenses) {
      final catId = (t['categoria_id'] as int? ?? 0);
      final amount = (t['cantidad'] as int? ?? 0);
      categoryTotals[catId] = (categoryTotals[catId] ?? 0) + amount;
    }

    final segments = <Map<String, dynamic>>[];
    for (var entry in categoryTotals.entries) {
      final cat = _categories.firstWhere(
        (c) => c['id'] == entry.key,
        orElse: () => {
          'nombre': 'Sin categoría',
          'color': '#999999',
          'icono': '📁',
        },
      );

      segments.add({
        'amount': entry.value,
        'name': cat['nombre'] ?? 'Sin categoría',
        'color': _hexToColor(cat['color'] as String? ?? '#999999'),
        'icon': cat['icono'] ?? '📁',
      });
    }

    segments.sort((a, b) => (b['amount'] as int).compareTo(a['amount'] as int));

    return segments.take(limit).toList();
  }
}

class _PieChartPainter extends CustomPainter {
  final List<Map<String, dynamic>> segments;

  _PieChartPainter({required this.segments});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;

    double startAngle = -math.pi / 2;

    for (var segment in segments) {
      final percentage = segment['percentage'] as double;
      final sweepAngle = 2 * math.pi * percentage;
      final color = segment['color'] as Color;

      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        true,
        paint,
      );

      startAngle += sweepAngle;
    }

    // Draw center circle for donut effect
    final centerPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, radius * 0.5, centerPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
