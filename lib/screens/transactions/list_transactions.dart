import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter/services.dart';
import '../../core/colors.dart';
import '../../core/database/db_helper.dart';
import '../../components/money_display.dart';
import '../../components/category_chip.dart';
import 'create_transactions.dart';

// hola
class ListTransactionsScreen extends StatefulWidget {
  final Map<String, dynamic> user;

  const ListTransactionsScreen({super.key, required this.user});

  @override
  State<ListTransactionsScreen> createState() => _ListTransactionsScreenState();
}

class _ListTransactionsScreenState extends State<ListTransactionsScreen> {
  List<Map<String, dynamic>> _transactions = [];
  List<Map<String, dynamic>> _categories = [];
  bool _isLoading = true;
  // Filters
  final Set<int> _selectedCategoryIds = {};
  DateTimeRange? _selectedDateRange;
  int _typeFilter = 0; // 0 = all, 1 = expense, 2 = income

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
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
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al cargar: $e')));
      }
    }
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

  Future<String?> _resolveAssetPath(String asset) async {
    try {
      await rootBundle.load(asset);
      return asset;
    } catch (_) {}
    try {
      final alt = 'assets/svgs/$asset';
      await rootBundle.load(alt);
      return alt;
    } catch (_) {}
    return null;
  }

  Widget _safeSvg(String asset, {double? width, double? height, Color? color}) {
    return FutureBuilder<String?>(
      future: _resolveAssetPath(asset),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return SizedBox(width: width, height: height, child: Center(child: SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary(context)))));
        }
        final path = snapshot.data;
        if (path != null) {
          return SvgPicture.asset(path, width: width, height: height, colorFilter: color != null ? ColorFilter.mode(color, BlendMode.srcIn) : null);
        }
        return Icon(Icons.image, size: width ?? height ?? 16, color: AppColors.textSecondary(context));
      },
    );
  }

  List<Map<String, dynamic>> get _filteredTransactions {
    var list = _transactions.where((t) => true).toList();

    // type filter
    if (_typeFilter == 1) {
      list = list.where((t) => t['is_ingreso'] == 0 || t['is_ingreso'] == false).toList();
    } else if (_typeFilter == 2) {
      list = list.where((t) => t['is_ingreso'] == 1 || t['is_ingreso'] == true).toList();
    }

    // category filter
    if (_selectedCategoryIds.isNotEmpty) {
      list = list.where((t) {
        final cid = (t['categoria_id'] is int) ? t['categoria_id'] as int : int.tryParse('${t['categoria_id']}') ?? 0;
        return _selectedCategoryIds.contains(cid);
      }).toList();
    }

    // date range filter
    if (_selectedDateRange != null) {
      list = list.where((t) {
        final dt = DateTime.parse(t['fecha'] as String);
        return !dt.isBefore(_selectedDateRange!.start) && !dt.isAfter(_selectedDateRange!.end);
      }).toList();
    }

    // sort desc
    list.sort((a, b) => (b['fecha'] as String).compareTo(a['fecha'] as String));
    return list;
  }

  Map<String, List<Map<String, dynamic>>> _groupByMonth(List<Map<String, dynamic>> txs) {
    final map = <String, List<Map<String, dynamic>>>{};
    for (var t in txs) {
      final dt = DateTime.parse(t['fecha'] as String);
      final key = DateFormat('yyyy-MM').format(dt);
      map.putIfAbsent(key, () => []).add(t);
    }
    return Map.fromEntries(map.entries.toList()
      ..sort((a, b) => b.key.compareTo(a.key)));
  }

  Future<void> _deleteTransaction(int id) async {
    try {
      await DatabaseHelper.instance.deleteMovimiento(id);
      await _loadData();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Movimiento eliminado')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al eliminar: $e')));
      }
    }
  }


  Future<void> _openCategorySelector() async {
    final selected = Set<int>.from(_selectedCategoryIds);
    await showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: AppColors.cardBackground(context),
        child: SizedBox(
          width: 320,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: Text('Seleccionar categorías', style: TextStyle(color: AppColors.textPrimary(context), fontWeight: FontWeight.w600)),
              ),
              Flexible(
                child: SingleChildScrollView(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _categories.map((c) {
                      final id = c['id'] as int;
                      final color = _hexToColor(c['color'] as String);
                      final icon = c['icono'] as String? ?? '';
                      final name = c['nombre'] as String? ?? '';
                      final selectedHere = selected.contains(id);
                      return GestureDetector(
                        onTap: () => setState(() {
                          if (selected.contains(id))
                            selected.remove(id);
                          else
                            selected.add(id);
                        }),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                          decoration: BoxDecoration(
                            color: selectedHere ? AppColors.primary(context).withValues(alpha: 0.12) : AppColors.background(context),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.textSecondary(context).withValues(alpha: 0.06)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(width: 28, height: 28, decoration: BoxDecoration(color: color, shape: BoxShape.circle), alignment: Alignment.center, child: Text(icon)),
                              const SizedBox(width: 8),
                              Text(name, style: TextStyle(color: AppColors.textPrimary(context))),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancelar', style: TextStyle(color: AppColors.textSecondary(context)))),
                  TextButton(onPressed: () {
                    setState(() {
                      _selectedCategoryIds
                        ..clear()
                        ..addAll(selected);
                    });
                    Navigator.pop(context);
                  }, child: Text('Aplicar')),
                ],
              )
            ],
          ),
        ),
      ),
    );
    setState(() {});
  }

  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 10),
      lastDate: DateTime(now.year + 1),
      initialDateRange: _selectedDateRange ?? DateTimeRange(start: now.subtract(const Duration(days: 30)), end: now),
    );
    if (picked != null) setState(() => _selectedDateRange = picked);
  }

  Widget _buildTransactionItem({
    required bool isIngreso,
    required int cantidad,
    required String fecha,
    required Color categoryColor,
    required String categoryIcon,
    required String nombre,
    String? descripcion,
    required VoidCallback onDelete,
    required Map<String, dynamic> transactionData,
  }) {
    final color = isIngreso ? AppColors.income(context) : AppColors.expense(context);
    final shortDesc = (descripcion ?? '').length > 20 ? '${(descripcion ?? '').substring(0, 20)}...' : (descripcion ?? '');

    return Dismissible(
      key: UniqueKey(),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete(),
      background: Container(
        margin: const EdgeInsets.only(bottom: 16),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: AppColors.alert(context),
          borderRadius: BorderRadius.circular(999),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: GestureDetector(
        onLongPress: () async {
          final result = await Navigator.of(context).push<bool>(
            MaterialPageRoute(
              builder: (context) => CreateTransactionScreen(user: widget.user, transactionToEdit: transactionData),
            ),
          );
          if (result == true) {
            _loadData();
          }
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: color),
          ),
          child: Row(
            children: [
              // left pill icon
              CategoryChip(color: categoryColor, icon: categoryIcon, size: 44),
              const SizedBox(width: 12),
              // middle texts
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(nombre, style: TextStyle(color: AppColors.textPrimary(context), fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(shortDesc, style: TextStyle(color: AppColors.textSecondary(context), fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                ]),
              ),
              const SizedBox(width: 12),
              // right amount and date
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                MoneyDisplay(amount: cantidad, color: color, sizeFont: 14, iconAtLeft: null),
                const SizedBox(height: 6),
                Text(DateFormat('dd/MM').format(DateTime.parse(fecha)), style: TextStyle(color: AppColors.textSecondary(context), fontSize: 12)),
              ])
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background(context),
      appBar: AppBar(
        backgroundColor: AppColors.background(context),
        elevation: 0,
        title: Text(
          'Movimientos',
          style: TextStyle(
            color: AppColors.textPrimary(context),
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: AppColors.primary(context),
              ),
            )
          : _transactions.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.receipt_long,
                        size: 64,
                        color: AppColors.textSecondary(context),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No hay movimientos',
                        style: TextStyle(
                          color: AppColors.textSecondary(context),
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // Filters row
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            // Category filter opener
                            GestureDetector(
                              onTap: () => _openCategorySelector(),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                margin: const EdgeInsets.only(right: 8),
                                decoration: BoxDecoration(
                                  color: AppColors.cardBackground(context),
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(color: AppColors.textSecondary(context).withValues(alpha: 0.08)),
                                ),
                                child: Row(
                                  children: [
                                    _safeSvg('assets/svgs/menu-alt-svgrepo-com.svg', width: 16, height: 16, color: AppColors.textPrimary(context)),
                                    const SizedBox(width: 8),
                                    Text(
                                      _selectedCategoryIds.isEmpty ? 'Categoría' : 'Categoría (${_selectedCategoryIds.length})',
                                      style: TextStyle(color: AppColors.textPrimary(context)),
                                    ),
                                    if (_selectedCategoryIds.isNotEmpty) ...[
                                      const SizedBox(width: 8),
                                      GestureDetector(
                                        onTap: () => setState(() => _selectedCategoryIds.clear()),
                                        child: Icon(Icons.close, size: 16, color: AppColors.textSecondary(context)),
                                      ),
                                    ]
                                  ],
                                ),
                              ),
                            ),

                            // Date range filter
                            GestureDetector(
                              onTap: () => _pickDateRange(),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                margin: const EdgeInsets.only(right: 8),
                                decoration: BoxDecoration(
                                  color: AppColors.cardBackground(context),
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(color: AppColors.textSecondary(context).withValues(alpha: 0.08)),
                                ),
                                child: Row(
                                  children: [
                                    _safeSvg('assets/svgs/calendar-lines-svgrepo-com.svg', width: 16, height: 16, color: AppColors.textPrimary(context)),
                                    const SizedBox(width: 8),
                                    Text(
                                      _selectedDateRange == null ? 'Fecha' : '${DateFormat('dd/MM/yyyy').format(_selectedDateRange!.start)} - ${DateFormat('dd/MM/yyyy').format(_selectedDateRange!.end)}',
                                      style: TextStyle(color: AppColors.textPrimary(context)),
                                    ),
                                    if (_selectedDateRange != null) ...[
                                      const SizedBox(width: 8),
                                      GestureDetector(
                                        onTap: () => setState(() => _selectedDateRange = null),
                                        child: Icon(Icons.close, size: 16, color: AppColors.textSecondary(context)),
                                      ),
                                    ]
                                  ],
                                ),
                              ),
                            ),

                            // Type pill
                            GestureDetector(
                              onTap: () => setState(() => _typeFilter = (_typeFilter + 1) % 3),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                margin: const EdgeInsets.only(right: 8),
                                decoration: BoxDecoration(
                                  color: AppColors.cardBackground(context),
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(color: AppColors.textSecondary(context).withValues(alpha: 0.08)),
                                ),
                                child: Row(
                                  children: [
                                    _safeSvg('assets/svgs/money-stack-svgrepo-com.svg', width: 16, height: 16, color: AppColors.textPrimary(context)),
                                    const SizedBox(width: 8),
                                    Text(
                                      _typeFilter == 0 ? 'Gasto/Ingreso' : _typeFilter == 1 ? 'Gasto' : 'Ingreso',
                                      style: TextStyle(color: _typeFilter == 0 ? AppColors.textPrimary(context) : _typeFilter == 1 ? AppColors.expense(context) : AppColors.income(context)),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Selected category pills
                    if (_selectedCategoryIds.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _selectedCategoryIds.map((cid) {
                            final cat = _categories.firstWhere((c) => c['id'] == cid, orElse: () => <String, dynamic>{});
                            if (cat.isEmpty) return const SizedBox.shrink();
                            final color = _hexToColor(cat['color'] as String);
                            final icon = cat['icono'] as String? ?? '';
                            final name = cat['nombre'] as String? ?? '';
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                              decoration: BoxDecoration(color: AppColors.cardBackground(context), borderRadius: BorderRadius.circular(999)),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  CategoryChip(color: color, icon: icon, label: name, size: 28, onTap: () {}),
                                  const SizedBox(width: 8),
                                  GestureDetector(onTap: () => setState(() => _selectedCategoryIds.remove(cid)), child: Icon(Icons.close, size: 16, color: AppColors.textSecondary(context))),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),

                    // List grouped by month
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.all(16),
                        children: () {
                          final filtered = _filteredTransactions;
                          final grouped = _groupByMonth(filtered);
                          final widgets = <Widget>[];
                          for (var entry in grouped.entries) {
                            final key = entry.key; // yyyy-MM
                            final sampleDate = DateTime.parse('${key}-01');
                            final monthLabel = DateFormat('MMMM yyyy').format(sampleDate);
                            widgets.add(Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Text('--- $monthLabel ---', style: TextStyle(color: AppColors.textSecondary(context), fontWeight: FontWeight.w600)),
                            ));
                            for (var t in entry.value) {
                              final isIngreso = t['is_ingreso'] == 1;
                              final cantidad = (t['cantidad'] is int) ? t['cantidad'] as int : int.tryParse('${t['cantidad']}') ?? 0;
                              final fecha = t['fecha'] as String;
                              final cid = (t['categoria_id'] is int) ? t['categoria_id'] as int : int.tryParse('${t['categoria_id']}') ?? 0;
                              final cat = _categories.firstWhere((c) => c['id'] == cid, orElse: () => <String, dynamic>{});
                              final catColor = cat.isNotEmpty ? _hexToColor(cat['color'] as String) : AppColors.textSecondary(context);
                              final catIcon = cat.isNotEmpty ? (cat['icono'] as String? ?? '') : '';
                              final name = t['nombre'] as String? ?? '';
                              final descripcion = t['descripcion'] as String? ?? '';
                              widgets.add(_buildTransactionItem(isIngreso: isIngreso, cantidad: cantidad, fecha: fecha, categoryColor: catColor, categoryIcon: catIcon, nombre: name, descripcion: descripcion, onDelete: () => _deleteTransaction(t['id'] as int), transactionData: t));
                            }
                          }
                          return widgets;
                        }(),
                      ),
                    ),
                  ],
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.of(context).push<bool>(
            MaterialPageRoute(
              builder: (context) => CreateTransactionScreen(user: widget.user),
            ),
          );
          if (result == true) {
            _loadData();
          }
        },
        backgroundColor: AppColors.primary(context),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildTransactionCard({
    required bool isIngreso,
    required int cantidad,
    required String fecha,
    required String categoryName,
    String? descripcion,
    required VoidCallback onDelete,
  }) {
    final color = isIngreso
        ? AppColors.income(context)
        : AppColors.expense(context);

    return Dismissible(
      key: UniqueKey(),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: AppColors.alert(context),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: Container(

        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardBackground(context),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        categoryName,
                        style: TextStyle(
                          color: AppColors.textPrimary(context),
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('dd/MM/yyyy').format(DateTime.parse(fecha)),
                        style: TextStyle(
                          color: AppColors.textSecondary(context),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                MoneyDisplay(
                  amount: cantidad,
                  color: color,
                  sizeFont: 16,
                  iconAtLeft: null,
                ),
              ],
            ),
            if (descripcion != null && descripcion.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                descripcion,
                style: TextStyle(
                  color: AppColors.textSecondary(context),
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }

}
