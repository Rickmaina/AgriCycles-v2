import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/extensions.dart';
import '../../domain/validators.dart';
import '../../shared/widgets/location_picker.dart';
import 'controllers/auth_controller.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();

  LocationSelection? _location;
  String? _locationError;
  bool _loading = false;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final formOk = _formKey.currentState!.validate();
    final locationOk = _location != null &&
        _location!.county.isNotEmpty &&
        _location!.subCounty.isNotEmpty;
    if (!formOk || !locationOk) {
      if (!locationOk) {
        setState(() => _locationError =
            'Please select your county and sub-county.');
      }
      return;
    }

    setState(() {
      _loading = true;
      _locationError = null;
    });

    final result = await ref.read(authControllerProvider).registerFarmer(
          name: _name.text.trim(),
          phone: _phone.text.trim(),
          email: _email.text.trim().isEmpty ? null : _email.text.trim(),
          county: _location!.county,
          subCounty: _location!.subCounty,
          area: _location!.ward,
        );

    if (!mounted) return;
    setState(() => _loading = false);

    result.when(
      success: (_) => context.go(AppRoutes.onboarding),
      failure: (f) => context.showSnack(f.message),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create account')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Basic details',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _name,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(labelText: 'Full name'),
                  validator: (v) =>
                      Validators.requiredText(v, label: 'Name'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                  decoration:
                      const InputDecoration(labelText: 'Phone number'),
                  validator: Validators.phone,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  decoration:
                      const InputDecoration(labelText: 'Email (optional)'),
                  validator: Validators.email,
                ),
                const SizedBox(height: 24),
                const Text(
                  'Location',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                ),
                const SizedBox(height: 6),
                const Text(
                  'We use this to match you with nearby buyers and sellers. '
                  'Only your broad area is ever shown publicly.',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 14),
                LocationPicker(
                  initial: _location,
                  onChanged: (sel) => setState(() {
                    _location = sel;
                    _locationError = null;
                  }),
                  onValidationError: (msg) =>
                      setState(() => _locationError = msg),
                ),
                if (_locationError != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    _locationError!,
                    style: const TextStyle(
                      color: AppColors.danger,
                      fontSize: 12,
                    ),
                  ),
                ],
                const SizedBox(height: 28),
                ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  child: _loading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Continue'),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => context.go(AppRoutes.login),
                  child:
                      const Text('Already have an account? Sign in'),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Contact privacy: your phone and exact address are never shown publicly.',
                  textAlign: TextAlign.center,
                  style:
                      TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
