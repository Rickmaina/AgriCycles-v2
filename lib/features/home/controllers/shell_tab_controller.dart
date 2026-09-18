import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Tracks which bottom-nav tab the home shell is showing. Screens can
/// read this and call [ShellTabController.goTo] to switch tabs
/// programmatically (e.g. dashboard hero → Market).
class ShellTabController extends StateNotifier<int> {
  ShellTabController() : super(0);

  void goTo(int index) => state = index;
}

final shellTabProvider = StateNotifierProvider<ShellTabController, int>(
  (ref) => ShellTabController(),
);
