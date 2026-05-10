import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/colors.dart';
import '../../core/database/db_helper.dart';
import '../categories/create_category.dart';

enum PaymentMethod { cash, card, transfer }

class CreateTransactionScreen extends StatefulWidget {
  final Map<String, dynamic> user;
  final bool? initialIsIngreso;

  const CreateTransactionScreen({
    super.key,
    required this.user,
    this.initialIsIngreso,
  });

  @override
  State<CreateTransactionScreen> createState() =>
      _CreateTransactionScreenState();
}

class _CreateTransactionScreenState extends State<CreateTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController();
  final _descriptionController = TextEditingController();

  late bool _isIngreso;
  int? _selectedCategoryId;
  DateTime _selectedDate = DateTime.now();
  PaymentMethod _selectedPaymentMethod = PaymentMethod.cash;
  List<Map<String, dynamic>> _categories = [];
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _isIngreso = widget.initialIsIngreso ?? true;
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

    setState(() => _isSaving = true);

    try {
      final int userId = (widget.user['id'] is int)
          ? widget.user['id'] as int
          : int.tryParse('${widget.user['id']}') ?? 1;

      final quantity = _parseAmountToCents(_quantityController.text);
      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);

      await DatabaseHelper.instance.createMovimiento(
        isIngreso: _isIngreso,
        cantidad: quantity,
        nombre: _isIngreso ? 'Ingreso' : 'Gasto',
        descripcion: _descriptionController.text.isNotEmpty
            ? _descriptionController.text
            : null,
        fecha: dateStr,
        tieneHora: false,
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
          _isIngreso ? 'Nuevo Ingreso' : 'Nuevo Gasto',
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
                    // Tipo de movimiento
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _buildTypeSelector(),
                    ),

                    // Cantidad
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _buildQuantityField(),
                    ),

                    // Categoría
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _buildCategorySelector(),
                    ),

                    // Descripción
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _buildDescriptionField(),
                    ),

                    // Fecha
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _buildDateSelector(),
                    ),

                    // Método de pago
                    Padding(
                      padding: const EdgeInsets.only(bottom: 24),
                      child: _buildPaymentMethodSelector(),
                    ),

                    // Botón guardar
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
          borderRadius: BorderRadius.circular(8),
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
            : Container(
                decoration: BoxDecoration(
                  color: AppColors.cardBackground(context),
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: DropdownButton<int>(
                  value: _selectedCategoryId,
                  isExpanded: true,
                  underline: const SizedBox(),
                  style: TextStyle(color: AppColors.textPrimary(context)),
                  items: _categories.map((category) {
                    return DropdownMenuItem<int>(
                      value: category['id'] as int,
                      child: Text(category['nombre'] as String),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() => _selectedCategoryId = value);
                  },
                ),
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
        Container(
          decoration: BoxDecoration(
            color: AppColors.cardBackground(context),
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: DropdownButton<PaymentMethod>(
            value: _selectedPaymentMethod,
            isExpanded: true,
            underline: const SizedBox(),
            style: TextStyle(color: AppColors.textPrimary(context)),
            items: PaymentMethod.values.map((method) {
              return DropdownMenuItem<PaymentMethod>(
                value: method,
                child: Text(_paymentMethodLabels[method] ?? method.name),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() => _selectedPaymentMethod = value);
              }
            },
          ),
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
          backgroundColor: _isIngreso
              ? AppColors.success(context)
              : AppColors.alert(context),
          disabledBackgroundColor: AppColors.textSecondary(context),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
                _isIngreso ? 'Registrar Ingreso' : 'Registrar Gasto',
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
