# Sistema de Movimientos (Ingresos/Gastos)

## Pantallas Disponibles

### CreateTransactionScreen
Formulario para registrar nuevos movimientos con validaciones:
- **Campos:**
  - Tipo (Ingreso/Gasto)
  - Cantidad (validación: > 0)
  - Categoría (obligatoria)
  - Descripción (opcional)
  - Fecha (date picker)
  - Método de pago (Efectivo, Tarjeta, Transferencia)

**Uso:**
```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => CreateTransactionScreen(user: widget.user),
  ),
);
```

### ListTransactionsScreen
Lista de movimientos con capacidad de eliminar por swipe (Dismissible):

**Uso:**
```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => ListTransactionsScreen(user: widget.user),
  ),
);
```

## CRUD Movimientos

### Crear movimiento
```dart
await DatabaseHelper.instance.createMovimiento(
  isIngreso: true,
  cantidad: 12345, // En centavos (100 = $1.00)
  nombre: 'Ingreso',
  descripcion: 'Descripción opcional',
  fecha: '2026-02-01',
  tieneHora: false,
  hora: null,
  categoriaId: 1,
  usuarioId: 1,
  metodoPago: 0, // 0=Efectivo, 1=Tarjeta, 2=Transferencia
);
```

### Leer movimientos
```dart
final movimientos = await DatabaseHelper.instance.readMovimientos();
// Filtrar por usuario
final userMovimientos = movimientos.where((m) => m['usuario_id'] == userId).toList();
```

### Actualizar movimiento
```dart
await DatabaseHelper.instance.updateMovimiento(
  movimientoId,
  {'cantidad': 50000, 'descripcion': 'Nuevo valor'},
);
```

### Eliminar movimiento
```dart
await DatabaseHelper.instance.deleteMovimiento(movimientoId);
```

## CRUD Categorías

### Crear categoría
```dart
await DatabaseHelper.instance.createCategoria(
  nombre: 'Comida',
  color: '#FF5722',
  icono: '🍔',
  usuarioId: 1,
);
```

### Leer categorías del usuario
```dart
final categorias = await DatabaseHelper.instance.readCategorias(userId);
```

### Leer categoría específica
```dart
final categoria = await DatabaseHelper.instance.readCategoriaById(categoryId);
```

### Actualizar categoría
```dart
await DatabaseHelper.instance.updateCategoria(
  categoryId,
  nombre: 'Nuevo nombre',
  color: '#FF0000',
  icono: '🍽️',
);
```

### Eliminar categoría
```dart
await DatabaseHelper.instance.deleteCategoria(categoryId);
```

## Validaciones Implementadas

- **Cantidad:** Debe ser > 0
- **Categoría:** Obligatoria (validación en formulario y DB)
- **Fecha:** Válida (date picker garantiza formato correcto)
- **Descripción:** Opcional
- **Método de pago:** Selección obligatoria (por defecto Efectivo)

## Notas
- Las cantidades se almacenan en centavos (integer)
- El `nombre` del movimiento se asigna automáticamente según tipo
- Los métodos de pago se almacenan como índice (0, 1, 2)
- Usar try-catch para manejar excepciones de validación