import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/enums.dart';
import '../models/verification_request_model.dart';

class VerificationService
    extends StateNotifier<List<VerificationRequestModel>> {
  VerificationService() : super(_seed());

  static List<VerificationRequestModel> _seed() {
    final now = DateTime.now();
    return [
      VerificationRequestModel(
        id: 'vr1',
        userId: 'u20',
        applicantName: 'Dr. Kamau',
        type: VerificationType.vet,
        documentRef: 'KVB-2019-4421',
        county: 'Nairobi',
        submittedAt: now.subtract(const Duration(hours: 6)),
      ),
      VerificationRequestModel(
        id: 'vr2',
        userId: 'u21',
        applicantName: 'Mumias Sugar Works',
        type: VerificationType.company,
        documentRef: 'BRS-2015-88231',
        county: 'Kakamega',
        submittedAt: now.subtract(const Duration(days: 1)),
      ),
      VerificationRequestModel(
        id: 'vr3',
        userId: 'u22',
        applicantName: 'Kisumu Feeds Ltd',
        type: VerificationType.company,
        documentRef: 'BRS-2020-11452',
        county: 'Kisumu',
        submittedAt: now.subtract(const Duration(hours: 3)),
      ),
      VerificationRequestModel(
        id: 'vr4',
        userId: 'u23',
        applicantName: 'Dr. Achieng',
        type: VerificationType.vet,
        documentRef: 'KVB-2021-7781',
        county: 'Kisumu',
        status: VerificationStatus.approved,
        submittedAt: now.subtract(const Duration(days: 5)),
        reviewedAt: now.subtract(const Duration(days: 4)),
        reviewedBy: 'Admin',
      ),
      VerificationRequestModel(
        id: 'vr5',
        userId: 'u30',
        applicantName: 'Peter Mwangi (Transport)',
        type: VerificationType.vehicle,
        documentRef: 'KDA 342J',
        plateNumber: 'KDA 342J',
        extraInfo: 'Isuzu FRR, 2019, diesel, 7t capacity',
        county: 'Kiambu',
        submittedAt: now.subtract(const Duration(hours: 12)),
      ),
      VerificationRequestModel(
        id: 'vr6',
        userId: 'u31',
        applicantName: 'Faith Transporters Ltd',
        type: VerificationType.vehicle,
        documentRef: 'KCX 887P',
        plateNumber: 'KCX 887P',
        extraInfo: 'Mitsubishi Fuso, 2017, diesel, 5t',
        county: 'Kakamega',
        submittedAt: now.subtract(const Duration(hours: 2)),
      ),
    ];
  }

  List<VerificationRequestModel> get pending =>
      state.where((r) => r.status == VerificationStatus.pending).toList();

  /// Adds a new submission to the queue.
  void submit(VerificationRequestModel request) {
    state = [...state, request];
  }

  void approve(String id, String adminName) {
    _update(id, (r) => r.copyWith(
          status: VerificationStatus.approved,
          reviewedAt: DateTime.now(),
          reviewedBy: adminName,
        ));
  }

  void reject(String id, String adminName, String reason) {
    _update(id, (r) => r.copyWith(
          status: VerificationStatus.rejected,
          reviewedAt: DateTime.now(),
          reviewedBy: adminName,
          rejectionReason: reason,
        ));
  }

  void _update(
    String id,
    VerificationRequestModel Function(VerificationRequestModel) map,
  ) {
    state = state.map((r) => r.id == id ? map(r) : r).toList();
  }
}

final verificationProvider =
    StateNotifierProvider<VerificationService, List<VerificationRequestModel>>(
  (ref) => VerificationService(),
);
