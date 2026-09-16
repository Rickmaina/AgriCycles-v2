import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
      itemBuilder: (_, i) => ListingCard(listing: listings[i]),
    );
  }
}
