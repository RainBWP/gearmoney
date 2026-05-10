import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/colors.dart';
import '../../core/database/db_helper.dart';
import '../categories/create_category.dart';
import '../../core/utils/money_format.dart';
import '../../components/money_input.dart';

enum PaymentMethod { cash, card, transfer }

class CreateTransactionScreen extends StatefulWidget {
  final Map<String, dynamic> user;
  final bool? initialIsIngreso;
  final Map<String, dynamic>? transactionToEdit;

  const CreateTransactionScreen({
    super.key,
    required this.user,
    this.initialIsIngreso,
    this.transactionToEdit,
  });

  @override
  State<CreateTransactionScreen> createState() =>
      _CreateTransactionScreenState();
}

class _CreateTransactionScreenState extends State<CreateTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _nameController = TextEditingController();

  late bool _isIngreso;
  int? _selectedCategoryId;
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  PaymentMethod _selectedPaymentMethod = PaymentMethod.cash;
  List<Map<String, dynamic>> _categories = [];
  bool _isLoading = true;
  bool _isSaving = false;
  int? _amountCents;
  bool _isEditing = false;
  int? _editingTransactionId;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.transactionToEdit != null;
    if (_isEditing) {
      _editingTransactionId = widget.transactionToEdit!['id'] as int;
      _isIngreso = widget.transactionToEdit!['is_ingreso'] == 1;
      _quantityController.text = MoneyFormatter.formatFromInt((widget.transactionToEdit!['cantidad'] as int));
      _amountCents = widget.transactionToEdit!['cantidad'] as int;
      _nameController.text = widget.transactionToEdit!['nombre'] as String? ?? '';
      _descriptionController.text = widget.transactionToEdit!['descripcion'] as String? ?? '';
      _selectedDate = DateTime.parse(widget.transactionToEdit!['fecha'] as String);
      _selectedCategoryId = widget.transactionToEdit!['categoria_id'] as int?;
      _selectedPaymentMethod = PaymentMethod.values[widget.transactionToEdit!['metodo_pago'] as int? ?? 0];
      final horaStr = widget.transactionToEdit!['hora'] as String?;
      if (horaStr != null && horaStr.isNotEmpty) {
        try {
          // Handle both 24h format (HH:mm) and localized format (h:mm AM/PM)
          final cleanHora = horaStr.replaceAll('AM', '').replaceAll('PM', '').trim();
          final parts = cleanHora.split(':');
          if (parts.length >= 2) {
            int hour = int.parse(parts[0].trim());
            int minute = int.parse(parts[1].trim());
            // If original had PM and hour < 12, add 12 (unless it's 12 PM)
            if (horaStr.contains('PM') && hour < 12) hour += 12;
            // If original had AM and hour == 12, set to 0 (12 AM = 00:00)
            if (horaStr.contains('AM') && hour == 12) hour = 0;
            _selectedTime = TimeOfDay(hour: hour, minute: minute);
          }
        } catch (_) {}
      }
    } else {
      _isIngreso = widget.initialIsIngreso ?? true;
    }
    _loadCategories();
  }

  final Map<PaymentMethod, String> _paymentMethodLabels = {
    PaymentMethod.cash: 'Efectivo',
    PaymentMethod.card: 'Tarjeta',
    PaymentMethod.transfer: 'Transferencia',
  };

  Future<void> _loadCategories() async {
    try {
      final int userId = (widget.user['id'] is int)
          ? widget.user['id'] as int
          : int.tryParse('${widget.user['id']}') ?? 1;

      final categories = await DatabaseHelper.instance.readCategorias(userId);

      if (mounted) {
        setState(() {
          _categories = categories;
          _isLoading = false;
          if (categories.isNotEmpty) {
            _selectedCategoryId = categories[0]['id'] as int;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar categorías: $e')),
        );
      }
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(primary: AppColors.primary(context)),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  int _parseAmountToCents(String rawValue) {
    final normalized = rawValue.trim().replaceAll(',', '.');
    final amount = double.tryParse(normalized);

    if (amount == null || amount <= 0) {
      throw Exception('La cantidad debe ser mayor a 0');
    }

    return (amount * 100).round();
  }

  Future<void> _saveTransaction() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor selecciona una categoría')),
      );
      return;
    }

    if (_amountCents == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ingresa la cantidad')));
      return;
    }

    setState(() => _isSaving = true);

    try {
      final int userId = (widget.user['id'] is int)
          ? widget.user['id'] as int
          : int.tryParse('${widget.user['id']}') ?? 1;

      final quantity = _amountCents!;
      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
      final timeStr = _selectedTime.format(context);

      if (_isEditing) {
        // Update existing transaction
        await DatabaseHelper.instance.updateMovimiento(
          _editingTransactionId!,
          {
            'is_ingreso': _isIngreso ? 1 : 0,
            'cantidad': quantity,
            'nombre': _nameController.text.isNotEmpty ? _nameController.text : (_isIngreso ? 'Ingreso' : 'Gasto'),
            'descripcion': _descriptionController.text.isNotEmpty ? _descriptionController.text : null,
            'fecha': dateStr,
            'tiene_hora': 1,
            'hora': '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}',
            'categoria_id': _selectedCategoryId!,
            'metodo_pago': _selectedPaymentMethod.index,
          },
        );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isIngreso ? 'Ingreso actualizado' : 'Gasto actualizado'),
            backgroundColor: _isIngreso
                ? AppColors.success(context)
                : AppColors.alert(context),
          ),
        );
      } else {
        // Create new transaction
        await DatabaseHelper.instance.createMovimiento(
          isIngreso: _isIngreso,
          cantidad: quantity,
          nombre: _nameController.text.isNotEmpty ? _nameController.text : (_isIngreso ? 'Ingreso' : 'Gasto'),
          descripcion: _descriptionController.text.isNotEmpty ? _descriptionController.text : null,
          fecha: dateStr,
          tieneHora: true,
          hora: '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}',
          categoriaId: _selectedCategoryId!,
          usuarioId: userId,
          metodoPago: _selectedPaymentMethod.index,
        );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isIngreso ? 'Ingreso registrado' : 'Gasto registrado'),
            backgroundColor: _isIngreso
                ? AppColors.success(context)
                : AppColors.alert(context),
          ),
        );
      }

      Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al guardar: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _descriptionController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background(context),
      appBar: AppBar(
        backgroundColor: AppColors.background(context),
        elevation: 0,
        title: Text(
          _isEditing
              ? (_isIngreso ? 'Editar Ingreso' : 'Editar Gasto')
              : (_isIngreso ? 'Nuevo Ingreso' : 'Nuevo Gasto'),
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
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    

                    // Money input (clean text only)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: MoneyInput(
                        controller: _quantityController,
                        onChangedCents: (c) => _amountCents = c,
                        fontSize: 28,
                      ),
                    ),

                    // Nombre (underlined)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: TextFormField(
                        controller: _nameController,
                        style: TextStyle(color: AppColors.textPrimary(context), fontWeight: FontWeight.w800, fontSize: 20),
                        decoration: InputDecoration(
                          hintText: 'Nombre del movimiento',
                          hintStyle: TextStyle(color: AppColors.textSecondary(context)),
                          border: const UnderlineInputBorder(),
                        ),
                        validator: (v) => null,
                      ),
                    ),

                    // Descripción (multiline)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: TextFormField(
                        controller: _descriptionController,
                        maxLines: 3,
                        style: TextStyle(color: AppColors.textPrimary(context)),
                        decoration: InputDecoration(
                          hintText: 'Detalles (opcional)',
                          hintStyle: TextStyle(color: AppColors.textSecondary(context)),
                          border: InputBorder.none,
                        ),
                      ),
                    ),

                    
                    
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildTypeSelector(),
                    ),

                    // Fecha pill
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: GestureDetector(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _selectedDate,
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2100),
                            builder: (context, child) => Theme(data: Theme.of(context).copyWith(colorScheme: ColorScheme.light(primary: AppColors.primary(context))), child: child!),
                          );
                          if (picked != null) setState(() => _selectedDate = picked);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: ShapeDecoration(
                            color: AppColors.cardBackground(context),
                            shape: const StadiumBorder(),
                          ),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            Icon(Icons.calendar_today, size: 16, color: AppColors.textPrimary(context)),
                            const SizedBox(width: 8),
                            Text(DateFormat('dd/MM/yyyy').format(_selectedDate), style: TextStyle(color: AppColors.textPrimary(context))),
                          ]),
                        ),
                      ),
                    ),

                    // Hora pill
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: GestureDetector(
                        onTap: () async {
                          final picked = await showTimePicker(context: context, initialTime: _selectedTime);
                          if (picked != null) setState(() => _selectedTime = picked);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: ShapeDecoration(
                            color: AppColors.cardBackground(context),
                            shape: const StadiumBorder(),
                          ),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            Icon(Icons.access_time, size: 16, color: AppColors.textPrimary(context)),
                            const SizedBox(width: 8),
                            Text(_selectedTime.format(context), style: TextStyle(color: AppColors.textPrimary(context))),
                          ]),
                        ),
                      ),
                    ),

                    // Categoria selector
                    Padding(padding: const EdgeInsets.only(bottom: 12), child: _buildCategorySelector()),

                    // Metodo de pago chips
                    Padding(padding: const EdgeInsets.only(bottom: 24), child: _buildPaymentMethodSelector()),

                    // Botón registrar
                    _buildSaveButton(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tipo de movimiento',
          style: TextStyle(
            color: AppColors.textPrimary(context),
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildTypeButton(
                label: 'Ingreso',
                isSelected: _isIngreso,
                onPressed: () => setState(() => _isIngreso = true),
                color: AppColors.success(context),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildTypeButton(
                label: 'Gasto',
                isSelected: !_isIngreso,
                onPressed: () => setState(() => _isIngreso = false),
                color: AppColors.alert(context),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTypeButton({
    required String label,
    required bool isSelected,
    required VoidCallback onPressed,
    required Color color,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? color : AppColors.cardBackground(context),
          borderRadius: BorderRadius.circular(100),
          border: Border.all(color: color, width: isSelected ? 2 : 1),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected
                  ? Colors.white
                  : AppColors.textSecondary(context),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuantityField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Cantidad',
          style: TextStyle(
            color: AppColors.textPrimary(context),
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _quantityController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: TextStyle(color: AppColors.textPrimary(context)),
          decoration: InputDecoration(
            hintText: '0.00',
            hintStyle: TextStyle(color: AppColors.textSecondary(context)),
            filled: true,
            fillColor: AppColors.cardBackground(context),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Ingresa la cantidad';
            }
            final quantity = double.tryParse(value.replaceAll(',', '.'));
            if (quantity == null || quantity <= 0) {
              return 'La cantidad debe ser mayor a 0';
            }
            return null;
          },
        ),
      ],
    );
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

  Widget _buildCategorySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Categoría',
          style: TextStyle(
            color: AppColors.textPrimary(context),
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        _categories.isEmpty
            ? Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.cardBackground(context),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.alert(context).withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'No hay categorías disponibles',
                      style: TextStyle(
                        color: AppColors.textPrimary(context),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Crea al menos una categoría antes de registrar movimientos',
                      style: TextStyle(
                        color: AppColors.textSecondary(context),
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  CreateCategoryScreen(user: widget.user),
                            ),
                          ).then((_) => _loadCategories());
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('Crear Categoría'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary(context),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                  ],
                ),
              )
            : Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _categories.map((cat) {
                  final catId = cat['id'] as int;
                  final catColor = _hexToColor(cat['color'] as String);
                  final catIcon = cat['icono'] as String? ?? '';
                  final catName = cat['nombre'] as String? ?? '';
                  final isSelected = _selectedCategoryId == catId;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedCategoryId = catId),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: catColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: isSelected ? catColor : catColor.withValues(alpha: 0.5),
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: catColor,
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: Text(catIcon, style: const TextStyle(fontSize: 14)),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            catName,
                            style: TextStyle(
                              color: catColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
      ],
    );
  }

  Widget _buildDescriptionField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Descripción (opcional)',
          style: TextStyle(
            color: AppColors.textPrimary(context),
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _descriptionController,
          maxLines: 3,
          style: TextStyle(color: AppColors.textPrimary(context)),
          decoration: InputDecoration(
            hintText: 'Añade detalles...',
            hintStyle: TextStyle(color: AppColors.textSecondary(context)),
            filled: true,
            fillColor: AppColors.cardBackground(context),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDateSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Fecha',
          style: TextStyle(
            color: AppColors.textPrimary(context),
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => _selectDate(context),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.cardBackground(context),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  DateFormat('dd/MM/yyyy').format(_selectedDate),
                  style: TextStyle(
                    color: AppColors.textPrimary(context),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Icon(
                  Icons.calendar_today,
                  color: AppColors.primary(context),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentMethodSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Método de pago',
          style: TextStyle(
            color: AppColors.textPrimary(context),
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: PaymentMethod.values.map((method) {
            final idx = method.index;
            final selected = _selectedPaymentMethod == method;
            return ChoiceChip(
              label: Text(_paymentMethodLabels[method] ?? method.name),
              selected: selected,
              onSelected: (_) => setState(() => _selectedPaymentMethod = method),
              selectedColor: AppColors.primary(context),
              backgroundColor: AppColors.cardBackground(context),
              labelStyle: TextStyle(color: selected ? Colors.white : AppColors.textPrimary(context)),
              shape: const StadiumBorder(),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isSaving ? null : _saveTransaction,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary(context),
          disabledBackgroundColor: AppColors.textSecondary(context),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
        ),
        child: _isSaving
            ? SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Text(
                _isEditing ? 'Guardar cambios' : 'Registrar',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
      ),
    );
  }
}
