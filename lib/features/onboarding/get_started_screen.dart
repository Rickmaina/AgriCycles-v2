import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_routes.dart';
import '../../core/constants/enums.dart';
import '../../core/theme/role_theme.dart';
import '../../shared/widgets/farmer_action_button.dart';
import 'controllers/onboarding_controller.dart';

/// Screen 1 of onboarding: what kind of farmer are you?
///
/// Fires on first login, before the farmer can reach home. One choice,
/// three big options, one continue button.
class GetStartedScreen extends ConsumerStatefulWidget {
  const GetStartedScreen({super.key});

  @override
  ConsumerState<GetStartedScreen> createState() => _GetStartedScreenState();
}

class _GetStartedScreenState extends ConsumerState<GetStartedScreen> {
  FarmerType? _selected;

  void _continue() {
    if (_selected == null) return;
    ref.read(onboardingControllerProvider.notifier).setFarmerType(_selected!);
    context.go(AppRoutes.onboardingLocation);
  }

  @override
  Widget build(BuildContext context) {
    const theme = RoleTheme.farmer;

    return Scaffold(
      backgroundColor: theme.background,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 32, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'What do you farm?',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: theme.textPrimary,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'This helps us match you with the right buyers and sellers.',
                      style: TextStyle(
                        fontSize: 15,
                        color: theme.textSecondary,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 28),
                    _SelectableTile(
                      icon: Icons.grass,
                      title: 'Crops',
                      subtitle: 'Maize, sugarcane, coffee',
                      selected: _selected == FarmerType.plant,
                      onTap: () =>
                          setState(() => _selected = FarmerType.plant),
                    ),
                    const SizedBox(height: 14),
                    _SelectableTile(
                      icon: Icons.pets,
                      title: 'Animals',
                      subtitle: 'Cows, goats, sheep, chicken',
                      selected: _selected == FarmerType.animal,
                      onTap: () =>
                          setState(() => _selected = FarmerType.animal),
                    ),
                    const SizedBox(height: 14),
                    _SelectableTile(
                      icon: Icons.eco,
                      title: 'Both',
                      subtitle: 'Crops and animals',
                      selected: _selected == FarmerType.both,
                      onTap: () =>
                          setState(() => _selected = FarmerType.both),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: FarmerActionButton(
                label: 'Continue',
                icon: Icons.arrow_forward,
                onPressed: _selected == null ? null : _continue,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SelectableTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _SelectableTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const theme = RoleTheme.farmer;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: selected
              ? theme.primaryMuted
              : theme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? theme.primary : theme.border,
            width: selected ? 2.5 : 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: selected ? theme.primary : theme.primaryMuted,
                borderRadius: BorderRadius.circular(14),
              ),
              alignment: Alignment.center,
              child: Icon(
                icon,
                size: 28,
                color: selected ? Colors.white : theme.primary,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: theme.textPrimary,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: theme.textSecondary,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            if (selected)
              Icon(Icons.check_circle, color: theme.primary, size: 28),
          ],
        ),
      ),
    );
  }
}
