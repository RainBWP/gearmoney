# Guía de Fuentes Personalizadas en Flutter

## 1. Agregar las fuentes a tu proyecto

### Estructura de carpetas
```
proyecto/
├── assets/
│   └── fonts/
│       ├── Poppins/
│       │   ├── Poppins-Regular.ttf
│       │   ├── Poppins-Bold.ttf
│       │   ├── Poppins-SemiBold.ttf
│       │   └── ... (otras variantes)
│       └── (otras fuentes)
├── lib/
├── pubspec.yaml
└── ...
```

### Registrar en `pubspec.yaml`

```yaml
flutter:
  uses-material-design: true
  
  fonts:
    - family: Poppins
      fonts:
        - asset: assets/fonts/Poppins/Poppins-Regular.ttf
          weight: 400
        - asset: assets/fonts/Poppins/Poppins-SemiBold.ttf
          weight: 600
        - asset: assets/fonts/Poppins/Poppins-Bold.ttf
          weight: 700
    
    # Otra fuente ejemplo
    - family: Inter
      fonts:
        - asset: assets/fonts/Inter/Inter-Regular.ttf
          weight: 400
        - asset: assets/fonts/Inter/Inter-Bold.ttf
          weight: 700
```

## 2. Crear un archivo de tema centralizado

Crea el archivo `lib/theme/app_theme.dart`:

```dart
import 'package:flutter/material.dart';

class AppTheme {
  static const String fontFamilyPrimary = 'Poppins';
  static const String fontFamilySecondary = 'Inter';

  static ThemeData lightTheme = ThemeData(
    fontFamily: fontFamilyPrimary,
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        fontFamily: fontFamilyPrimary,
        fontSize: 32,
        fontWeight: FontWeight.w700,
      ),
      headlineMedium: TextStyle(
        fontFamily: fontFamilyPrimary,
        fontSize: 24,
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: TextStyle(
        fontFamily: fontFamilyPrimary,
        fontSize: 16,
        fontWeight: FontWeight.w400,
      ),
      bodyMedium: TextStyle(
        fontFamily: fontFamilyPrimary,
        fontSize: 14,
        fontWeight: FontWeight.w400,
      ),
      labelLarge: TextStyle(
        fontFamily: fontFamilyPrimary,
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
    ),
    colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
    useMaterial3: true,
  );
}
```

## 3. Usar el tema en `main.dart`

```dart
import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'screens/auth/login.dart';
import 'core/database/db_helper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DatabaseHelper.instance.database;
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GearMoney',
      theme: AppTheme.lightTheme,
      home: const LoginScreen(),
    );
  }
}
```

## 4. Usar la fuente en widgets

### Opción A: Usar estilos del tema
```dart
Text(
  'Mi Texto',
  style: Theme.of(context).textTheme.headlineMedium,
)
```

### Opción B: Especificar fuente directamente
```dart
Text(
  'Mi Texto',
  style: TextStyle(
    fontFamily: 'Poppins',
    fontSize: 18,
    fontWeight: FontWeight.w600,
  ),
)
```

## 5. Descargar fuentes

Recomendadas:
- **Google Fonts**: https://fonts.google.com/
  - Poppins, Inter, Roboto, Open Sans, etc.
  
- **Font Awesome** (para iconos): https://fontawesome.com/

## Notas

- ⚠️ Las fuentes deben estar en formato `.ttf` o `.otf`
- ⚠️ Después de agregar fuentes, ejecuta `flutter pub get` y reinicia la app
- ✅ Es mejor centralizar el tema en un archivo para mantener consistencia
- ✅ Usa `fontWeight` para cambiar la variante (400, 600, 700, etc.)
