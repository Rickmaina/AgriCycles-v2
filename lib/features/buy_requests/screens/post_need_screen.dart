import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/enums.dart';
import '../../../core/theme/role_theme.dart';
import '../../../core/utils/extensions.dart';
import '../../../data/services/auth_service.dart';
import '../../../domain/validators.dart';
import '../../../shared/widgets/farmer_action_button.dart';
import '../../../shared/widgets/location_picker.dart';
import '../controllers/buy_request_controller.dart';

/// Post a need. Farmer version: resource, quantity, price, location.
/// Company version adds radius, deadline, and notes.
class PostNeedScreen extends ConsumerStatefulWidget {
  const PostNeedScreen({super.key});

  @override
  ConsumerState<PostNeedScreen> createState() => _PostNeedScreenState();
}

class _PostNeedScreenState extends ConsumerState<PostNeedScreen> {
  final _formKey = GlobalKey<FormState>();
  final _resourceType = TextEditingController();
  final _quantity = TextEditingController();
  final _price = TextEditingController();
  final _notes = TextEditingController();

  String _category = 'Crop residue';
  String _unit = 'tonnes';
  int _radiusKm = 50;
  int _deadlineDays = 14;
  LocationSelection? _location;
  String? _locationError;
  bool _submitting = false;

  static const _units = ['kg', 'tonnes', 'bags', 'litres'];
  static const _categories = [
    'Crop residue',
    'Animal waste',
    'By-product',
  ];
  static const _radii = [30, 50, 100, 250];
  static const _deadlines = [7, 14, 30];

  @override
  void dispose() {
    _resourceType.dispose();
    _quantity.dispose();
    _price.dispose();
    _notes.dispose();
    super.dispose();
  }

  bool get _isCompany {
    final user = ref.read(authProvider);
    return user?.role == UserRole.company;
  }

  void _submit() {
    final formOk = _formKey.currentState!.validate();
    final locationOk = _location != null &&
        _location!.county.isNotEmpty &&
        _location!.subCounty.isNotEmpty;
    if (!formOk || !locationOk) {
      if (!locationOk) {
        setState(() => _locationError =
            'Pick where you want supply delivered.');
      }
      return;
    }

    final user = ref.read(authProvider);
    if (user == null) return;

    setState(() => _submitting = true);

    ref.read(buyRequestControllerProvider).postRequest(
          buyerId: user.id,
          buyerName: user.name,
          resourceType: _resourceType.text.trim(),
          category: _category,
          quantity: double.parse(_quantity.text.trim()),
          unit: _unit,
          offeredPricePerUnit: double.parse(_price.text.trim()),
          description: _notes.text.trim().isEmpty
              ? null
              : _notes.text.trim(),
          deliveryCounty: _location!.county,
          deliverySubCounty: _location!.subCounty,
          deliveryArea: _location!.ward,
        );

    if (!mounted) return;
    context.showSnack('Need posted');
    context.go('/market');
  }

  @override
  Widget build(BuildContext context) {
    const theme = RoleTheme.farmer;
    final isCompany = _isCompany;

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
        title: Text(isCompany ? 'Post a need' : 'Ask for something'),
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
                        label: 'What do you need?',
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
                              validator: (v) =>
                                  Validators.positiveNumber(
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
                        label: 'Your price per $_unit (KES)',
                        keyboard:
                            const TextInputType.numberWithOptions(
                                decimal: true),
                        validator: (v) => Validators.positiveNumber(
                          v,
                          label: 'Price',
                        ),
                      ),
                      if (isCompany) ...[
                        const SizedBox(height: 24),
                        _sectionLabel(theme, 'How far will you buy from?'),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          children: _radii.map((r) {
                            final active = _radiusKm == r;
                            return ChoiceChip(
                              label: Text('$r km'),
                              selected: active,
                              onSelected: (_) =>
                                  setState(() => _radiusKm = r),
                              labelStyle: TextStyle(
                                color: active
                                    ? Colors.white
                                    : theme.textPrimary,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                              selectedColor: theme.primary,
                              backgroundColor: theme.surface,
                              side: BorderSide(color: theme.border),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 20),
                        _sectionLabel(theme, 'How long should it stay open?'),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          children: _deadlines.map((d) {
                            final active = _deadlineDays == d;
                            return ChoiceChip(
                              label: Text('$d days'),
                              selected: active,
                              onSelected: (_) =>
                                  setState(() => _deadlineDays = d),
                              labelStyle: TextStyle(
                                color: active
                                    ? Colors.white
                                    : theme.textPrimary,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                              selectedColor: theme.primary,
                              backgroundColor: theme.surface,
                              side: BorderSide(color: theme.border),
                            );
                          }).toList(),
                        ),
                      ],
                      const SizedBox(height: 24),
                      _sectionLabel(theme, 'Where do you want delivery?'),
                      const SizedBox(height: 6),
                      Text(
                        'Only the broad area is shared with sellers.',
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
                      if (isCompany) ...[
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: _notes,
                          maxLines: 3,
                          maxLength: 240,
                          decoration: InputDecoration(
                            labelText: 'Notes for sellers (optional)',
                            hintText:
                                'e.g. Grade A only. Collection this month.',
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
                      ],
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: FarmerActionButton(
                label: isCompany ? 'Post need' : 'Post request',
                icon: Icons.campaign_outlined,
                onPressed: _submitting ? null : _submit,
                loading: _submitting,
              ),
            ),
          ],
        ),
      ),
    );
  }

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
      items: _categories
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
