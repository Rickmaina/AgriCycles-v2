import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/enums.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/extensions.dart';
import '../../data/models/listing_model.dart';
import '../../data/models/offer_model.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/order_service.dart';
import '../../shared/widgets/empty_state.dart';
import 'controllers/marketplace_controller.dart';

class IncomingOffersScreen extends ConsumerWidget {
  const IncomingOffersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider);
    if (user == null) return const SizedBox.shrink();

    final offers = ref.watch(incomingOffersProvider(user.id));
    final listings = ref.watch(allListingsProvider);

    if (offers.isEmpty) {
      return const EmptyState(
        icon: Icons.mark_email_unread_outlined,
        title: 'No incoming offers yet',
        subtitle: 'Buyers will show up here when they bid on your listings.',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: offers.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) {
        final offer = offers[i];
        final listing = listings.firstWhere(
          (l) => l.id == offer.listingId,
          orElse: () => listings.first,
        );
        return _OfferCard(offer: offer, listing: listing);
      },
    );
  }
}

class _OfferCard extends ConsumerWidget {
  final OfferModel offer;
  final ListingModel listing;

  const _OfferCard({required this.offer, required this.listing});

  void _accept(BuildContext context, WidgetRef ref) {
    final seller = ref.read(authProvider);
    if (seller == null) return;

    ref.read(ordersProvider.notifier).createFromOffer(
          listingId: offer.listingId,
          resourceType: listing.resourceType,
          unit: listing.unit,
          buyerId: offer.buyerId,
          buyerName: offer.buyerName,
          sellerId: seller.id,
          sellerName: seller.name,
          quantity: offer.quantity,
          pricePerUnit: offer.pricePerUnit,
          pickupCounty: listing.county,
          pickupSubCounty: listing.subCounty,
          pickupArea: listing.area,
          deliveryCounty: offer.deliveryCounty,
          deliverySubCounty: offer.deliverySubCounty,
          deliveryArea: offer.deliveryArea,
          deliveryNotes: offer.deliveryNotes,
        );

    ref
        .read(marketplaceControllerProvider)
        .updateOfferStatus(offer.id, OfferStatus.accepted);

    context.showSnack('Offer accepted — order created');
  }

  void _decline(BuildContext context, WidgetRef ref) {
    ref
        .read(marketplaceControllerProvider)
        .updateOfferStatus(offer.id, OfferStatus.declined);
    context.showSnack('Offer declined');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final decided = offer.status != OfferStatus.pending;

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
                  listing.resourceType,
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ),
              _StatusChip(status: offer.status),
            ],
          ),
          const SizedBox(height: 8),
          _line('From', offer.buyerName),
          const SizedBox(height: 4),
          _line('Offer', '${offer.pricePerUnit.kes} / ${listing.unit}'),
          const SizedBox(height: 4),
          _line(
            'Quantity',
            '${offer.quantity} ${listing.unit}  •  total ${(offer.quantity * offer.pricePerUnit).kes}',
          ),
          const SizedBox(height: 4),
          _line(
            'Deliver to',
            '${offer.deliveryArea}, ${offer.deliverySubCounty} (${offer.deliveryCounty})',
          ),
          if (offer.deliveryNotes != null) ...[
            const SizedBox(height: 4),
            _line('Notes', offer.deliveryNotes!),
          ],
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
                    onPressed: () => _decline(context, ref),
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
                    onPressed: () => _accept(context, ref),
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 72,
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
}

class _StatusChip extends StatelessWidget {
  final OfferStatus status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      OfferStatus.pending => AppColors.statePending,
      OfferStatus.countered => AppColors.stateActive,
      OfferStatus.accepted => AppColors.success,
      OfferStatus.declined => AppColors.danger,
      OfferStatus.expired => AppColors.textMuted,
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
