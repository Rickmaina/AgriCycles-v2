import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/enums.dart';
import '../models/dispute_model.dart';

class DisputeService extends StateNotifier<List<DisputeModel>> {
  DisputeService() : super(const []);

  List<DisputeModel> get open =>
      state.where((d) => d.status != DisputeStatus.resolved).toList();

  List<DisputeModel> byOrder(String orderId) =>
      state.where((d) => d.orderId == orderId).toList();

  DisputeModel? byId(String id) {
    for (final d in state) {
      if (d.id == id) return d;
    }
    return null;
  }

  DisputeModel raise(DisputeModel dispute) {
    state = [dispute, ...state];
    return dispute;
  }

  void markUnderReview(String disputeId) {
    _update(
      disputeId,
      (d) => d.copyWith(
        status: DisputeStatus.underReview,
        updatedAt: DateTime.now(),
      ),
    );
  }

  void resolve({
    required String disputeId,
    required DisputeResolution resolution,
    required String adminName,
    String? notes,
  }) {
    _update(
      disputeId,
      (d) => d.copyWith(
        status: DisputeStatus.resolved,
        resolution: resolution,
        resolutionNotes: notes,
        resolvedBy: adminName,
        resolvedAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );
  }

  void _update(
    String id,
    DisputeModel Function(DisputeModel) map,
  ) {
    state = state.map((d) => d.id == id ? map(d) : d).toList();
  }
}

final disputeProvider =
    StateNotifierProvider<DisputeService, List<DisputeModel>>(
  (ref) => DisputeService(),
);
