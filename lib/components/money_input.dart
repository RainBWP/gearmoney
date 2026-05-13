import 'package:flutter/material.dart';
import '../core/utils/money_format.dart';
import '../core/colors.dart';

class MoneyInput extends StatefulWidget {
  final TextEditingController? controller;
  final int? initialCents;
  final ValueChanged<int>? onChangedCents;
  final double fontSize;

  const MoneyInput({
    super.key,
    this.controller,
    this.initialCents,
    this.onChangedCents,
    this.fontSize = 28,
  });

  @override
  State<MoneyInput> createState() => _MoneyInputState();
}

class _MoneyInputState extends State<MoneyInput> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = widget.controller ?? TextEditingController();
    if (widget.initialCents != null && (_ctrl.text).isEmpty) {
      _ctrl.text = MoneyFormatter.formatFromInt(widget.initialCents!);
    }
    _ctrl.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    final text = _ctrl.text.trim();
    try {
      final cents = MoneyFormatter.parseToInt(text);
      widget.onChangedCents?.call(cents);
    } catch (_) {
      // ignore parse errors while typing
    }
  }

  @override
  void dispose() {
    _ctrl.removeListener(_onTextChanged);
    if (widget.controller == null) _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
          decoration: BoxDecoration(
            color: AppColors.cardBackground(context).withValues(alpha: 0),
          ),
          child: Text(
            '\$',
            style: TextStyle(
              color: AppColors.textPrimary(context),
              fontSize: widget.fontSize,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: TextFormField(
            controller: _ctrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: TextStyle(
              color: AppColors.textPrimary(context),
              fontSize: widget.fontSize,
              fontWeight: FontWeight.w800,
            ),
            decoration: const InputDecoration(
              border: InputBorder.none,
              hintText: '0.00',
              isDense: true,
              contentPadding: EdgeInsets.zero,
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) return 'Ingresa la cantidad';
              try {
                final cents = MoneyFormatter.parseToInt(value.trim());
                if (cents <= 0) return 'La cantidad debe ser mayor a 0';
              } catch (e) {
                return 'Formato inválido';
              }
              return null;
            },
          ),
        ),
      ],
    );
  }
}
