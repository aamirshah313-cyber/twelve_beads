/// Shared spacing scale, per the "share design tokens" requirement in
/// 03-architecture-and-data.md. Keep every screen's padding/gaps drawn from
/// this scale instead of ad hoc literals.
class AppSpacing {
  const AppSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;

  /// Minimum accessible touch target size (dp), per 04-ui-ux-and-visual-system.md.
  static const double minTouchTarget = 48;
}
