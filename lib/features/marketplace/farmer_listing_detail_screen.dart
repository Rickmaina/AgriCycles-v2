import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/enums.dart';
import '../../core/theme/role_theme.dart';
import '../../data/models/listing_model.dart';
import '../../data/models/user_model.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/seed/seed_data.dart';
import '../../shared/widgets/farmer_action_button.dart';
import '../../shared/widgets/farmer_distance.dart';
import 'make_offer_screen.dart';

/// Farmer listing detail: hero photo, large price, two actions, details collapsed.
class FarmerListingDetailScreen extends ConsumerStatefulWidget {
  final ListingModel listing;

  const FarmerListingDetailScreen({super.key, required this.listing});

  @override
  ConsumerState<FarmerListingDetailScreen> createState() =>
      _FarmerListingDetailScreenState();
}

class _FarmerListingDetailScreenState
    extends ConsumerState<FarmerListingDetailScreen> {
  bool _moreOpen = false;

  ListingModel get listing => widget.listing;

  @override
  Widget build(BuildContext context) {
    const theme = RoleTheme.farmer;
    final user = ref.watch(authProvider);
    final distance = farmerDistanceLabel(
      listing: listing,
      from: viewerLocationOf(user),
    );
    final verified = listing.sellerVerification == VerificationStatus.approved;
    final isOwn = user?.id == listing.sellerId;

    return Scaffold(
      backgroundColor: theme.background,
      appBar: AppBar(
        backgroundColor: theme.surface,
        foregroundColor: theme.textPrimary,
        elevation: 0,
        title: Text(listing.resourceType),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              children: [
                _hero(theme),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _priceLine(),
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: theme.primary,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Icon(Icons.location_on, size: 18, color: theme.primary),
                          const SizedBox(width: 4),
                          Text(
                            distance,
                            style: TextStyle(
                              fontSize: 16,
                              color: theme.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: theme.primaryMuted,
                            child: Text(
                              listing.sellerName.isEmpty
                                  ? '?'
                                  : listing.sellerName[0].toUpperCase(),
                              style: TextStyle(
                                color: theme.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              listing.sellerName,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: theme.textPrimary,
                              ),
                            ),
                          ),
                          if (verified)
                            Icon(Icons.check_circle, color: theme.primary),
                        ],
                      ),
                      const SizedBox(height: 16),
                      InkWell(
                        onTap: () => setState(() => _moreOpen = !_moreOpen),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            children: [
                              Text(
                                'More details',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: theme.textPrimary,
                                ),
                              ),
                              const Spacer(),
                              Icon(
                                _moreOpen
                                    ? Icons.expand_less
                                    : Icons.expand_more,
                                color: theme.textMuted,
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (_moreOpen) ...[
                        _detailRow(theme, 'Kind', listing.category),
                        _detailRow(
                          theme,
                          'How much',
                          '${_qty(listing.quantity)} ${listing.unit}',
                        ),
                        _detailRow(theme, 'Place', listing.broadLocation),
                        if (listing.description != null &&
                            listing.description!.isNotEmpty)
                          _detailRow(theme, 'Notes', listing.description!),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (!isOwn)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: Column(
                children: [
                  FarmerActionButton(
                    label: 'Give a price',
                    icon: Icons.payments_outlined,
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => MakeOfferScreen(listing: listing),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 10),
                  FarmerActionButton(
                    label: 'Call seller',
                    icon: Icons.call_outlined,
                    variant: FarmerButtonVariant.secondary,
                    onPressed: () => _callSeller(context, theme),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _hero(RoleTheme theme) {
    return AspectRatio(
      aspectRatio: 16 / 10,
      child: ColoredBox(
        color: theme.primaryMuted,
        child: listing.photoUrl == null
            ? Icon(_iconForCategory(), size: 88, color: theme.primary)
            : Image.network(
                listing.photoUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    Icon(_iconForCategory(), size: 88, color: theme.primary),
              ),
      ),
    );
  }

  Widget _detailRow(RoleTheme theme, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        '$label: $value',
        style: TextStyle(fontSize: 14, color: theme.textSecondary, height: 1.3),
      ),
    );
  }

  void _callSeller(BuildContext context, RoleTheme theme) {
    UserModel? seller;
    for (final u in SeedData.users) {
      if (u.id == listing.sellerId) {
        seller = u;
        break;
      }
    }
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Call seller'),
        content: Text(
          seller == null
              ? 'The number is shared after you agree a price.'
              : 'Call ${listing.sellerName} on ${seller.phone}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  IconData _iconForCategory() {
    switch (listing.category) {
      case 'Crop residue':
        return Icons.grass;
      case 'Animal waste':
        return Icons.pets;
      case 'By-product':
        return Icons.inventory_2_outlined;
      default:
        return Icons.eco;
    }
  }

  String _priceLine() {
    final price = listing.pricePerUnit.round();
    return 'KES ${_formatKes(price)} / ${listing.unit}';
  }

  String _qty(double v) =>
      v.truncateToDouble() == v ? v.toStringAsFixed(0) : v.toString();

  String _formatKes(int amount) {
    final s = amount.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return buf.toString();
  }
}
