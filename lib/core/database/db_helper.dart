// PLEASE DONT EDIT SQL TABLES THEY ARE FINE AND CREATED BEFORE
// BUILD ALL THE PROYECT, NO REBUILD TABLES, IF SOMETHING IS NOT OM THE TABLE
// MAYBE ITS BECAUSE IT SHOULDNT BE THERE, NO REBUILD TABLES

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('finanzas.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    // onCreate se ejecuta solo la primera vez que se abre la base de datos
    // Si la BD ya existe, simplemente se reabre sin ejecutar onCreate
    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB, // Solo se ejecuta en primera creación
      singleInstance: true,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE Usuario (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT NOT NULL,
        apellidos TEXT NOT NULL,
        correo TEXT NOT NULL,
        contrasena TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE Categorias (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT NOT NULL,
        color TEXT NOT NULL, 
        icono TEXT NOT NULL,
        usuario_id INTEGER NOT NULL
      )
    ''');

    // Usamos INTEGER para la cantidad (centavos) como en tus notas
    await db.execute('''
      CREATE TABLE Movimientos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        is_ingreso INTEGER NOT NULL,
        cantidad INTEGER NOT NULL,
        nombre TEXT NOT NULL,
        descripcion TEXT,
        fecha TEXT NOT NULL,
        tiene_hora INTEGER NOT NULL,
        hora TEXT,
        categoria_id INTEGER NOT NULL,
        usuario_id INTEGER NOT NULL,
        metodo_pago INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE Presupuestos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT NOT NULL,
        monto INTEGER NOT NULL,
        dia_ciclo INTEGER NOT NULL,
        usuario_id INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE Presupuestos_Categorias (
        id_presupuesto INTEGER NOT NULL,
        id_categoria INTEGER NOT NULL,
        PRIMARY KEY (id_presupuesto, id_categoria)
      )
    ''');
  }

  // --- CRUD USUARIO ---

  Future<int> createUsuario({
    required String nombre,
    required String apellidos,
    required String correo,
    required String contrasena,
  }) async {
    // Validaciones
    if (nombre.trim().isEmpty) throw Exception('El nombre es obligatorio');
    if (apellidos.trim().isEmpty) throw Exception('Los apellidos son obligatorios');
    if (correo.trim().isEmpty) throw Exception('El correo es obligatorio');
    if (contrasena.isEmpty) throw Exception('La contraseña es obligatoria');
    if (contrasena.length < 6) {
      throw Exception('La contraseña debe tener al menos 6 caracteres');
    }

    final db = await instance.database;
    
    // Verificar si el correo ya existe
    final existing = await db.query(
      'Usuario',
      where: 'correo = ?',
      whereArgs: [correo.trim().toLowerCase()],
    );
    
    if (existing.isNotEmpty) {
      throw Exception('Este correo ya está registrado');
    }

    return await db.insert('Usuario', {
      'nombre': nombre.trim(),
      'apellidos': apellidos.trim(),
      'correo': correo.trim().toLowerCase(),
      'contrasena': contrasena, // En producción, usar hash como bcrypt
    });
  }

  Future<Map<String, dynamic>?> readUsuario(String correo, String contrasena) async {
    final db = await instance.database;
    final result = await db.query(
      'Usuario',
      where: 'correo = ? AND contrasena = ?',
      whereArgs: [correo.trim().toLowerCase(), contrasena],
    );
    
    return result.isNotEmpty ? result.first : null;
  }

  Future<Map<String, dynamic>?> readUsuarioById(int id) async {
    final db = await instance.database;
    final result = await db.query(
      'Usuario',
      where: 'id = ?',
      whereArgs: [id],
    );
    
    return result.isNotEmpty ? result.first : null;
  }

  Future<int> updateUsuario(
    int id, {
    String? nombre,
    String? apellidos,
    String? correo,
    String? contrasena,
  }) async {
    final db = await instance.database;
    final updates = <String, dynamic>{};

    if (nombre != null && nombre.trim().isNotEmpty) {
      updates['nombre'] = nombre.trim();
    }
    if (apellidos != null && apellidos.trim().isNotEmpty) {
      updates['apellidos'] = apellidos.trim();
    }
    if (correo != null && correo.trim().isNotEmpty) {
      updates['correo'] = correo.trim().toLowerCase();
    }
    if (contrasena != null && contrasena.isNotEmpty) {
      if (contrasena.length < 6) {
        throw Exception('La contraseña debe tener al menos 6 caracteres');
      }
      updates['contrasena'] = contrasena;
    }

    if (updates.isEmpty) throw Exception('No hay datos para actualizar');

    return await db.update('Usuario', updates, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteUsuario(int id) async {
    final db = await instance.database;
    return await db.delete('Usuario', where: 'id = ?', whereArgs: [id]);
  }

  // --- CRUD EJEMPLO MOVIMIENTOS ---

  Future<int> createMovimiento({
    required bool isIngreso,
    required int cantidad,
    required String nombre,
    String? descripcion,
    required String fecha,
    required bool tieneHora,
    String? hora,
    required int categoriaId,
    required int usuarioId,
    required int metodoPago,
  }) async {
    // Validaciones ño
    if (cantidad <= 0) throw Exception('La cantidad debe ser mayor a 0');
    if (nombre.trim().isEmpty) throw Exception('El nombre es obligatorio');
    if (categoriaId <= 0) throw Exception('Selecciona una categoría válida');

    final db = await instance.database;
    return await db.insert('Movimientos', {
      'is_ingreso': isIngreso ? 1 : 0,
      'cantidad': cantidad,
      'nombre': nombre,
      'descripcion': descripcion,
      'fecha': fecha,
      'tiene_hora': tieneHora ? 1 : 0,
      'hora': hora,
      'categoria_id': categoriaId,
      'usuario_id': usuarioId,
      'metodo_pago': metodoPago,
    });
  }

  Future<List<Map<String, dynamic>>> readMovimientos() async {
    final db = await instance.database;
    return await db.query('Movimientos', orderBy: 'fecha DESC');
  }

  Future<int> updateMovimiento(int id, Map<String, dynamic> datosActualizados) async {
    if (datosActualizados.containsKey('cantidad') && datosActualizados['cantidad'] <= 0) {
      throw Exception('La cantidad no puede ser 0');
    }
    final db = await instance.database;
    return await db.update('Movimientos', datosActualizados, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteMovimiento(int id) async {
    final db = await instance.database;
    return await db.delete('Movimientos', where: 'id = ?', whereArgs: [id]);
  }
}