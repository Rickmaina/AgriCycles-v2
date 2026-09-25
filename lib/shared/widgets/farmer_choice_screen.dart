import 'package:flutter/material.dart';

import '../../core/theme/role_theme.dart';
import 'farmer_tile.dart';

/// Reusable two-to-three-choice screen for farmer flows.
///
/// Use this when a farmer needs to pick one of two or three options.
/// Not for lists — for decisions. The whole screen has one job: help
/// the farmer choose without reading anything complicated.
class FarmerChoiceScreen extends StatelessWidget {
  final String title;
  final String? header;
  final List<FarmerChoice> choices;

  const FarmerChoiceScreen({
    super.key,
    required this.title,
    this.header,
    required this.choices,
  });

  @override
  Widget build(BuildContext context) {
    const theme = RoleTheme.farmer;

    return Scaffold(
      backgroundColor: theme.background,
      appBar: AppBar(
        title: Text(title),
        backgroundColor: theme.surface,
        foregroundColor: theme.textPrimary,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (header != null) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 8, 4, 16),
                  child: Text(
                    header!,
                    style: TextStyle(
                      fontSize: 15,
                      color: theme.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
              for (var i = 0; i < choices.length; i++) ...[
                FarmerTile(
                  icon: choices[i].icon,
                  title: choices[i].title,
                  subtitle: choices[i].subtitle,
                  badge: choices[i].badge,
                  iconBackground: choices[i].iconBackground,
                  onTap: choices[i].onTap,
                ),
                if (i < choices.length - 1) const SizedBox(height: 16),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// A single choice within a [FarmerChoiceScreen].
class FarmerChoice {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? badge;
  final Color? iconBackground;
  final VoidCallback onTap;

  const FarmerChoice({
    required this.icon,
    required this.title,
    this.subtitle,
    this.badge,
    this.iconBackground,
    required this.onTap,
  });
}
