import 'package:flutter/material.dart';
import '../../core/colors.dart';
import '../../core/database/db_helper.dart';
import '../../core/utils/transactions_calculator.dart';
import '../../components/money_display.dart';
import '../../components/transaction_card_small.dart';
import '../../components/budget_card_small.dart';
// import '../transactions/create_transactions.dart';
import '../categories/category_list.dart';
import '../../screens/transactions/list_transactions.dart';
import '../presupuestos/presupuesto_list.dart';
import '../presupuestos/create_presupuesto.dart';

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
    loadData();
  }

  Future<void> loadData() async {
    final dbh = DatabaseHelper.instance;
    final db = await dbh.database;

    final allMov = await dbh.readMovimientos();
    final int userId = (widget.user['id'] is int)
        ? widget.user['id'] as int
        : int.tryParse('${widget.user['id']}') ?? 1;
    // filter by usuario_id y ordenar por fecha descendente (más nuevos primero)
    final userMov = allMov.where((m) => m['usuario_id'] == userId).toList();
    userMov.sort((a, b) {
      String getDateTimeStr(Map<String, dynamic> m) {
        final fecha = m['fecha'] ?? '';
        final hora = m['hora'] ?? '';
        if (fecha is String && fecha.isNotEmpty) {
          if (hora is String && hora.isNotEmpty) {
            // Unir fecha y hora para comparar
            return '$fecha $hora';
          }
          return fecha;
        }
        return '';
      }
      final strA = getDateTimeStr(a);
      final strB = getDateTimeStr(b);
      // Si ambos tienen fecha (y posiblemente hora), comparar como DateTime
      if (strA.isNotEmpty && strB.isNotEmpty) {
        try {
          final dtA = DateTime.parse(strA.replaceAll('/', '-'));
          final dtB = DateTime.parse(strB.replaceAll('/', '-'));
          return dtB.compareTo(dtA); // descendente
        } catch (_) {
          // Si falla el parseo, comparar como string
          return strB.compareTo(strA);
        }
      }
      // Fallback: comparar por id descendente
      final ida = a['id'] is int ? a['id'] as int : int.tryParse('${a['id']}') ?? 0;
      final idb = b['id'] is int ? b['id'] as int : int.tryParse('${b['id']}') ?? 0;
      return idb.compareTo(ida);
    });

    // Obtener información de categorías para enriquecer los movimientos
    final categories = await dbh.readCategorias(userId);
    final categoryMap = {
      for (final cat in categories)
        cat['id']: {'nombre': cat['nombre'], 'color': cat['color'], 'icono': cat['icono']}
    };

    // Enriquecer movimientos con información de categorías
    final enrichedMov = userMov.map((m) {
      final catId = (m['categoria_id'] is int)
          ? m['categoria_id'] as int
          : int.tryParse('${m['categoria_id']}') ?? 0;
      final catInfo = categoryMap[catId];
      return {
        ...m,
        'categoria_nombre': catInfo?['nombre'] ?? 'Sin categoría',
        'categoria_color': catInfo?['color'],
        'categoria_icono': catInfo?['icono'] ?? '📁',
      };
    }).toList();

    final ingresos = await TransactionsCalculator.getTotalIngresosUltimoMes(
      userId: userId,
    );
    final gastos = await TransactionsCalculator.getTotalGastosUltimoMes(
      userId: userId,
    );

    // budgets
    final pres = await db.query(
      'Presupuestos',
      where: 'usuario_id = ?',
      whereArgs: [userId],
      orderBy: 'id ASC',
    );

    final enrichedPres = <Map<String, dynamic>>[];
    for (final p in pres) {
      final presId = p['id'] as int;
      
      // Consultar categorías asociadas a este presupuesto
      final catRels = await db.query(
        'Presupuestos_Categorias',
        where: 'id_presupuesto = ?',
        whereArgs: [presId],
      );

      final categoryIds = catRels.map((r) => r['id_categoria'] as int).toList();
      
      // Filtrar de la lista general de categorías que ya descargamos arriba
      final catDetails = categories
          .where((c) => categoryIds.contains(c['id']))
          .toList();

      // Calcular gasto del presupuesto iterando sobre los movimientos del usuario (userMov)
      int totalGasto = 0;
      for (final m in userMov) {
        final movCatId = (m['categoria_id'] is int)
            ? m['categoria_id'] as int
            : int.tryParse('${m['categoria_id']}') ?? 0;

        // Si es un gasto y pertenece a una de las categorías del presupuesto
        if (m['is_ingreso'] == 0 && categoryIds.contains(movCatId)) {
          final cant = (m['cantidad'] is int)
              ? m['cantidad'] as int
              : int.tryParse('${m['cantidad']}') ?? 0;
          totalGasto += cant;
        }
      }

      final presupuestoMonto = p['monto'] as int;
      final restante = presupuestoMonto - totalGasto;
      final esExcedido = restante < 0;

      enrichedPres.add({
        ...p,
        'categorias': catDetails,
        'gasto_total': totalGasto,
        'restante': restante,
        'es_excedido': esExcedido,
      });
    }

    if (!mounted) return;

    setState(() {
      totalIngresos = ingresos;
      totalGastos = gastos;
      saldo = ingresos - gastos;
      movimientos = enrichedMov;
      presupuestos = enrichedPres;
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
                  const SizedBox(height: 6),
                  MoneyDisplay(
                    amount: totalIngresos,
                    color: AppColors.income(context),
                    sizeFont: 24,
                    iconAtLeft: 'assets/svgs/up-trend-svgrepo-com.svg',
                  ),
                  const SizedBox(height: 3),
                  MoneyDisplay(
                    amount: totalGastos,
                    color: AppColors.expense(context),
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
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ListTransactionsScreen(user: widget.user),
                        ),
                      ).then((_) => loadData());
                    },
                    child: Row(
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
                  ).then((_) => loadData());
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
                  GestureDetector(
                    onTap: () {
                      if (presupuestos.isEmpty) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                CreatePresupuestoScreen(user: widget.user),
                          ),
                        ).then((_) => loadData());
                      } else {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                PresupuestoListScreen(user: widget.user),
                          ),
                        ).then((_) => loadData());
                      }
                    },
                    child: Row(
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
        final name = m['categoria_nombre'] ?? m['nombre'] ?? '';
        final fechaStr = m['fecha'] ?? '';

        // Obtener color de la categoría
        final categoryColorHex = m['categoria_color'];
        final catColor = (categoryColorHex is String && categoryColorHex.startsWith('#'))
            ? Color(int.parse(categoryColorHex.replaceFirst('#', '0xff')))
            : AppColors.primary(context);

        final categoryIcon = m['categoria_icono'] ?? '📁';

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
            categoryColor: catColor,
            categoryIcon: categoryIcon,
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
      final restante = p['restante'] as int? ?? monto;
      final gastoTotal = p['gasto_total'] as int? ?? 0;
      final esExcedido = p['es_excedido'] as bool? ?? false;
      items.add(
        BudgetCardSmall(
          name: name, 
          amount: monto,
          restante: restante,        // <- NUEVO
          gastoTotal: gastoTotal,    // <- NUEVO
          esExcedido: esExcedido,    // <- NUEVO
        )
      );
    }

    return items;
  }
}
