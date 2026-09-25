import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/enums.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/extensions.dart';
import '../../data/models/listing_model.dart';
import '../../data/models/offer_model.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/marketplace_service.dart';
import '../../data/services/order_service.dart';
import '../../shared/widgets/empty_state.dart';
import 'controllers/marketplace_controller.dart';
import 'widgets/counter_offer_sheet.dart';
import 'widgets/offer_history.dart';

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

void _showOfferDialog(
    BuildContext context, OfferModel offer, ListingModel listing) {
  showDialog<void>(
    context: context,
    builder: (_) => AlertDialog(
      title: Text(listing.resourceType),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Buyer: ${offer.buyerName}'),
          const SizedBox(height: 8),
          Text('Quantity: ${offer.quantity} ${listing.unit}'),
          const SizedBox(height: 8),
          Text('Price: ${(offer.pricePerUnit).kes} / ${listing.unit}'),
          const SizedBox(height: 8),
          Text(
              'Delivery: ${offer.deliveryArea}, ${offer.deliverySubCounty} (${offer.deliveryCounty})'),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    ),
  );
}

class _OfferCard extends ConsumerWidget {
  final OfferModel offer;
  final ListingModel listing;

  const _OfferCard({required this.offer, required this.listing});

  Future<void> _counter(BuildContext context, WidgetRef ref) async {
    final seller = ref.read(authProvider);
    if (seller == null) return;

    final counters = ref.read(counterOffersForProvider(offer.id));
    final latestPrice =
        counters.isEmpty ? offer.pricePerUnit : counters.last.pricePerUnit;
    final latestQty =
        counters.isEmpty ? offer.quantity : counters.last.quantity;

    final ok = await CounterOfferSheet.show(
      context,
      offer: offer,
      byUserId: seller.id,
      byName: seller.name,
      defaultQuantity: latestQty,
      defaultPrice: latestPrice,
    );
    if (ok == true && context.mounted) {
      context.showSnack('Counter-offer sent');
    }
  }

  void _accept(BuildContext context, WidgetRef ref) {
    final seller = ref.read(authProvider);
    if (seller == null) return;

    final counters = ref.read(counterOffersForProvider(offer.id));
    final latest = counters.isEmpty ? null : counters.last;
    final agreedQuantity = latest?.quantity ?? offer.quantity;
    final agreedPrice = latest?.pricePerUnit ?? offer.pricePerUnit;

    ref.read(ordersProvider.notifier).createFromOffer(
          listingId: offer.listingId,
          resourceType: listing.resourceType,
          unit: listing.unit,
          buyerId: offer.buyerId,
          buyerName: offer.buyerName,
          sellerId: seller.id,
          sellerName: seller.name,
          quantity: agreedQuantity,
          pricePerUnit: agreedPrice,
          pickupLocation: listing.location,
          pickupCounty: listing.county,
          pickupSubCounty: listing.subCounty,
          pickupArea: listing.area,
          deliveryLocation: offer.deliveryLocation,
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
    final user = ref.read(authProvider);
    if (user == null) return const SizedBox.shrink();

    final controller = ref.read(marketplaceControllerProvider);
    final decided = offer.status == OfferStatus.accepted ||
        offer.status == OfferStatus.declined;
    final expired = ref.read(marketplaceProvider.notifier).isExpired(offer);
    final capped = controller.isNegotiationClosed(offer);
    final myTurn = controller.canActorCounter(
      offer: offer,
      actorId: user.id,
    );
    final nextId = controller.nextActorId(offer);
    final nextName =
        nextId == offer.buyerId ? offer.buyerName : offer.sellerName;

    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _showOfferDialog(context, offer, listing),
        child: Container(
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
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  _StatusChip(status: offer.status),
                ],
              ),
              const SizedBox(height: 12),
              OfferHistory(
                offer: offer,
                unit: listing.unit,
                currentActorId: decided || capped || expired ? null : nextId,
                currentActorName:
                    decided || capped || expired ? null : nextName,
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
              if (expired) ...[
                const SizedBox(height: 12),
                _banner(
                  icon: Icons.schedule,
                  color: AppColors.textMuted,
                  text: 'Negotiation expired (7-day limit)',
                ),
              ] else if (capped && !decided) ...[
                const SizedBox(height: 12),
                _banner(
                  icon: Icons.block,
                  color: AppColors.danger,
                  text: 'Counter-offer cap reached ($kMaxCounterRounds rounds)',
                ),
              ],
              if (!decided && !expired && !capped) ...[
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
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: myTurn ? () => _counter(context, ref) : null,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: const BorderSide(color: AppColors.primary),
                          minimumSize: const Size.fromHeight(44),
                        ),
                        child: const Text('Counter'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: myTurn ? () => _accept(context, ref) : null,
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
        ),
      ),
    );
  }

  Widget _banner({
    required IconData icon,
    required Color color,
    required String text,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style:
                  const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ),
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
            style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
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
