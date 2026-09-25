import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_routes.dart';
import '../../core/theme/role_theme.dart';
import '../../shared/widgets/farmer_action_button.dart';
import 'controllers/onboarding_controller.dart';

/// Screen 3 of onboarding: confirmation and handoff.
///
/// Shows a summary, previews the three main actions, then commits the
/// onboarding data and navigates home.
class OnboardingCompleteScreen extends ConsumerStatefulWidget {
  const OnboardingCompleteScreen({super.key});

  @override
  ConsumerState<OnboardingCompleteScreen> createState() =>
      _OnboardingCompleteScreenState();
}

class _OnboardingCompleteScreenState
    extends ConsumerState<OnboardingCompleteScreen> {
  bool _committing = false;

  void _start() {
    if (_committing) return;
    setState(() => _committing = true);

    ref.read(onboardingControllerProvider.notifier).commit();

    // Small delay so the loading state is visible and the state
    // change propagates before we navigate.
    Future.delayed(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      context.go(AppRoutes.home);
    });
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
                padding: const EdgeInsets.fromLTRB(20, 40, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 88,
                        height: 88,
                        decoration: BoxDecoration(
                          color: theme.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 52,
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    Text(
                      "You're ready",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: theme.textPrimary,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Here is what you can do now.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        color: theme.textSecondary,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 32),
                    const _PreviewTile(
                      icon: Icons.sell_outlined,
                      title: 'Sell what you have',
                      subtitle: 'List crop waste, manure, feed',
                      theme: RoleTheme.farmer,
                    ),
                    const SizedBox(height: 12),
                    const _PreviewTile(
                      icon: Icons.shopping_basket_outlined,
                      title: 'Buy from other farmers',
                      subtitle: 'Browse listings near you',
                      theme: RoleTheme.farmer,
                    ),
                    const SizedBox(height: 12),
                    const _PreviewTile(
                      icon: Icons.list_alt_outlined,
                      title: 'Track your deals',
                      subtitle: 'See offers, orders, and pickups',
                      theme: RoleTheme.farmer,
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: FarmerActionButton(
                label: 'Start',
                icon: Icons.arrow_forward,
                onPressed: _committing ? null : _start,
                loading: _committing,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PreviewTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final RoleTheme theme;

  const _PreviewTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.border, width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: theme.primaryMuted,
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Icon(icon, color: theme.primary, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: theme.textPrimary,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 3),
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
        ],
      ),
    );
  }
}
