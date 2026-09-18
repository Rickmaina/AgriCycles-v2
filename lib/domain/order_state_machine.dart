import '../core/constants/enums.dart';

/// Defines the valid order lifecycle from Section 6.2.
///
/// Every state transition in the app goes through this class. Screens
/// ask "what can the current actor do next?" and get back an [Action]
/// or null. They never invent transitions themselves.
///
/// This is pure Dart - no Flutter, no widgets - so it is trivially
/// unit-testable and portable to a backend later.
class OrderStateMachine {
  OrderStateMachine._();

  /// The canonical linear flow for a healthy order.
  /// Branch states (declined, expired, disputed) are NOT in this list -
  /// they are rendered as terminal branches (see [isBranch]).
  static const List<OrderState> linearFlow = [
    OrderState.requested,
    OrderState.negotiation,
    OrderState.accepted,
    OrderState.paymentSecured,
    OrderState.pickupScheduled,
    OrderState.qualityConfirmed,
    OrderState.completed,
    OrderState.paymentReleased,
    OrderState.rated,
  ];

  /// Index into [linearFlow] for a non-branch state; -1 for branch states.
  static int stepIndex(OrderState state) => linearFlow.indexOf(state);

  /// Which actor is responsible for advancing out of [state]?
  /// Returns null for terminal states.
  static Actor? currentActor(OrderState state) {
    switch (state) {
      case OrderState.requested:
        return Actor.seller; // seller must respond (accept/negotiate/decline)
      case OrderState.negotiation:
        return Actor.seller; // seller accepts or counters
      case OrderState.accepted:
        return Actor.buyer; // buyer secures payment
      case OrderState.paymentSecured:
        return Actor.admin; // admin assigns pickup
      case OrderState.pickupScheduled:
        return Actor.admin; // admin marks delivered
      case OrderState.qualityConfirmed:
        return Actor.buyer; // buyer confirms and completes
      case OrderState.completed:
        return Actor.buyer; // release payment
      case OrderState.paymentReleased:
        return Actor.buyer; // rate
      case OrderState.rated:
      case OrderState.declined:
      case OrderState.expired:
      case OrderState.disputed:
        return null;
    }
  }

  /// The next state a healthy order moves into from [state].
  /// Returns null for branch/terminal states.
  static OrderState? nextState(OrderState state) {
    switch (state) {
      case OrderState.requested:
        return OrderState.negotiation;
      case OrderState.negotiation:
        return OrderState.accepted;
      case OrderState.accepted:
        return OrderState.paymentSecured;
      case OrderState.paymentSecured:
        return OrderState.pickupScheduled;
      case OrderState.pickupScheduled:
        return OrderState.qualityConfirmed;
      case OrderState.qualityConfirmed:
        return OrderState.completed;
      case OrderState.completed:
        return OrderState.paymentReleased;
      case OrderState.paymentReleased:
        return OrderState.rated;
      case OrderState.rated:
      case OrderState.declined:
      case OrderState.expired:
      case OrderState.disputed:
        return null;
    }
  }

  /// The logistics sub-state that should accompany a state transition.
  /// Returns null when the target state has no logistics meaning.
  static LogisticsState? logisticsFor(OrderState state) {
    switch (state) {
      case OrderState.paymentSecured:
        return LogisticsState.awaitingAdminAssignment;
      case OrderState.pickupScheduled:
        return LogisticsState.pickupAssigned;
      case OrderState.qualityConfirmed:
        return LogisticsState.delivered;
      default:
        return null;
    }
  }

  /// Can [actor] advance the order from [state]?
  static bool canAdvance({
    required OrderState state,
    required Actor actor,
  }) =>
      currentActor(state) == actor && nextState(state) != null;

  /// Branch transitions available from any state.
  static const Map<OrderState, List<OrderState>> branchTransitions = {
    OrderState.requested: [OrderState.declined, OrderState.expired],
    OrderState.negotiation: [OrderState.declined, OrderState.expired],
    OrderState.accepted: [OrderState.disputed],
    OrderState.paymentSecured: [OrderState.disputed],
    OrderState.pickupScheduled: [OrderState.disputed],
    OrderState.qualityConfirmed: [OrderState.disputed],
  };

  static bool canBranch(OrderState from, OrderState to) =>
      branchTransitions[from]?.contains(to) ?? false;
}

/// Who is performing an action. Deliberately not tied to [UserRole] so
/// the same action can be re-used for multiple roles (e.g. both buyer
/// and seller can raise a dispute).
enum Actor { farmer, buyer, seller, company, admin, system }

extension ActorLabel on Actor {
  String get label {
    switch (this) {
      case Actor.farmer:
        return 'Farmer';
      case Actor.buyer:
        return 'Buyer';
      case Actor.seller:
        return 'Seller';
      case Actor.company:
        return 'Company';
      case Actor.admin:
        return 'Admin';
      case Actor.system:
        return 'System';
    }
  }
}
