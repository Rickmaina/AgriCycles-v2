import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_routes.dart';
import '../../core/theme/role_theme.dart';
import '../../core/utils/extensions.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/seed/seed_listings.dart';
import '../../domain/validators.dart';
import '../../shared/widgets/farmer_action_button.dart';
import '../../shared/widgets/location_picker.dart';
import 'controllers/marketplace_controller.dart';

/// Farmer listing creation. One screen, minimal fields, submit for
/// admin review.
class CreateListingScreen extends ConsumerStatefulWidget {
  const CreateListingScreen({super.key});

  @override
  ConsumerState<CreateListingScreen> createState() =>
      _CreateListingScreenState();
}

class _CreateListingScreenState extends ConsumerState<CreateListingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _resourceType = TextEditingController();
  final _quantity = TextEditingController();
  final _price = TextEditingController();

  String _category = 'Crop residue';
  String _unit = 'tonnes';
  LocationSelection? _location;
  String? _locationError;
  bool _submitting = false;

  static const _units = ['kg', 'tonnes', 'bags', 'litres'];

  @override
  void dispose() {
    _resourceType.dispose();
    _quantity.dispose();
    _price.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final formOk = _formKey.currentState!.validate();
    final locationOk = _location != null &&
        _location!.county.isNotEmpty &&
        _location!.subCounty.isNotEmpty;
    if (!formOk || !locationOk) {
      if (!locationOk) {
        setState(() => _locationError = 'Pick where buyers can collect.');
      }
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Send for checking?'),
        content: const Text(
          'Your listing will be reviewed before it appears to buyers.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Send'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final user = ref.read(authProvider);
    if (user == null) return;

    setState(() => _submitting = true);

    ref.read(marketplaceControllerProvider).addListing(
          sellerId: user.id,
          sellerName: user.name,
          resourceType: _resourceType.text.trim(),
          category: _category,
          quantity: double.parse(_quantity.text.trim()),
          unit: _unit,
          pricePerUnit: double.parse(_price.text.trim()),
          county: _location!.county,
          subCounty: _location!.subCounty,
          area: _location!.ward,
          sellerVerification: user.verificationStatus,
        );

    if (!mounted) return;
    context.showSnack('Sent for checking');
    context.go(AppRoutes.home);
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
          onPressed: () => context.pop(),
        ),
        title: const Text('Sell something'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _field(
                        theme: theme,
                        controller: _resourceType,
                        label: 'What are you selling?',
                        hint: 'e.g. Maize stalks',
                        keyboard: TextInputType.text,
                        validator: (v) => Validators.requiredText(
                          v,
                          label: 'Resource name',
                        ),
                      ),
                      const SizedBox(height: 14),
                      _categoryPicker(theme),
                      const SizedBox(height: 14),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 3,
                            child: _field(
                              theme: theme,
                              controller: _quantity,
                              label: 'How much?',
                              keyboard:
                                  const TextInputType.numberWithOptions(
                                      decimal: true),
                              validator: (v) => Validators.positiveNumber(
                                v,
                                label: 'Quantity',
                                max: 100000,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            flex: 2,
                            child: _unitPicker(theme),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      _field(
                        theme: theme,
                        controller: _price,
                        label: 'Price per $_unit (KES)',
                        keyboard: const TextInputType.numberWithOptions(
                            decimal: true),
                        validator: (v) => Validators.positiveNumber(
                          v,
                          label: 'Price',
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Where can buyers collect it?',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: theme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Only the broad area is shown to buyers.',
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
                label: 'Send for checking',
                icon: Icons.check,
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
    required TextInputType keyboard,
    required String? Function(String?) validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboard,
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
      ],
      decoration: InputDecoration(
        labelText: label,
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

  Widget _categoryPicker(RoleTheme theme) {
    return DropdownButtonFormField<String>(
      initialValue: _category,
      decoration: InputDecoration(
        labelText: 'Category',
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
      items: SeedListings.categories
          .where((c) => c != 'All')
          .map((c) => DropdownMenuItem(value: c, child: Text(c)))
          .toList(),
      onChanged: (v) => setState(() => _category = v!),
    );
  }

  Widget _unitPicker(RoleTheme theme) {
    return DropdownButtonFormField<String>(
      initialValue: _unit,
      decoration: InputDecoration(
        labelText: 'Unit',
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
      items: _units
          .map((u) => DropdownMenuItem(value: u, child: Text(u)))
          .toList(),
      onChanged: (v) => setState(() => _unit = v!),
    );
  }
}
