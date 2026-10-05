import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_routes.dart';

// ─────────────────────────────────────────────────────────────────────────────
// MarketHomeScreen — redesigned
//
// Drop-in replacement for the old three-tile market menu.
// Shows all marketplace listings immediately with filter chips at the top.
//
// Wire-up note:
//   Use the real provider once the app has a live listings source.
//   The screen watches a Riverpod family here so the structure is ready.
// ─────────────────────────────────────────────────────────────────────────────

enum MarketFilter {
  all('All', Icons.grid_view_rounded),
  forSale('For Sale', Icons.sell_outlined),
  wanted('Wanted', Icons.shopping_cart_outlined),
  community('Community', Icons.groups_outlined),
  near('Near Me', Icons.location_on_outlined);

  const MarketFilter(this.label, this.icon);
  final String label;
  final IconData icon;
}

final marketListingsProvider =
    Provider.family<List<_MockListing>, MarketFilter>(
  (ref, filter) {
    final items = _mockListings.where((listing) {
      switch (filter) {
        case MarketFilter.all:
          return true;
        case MarketFilter.forSale:
          return listing.type == ListingType.forSale;
        case MarketFilter.wanted:
          return listing.type == ListingType.wanted;
        case MarketFilter.community:
          return listing.type == ListingType.community;
        case MarketFilter.near:
          return listing.distanceKm != null && listing.distanceKm! < 30;
      }
    }).toList();

    return items;
  },
);

class MarketHomeScreen extends ConsumerStatefulWidget {
  const MarketHomeScreen({super.key});

  @override
  ConsumerState<MarketHomeScreen> createState() => _MarketHomeScreenState();
}

class _MarketHomeScreenState extends ConsumerState<MarketHomeScreen> {
  MarketFilter _active = MarketFilter.all;
  final _searchCtrl = TextEditingController();
  String _query = '';

  static const _bg = Color(0xFFF5F7F5);
  static const _card = Color(0xFFFFFFFF);
  static const _border = Color(0xFFDDE8DD);

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final listings = _applySearch(ref.watch(marketListingsProvider(_active)));

    return Scaffold(
      backgroundColor: _bg,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            backgroundColor: _card,
            surfaceTintColor: Colors.transparent,
            shadowColor: _border,
            elevation: innerBoxIsScrolled ? 1 : 0,
            floating: true,
            snap: true,
            pinned: false,
            automaticallyImplyLeading: false,
            title: null,
            flexibleSpace: null,
            toolbarHeight: 0,
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(116),
              child: _StickyHeader(
                searchCtrl: _searchCtrl,
                query: _query,
                active: _active,
                onQueryChanged: (value) => setState(() => _query = value),
                onFilterChanged: (filter) => setState(() => _active = filter),
              ),
            ),
          ),
        ],
        body: listings.isEmpty
            ? _EmptyState(filter: _active)
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 32),
                itemCount: listings.length,
                itemBuilder: (ctx, i) {
                  final item = listings[i];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _ListingCard(
                      item: item,
                      onTap: () => context.go(AppRoutes.listingDetail(item.id)),
                      onMakeOffer: item.type == ListingType.forSale
                          ? () => context.go(AppRoutes.offerDetail(item.id))
                          : null,
                    ),
                  );
                },
              ),
      ),
      floatingActionButton: _MarketFab(active: _active),
    );
  }

  List<_MockListing> _applySearch(List<_MockListing> all) {
    var list = all;

    if (_query.trim().isNotEmpty) {
      final q = _query.trim().toLowerCase();
      list = list.where((listing) {
        return listing.name.toLowerCase().contains(q) ||
            listing.location.toLowerCase().contains(q) ||
            listing.sellerName.toLowerCase().contains(q);
      }).toList();
    }

    return list;
  }
}

class _StickyHeader extends StatelessWidget {
  const _StickyHeader({
    required this.searchCtrl,
    required this.query,
    required this.active,
    required this.onQueryChanged,
    required this.onFilterChanged,
  });

  final TextEditingController searchCtrl;
  final String query;
  final MarketFilter active;
  final ValueChanged<String> onQueryChanged;
  final ValueChanged<MarketFilter> onFilterChanged;

  static const _green = Color(0xFF2E7D32);
  static const _border = Color(0xFFDDE8DD);
  static const _bg = Color(0xFFF5F7F5);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 44,
            child: TextField(
              controller: searchCtrl,
              onChanged: onQueryChanged,
              style: const TextStyle(fontSize: 14, color: Color(0xFF1A2E1A)),
              decoration: InputDecoration(
                hintText: 'Search resources, sellers, location…',
                hintStyle:
                    const TextStyle(fontSize: 14, color: Color(0xFF8FA888)),
                prefixIcon: const Icon(Icons.search_rounded,
                    size: 20, color: Color(0xFF8FA888)),
                suffixIcon: query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded,
                            size: 18, color: Color(0xFF8FA888)),
                        onPressed: () {
                          searchCtrl.clear();
                          onQueryChanged('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: _bg,
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: _border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: _border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: _green, width: 1.5),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              children: MarketFilter.values.map((filter) {
                final isActive = active == filter;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => onFilterChanged(filter),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: isActive ? _green : Colors.white,
                        borderRadius: BorderRadius.circular(99),
                        border: Border.all(
                          color: isActive ? _green : _border,
                          width: isActive ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            filter.icon,
                            size: 14,
                            color: isActive
                                ? Colors.white
                                : const Color(0xFF546E4F),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            filter.label,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight:
                                  isActive ? FontWeight.w700 : FontWeight.w500,
                              color: isActive
                                  ? Colors.white
                                  : const Color(0xFF546E4F),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}

class _ListingCard extends StatelessWidget {
  const _ListingCard({
    required this.item,
    required this.onTap,
    this.onMakeOffer,
  });

  final _MockListing item;
  final VoidCallback onTap;
  final VoidCallback? onMakeOffer;

  static const _green = Color(0xFF2E7D32);
  static const _blue = Color(0xFF1565C0);
  static const _amber = Color(0xFFF59E0B);
  static const _border = Color(0xFFDDE8DD);

  Color get _typeColor => switch (item.type) {
        ListingType.forSale => _green,
        ListingType.wanted => _blue,
        ListingType.community => _amber,
      };

  String get _typeLabel => switch (item.type) {
        ListingType.forSale => 'For Sale',
        ListingType.wanted => 'Wanted',
        ListingType.community => 'Community',
      };

  Color get _qualityColor => switch (item.quality) {
        'Premium' => const Color(0xFF059669),
        'Good' => _green,
        'Fair' => _amber,
        _ => const Color(0xFF9E9E9E),
      };

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _border),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0A1A2E1A),
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: _typeColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(
                      child: Text(item.emoji,
                          style: const TextStyle(fontSize: 26)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: _typeColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(99),
                              ),
                              child: Text(
                                _typeLabel,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: _typeColor,
                                ),
                              ),
                            ),
                            if (item.quality != null) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                  color: _qualityColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(99),
                                ),
                                child: Text(
                                  item.quality!,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: _qualityColor,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.name,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1A2E1A),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${item.quantity} ${item.unit}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF546E4F),
                          ),
                        ),
                        const SizedBox(height: 5),
                        Row(
                          children: [
                            const Icon(Icons.person_outline,
                                size: 12, color: Color(0xFF8FA888)),
                            const SizedBox(width: 3),
                            Text(
                              item.sellerName,
                              style: const TextStyle(
                                  fontSize: 11, color: Color(0xFF8FA888)),
                            ),
                            const SizedBox(width: 10),
                            const Icon(Icons.location_on_outlined,
                                size: 12, color: Color(0xFF8FA888)),
                            const SizedBox(width: 2),
                            Text(
                              item.location,
                              style: const TextStyle(
                                  fontSize: 11, color: Color(0xFF8FA888)),
                            ),
                            if (item.distanceKm != null) ...[
                              const SizedBox(width: 4),
                              Text(
                                '· ${item.distanceKm!.toStringAsFixed(0)} km',
                                style: const TextStyle(
                                    fontSize: 11, color: Color(0xFF8FA888)),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (item.priceLabel != null) ...[
                        Text(
                          item.priceLabel!,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: _typeColor,
                          ),
                        ),
                        Text(
                          '/ ${item.unit}',
                          style: const TextStyle(
                              fontSize: 10, color: Color(0xFF8FA888)),
                        ),
                      ] else
                        Text(
                          'Negotiable',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _typeColor,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      const SizedBox(height: 10),
                      if (item.type == ListingType.community &&
                          item.spotsLeft != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: _amber.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(99),
                          ),
                          child: Text(
                            '${item.spotsLeft} spots left',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF92400E),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            if (onMakeOffer != null) ...[
              Container(
                height: 1,
                color: const Color(0xFFF0F7F0),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
                child: Row(
                  children: [
                    Text(
                      item.postedLabel,
                      style: const TextStyle(
                          fontSize: 11, color: Color(0xFF8FA888)),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: onMakeOffer,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 7),
                        decoration: BoxDecoration(
                          color: _green,
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: const Text(
                          'Make Offer',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MarketFab extends StatelessWidget {
  const _MarketFab({required this.active});
  final MarketFilter active;

  static const _green = Color(0xFF2E7D32);
  static const _blue = Color(0xFF1565C0);
  static const _amber = Color(0xFFF59E0B);

  @override
  Widget build(BuildContext context) {
    final (icon, label, color, route) = switch (active) {
      MarketFilter.wanted => (
          Icons.add_circle_outline,
          'Post a Need',
          _blue,
          AppRoutes.postNeed,
        ),
      MarketFilter.community => (
          Icons.groups_outlined,
          'Join / Create',
          _amber,
          AppRoutes.communityOrders,
        ),
      _ => (
          Icons.sell_outlined,
          'Sell',
          _green,
          AppRoutes.createListing,
        ),
    };

    return FloatingActionButton.extended(
      onPressed: () => context.go(route),
      backgroundColor: color,
      foregroundColor: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      icon: Icon(icon, size: 20),
      label: Text(
        label,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.filter});
  final MarketFilter filter;

  @override
  Widget build(BuildContext context) {
    final (emoji, title, sub) = switch (filter) {
      MarketFilter.forSale => (
          '🌾',
          'Nothing for sale yet',
          'Be the first to list a resource.'
        ),
      MarketFilter.wanted => (
          '🛒',
          'No needs posted yet',
          'Post what you are looking for.'
        ),
      MarketFilter.community => (
          '👥',
          'No community orders',
          'Start or join a group buy.'
        ),
      MarketFilter.near => (
          '📍',
          'Nothing nearby',
          'Try expanding your search area.'
        ),
      _ => ('📦', 'Market is empty', 'Check back soon.'),
    };

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 52)),
            const SizedBox(height: 14),
            Text(
              title,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A2E1A),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              sub,
              style: const TextStyle(
                  fontSize: 13, color: Color(0xFF8FA888), height: 1.5),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

enum ListingType { forSale, wanted, community }

class _MockListing {
  const _MockListing({
    required this.id,
    required this.type,
    required this.emoji,
    required this.name,
    required this.quantity,
    required this.unit,
    required this.sellerName,
    required this.location,
    this.priceLabel,
    this.quality,
    this.distanceKm,
    this.spotsLeft,
    this.postedLabel = 'Just now',
  });

  final String id;
  final ListingType type;
  final String emoji;
  final String name;
  final double quantity;
  final String unit;
  final String sellerName;
  final String location;
  final String? priceLabel;
  final String? quality;
  final double? distanceKm;
  final int? spotsLeft;
  final String postedLabel;
}

const _mockListings = <_MockListing>[
  _MockListing(
    id: '1',
    type: ListingType.forSale,
    emoji: '🌽',
    name: 'Maize Stalks',
    quantity: 20,
    unit: 'bags',
    sellerName: 'James M.',
    location: 'Nakuru',
    priceLabel: 'KES 850',
    quality: 'Good',
    distanceKm: 4.2,
    postedLabel: '2 hrs ago',
  ),
  _MockListing(
    id: '2',
    type: ListingType.forSale,
    emoji: '🌾',
    name: 'Sugarcane Bagasse',
    quantity: 2,
    unit: 'tonnes',
    sellerName: 'Grace W.',
    location: 'Kisumu',
    priceLabel: 'KES 4,200',
    quality: 'Premium',
    distanceKm: 12.0,
    postedLabel: '5 hrs ago',
  ),
  _MockListing(
    id: '3',
    type: ListingType.wanted,
    emoji: '🌱',
    name: 'Cow Manure',
    quantity: 1,
    unit: 'truck',
    sellerName: 'Peter K.',
    location: 'Eldoret',
    quality: 'Good',
    distanceKm: 28.5,
    postedLabel: '1 day ago',
  ),
  _MockListing(
    id: '4',
    type: ListingType.community,
    emoji: '🍚',
    name: 'Rice Husks — Group Buy',
    quantity: 50,
    unit: 'bags',
    sellerName: 'AgriCycles',
    location: 'Mwea',
    priceLabel: 'KES 600',
    spotsLeft: 3,
    postedLabel: '3 hrs ago',
  ),
  _MockListing(
    id: '5',
    type: ListingType.forSale,
    emoji: '🪵',
    name: 'Wood Chips',
    quantity: 1,
    unit: 'pickup load',
    sellerName: 'Samuel O.',
    location: 'Thika',
    priceLabel: 'KES 3,500',
    quality: 'Fair',
    distanceKm: 8.0,
    postedLabel: '6 hrs ago',
  ),
  _MockListing(
    id: '6',
    type: ListingType.wanted,
    emoji: '☕',
    name: 'Coffee Husks',
    quantity: 10,
    unit: 'bags',
    sellerName: 'Mary N.',
    location: 'Nyeri',
    distanceKm: 45.0,
    postedLabel: '2 days ago',
  ),
  _MockListing(
    id: '7',
    type: ListingType.forSale,
    emoji: '🌿',
    name: 'Crop Residues',
    quantity: 500,
    unit: 'kg',
    sellerName: 'John A.',
    location: 'Nakuru',
    priceLabel: 'KES 12',
    quality: 'Good',
    distanceKm: 6.3,
    postedLabel: '1 hr ago',
  ),
];
