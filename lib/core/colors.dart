import 'package:flutter/material.dart';

class AppColors {
    // ----- Light theme values -----
    static const Color _primaryLight = Color(0xFFF0C300);          // amarillo
    static const Color _backgroundLight = Color(0xFFFFFFFF);       // blanco
    static const Color _textPrimaryLight = Color(0xFF000000);     // negro oscuro
    static const Color _textSecondaryLight = Color(0xFF888888);   // gris medio
    static const Color _cardBackgroundLight = Color(0xFFEEEEEE);  // gris claro
    static const Color _alertLight = Color(0xFFFF4D4D);
    static const Color _warningLight = Color.fromARGB(255, 255, 166, 0);
    static const Color _successLight = Color(0xFF4CAF50);

    // ----- Dark theme values -----
    static const Color _primaryDark = Color(0xFFF0C300);           // la misma amarillo
    static const Color _backgroundDark = Color(0xFF121212);        // negro difuso
    static const Color _textPrimaryDark = Color(0xFFFFFFFF);      // blanco
    static const Color _textSecondaryDark = Color(0xFFAAAAAA);    // gris claro
    static const Color _cardBackgroundDark = Color(0xFF1E1E1E);    // gris oscuro
    static const Color _alertDark = Color(0xFFFF4D4D);
    static const Color _warningDark = Color.fromARGB(255, 255, 166, 0);
    static const Color _successDark = Color(0xFF4CAF50);

    /// Getter helpers que devuelven el color según el mode
    static Color primary(BuildContext ctx) =>
        Theme.of(ctx).brightness == Brightness.dark
            ? _primaryDark
            : _primaryLight;

    static Color background(BuildContext ctx) =>
        Theme.of(ctx).brightness == Brightness.dark
            ? _backgroundDark
            : _backgroundLight;

    static Color textPrimary(BuildContext ctx) =>
        Theme.of(ctx).brightness == Brightness.dark
            ? _textPrimaryDark
            : _textPrimaryLight;

    static Color textSecondary(BuildContext ctx) =>
        Theme.of(ctx).brightness == Brightness.dark
            ? _textSecondaryDark
            : _textSecondaryLight;

    static Color cardBackground(BuildContext ctx) =>
        Theme.of(ctx).brightness == Brightness.dark
            ? _cardBackgroundDark
            : _cardBackgroundLight;

    static Color alert(BuildContext ctx) =>
        Theme.of(ctx).brightness == Brightness.dark
            ? _alertDark
            : _alertLight;

    static Color warning(BuildContext ctx) =>
        Theme.of(ctx).brightness == Brightness.dark
            ? _warningDark
            : _warningLight;
    
    static Color success(BuildContext ctx) =>
        Theme.of(ctx).brightness == Brightness.dark
            ? _successDark
            : _successLight;

    
}