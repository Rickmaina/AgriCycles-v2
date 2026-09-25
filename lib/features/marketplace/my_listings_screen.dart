import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../data/models/listing_model.dart';
import '../../data/services/auth_service.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/listing_card.dart';
import 'controllers/marketplace_controller.dart';

class MyListingsScreen extends ConsumerWidget {
  const MyListingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider);
    if (user == null) return const SizedBox.shrink();

    final listings = ref.watch(myListingsProvider(user.id));

    if (listings.isEmpty) {
      return const EmptyState(
        icon: Icons.inventory_2_outlined,
        title: "You haven't listed anything yet",
        subtitle: 'Tap the + button to add your first listing.',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: listings.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) => _MyListingCard(listing: listings[i]),
    );
  }
}

class _MyListingCard extends StatelessWidget {
  final ListingModel listing;

  const _MyListingCard({required this.listing});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _showListingDetails(context),
        child: ListingCard(listing: listing),
      ),
    );
  }

  void _showListingDetails(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(listing.resourceType),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${listing.quantity} ${listing.unit} • ${listing.category}'),
            const SizedBox(height: 8),
            Text(listing.broadLocation),
            if (listing.description != null) ...[
              const SizedBox(height: 12),
              Text(listing.description!),
            ],
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
}
