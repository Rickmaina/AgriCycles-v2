import 'package:flutter/material.dart';

import '../../core/theme/role_theme.dart';
import '../../data/models/listing_model.dart';

/// Farmer-facing listing card. Photo-first, one price, one location.
///
/// The card shows the minimum a farmer needs to decide whether to tap:
/// what it is, what it costs, and where it is. Everything else is one
/// tap away. Contact details are never on the card (Section 8.1).
class ListingCard extends StatelessWidget {
  final ListingModel listing;
  final VoidCallback? onTap;

  final String? distanceLabel;

  const ListingCard({
    super.key,
    required this.listing,
    this.onTap,
    this.distanceLabel,
  });

  @override
  Widget build(BuildContext context) {
    const theme = RoleTheme.farmer;

    return Material(
      color: theme.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: theme.border, width: 1.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(flex: 6, child: _photo(theme)),
              Expanded(
                flex: 4,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        listing.resourceType,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: theme.textPrimary,
                          height: 1.2,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        _priceLine(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: theme.primary,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.location_on_outlined,
                              size: 14, color: theme.textMuted),
                          const SizedBox(width: 2),
                          Expanded(
                            child: Text(
                              distanceLabel ?? listing.county,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13,
                                color: theme.textSecondary,
                                height: 1.1,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _photo(RoleTheme theme) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
      child: Container(
        color: theme.primaryMuted,
        child: listing.photoUrl == null
            ? Center(
                child: Icon(
                  _iconForCategory(),
                  size: 56,
                  color: theme.primary,
                ),
              )
            : Image.network(
                listing.photoUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Center(
                  child: Icon(
                    _iconForCategory(),
                    size: 56,
                    color: theme.primary,
                  ),
                ),
              ),
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
    final formatted = _formatKes(price);
    return 'KES $formatted / ${listing.unit}';
  }

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
