import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'core/database/db_helper.dart';
import 'screens/auth/login.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializar sqflite para Windows/Desktop
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
  
  // Esto inicializa la base de datos al arrancar
  await DatabaseHelper.instance.database; 

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GearMoney',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const LoginScreen(),
    );
  }
}

