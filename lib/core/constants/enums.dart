// ─────────────────────────────────────────────────────────────
// Roles
// ─────────────────────────────────────────────────────────────
enum UserRole { farmer, vet, company, admin }

extension UserRoleLabel on UserRole {
  String get label {
    switch (this) {
      case UserRole.farmer:  return 'Farmer';
      case UserRole.vet:     return 'Vet';
      case UserRole.company: return 'Company';
      case UserRole.admin:   return 'Admin';
    }
  }
}

// ─────────────────────────────────────────────────────────────
// Onboarding
// ─────────────────────────────────────────────────────────────
enum FarmerType { plant, animal, both }

extension FarmerTypeLabel on FarmerType {
  String get label {
    switch (this) {
      case FarmerType.plant:  return 'Plant farmer';
      case FarmerType.animal: return 'Animal farmer';
      case FarmerType.both:   return 'Mixed farmer';
    }
  }
}

// ─────────────────────────────────────────────────────────────
// Verification
// ─────────────────────────────────────────────────────────────
enum VerificationStatus { unverified, pending, approved, rejected, suspended }

enum VerificationType { vet, company, vehicle }

extension VerificationTypeLabel on VerificationType {
  String get label {
    switch (this) {
      case VerificationType.vet:     return 'Veterinarian';
      case VerificationType.company: return 'Company';
      case VerificationType.vehicle: return 'Vehicle';
    }
  }
}

// ─────────────────────────────────────────────────────────────
// Vet visits (Section 6.1) - lighter, no payment/quality stages
// ─────────────────────────────────────────────────────────────
enum VetVisitState { requested, confirmed, declined, completed, rated }

extension VetVisitStateLabel on VetVisitState {
  String get label {
    switch (this) {
      case VetVisitState.requested: return 'Requested';
      case VetVisitState.confirmed: return 'Confirmed';
      case VetVisitState.declined:  return 'Declined';
      case VetVisitState.completed: return 'Completed';
      case VetVisitState.rated:     return 'Rated';
    }
  }
}

// ─────────────────────────────────────────────────────────────
// Marketplace order (Section 6.2) - full commerce lifecycle
// ─────────────────────────────────────────────────────────────
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
      case OrderState.requested:        return 'Requested';
      case OrderState.negotiation:      return 'Negotiation';
      case OrderState.accepted:         return 'Accepted';
      case OrderState.paymentSecured:   return 'Payment secured';
      case OrderState.pickupScheduled:  return 'Pickup scheduled';
      case OrderState.qualityConfirmed: return 'Quality confirmed';
      case OrderState.completed:        return 'Completed';
      case OrderState.paymentReleased:  return 'Payment released';
      case OrderState.rated:            return 'Rated';
      case OrderState.declined:         return 'Declined';
      case OrderState.expired:          return 'Expired';
      case OrderState.disputed:         return 'Disputed';
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

// ─────────────────────────────────────────────────────────────
// Logistics (Section 16.3) - Admin-mediated pickup sub-state
// ─────────────────────────────────────────────────────────────
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

// ─────────────────────────────────────────────────────────────
// Offers
// ─────────────────────────────────────────────────────────────
enum OfferStatus { pending, countered, accepted, declined, expired }

extension OfferStatusLabel on OfferStatus {
  String get label {
    switch (this) {
      case OfferStatus.pending:   return 'Pending';
      case OfferStatus.countered: return 'Countered';
      case OfferStatus.accepted:  return 'Accepted';
      case OfferStatus.declined:  return 'Declined';
      case OfferStatus.expired:   return 'Expired';
    }
  }
}

// ─────────────────────────────────────────────────────────────
// Listings
// ─────────────────────────────────────────────────────────────
enum ListingStatus { active, paused, sold, expired }
