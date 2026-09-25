import 'package:flutter/material.dart';

import '../../core/constants/enums.dart';
import '../../core/theme/role_theme.dart';

/// Visual status icon for farmer-facing screens.
///
/// Replaces text status labels ("Pending review", "Rejected") with
/// universally-readable icons. Farmers who can't read the word "active"
/// still recognise a green tick.
class FarmerStatusIcon extends StatelessWidget {
  final FarmerStatusTone tone;
  final FarmerStatusSize size;
  final String? label;

  const FarmerStatusIcon({
    super.key,
    required this.tone,
    this.size = FarmerStatusSize.small,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    const theme = RoleTheme.farmer;
    final (icon, color) = _iconAndColor(theme);
    final dimension = size == FarmerStatusSize.large ? 48.0 : 24.0;

    if (label == null) {
      return Icon(icon, color: color, size: dimension);
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: dimension),
        const SizedBox(width: 8),
        Text(
          label!,
          style: TextStyle(
            fontSize: size == FarmerStatusSize.large ? 15 : 13,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }

  (IconData, Color) _iconAndColor(RoleTheme theme) {
    switch (tone) {
      case FarmerStatusTone.waiting:
        return (Icons.schedule, theme.accent);
      case FarmerStatusTone.good:
        return (Icons.check_circle, theme.primary);
      case FarmerStatusTone.notGood:
        return (Icons.cancel, theme.danger);
      case FarmerStatusTone.paused:
        return (Icons.pause_circle_outline, theme.textMuted);
    }
  }
}

enum FarmerStatusTone { waiting, good, notGood, paused }
enum FarmerStatusSize { small, large }

// ─────────────────────────────────────────────────────────────
// Status → tone mappers
// ─────────────────────────────────────────────────────────────

/// Listing status → farmer tone.
FarmerStatusTone farmerToneForListing(ListingStatus status) {
  switch (status) {
    case ListingStatus.pendingReview:
      return FarmerStatusTone.waiting;
    case ListingStatus.active:
      return FarmerStatusTone.good;
    case ListingStatus.sold:
      return FarmerStatusTone.good;
    case ListingStatus.rejected:
      return FarmerStatusTone.notGood;
    case ListingStatus.paused:
      return FarmerStatusTone.paused;
    case ListingStatus.expired:
      return FarmerStatusTone.paused;
  }
}

/// Order status → farmer tone.
FarmerStatusTone farmerToneForOrder(OrderState state) {
  switch (state) {
    case OrderState.requested:
    case OrderState.negotiation:
    case OrderState.accepted:
    case OrderState.paymentSecured:
    case OrderState.pickupScheduled:
    case OrderState.qualityConfirmed:
      return FarmerStatusTone.waiting;
    case OrderState.completed:
    case OrderState.paymentReleased:
    case OrderState.rated:
      return FarmerStatusTone.good;
    case OrderState.declined:
    case OrderState.disputed:
      return FarmerStatusTone.notGood;
    case OrderState.expired:
      return FarmerStatusTone.paused;
  }
}

/// Offer status → farmer tone.
FarmerStatusTone farmerToneForOffer(OfferStatus status) {
  switch (status) {
    case OfferStatus.pending:
    case OfferStatus.countered:
      return FarmerStatusTone.waiting;
    case OfferStatus.accepted:
      return FarmerStatusTone.good;
    case OfferStatus.declined:
      return FarmerStatusTone.notGood;
    case OfferStatus.expired:
      return FarmerStatusTone.paused;
  }
}
