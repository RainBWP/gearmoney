import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Universidad',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const BienvenidaScreen(),
    );
  }
}

class BienvenidaScreen extends StatelessWidget {
  const BienvenidaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Universidad'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Semana de talleres tecnologicos',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Container(
              height: 180,
              decoration: BoxDecoration(
                color: Colors.blue.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: const Text(
                'Placeholder de imagen',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Lorem ipsum dolor sit amet, consectetur adipiscing elit. '
              'Vivamus euismod, nibh ac facilisis iaculis, arcu justo '
              'pulvinar turpis, nec posuere erat justo at sapien.',
              textAlign: TextAlign.justify,
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
        foregroundColor: Theme.of(context).colorScheme.onSecondaryContainer,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const FormularioScreen()),
          );
        },
        label: const Text('Centro Inscribir'),
        icon: const Icon(Icons.school),
      ),
    );
  }
}

class FormularioScreen extends StatefulWidget {
  const FormularioScreen({super.key});

  @override
  State<FormularioScreen> createState() => _FormularioScreenState();
}

class _FormularioScreenState extends State<FormularioScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _matriculaController = TextEditingController();
  final TextEditingController _carreraController = TextEditingController();
  final TextEditingController _semestreController = TextEditingController();

  final List<String> _opcionesCursos = [
    'Programacion web',
    'Programacion Movil',
    'Ciberseguridad',
    'Animacion por Computadora',
    'Redes',
  ];

  final List<String> _cursosSeleccionados = [];
  String? _modalidad;
  bool _mostrarErrorCursos = false;
  bool _mostrarErrorModalidad = false;

  bool get _isFormReady {
    return _nombreController.text.trim().isNotEmpty &&
        _matriculaController.text.trim().isNotEmpty &&
        _carreraController.text.trim().isNotEmpty &&
        _semestreController.text.trim().isNotEmpty &&
        _cursosSeleccionados.isNotEmpty &&
        _modalidad != null;
  }

  @override
  void initState() {
    super.initState();
    _nombreController.addListener(_refresh);
    _matriculaController.addListener(_refresh);
    _carreraController.addListener(_refresh);
    _semestreController.addListener(_refresh);
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _matriculaController.dispose();
    _carreraController.dispose();
    _semestreController.dispose();
    super.dispose();
  }

  void _refresh() {
    setState(() {});
  }

  void _toggleCurso(String curso, bool seleccionado) {
    setState(() {
      if (seleccionado) {
        _cursosSeleccionados.add(curso);
      } else {
        _cursosSeleccionados.remove(curso);
      }
      _mostrarErrorCursos = false;
    });
  }

  void _enviarFormulario() {
    final esValido = _formKey.currentState!.validate();

    setState(() {
      _mostrarErrorCursos = _cursosSeleccionados.isEmpty;
      _mostrarErrorModalidad = _modalidad == null;
    });

    if (!esValido || _mostrarErrorCursos || _mostrarErrorModalidad) {
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ResultadoScreen(
          nombre: _nombreController.text.trim(),
          matricula: _matriculaController.text.trim(),
          carrera: _carreraController.text.trim(),
          semestre: _semestreController.text.trim(),
          cursos: _cursosSeleccionados,
          modalidad: _modalidad!,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Universidad'),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nombreController,
              decoration: const InputDecoration(labelText: 'Nombre'),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'El nombre es obligatorio';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _matriculaController,
              decoration: const InputDecoration(labelText: 'Matricula'),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'La matricula es obligatoria';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _carreraController,
              decoration: const InputDecoration(labelText: 'Carrera'),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'La carrera es obligatoria';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _semestreController,
              decoration: const InputDecoration(labelText: 'Semestre Actual'),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'El semestre actual es obligatorio';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            const Text(
              'Curso que inscribe (multiple opcion):',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            ..._opcionesCursos.map(
              (curso) => CheckboxListTile(
                value: _cursosSeleccionados.contains(curso),
                title: Text(curso),
                controlAffinity: ListTileControlAffinity.leading,
                onChanged: (value) => _toggleCurso(curso, value ?? false),
                contentPadding: EdgeInsets.zero,
              ),
            ).toList(),
            if (_mostrarErrorCursos)
              const Padding(
                padding: EdgeInsets.only(top: 4),
                child: Text(
                  'Selecciona al menos un curso',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            const SizedBox(height: 20),
            const Text(
              'Modalidad (una opcion):',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            RadioListTile<String>(
              value: 'Presencial',
              groupValue: _modalidad,
              title: const Text('Presencial'),
              contentPadding: EdgeInsets.zero,
              onChanged: (value) {
                setState(() {
                  _modalidad = value;
                  _mostrarErrorModalidad = false;
                });
              },
            ),
            RadioListTile<String>(
              value: 'Remoto',
              groupValue: _modalidad,
              title: const Text('Remoto'),
              contentPadding: EdgeInsets.zero,
              onChanged: (value) {
                setState(() {
                  _modalidad = value;
                  _mostrarErrorModalidad = false;
                });
              },
            ),
            RadioListTile<String>(
              value: 'Hibrido',
              groupValue: _modalidad,
              title: const Text('Hibrido'),
              contentPadding: EdgeInsets.zero,
              onChanged: (value) {
                setState(() {
                  _modalidad = value;
                  _mostrarErrorModalidad = false;
                });
              },
            ),
            if (_mostrarErrorModalidad)
              const Padding(
                padding: EdgeInsets.only(top: 4),
                child: Text(
                  'Selecciona una modalidad',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isFormReady ? _enviarFormulario : null,
                child: const Text('Enviar'),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}

class ResultadoScreen extends StatelessWidget {
  final String nombre;
  final String matricula;
  final String carrera;
  final String semestre;
  final List<String> cursos;
  final String modalidad;

  const ResultadoScreen({
    super.key,
    required this.nombre,
    required this.matricula,
    required this.carrera,
    required this.semestre,
    required this.cursos,
    required this.modalidad,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Universidad'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Registro Exitoso',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Text('Nombre: $nombre', style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 12),
            Text('Matricula: $matricula', style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 12),
            Text('Carrera: $carrera', style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 12),
            Text('Semestre Actual: $semestre', style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 12),
            Text(
              'Cursos: ${cursos.join(', ')}',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 12),
            Text('Modalidad: $modalidad', style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Comprobante enviado a impresion')),
                );
              },
              child: const Text('Imprimir Comprobante'),
            ),
          ],
        ),
      ),
    );
  }
}