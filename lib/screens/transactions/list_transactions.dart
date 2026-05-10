import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/colors.dart';
import '../../core/database/db_helper.dart';
import '../../components/money_display.dart';
import 'create_transactions.dart';


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

  String _getCategoryName(int categoryId) {
    try {
      return _categories.firstWhere((c) => c['id'] == categoryId)['nombre']
          as String;
    } catch (e) {
      return 'Sin categoría';
    }
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
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _transactions.length,
              itemBuilder: (context, index) {
                final transaction = _transactions[index];
                final isIngreso = transaction['is_ingreso'] == 1;
                final cantidad = (transaction['cantidad'] is int)
                    ? transaction['cantidad'] as int
                    : int.tryParse('${transaction['cantidad']}') ?? 0;
                final fecha = transaction['fecha'] as String;
                final categoryName = _getCategoryName(
                  (transaction['categoria_id'] is int)
                      ? transaction['categoria_id'] as int
                      : int.tryParse('${transaction['categoria_id']}') ?? 0,
                );

                return _buildTransactionCard(
                  isIngreso: isIngreso,
                  cantidad: cantidad,
                  fecha: fecha,
                  categoryName: categoryName,
                  descripcion: transaction['descripcion'] as String?,
                  onDelete: () => _deleteTransaction(transaction['id'] as int),
                );
              },
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
        ? AppColors.success(context)
        : AppColors.alert(context);

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
