import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/extensions.dart';
import '../../../data/services/auth_service.dart';
import '../../../domain/validators.dart';
import '../../../shared/widgets/location_picker.dart';
import '../controllers/buy_request_controller.dart';

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
  final _description = TextEditingController();

  String _category = 'Crop residue';
  String _unit = 'tonnes';
  LocationSelection? _location;
  String? _locationError;

  static const _units = ['kg', 'tonnes', 'bags', 'litres'];
  static const _categories = [
    'Crop residue',
    'Animal waste',
    'By-product',
  ];

  @override
  void dispose() {
    _resourceType.dispose();
    _quantity.dispose();
    _price.dispose();
    _description.dispose();
    super.dispose();
  }

  void _submit() {
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

    final user = ref.read(authProvider);
    if (user == null) return;

    ref.read(buyRequestControllerProvider).postRequest(
          buyerId: user.id,
          buyerName: user.name,
          resourceType: _resourceType.text.trim(),
          category: _category,
          quantity: double.parse(_quantity.text.trim()),
          unit: _unit,
          offeredPricePerUnit: double.parse(_price.text.trim()),
          description: _description.text.trim().isEmpty
              ? null
              : _description.text.trim(),
          deliveryCounty: _location!.county,
          deliverySubCounty: _location!.subCounty,
          deliveryArea: _location!.ward,
        );

    context.showSnack('Buy request posted');
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Post a need')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            children: [
              const _SectionLabel('What do you need?'),
              const SizedBox(height: 10),
              TextFormField(
                controller: _resourceType,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Resource name',
                  hintText: 'e.g. Maize stalks, Cow manure',
                ),
                validator: (v) =>
                    Validators.requiredText(v, label: 'Resource'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _category,
                decoration: const InputDecoration(labelText: 'Category'),
                items: _categories
                    .map((c) =>
                        DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) => setState(() => _category = v!),
              ),
              const SizedBox(height: 24),

              const _SectionLabel('How much & at what price?'),
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: TextFormField(
                      controller: _quantity,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                            RegExp(r'^\d*\.?\d{0,2}')),
                      ],
                      decoration:
                          const InputDecoration(labelText: 'Quantity'),
                      validator: (v) => Validators.positiveNumber(v,
                          label: 'Quantity', max: 100000),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: DropdownButtonFormField<String>(
                      initialValue: _unit,
                      decoration:
                          const InputDecoration(labelText: 'Unit'),
                      items: _units
                          .map((u) =>
                              DropdownMenuItem(value: u, child: Text(u)))
                          .toList(),
                      onChanged: (v) => setState(() => _unit = v!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _price,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(
                      RegExp(r'^\d*\.?\d{0,2}')),
                ],
                decoration: InputDecoration(
                  labelText: 'Your offer per $_unit (KES)',
                  prefixText: 'KES ',
                ),
                validator: (v) =>
                    Validators.positiveNumber(v, label: 'Price'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _description,
                maxLines: 3,
                maxLength: 240,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                  hintText: 'Any specifics about quality, timing, use',
                ),
              ),
              const SizedBox(height: 16),

              const _SectionLabel('Delivery point'),
              const SizedBox(height: 6),
              const Text(
                'Only the broad area is shared with sellers.',
                style: TextStyle(
                    fontSize: 12, color: AppColors.textMuted),
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
                      color: AppColors.danger, fontSize: 12),
                ),
              ],
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _submit,
                icon: const Icon(Icons.campaign_outlined),
                label: const Text('Post request'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
    );
  }
}
