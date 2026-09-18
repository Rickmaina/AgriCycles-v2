import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/kenya_locations.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/extensions.dart';
import '../../data/models/listing_model.dart';
import '../../data/services/auth_service.dart';
import '../../domain/transport_estimator.dart';
import '../../domain/validators.dart';
import 'controllers/marketplace_controller.dart';

class MakeOfferScreen extends ConsumerStatefulWidget {
  final ListingModel listing;
  const MakeOfferScreen({super.key, required this.listing});

  @override
  ConsumerState<MakeOfferScreen> createState() => _MakeOfferScreenState();
}

class _MakeOfferScreenState extends ConsumerState<MakeOfferScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _quantity;
  late final TextEditingController _price;
  final _message = TextEditingController();
  final _deliverySubCounty = TextEditingController();
  final _deliveryArea = TextEditingController();
  final _deliveryNotes = TextEditingController();
  String? _deliveryCounty;

  @override
  void initState() {
    super.initState();
    _quantity = TextEditingController(text: widget.listing.quantity.toString());
    _price = TextEditingController(
        text: widget.listing.pricePerUnit.toStringAsFixed(0));
    _deliveryCounty = widget.listing.county;
  }

  @override
  void dispose() {
    _quantity.dispose();
    _price.dispose();
    _message.dispose();
    _deliverySubCounty.dispose();
    _deliveryArea.dispose();
    _deliveryNotes.dispose();
    super.dispose();
  }

  double get _distanceKm => _deliveryCounty == null
      ? 0
      : TransportEstimator.distanceKm(
          pickupCounty: widget.listing.county,
          deliveryCounty: _deliveryCounty!,
        );

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final user = ref.read(authProvider);
    if (user == null) return;

    ref.read(marketplaceControllerProvider).makeOffer(
          listing: widget.listing,
          buyerId: user.id,
          buyerName: user.name,
          quantity: double.parse(_quantity.text.trim()),
          pricePerUnit: double.parse(_price.text.trim()),
          deliveryCounty: _deliveryCounty!,
          deliverySubCounty: _deliverySubCounty.text.trim(),
          deliveryArea: _deliveryArea.text.trim(),
          deliveryNotes: _deliveryNotes.text.trim().isEmpty
              ? null
              : _deliveryNotes.text.trim(),
          message: _message.text.trim().isEmpty ? null : _message.text.trim(),
        );

    context.showSnack('Offer sent to seller');
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final l = widget.listing;

    return Scaffold(
      appBar: AppBar(title: const Text('Make an offer')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _ListingSummary(listing: l),
                const SizedBox(height: 20),
                const _SectionLabel('Your offer'),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _quantity,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                        RegExp(r'^\d*\.?\d{0,2}')),
                  ],
                  decoration:
                      InputDecoration(labelText: 'Quantity (${l.unit})'),
                  validator: (v) => Validators.quantity(
                    v,
                    available: l.quantity,
                    unit: l.unit,
                  ),
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
                  decoration: const InputDecoration(
                      labelText: 'Your price per unit (KES)'),
                  validator: (v) =>
                      Validators.positiveNumber(v, label: 'Price'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _message,
                  maxLines: 3,
                  decoration: const InputDecoration(
                      labelText: 'Message to seller (optional)'),
                ),
                const SizedBox(height: 24),
                const _SectionLabel('Delivery point'),
                const SizedBox(height: 6),
                const Text(
                  'Where do you want the goods delivered? The seller and Admin logistics see this once you make the offer.',
                  style: TextStyle(
                      fontSize: 12, color: AppColors.textMuted, height: 1.4),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _deliveryCounty,
                  decoration: const InputDecoration(labelText: 'County'),
                  items: KenyaLocations.counties
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (v) => setState(() => _deliveryCounty = v),
                  validator: Validators.county,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _deliverySubCounty,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(labelText: 'Sub-county'),
                  validator: (v) =>
                      Validators.requiredText(v, label: 'Sub-county'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _deliveryArea,
                  textCapitalization: TextCapitalization.words,
                  decoration:
                      const InputDecoration(labelText: 'Area / Village'),
                  validator: (v) => Validators.requiredText(v, label: 'Area'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _deliveryNotes,
                  maxLines: 2,
                  maxLength: 120,
                  decoration: const InputDecoration(
                    labelText: 'Landmark / notes (optional)',
                    hintText: 'e.g. gate opposite Kamakis shopping centre',
                  ),
                ),
                if (_distanceKm > 0) ...[
                  const SizedBox(height: 8),
                  _DistanceHint(km: _distanceKm),
                ],
                const SizedBox(height: 20),
                const _AdminMediatedNote(),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _submit,
                  child: const Text('Send offer'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ListingSummary extends StatelessWidget {
  final ListingModel listing;
  const _ListingSummary({required this.listing});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            listing.resourceType,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
          ),
          const SizedBox(height: 4),
          Text(
            '${listing.sellerName} • ${listing.broadLocation}',
            style:
                const TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 6),
          Text(
            'Asking: ${listing.pricePerUnit.kes} / ${listing.unit}',
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.primary),
          ),
        ],
      ),
    );
  }
}

class _DistanceHint extends StatelessWidget {
  final double km;
  const _DistanceHint({required this.km});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.info.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(Icons.route_outlined, size: 18, color: AppColors.info),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Pickup to delivery: ≈ ${km.toStringAsFixed(0)} km straight-line',
              style:
                  const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminMediatedNote extends StatelessWidget {
  const _AdminMediatedNote();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline, size: 18, color: AppColors.info),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Final transport is arranged by Admin once the seller accepts.',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ),
        ],
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
