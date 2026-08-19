import 'package:flutter/material.dart';

/// A warm, tabletop-inspired seed color (deep amber wood tone), per the
/// "sophisticated, warm tabletop experience" direction in
/// 04-ui-ux-and-visual-system.md. Later phases may refine this further once
/// the procedural board painter exists; Phase 1 establishes one consistent,
/// documented Material 3 seed rather than per-screen colors.
const _seedColor = Color(0xFFB5651D);

/// The bundled Urdu-capable font family (Noto Nastaliq Urdu, OFL-licensed —
/// see assets/fonts/OFL.txt). Applied only for the Urdu locale so Latin text
/// keeps the platform's default Material typeface.
const notoNastaliqUrduFontFamily = 'NotoNastaliqUrdu';

ThemeData buildAppTheme({
  required Brightness brightness,
  required bool highContrast,
  required String languageCode,
}) {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: _seedColor,
    brightness: brightness,
    // High contrast increases perceived contrast primarily via component
    // theming (below); the seed keeps hue continuity between modes.
    contrastLevel: highContrast ? 1.0 : 0.0,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    fontFamily: languageCode == 'ur' ? notoNastaliqUrduFontFamily : null,
    visualDensity: VisualDensity.adaptivePlatformDensity,
  );
}
