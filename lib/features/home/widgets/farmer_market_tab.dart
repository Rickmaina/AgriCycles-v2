import 'package:flutter/material.dart';

import '../../../shared/widgets/segmented_toggle.dart';
import '../../buy_requests/screens/browse_needs_screen.dart';
import '../../marketplace/browse_screen.dart';
import '../../marketplace/incoming_offers_screen.dart';
import '../../marketplace/my_listings_screen.dart';

class FarmerMarketTab extends StatefulWidget {
  const FarmerMarketTab({super.key});

  @override
  State<FarmerMarketTab> createState() => _FarmerMarketTabState();
}

class _FarmerMarketTabState extends State<FarmerMarketTab> {
  int _tab = 0;

  static const _tabs = ['Browse', 'Needs', 'Mine', 'Offers'];

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
            expand: false,
          ),
        ),
        Expanded(
          child: switch (_tab) {
            0 => const BrowseScreen(),
            1 => const BrowseNeedsScreen(),
            2 => const MyListingsScreen(),
            _ => const IncomingOffersScreen(),
          },
        ),
      ],
    );
  }
}
