import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_routes.dart';
import '../../core/theme/role_theme.dart';
import '../../data/models/geo_location.dart';
import '../../shared/widgets/farmer_action_button.dart';
import '../../shared/widgets/location_picker.dart';
import 'controllers/onboarding_controller.dart';

/// Screen 2 of onboarding: where and how big?
class FarmLocationScreen extends ConsumerStatefulWidget {
  const FarmLocationScreen({super.key});

  @override
  ConsumerState<FarmLocationScreen> createState() =>
      _FarmLocationScreenState();
}

class _FarmLocationScreenState extends ConsumerState<FarmLocationScreen> {
  LocationSelection? _location;
  String? _scale;

  static const _scales = [
    _ScaleOption(
      value: 'small',
      label: 'Small',
      subtitle: 'Under 2 acres',
    ),
    _ScaleOption(
      value: 'medium',
      label: 'Medium',
      subtitle: '2–10 acres',
    ),
    _ScaleOption(
      value: 'large',
      label: 'Big',
      subtitle: 'Over 10 acres',
    ),
  ];

  bool get _canContinue => _location != null && _scale != null;

  void _continue() {
    if (!_canContinue) return;

    final controller = ref.read(onboardingControllerProvider.notifier);
    controller.setLocation(
      GeoLocation(
        county: _location!.county,
        subCounty: _location!.subCounty,
        area: _location!.ward,
        source: LocationSource.selfReported,
      ),
    );
    controller.setFarmScale(_scale!);

    context.go(AppRoutes.onboardingComplete);
  }

  @override
  Widget build(BuildContext context) {
    const theme = RoleTheme.farmer;

    return Scaffold(
      backgroundColor: theme.background,
      appBar: AppBar(
        backgroundColor: theme.surface,
        foregroundColor: theme.textPrimary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(AppRoutes.onboarding),
        ),
        title: const Text('Where and how big?'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Where do you farm?',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: theme.textPrimary,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'We use this to match you with nearby buyers and sellers.',
                      style: TextStyle(
                        fontSize: 14,
                        color: theme.textSecondary,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 16),
                    LocationPicker(
                      initial: _location,
                      onChanged: (sel) => setState(() => _location = sel),
                    ),
                    const SizedBox(height: 28),
                    Text(
                      'How big is your farm?',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: theme.textPrimary,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Rough size is fine.',
                      style: TextStyle(
                        fontSize: 14,
                        color: theme.textSecondary,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 16),
                    for (final opt in _scales) ...[
                      _ScaleTile(
                        option: opt,
                        selected: _scale == opt.value,
                        onTap: () => setState(() => _scale = opt.value),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: FarmerActionButton(
                label: 'Continue',
                icon: Icons.arrow_forward,
                onPressed: _canContinue ? _continue : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScaleOption {
  final String value;
  final String label;
  final String subtitle;
  const _ScaleOption({
    required this.value,
    required this.label,
    required this.subtitle,
  });
}

class _ScaleTile extends StatelessWidget {
  final _ScaleOption option;
  final bool selected;
  final VoidCallback onTap;

  const _ScaleTile({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const theme = RoleTheme.farmer;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: selected ? theme.primaryMuted : theme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? theme.primary : theme.border,
            width: selected ? 2.5 : 1.5,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    option.label,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: theme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    option.subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: theme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (selected)
              Icon(Icons.check_circle, color: theme.primary, size: 26),
          ],
        ),
      ),
    );
  }
}
