import 'package:flutter/material.dart';

import '../../core/constants/enums.dart';
import 'app_colors.dart';

/// Per-role visual language. Same design system, different feel.
/// Screens read `RoleTheme.of(user.role)` and use its tokens instead of
/// hardcoding colors, radii, or densities. This is what makes Farmer,
/// Company, and Admin feel like three products on one codebase.
class RoleTheme {
  final Color primary;
  final Color primaryMuted;
  final Color accent;
  final Color background;
  final Color surface;
  final Color border;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final double cardRadius;
  final double cardPadding;
  final double sectionSpacing;
  final bool denseLists;
  final AppBarStyle appBarStyle;

  const RoleTheme({
    required this.primary,
    required this.primaryMuted,
    required this.accent,
    required this.background,
    required this.surface,
    required this.border,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.cardRadius,
    required this.cardPadding,
    required this.sectionSpacing,
    required this.denseLists,
    required this.appBarStyle,
  });

  /// Farmer — warm, earthy, generous spacing. Feels like an app made
  /// for use in a field: big targets, quiet palette, no visual noise.
  static const RoleTheme farmer = RoleTheme(
    primary: Color(0xFF2E7D32),
    primaryMuted: Color(0xFFE8F1E9),
    accent: Color(0xFFF9A825),
    background: Color(0xFFF7F8F5),
    surface: Color(0xFFFFFFFF),
    border: Color(0xFFDDE3D8),
    textPrimary: Color(0xFF1B1F1A),
    textSecondary: Color(0xFF5A6157),
    textMuted: Color(0xFF8A9186),
    cardRadius: 16,
    cardPadding: 16,
    sectionSpacing: 20,
    denseLists: false,
    appBarStyle: AppBarStyle.friendly,
  );

  /// Company — cooler, more data-dense, procurement-cockpit feel.
  /// Tighter spacing so more KPIs fit on screen.
  static const RoleTheme company = RoleTheme(
    primary: Color(0xFF00695C),
    primaryMuted: Color(0xFFE0F2F1),
    accent: Color(0xFF00897B),
    background: Color(0xFFF4F7F7),
    surface: Color(0xFFFFFFFF),
    border: Color(0xFFD4DEDD),
    textPrimary: Color(0xFF0F1A19),
    textSecondary: Color(0xFF4A5B59),
    textMuted: Color(0xFF7A8A88),
    cardRadius: 10,
    cardPadding: 12,
    sectionSpacing: 14,
    denseLists: true,
    appBarStyle: AppBarStyle.utilitarian,
  );

  /// Admin — neutral slate, clinical, operationally urgent. Reads like
  /// a control tower: everything is a queue with depth and priority.
  static const RoleTheme admin = RoleTheme(
    primary: Color(0xFF37474F),
    primaryMuted: Color(0xFFECEFF1),
    accent: Color(0xFFEF6C00),
    background: Color(0xFFF2F4F5),
    surface: Color(0xFFFFFFFF),
    border: Color(0xFFD6DBDE),
    textPrimary: Color(0xFF1A1F22),
    textSecondary: Color(0xFF4A555A),
    textMuted: Color(0xFF7C868B),
    cardRadius: 8,
    cardPadding: 12,
    sectionSpacing: 12,
    denseLists: true,
    appBarStyle: AppBarStyle.console,
  );

  static RoleTheme of(UserRole role) {
    switch (role) {
      case UserRole.farmer:
        return farmer;
      case UserRole.company:
        return company;
      case UserRole.admin:
        return admin;
      case UserRole.vet:
        return farmer;
    }
  }

  /// Convenience: the AppBar color for this role.
  Color get appBarBackground {
    switch (appBarStyle) {
      case AppBarStyle.friendly:
        return surface;
      case AppBarStyle.utilitarian:
        return primary;
      case AppBarStyle.console:
        return primary;
    }
  }

  Color get appBarForeground {
    switch (appBarStyle) {
      case AppBarStyle.friendly:
        return textPrimary;
      case AppBarStyle.utilitarian:
      case AppBarStyle.console:
        return Colors.white;
    }
  }

  /// Dense-list row height for role.
  double get rowMinHeight => denseLists ? 56 : 72;

  /// Section header text style for role.
  TextStyle get sectionTitleStyle => TextStyle(
        fontSize: denseLists ? 13 : 15,
        fontWeight: FontWeight.w700,
        color: textPrimary,
        letterSpacing: denseLists ? 0.2 : 0,
      );
}

enum AppBarStyle { friendly, utilitarian, console }

/// Extension to keep call sites short.
extension RoleThemeX on UserRole {
  RoleTheme get theme => RoleTheme.of(this);
}

/// Bridge so screens can fall back to the default AppColors if needed.
extension RoleThemeColors on RoleTheme {
  Color get statePending => AppColors.statePending;
  Color get stateActive => AppColors.stateActive;
  Color get stateSecured => AppColors.stateSecured;
  Color get stateCompleted => AppColors.stateCompleted;
  Color get stateDisputed => AppColors.stateDisputed;
  Color get stateExpired => AppColors.stateExpired;
  Color get success => AppColors.success;
  Color get danger => AppColors.danger;
  Color get warning => AppColors.warning;
  Color get info => AppColors.info;
}
