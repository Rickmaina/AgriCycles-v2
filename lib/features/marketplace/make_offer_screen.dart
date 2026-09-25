import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/role_theme.dart';
import '../../core/utils/extensions.dart';
import '../../data/models/listing_model.dart';
import '../../data/services/auth_service.dart';
import '../../domain/validators.dart';
import '../../shared/widgets/farmer_action_button.dart';
import '../../shared/widgets/location_picker.dart';
import 'controllers/marketplace_controller.dart';

/// Make an offer. Three inputs, one action.
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

  LocationSelection? _delivery;
  String? _locationError;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _quantity = TextEditingController(
      text: _formatNumber(widget.listing.quantity),
    );
    _price = TextEditingController(
      text: widget.listing.pricePerUnit.round().toString(),
    );
    _delivery = LocationSelection(
      county: widget.listing.county,
      subCounty: widget.listing.subCounty,
      ward: widget.listing.area,
    );
  }

  String _formatNumber(double v) =>
      v.truncateToDouble() == v ? v.toStringAsFixed(0) : v.toString();

  @override
  void dispose() {
    _quantity.dispose();
    _price.dispose();
    super.dispose();
  }

  void _submit() {
    final formOk = _formKey.currentState!.validate();
    final locationOk = _delivery != null &&
        _delivery!.county.isNotEmpty &&
        _delivery!.subCounty.isNotEmpty;
    if (!formOk || !locationOk) {
      if (!locationOk) {
        setState(() => _locationError = 'Pick where to deliver.');
      }
      return;
    }

    final user = ref.read(authProvider);
    if (user == null) return;

    setState(() => _submitting = true);

    ref.read(marketplaceControllerProvider).makeOffer(
          listing: widget.listing,
          buyerId: user.id,
          buyerName: user.name,
          quantity: double.parse(_quantity.text.trim()),
          pricePerUnit: double.parse(_price.text.trim()),
          deliveryCounty: _delivery!.county,
          deliverySubCounty: _delivery!.subCounty,
          deliveryArea: _delivery!.ward,
        );

    context.showSnack('Offer sent');
    context.pop();
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
        title: const Text('Give a price'),
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
                      _listingSummary(theme),
                      const SizedBox(height: 24),
                      _field(
                        theme: theme,
                        controller: _quantity,
                        label: 'How much? (${widget.listing.unit})',
                        keyboard: const TextInputType.numberWithOptions(
                            decimal: true),
                        validator: (v) => Validators.quantity(
                          v,
                          available: widget.listing.quantity,
                          unit: widget.listing.unit,
                        ),
                      ),
                      const SizedBox(height: 14),
                      _field(
                        theme: theme,
                        controller: _price,
                        label: 'Price per ${widget.listing.unit} (KES)',
                        keyboard: const TextInputType.numberWithOptions(
                            decimal: true),
                        validator: (v) => Validators.positiveNumber(
                          v,
                          label: 'Price',
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Where do you want it delivered?',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: theme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 14),
                      LocationPicker(
                        initial: _delivery,
                        onChanged: (sel) {
                          setState(() {
                            _delivery = sel;
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
                label: 'Send my price',
                icon: Icons.send,
                onPressed: _submitting ? null : _submit,
                loading: _submitting,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _listingSummary(RoleTheme theme) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.border, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.listing.resourceType,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: theme.textPrimary,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${widget.listing.sellerName}  ·  ${widget.listing.county}',
            style: TextStyle(
              fontSize: 13,
              color: theme.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Asking: KES ${widget.listing.pricePerUnit.round()} / ${widget.listing.unit}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: theme.primary,
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
}
