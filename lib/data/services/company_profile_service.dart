import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/company_profile_model.dart';
import '../models/geo_location.dart';

/// Holds the current company's profile data. In-memory only for now.
/// Cleared on logout.
class CompanyProfileService extends StateNotifier<CompanyProfileModel?> {
  CompanyProfileService() : super(null);

  void save({
    required String businessName,
    required String businessType,
    required String contactName,
    String? descriptor,
    required GeoLocation base,
  }) {
    state = CompanyProfileModel(
      businessName: businessName,
      businessType: businessType,
      contactName: contactName,
      descriptor: descriptor,
      base: base,
      updatedAt: DateTime.now(),
    );
  }

  void clear() => state = null;
}

final companyProfileProvider =
    StateNotifierProvider<CompanyProfileService, CompanyProfileModel?>(
  (ref) => CompanyProfileService(),
);
