import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/enums.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/listing_model.dart';
import '../../shared/widgets/empty_state.dart';
import '../marketplace/controllers/marketplace_controller.dart';

class PendingReviewQueueScreen extends ConsumerWidget {
  const PendingReviewQueueScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final list = ref.watch(pendingReviewListingsProvider);

    return list.isEmpty
        ? const EmptyState(
            icon: Icons.pending_actions_outlined,
            title: 'No listings waiting for review',
            subtitle: 'New “Other” and unrecognized listings will appear here.',
          )
        : ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            itemCount: list.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, i) => _ReviewCard(listing: list[i]),
          );
  }
}

class _ReviewCard extends ConsumerWidget {
  final ListingModel listing;

  const _ReviewCard({required this.listing});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  'Pending review',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.warning,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${listing.category} • ${listing.broadLocation}',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          if (listing.description != null) ...[
            Text(
              listing.description!,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 12),
          ],
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    ref
                        .read(marketplaceControllerProvider)
                        .updateListingStatus(listing.id, ListingStatus.active);
                  },
                  child: const Text('Approve'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextButton(
                  onPressed: () {
                    ref
                        .read(marketplaceControllerProvider)
                        .updateListingStatus(listing.id, ListingStatus.paused);
                  },
                  child: const Text('Needs edits'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
