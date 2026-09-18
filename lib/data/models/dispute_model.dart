import '../../core/constants/enums.dart';

/// A dispute on an order. Can be raised by either party; resolved by
/// Admin. Captures the reason, the affected scope (full or partial),
/// and the resolution decision.
class DisputeModel {
  final String id;
  final String orderId;
  final String orderResourceType;

  final String raisedById;
  final String raisedByName;
  final String raisedByRole; // 'buyer' | 'seller'

  final DisputeIssueType issueType;
  final String description;
  final double? affectedQuantity; // null for full-order dispute
  final double? affectedAmount; // in KES, null if not monetary
  final List<String> evidenceRefs; // filenames / refs, not raw URLs

  final DisputeStatus status;
  final DisputeResolution? resolution;
  final String? resolutionNotes;
  final String? resolvedBy;
  final DateTime? resolvedAt;

  final DateTime createdAt;
  final DateTime updatedAt;

  const DisputeModel({
    required this.id,
    required this.orderId,
    required this.orderResourceType,
    required this.raisedById,
    required this.raisedByName,
    required this.raisedByRole,
    required this.issueType,
    required this.description,
    this.affectedQuantity,
    this.affectedAmount,
    this.evidenceRefs = const [],
    this.status = DisputeStatus.open,
    this.resolution,
    this.resolutionNotes,
    this.resolvedBy,
    this.resolvedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  DisputeModel copyWith({
    DisputeStatus? status,
    DisputeResolution? resolution,
    String? resolutionNotes,
    String? resolvedBy,
    DateTime? resolvedAt,
    DateTime? updatedAt,
  }) =>
      DisputeModel(
        id: id,
        orderId: orderId,
        orderResourceType: orderResourceType,
        raisedById: raisedById,
        raisedByName: raisedByName,
        raisedByRole: raisedByRole,
        issueType: issueType,
        description: description,
        affectedQuantity: affectedQuantity,
        affectedAmount: affectedAmount,
        evidenceRefs: evidenceRefs,
        status: status ?? this.status,
        resolution: resolution ?? this.resolution,
        resolutionNotes: resolutionNotes ?? this.resolutionNotes,
        resolvedBy: resolvedBy ?? this.resolvedBy,
        resolvedAt: resolvedAt ?? this.resolvedAt,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
}
