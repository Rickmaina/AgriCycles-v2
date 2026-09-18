import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_routes.dart';
import '../../core/constants/enums.dart';
import '../../core/theme/app_colors.dart';
import '../auth/controllers/auth_controller.dart';

class GetStartedScreen extends ConsumerStatefulWidget {
  const GetStartedScreen({super.key});

  @override
  ConsumerState<GetStartedScreen> createState() => _GetStartedScreenState();
}

class _GetStartedScreenState extends ConsumerState<GetStartedScreen> {
  FarmerType? _selected;

  void _finish(FarmerType type) {
    ref.read(authControllerProvider).completeOnboarding(farmerType: type);
    context.go(AppRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Get started')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'What kind of farmer are you?',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              const Text(
                'Optional — helps match your resources with nearby buyers and sellers.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 24),
              _TypeCard(
                icon: Icons.grass,
                title: 'Plant / cash-crop farmer',
                subtitle: 'Maize, sugarcane, coffee, vegetables',
                selected: _selected == FarmerType.plant,
                onTap: () => setState(() => _selected = FarmerType.plant),
              ),
              const SizedBox(height: 12),
              _TypeCard(
                icon: Icons.pets,
                title: 'Animal farmer',
                subtitle: 'Cows, goats, sheep, chicken',
                selected: _selected == FarmerType.animal,
                onTap: () => setState(() => _selected = FarmerType.animal),
              ),
              const SizedBox(height: 12),
              _TypeCard(
                icon: Icons.eco,
                title: 'Both',
                subtitle: 'Crops and livestock',
                selected: _selected == FarmerType.both,
                onTap: () => setState(() => _selected = FarmerType.both),
              ),
              const SizedBox(height: 28),
              ElevatedButton(
                onPressed: _selected == null ? null : () => _finish(_selected!),
                child: const Text('Start trading'),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => _finish(FarmerType.both),
                child: const Text('Skip for now'),
              ),
              const SizedBox(height: 8),
              const Text(
                'You can change this later from your profile.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: AppColors.textMuted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TypeCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _TypeCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withValues(alpha: 0.08)
              : AppColors.surface,
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
            width: selected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: selected ? AppColors.primary : AppColors.textSecondary,
              size: 32,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 16)),
                  const SizedBox(height: 4),
                  Text(subtitle,
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 13)),
                ],
              ),
            ),
            if (selected)
              const Icon(Icons.check_circle, color: AppColors.primary),
          ],
        ),
      ),
    );
  }
}
