import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/platform_rules_model.dart';

class PlatformRulesService extends StateNotifier<PlatformRulesModel> {
  PlatformRulesService() : super(PlatformRulesModel.defaults);

  void update(PlatformRulesModel Function(PlatformRulesModel) map) {
    state = map(state);
  }
}

final platformRulesProvider =
    StateNotifierProvider<PlatformRulesService, PlatformRulesModel>(
  (ref) => PlatformRulesService(),
);
