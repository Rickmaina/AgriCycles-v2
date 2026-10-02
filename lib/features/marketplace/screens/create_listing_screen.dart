import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_routes.dart';
import '../../../core/theme/role_theme.dart';
import '../../../core/utils/extensions.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/services/seed/seed_listings.dart';
import '../../../domain/validators.dart';
import '../../../shared/widgets/farmer_action_button.dart';
import '../../../shared/widgets/location_picker.dart';
import '../controllers/marketplace_controller.dart';

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

  String _selectedResource = SeedListings.resourceCatalogue.first;
  String _quality = 'Standard';
  String _category = 'Crop residue';
  String _unit = 'tonnes';
  LocationSelection? _location;
  String? _locationError;
  bool _submitting = false;

  static const _units = ['kg', 'tonnes', 'bags', 'litres'];

  bool get _isOtherResource => _selectedResource == 'Other agricultural waste';

  @override
  void dispose() {
    _resourceType.dispose();
    _quantity.dispose();
    _price.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final resourceName =
        _isOtherResource ? _resourceType.text.trim() : _selectedResource.trim();

    final formOk = _formKey.currentState!.validate();
    final locationOk = _location != null &&
        _location!.county.isNotEmpty &&
        _location!.subCounty.isNotEmpty;
    if (!formOk || !locationOk || resourceName.isEmpty) {
      if (resourceName.isEmpty) {
        _formKey.currentState?.validate();
      }
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
          resourceType: resourceName,
          category: _category,
          quantity: double.parse(_quantity.text.trim()),
          unit: _unit,
          pricePerUnit: double.parse(_price.text.trim()),
          quality: _quality,
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
        title: const Text('What are you selling?'),
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
                      Text(
                        'Tell buyers what you have to sell.',
                        style: TextStyle(
                          fontSize: 14,
                          color: theme.textMuted,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'What are you selling?',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: theme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _resourcePicker(theme),
                      if (_isOtherResource) ...[
                        const SizedBox(height: 14),
                        _field(
                          theme: theme,
                          controller: _resourceType,
                          label: 'Describe the material',
                          hint: 'e.g. Banana stems',
                          keyboard: TextInputType.text,
                          validator: (v) => Validators.requiredText(
                            v,
                            label: 'Material',
                          ),
                        ),
                      ],
                      const SizedBox(height: 14),
                      _qualityPicker(theme),
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
                              label: 'Quantity',
                              hint: 'e.g. 20',
                              keyboard: const TextInputType.numberWithOptions(
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
                        hint: 'e.g. 4500',
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
                      const SizedBox(height: 20),
                      _reviewCard(theme),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: FarmerActionButton(
                label: 'Submit listing',
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

  Widget _resourcePicker(RoleTheme theme) {
    return DropdownButtonFormField<String>(
      initialValue: SeedListings.resourceCatalogue.contains(_selectedResource)
          ? _selectedResource
          : SeedListings.resourceCatalogue.first,
      decoration: InputDecoration(
        labelText: 'Select a resource',
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
      items: SeedListings.resourceCatalogue
          .map((resource) => DropdownMenuItem(
                value: resource,
                child: Text(resource),
              ))
          .toList(),
      onChanged: (value) {
        if (value == null) return;
        setState(() {
          _selectedResource = value;
          if (!_isOtherResource) {
            _resourceType.clear();
          }
        });
      },
    );
  }

  Widget _reviewCard(RoleTheme theme) {
    final resource =
        _isOtherResource ? _resourceType.text.trim() : _selectedResource.trim();
    final quantity = _quantity.text.trim();
    final price = _price.text.trim();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Review your listing',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: theme.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          _reviewRow('Resource', resource.isEmpty ? 'Not added yet' : resource),
          _reviewRow('Quantity',
              quantity.isEmpty ? 'Not added yet' : '$quantity $_unit'),
          _reviewRow('Quality', _quality),
          _reviewRow(
              'Price', price.isEmpty ? 'Not added yet' : 'KES $price / $_unit'),
          _reviewRow(
            'Location',
            _location == null
                ? 'Pick a location'
                : '${_location!.county}, ${_location!.subCounty}',
          ),
        ],
      ),
    );
  }

  Widget _reviewRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.black54,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
        ],
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

  Widget _qualityPicker(RoleTheme theme) {
    const qualities = ['Standard', 'Dry', 'Fresh', 'Premium', 'Mixed'];
    return DropdownButtonFormField<String>(
      initialValue: qualities.contains(_quality) ? _quality : 'Standard',
      decoration: InputDecoration(
        labelText: 'Quality',
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
      items: qualities
          .map((quality) =>
              DropdownMenuItem(value: quality, child: Text(quality)))
          .toList(),
      onChanged: (value) => setState(() => _quality = value ?? 'Standard'),
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
