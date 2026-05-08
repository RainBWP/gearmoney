import 'package:flutter/material.dart';
import 'money_display.dart';
import '../core/colors.dart';

class TransactionCardSmall extends StatelessWidget {
	final int? amount;
	final bool? isIncome;
	final String? name;
	final DateTime? date;
	final Color? categoryColor; // placeholder circle color

	const TransactionCardSmall({
		super.key,
		this.amount,
		this.isIncome,
		this.name,
		this.date,
		this.categoryColor,
	});

	@override
	Widget build(BuildContext context) {
		if (amount == null || name == null || date == null) {
			// placeholder grey box with rounded corners
			return Container(
				height: 64,
				decoration: BoxDecoration(
					color: Colors.grey[300],
					borderRadius: BorderRadius.circular(8),
				),
				margin: EdgeInsets.symmetric(vertical: 6),
				padding: EdgeInsets.all(12),
			);
		}

		final moneyColor = isIncome == true ? Colors.green : Colors.red;

		return Container(
			padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
			child: Row(
				children: [
					// placeholder circle for category
					Container(
						width: 40,
						height: 40,
						decoration: BoxDecoration(
							color: categoryColor ?? AppColors.primary(context),
							shape: BoxShape.circle,
						),
					),
					SizedBox(width: 12),
					Expanded(
						child: Column(
							crossAxisAlignment: CrossAxisAlignment.start,
							children: [
								Text(
									name!,
									style: TextStyle(fontSize: 14, color: AppColors.textPrimary(context)),

									maxLines: 1,
									overflow: TextOverflow.ellipsis,
								),
								SizedBox(height: 4),
								Text(
									_formatDate(date!),
									style: TextStyle(fontSize: 12, color: AppColors.textSecondary(context)),
								),
							],
						),
					),
					MoneyDisplay(amount: amount!, color: moneyColor, sizeFont: 16),
				],
			),
		);
	}

	String _formatDate(DateTime d) {
		return "${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";
	}
}

