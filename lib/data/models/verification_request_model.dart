import '../../core/constants/enums.dart';

/// One item in the shared verification queue (Section 8).
/// Covers vets, companies, and vehicles via the `type` field.
class VerificationRequestModel {
  final String id;
  final String userId;
  final String applicantName;
  final VerificationType type;
  final String documentRef;
  final String? plateNumber; // vehicles only
  final String? extraInfo; // vehicles: make/model/capacity
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
    required this.documentRef,
    this.plateNumber,
    this.extraInfo,
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
      documentRef: documentRef,
      plateNumber: plateNumber,
      extraInfo: extraInfo,
      county: county,
      status: status ?? this.status,
      submittedAt: submittedAt,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      reviewedBy: reviewedBy ?? this.reviewedBy,
      rejectionReason: rejectionReason ?? this.rejectionReason,
    );
  }
}
