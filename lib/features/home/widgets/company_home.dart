import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_routes.dart';
import '../../../core/constants/enums.dart';
import '../../../core/theme/role_theme.dart';
import '../../../data/models/listing_model.dart';
import '../../../data/models/order_model.dart';
import '../../../data/services/auth_service.dart';
import '../../../domain/transport_estimator.dart';
import '../../buy_requests/controllers/buy_request_controller.dart';
import '../../marketplace/controllers/marketplace_controller.dart';
import '../../orders/controllers/orders_controller.dart';

/// Company procurement desk. Four blocks, ordered by urgency.
class CompanyHome extends ConsumerWidget {
  const CompanyHome({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const theme = RoleTheme.company;
    final user = ref.watch(authProvider);

    if (user == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final baseCounty = user.county ?? 'Nairobi';

    return Container(
      color: theme.background,
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            _greeting(theme, user.name, baseCounty),
            const SizedBox(height: 20),

            // ── Three primary actions ─────────────────────────
            const _PrimaryActions(),
            const SizedBox(height: 24),

            // ── Needs attention ───────────────────────────────
            _AttentionBlock(ref: ref),

            // ── Supply near you ───────────────────────────────
            const SizedBox(height: 20),
            _SupplyNearYou(baseCounty: baseCounty),

            // ── Open needs summary ────────────────────────────
            const SizedBox(height: 20),
            const _OpenNeedsSummary(),

            // ── This week ─────────────────────────────────────
            const SizedBox(height: 24),
            _ThisWeek(ref: ref),
          ],
        ),
      ),
    );
  }

  Widget _greeting(RoleTheme theme, String name, String county) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Good morning,',
          style: TextStyle(
            fontSize: 14,
            color: theme.textSecondary,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: theme.textPrimary,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Icon(Icons.location_on_outlined,
                size: 14, color: theme.textMuted),
            const SizedBox(width: 4),
            Text(
              county,
              style: TextStyle(
                fontSize: 13,
                color: theme.textSecondary,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Three primary action cards
// ─────────────────────────────────────────────────────────────

class _PrimaryActions extends StatelessWidget {
  const _PrimaryActions();

  @override
  Widget build(BuildContext context) {
    const theme = RoleTheme.company;

    return Row(
      children: [
        Expanded(
          child: _ActionCard(
            icon: Icons.search,
            label: 'Find\nSupply',
            onTap: () => context.go(AppRoutes.market),
            theme: theme,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _ActionCard(
            icon: Icons.campaign_outlined,
            label: 'Post\na Need',
            onTap: () => context.push(AppRoutes.postNeed),
            theme: theme,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _ActionCard(
            icon: Icons.receipt_long_outlined,
            label: 'My\nOrders',
            onTap: () => context.push(AppRoutes.orders),
            theme: theme,
          ),
        ),
      ],
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final RoleTheme theme;

  const _ActionCard({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: theme.primary,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white, size: 28),
              const SizedBox(height: 10),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Needs attention
// ─────────────────────────────────────────────────────────────

class _AttentionBlock extends ConsumerWidget {
  final WidgetRef ref;
  const _AttentionBlock({required this.ref});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const theme = RoleTheme.company;
    final user = ref.watch(authProvider);
    if (user == null) return const SizedBox.shrink();

    final orders = ref.watch(buyingOrdersProvider(user.id));
    final items = _urgencyItems(orders);

    if (items.isEmpty) return const SizedBox.shrink();

    final visible = items.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionHeader(
          theme: theme,
          label: 'Needs attention',
          count: items.length,
        ),
        const SizedBox(height: 8),
        ...visible.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _AttentionRow(item: item, theme: theme),
          ),
        ),
        if (items.length > 3) ...[
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: () => context.push(AppRoutes.orders),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                foregroundColor: theme.primary,
              ),
              child: Text(
                'See all ${items.length} →',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  List<_AttentionItem> _urgencyItems(List<OrderModel> orders) {
    final items = <_AttentionItem>[];
    for (final o in orders) {
      if (o.state == OrderState.accepted) {
        items.add(_AttentionItem(
          orderId: o.id,
          label: 'Payment needed',
          detail: '${o.resourceType} · ${o.sellerName}',
          urgency: _AttentionUrgency.high,
        ));
      } else if (o.state == OrderState.paymentSecured) {
        items.add(_AttentionItem(
          orderId: o.id,
          label: 'Awaiting pickup assignment',
          detail: '${o.resourceType} · ${o.sellerName}',
          urgency: _AttentionUrgency.medium,
        ));
      } else if (o.state == OrderState.qualityConfirmed) {
        items.add(_AttentionItem(
          orderId: o.id,
          label: 'Confirm quality',
          detail: '${o.resourceType} · ${o.sellerName}',
          urgency: _AttentionUrgency.high,
        ));
      } else if (o.state == OrderState.completed) {
        items.add(_AttentionItem(
          orderId: o.id,
          label: 'Release payment',
          detail: '${o.resourceType} · ${o.sellerName}',
          urgency: _AttentionUrgency.medium,
        ));
      } else if (o.state == OrderState.disputed) {
        items.add(_AttentionItem(
          orderId: o.id,
          label: 'Dispute open',
          detail: '${o.resourceType} · ${o.sellerName}',
          urgency: _AttentionUrgency.high,
        ));
      }
    }
    // Sort: high first, then medium
    items.sort((a, b) => a.urgency.index.compareTo(b.urgency.index));
    return items;
  }
}

enum _AttentionUrgency { high, medium }

class _AttentionItem {
  final String orderId;
  final String label;
  final String detail;
  final _AttentionUrgency urgency;
  const _AttentionItem({
    required this.orderId,
    required this.label,
    required this.detail,
    required this.urgency,
  });
}

class _AttentionRow extends StatelessWidget {
  final _AttentionItem item;
  final RoleTheme theme;

  const _AttentionRow({required this.item, required this.theme});

  @override
  Widget build(BuildContext context) {
    final color = item.urgency == _AttentionUrgency.high
        ? theme.danger
        : theme.accent;

    return Material(
      color: theme.surface,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => context.push('/orders/${item.orderId}'),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: color.withValues(alpha: 0.30),
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 6,
                height: 36,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      item.label,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: theme.textPrimary,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.detail,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right,
                  size: 20, color: theme.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Supply near you
// ─────────────────────────────────────────────────────────────

class _SupplyNearYou extends ConsumerWidget {
  final String baseCounty;
  const _SupplyNearYou({required this.baseCounty});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const theme = RoleTheme.company;
    final all = ref.watch(allListingsProvider);

    final visible = all.where((l) => l.isVisibleToPublic).toList();
    if (visible.isEmpty) return const SizedBox.shrink();

    // Sort by distance from base county
    visible.sort((a, b) {
      final da = TransportEstimator.distanceKm(
        pickupCounty: baseCounty,
        deliveryCounty: a.county,
      );
      final db = TransportEstimator.distanceKm(
        pickupCounty: baseCounty,
        deliveryCounty: b.county,
      );
      return da.compareTo(db);
    });

    final top = visible.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _SectionHeader(theme: RoleTheme.company, label: 'Supply near you'),
        const SizedBox(height: 8),
        ...top.map(
          (l) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: _SupplyRow(
              listing: l,
              baseCounty: baseCounty,
              theme: theme,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            onPressed: () => context.go(AppRoutes.market),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              foregroundColor: theme.primary,
            ),
            child: const Text(
              'View all supply →',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SupplyRow extends StatelessWidget {
  final ListingModel listing;
  final String baseCounty;
  final RoleTheme theme;

  const _SupplyRow({
    required this.listing,
    required this.baseCounty,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final km = TransportEstimator.distanceKm(
      pickupCounty: baseCounty,
      deliveryCounty: listing.county,
    );

    return Material(
      color: theme.surface,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => context.go(AppRoutes.market),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: theme.border),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      listing.resourceType,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: theme.textPrimary,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${listing.quantity} ${listing.unit}  ·  '
                      'KES ${listing.pricePerUnit.round()} / ${listing.unit}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.primaryMuted,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  km > 0 ? '${km.toStringAsFixed(0)} km' : '—',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: theme.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Open needs summary
// ─────────────────────────────────────────────────────────────

class _OpenNeedsSummary extends ConsumerWidget {
  const _OpenNeedsSummary();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const theme = RoleTheme.company;
    final user = ref.watch(authProvider);
    if (user == null) return const SizedBox.shrink();

    final needs = ref.watch(myBuyRequestsProvider(user.id));
    final open = needs.where((n) => n.status == BuyRequestStatus.open).toList();

    if (open.isEmpty) return const SizedBox.shrink();

    return Material(
      color: theme.surface,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => context.push(AppRoutes.browseNeeds),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: theme.border),
          ),
          child: Row(
            children: [
              Icon(Icons.campaign_outlined,
                  size: 20, color: theme.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '${open.length} open need${open.length == 1 ? '' : 's'}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: theme.textPrimary,
                  ),
                ),
              ),
              Text(
                'Manage',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: theme.primary,
                ),
              ),
              Icon(Icons.chevron_right,
                  size: 20, color: theme.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// This week
// ─────────────────────────────────────────────────────────────

class _ThisWeek extends ConsumerWidget {
  final WidgetRef ref;
  const _ThisWeek({required this.ref});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const theme = RoleTheme.company;
    final user = ref.watch(authProvider);
    if (user == null) return const SizedBox.shrink();

    final orders = ref.watch(buyingOrdersProvider(user.id));
    final oneWeekAgo = DateTime.now().subtract(const Duration(days: 7));
    final recent = orders.where((o) => o.createdAt.isAfter(oneWeekAgo));

    final count = recent.length;
    final gmv = recent.fold<double>(
      0,
      (sum, o) => sum + (o.quantity * o.pricePerUnit),
    );

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: theme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'This week',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: theme.textSecondary,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _Metric(theme: theme, label: 'Orders', value: '$count'),
              const _MetricDivider(theme: RoleTheme.company),
              _Metric(theme: theme, label: 'GMV', value: _shortKes(gmv)),
              const _MetricDivider(theme: RoleTheme.company),
              const _Metric(
                  theme: RoleTheme.company,
                  label: 'Avg days',
                  value: '—'),
            ],
          ),
        ],
      ),
    );
  }

  String _shortKes(double v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(0)}K';
    return v.toStringAsFixed(0);
  }
}

class _Metric extends StatelessWidget {
  final RoleTheme theme;
  final String label;
  final String value;

  const _Metric({
    required this.theme,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: theme.textPrimary,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: theme.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricDivider extends StatelessWidget {
  final RoleTheme theme;
  const _MetricDivider({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 28,
      color: theme.border,
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Section header
// ─────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final RoleTheme theme;
  final String label;
  final int? count;

  const _SectionHeader({
    required this.theme,
    required this.label,
    this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: theme.textPrimary,
          ),
        ),
        if (count != null && count! > 0) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
            decoration: BoxDecoration(
              color: theme.primary,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$count',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
