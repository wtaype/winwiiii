import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// 🎨 COLORES Y DISEÑO - TEMA VERDE v3 OPTIMIZADO _______
class AppCSS {
  // 🖼️ ASSETS _______
  static const String lgPath = 'assets/images/logo.png';
  static const String logoSmile = 'assets/images/smile.png';
  
  static Widget get logo => Image.asset(
    lgPath, width: 80, height: 80, fit: BoxFit.cover,
    errorBuilder: (_, __, ___) => const Icon(Icons.account_circle, size: 80, color: primary),
  );

  static Widget logoCirculo({double size = 80}) => Container(
    width: size, height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle, color: white,
      boxShadow: [BoxShadow(color: primary.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 3))],
    ),
    child: ClipOval(child: logo),
  );

  // 🎨 PRINCIPALES _______
  static const Color primary = Color(0xFF4CAF50);
  static const Color verdePrimario = primary; // Alias para compatibilidad
  static const Color secondary = Color(0xFF81C784);
  static const Color bgLight = Color(0xFFB9F6CA);
  static const Color verdeClaro = bgLight; // Alias para compatibilidad
  static const Color bgSoft = Color(0xFFE8F5E8);
  static const Color bgDark = Color(0xFF388E3C);
  static const Color white = Colors.white;
  static const Color black = Color(0xFF000000);
  static const Color gray = Color(0xFF9E9E9E);
  static const Color grayLight = Color(0xFFF5F5F5);
  static const Color grayDark = Color(0xFF424242);
  static const Color border = bgLight; // Reutiliza bgLight
  static const Color inputBg = Color(0xFFF5FFF6);
  static const Color clear = Colors.transparent;

  // 📝 TEXTOS _______
  static const Color text = black;
  static const Color text700 = Color(0xFF1A1A1A);
  static const Color text500 = Color(0xFF2E2E2E);
  static const Color text300 = Color(0xFF666666);
  static const Color textGreen = bgDark;

  // ✅ ESTADOS _______
  static const Color success = primary; // Reutiliza primary
  static const Color error = Color(0xFFE53935);
  static const Color warning = Color(0xFFFF9800);
  static const Color info = Color(0xFF2196F3);

  // 🧩 CATEGORÍAS bg1-bg6 _______
  static const Color bg1 = primary;
  static const Color bg2 = info;
  static const Color bg3 = Color(0xFF9C27B0);
  static const Color bg4 = Color(0xFFFF5722);
  static const Color bg5 = Color(0xFFFFB300);
  static const Color bg6 = Color(0xFF00BCD4);

  // 🌈 GRADIENTES _______
  static const LinearGradient gradGreen = LinearGradient(
    colors: [primary, secondary],
    begin: Alignment.topLeft, end: Alignment.bottomRight,
  );
  static const LinearGradient gradSoft = LinearGradient(
    colors: [bgLight, primary],
    begin: Alignment.topLeft, end: Alignment.bottomRight,
  );

  // 📐 ESPACIADOS Y RADIOS _______
  static const double sp8 = 8.0, sp16 = 16.0, sp24 = 24.0;
  static const double rad8 = 8.0, rad12 = 12.0, rad16 = 16.0, rad20 = 20.0;

  // ⏱️ TRANSICIONES _______
  static const Duration trans1 = Duration(milliseconds: 300);
  static const Duration trans2 = Duration(milliseconds: 600);
  static const Duration trans3 = Duration(seconds: 3);

  // 📱 PADDINGS _______
  static const padM = EdgeInsets.symmetric(vertical: 9, horizontal: 10);
  static const padL = EdgeInsets.symmetric(vertical: 15, horizontal: 20);

  // 📏 GAPS _______
  static const gapS = SizedBox(height: sp8);
  static const gapM = SizedBox(height: sp16);
  static const gapL = SizedBox(height: sp24);
  static const gapHS = SizedBox(width: sp8);
  static const gapHM = SizedBox(width: sp16);

  // 🪟 GLASS - Función unificada optimizada _______
  static BoxDecoration glass([double intensity = 0.5]) {
    final opcBorde = intensity * 0.8;
    final opcFondo = 0.5 + (intensity * 0.35);
    final blur = 12.0 + (intensity * 12);
    final radius = intensity < 0.4 ? rad20 : (intensity > 0.7 ? rad20 : rad16);
    
    return BoxDecoration(
      color: white.withValues(alpha: opcFondo),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: border.withValues(alpha: opcBorde), width: intensity > 0.6 ? 1.5 : 1),
      boxShadow: [BoxShadow(
        color: (intensity < 0.5 ? primary : black).withValues(alpha: 0.08),
        blurRadius: blur,
        offset: Offset(0, intensity * 8),
      )],
    );
  }
  
  // Atajos compatibilidad _______
  static BoxDecoration get glass300 => glass(0.3);
  static BoxDecoration get glass500 => glass(0.5);
  static BoxDecoration get glass700 => glass(0.7);

  // 🌫️ SOMBRAS _______
  static const shadow = [
    BoxShadow(color: Color(0x1A4CAF50), blurRadius: 15, offset: Offset(0, 5)),
  ];

  // 🔲 BORDES _______
  static final borderBox = BoxDecoration(
    color: inputBg,
    borderRadius: BorderRadius.circular(rad12),
    border: Border.all(color: border),
  );
}

// 🎭 ESTILOS v3 OPTIMIZADO _______
class AppStyle {
  static final _font = GoogleFonts.poppins().fontFamily;

  // 🎨 TEMA _______
  static final tema = ThemeData(
    scaffoldBackgroundColor: AppCSS.bgLight,
    primarySwatch: Colors.green,
    fontFamily: _font,
    appBarTheme: AppBarTheme(
      backgroundColor: AppCSS.primary,
      foregroundColor: AppCSS.white,
      elevation: 0,
      toolbarHeight: 45,
      titleTextStyle: _tx(16, FontWeight.w600, AppCSS.white),
      centerTitle: true,
      iconTheme: const IconThemeData(color: AppCSS.white, size: 22),
    ),
    textTheme: TextTheme(
      headlineLarge: h1, headlineMedium: h2, titleLarge: h3,
      bodyLarge: bd, bodyMedium: bdS,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppCSS.primary,
        foregroundColor: AppCSS.white,
        textStyle: _tx(16, FontWeight.w600, AppCSS.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppCSS.rad12)),
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Colors.white,
      selectedItemColor: AppCSS.primary,
      unselectedItemColor: AppCSS.gray,
      elevation: 10,
      type: BottomNavigationBarType.fixed,
    ),
    visualDensity: VisualDensity.adaptivePlatformDensity,
  );

  // 📝 TEXTOS _______
  static final h1 = _tx(32, FontWeight.w600, AppCSS.textGreen);
  static final h2 = _tx(24, FontWeight.w600, AppCSS.textGreen);
  static final h3 = _tx(18, FontWeight.w600, AppCSS.text700);
  static final bd = _tx(16, FontWeight.w500, AppCSS.text500);
  static final bdS = _tx(14, FontWeight.w500, AppCSS.text500);
  static final lbl = _tx(13, FontWeight.w500, AppCSS.text300);
  static final sm = _tx(11, FontWeight.w500, AppCSS.text300);
  static final btn = _tx(16, FontWeight.w600, AppCSS.white);

  static TextStyle _tx(double sz, FontWeight w, Color c) =>
      TextStyle(fontSize: sz, fontWeight: w, color: c, fontFamily: _font);
}

// 🎨 VALIDACIÓN OPTIMIZADA _______
class Vd {
  static const err = _VdColors(
    borde: AppCSS.error,
    texto: Color(0xFFD32F2F),
    fondo: Color(0xFFFFEBEE),
    icono: AppCSS.error,
  );
  static const ok = _VdColors(
    borde: AppCSS.primary,
    texto: Color(0xFF2E7D32),
    fondo: AppCSS.bgSoft,
    icono: AppCSS.primary,
  );
}

class _VdColors {
  final Color borde, texto, fondo, icono;
  const _VdColors({required this.borde, required this.texto, required this.fondo, required this.icono});
}

// Retrocompatibilidad _______
class VdError { 
  static Color get borde => Vd.err.borde;
  static Color get texto => Vd.err.texto;
  static Color get fondo => Vd.err.fondo;
  static Color get icono => Vd.err.icono;
}
class VdGreen {
  static Color get borde => Vd.ok.borde;
  static Color get texto => Vd.ok.texto;
  static Color get fondo => Vd.ok.fondo;
  static Color get icono => Vd.ok.icono;
}
