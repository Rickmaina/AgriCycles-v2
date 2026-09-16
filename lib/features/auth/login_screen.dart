import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_routes.dart';
import '../../core/constants/enums.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/extensions.dart';
import '../transport/register_vehicle_screen.dart';
import 'controllers/auth_controller.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  UserRole? _loading;

  Future<void> _login(UserRole role) async {
    setState(() => _loading = role);
    final result =
        await ref.read(authControllerProvider).loginAsRole(role);
    if (!mounted) return;
    setState(() => _loading = null);

    result.when(
      success: (snap) {
        context.go(
          snap.needsOnboarding ? AppRoutes.onboarding : AppRoutes.home,
        );
      },
      failure: (f) => context.showSnack(f.message),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.agriculture,
                      color: Colors.white, size: 44),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'AgriCycles',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Recycle, trade, and value-add agricultural resources',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 40),
              const Text(
                'Continue as demo role',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              _RoleTile(
                icon: Icons.person,
                label: 'Farmer',
                busy: _loading == UserRole.farmer,
                onTap: () => _login(UserRole.farmer),
              ),
              _RoleTile(
                icon: Icons.business,
                label: 'Company',
                busy: _loading == UserRole.company,
                onTap: () => _login(UserRole.company),
              ),
              _RoleTile(
                icon: Icons.admin_panel_settings,
                label: 'Admin',
                busy: _loading == UserRole.admin,
                onTap: () => _login(UserRole.admin),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loading != null
                    ? null
                    : () => context.go(AppRoutes.register),
                child: const Text('Create a new account'),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const RegisterVehicleScreen(),
                  ),
                ),
                child: const Text(
                  'Register a transport vehicle',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool busy;
  final VoidCallback onTap;

  const _RoleTile({
    required this.icon,
    required this.label,
    required this.busy,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: busy ? null : onTap,
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(icon, color: AppColors.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                if (busy)
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  const Icon(Icons.chevron_right,
                      color: AppColors.textMuted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
