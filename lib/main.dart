import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Control de Acceso',
      debugShowCheckedModeBanner: false,
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int intentosRestantes = 3;

  String get mensajeEstado {
    if (intentosRestantes == 0) {
      return 'Acceso bloqueado: sin intentos.';
    }
    if (intentosRestantes == 1) {
      return 'Ultimo intento disponible.';
    }
    return 'Puedes intentar acceder.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pantalla Principal')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Intentos restantes:', style: TextStyle(fontSize: 20)),
            const SizedBox(height: 10),
            Text(
              '$intentosRestantes',
              style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text(mensajeEstado, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: intentosRestantes > 0
                  ? () {
                      setState(() {
                        intentosRestantes--;
                      });
                    }
                  : null,
              child: const Text('Intentar acceso'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: intentosRestantes > 0
                  ? () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              SegundaPantalla(intentos: intentosRestantes),
                        ),
                      );
                    }
                  : null,
              child: const Text('Ir a Segunda Pantalla'),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            intentosRestantes = 3;
          });
        },
        child: const Icon(Icons.refresh),
      ),
    );
  }
}

class SegundaPantalla extends StatelessWidget {
  final int intentos;

  const SegundaPantalla({super.key, required this.intentos});

  @override
  Widget build(BuildContext context) {
    final String mensaje = intentos > 0
        ? 'Aun tienes intentos disponibles.'
        : 'Ya no tienes intentos disponibles.';

    return Scaffold(
      appBar: AppBar(title: const Text('Segunda Pantalla')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(mensaje, style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 12),
            Text(
              'Intentos recibidos: $intentos',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Regresar'),
            ),
          ],
        ),
      ),
    );
  }
}
