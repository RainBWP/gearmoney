import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart'
    show ConflictAlgorithm, Database, getDatabasesPath, openDatabase;

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

class Registro {
  final int? id;
  final String nombre;
  final String matricula;
  final String carrera;
  final String semestre;
  final List<String> cursos;
  final String modalidad;

  const Registro({
    this.id,
    required this.nombre,
    required this.matricula,
    required this.carrera,
    required this.semestre,
    required this.cursos,
    required this.modalidad,
  });

  Registro copyWith({
    int? id,
    String? nombre,
    String? matricula,
    String? carrera,
    String? semestre,
    List<String>? cursos,
    String? modalidad,
  }) {
    return Registro(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      matricula: matricula ?? this.matricula,
      carrera: carrera ?? this.carrera,
      semestre: semestre ?? this.semestre,
      cursos: cursos ?? this.cursos,
      modalidad: modalidad ?? this.modalidad,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
      'matricula': matricula,
      'carrera': carrera,
      'semestre': semestre,
      'cursos': jsonEncode(cursos),
      'modalidad': modalidad,
    };
  }

  factory Registro.fromMap(Map<String, dynamic> map) {
    return Registro(
      id: map['id'] as int,
      nombre: map['nombre'] as String,
      matricula: map['matricula'] as String,
      carrera: map['carrera'] as String,
      semestre: map['semestre'] as String,
      cursos: (jsonDecode(map['cursos'] as String) as List<dynamic>)
          .map((curso) => curso.toString())
          .toList(),
      modalidad: map['modalidad'] as String,
    );
  }
}

class RegistroDatabase {
  RegistroDatabase._();

  static final RegistroDatabase instance = RegistroDatabase._();
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;

    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, 'registros_universidad.db');

    _database = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE registros (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            nombre TEXT NOT NULL,
            matricula TEXT NOT NULL,
            carrera TEXT NOT NULL,
            semestre TEXT NOT NULL,
            cursos TEXT NOT NULL,
            modalidad TEXT NOT NULL
          )
        ''');
      },
    );

    return _database!;
  }

  Future<int> crearRegistro(Registro registro) async {
    final db = await database;
    return db.insert(
      'registros',
      registro.toMap()..remove('id'),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Registro>> obtenerRegistros() async {
    final db = await database;
    final registros = await db.query('registros', orderBy: 'id DESC');
    return registros.map(Registro.fromMap).toList();
  }

  Future<int> actualizarRegistro(Registro registro) async {
    final db = await database;
    return db.update(
      'registros',
      registro.toMap()..remove('id'),
      where: 'id = ?',
      whereArgs: [registro.id],
    );
  }

  Future<int> borrarRegistro(int id) async {
    final db = await database;
    return db.delete('registros', where: 'id = ?', whereArgs: [id]);
  }
}

class BienvenidaScreen extends StatelessWidget {
  const BienvenidaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Universidad'), centerTitle: true),
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
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const RegistrosScreen()),
                  );
                },
                icon: const Icon(Icons.list_alt),
                label: const Text('Ver registros'),
              ),
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
  final Registro? registro;

  const FormularioScreen({super.key, this.registro});

  @override
  State<FormularioScreen> createState() => _FormularioScreenState();
}

class _FormularioScreenState extends State<FormularioScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _matriculaController = TextEditingController();

  final List<String> _opcionesCarrera = [
    'Licenciatura en Ingeniera de Ciencias de la Computacion',
    'Ciberseguridad',
    'Ingeniero en Tecnlologias Inamalbricas',
    'Inteligencia Artificial',
  ];

  final List<String> _opcionesSemestre = [
    '1',
    '2',
    '3',
    '4',
    '5',
    '6',
    '7',
    '8',
    '9',
    '10',
    'OTRO',
  ];

  final List<String> _opcionesCursos = [
    'Programacion web',
    'Programacion Movil',
    'Ciberseguridad',
    'Animacion por Computadora',
    'Redes',
  ];

  final List<String> _cursosSeleccionados = [];
  String? _carreraSeleccionada;
  String? _semestreSeleccionado;
  String? _modalidad;
  bool _mostrarErrorCursos = false;
  bool _mostrarErrorModalidad = false;

  bool get _isEditMode => widget.registro != null;

  bool get _isFormReady {
    return _nombreController.text.trim().isNotEmpty &&
        _matriculaController.text.trim().isNotEmpty &&
        _carreraSeleccionada != null &&
        _semestreSeleccionado != null &&
        _cursosSeleccionados.isNotEmpty &&
        _modalidad != null;
  }

  @override
  void initState() {
    super.initState();
    _nombreController.addListener(_refresh);
    _matriculaController.addListener(_refresh);

    final registro = widget.registro;
    if (registro != null) {
      _nombreController.text = registro.nombre;
      _matriculaController.text = registro.matricula;
      _carreraSeleccionada = registro.carrera;
      _semestreSeleccionado = registro.semestre;
      _cursosSeleccionados.addAll(registro.cursos);
      _modalidad = registro.modalidad;
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _matriculaController.dispose();
    super.dispose();
  }

  void _refresh() {
    setState(() {});
  }

  void _toggleCurso(String curso, bool seleccionado) {
    setState(() {
      if (seleccionado) {
        if (!_cursosSeleccionados.contains(curso)) {
          _cursosSeleccionados.add(curso);
        }
      } else {
        _cursosSeleccionados.remove(curso);
      }
      _mostrarErrorCursos = false;
    });
  }

  Future<void> _enviarFormulario() async {
    final esValido = _formKey.currentState!.validate();

    setState(() {
      _mostrarErrorCursos = _cursosSeleccionados.isEmpty;
      _mostrarErrorModalidad = _modalidad == null;
    });

    if (!esValido || _mostrarErrorCursos || _mostrarErrorModalidad) {
      return;
    }

    final registro = Registro(
      id: widget.registro?.id,
      nombre: _nombreController.text.trim(),
      matricula: _matriculaController.text.trim(),
      carrera: _carreraSeleccionada!,
      semestre: _semestreSeleccionado!,
      cursos: List<String>.from(_cursosSeleccionados),
      modalidad: _modalidad!,
    );

    if (_isEditMode) {
      await RegistroDatabase.instance.actualizarRegistro(registro);
      if (!mounted) return;
      Navigator.pop(context, true);
      return;
    }

    final nuevoId = await RegistroDatabase.instance.crearRegistro(registro);
    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ResultadoScreen(
          registro: registro.copyWith(id: nuevoId),
          titulo: 'Registro Exitoso',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? 'Editar Registro' : 'Universidad'),
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
            DropdownButtonFormField<String>(
              value: _carreraSeleccionada,
              decoration: const InputDecoration(labelText: 'Carrera'),
              items: _opcionesCarrera
                  .map(
                    (carrera) => DropdownMenuItem<String>(
                      value: carrera,
                      child: Text(carrera),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _carreraSeleccionada = value;
                });
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'La carrera es obligatoria';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              value: _semestreSeleccionado,
              decoration: const InputDecoration(labelText: 'Semestre Actual'),
              items: _opcionesSemestre
                  .map(
                    (semestre) => DropdownMenuItem<String>(
                      value: semestre,
                      child: Text(semestre),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _semestreSeleccionado = value;
                });
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
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
            ..._opcionesCursos
                .map(
                  (curso) => CheckboxListTile(
                    value: _cursosSeleccionados.contains(curso),
                    title: Text(curso),
                    controlAffinity: ListTileControlAffinity.leading,
                    onChanged: (value) => _toggleCurso(curso, value ?? false),
                    contentPadding: EdgeInsets.zero,
                  ),
                )
                .toList(),
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
                child: Text(_isEditMode ? 'Guardar cambios' : 'Enviar'),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}

class RegistrosScreen extends StatefulWidget {
  const RegistrosScreen({super.key});

  @override
  State<RegistrosScreen> createState() => _RegistrosScreenState();
}

class _RegistrosScreenState extends State<RegistrosScreen> {
  late Future<List<Registro>> _registrosFuture;

  @override
  void initState() {
    super.initState();
    _cargarRegistros();
  }

  void _cargarRegistros() {
    _registrosFuture = RegistroDatabase.instance.obtenerRegistros();
  }

  Future<void> _editarRegistro(Registro registro) async {
    final actualizado = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => FormularioScreen(registro: registro)),
    );

    if (actualizado == true) {
      setState(_cargarRegistros);
    }
  }

  Future<void> _borrarRegistro(Registro registro) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Borrar registro'),
          content: const Text(
            'Esta accion eliminara el registro seleccionado.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Borrar'),
            ),
          ],
        );
      },
    );

    if (confirmar != true || registro.id == null) {
      return;
    }

    await RegistroDatabase.instance.borrarRegistro(registro.id!);
    if (!mounted) return;

    setState(_cargarRegistros);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registros Guardados'),
        centerTitle: true,
      ),
      body: FutureBuilder<List<Registro>>(
        future: _registrosFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(
              child: Text('No se pudieron cargar los registros.'),
            );
          }

          final registros = snapshot.data ?? [];

          if (registros.isEmpty) {
            return const Center(child: Text('Aun no hay registros guardados.'));
          }

          return RefreshIndicator(
            onRefresh: () async {
              setState(_cargarRegistros);
              await _registrosFuture;
            },
            child: ListView.separated(
              itemCount: registros.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final registro = registros[index];

                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  title: Text(
                    registro.matricula,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '${registro.nombre} - ${registro.carrera}',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ResultadoScreen(
                          registro: registro,
                          titulo: 'Detalle de Registro',
                        ),
                      ),
                    );
                  },
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'editar') {
                        _editarRegistro(registro);
                      }

                      if (value == 'borrar') {
                        _borrarRegistro(registro);
                      }
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem<String>(
                        value: 'editar',
                        child: Text('Editar'),
                      ),
                      PopupMenuItem<String>(
                        value: 'borrar',
                        child: Text('Borrar'),
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class ResultadoScreen extends StatelessWidget {
  final Registro registro;
  final String titulo;

  const ResultadoScreen({
    super.key,
    required this.registro,
    required this.titulo,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Universidad'), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              titulo,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Text(
              'Nombre: ${registro.nombre}',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 12),
            Text(
              'Matricula: ${registro.matricula}',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 12),
            Text(
              'Carrera: ${registro.carrera}',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 12),
            Text(
              'Semestre Actual: ${registro.semestre}',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 12),
            Text(
              'Cursos: ${registro.cursos.join(', ')}',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 12),
            Text(
              'Modalidad: ${registro.modalidad}',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Comprobante enviado a impresion'),
                  ),
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
