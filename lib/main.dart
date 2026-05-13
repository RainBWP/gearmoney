import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:gearmoney/core/colors.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'core/database/db_helper.dart';
import 'screens/auth/login.dart';

import 'core/theme_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // FFI only for desktop; Android/iOS must use native sqflite.
  final isDesktop =
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.windows ||
          defaultTargetPlatform == TargetPlatform.linux ||
          defaultTargetPlatform == TargetPlatform.macOS);
  if (isDesktop) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  // Esto inicializa la base de datos al arrancar
  await DatabaseHelper.instance.database;

  debugPaintSizeEnabled =
      false; // borra una linea amarilla en el texto cuando debug
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (_, ThemeMode currentMode, __) {
        return MaterialApp(
          title: 'GearMoney',

          themeMode: currentMode,

          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(
                0xFFF0C300,
              ), // Usamos el HEX directo porque AppColors.primary necesita contexto con el tema ya aplicado
              brightness: Brightness.light,
            ),
            useMaterial3: true,
            fontFamily: 'Verdana',
          ),

          darkTheme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFFF0C300),
              brightness: Brightness.dark,
            ),
            useMaterial3: true,
            fontFamily: 'Verdana',
          ),

          home: const LoginScreen(),
        );
      },
    );
  }
}
