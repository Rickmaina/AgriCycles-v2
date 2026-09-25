import 'package:flutter/material.dart';

import '../../core/theme/role_theme.dart';

/// The "do this next" card. Used at the top of the farmer dashboard to
/// surface the single most important action right now (e.g. "2 vaccines
/// due today", "1 offer waiting on you").
///
/// Visually dominant — bigger than a normal card, with a strong icon,
/// prominent headline, and a single primary action button.
class HeroActionCard extends StatelessWidget {
  final IconData icon;
  final String headline;
  final String? subline;
  final String? actionLabel;
  final VoidCallback? onAction;
  final RoleTheme theme;
  final Color? overrideAccent;

  const HeroActionCard({
    super.key,
    required this.icon,
    required this.headline,
    this.subline,
    this.actionLabel,
    this.onAction,
    required this.theme,
    this.overrideAccent,
  });

  @override
  Widget build(BuildContext context) {
    final accent = overrideAccent ?? theme.accent;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accent.withValues(alpha: 0.14),
            accent.withValues(alpha: 0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(theme.cardRadius + 2),
        border: Border.all(color: accent.withValues(alpha: 0.30)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      headline,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: theme.textPrimary,
                        height: 1.2,
                      ),
                    ),
                    if (subline != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subline!,
                        style: TextStyle(
                          fontSize: 13,
                          color: theme.textSecondary,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onAction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: accent,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(theme.cardRadius - 2),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                child: Text(actionLabel!),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
