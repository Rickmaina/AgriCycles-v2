import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/enums.dart';
import '../../../core/constants/kenya_locations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/extensions.dart';
import '../../../data/models/buy_request_offer_model.dart';
import '../../../data/services/auth_service.dart';
import '../../../domain/validators.dart';
import '../controllers/buy_request_controller.dart';

class BuyRequestDetailScreen extends ConsumerWidget {
  final String requestId;
  const BuyRequestDetailScreen({super.key, required this.requestId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final request = ref.watch(buyRequestByIdProvider(requestId));
    final user = ref.watch(authProvider);

    if (request == null || user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Buy request')),
        body: const Center(child: Text('Request not found')),
      );
    }

    final isBuyer = request.buyerId == user.id;
    final offers = ref.watch(buyRequestOffersProvider(requestId));

    return Scaffold(
      appBar: AppBar(title: const Text('Buy request')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          _SummaryCard(request: request),
          const SizedBox(height: 20),
          if (isBuyer) ...[
            _SectionLabel('Incoming offers (${offers.length})'),
            const SizedBox(height: 10),
            if (offers.isEmpty)
              const _EmptyOffers()
            else
              ...offers.map((o) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _BuyerOfferCard(
                      offer: o,
                      unit: request.unit,
                    ),
                  )),
          ] else ...[
            const _SectionLabel('Send your offer'),
            const SizedBox(height: 10),
            _SellerOfferForm(
              requestId: request.id,
              unit: request.unit,
              suggestedPrice: request.offeredPricePerUnit,
              suggestedQty: request.quantity,
            ),
          ],
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
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final dynamic request;
  const _SummaryCard({required this.request});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            request.resourceType as String,
            style: const TextStyle(
                fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            'from ${request.buyerName}',
            style: const TextStyle(
                fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 14),
          _row('Needs',
              '${request.quantity} ${request.unit}'),
          const SizedBox(height: 6),
          _row('Offering',
              '${(request.offeredPricePerUnit as double).kes} / ${request.unit}'),
          const SizedBox(height: 6),
          _row('Total budget',
              (request.totalBudget as double).kes,
              bold: true),
          const Divider(height: 24, color: AppColors.border),
          _row('Deliver to',
              '${request.deliveryBroadLocation}'),
          if (request.description != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.surfaceAlt,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                request.description as String,
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textSecondary),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _row(String label, String value, {bool bold = false}) {
    return Row(
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 13, color: AppColors.textSecondary)),
        const Spacer(),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 13,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
              color: bold ? AppColors.primary : AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}

class _EmptyOffers extends StatelessWidget {
  const _EmptyOffers();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Row(
        children: [
          Icon(Icons.hourglass_empty, color: AppColors.textMuted),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'No seller offers yet. Sellers are notified when you post.',
              style: TextStyle(
                  fontSize: 12, color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}

class _BuyerOfferCard extends ConsumerWidget {
  final BuyRequestOfferModel offer;
  final String unit;
  const _BuyerOfferCard({required this.offer, required this.unit});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final decided = offer.status != BuyRequestOfferStatus.pending;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  offer.sellerName,
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ),
              _statusChip(offer.status),
            ],
          ),
          const SizedBox(height: 8),
          _line('Price', '${offer.pricePerUnit.kes} / $unit'),
          const SizedBox(height: 4),
          _line('Quantity', '${offer.quantity} $unit'),
          const SizedBox(height: 4),
          _line('Pickup', offer.pickupBroadLocation),
          const SizedBox(height: 4),
          _line('Transport', offer.estimatedTransportCost.kes),
          const SizedBox(height: 6),
          Row(
            children: [
              const Text(
                'Landed cost',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary),
              ),
              const Spacer(),
              Text(
                offer.landedCost.kes,
                style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary),
              ),
            ],
          ),
          if (offer.message != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.surfaceAlt,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                offer.message!,
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textSecondary),
              ),
            ),
          ],
          if (!decided) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => ref
                        .read(buyRequestControllerProvider)
                        .declineOffer(offer),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.danger,
                      side: const BorderSide(color: AppColors.danger),
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
                      context.showSnack(
                          'Offer accepted — seller will contact you');
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

  Widget _line(String label, String value) {
    return Row(
      children: [
        SizedBox(
          width: 84,
          child: Text(
            label,
            style: const TextStyle(
                fontSize: 12, color: AppColors.textMuted),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  Widget _statusChip(BuyRequestOfferStatus status) {
    final color = switch (status) {
      BuyRequestOfferStatus.pending => AppColors.statePending,
      BuyRequestOfferStatus.accepted => AppColors.success,
      BuyRequestOfferStatus.declined => AppColors.danger,
      BuyRequestOfferStatus.withdrawn => AppColors.textMuted,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
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

class _SellerOfferForm extends ConsumerStatefulWidget {
  final String requestId;
  final String unit;
  final double suggestedPrice;
  final double suggestedQty;

  const _SellerOfferForm({
    required this.requestId,
    required this.unit,
    required this.suggestedPrice,
    required this.suggestedQty,
  });

  @override
  ConsumerState<_SellerOfferForm> createState() => _SellerOfferFormState();
}

class _SellerOfferFormState extends ConsumerState<_SellerOfferForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _quantity;
  late final TextEditingController _price;
  final _message = TextEditingController();
  final _subCounty = TextEditingController();
  final _area = TextEditingController();
  String? _county;

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
    _message.dispose();
    _subCounty.dispose();
    _area.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final user = ref.read(authProvider);
    if (user == null) return;

    final request =
        ref.read(buyRequestByIdProvider(widget.requestId));
    if (request == null) return;

    ref.read(buyRequestControllerProvider).submitOffer(
          request: request,
          sellerId: user.id,
          sellerName: user.name,
          pricePerUnit: double.parse(_price.text.trim()),
          quantity: double.parse(_quantity.text.trim()),
          pickupCounty: _county!,
          pickupSubCounty: _subCounty.text.trim(),
          pickupArea: _area.text.trim(),
          message: _message.text.trim().isEmpty
              ? null
              : _message.text.trim(),
        );

    context.showSnack('Offer sent to buyer');
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _quantity,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(
                  RegExp(r'^\d*\.?\d{0,2}')),
            ],
            decoration: InputDecoration(
                labelText: 'Quantity you can supply (${widget.unit})'),
            validator: (v) =>
                Validators.positiveNumber(v, label: 'Quantity'),
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
            maxLines: 2,
            maxLength: 140,
            decoration: const InputDecoration(
              labelText: 'Message (optional)',
            ),
          ),
          const SizedBox(height: 16),
          const _SectionLabel('Your pickup point'),
          const SizedBox(height: 10),
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
            validator: (v) => Validators.requiredText(v, label: 'Area'),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _submit,
            child: const Text('Send offer'),
          ),
        ],
      ),
    );
  }
}
