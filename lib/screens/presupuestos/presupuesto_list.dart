import 'package:flutter/material.dart';
import '../../core/colors.dart';
import '../../core/database/db_helper.dart';
import '../../core/utils/money_format.dart';
import 'create_presupuesto.dart';

class PresupuestoListScreen extends StatefulWidget {
  final Map<String, dynamic> user;

  const PresupuestoListScreen({super.key, required this.user});

  @override
  State<PresupuestoListScreen> createState() => _PresupuestoListScreenState();
}

class _PresupuestoListScreenState extends State<PresupuestoListScreen> {
  List<Map<String, dynamic>> _presupuestos = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPresupuestos();
  }

  Future<void> _loadPresupuestos() async {
    try {
      final int userId = (widget.user['id'] is int)
          ? widget.user['id'] as int
          : int.tryParse('${widget.user['id']}') ?? 1;

      final dbh = DatabaseHelper.instance;
      final db = await dbh.database;

      // Obtener presupuestos
      final pres = await db.query(
        'Presupuestos',
        where: 'usuario_id = ?',
        whereArgs: [userId],
      );

      // Para cada presupuesto, obtener sus categorías
      final enrichedPres = <Map<String, dynamic>>[];
      for (final p in pres) {
        final presId = p['id'] as int;
        final catRels = await db.query(
          'Presupuestos_Categorias',
          where: 'id_presupuesto = ?',
          whereArgs: [presId],
        );

        final categoryIds =
            catRels.map((r) => r['id_categoria'] as int).toList();
        final categories = await dbh.readCategorias(userId);
        final catDetails = categories
            .where((c) => categoryIds.contains(c['id']))
            .toList();

        // Calcular gasto del presupuesto
        final allMov = await dbh.readMovimientos();
        final userMov = allMov
            .where((m) =>
                m['usuario_id'] == userId &&
                categoryIds.contains(m['categoria_id']))
            .toList();

        int totalGasto = 0;
        for (final m in userMov) {
          if (m['is_ingreso'] == 0) {
            final cant = (m['cantidad'] is int)
                ? m['cantidad'] as int
                : int.tryParse('${m['cantidad']}') ?? 0;
            totalGasto += cant;
          }
        }

        final presupuesto = p['monto'] as int;
        final restante = presupuesto - totalGasto;
        final esExcedido = restante < 0;

        enrichedPres.add({
          ...p,
          'categorias': catDetails,
          'gasto_total': totalGasto,
          'restante': restante,
          'es_excedido': esExcedido,
        });
      }

      if (mounted) {
        setState(() {
          _presupuestos = enrichedPres;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar presupuestos: $e')),
        );
      }
    }
  }

  Future<void> _deletePresupuesto(int presupuestoId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Eliminar presupuesto'),
          content: const Text(
            '¿Estás seguro de que deseas borrar este presupuesto?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      try {
        final db = await DatabaseHelper.instance.database;
        await db.delete(
          'Presupuestos_Categorias',
          where: 'id_presupuesto = ?',
          whereArgs: [presupuestoId],
        );
        await db.delete(
          'Presupuestos',
          where: 'id = ?',
          whereArgs: [presupuestoId],
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Presupuesto eliminado')),
          );
          _loadPresupuestos();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al eliminar: $e')),
          );
        }
      }
    }
  }

  void _editPresupuesto(Map<String, dynamic> presupuesto) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreatePresupuestoScreen(user: widget.user),
      ),
    ).then((_) => _loadPresupuestos());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background(context),
      appBar: AppBar(
        backgroundColor: AppColors.background(context),
        elevation: 0,
        title: Text(
          'Mis Presupuestos',
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
          : _presupuestos.isEmpty
              ? Center(
                  child: Text(
                    'No hay presupuestos',
                    style: TextStyle(
                      color: AppColors.textSecondary(context),
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _presupuestos.length,
                  itemBuilder: (context, index) {
                    final p = _presupuestos[index];
                    return _buildPresupuestoCard(p);
                  },
                ),
    );
  }

  Widget _buildPresupuestoCard(Map<String, dynamic> presupuesto) {
    final nombre = presupuesto['nombre'] as String? ?? '';
    final monto = presupuesto['monto'] as int? ?? 0;
    final categorias = presupuesto['categorias'] as List? ?? [];
    final restante = presupuesto['restante'] as int? ?? 0;
    final esExcedido = presupuesto['es_excedido'] as bool? ?? false;
    final presupuestoId = presupuesto['id'] as int;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    final backgroundColor = esExcedido
        ? (isDarkMode ? Colors.red.withValues(alpha: 0.2) : Colors.red.shade50)
        : (isDarkMode ? Colors.green.withValues(alpha: 0.2) : Colors.green.shade50);
    final borderColor = esExcedido
        ? (isDarkMode ? Colors.red.shade700 : Colors.red.shade200)
        : (isDarkMode ? Colors.green.shade700 : Colors.green.shade200);
    final textColor = esExcedido
        ? (isDarkMode ? Colors.red.shade200 : Colors.red.shade700)
        : (isDarkMode ? Colors.green.shade300 : Colors.green.shade700);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Nombre y monto asignado
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  nombre,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary(context),
                  ),
                ),
              ),
              Text(
                MoneyFormatter.formatFromInt(monto),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Categorías y restante/excedido en una fila
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Emojis de categorías
              Expanded(
                child: Wrap(
                  spacing: 8,
                  children: categorias.map<Widget>((cat) {
                    final colorHex = cat['color'] as String? ?? '#FF5722';
                    final color = Color(
                      int.parse(colorHex.replaceFirst('#', '0xff')),
                    );
                    final emoji = cat['icono'] as String? ?? '📁';

                    return Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: color.withValues(alpha: 0.5),
                        ),
                      ),
                      child: Center(
                        child: Text(emoji, style: const TextStyle(fontSize: 18)),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(width: 12),
              // Restante/Excedido texto
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        esExcedido ? 'Excedido: ' : 'Restante: ',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                      ),
                      Text(
                        MoneyFormatter.formatFromInt(restante.abs()),
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: textColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(width: 8),
              // Menú de opciones
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'editar') {
                    _editPresupuesto(presupuesto);
                  } else if (value == 'eliminar') {
                    _deletePresupuesto(presupuestoId);
                  }
                },
                itemBuilder: (BuildContext context) => [
                  const PopupMenuItem<String>(
                    value: 'editar',
                    child: Text('Editar'),
                  ),
                  const PopupMenuItem<String>(
                    value: 'eliminar',
                    child: Text('Eliminar'),
                  ),
                ],
                child: Icon(
                  Icons.more_vert,
                  color: textColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
