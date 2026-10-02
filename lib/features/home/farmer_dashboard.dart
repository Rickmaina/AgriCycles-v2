import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_routes.dart';
import '../../core/constants/enums.dart';
import '../../data/models/listing_model.dart';
import '../../data/models/order_model.dart';
import '../../data/models/user_model.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/notification_service.dart';
import '../../data/services/order_service.dart';
import '../marketplace/controllers/marketplace_controller.dart';

class FarmerDashboard extends ConsumerWidget {
  const FarmerDashboard({super.key});

  static const _green = Color(0xFF2E7D32);
  static const _bg = Color(0xFFF5F7F5);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider);
    final listings = ref
        .watch(allListingsProvider)
        .where((ListingModel listing) => listing.isVisibleToPublic)
        .take(4)
        .toList();
    final myOrders = user == null
        ? const <OrderModel>[]
        : ref.watch(ordersProvider).where((order) {
            return order.buyerId == user.id || order.sellerId == user.id;
          }).toList();
    final unreadCount =
        user == null ? 0 : ref.watch(myUnreadCountProvider(user.id));
    final farmerName = user?.name ?? 'Farmer';
    final farmerLocation = _locationLabel(user);

    final recentOrders = myOrders.take(2).map((order) {
      final statusColor = order.state == OrderState.accepted
          ? const Color(0xFF2E7D32)
          : const Color(0xFF1565C0);
      final statusLabel = _activityStatus(order.state);

      return _ActivityItem(
        emoji: _resourceEmoji(order.resourceType),
        title: order.resourceType,
        subtitle:
            '${order.state.label} • KES ${order.pricePerUnit.toStringAsFixed(0)}',
        statusLabel: statusLabel,
        statusColor: statusColor,
        route: AppRoutes.activity,
      );
    }).toList();

    final previewItems = listings.map((listing) {
      return _PreviewListing(
        emoji: _resourceEmoji(listing.resourceType),
        name: listing.resourceType,
        qty: '${_formatAmount(listing.quantity)} ${listing.unit}',
        unit: listing.unit,
        price: 'KES ${listing.pricePerUnit.toStringAsFixed(0)}',
        location:
            listing.broadLocation.isNotEmpty ? listing.broadLocation : 'Kenya',
        quality: listing.quality.isNotEmpty ? listing.quality : 'Good',
      );
    }).toList();

    return Scaffold(
      backgroundColor: _bg,
      body: RefreshIndicator(
        color: _green,
        onRefresh: () async {
          await Future<void>.delayed(const Duration(milliseconds: 800));
        },
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: _Header(
                name: farmerName,
                location: farmerLocation,
                unreadCount: unreadCount,
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 4)),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverToBoxAdapter(
                child: _HeroActions(
                  onSell: () => context.go(AppRoutes.createListing),
                  onBuy: () => context.go(AppRoutes.browse),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
              sliver: SliverToBoxAdapter(
                child: _ActivityQuickLook(items: recentOrders),
              ),
            ),
            const SliverPadding(
              padding: EdgeInsets.fromLTRB(16, 24, 16, 12),
              sliver: SliverToBoxAdapter(child: _SectionHeader()),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: _MarketplacePreview(items: previewItems),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              sliver: SliverToBoxAdapter(
                child: GestureDetector(
                  onTap: () => context.go(AppRoutes.browse),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'View all listings',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _green,
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(Icons.arrow_forward, size: 16, color: _green),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _locationLabel(UserModel? user) {
    final parts = [user?.county, user?.subCounty, user?.area]
        .whereType<String>()
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toList();

    if (parts.isEmpty) return 'Location not set';
    if (parts.length == 1) return parts.first;
    return '${parts[0]}, ${parts[1]}';
  }

  static String _activityStatus(OrderState state) {
    switch (state) {
      case OrderState.accepted:
        return 'Respond';
      case OrderState.paymentSecured:
      case OrderState.pickupScheduled:
      case OrderState.qualityConfirmed:
        return 'Waiting';
      default:
        return state.label;
    }
  }

  static String _formatAmount(double value) {
    if (value % 1 == 0) {
      return value.toInt().toString();
    }
    return value.toStringAsFixed(1).replaceFirst(RegExp(r'\.0$'), '');
  }

  static String _resourceEmoji(String resourceType) {
    final type = resourceType.toLowerCase();
    if (type.contains('maize')) return '🌽';
    if (type.contains('sugar') || type.contains('bagasse')) return '🌾';
    if (type.contains('manure') || type.contains('compost')) return '🌱';
    if (type.contains('rice') || type.contains('husk')) return '🍚';
    if (type.contains('milk')) return '🥛';
    if (type.contains('bean')) return '🫘';
    if (type.contains('veget')) return '🥬';
    if (type.contains('fruit')) return '🍊';
    if (type.contains('hay')) return '🌾';
    return '🌿';
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.name,
    required this.location,
    required this.unreadCount,
  });

  final String name;
  final String location;
  final int unreadCount;

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 12,
        left: 16,
        right: 16,
        bottom: 20,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFF2E7D32),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Center(
                  child: Text('🌱', style: TextStyle(fontSize: 18)),
                ),
              ),
              const SizedBox(width: 10),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'AgriCycles',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1A2E1A),
                      letterSpacing: -0.3,
                    ),
                  ),
                  Text(
                    'Marketplace',
                    style: TextStyle(
                      fontSize: 11,
                      color: Color(0xFF8FA888),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Stack(
                children: [
                  IconButton(
                    onPressed: () => context.go(AppRoutes.notifications),
                    icon: const Icon(
                      Icons.notifications_outlined,
                      color: Color(0xFF546E4F),
                    ),
                    style: IconButton.styleFrom(
                      backgroundColor: const Color(0xFFF0F7F0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  if (unreadCount > 0)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        width: 18,
                        height: 18,
                        decoration: const BoxDecoration(
                          color: Color(0xFFDC2626),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            unreadCount > 9 ? '9+' : unreadCount.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            '$_greeting 👋',
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF8FA888),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Welcome back, $name',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A2E1A),
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(
                Icons.location_on_outlined,
                size: 14,
                color: Color(0xFF8FA888),
              ),
              const SizedBox(width: 3),
              Text(
                location,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF8FA888),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroActions extends StatelessWidget {
  const _HeroActions({
    required this.onSell,
    required this.onBuy,
  });

  final VoidCallback onSell;
  final VoidCallback onBuy;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'What would you like to do?',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF8FA888),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _HeroButton(
                emoji: '🌾',
                label: 'Sell',
                sublabel: 'List your resources',
                color: const Color(0xFF2E7D32),
                bg: const Color(0xFFE8F5E9),
                onTap: onSell,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _HeroButton(
                emoji: '🛒',
                label: 'Buy',
                sublabel: 'Browse the market',
                color: const Color(0xFF1565C0),
                bg: const Color(0xFFE3F2FD),
                onTap: onBuy,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _HeroButton extends StatelessWidget {
  const _HeroButton({
    required this.emoji,
    required this.label,
    required this.sublabel,
    required this.color,
    required this.bg,
    required this.onTap,
  });

  final String emoji, label, sublabel;
  final Color color, bg;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(height: 10),
            Text(
              label,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              sublabel,
              style: TextStyle(
                fontSize: 12,
                color: color.withValues(alpha: 0.7),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActivityQuickLook extends StatelessWidget {
  const _ActivityQuickLook({required this.items});

  final List<_ActivityItem> items;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.go(AppRoutes.activity),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFDDE8DD)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0A2E7D32),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            const Row(
              children: [
                Text('📋', style: TextStyle(fontSize: 16)),
                SizedBox(width: 8),
                Text(
                  'My Activity',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A2E1A),
                  ),
                ),
                Spacer(),
                Text(
                  'See all',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2E7D32),
                  ),
                ),
                Icon(Icons.chevron_right, size: 16, color: Color(0xFF2E7D32)),
              ],
            ),
            if (items.isEmpty) ...[
              const SizedBox(height: 20),
              const Center(
                child: Text(
                  'No active transactions yet',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF8FA888),
                  ),
                ),
              ),
              const SizedBox(height: 4),
            ] else ...[
              const SizedBox(height: 12),
              ...items.map((item) => _ActivityRow(item: item)),
            ],
          ],
        ),
      ),
    );
  }
}

class _ActivityItem {
  const _ActivityItem({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.statusLabel,
    required this.statusColor,
    required this.route,
  });

  final String emoji, title, subtitle, statusLabel, route;
  final Color statusColor;
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({required this.item});

  final _ActivityItem item;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFF0F7F0),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(item.emoji, style: const TextStyle(fontSize: 18)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A2E1A),
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  item.subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF8FA888),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: item.statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(99),
            ),
            child: Text(
              item.statusLabel,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: item.statusColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Text(
          "What's Available",
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1A2E1A),
          ),
        ),
        const Spacer(),
        GestureDetector(
          onTap: () => context.go(AppRoutes.browse),
          child: const Text(
            'Filter',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2E7D32),
            ),
          ),
        ),
      ],
    );
  }
}

class _MarketplacePreview extends StatelessWidget {
  const _MarketplacePreview({required this.items});

  final List<_PreviewListing> items;

  @override
  Widget build(BuildContext context) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (ctx, i) {
          if (i >= items.length) return null;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _ListingCard(listing: items[i]),
          );
        },
        childCount: items.length,
      ),
    );
  }
}

class _PreviewListing {
  const _PreviewListing({
    required this.emoji,
    required this.name,
    required this.qty,
    required this.unit,
    required this.price,
    required this.location,
    required this.quality,
  });

  final String emoji, name, qty, unit, price, location, quality;
}

class _ListingCard extends StatelessWidget {
  const _ListingCard({required this.listing});

  final _PreviewListing listing;

  Color get _qualityColor {
    return switch (listing.quality) {
      'Premium' => const Color(0xFF059669),
      'Good' => const Color(0xFF2E7D32),
      'Fair' => const Color(0xFFF59E0B),
      _ => const Color(0xFF9E9E9E),
    };
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.go(AppRoutes.browse),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFDDE8DD)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0A2E7D32),
              blurRadius: 6,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: const BoxDecoration(
                color: Color(0xFFE8F5E9),
                borderRadius: BorderRadius.all(Radius.circular(14)),
              ),
              child: Center(
                child:
                    Text(listing.emoji, style: const TextStyle(fontSize: 26)),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    listing.name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A2E1A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    listing.qty,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF546E4F),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        size: 12,
                        color: Color(0xFF8FA888),
                      ),
                      const SizedBox(width: 2),
                      Text(
                        listing.location,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF8FA888),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: _qualityColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Text(
                          listing.quality,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: _qualityColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  listing.price,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF2E7D32),
                  ),
                ),
                Text(
                  '/ ${listing.unit}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF8FA888),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.chevron_right,
                      size: 16, color: Color(0xFF2E7D32)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
