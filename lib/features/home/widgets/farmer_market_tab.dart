import 'package:flutter/material.dart';

import '../../../shared/widgets/segmented_toggle.dart';
import '../../marketplace/browse_screen.dart';
import '../../marketplace/incoming_offers_screen.dart';
import '../../marketplace/my_listings_screen.dart';

/// Farmer Market tab: Browse / Mine / Offers, driven by [SegmentedToggle].
class FarmerMarketTab extends StatefulWidget {
  const FarmerMarketTab({super.key});

  @override
  State<FarmerMarketTab> createState() => _FarmerMarketTabState();
}

class _FarmerMarketTabState extends State<FarmerMarketTab> {
  int _tab = 0;

  static const _tabs = ['Browse', 'Mine', 'Offers'];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: SegmentedToggle(
            options: _tabs,
            selectedIndex: _tab,
            onChanged: (i) => setState(() => _tab = i),
          ),
        ),
        Expanded(
          child: switch (_tab) {
            0 => const BrowseScreen(),
            1 => const MyListingsScreen(),
            _ => const IncomingOffersScreen(),
          },
        ),
      ],
    );
  }
}
