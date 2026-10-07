import '../../core/constants/enums.dart';

/// One item in the shared verification queue.
/// Covers vets, companies, vehicles, and drivers via the `type` field.
class VerificationRequestModel {
  final String id;
  final String userId;
  final String applicantName;
  final VerificationType type;

  /// Document references (licence numbers, certificate IDs, plate scans).
  /// Display-only for now; file URLs land later.
  final List<String> documentRefs;

  final String? plateNumber; // vehicles only
  final String? extraInfo; // vehicles: make/model/capacity

  // ── Driver-only fields ───────────────────────────────────────
  final String? driverLicence;
  final String? driverVehiclePlate;
  final String? driverVehicleClass;

  final String county;
  final VerificationStatus status;
  final DateTime submittedAt;
  final DateTime? reviewedAt;
  final String? reviewedBy;
  final String? rejectionReason;

  const VerificationRequestModel({
    required this.id,
    required this.userId,
    required this.applicantName,
    required this.type,
    this.documentRefs = const [],
    this.plateNumber,
    this.extraInfo,
    this.driverLicence,
    this.driverVehiclePlate,
    this.driverVehicleClass,
    required this.county,
    this.status = VerificationStatus.pending,
    required this.submittedAt,
    this.reviewedAt,
    this.reviewedBy,
    this.rejectionReason,
  });

  VerificationRequestModel copyWith({
    VerificationStatus? status,
    DateTime? reviewedAt,
    String? reviewedBy,
    String? rejectionReason,
  }) {
    return VerificationRequestModel(
      id: id,
      userId: userId,
      applicantName: applicantName,
      type: type,
      documentRefs: documentRefs,
      plateNumber: plateNumber,
      extraInfo: extraInfo,
      driverLicence: driverLicence,
      driverVehiclePlate: driverVehiclePlate,
      driverVehicleClass: driverVehicleClass,
      county: county,
      status: status ?? this.status,
      submittedAt: submittedAt,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      reviewedBy: reviewedBy ?? this.reviewedBy,
      rejectionReason: rejectionReason ?? this.rejectionReason,
    );
  }
}
