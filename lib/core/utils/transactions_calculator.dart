import 'package:intl/intl.dart';

import 'money_format.dart';
import '../database/db_helper.dart';

class TransactionsCalculator {
	static String formatMoney(int amount) {
		return MoneyFormatter.formatFromInt(amount);
	}

	static Future<int> getTotalIngresosUltimoMes({
		required int userId,
		DateTime? referenceDate,
		int? dayLimit,
		int? categoryId,
	}) {
		return getTotalMovimientosUltimoMes(
			userId: userId,
			isIngreso: true,
			referenceDate: referenceDate,
			dayLimit: dayLimit,
			categoryId: categoryId,
		);
	}

	static Future<int> getTotalGastosUltimoMes({
		required int userId,
		DateTime? referenceDate,
		int? dayLimit,
		int? categoryId,
	}) {
		return getTotalMovimientosUltimoMes(
			userId: userId,
			isIngreso: false,
			referenceDate: referenceDate,
			dayLimit: dayLimit,
			categoryId: categoryId,
		);
	}

	static Future<int> getTotalMovimientosUltimoMes({
		required int userId,
		required bool isIngreso,
		DateTime? referenceDate,
		int? dayLimit,
		int? categoryId,
	}) async {
		final now = _normalizeDate(referenceDate ?? DateTime.now());
		final effectiveDay = dayLimit ?? now.day;
		final startDate = _buildRelativeDate(
			year: now.year,
			month: now.month - 1,
			day: effectiveDay,
		);
		final endDate = _buildRelativeDate(
			year: now.year,
			month: now.month,
			day: effectiveDay,
		);

		return _sumMovimientos(
			userId: userId,
			isIngreso: isIngreso,
			startDate: startDate,
			endDate: endDate,
			categoryId: categoryId,
		);
	}

	static Future<int> getTotalIngresosEntreFechas({
		required int userId,
		required DateTime startDate,
		required DateTime endDate,
		int? categoryId,
	}) {
		return _sumMovimientos(
			userId: userId,
			isIngreso: true,
			startDate: startDate,
			endDate: endDate,
			categoryId: categoryId,
		);
	}

	static Future<int> getTotalGastosEntreFechas({
		required int userId,
		required DateTime startDate,
		required DateTime endDate,
		int? categoryId,
	}) {
		return _sumMovimientos(
			userId: userId,
			isIngreso: false,
			startDate: startDate,
			endDate: endDate,
			categoryId: categoryId,
		);
	}

	static Future<List<Map<String, int>>> getResumenMensualPorAnio({
		required int userId,
		required int year,
		int? categoryId,
	}) async {
		final db = await DatabaseHelper.instance.database;
		final startDate = DateTime(year, 1, 1);
		final endDate = DateTime(year, 12, 31);

		final where = <String>[
			'usuario_id = ?',
			'fecha >= ?',
			'fecha <= ?',
		];
		final whereArgs = <Object?>[
			userId,
			_formatDate(startDate),
			_formatDate(endDate),
		];

		if (categoryId != null) {
			where.add('categoria_id = ?');
			whereArgs.add(categoryId);
		}

		final rows = await db.query(
			'Movimientos',
			columns: const ['is_ingreso', 'cantidad', 'fecha'],
			where: where.join(' AND '),
			whereArgs: whereArgs,
		);

		final months = List.generate(
			12,
			(index) => <String, int>{
				'month': index + 1,
				'ingresos': 0,
				'gastos': 0,
				'saldo': 0,
			},
		);

		for (final row in rows) {
			final dateText = row['fecha']?.toString() ?? '';
			final parsedDate = DateTime.tryParse(dateText);
			if (parsedDate == null || parsedDate.year != year) {
				continue;
			}

			final monthIndex = parsedDate.month - 1;
			final amount = _readInt(row['cantidad']);
			final isIngreso = _readInt(row['is_ingreso']) == 1;

			if (isIngreso) {
				months[monthIndex]['ingresos'] =
						months[monthIndex]['ingresos']! + amount;
			} else {
				months[monthIndex]['gastos'] = months[monthIndex]['gastos']! + amount;
			}
			months[monthIndex]['saldo'] =
					months[monthIndex]['ingresos']! - months[monthIndex]['gastos']!;
		}

		return months;
	}

	static Future<int> getGastoPresupuesto({
		required int userId,
		required String nombrePresupuesto,
		DateTime? referenceDate,
		int? dayLimit,
	}) async {
		final budget = await _readBudgetByName(
			userId: userId,
			nombrePresupuesto: nombrePresupuesto,
		);

		if (budget == null) {
			throw Exception('No se encontró el presupuesto "$nombrePresupuesto"');
		}

		final categoryIds = await _readBudgetCategoryIds(budget['id'] as int);
		if (categoryIds.isEmpty) {
			return 0;
		}

		final now = _normalizeDate(referenceDate ?? DateTime.now());
		final effectiveDay = dayLimit ?? now.day;
		final startDate = _buildRelativeDate(
			year: now.year,
			month: now.month - 1,
			day: effectiveDay,
		);
		final endDate = _buildRelativeDate(
			year: now.year,
			month: now.month,
			day: effectiveDay,
		);

		return _sumMovimientosPorCategorias(
			userId: userId,
			startDate: startDate,
			endDate: endDate,
			categoryIds: categoryIds,
		);
	}

	static Future<int> getDiferenciaPresupuesto({
		required int userId,
		required String nombrePresupuesto,
		DateTime? referenceDate,
		int? dayLimit,
	}) async {
		final budget = await _readBudgetByName(
			userId: userId,
			nombrePresupuesto: nombrePresupuesto,
		);

		if (budget == null) {
			throw Exception('No se encontró el presupuesto "$nombrePresupuesto"');
		}

		final monto = _readInt(budget['monto']);
		final gastado = await getGastoPresupuesto(
			userId: userId,
			nombrePresupuesto: nombrePresupuesto,
			referenceDate: referenceDate,
			dayLimit: dayLimit,
		);

		return monto - gastado;
	}

	static Future<int> _sumMovimientos({
		required int userId,
		required bool isIngreso,
		required DateTime startDate,
		required DateTime endDate,
		int? categoryId,
	}) async {
		final db = await DatabaseHelper.instance.database;
		final where = <String>[
			'usuario_id = ?',
			'is_ingreso = ?',
			'fecha >= ?',
			'fecha <= ?',
		];
		final whereArgs = <Object?>[
			userId,
			isIngreso ? 1 : 0,
			_formatDate(startDate),
			_formatDate(endDate),
		];

		if (categoryId != null) {
			where.add('categoria_id = ?');
			whereArgs.add(categoryId);
		}

		final rows = await db.query(
			'Movimientos',
			columns: const ['cantidad'],
			where: where.join(' AND '),
			whereArgs: whereArgs,
		);

		var total = 0;
		for (final row in rows) {
			total += _readInt(row['cantidad']);
		}
		return total;
	}

	static Future<int> _sumMovimientosPorCategorias({
		required int userId,
		required DateTime startDate,
		required DateTime endDate,
		required List<int> categoryIds,
	}) async {
		final db = await DatabaseHelper.instance.database;
		final placeholders = List.filled(categoryIds.length, '?').join(', ');
		final rows = await db.query(
			'Movimientos',
			columns: const ['cantidad'],
			where:
					'usuario_id = ? AND is_ingreso = 0 AND fecha >= ? AND fecha <= ? AND categoria_id IN ($placeholders)',
			whereArgs: <Object?>[
				userId,
				_formatDate(startDate),
				_formatDate(endDate),
				...categoryIds,
			],
		);

		var total = 0;
		for (final row in rows) {
			total += _readInt(row['cantidad']);
		}
		return total;
	}

	static Future<Map<String, dynamic>?> _readBudgetByName({
		required int userId,
		required String nombrePresupuesto,
	}) async {
		final db = await DatabaseHelper.instance.database;
		final result = await db.query(
			'Presupuestos',
			where: 'usuario_id = ? AND nombre = ?',
			whereArgs: [userId, nombrePresupuesto.trim()],
			limit: 1,
		);

		if (result.isEmpty) {
			return null;
		}

		return result.first;
	}

	static Future<List<int>> _readBudgetCategoryIds(int budgetId) async {
		final db = await DatabaseHelper.instance.database;
		final rows = await db.query(
			'Presupuestos_Categorias',
			columns: const ['id_categoria'],
			where: 'id_presupuesto = ?',
			whereArgs: [budgetId],
		);

		return rows
				.map((row) => _readInt(row['id_categoria']))
				.where((value) => value > 0)
				.toList();
	}

	static DateTime _normalizeDate(DateTime date) {
		return DateTime(date.year, date.month, date.day);
	}

	static DateTime _buildRelativeDate({
		required int year,
		required int month,
		required int day,
	}) {
		final normalizedMonthDate = DateTime(year, month, 1);
		final lastDayOfMonth = DateTime(
			normalizedMonthDate.year,
			normalizedMonthDate.month + 1,
			0,
		).day;
		final validDay = day.clamp(1, lastDayOfMonth);
		return DateTime(normalizedMonthDate.year, normalizedMonthDate.month, validDay);
	}

	static String _formatDate(DateTime date) {
		return DateFormat('yyyy-MM-dd').format(_normalizeDate(date));
	}

	static int _readInt(Object? value) {
		if (value is int) {
			return value;
		}
		return int.tryParse(value?.toString() ?? '') ?? 0;
	}
}