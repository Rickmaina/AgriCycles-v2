import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_routes.dart';
import '../../../core/theme/role_theme.dart';
import '../../../data/models/buy_request_model.dart';
import '../../../data/models/listing_model.dart';
import '../../../data/models/pre_order_model.dart';
import '../../../data/services/auth_service.dart';
import '../../../domain/transport_estimator.dart';
import '../../buy_requests/controllers/buy_request_controller.dart';
import '../../buy_requests/screens/buy_request_detail_screen.dart';
import '../../community/controllers/pre_order_controller.dart';
import '../../community/screens/community_order_detail_screen.dart';
import '../controllers/marketplace_controller.dart';
import 'listing_detail_screen.dart';

// ─────────────────────────────────────────────────────────────
// Filter taxonomy
// ─────────────────────────────────────────────────────────────

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

// ─────────────────────────────────────────────────────────────
// Unified view-model — one card renders listings, buy requests,
// and pre-orders. Admin-prioritizable hooks included.
// ─────────────────────────────────────────────────────────────

enum MarketCardKind { listing, wanted, community }

class MarketCard {
  final String id;
  final MarketCardKind kind;
  final String resourceType;
  final String category;
  final String sellerOrBuyerName;
  final String location;
  final String? priceLabel;      // null → "Negotiable"
  final String quantityLabel;
  final String unit;
  final double? distanceKm;      // from viewer's county
  final String? quality;         // listing only, nullable
  final int? spotsLeft;          // community only
  final DateTime createdAt;
  final bool isFeatured;         // admin-controlled later
  final int priority;            // admin-controlled later

  const MarketCard({
    required this.id,
    required this.kind,
    required this.resourceType,
    required this.category,
    required this.sellerOrBuyerName,
    required this.location,
    this.priceLabel,
    required this.quantityLabel,
    required this.unit,
    this.distanceKm,
    this.quality,
    this.spotsLeft,
    required this.createdAt,
    this.isFeatured = false,
    this.priority = 0,
  });

  bool get isNew =>
      DateTime.now().difference(createdAt).inDays < 7;

  /// Sort: featured first, then priority desc, then newest.
  static int compare(MarketCard a, MarketCard b) {
    if (a.isFeatured != b.isFeatured) return a.isFeatured ? -1 : 1;
    if (a.priority != b.priority) return b.priority.compareTo(a.priority);
    return b.createdAt.compareTo(a.createdAt);
  }
}

// ─────────────────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────────────────

class MarketHomeScreen extends ConsumerStatefulWidget {
  const MarketHomeScreen({super.key});

  @override
  ConsumerState<MarketHomeScreen> createState() =>
      _MarketHomeScreenState();
}

class _MarketHomeScreenState extends ConsumerState<MarketHomeScreen> {
  MarketFilter _active = MarketFilter.all;
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const theme = RoleTheme.farmer;
    final user = ref.watch(authProvider);
    final viewerCounty = user?.county ?? '';

    // Gather all data sources
    final listings = ref.watch(allListingsProvider);
    final buyRequests = ref.watch(openBuyRequestsProvider);
    final preOrders = ref.watch(openPreOrdersProvider);

    // Adapt to unified cards
    final cards = _buildCards(
      listings: listings,
      buyRequests: buyRequests,
      preOrders: preOrders,
      viewerCounty: viewerCounty,
    );

    // Apply filter
    final filtered = _filtered(cards);

    // Sort
    filtered.sort(MarketCard.compare);

    // Search
    final searched = _searched(filtered);

    return Column(
      children: [
        _Header(
          searchCtrl: _searchCtrl,
          query: _query,
          active: _active,
          theme: theme,
          onQueryChanged: (v) => setState(() => _query = v),
          onFilterChanged: (f) => setState(() => _active = f),
        ),
        Expanded(
          child: searched.isEmpty
              ? _EmptyState(filter: _active, theme: theme)
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                  itemCount: searched.length,
                  itemBuilder: (ctx, i) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _MarketCardWidget(
                      card: searched[i],
                      theme: theme,
                      onTap: () => _openCard(searched[i]),
                    ),
                  ),
                ),
        ),
      ],
    );
  }

  // ── Data adapter ───────────────────────────────────────────
  List<MarketCard> _buildCards({
    required List<ListingModel> listings,
    required List<BuyRequestModel> buyRequests,
    required List<PreOrderModel> preOrders,
    required String viewerCounty,
  }) {
    final cards = <MarketCard>[];

    for (final l in listings) {
      if (!l.isVisibleToPublic) continue;
      cards.add(
        MarketCard(
          id: l.id,
          kind: MarketCardKind.listing,
          resourceType: l.resourceType,
          category: l.category,
          sellerOrBuyerName: l.sellerName,
          location: l.broadLocation,
          priceLabel: _kesPerUnit(l.pricePerUnit, l.unit),
          quantityLabel: _formatQty(l.quantity),
          unit: l.unit,
          distanceKm: _distance(viewerCounty, l.county),
          quality: _gradeFor(l),
          createdAt: DateTime.now(),
        ),
      );
    }

    for (final br in buyRequests) {
      cards.add(
        MarketCard(
          id: br.id,
          kind: MarketCardKind.wanted,
          resourceType: br.resourceType,
          category: br.category,
          sellerOrBuyerName: br.buyerName,
          location: br.deliveryBroadLocation,
          priceLabel: _kesPerUnit(br.offeredPricePerUnit, br.unit),
          quantityLabel: _formatQty(br.quantity),
          unit: br.unit,
          distanceKm: _distance(viewerCounty, br.deliveryCounty),
          createdAt: br.createdAt,
        ),
      );
    }

    for (final po in preOrders) {
      final spots = _spotsLeft(po);
      cards.add(
        MarketCard(
          id: po.id,
          kind: MarketCardKind.community,
          resourceType: po.resourceType,
          category: po.category,
          sellerOrBuyerName: po.buyerName,
          location: po.deliveryBroadLocation,
          priceLabel: _kesPerUnit(po.offeredPricePerUnit, po.unit),
          quantityLabel: _formatQty(po.targetQuantity),
          unit: po.unit,
          distanceKm: _distance(viewerCounty, po.deliveryLocation.county),
          spotsLeft: spots,
          createdAt: po.createdAt,
        ),
      );
    }

    return cards;
  }

  // ── Filtering ──────────────────────────────────────────────
  List<MarketCard> _filtered(List<MarketCard> source) {
    switch (_active) {
      case MarketFilter.all:
        return List.of(source);
      case MarketFilter.forSale:
        return source
            .where((c) => c.kind == MarketCardKind.listing)
            .toList();
      case MarketFilter.wanted:
        return source
            .where((c) => c.kind == MarketCardKind.wanted)
            .toList();
      case MarketFilter.community:
        return source
            .where((c) => c.kind == MarketCardKind.community)
            .toList();
      case MarketFilter.near:
        return source
            .where((c) => c.distanceKm != null && c.distanceKm! < 30)
            .toList();
    }
  }

  // ── Search ─────────────────────────────────────────────────
  List<MarketCard> _searched(List<MarketCard> source) {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return source;
    return source.where((c) {
      return c.resourceType.toLowerCase().contains(q) ||
          c.category.toLowerCase().contains(q) ||
          c.sellerOrBuyerName.toLowerCase().contains(q) ||
          c.location.toLowerCase().contains(q);
    }).toList();
  }

  // ── Navigation ─────────────────────────────────────────────
  void _openCard(MarketCard card) {
    switch (card.kind) {
      case MarketCardKind.listing:
        final listing = ref
            .read(allListingsProvider)
            .firstWhere((l) => l.id == card.id);
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ListingDetailScreen(listing: listing),
          ),
        );
        break;
      case MarketCardKind.wanted:
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => BuyRequestDetailScreen(requestId: card.id),
          ),
        );
        break;
      case MarketCardKind.community:
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) =>
                CommunityOrderDetailScreen(preOrderId: card.id),
          ),
        );
        break;
    }
  }

  // ── Helpers ────────────────────────────────────────────────
  double? _distance(String from, String to) {
    if (from.isEmpty || to.isEmpty) return null;
    final km = TransportEstimator.distanceKm(
      pickupCounty: from,
      deliveryCounty: to,
    );
    return km > 0 ? km : null;
  }

  String _kesPerUnit(double price, String unit) {
    final n = price.round();
    final s = n.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return 'KES ${buf.toString()} / $unit';
  }

  String _formatQty(double v) =>
      v.truncateToDouble() == v ? v.toStringAsFixed(0) : v.toString();

  String? _gradeFor(ListingModel l) => null; // populated when listings carry grade

  int? _spotsLeft(PreOrderModel po) {
    // Placeholder — computed properly when pre-order service exposes progress
    return null;
  }
}

// ─────────────────────────────────────────────────────────────
// Header: search + filter chips
// ─────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header({
    required this.searchCtrl,
    required this.query,
    required this.active,
    required this.theme,
    required this.onQueryChanged,
    required this.onFilterChanged,
  });

  final TextEditingController searchCtrl;
  final String query;
  final MarketFilter active;
  final RoleTheme theme;
  final ValueChanged<String> onQueryChanged;
  final ValueChanged<MarketFilter> onFilterChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: theme.surface,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: searchCtrl,
            onChanged: onQueryChanged,
            style: const TextStyle(fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Search resources, sellers, location',
              hintStyle: TextStyle(fontSize: 14, color: theme.textMuted),
              prefixIcon:
                  Icon(Icons.search_rounded, size: 20, color: theme.textMuted),
              suffixIcon: query.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.clear_rounded,
                          size: 18, color: theme.textMuted),
                      onPressed: () {
                        searchCtrl.clear();
                        onQueryChanged('');
                      },
                    )
                  : null,
              filled: true,
              fillColor: theme.background,
              isDense: true,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: theme.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: theme.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: theme.primary, width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              children: MarketFilter.values.map((f) {
                final isActive = active == f;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => onFilterChanged(f),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: isActive ? theme.primary : theme.surface,
                        borderRadius: BorderRadius.circular(99),
                        border: Border.all(
                          color: isActive ? theme.primary : theme.border,
                          width: isActive ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            f.icon,
                            size: 14,
                            color: isActive
                                ? Colors.white
                                : theme.textSecondary,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            f.label,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: isActive
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: isActive
                                  ? Colors.white
                                  : theme.textSecondary,
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
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// The unified card
// ─────────────────────────────────────────────────────────────

class _MarketCardWidget extends StatelessWidget {
  const _MarketCardWidget({
    required this.card,
    required this.theme,
    required this.onTap,
  });

  final MarketCard card;
  final RoleTheme theme;
  final VoidCallback onTap;

  Color get _kindColor {
    switch (card.kind) {
      case MarketCardKind.listing:
        return theme.primary;
      case MarketCardKind.wanted:
        return theme.info;
      case MarketCardKind.community:
        return theme.accent;
    }
  }

  String get _kindLabel {
    switch (card.kind) {
      case MarketCardKind.listing:
        return 'For Sale';
      case MarketCardKind.wanted:
        return 'Wanted';
      case MarketCardKind.community:
        return 'Community';
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: theme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.border),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: _kindColor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: Icon(
                  _kindIcon(card.category),
                  size: 26,
                  color: _kindColor,
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
                            color: _kindColor.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(99),
                          ),
                          child: Text(
                            _kindLabel,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: _kindColor,
                            ),
                          ),
                        ),
                        if (card.isNew) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: theme.accent.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(99),
                            ),
                            child: Text(
                              'New',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: theme.accent,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      card.resourceType,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: theme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${card.quantityLabel} ${card.unit}',
                      style: TextStyle(
                        fontSize: 13,
                        color: theme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.person_outline,
                            size: 12, color: theme.textMuted),
                        const SizedBox(width: 3),
                        Flexible(
                          child: Text(
                            card.sellerOrBuyerName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                fontSize: 11, color: theme.textMuted),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(Icons.location_on_outlined,
                            size: 12, color: theme.textMuted),
                        const SizedBox(width: 2),
                        Flexible(
                          child: Text(
                            card.location,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                fontSize: 11, color: theme.textMuted),
                          ),
                        ),
                        if (card.distanceKm != null) ...[
                          const SizedBox(width: 4),
                          Text(
                            '· ${card.distanceKm!.toStringAsFixed(0)} km',
                            style: TextStyle(
                                fontSize: 11, color: theme.textMuted),
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
                  if (card.priceLabel != null)
                    Text(
                      card.priceLabel!,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _kindColor,
                      ),
                    )
                  else
                    Text(
                      'Negotiable',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _kindColor,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  const SizedBox(height: 10),
                  if (card.kind == MarketCardKind.community &&
                      card.spotsLeft != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: theme.accent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text(
                        '${card.spotsLeft} spots left',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: theme.accent,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _kindIcon(String category) {
    switch (category.toLowerCase()) {
      case 'crop residue':
        return Icons.grass;
      case 'animal waste':
        return Icons.pets;
      case 'by-product':
        return Icons.inventory_2_outlined;
      default:
        return Icons.eco;
    }
  }
}

// ─────────────────────────────────────────────────────────────
// Empty state
// ─────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.filter, required this.theme});
  final MarketFilter filter;
  final RoleTheme theme;

  @override
  Widget build(BuildContext context) {
    final (title, subtitle, cta) = switch (filter) {
      MarketFilter.forSale => (
          'Nothing for sale yet',
          'Be the first to list a resource.',
          'Sell something',
        ),
      MarketFilter.wanted => (
          'No needs posted yet',
          'Post what you are looking for.',
          'Post a need',
        ),
      MarketFilter.community => (
          'No community orders',
          'Start or join a group buy.',
          'Open community',
        ),
      MarketFilter.near => (
          'Nothing nearby',
          'Try widening your search area.',
          null,
        ),
      MarketFilter.all => (
          'Market is empty',
          'Check back soon.',
          null,
        ),
    };

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.storefront_outlined, size: 52, color: theme.textMuted),
            const SizedBox(height: 14),
            Text(
              title,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: theme.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: TextStyle(
                  fontSize: 13, color: theme.textMuted, height: 1.5),
              textAlign: TextAlign.center,
            ),
            if (cta != null) ...[
              const SizedBox(height: 20),
              OutlinedButton(
                onPressed: () {
                  if (filter == MarketFilter.wanted) {
                    context.push(AppRoutes.postNeed);
                  } else if (filter == MarketFilter.community) {
                    context.push(AppRoutes.communityOrders);
                  } else {
                    context.push(AppRoutes.createListing);
                  }
                },
                child: Text(cta),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
