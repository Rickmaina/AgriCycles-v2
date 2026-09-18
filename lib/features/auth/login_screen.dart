import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_routes.dart';
import '../../core/constants/enums.dart';
import '../../core/theme/role_theme.dart';
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
  UserRole? _preview;

  RoleTheme get _previewTheme =>
      _preview == null ? RoleTheme.farmer : RoleTheme.of(_preview!);

  Future<void> _login(UserRole role) async {
    setState(() {
      _loading = role;
      _preview = role;
    });
    final result = await ref.read(authControllerProvider).loginAsRole(role);
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
    final theme = _previewTheme;

    return Scaffold(
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        color: theme.background,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 32),
                Center(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      color: theme.primary,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: const Icon(Icons.agriculture,
                        color: Colors.white, size: 42),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'AgriCycles',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: theme.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Recycle, trade, and value-add agricultural resources',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: theme.textSecondary,
                  ),
                ),
                const SizedBox(height: 36),
                Text(
                  'Choose your role',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: theme.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                _RolePreviewTile(
                  role: UserRole.farmer,
                  icon: Icons.person_outline,
                  title: 'Farmer',
                  subtitle: 'Sell resources, buy inputs, join community orders',
                  busy: _loading == UserRole.farmer,
                  theme: theme,
                  onTap: () => _login(UserRole.farmer),
                ),
                const SizedBox(height: 10),
                _RolePreviewTile(
                  role: UserRole.company,
                  icon: Icons.business_outlined,
                  title: 'Company',
                  subtitle: 'Procure at scale, manage pickup routes',
                  busy: _loading == UserRole.company,
                  theme: theme,
                  onTap: () => _login(UserRole.company),
                ),
                const SizedBox(height: 10),
                _RolePreviewTile(
                  role: UserRole.admin,
                  icon: Icons.shield_outlined,
                  title: 'Admin',
                  subtitle:
                      'Verify users, coordinate logistics, resolve disputes',
                  busy: _loading == UserRole.admin,
                  theme: theme,
                  onTap: () => _login(UserRole.admin),
                ),
                const SizedBox(height: 28),
                OutlinedButton(
                  onPressed: _loading != null
                      ? null
                      : () => context.go(AppRoutes.register),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: theme.primary,
                    side: BorderSide(color: theme.primary),
                  ),
                  child: const Text('Create a new account'),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const RegisterVehicleScreen(),
                    ),
                  ),
                  child: Text(
                    'Register a transport vehicle',
                    style: TextStyle(color: theme.textSecondary),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Demo build — data is local and resets on reload.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    color: theme.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RolePreviewTile extends StatelessWidget {
  final UserRole role;
  final IconData icon;
  final String title;
  final String subtitle;
  final bool busy;
  final RoleTheme theme;
  final VoidCallback onTap;

  const _RolePreviewTile({
    required this.role,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.busy,
    required this.theme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final roleTheme = RoleTheme.of(role);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: theme == roleTheme ? theme.primary : theme.border,
          width: theme == roleTheme ? 2 : 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: busy ? null : onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: roleTheme.primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: theme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.textSecondary,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                if (busy)
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(roleTheme.primary),
                    ),
                  )
                else
                  Icon(Icons.arrow_forward, size: 18, color: theme.textMuted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
