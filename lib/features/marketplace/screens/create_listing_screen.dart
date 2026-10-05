import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_routes.dart';
import '../../../core/theme/role_theme.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/services/seed/seed_data.dart';
import '../../../data/services/seed/seed_listings.dart';
import '../../../shared/widgets/farmer_action_button.dart';
import '../../../shared/widgets/location_picker.dart';
import '../controllers/marketplace_controller.dart';
import 'listing_submitted_screen.dart';

/// Farmer listing creation.
///
/// Single scrollable screen, four sections:
///   1. What    — resource name (typeable + chips), category, description
///   2. How much & price
///   3. Where   — pre-filled from registered location when available
///   4. Quality — optional
///
/// Standard prices from [SeedPrices] auto-fill and lock the price field.
/// Submit → ListingSubmittedScreen.
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
  final _description = TextEditingController();

  String? _selectedChip;
  String _category = 'Crop residue';
  String _quality = 'Standard';
  String _unit = 'kg';
  LocationSelection? _location;
  bool _useRegistered = true;
  String? _locationError;
  bool _submitting = false;

  static const _units = [
    'kg',
    'tonnes',
    'bags',
    'litres',
    'trucks',
    'pickups',
  ];

  // Hard-coded conversions for local units. Admin will configure later.
  static const double _kgPerTruck = 10000;
  static const double _kgPerPickup = 3000;
  static const double _kgPerBag = 50;
  static const double _kgPerTonne = 1000;
  static const double _kgPerLitre = 1;

  @override
  void initState() {
    super.initState();
    _resourceType.addListener(_onResourceChanged);
    _quantity.addListener(_rebuild);
    _price.addListener(_rebuild);
    _prefillFromRegistered();
  }

  void _rebuild() => setState(() {});

  void _onResourceChanged() {
    setState(() {
      _selectedChip = null;
      final match =
          SeedListings.categoryByResource[_resourceType.text.trim()];
      if (match != null) _category = match;
      _maybePrefillPrice();
    });
  }

  void _prefillFromRegistered() {
    final user = ref.read(authProvider);
    if (user == null) return;
    if ((user.county ?? '').isEmpty || (user.subCounty ?? '').isEmpty) {
      _useRegistered = false;
      return;
    }
    _location = LocationSelection(
      county: user.county!,
      subCounty: user.subCounty!,
      ward: user.area ?? '',
    );
  }

  /// If admin has set a standard price for the current resource,
  /// pre-fill the price field and mark it read-only.
  void _maybePrefillPrice() {
    final resource = _effectiveResourceName();
    if (resource.isEmpty) return;
    final standard = SeedPrices.forResource(resource);
    if (standard != null) {
      // Standard price is per kg. Convert to the selected unit.
      final priceInUnit = standard * _kgPerUnit(_unit);
      _price.text = priceInUnit.toStringAsFixed(0);
    }
  }

  double _kgPerUnit(String unit) {
    switch (unit) {
      case 'kg':
        return 1;
      case 'tonnes':
        return _kgPerTonne;
      case 'bags':
        return _kgPerBag;
      case 'litres':
        return _kgPerLitre;
      case 'trucks':
        return _kgPerTruck;
      case 'pickups':
        return _kgPerPickup;
      default:
        return 1;
    }
  }

  bool get _isStandardPriced {
    final resource = _effectiveResourceName();
    return SeedPrices.forResource(resource) != null;
  }

  bool get _isOtherResource =>
      _selectedChip == 'Other agricultural waste';

  String _effectiveResourceName() {
    if (_isOtherResource) return _resourceType.text.trim();
    if (_selectedChip != null) return _selectedChip!;
    return _resourceType.text.trim();
  }

  bool get _hasRegisteredLocation {
    final user = ref.watch(authProvider);
    return user != null &&
        (user.county ?? '').isNotEmpty &&
        (user.subCounty ?? '').isNotEmpty;
  }

  bool get _isDirty =>
      _resourceType.text.trim().isNotEmpty ||
      _quantity.text.trim().isNotEmpty ||
      _price.text.trim().isNotEmpty ||
      _description.text.trim().isNotEmpty ||
      _selectedChip != null;

  double get _totalValue {
    final q = double.tryParse(_quantity.text.trim()) ?? 0;
    final p = double.tryParse(_price.text.trim()) ?? 0;
    return q * p;
  }

  @override
  void dispose() {
    _resourceType.removeListener(_onResourceChanged);
    _quantity.removeListener(_rebuild);
    _price.removeListener(_rebuild);
    _resourceType.dispose();
    _quantity.dispose();
    _price.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _handleBack() async {
    if (!_isDirty) {
      if (!mounted) return;
      _safeBack();
      return;
    }
    final discard = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Discard listing?'),
        content: const Text(
          'You have unsaved changes. Leave anyway?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Keep editing'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFC62828),
            ),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
    if (discard == true && mounted) _safeBack();
  }

  /// Pop if we can; otherwise replace with home so the stack is never
  /// empty. Guards against the "popped the last page" assertion that
  /// happens when a screen was reached via `go` instead of `push`.
  void _safeBack() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.home);
    }
  }

  Future<void> _submit() async {
    // Guard: block re-entry from the first tap, not just after the dialog.
    if (_submitting) return;
    setState(() => _submitting = true);

    final resourceName = _effectiveResourceName();
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
      setState(() => _submitting = false);
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Send for checking?'),
        content: const Text(
          'Your listing will be reviewed before it appears in the market.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Keep editing'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Send'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) {
      if (mounted) setState(() => _submitting = false);
      return;
    }

    final user = ref.read(authProvider);
    if (user == null) {
      if (mounted) setState(() => _submitting = false);
      return;
    }

    final listing = ref.read(marketplaceControllerProvider).addListing(
          sellerId: user.id,
          sellerName: user.name,
          resourceType: resourceName,
          category: _category,
          quantity: double.parse(_quantity.text.trim()),
          unit: _unit,
          pricePerUnit: double.parse(_price.text.trim()),
          description: _description.text.trim().isEmpty
              ? null
              : _description.text.trim(),
          county: _location!.county,
          subCounty: _location!.subCounty,
          area: _location!.ward,
          sellerVerification: user.verificationStatus,
        );

    if (!mounted) return;
    setState(() => _submitting = false);

    // Clear form so "Sell another" starts fresh
    _resourceType.clear();
    _quantity.clear();
    _price.clear();
    _description.clear();

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => ListingSubmittedScreen(listing: listing),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  // Build
  // ─────────────────────────────────────────────────────────
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
          onPressed: _handleBack,
        ),
        title: const Text('Sell something'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                  children: [
                    _sectionLabel(theme, 'What are you selling?'),
                    const SizedBox(height: 10),
                    _resourceChips(theme),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _resourceType,
                      textCapitalization: TextCapitalization.sentences,
                      maxLength: 60,
                      decoration: InputDecoration(
                        labelText: _isOtherResource
                            ? 'Describe what you are selling'
                            : 'Or type a name',
                        hintText: _isOtherResource
                            ? 'e.g. Groundnut shells'
                            : 'e.g. Maize stalks',
                        filled: true,
                        fillColor: theme.surface,
                        counterText: '',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: theme.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: theme.border),
                        ),
                      ),
                      validator: (v) {
                        final effective = _effectiveResourceName();
                        if (effective.isEmpty) return 'Required';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    _categoryPicker(theme),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _description,
                      maxLines: 3,
                      maxLength: 300,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        labelText: 'Description (optional)',
                        hintText: 'Condition, storage, use case',
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
                    ),

                    const SizedBox(height: 24),
                    _sectionLabel(theme, 'How much and at what price?'),
                    const SizedBox(height: 10),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 3,
                          child: TextFormField(
                            controller: _quantity,
                            keyboardType:
                                const TextInputType.numberWithOptions(
                                    decimal: true),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                  RegExp(r'^\d*\.?\d{0,2}')),
                            ],
                            decoration: InputDecoration(
                              labelText: 'Quantity',
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
                            validator: (v) => _validateQuantity(v),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 2,
                          child: _unitPicker(theme),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _price,
                      readOnly: _isStandardPriced,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: _isStandardPriced
                          ? null
                          : [
                              FilteringTextInputFormatter.allow(
                                  RegExp(r'^\d*\.?\d{0,2}')),
                            ],
                      decoration: InputDecoration(
                        labelText: 'Price per $_unit (KES)',
                        prefixText: 'KES ',
                        helperText: _isStandardPriced
                            ? 'Standard price set by AgriCycles'
                            : 'Your asking price',
                        filled: true,
                        fillColor: _isStandardPriced
                            ? theme.primaryMuted
                            : theme.surface,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: _isStandardPriced
                                ? theme.primary
                                : theme.border,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: _isStandardPriced
                                ? theme.primary
                                : theme.border,
                          ),
                        ),
                      ),
                      validator: (v) {
                        final d = double.tryParse(v?.trim() ?? '');
                        if (d == null || d <= 0) return 'Enter a price';
                        if (d > 1000000) return 'Price too high';
                        return null;
                      },
                    ),
                    if (_totalValue > 0) ...[
                      const SizedBox(height: 10),
                      _totalPreview(theme),
                    ],

                    const SizedBox(height: 24),
                    _sectionLabel(theme, 'Where can buyers collect?'),
                    const SizedBox(height: 10),
                    if (_hasRegisteredLocation) ...[
                      _useRegisteredCheckbox(theme),
                      const SizedBox(height: 12),
                    ],
                    if (!_useRegistered || !_hasRegisteredLocation) ...[
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

                    const SizedBox(height: 24),
                    _sectionLabel(theme, 'Quality (optional)'),
                    const SizedBox(height: 10),
                    _qualityPicker(theme),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: FarmerActionButton(
                label: 'Send for review',
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

  // ─────────────────────────────────────────────────────────
  // Section widgets
  // ─────────────────────────────────────────────────────────
  Widget _sectionLabel(RoleTheme theme, String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: theme.textPrimary,
      ),
    );
  }

  Widget _resourceChips(RoleTheme theme) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: SeedListings.resourceCatalogue.map((r) {
        final active = _selectedChip == r;
        return ChoiceChip(
          label: Text(r),
          selected: active,
          onSelected: (_) {
            setState(() {
              _selectedChip = active ? null : r;
              if (_selectedChip != null) {
                _resourceType.clear();
                _category = SeedListings.categoryByResource[_selectedChip] ??
                    _category;
              }
              _maybePrefillPrice();
            });
          },
          labelStyle: TextStyle(
            color: active ? Colors.white : theme.textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
          selectedColor: theme.primary,
          backgroundColor: theme.surface,
          side: BorderSide(color: theme.border),
        );
      }).toList(),
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
      onChanged: (v) {
        setState(() {
          _unit = v!;
          _quantity.clear();
          _maybePrefillPrice();
        });
      },
    );
  }

  Widget _qualityPicker(RoleTheme theme) {
    const qualities = ['Standard', 'Premium', 'Fair'];
    return Wrap(
      spacing: 8,
      children: qualities.map((q) {
        final active = _quality == q;
        return ChoiceChip(
          label: Text(q),
          selected: active,
          onSelected: (_) => setState(() => _quality = q),
          labelStyle: TextStyle(
            color: active ? Colors.white : theme.textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
          selectedColor: theme.primary,
          backgroundColor: theme.surface,
          side: BorderSide(color: theme.border),
        );
      }).toList(),
    );
  }

  Widget _useRegisteredCheckbox(RoleTheme theme) {
    final user = ref.watch(authProvider);
    final label =
        '${user?.area ?? ""}, ${user?.subCounty ?? ""}, ${user?.county ?? ""}'
            .replaceAll(RegExp(r'^,\s*'), '')
            .replaceAll(RegExp(r',\s*,'), ',');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _useRegistered ? theme.primary : theme.border,
          width: _useRegistered ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          Checkbox(
            value: _useRegistered,
            onChanged: (v) {
              setState(() {
                _useRegistered = v ?? false;
                if (_useRegistered) {
                  _location = LocationSelection(
                    county: user?.county ?? '',
                    subCounty: user?.subCounty ?? '',
                    ward: user?.area ?? '',
                  );
                  _locationError = null;
                }
              });
            },
            activeColor: theme.primary,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Same as my registered location',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: theme.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _totalPreview(RoleTheme theme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.primaryMuted,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(Icons.calculate_outlined,
              size: 18, color: theme.primary),
          const SizedBox(width: 8),
          Text(
            'Total value',
            style: TextStyle(
              fontSize: 13,
              color: theme.textSecondary,
            ),
          ),
          const Spacer(),
          Text(
            _formatKes(_totalValue),
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: theme.primary,
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  // Validators
  // ─────────────────────────────────────────────────────────
  String? _validateQuantity(String? v) {
    final d = double.tryParse(v?.trim() ?? '');
    if (d == null || d <= 0) return 'Enter a number';
    final max = _maxQuantityFor(_unit);
    if (d > max) return 'Max $max $_unit';
    return null;
  }

  double _maxQuantityFor(String unit) {
    switch (unit) {
      case 'kg':
        return 50000;
      case 'tonnes':
        return 50;
      case 'bags':
        return 5000;
      case 'litres':
        return 5000;
      case 'trucks':
        return 5;
      case 'pickups':
        return 16;
      default:
        return 50000;
    }
  }

  String _formatKes(double v) {
    final rounded = v.round();
    final s = rounded.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return 'KES ${buf.toString()}';
  }
}
