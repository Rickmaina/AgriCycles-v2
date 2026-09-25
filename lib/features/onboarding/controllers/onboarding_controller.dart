import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/enums.dart';
import '../../../data/models/geo_location.dart';
import '../../../data/services/auth_service.dart';
import '../../auth/controllers/auth_controller.dart';

/// Multi-step onboarding state. Holds farmer type, location, and
/// farm scale until Screen 3 commits them to the user account.
class OnboardingState {
  final FarmerType? farmerType;
  final GeoLocation? location;
  final String? farmScale;

  const OnboardingState({
    this.farmerType,
    this.location,
    this.farmScale,
  });

  OnboardingState copyWith({
    FarmerType? farmerType,
    GeoLocation? location,
    String? farmScale,
  }) {
    return OnboardingState(
      farmerType: farmerType ?? this.farmerType,
      location: location ?? this.location,
      farmScale: farmScale ?? this.farmScale,
    );
  }

  bool get isComplete =>
      farmerType != null && location != null && farmScale != null;
}

class OnboardingController extends StateNotifier<OnboardingState> {
  OnboardingController(this._ref) : super(const OnboardingState());

  final Ref _ref;

  void setFarmerType(FarmerType type) {
    state = state.copyWith(farmerType: type);
  }

  void setLocation(GeoLocation location) {
    state = state.copyWith(location: location);
  }

  void setFarmScale(String scale) {
    state = state.copyWith(farmScale: scale);
  }

  /// Called from Screen 3. Writes the collected data to the user
  /// account and lets the router gate stop firing.
  void commit() {
    final user = _ref.read(authProvider);
    if (user == null) return;

    final authController = _ref.read(authControllerProvider);

    // Persist farmer type via the existing onboarding path.
    if (state.farmerType != null) {
      authController.completeOnboarding(
        farmerType: state.farmerType!,
        cropDetails: state.location != null
            ? '${state.location!.county}, ${state.location!.subCounty}'
            : null,
        farmScale: state.farmScale,
      );
    }
  }

  void reset() {
    state = const OnboardingState();
  }
}

final onboardingControllerProvider =
    StateNotifierProvider<OnboardingController, OnboardingState>(
  (ref) => OnboardingController(ref),
);
