import 'package:flutter/material.dart';
import '../../core/colors.dart';
import '../../core/database/db_helper.dart';

class CreateCategoryScreen extends StatefulWidget {
  final Map<String, dynamic> user;

  const CreateCategoryScreen({super.key, required this.user});

  @override
  State<CreateCategoryScreen> createState() => _CreateCategoryScreenState();
}

class _CreateCategoryScreenState extends State<CreateCategoryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  String _selectedColor = '#FF5722'; // Color por defecto (naranja)
  String _selectedIcon = '📁'; // Icono por defecto
  bool _isSaving = false;

  final List<String> _availableColors = [
    '#FF5722', // Rojo naranja
    '#FF6F00', // Naranja
    '#FFC107', // Amarillo
    '#8BC34A', // Verde claro
    '#4CAF50', // Verde
    '#00BCD4', // Cyan
    '#2196F3', // Azul
    '#3F51B5', // Índigo
    '#9C27B0', // Púrpura
    '#E91E63', // Rosa
    '#795548', // Marrón
    '#607D8B', // Gris azulado
  ];

  final List<String> _availableIcons = [
    '📁',
    '💰',
    '🛒',
    '🍔',
    '🚗',
    '🏠',
    '💻',
    '⚽',
    '📚',
    '🎬',
    '✈️',
    '💊',
    '🎮',
    '👕',
    '🌮',
    '☕',
    '🎓',
    '💐',
    '🐕',
    '⚡',
    '🎵',
    '🌍',
    '💍',
    '🏥',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _saveCategory() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSaving = true);

    try {
      final int userId = (widget.user['id'] is int)
          ? widget.user['id'] as int
          : int.tryParse('${widget.user['id']}') ?? 1;

      await DatabaseHelper.instance.createCategoria(
        nombre: _nameController.text,
        color: _selectedColor,
        icono: _selectedIcon,
        usuarioId: userId,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Categoría creada exitosamente'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background(context),
      appBar: AppBar(
        backgroundColor: AppColors.background(context),
        elevation: 0,
        title: Text(
          'Nueva Categoría',
          style: TextStyle(
            color: AppColors.textPrimary(context),
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Nombre
              Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: _buildNameField(),
              ),

              // Seleccionar icono
              Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: _buildIconSelector(),
              ),

              // Seleccionar color
              Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: _buildColorSelector(),
              ),

              // Preview
              Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: _buildPreview(),
              ),

              // Botón guardar
              _buildSaveButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNameField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Nombre de la categoría',
          style: TextStyle(
            color: AppColors.textPrimary(context),
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _nameController,
          style: TextStyle(color: AppColors.textPrimary(context)),
          decoration: InputDecoration(
            hintText: 'Ej: Comida, Transporte...',
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
              return 'Ingresa el nombre de la categoría';
            }
            if (value.length < 2) {
              return 'El nombre debe tener al menos 2 caracteres';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildIconSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Selecciona un icono',
          style: TextStyle(
            color: AppColors.textPrimary(context),
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 6,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: _availableIcons.length,
          itemBuilder: (context, index) {
            final icon = _availableIcons[index];
            final isSelected = icon == _selectedIcon;
            return GestureDetector(
              onTap: () => setState(() => _selectedIcon = icon),
              child: Container(
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary(context)
                      : AppColors.cardBackground(context),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primary(context)
                        : AppColors.textSecondary(context).withOpacity(0.3),
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Center(
                  child: Text(icon, style: const TextStyle(fontSize: 24)),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildColorSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Selecciona un color',
          style: TextStyle(
            color: AppColors.textPrimary(context),
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 6,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: _availableColors.length,
          itemBuilder: (context, index) {
            final colorHex = _availableColors[index];
            final color = Color(int.parse(colorHex.replaceFirst('#', '0xff')));
            final isSelected = colorHex == _selectedColor;

            return GestureDetector(
              onTap: () => setState(() => _selectedColor = colorHex),
              child: Container(
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected ? Colors.white : Colors.transparent,
                    width: 3,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: color.withOpacity(0.5),
                            blurRadius: 8,
                          ),
                        ]
                      : null,
                ),
                child: isSelected
                    ? const Center(
                        child: Icon(Icons.check, color: Colors.white, size: 24),
                      )
                    : null,
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildPreview() {
    final color = Color(int.parse(_selectedColor.replaceFirst('#', '0xff')));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Vista previa',
          style: TextStyle(
            color: AppColors.textPrimary(context),
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.cardBackground(context),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.3), width: 2),
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    _selectedIcon,
                    style: const TextStyle(fontSize: 32),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _nameController.text.isEmpty
                          ? 'Nombre de la categoría'
                          : _nameController.text,
                      style: TextStyle(
                        color: AppColors.textPrimary(context),
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Nueva categoría',
                      style: TextStyle(
                        color: AppColors.textSecondary(context),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isSaving ? null : _saveCategory,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary(context),
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
            : const Text(
                'Crear Categoría',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
      ),
    );
  }
}
