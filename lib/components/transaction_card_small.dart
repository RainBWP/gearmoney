import 'package:flutter/material.dart';
import 'money_display.dart';
import '../core/colors.dart';

class TransactionCardSmall extends StatelessWidget {
	final int? amount;
	final bool? isIncome;
	final String? name;
	final DateTime? date;
	final Color? categoryColor;
	final String? categoryIcon;

  final String svgUp = 'assets/svgs/up-trend-svgrepo-com.svg';
  final String svgDown = 'assets/svgs/down-trend-round-svgrepo-com.svg';

	const TransactionCardSmall({
		super.key,
		this.amount,
		this.isIncome,
		this.name,
		this.date,
		this.categoryColor,
		this.categoryIcon,
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

		final moneyColor = isIncome == true 
			? AppColors.income(context) 
			: AppColors.expense(context);
		final nameColor = isIncome == true 
			? AppColors.income(context) 
			: AppColors.expense(context);

		return Container(
			padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
			child: Row(
				children: [
					// Category icon with background circle
					Container(
						width: 40,
						height: 40,
						decoration: BoxDecoration(
							color: categoryColor ?? AppColors.primary(context),
							shape: BoxShape.circle,
						),
						child: Center(
							child: Text(
								categoryIcon ?? '📁',
								style: const TextStyle(fontSize: 20),
							),
						),
					),
					SizedBox(width: 12),
					Expanded(
						child: Column(
							crossAxisAlignment: CrossAxisAlignment.start,
							children: [
								Text(
									name!,
									style: TextStyle(
										fontSize: 14, 
										color: nameColor,
										fontWeight: FontWeight.w600,
									),
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
					MoneyDisplay(amount: amount!, 
            color: moneyColor, 
            sizeFont: 16, 
            iconAtLeft: isIncome == true ? svgUp : svgDown),
				],
			),
		);
	}

	String _formatDate(DateTime d) {
		return "${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";
	}
}

