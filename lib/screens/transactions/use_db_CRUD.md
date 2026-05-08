# Usarlo en UI
Para que el usuario no pase a la siguiente pantalla si falla la validación, metes la función en un try-catch.

``` dart
void guardarDatos() async {
  try {
    await DatabaseHelper.instance.createMovimiento(
      isIngreso: true,
      cantidad: 12345, // Son $123.45 en centavos uwu
      nombre: 'Comida',
      fecha: '2026-02-01',
      tieneHora: false,
      categoriaId: 1,
      usuarioId: 1,
      metodoPago: 0, 
    );
    // Si sale bien, cierras pantalla o limpias ewe
    Navigator.pop(context); 
  } catch (e) {
    // Si falla la validación, le avisas al usuario ño
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
    );
  }
}
```