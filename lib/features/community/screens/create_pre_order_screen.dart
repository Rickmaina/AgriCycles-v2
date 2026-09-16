import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/enums.dart';
import '../../../core/constants/kenya_locations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/extensions.dart';
import '../../../data/services/auth_service.dart';
import '../../../domain/validators.dart';
import '../controllers/pre_order_controller.dart';

class CreatePreOrderScreen extends ConsumerStatefulWidget {
  const CreatePreOrderScreen({super.key});

  @override
  ConsumerState<CreatePreOrderScreen> createState() =>
      _CreatePreOrderScreenState();
}

class _CreatePreOrderScreenState
    extends ConsumerState<CreatePreOrderScreen> {
  final _formKey = GlobalKey<FormState>();
  final _resourceType = TextEditingController();
  final _target = TextEditingController();
  final _price = TextEditingController();
  final _description = TextEditingController();
  final _subCounty = TextEditingController();
  final _area = TextEditingController();
  final _notes = TextEditingController();

  String _category = 'Crop residue';
  String _unit = 'tonnes';
  String? _county;
  int _deadlineDays = 14;

  static const _units = ['kg', 'tonnes', 'bags', 'litres'];
  static const _categories = [
    'Crop residue',
    'Animal waste',
    'By-product',
  ];

  @override
  void dispose() {
    _resourceType.dispose();
    _target.dispose();
    _price.dispose();
    _description.dispose();
    _subCounty.dispose();
    _area.dispose();
    _notes.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final user = ref.read(authProvider);
    if (user == null) return;

    ref.read(preOrderControllerProvider).create(
          buyerId: user.id,
          buyerName: user.name,
          buyerIsCompany: user.role == UserRole.company,
          resourceType: _resourceType.text.trim(),
          category: _category,
          targetQuantity: double.parse(_target.text.trim()),
          unit: _unit,
          offeredPricePerUnit: double.parse(_price.text.trim()),
          description: _description.text.trim().isEmpty
              ? null
              : _description.text.trim(),
          deliveryCounty: _county!,
          deliverySubCounty: _subCounty.text.trim(),
          deliveryArea: _area.text.trim(),
          deliveryNotes: _notes.text.trim().isEmpty
              ? null
              : _notes.text.trim(),
          deadline: DateTime.now().add(Duration(days: _deadlineDays)),
        );

    context.showSnack('Community order published');
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Community pre-order')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.info.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.groups_outlined,
                        size: 18, color: AppColors.info),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Farmers commit quantities until your target is reached. Pickup is coordinated across all contributing farms.',
                        style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                            height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              const _SectionLabel('What do you need aggregated?'),
              const SizedBox(height: 10),
              TextFormField(
                controller: _resourceType,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Resource name',
                  hintText: 'e.g. Maize stalks',
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

              const _SectionLabel('Target & price'),
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: TextFormField(
                      controller: _target,
                      keyboardType:
                          const TextInputType.numberWithOptions(
                              decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                            RegExp(r'^\d*\.?\d{0,2}')),
                      ],
                      decoration: const InputDecoration(
                          labelText: 'Target quantity'),
                      validator: (v) => Validators.positiveNumber(v,
                          label: 'Target', max: 100000),
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
                  labelText: 'Price per $_unit (KES)',
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
                ),
              ),
              const SizedBox(height: 24),

              const _SectionLabel('Deadline'),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                children: [7, 14, 21, 30].map((d) {
                  final active = _deadlineDays == d;
                  return ChoiceChip(
                    label: Text('$d days'),
                    selected: active,
                    onSelected: (_) =>
                        setState(() => _deadlineDays = d),
                    labelStyle: TextStyle(
                      color: active
                          ? Colors.white
                          : AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                    selectedColor: AppColors.primary,
                    backgroundColor: AppColors.surface,
                    side: const BorderSide(color: AppColors.border),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              const _SectionLabel('Delivery point'),
              const SizedBox(height: 6),
              const Text(
                'Broad area is shown to contributors.',
                style: TextStyle(
                    fontSize: 12, color: AppColors.textMuted),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _county,
                decoration: const InputDecoration(labelText: 'County'),
                items: KenyaLocations.counties
                    .map((c) =>
                        DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) => setState(() => _county = v),
                validator: Validators.county,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _subCounty,
                textCapitalization: TextCapitalization.words,
                decoration:
                    const InputDecoration(labelText: 'Sub-county'),
                validator: (v) =>
                    Validators.requiredText(v, label: 'Sub-county'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _area,
                textCapitalization: TextCapitalization.words,
                decoration:
                    const InputDecoration(labelText: 'Area / Village'),
                validator: (v) =>
                    Validators.requiredText(v, label: 'Area'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _notes,
                maxLines: 2,
                maxLength: 120,
                decoration: const InputDecoration(
                  labelText: 'Landmark / notes (optional)',
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _submit,
                icon: const Icon(Icons.groups),
                label: const Text('Publish community order'),
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
