enum UserRole { farmer, vet, company, admin }

extension UserRoleLabel on UserRole {
  String get label {
    switch (this) {
      case UserRole.farmer:
        return 'Farmer';
      case UserRole.vet:
        return 'Vet';
      case UserRole.company:
        return 'Company';
      case UserRole.admin:
        return 'Admin';
    }
  }
}

enum FarmerType { plant, animal, both }

extension FarmerTypeLabel on FarmerType {
  String get label {
    switch (this) {
      case FarmerType.plant:
        return 'Plant farmer';
      case FarmerType.animal:
        return 'Animal farmer';
      case FarmerType.both:
        return 'Mixed farmer';
    }
  }
}

enum VerificationStatus { unverified, pending, approved, rejected, suspended }

enum VerificationType { vet, company, vehicle }

extension VerificationTypeLabel on VerificationType {
  String get label {
    switch (this) {
      case VerificationType.vet:
        return 'Veterinarian';
      case VerificationType.company:
        return 'Company';
      case VerificationType.vehicle:
        return 'Vehicle';
    }
  }
}

enum VetVisitState { requested, confirmed, declined, completed, rated }

extension VetVisitStateLabel on VetVisitState {
  String get label {
    switch (this) {
      case VetVisitState.requested:
        return 'Requested';
      case VetVisitState.confirmed:
        return 'Confirmed';
      case VetVisitState.declined:
        return 'Declined';
      case VetVisitState.completed:
        return 'Completed';
      case VetVisitState.rated:
        return 'Rated';
    }
  }
}

enum OrderState {
  requested,
  negotiation,
  accepted,
  paymentSecured,
  pickupScheduled,
  qualityConfirmed,
  completed,
  paymentReleased,
  rated,
  declined,
  expired,
  disputed,
}

extension OrderStateLabel on OrderState {
  String get label {
    switch (this) {
      case OrderState.requested:
        return 'Requested';
      case OrderState.negotiation:
        return 'Negotiation';
      case OrderState.accepted:
        return 'Accepted';
      case OrderState.paymentSecured:
        return 'Payment secured';
      case OrderState.pickupScheduled:
        return 'Pickup scheduled';
      case OrderState.qualityConfirmed:
        return 'Quality confirmed';
      case OrderState.completed:
        return 'Completed';
      case OrderState.paymentReleased:
        return 'Payment released';
      case OrderState.rated:
        return 'Rated';
      case OrderState.declined:
        return 'Declined';
      case OrderState.expired:
        return 'Expired';
      case OrderState.disputed:
        return 'Disputed';
    }
  }

  bool get isTerminal =>
      this == OrderState.rated ||
      this == OrderState.declined ||
      this == OrderState.expired ||
      this == OrderState.disputed;

  bool get isBranch =>
      this == OrderState.declined ||
      this == OrderState.expired ||
      this == OrderState.disputed;
}

enum LogisticsState {
  awaitingAdminAssignment,
  pickupAssigned,
  inTransit,
  delivered,
}

extension LogisticsStateLabel on LogisticsState {
  String get label {
    switch (this) {
      case LogisticsState.awaitingAdminAssignment:
        return 'Awaiting Admin assignment';
      case LogisticsState.pickupAssigned:
        return 'Pickup assigned';
      case LogisticsState.inTransit:
        return 'In transit';
      case LogisticsState.delivered:
        return 'Delivered';
    }
  }
}

enum OfferStatus { pending, countered, accepted, declined, expired }

extension OfferStatusLabel on OfferStatus {
  String get label {
    switch (this) {
      case OfferStatus.pending:
        return 'Pending';
      case OfferStatus.countered:
        return 'Countered';
      case OfferStatus.accepted:
        return 'Accepted';
      case OfferStatus.declined:
        return 'Declined';
      case OfferStatus.expired:
        return 'Expired';
    }
  }
}

enum ListingStatus { active, paused, sold, expired }

enum BuyRequestStatus { open, matched, closed, expired }

extension BuyRequestStatusLabel on BuyRequestStatus {
  String get label {
    switch (this) {
      case BuyRequestStatus.open:
        return 'Open';
      case BuyRequestStatus.matched:
        return 'Matched';
      case BuyRequestStatus.closed:
        return 'Closed';
      case BuyRequestStatus.expired:
        return 'Expired';
    }
  }
}

enum BuyRequestOfferStatus { pending, accepted, declined, withdrawn }

extension BuyRequestOfferStatusLabel on BuyRequestOfferStatus {
  String get label {
    switch (this) {
      case BuyRequestOfferStatus.pending:
        return 'Pending';
      case BuyRequestOfferStatus.accepted:
        return 'Accepted';
      case BuyRequestOfferStatus.declined:
        return 'Declined';
      case BuyRequestOfferStatus.withdrawn:
        return 'Withdrawn';
    }
  }
}

enum PreOrderStatus { open, locked, completed, cancelled, expired }

extension PreOrderStatusLabel on PreOrderStatus {
  String get label {
    switch (this) {
      case PreOrderStatus.open:
        return 'Open';
      case PreOrderStatus.locked:
        return 'Locked';
      case PreOrderStatus.completed:
        return 'Completed';
      case PreOrderStatus.cancelled:
        return 'Cancelled';
      case PreOrderStatus.expired:
        return 'Expired';
    }
  }
}

enum ContributionStatus { committed, confirmed, rejected, withdrawn }

extension ContributionStatusLabel on ContributionStatus {
  String get label {
    switch (this) {
      case ContributionStatus.committed:
        return 'Committed';
      case ContributionStatus.confirmed:
        return 'Confirmed';
      case ContributionStatus.rejected:
        return 'Rejected';
      case ContributionStatus.withdrawn:
        return 'Withdrawn';
    }
  }
}

enum DisputeIssueType { quality, quantity, payment, pickup, other }

extension DisputeIssueTypeLabel on DisputeIssueType {
  String get label {
    switch (this) {
      case DisputeIssueType.quality:
        return 'Quality';
      case DisputeIssueType.quantity:
        return 'Quantity';
      case DisputeIssueType.payment:
        return 'Payment';
      case DisputeIssueType.pickup:
        return 'Pickup';
      case DisputeIssueType.other:
        return 'Other';
    }
  }
}

enum DisputeStatus { open, underReview, resolved }

extension DisputeStatusLabel on DisputeStatus {
  String get label {
    switch (this) {
      case DisputeStatus.open:
        return 'Open';
      case DisputeStatus.underReview:
        return 'Under review';
      case DisputeStatus.resolved:
        return 'Resolved';
    }
  }
}

enum DisputeResolution {
  favourBuyer,
  favourSeller,
  split,
  withdrawn,
}

extension DisputeResolutionLabel on DisputeResolution {
  String get label {
    switch (this) {
      case DisputeResolution.favourBuyer:
        return 'Refund buyer';
      case DisputeResolution.favourSeller:
        return 'Release to seller';
      case DisputeResolution.split:
        return 'Split';
      case DisputeResolution.withdrawn:
        return 'Withdrawn';
    }
  }
}
