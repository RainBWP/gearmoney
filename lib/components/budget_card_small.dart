import 'package:flutter/material.dart';
import '../core/colors.dart';

class BudgetCardSmall extends StatelessWidget {
  final String? name;
  final int? amount;
  final List<Color>? categoryColors; // placeholders

  const BudgetCardSmall({
    super.key,
    this.name,
    this.amount,
    this.categoryColors,
  });

  @override
  Widget build(BuildContext context) {
    if (name == null || amount == null) return SizedBox.shrink();

    // placeholder calculation: assume spent = 40% of amount
    final spent = (amount! * 0.4).round();
    final remaining = amount! - spent;
    final ratio = amount! > 0 ? remaining / amount! : 0.0;

    Color statusColor;
    String label;
    if (ratio > 0.5) {
      statusColor = Colors.green;
      label = 'Restante: \$$remaining';
    } else if (ratio > 0.2) {
      statusColor = Color(0xFFF0C300); // primary yellow
      label = 'Restante: \$$remaining';
    } else {
      statusColor = Colors.red;
      label = 'Alerta: \$$remaining';
    }

    final cats =
        categoryColors ??
        [AppColors.primary(context), Colors.grey, Colors.grey[400]!];

    return Container(
      margin: EdgeInsets.symmetric(vertical: 8),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$name - \$$amount',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textPrimary(context),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 8),
                Row(
                  children: List.generate(
                    cats.length > 3 ? 3 : cats.length,
                    (i) => Container(
                      margin: EdgeInsets.only(right: 6),
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
