import 'package:flutter/material.dart';
import '../core/colors.dart';
import '../core/utils/money_format.dart'; // Verifica que el nombre del archivo sea correcto

class BudgetCardSmall extends StatelessWidget {
  final String? name;
  final int? amount;
  final List<Color>? categoryColors;
  
  // NUEVOS PARÁMETROS REALES
  final int? restante;
  final int? gastoTotal;
  final bool? esExcedido;

  const BudgetCardSmall({
    super.key,
    this.name,
    this.amount,
    this.categoryColors,
    this.restante,
    this.gastoTotal,
    this.esExcedido,
  });

  @override
  Widget build(BuildContext context) {
    if (name == null || amount == null) return const SizedBox.shrink();

    // Usamos los datos reales pasados, con fallbacks de seguridad por si acaso
    final realRestante = restante ?? amount!;
    final realExcedido = esExcedido ?? false;

    // Calculamos el ratio real para definir el color
    final ratio = amount! > 0 ? realRestante / amount! : 0.0;

    Color statusColor;
    String label;

    // Lógica de estados con la información de la base de datos
    if (realExcedido) {
      statusColor = Colors.red;
      // Usamos .abs() para que no muestre "Excedido: -500", sino "Excedido: 500"
      label = 'Excedido: ${MoneyFormatter.formatFromInt(realRestante.abs())}';
    } else if (ratio > 0.5) {
      statusColor = Colors.green;
      label = 'Restante: ${MoneyFormatter.formatFromInt(realRestante)}';
    } else if (ratio > 0.2) {
      statusColor = const Color(0xFFF0C300); // primary yellow
      label = 'Restante: ${MoneyFormatter.formatFromInt(realRestante)}';
    } else {
      statusColor = Colors.red;
      label = 'Alerta: ${MoneyFormatter.formatFromInt(realRestante)}';
    }

    final cats = categoryColors ??
        [AppColors.primary(context), Colors.grey, Colors.grey[400]!];

    // Detectamos modo oscuro para que el borde se adapte (Opcional, pero recomendado)
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDarkMode ? Colors.grey[800]! : Colors.grey[300]!,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$name - ${MoneyFormatter.formatFromInt(amount!)}',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textPrimary(context),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: List.generate(
                    cats.length > 3 ? 3 : cats.length,
                    (i) => Container(
                      margin: const EdgeInsets.only(right: 6),
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        color: cats[i],
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}