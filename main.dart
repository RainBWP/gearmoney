import 'package:flutter/material.dart';

void main() {
    runApp(const MyApp());
}

class MyApp extends StatelessWidget {
    const MyApp({super.key});

    @override
    Widget build(BuildContext context) {
        return MaterialApp(
            title: 'Flutter Basico',
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
                primarySwatch: Colors.blue,
            ),
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
    int contador = 0;
    @override
    Widget build(BuildContext context) {
        return Scaffold(
            appBar: AppBar(
                title: const Text('Pantalla Principal'),
                centerTitle: true,
            ),
            body: Center(
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                        const Text(
                            'Contador Actual:',
                            style: TextStyle(fontSize: 18),
                        ),

                        const SizedBox(height: 10),

                        Text(
                            '$contador',
                            style: const TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                            )
                        ),

                        const SizedBox(height: 20),
                        
                        ElevatedButton(onPressed: (){
                            setState(() {
                                contador++;
                            });
                        }, child: const Text('Incrementar')),

                        ElevatedButton(
                            onPressed: () {
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) => SegundaPantalla(valor: contador),
                                    ),
                                );
                            },
                            child: const Text('Ir a Segunda Pantalla'),
                        ),
                        FloatingActionButton(
                            onPressed: (){
                                setState(() {
                                    contador=0;
                                });
                            },
                            child: const Icon(Icons.refresh),
                        )
                    ],
                ),
            ),
        );
    }
}

class SegundaPantalla extends StatelessWidget {
    final int valor;

    const SegundaPantalla({super.key, required this.valor});

    @override
    Widget build(BuildContext context) {
        return Scaffold(
            appBar: AppBar(
                title: const Text('Segunda Pantalla'),
            ),
            body: Center(
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                        const Text(
                            'Valor recibido:',
                            style: TextStyle(fontSize: 18),
                        ),

                        const SizedBox(height: 10),

                        Text(
                            '$valor',
                            style: const TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                            ),
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