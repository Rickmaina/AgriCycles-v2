import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/enums.dart';
import '../../../core/theme/role_theme.dart';
import '../../../core/utils/extensions.dart';
import '../../../data/models/buy_request_offer_model.dart';
import '../../../data/services/auth_service.dart';
import '../../../domain/transport_estimator.dart';
import '../../../domain/validators.dart';
import '../../../shared/widgets/farmer_action_button.dart';
import '../../../shared/widgets/location_picker.dart';
import '../controllers/buy_request_controller.dart';

/// Role-aware buy-request detail.
///
/// If the current user owns the request, they see incoming offers
/// (farmer-simple rows). If they don't, they see the request summary
/// and a form to submit their own offer.
class BuyRequestDetailScreen extends ConsumerWidget {
  final String requestId;
  const BuyRequestDetailScreen({super.key, required this.requestId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const theme = RoleTheme.farmer;
    final request = ref.watch(buyRequestByIdProvider(requestId));
    final user = ref.watch(authProvider);

    if (request == null || user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Request')),
        body: const Center(child: Text('Request not found')),
      );
    }

    final isBuyer = request.buyerId == user.id;
    final isCompany = user.role == UserRole.company;

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
        title: Text(isBuyer ? 'My request' : 'Buy request'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            _summary(theme, request, isCompany),
            const SizedBox(height: 20),
            if (isBuyer) ...[
              _sectionLabel(theme, 'Offers (${_offerCount(ref)})'),
              const SizedBox(height: 10),
              _offersList(theme, ref, requestId, request.unit),
            ] else ...[
              _sectionLabel(theme, 'Send your offer'),
              const SizedBox(height: 10),
              _SellerOfferForm(
                requestId: requestId,
                unit: request.unit,
                suggestedPrice: request.offeredPricePerUnit,
                suggestedQty: request.quantity,
                isCompany: isCompany,
                baseCounty: user.county,
              ),
            ],
          ],
        ),
      ),
    );
  }

  int _offerCount(WidgetRef ref) {
    return ref.read(buyRequestOffersProvider(requestId)).length;
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

  Widget _summary(RoleTheme theme, dynamic request, bool isCompany) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.border, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            request.resourceType as String,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: theme.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'from ${request.buyerName}',
            style: TextStyle(
              fontSize: 13,
              color: theme.textSecondary,
            ),
          ),
          const SizedBox(height: 14),
          _row(theme, 'Needs', '${request.quantity} ${request.unit}'),
          const SizedBox(height: 6),
          _row(
            theme,
            'Offering',
            'KES ${(request.offeredPricePerUnit as double).round()} / ${request.unit}',
          ),
          const SizedBox(height: 6),
          _row(
            theme,
            'Total budget',
            _formatKes((request.quantity as double) *
                (request.offeredPricePerUnit as double)),
            bold: true,
          ),
          const Divider(height: 24, color: Color(0xFFEEEEEE)),
          _row(theme, 'Deliver to', request.deliveryBroadLocation as String),
          if (request.description != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: theme.primaryMuted,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                request.description as String,
                style: TextStyle(
                  fontSize: 12,
                  color: theme.textSecondary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _row(
    RoleTheme theme,
    String label,
    String value, {
    bool bold = false,
  }) {
    return Row(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: theme.textSecondary,
          ),
        ),
        const Spacer(),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 13,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
              color: bold ? theme.primary : theme.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _offersList(
    RoleTheme theme,
    WidgetRef ref,
    String requestId,
    String unit,
  ) {
    final offers = ref.watch(buyRequestOffersProvider(requestId));
    if (offers.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.primaryMuted,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(Icons.hourglass_empty, color: theme.textMuted),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'No offers yet. Sellers are notified.',
                style: TextStyle(
                  fontSize: 13,
                  color: theme.textSecondary,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: offers
          .map((o) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _BuyerOfferRow(offer: o, unit: unit),
              ))
          .toList(),
    );
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

// ─────────────────────────────────────────────────────────────
// Buyer's view of one offer
// ─────────────────────────────────────────────────────────────

class _BuyerOfferRow extends ConsumerWidget {
  final BuyRequestOfferModel offer;
  final String unit;

  const _BuyerOfferRow({required this.offer, required this.unit});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const theme = RoleTheme.farmer;
    final decided = offer.status != BuyRequestOfferStatus.pending;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.border, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  offer.sellerName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: theme.textPrimary,
                  ),
                ),
              ),
              _statusChip(offer.status, theme),
            ],
          ),
          const SizedBox(height: 10),
          _line(theme, 'Price', 'KES ${offer.pricePerUnit.round()} / $unit'),
          const SizedBox(height: 4),
          _line(theme, 'Quantity', '${offer.quantity} $unit'),
          const SizedBox(height: 4),
          _line(theme, 'Pickup', offer.pickupBroadLocation),
          if (offer.message != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: theme.primaryMuted,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                offer.message!,
                style: TextStyle(
                  fontSize: 12,
                  color: theme.textSecondary,
                ),
              ),
            ),
          ],
          if (!decided) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => ref
                        .read(buyRequestControllerProvider)
                        .declineOffer(offer),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: theme.danger,
                      side: BorderSide(color: theme.danger),
                      minimumSize: const Size.fromHeight(44),
                    ),
                    child: const Text('Decline'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      ref
                          .read(buyRequestControllerProvider)
                          .acceptOffer(offer);
                      context.showSnack('Offer accepted');
                    },
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(44),
                    ),
                    child: const Text('Accept'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _line(RoleTheme theme, String label, String value) {
    return Row(
      children: [
        SizedBox(
          width: 72,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: theme.textMuted,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: theme.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _statusChip(BuyRequestOfferStatus status, RoleTheme theme) {
    final color = switch (status) {
      BuyRequestOfferStatus.pending => theme.accent,
      BuyRequestOfferStatus.accepted => theme.primary,
      BuyRequestOfferStatus.declined => theme.danger,
      BuyRequestOfferStatus.withdrawn => theme.textMuted,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Seller's form to submit an offer
// ─────────────────────────────────────────────────────────────

class _SellerOfferForm extends ConsumerStatefulWidget {
  final String requestId;
  final String unit;
  final double suggestedPrice;
  final double suggestedQty;
  final bool isCompany;
  final String? baseCounty;

  const _SellerOfferForm({
    required this.requestId,
    required this.unit,
    required this.suggestedPrice,
    required this.suggestedQty,
    required this.isCompany,
    this.baseCounty,
  });

  @override
  ConsumerState<_SellerOfferForm> createState() => _SellerOfferFormState();
}

class _SellerOfferFormState extends ConsumerState<_SellerOfferForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _quantity;
  late final TextEditingController _price;

  LocationSelection? _location;
  String? _locationError;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _quantity = TextEditingController(
        text: widget.suggestedQty.toStringAsFixed(0));
    _price = TextEditingController(
        text: widget.suggestedPrice.toStringAsFixed(0));
  }

  @override
  void dispose() {
    _quantity.dispose();
    _price.dispose();
    super.dispose();
  }

  void _submit() {
    final formOk = _formKey.currentState!.validate();
    final locationOk = _location != null &&
        _location!.county.isNotEmpty &&
        _location!.subCounty.isNotEmpty;
    if (!formOk || !locationOk) {
      if (!locationOk) {
        setState(() => _locationError = 'Pick your pickup point.');
      }
      return;
    }

    final user = ref.read(authProvider);
    if (user == null) return;

    final request = ref.read(buyRequestByIdProvider(widget.requestId));
    if (request == null) return;

    setState(() => _submitting = true);

    ref.read(buyRequestControllerProvider).submitOffer(
          request: request,
          sellerId: user.id,
          sellerName: user.name,
          pricePerUnit: double.parse(_price.text.trim()),
          quantity: double.parse(_quantity.text.trim()),
          pickupCounty: _location!.county,
          pickupSubCounty: _location!.subCounty,
          pickupArea: _location!.ward,
        );

    if (!mounted) return;
    context.showSnack('Offer sent');
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    const theme = RoleTheme.farmer;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.isCompany && widget.baseCounty != null) ...[
            _distanceHint(widget.baseCounty!),
            const SizedBox(height: 12),
          ],
          _field(
            controller: _quantity,
            label: 'Your quantity (${widget.unit})',
            validator: (v) =>
                Validators.positiveNumber(v, label: 'Quantity'),
          ),
          const SizedBox(height: 12),
          _field(
            controller: _price,
            label: 'Your price per ${widget.unit} (KES)',
            validator: (v) =>
                Validators.positiveNumber(v, label: 'Price'),
          ),
          const SizedBox(height: 20),
          Text(
            'Your pickup point',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: theme.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
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
          const SizedBox(height: 24),
          FarmerActionButton(
            label: 'Send my offer',
            icon: Icons.send,
            onPressed: _submitting ? null : _submit,
            loading: _submitting,
          ),
        ],
      ),
    );
  }

  Widget _distanceHint(String fromCounty) {
    const theme = RoleTheme.farmer;
    if (_location == null) return const SizedBox.shrink();
    final km = TransportEstimator.distanceKm(
      pickupCounty: fromCounty,
      deliveryCounty: _location!.county,
    );
    if (km <= 0) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: theme.primaryMuted,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.route_outlined, size: 16, color: theme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'About ${km.toStringAsFixed(0)} km from your base',
              style: TextStyle(
                fontSize: 12,
                color: theme.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required String? Function(String?) validator,
  }) {
    const theme = RoleTheme.farmer;
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
