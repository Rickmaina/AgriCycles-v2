import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/extensions.dart';
import '../../../data/models/offer_model.dart';
import '../controllers/marketplace_controller.dart';

class OfferHistory extends ConsumerWidget {
  final OfferModel offer;
  final String unit;
  final String? currentActorId;
  final String? currentActorName;

  const OfferHistory({
    super.key,
    required this.offer,
    required this.unit,
    this.currentActorId,
    this.currentActorName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final counters = ref.watch(counterOffersForProvider(offer.id));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _entry(
          byName: offer.buyerName,
          label: 'Original offer',
          pricePerUnit: offer.pricePerUnit,
          quantity: offer.quantity,
          message: offer.message,
          createdAt: offer.createdAt,
          isOpening: true,
        ),
        for (final c in counters)
          _entry(
            byName: c.byName,
            label: 'Counter',
            pricePerUnit: c.pricePerUnit,
            quantity: c.quantity,
            message: c.message,
            createdAt: c.createdAt,
            isOpening: false,
          ),
        if (currentActorId != null && currentActorName != null) _turnHint(),
      ],
    );
  }

  Widget _entry({
    required String byName,
    required String label,
    required double pricePerUnit,
    required double quantity,
    required String? message,
    required DateTime createdAt,
    required bool isOpening,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(top: 6, right: 10),
            decoration: BoxDecoration(
              color: isOpening ? AppColors.primary : AppColors.info,
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      byName,
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      label,
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textMuted),
                    ),
                    const Spacer(),
                    Text(
                      createdAt.relative,
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textMuted),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${pricePerUnit.kes} / $unit  •  $quantity $unit',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (message != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    message,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _turnHint() {
    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.hourglass_top, size: 16, color: AppColors.warning),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Waiting on $currentActorName to respond',
              style:
                  const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}
