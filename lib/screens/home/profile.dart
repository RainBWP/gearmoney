import 'package:flutter/material.dart';
import '../../core/colors.dart';
import '../../core/database/db_helper.dart';
import '../../core/theme_manager.dart';
import '../auth/login.dart';


class ProfileScreen extends StatefulWidget {
  final Map<String, dynamic> user;

  const ProfileScreen({super.key, required this.user});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _lastnameController;
  late TextEditingController _emailController;
  bool _isEditing = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user['nombre'] ?? '');
    _lastnameController = TextEditingController(
      text: widget.user['apellidos'] ?? '',
    );
    _emailController = TextEditingController(text: widget.user['correo'] ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _lastnameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  int get _userId {
    return (widget.user['id'] is int)
        ? widget.user['id'] as int
        : int.tryParse('${widget.user['id']}') ?? 1;
  }

  Future<void> _saveProfile() async {
    if (_nameController.text.isEmpty ||
        _lastnameController.text.isEmpty ||
        _emailController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor completa todos los campos')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      await DatabaseHelper.instance.updateUsuario(
        _userId,
        nombre: _nameController.text.trim(),
        apellidos: _lastnameController.text.trim(),
        correo: _emailController.text.trim(),
      );

      widget.user['nombre'] = _nameController.text.trim();
      widget.user['apellidos'] = _lastnameController.text.trim();
      widget.user['correo'] = _emailController.text.trim();

      if (mounted) {
        setState(() => _isEditing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Perfil actualizado exitosamente')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _cancelEditing() {
    setState(() {
      _isEditing = false;
      _nameController.text = widget.user['nombre'] ?? '';
      _lastnameController.text = widget.user['apellidos'] ?? '';
      _emailController.text = widget.user['correo'] ?? '';
    });
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Eliminar perfil'),
          content: const Text(
            '¿Estás seguro de que deseas borrar tu perfil? Esta acción no se puede deshacer.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await _deleteProfile();
    }
  }

  Future<void> _deleteProfile() async {
    setState(() => _isSaving = true);

    try {
      await DatabaseHelper.instance.deleteUsuario(_userId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Perfil eliminado correctamente')),
        );
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al borrar perfil: ${e.toString()}')),
        );
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
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(32),
          children: [
            Text(
              'Perfil',
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w600,
                color: AppColors.primary(context),
              ),
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.cardBackground(context),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Nombre',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary(context),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _nameController,
                    enabled: _isEditing,
                    decoration: InputDecoration(
                      hintText: 'Tu nombre',
                      hintStyle: TextStyle(color: Colors.grey[400]),
                      border: InputBorder.none,
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(
                          color: Colors.grey[400]!,
                          width: 1,
                        ),
                      ),
                      disabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(
                          color: Colors.grey[400]!,
                          width: 1,
                        ),
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(
                          color: AppColors.primary(context),
                          width: 2,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Apellidos',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary(context),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _lastnameController,
                    enabled: _isEditing,
                    decoration: InputDecoration(
                      hintText: 'Tus apellidos',
                      hintStyle: TextStyle(color: Colors.grey[400]),
                      border: InputBorder.none,
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(
                          color: Colors.grey[400]!,
                          width: 1,
                        ),
                      ),
                      disabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(
                          color: Colors.grey[400]!,
                          width: 1,
                        ),
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(
                          color: AppColors.primary(context),
                          width: 2,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Correo',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary(context),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _emailController,
                    enabled: _isEditing,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      hintText: 'tu@email.com',
                      hintStyle: TextStyle(color: Colors.grey[400]),
                      border: InputBorder.none,
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(
                          color: Colors.grey[400]!,
                          width: 1,
                        ),
                      ),
                      disabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(
                          color: Colors.grey[400]!,
                          width: 1,
                        ),
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(
                          color: AppColors.primary(context),
                          width: 2,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _isSaving
                          ? null
                          : () {
                              if (_isEditing) {
                                _saveProfile();
                              } else {
                                setState(() => _isEditing = true);
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary(context),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : Text(
                              _isEditing ? 'Guardar cambios' : 'Editar perfil',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                  if (_isEditing) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: OutlinedButton(
                        onPressed: _isSaving ? null : _cancelEditing,
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: AppColors.textSecondary(context),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Cancelar',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton(
                      onPressed: _isSaving ? null : () {
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(builder: (_) => const LoginScreen()),
                          (route) => false,
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: AppColors.textSecondary(context),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Cerrar sesión',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton(
                      onPressed: _isSaving ? null : _confirmDelete,
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.red.shade50,
                        foregroundColor: Colors.red,
                        side: BorderSide(color: Colors.red.shade200),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Borrar perfil',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            Text(
              'Ajustes',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppColors.primary(context),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
              decoration: BoxDecoration(
                color: AppColors.cardBackground(context),
                borderRadius: BorderRadius.circular(16),
              ),
              child: ValueListenableBuilder<ThemeMode>(
                valueListenable: themeNotifier,
                builder: (context, currentMode, child) {
                  // Determina si el switch debe estar encendido (true = dark mode)
                  final isDark =
                      currentMode == ThemeMode.dark ||
                      (currentMode == ThemeMode.system &&
                          MediaQuery.of(context).platformBrightness ==
                              Brightness.dark);

                  return SwitchListTile(
                    title: Text(
                      'Modo Oscuro',
                      style: TextStyle(
                        color: AppColors.textPrimary(context),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    secondary: Icon(
                      isDark ? Icons.dark_mode : Icons.light_mode,
                      color: AppColors.primary(context),
                    ),
                    value: isDark,
                    activeColor: AppColors.primary(context),
                    onChanged: (value) {
                      // Cambia el estado global del tema
                      themeNotifier.value = value
                          ? ThemeMode.dark
                          : ThemeMode.light;
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
