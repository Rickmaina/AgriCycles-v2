import 'package:flutter/material.dart';

import '../../core/theme/role_theme.dart';

/// Large primary action button for farmer-facing screens.
///
/// Farmer buttons are intentionally larger than the app-wide 48px
/// accessibility baseline: farmers often tap in field conditions with
/// dirty hands or gloves, and the larger surface reduces mis-taps.
class FarmerActionButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool loading;
  final FarmerButtonVariant variant;
  final bool fullWidth;

  const FarmerActionButton({
    super.key,
    required this.label,
    this.icon,
    required this.onPressed,
    this.loading = false,
    this.variant = FarmerButtonVariant.primary,
    this.fullWidth = true,
  });

  static const double _height = 64;
  static const double _radius = 16;
  static const double _fontSize = 17;

  @override
  Widget build(BuildContext context) {
    const theme = RoleTheme.farmer;
    final disabled = loading || onPressed == null;

    final Widget child = loading
        ? SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: variant == FarmerButtonVariant.primary
                  ? Colors.white
                  : theme.primary,
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 24),
                const SizedBox(width: 12),
              ],
              Flexible(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: _fontSize,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ],
          );

    final button = variant == FarmerButtonVariant.primary
        ? ElevatedButton(
            onPressed: disabled ? null : onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.primary,
              foregroundColor: Colors.white,
              disabledBackgroundColor:
                  theme.primary.withValues(alpha: 0.4),
              disabledForegroundColor:
                  Colors.white.withValues(alpha: 0.7),
              elevation: 0,
              minimumSize: const Size.fromHeight(_height),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(_radius),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24),
            ),
            child: child,
          )
        : OutlinedButton(
            onPressed: disabled ? null : onPressed,
            style: OutlinedButton.styleFrom(
              foregroundColor: theme.primary,
              disabledForegroundColor:
                  theme.primary.withValues(alpha: 0.4),
              side: BorderSide(color: theme.primary, width: 2),
              minimumSize: const Size.fromHeight(_height),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(_radius),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24),
            ),
            child: child,
          );

    return fullWidth ? SizedBox(width: double.infinity, child: button) : button;
  }
}

enum FarmerButtonVariant { primary, secondary }
