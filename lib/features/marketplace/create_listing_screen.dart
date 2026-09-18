import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/kenya_locations.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/extensions.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/mock/mock_listings.dart';
import '../../domain/validators.dart';
import 'controllers/marketplace_controller.dart';

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
  final _subCounty = TextEditingController();
  final _area = TextEditingController();

  String _category = 'Crop residue';
  String _unit = 'tonnes';
  String? _county;

  static const _units = ['kg', 'tonnes', 'bags', 'litres'];

  @override
  void initState() {
    super.initState();
    _quantity.addListener(_rebuild);
    _price.addListener(_rebuild);
  }

  void _rebuild() => setState(() {});

  @override
  void dispose() {
    _resourceType.dispose();
    _quantity.dispose();
    _price.dispose();
    _description.dispose();
    _subCounty.dispose();
    _area.dispose();
    super.dispose();
  }

  double get _totalValue {
    final q = double.tryParse(_quantity.text.trim()) ?? 0;
    final p = double.tryParse(_price.text.trim()) ?? 0;
    return q * p;
  }

  Future<void> _confirmAndSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Publish listing?'),
        content: Text(
          '${_resourceType.text.trim()} • '
          '${_quantity.text.trim()} $_unit\n'
          'KES ${_price.text.trim()} / $_unit  •  '
          'Total ${_totalValue.kes}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Publish'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final user = ref.read(authProvider);
    if (user == null) return;

    ref.read(marketplaceControllerProvider).addListing(
          sellerId: user.id,
          sellerName: user.name,
          resourceType: _resourceType.text.trim(),
          category: _category,
          quantity: double.parse(_quantity.text.trim()),
          unit: _unit,
          pricePerUnit: double.parse(_price.text.trim()),
          description: _description.text.trim().isEmpty
              ? null
              : _description.text.trim(),
          county: _county!,
          subCounty: _subCounty.text.trim(),
          area: _area.text.trim(),
          sellerVerification: user.verificationStatus,
        );

    if (!mounted) return;
    context.showSnack('Listing published');
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New listing'),
        actions: [
          TextButton(
            onPressed: _confirmAndSubmit,
            child: const Text('Publish',
                style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            children: [
              const _SectionLabel('What are you selling?'),
              const SizedBox(height: 10),
              TextFormField(
                controller: _resourceType,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Resource name',
                  hintText: 'e.g. Maize stalks, Cow manure',
                ),
                validator: (v) => Validators.requiredText(v, label: 'Resource'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _category,
                decoration: const InputDecoration(labelText: 'Category'),
                items: MockListings.categories
                    .where((c) => c != 'All')
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) => setState(() => _category = v!),
              ),
              const SizedBox(height: 24),
              const _SectionLabel('Quantity & price'),
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: TextFormField(
                      controller: _quantity,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                            RegExp(r'^\d*\.?\d{0,2}')),
                      ],
                      decoration: const InputDecoration(labelText: 'Quantity'),
                      validator: (v) => Validators.positiveNumber(v,
                          label: 'Quantity', max: 100000),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: DropdownButtonFormField<String>(
                      initialValue: _unit,
                      decoration: const InputDecoration(labelText: 'Unit'),
                      items: _units
                          .map(
                              (u) => DropdownMenuItem(value: u, child: Text(u)))
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
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                ],
                decoration: InputDecoration(
                  labelText: 'Price per $_unit (KES)',
                  prefixText: 'KES ',
                ),
                validator: (v) => Validators.positiveNumber(v, label: 'Price'),
              ),
              if (_totalValue > 0) ...[
                const SizedBox(height: 12),
                _TotalPreview(value: _totalValue),
              ],
              const SizedBox(height: 12),
              TextFormField(
                controller: _description,
                maxLines: 3,
                maxLength: 240,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                  hintText: 'Condition, how it was stored, use case…',
                ),
              ),
              const SizedBox(height: 16),
              const _SectionLabel('Photos'),
              const SizedBox(height: 10),
              const _PhotoPlaceholder(),
              const SizedBox(height: 24),
              const _SectionLabel('Pickup location'),
              const SizedBox(height: 6),
              const Text(
                'Only the broad area is shown publicly. Your exact address stays private until an order is accepted.',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textMuted,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _county,
                decoration: const InputDecoration(labelText: 'County'),
                items: KenyaLocations.counties
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) => setState(() => _county = v),
                validator: Validators.county,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _subCounty,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Sub-county'),
                validator: (v) =>
                    Validators.requiredText(v, label: 'Sub-county'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _area,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Area / Village'),
                validator: (v) => Validators.requiredText(v, label: 'Area'),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: _confirmAndSubmit,
                icon: const Icon(Icons.check),
                label: const Text('Publish listing'),
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

class _TotalPreview extends StatelessWidget {
  final double value;
  const _TotalPreview({required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(Icons.calculate_outlined,
              size: 18, color: AppColors.primary),
          const SizedBox(width: 8),
          const Text(
            'Total listing value',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
          const Spacer(),
          Text(
            value.kes,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _PhotoPlaceholder extends StatelessWidget {
  const _PhotoPlaceholder();

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.showSnack('Photo upload coming in a later pass'),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 110,
        decoration: BoxDecoration(
          color: AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_a_photo_outlined,
                size: 28, color: AppColors.textMuted),
            SizedBox(height: 6),
            Text(
              'Add photos (optional)',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
