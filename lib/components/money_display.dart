import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../core/utils/money_format.dart';

class MoneyDisplay extends StatelessWidget {
	final int amount;
	final Color color;
	final double sizeFont;
	final String? iconAtLeft; // asset path or null

	const MoneyDisplay({
		super.key,
		required this.amount,
		required this.color,
		required this.sizeFont,
		this.iconAtLeft,
	});

	String _formatAmount(int value) {
		// simple thousands separator
		final s = MoneyFormatter.formatFromInt(value);
		return s; // keep simple for now
	}

	@override
	Widget build(BuildContext context) {
		final text = Text('\$${_formatAmount(amount)}',
			style: TextStyle(
				color: color,
				fontSize: sizeFont,
				fontWeight: FontWeight.w600,
			),
		);

		if (iconAtLeft == null) return text;

		final iconSize = sizeFont; // same length as text

		Widget icon;
		if (iconAtLeft!.endsWith('.svg')) {
			icon = SvgPicture.asset(
				iconAtLeft!,
				width: iconSize,
				height: iconSize,
				fit: BoxFit.contain,
			);
		} else {
			icon = Image.asset(
				iconAtLeft!,
				width: iconSize,
				height: iconSize,
				fit: BoxFit.contain,
			);
		}

		return Row(
			mainAxisSize: MainAxisSize.min,
			crossAxisAlignment: CrossAxisAlignment.center,
			children: [
				icon,
				SizedBox(width: 8),
				text,
			],
		);
	}
}

