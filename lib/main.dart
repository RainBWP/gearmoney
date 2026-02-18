import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Registro de Alumno',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const FormularioScreen(),
    );
  }
}

// Pantalla 1: Formulario
class FormularioScreen extends StatefulWidget {
  const FormularioScreen({super.key});

  @override
  State<FormularioScreen> createState() => _FormularioScreenState();
}

class _FormularioScreenState extends State<FormularioScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  
  String nombre = '';
  String matricula = '';
  String carrera = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registro de Alumno'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                decoration: const InputDecoration(labelText: 'Nombre del Alumno'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'El nombre no puede estar vacío';
                  }
                  return null;
                },
                onSaved: (value) => nombre = value!,
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Matrícula'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'La matrícula no puede estar vacía';
                  }
                  if (int.tryParse(value) == null) {
                    return 'La matrícula debe ser numérica';
                  }
                  return null;
                },
                onSaved: (value) => matricula = value!,
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Carrera'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'La carrera no puede estar vacía';
                  }
                  return null;
                },
                onSaved: (value) => carrera = value!,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    _formKey.currentState!.save();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ResultadoScreen(
                          nombre: nombre,
                          matricula: matricula,
                          carrera: carrera,
                        ),
                      ),
                    );
                  }
                },
                child: const Text('Registrar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Pantalla 2: Resultado
class ResultadoScreen extends StatelessWidget {
  final String nombre;
  final String matricula;
  final String carrera;

  const ResultadoScreen({
    super.key,
    required this.nombre,
    required this.matricula,
    required this.carrera,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Alumno Registrado'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Alumno Registrado',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            Text('Nombre: $nombre', style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 12),
            Text('Matrícula: $matricula', style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 12),
            Text('Carrera: $carrera', style: const TextStyle(fontSize: 18)),
          ],
        ),
      ),
    );
  }
}