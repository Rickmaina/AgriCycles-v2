import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/role_theme.dart';
import '../../../data/models/listing_model.dart';
import '../../../data/services/auth_service.dart';
import '../../buy_requests/controllers/buy_request_controller.dart';
import '../controllers/marketplace_controller.dart';

// ─────────────────────────────────────────────────────────────
// LISTING offer flow
// ─────────────────────────────────────────────────────────────

/// Two-dialog offer flow for a listing card in the market.
///
///   1. Give a price (quantity + price)
///   2. Offer sent (confirmation)
///
/// Returns to the market screen underneath. No page navigation.
Future<void> showListingOfferFlow({
  required BuildContext context,
  required WidgetRef ref,
  required ListingModel listing,
}) async {
  final submitted = await showDialog<bool>(
    context: context,
    barrierDismissible: true,
    builder: (dialogContext) => _OfferFormDialog(
      title: 'Give a price',
      subtitle: '${listing.sellerName} · ${listing.broadLocation}',
      askingLabel:
          'Asking: KES ${listing.pricePerUnit.round()} / ${listing.unit}',
      unit: listing.unit,
      availableQuantity: listing.quantity,
      initialQuantity: listing.quantity,
      initialPrice: listing.pricePerUnit,
      onSubmit: (quantity, price) {
        final user = ref.read(authProvider);
        if (user == null) return;

        ref.read(marketplaceControllerProvider).makeOffer(
              listing: listing,
              buyerId: user.id,
              buyerName: user.name,
              quantity: quantity,
              pricePerUnit: price,
              deliveryCounty: listing.county,
              deliverySubCounty: listing.subCounty,
              deliveryArea: listing.area,
            );
      },
    ),
  );

  if (submitted != true || !context.mounted) return;

  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => _OfferSentDialog(
      sellerName: listing.sellerName,
    ),
  );
}

// ─────────────────────────────────────────────────────────────
// BUY REQUEST offer flow
// ─────────────────────────────────────────────────────────────

/// Two-dialog offer flow for a buy-request (Wanted) card.
Future<void> showBuyRequestOfferFlow({
  required BuildContext context,
  required WidgetRef ref,
  required dynamic request, // BuyRequestModel
}) async {
  final submitted = await showDialog<bool>(
    context: context,
    barrierDismissible: true,
    builder: (dialogContext) => _OfferFormDialog(
      title: 'Send your offer',
      subtitle:
          '${request.buyerName} · ${request.deliveryBroadLocation}',
      askingLabel:
          'Offering: KES ${request.offeredPricePerUnit.round()} / ${request.unit}',
      unit: request.unit,
      availableQuantity: request.quantity,
      initialQuantity: request.quantity,
      initialPrice: request.offeredPricePerUnit,
      onSubmit: (quantity, price) {
        final user = ref.read(authProvider);
        if (user == null) return;

        ref.read(buyRequestControllerProvider).submitOffer(
              request: request,
              sellerId: user.id,
              sellerName: user.name,
              pricePerUnit: price,
              quantity: quantity,
              pickupCounty: user.county ?? request.deliveryCounty,
              pickupSubCounty: user.subCounty ?? '',
              pickupArea: user.area ?? '',
            );
      },
    ),
  );

  if (submitted != true || !context.mounted) return;

  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => _OfferSentDialog(
      sellerName: request.buyerName,
      messageSubject: 'buyer',
    ),
  );
}

// ─────────────────────────────────────────────────────────────
// Shared — offer form dialog
// ─────────────────────────────────────────────────────────────

class _OfferFormDialog extends StatefulWidget {
  final String title;
  final String subtitle;
  final String askingLabel;
  final String unit;
  final double availableQuantity;
  final double initialQuantity;
  final double initialPrice;
  final void Function(double quantity, double price) onSubmit;

  const _OfferFormDialog({
    required this.title,
    required this.subtitle,
    required this.askingLabel,
    required this.unit,
    required this.availableQuantity,
    required this.initialQuantity,
    required this.initialPrice,
    required this.onSubmit,
  });

  @override
  State<_OfferFormDialog> createState() => _OfferFormDialogState();
}

class _OfferFormDialogState extends State<_OfferFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _quantity;
  late final TextEditingController _price;

  @override
  void initState() {
    super.initState();
    _quantity = TextEditingController(
        text: _formatNumber(widget.initialQuantity));
    _price = TextEditingController(
        text: widget.initialPrice.round().toString());
    _quantity.addListener(_rebuild);
    _price.addListener(_rebuild);
  }

  void _rebuild() => setState(() {});

  String _formatNumber(double v) =>
      v.truncateToDouble() == v ? v.toStringAsFixed(0) : v.toString();

  @override
  void dispose() {
    _quantity.dispose();
    _price.dispose();
    super.dispose();
  }

  double get _total {
    final q = double.tryParse(_quantity.text.trim()) ?? 0;
    final p = double.tryParse(_price.text.trim()) ?? 0;
    return q * p;
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final q = double.parse(_quantity.text.trim());
    final p = double.parse(_price.text.trim());
    widget.onSubmit(q, p);
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    const theme = RoleTheme.farmer;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: theme.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: theme.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: theme.primaryMuted,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  widget.askingLabel,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: theme.primary,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              TextFormField(
                controller: _quantity,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(
                      RegExp(r'^\d*\.?\d{0,2}')),
                ],
                decoration: InputDecoration(
                  labelText: 'Quantity (${widget.unit})',
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
                validator: (v) {
                  final d = double.tryParse(v?.trim() ?? '');
                  if (d == null || d <= 0) return 'Enter a number';
                  if (d > widget.availableQuantity) {
                    return 'Only ${widget.availableQuantity} available';
                  }
                  return null;
                },
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
                  labelText: 'Price per ${widget.unit} (KES)',
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
                validator: (v) {
                  final d = double.tryParse(v?.trim() ?? '');
                  return (d == null || d <= 0) ? 'Enter a number' : null;
                },
              ),
              if (_total > 0) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: theme.primaryMuted,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Text(
                        'Total',
                        style: TextStyle(
                          fontSize: 13,
                          color: theme.textSecondary,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'KES ${_formatKes(_total)}',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: theme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                        foregroundColor: theme.textSecondary,
                        side: BorderSide(color: theme.border),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                      ),
                      child: const Text('Send offer'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatKes(double v) {
    final s = v.round().toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return buf.toString();
  }
}

// ─────────────────────────────────────────────────────────────
// Shared — success dialog
// ─────────────────────────────────────────────────────────────

class _OfferSentDialog extends StatelessWidget {
  final String sellerName;
  final String messageSubject;

  const _OfferSentDialog({
    required this.sellerName,
    this.messageSubject = 'seller',
  });

  @override
  Widget build(BuildContext context) {
    const theme = RoleTheme.farmer;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 32),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: theme.primary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.check, color: theme.primary, size: 36),
            ),
            const SizedBox(height: 16),
            Text(
              'Offer sent',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: theme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '$sellerName will see your offer. '
              'You will be notified when they respond.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: theme.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
                child: const Text('Done'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
