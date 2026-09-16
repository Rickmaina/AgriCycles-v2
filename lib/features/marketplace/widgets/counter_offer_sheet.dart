import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/models/offer_model.dart';
import '../../../domain/validators.dart';
import '../controllers/marketplace_controller.dart';

class CounterOfferSheet extends ConsumerStatefulWidget {
  final OfferModel offer;
  final String byUserId;
  final String byName;
  final double defaultQuantity;
  final double defaultPrice;

  const CounterOfferSheet({
    super.key,
    required this.offer,
    required this.byUserId,
    required this.byName,
    required this.defaultQuantity,
    required this.defaultPrice,
  });

  static Future<bool?> show(
    BuildContext context, {
    required OfferModel offer,
    required String byUserId,
    required String byName,
    required double defaultQuantity,
    required double defaultPrice,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: CounterOfferSheet(
          offer: offer,
          byUserId: byUserId,
          byName: byName,
          defaultQuantity: defaultQuantity,
          defaultPrice: defaultPrice,
        ),
      ),
    );
  }

  @override
  ConsumerState<CounterOfferSheet> createState() =>
      _CounterOfferSheetState();
}

class _CounterOfferSheetState extends ConsumerState<CounterOfferSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _quantity;
  late final TextEditingController _price;
  final _message = TextEditingController();

  @override
  void initState() {
    super.initState();
    _quantity =
        TextEditingController(text: _formatQty(widget.defaultQuantity));
    _price = TextEditingController(
        text: widget.defaultPrice.toStringAsFixed(0));
  }

  String _formatQty(double q) =>
      q.truncateToDouble() == q ? q.toStringAsFixed(0) : q.toString();

  @override
  void dispose() {
    _quantity.dispose();
    _price.dispose();
    _message.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    ref.read(marketplaceControllerProvider).counterOffer(
          offer: widget.offer,
          byUserId: widget.byUserId,
          byName: widget.byName,
          pricePerUnit: double.parse(_price.text.trim()),
          quantity: double.parse(_quantity.text.trim()),
          message: _message.text.trim().isEmpty
              ? null
              : _message.text.trim(),
        );
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Counter-offer',
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              const Text(
                'Propose different terms. The other party gets one turn back.',
                style: TextStyle(
                    fontSize: 12, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _quantity,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(
                      RegExp(r'^\d*\.?\d{0,2}')),
                ],
                decoration:
                    const InputDecoration(labelText: 'Quantity'),
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
              TextField(
                controller: _message,
                maxLines: 2,
                maxLength: 140,
                decoration: const InputDecoration(
                  labelText: 'Message (optional)',
                  hintText: 'e.g. Price is firm, but I can cover transport',
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _submit,
                child: const Text('Send counter-offer'),
              ),
              const SizedBox(height: 4),
              Center(
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
