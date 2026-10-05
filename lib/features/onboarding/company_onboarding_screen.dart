import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_routes.dart';
import '../../core/theme/role_theme.dart';
import '../../data/models/geo_location.dart';
import '../../shared/widgets/farmer_action_button.dart';
import '../../shared/widgets/location_picker.dart';
import '../auth/controllers/auth_controller.dart';

/// Company onboarding. Single screen: business identity, type,
/// base location, and contact person.
class CompanyOnboardingScreen extends ConsumerStatefulWidget {
  const CompanyOnboardingScreen({super.key});

  @override
  ConsumerState<CompanyOnboardingScreen> createState() =>
      _CompanyOnboardingScreenState();
}

class _CompanyOnboardingScreenState
    extends ConsumerState<CompanyOnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _businessName = TextEditingController();
  final _contactName = TextEditingController();
  final _descriptor = TextEditingController();

  String _businessType = 'Aggregator';
  LocationSelection? _location;
  String? _locationError;
  bool _submitting = false;

  static const _types = [
    'Aggregator',
    'Processor',
    'Exporter',
    'Retailer',
    'Other',
  ];

  @override
  void dispose() {
    _businessName.dispose();
    _contactName.dispose();
    _descriptor.dispose();
    super.dispose();
  }

  void _submit() {
    final formOk = _formKey.currentState!.validate();
    final locationOk = _location != null &&
        _location!.county.isNotEmpty &&
        _location!.subCounty.isNotEmpty;
    if (!formOk || !locationOk) {
      if (!locationOk) {
        setState(() => _locationError = 'Pick your operating base.');
      }
      return;
    }

    setState(() => _submitting = true);

    final controller = ref.read(authControllerProvider);
    controller.completeCompanyOnboarding(
      businessName: _businessName.text.trim(),
      businessType: _businessType,
      contactName: _contactName.text.trim(),
      descriptor: _descriptor.text.trim().isEmpty
          ? null
          : _descriptor.text.trim(),
      base: GeoLocation(
        county: _location!.county,
        subCounty: _location!.subCounty,
        area: _location!.ward,
        source: LocationSource.selfReported,
      ),
    );

    if (!mounted) return;
    context.go(AppRoutes.companyPending);
  }

  @override
  Widget build(BuildContext context) {
    const theme = RoleTheme.company;

    return Scaffold(
      backgroundColor: theme.background,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 32, 20, 20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Tell us about your business',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                          color: theme.textPrimary,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'This helps farmers and buyers trust who they are dealing with.',
                        style: TextStyle(
                          fontSize: 14,
                          color: theme.textSecondary,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 28),
                      _field(
                        theme: theme,
                        controller: _businessName,
                        label: 'Business name',
                        hint: 'e.g. Kenya Sugarcane Co.',
                        validator: (v) =>
                            (v == null || v.trim().isEmpty)
                                ? 'Required'
                                : null,
                      ),
                      const SizedBox(height: 14),
                      _typePicker(theme),
                      const SizedBox(height: 14),
                      _field(
                        theme: theme,
                        controller: _contactName,
                        label: 'Contact person',
                        hint: 'Full name',
                        validator: (v) =>
                            (v == null || v.trim().isEmpty)
                                ? 'Required'
                                : null,
                      ),
                      const SizedBox(height: 14),
                      _field(
                        theme: theme,
                        controller: _descriptor,
                        label: 'What do you buy or sell?',
                        hint: 'e.g. Feed operations, biomass',
                        required: false,
                        validator: (_) => null,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Operating base',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: theme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Used to match you with nearby supply.',
                        style: TextStyle(
                          fontSize: 13,
                          color: theme.textMuted,
                        ),
                      ),
                      const SizedBox(height: 14),
                      LocationPicker(
                        initial: _location,
                        onChanged: (sel) {
                          setState(() {
                            _location = sel;
                            _locationError = null;
                          });
                        },
                      ),
                      if (_locationError != null) ...[
                        const SizedBox(height: 10),
                        Text(
                          _locationError!,
                          style: TextStyle(
                            color: theme.danger,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: FarmerActionButton(
                label: 'Continue',
                icon: Icons.arrow_forward,
                onPressed: _submitting ? null : _submit,
                loading: _submitting,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field({
    required RoleTheme theme,
    required TextEditingController controller,
    required String label,
    String? hint,
    bool required = true,
    required String? Function(String?) validator,
  }) {
    return TextFormField(
      controller: controller,
      textCapitalization: TextCapitalization.words,
      decoration: InputDecoration(
        labelText: required ? label : '$label (optional)',
        hintText: hint,
        filled: true,
        fillColor: theme.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: theme.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: theme.border),
        ),
      ),
      validator: validator,
    );
  }

  Widget _typePicker(RoleTheme theme) {
    return DropdownButtonFormField<String>(
      initialValue: _businessType,
      decoration: InputDecoration(
        labelText: 'Business type',
        filled: true,
        fillColor: theme.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: theme.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: theme.border),
        ),
      ),
      items: _types
          .map((t) => DropdownMenuItem(value: t, child: Text(t)))
          .toList(),
      onChanged: (v) => setState(() => _businessType = v!),
    );
  }
}
