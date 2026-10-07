import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/enums.dart';
import '../../core/theme/role_theme.dart';
import '../../data/models/listing_model.dart';
import '../../shared/widgets/empty_state.dart';
import '../marketplace/controllers/marketplace_controller.dart';
import 'widgets/admin_queue_card.dart';

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
    const theme = RoleTheme.admin;

    return AdminQueueCard(
      theme: theme,
      icon: Icons.inventory_2_outlined,
      title: listing.resourceType,
      statusChip: AdminStatusChip(
        label: 'Pending review',
        color: theme.accent,
      ),
      meta: '${listing.category} • ${listing.broadLocation}',
      description: listing.description,
      actions: [
        OutlinedButton(
          onPressed: () {
            ref
                .read(marketplaceControllerProvider)
                .updateListingStatus(listing.id, ListingStatus.active);
          },
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(44),
          ),
          child: const Text('Approve'),
        ),
        OutlinedButton(
          onPressed: () {
            ref
                .read(marketplaceControllerProvider)
                .updateListingStatus(listing.id, ListingStatus.paused);
          },
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(44),
          ),
          child: const Text('Needs edits'),
        ),
      ],
    );
  }
}
