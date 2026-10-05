import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/enums.dart';
import '../../../core/theme/role_theme.dart';
import '../../../data/models/listing_model.dart';
import '../../../data/services/auth_service.dart';
import '../../../domain/transport_estimator.dart';
import '../../../shared/widgets/farmer_action_button.dart';
import '../../../shared/widgets/verification_badge.dart';
import 'make_offer_screen.dart';

/// Role-aware listing detail.
///
/// Farmer sees hero photo, big price, two big actions.
/// Company sees the same listing with additional metadata and distance
/// from their registered base county.
class ListingDetailScreen extends ConsumerStatefulWidget {
  final ListingModel listing;
  const ListingDetailScreen({super.key, required this.listing});

  @override
  ConsumerState<ListingDetailScreen> createState() =>
      _ListingDetailScreenState();
}

class _ListingDetailScreenState extends ConsumerState<ListingDetailScreen> {
  bool _moreOpen = false;

  ListingModel get listing => widget.listing;

  @override
  Widget build(BuildContext context) {
    const theme = RoleTheme.farmer;
    final user = ref.watch(authProvider);
    final isCompany = user?.role == UserRole.company;
    final baseCounty = user?.county ?? '';

    final km = baseCounty.isEmpty
        ? null
        : TransportEstimator.distanceKm(
            pickupCounty: baseCounty,
            deliveryCounty: listing.county,
          );

    return Scaffold(
      backgroundColor: theme.background,
      appBar: AppBar(
        backgroundColor: theme.surface,
        foregroundColor: theme.textPrimary,
        elevation: 0,
        title: Text(listing.resourceType),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _hero(theme),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                listing.resourceType,
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                  color: theme.textPrimary,
                                  height: 1.2,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            VerificationBadge(
                                status: listing.sellerVerification),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _priceLine(),
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: theme.primary,
                          ),
                        ),
                        const SizedBox(height: 20),
                        _infoRow(
                          theme,
                          Icons.agriculture_outlined,
                          'Seller',
                          listing.sellerName,
                        ),
                        const SizedBox(height: 10),
                        _infoRow(
                          theme,
                          Icons.inventory_2_outlined,
                          'Available',
                          '${listing.quantity} ${listing.unit}',
                        ),
                        const SizedBox(height: 10),
                        _infoRow(
                          theme,
                          Icons.location_on_outlined,
                          'Pickup area',
                          listing.broadLocation,
                        ),
                        if (km != null && km > 0) ...[
                          const SizedBox(height: 10),
                          _infoRow(
                            theme,
                            Icons.route_outlined,
                            isCompany ? 'From your base' : 'Distance',
                            '${km.toStringAsFixed(0)} km',
                          ),
                        ],
                        const SizedBox(height: 20),
                        if (listing.description != null &&
                            listing.description!.isNotEmpty)
                          _description(theme, listing.description!),
                        if (isCompany) ...[
                          const SizedBox(height: 20),
                          _companyNote(theme),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: Column(
                children: [
                  FarmerActionButton(
                    label: isCompany ? 'Make an offer' : 'Give a price',
                    icon: Icons.send,
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => MakeOfferScreen(listing: listing),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _hero(RoleTheme theme) {
    return Container(
      height: 220,
      color: theme.primaryMuted,
      alignment: Alignment.center,
      child: listing.photoUrl == null
          ? Icon(
              _categoryIcon(),
              size: 96,
              color: theme.primary,
            )
          : Image.network(
              listing.photoUrl!,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Icon(
                _categoryIcon(),
                size: 96,
                color: theme.primary,
              ),
            ),
    );
  }

  IconData _categoryIcon() {
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

  Widget _infoRow(
    RoleTheme theme,
    IconData icon,
    String label,
    String value,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: theme.textMuted),
        const SizedBox(width: 12),
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: TextStyle(
                fontSize: 13, color: theme.textSecondary),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: theme.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _description(RoleTheme theme, String text) {
    return GestureDetector(
      onTap: () => setState(() => _moreOpen = !_moreOpen),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: theme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'More details',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: theme.textPrimary,
                  ),
                ),
                const Spacer(),
                Icon(
                  _moreOpen ? Icons.expand_less : Icons.expand_more,
                  size: 20,
                  color: theme.textMuted,
                ),
              ],
            ),
            if (_moreOpen) ...[
              const SizedBox(height: 10),
              Text(
                text,
                style: TextStyle(
                  fontSize: 13,
                  color: theme.textSecondary,
                  height: 1.5,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _companyNote(RoleTheme theme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.primaryMuted,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 16, color: theme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Contact details are shared after the seller accepts your offer.',
              style: TextStyle(
                fontSize: 12,
                color: theme.textSecondary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _priceLine() {
    final n = listing.pricePerUnit.round();
    final s = n.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return 'KES ${buf.toString()} / ${listing.unit}';
  }
}
