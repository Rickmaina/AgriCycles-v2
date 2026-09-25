import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/enums.dart';
import '../../../core/theme/role_theme.dart';
import '../../../data/services/auth_service.dart';
import '../../../shared/widgets/kpi_strip.dart';
import '../../../shared/widgets/priority_row.dart';
import '../../../shared/widgets/section_header.dart';
import '../../company/screens/company_routes_screen.dart';
import '../../orders/controllers/orders_controller.dart';
import '../../orders/order_detail_screen.dart';

class CompanyHome extends ConsumerWidget {
  const CompanyHome({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider);
    if (user == null) return const SizedBox.shrink();

    const theme = RoleTheme.company;
    final buying = ref.watch(buyingOrdersProvider(user.id));
    final active = buying.where((o) => !o.state.isTerminal).toList();
    final awaitingPickup =
        active.where((o) => o.state == OrderState.paymentSecured).length;
    final inProgress = active
        .where((o) =>
            o.state == OrderState.pickupScheduled ||
            o.state == OrderState.qualityConfirmed)
        .length;
    final totalSpend = active.fold<double>(
      0,
      (sum, o) => sum + (o.quantity * o.pricePerUnit),
    );

    return Container(
      color: theme.background,
      child: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          KpiStrip(
            theme: theme,
            items: [
              KpiItem(
                icon: Icons.receipt_long_outlined,
                label: 'Active',
                value: '${active.length}',
                tone: KpiTone.emphasis,
              ),
              KpiItem(
                icon: Icons.local_shipping_outlined,
                label: 'Awaiting pickup',
                value: '$awaitingPickup',
                tone: awaitingPickup > 0 ? KpiTone.warning : KpiTone.normal,
              ),
              KpiItem(
                icon: Icons.hourglass_bottom_outlined,
                label: 'In progress',
                value: '$inProgress',
              ),
              KpiItem(
                icon: Icons.payments_outlined,
                label: 'Spend',
                value: _shortKes(totalSpend),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _RoutesTile(activeCount: active.length, theme: theme),
          const SizedBox(height: 16),
          SectionHeader(
            theme: theme,
            icon: Icons.priority_high,
            title: 'Needs your attention',
            badge: awaitingPickup > 0 ? '$awaitingPickup' : null,
          ),
          if (active.isEmpty)
            const _EmptyQueue(theme: theme)
          else
            Column(
              children: [
                for (final o in active.take(4))
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: PriorityRow(
                      theme: theme,
                      icon: _iconForState(o.state),
                      title: o.resourceType,
                      subtitle: 'from ${o.sellerName} • ${o.pickupCounty}',
                      trailingValue:
                          '${o.quantity.toStringAsFixed(0)} ${o.unit}',
                      tone: _toneForState(o.state),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => OrderDetailScreen(orderId: o.id),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          const SizedBox(height: 16),
          const SectionHeader(
            theme: theme,
            icon: Icons.bolt_outlined,
            title: 'Quick actions',
          ),
          const _QuickActions(theme: theme),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  String _shortKes(double v) {
    if (v >= 1000000) {
      return '${(v / 1000000).toStringAsFixed(1)}M';
    }
    if (v >= 1000) {
      return '${(v / 1000).toStringAsFixed(0)}K';
    }
    return v.toStringAsFixed(0);
  }

  IconData _iconForState(OrderState s) {
    switch (s) {
      case OrderState.negotiation:
      case OrderState.requested:
        return Icons.swap_horiz;
      case OrderState.accepted:
        return Icons.check_circle_outline;
      case OrderState.paymentSecured:
        return Icons.lock_outline;
      case OrderState.pickupScheduled:
        return Icons.local_shipping_outlined;
      case OrderState.qualityConfirmed:
        return Icons.verified_outlined;
      default:
        return Icons.receipt_long_outlined;
    }
  }

  PriorityTone _toneForState(OrderState s) {
    switch (s) {
      case OrderState.negotiation:
      case OrderState.requested:
        return PriorityTone.attention;
      case OrderState.accepted:
        return PriorityTone.info;
      case OrderState.paymentSecured:
        return PriorityTone.attention;
      case OrderState.pickupScheduled:
      case OrderState.qualityConfirmed:
        return PriorityTone.info;
      default:
        return PriorityTone.neutral;
    }
  }
}

class _RoutesTile extends StatelessWidget {
  final int activeCount;
  final RoleTheme theme;
  const _RoutesTile({required this.activeCount, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: theme.primaryMuted,
      borderRadius: BorderRadius.circular(theme.cardRadius),
      child: InkWell(
        borderRadius: BorderRadius.circular(theme.cardRadius),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => const CompanyRoutesScreen(),
          ),
        ),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(theme.cardRadius),
            border: Border.all(color: theme.primary.withValues(alpha: 0.30)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: theme.primary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.route_outlined,
                    color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Active pickup routes',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: theme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      activeCount == 0
                          ? 'No active pickups yet'
                          : '$activeCount order${activeCount == 1 ? "" : "s"} in progress',
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: theme.primary, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyQueue extends StatelessWidget {
  final RoleTheme theme;
  const _EmptyQueue({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(theme.cardRadius),
        border: Border.all(color: theme.border),
      ),
      child: Row(
        children: [
          Icon(Icons.inbox_outlined, color: theme.textMuted, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Nothing waiting. Browse the market to place an order.',
              style: TextStyle(
                fontSize: 12,
                color: theme.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  final RoleTheme theme;
  const _QuickActions({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _QuickTile(
            theme: theme,
            icon: Icons.storefront_outlined,
            label: 'Browse market',
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _QuickTile(
            theme: theme,
            icon: Icons.groups_outlined,
            label: 'Community orders',
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _QuickTile(
            theme: theme,
            icon: Icons.campaign_outlined,
            label: 'Post a need',
          ),
        ),
      ],
    );
  }
}

class _QuickTile extends StatelessWidget {
  final RoleTheme theme;
  final IconData icon;
  final String label;

  const _QuickTile({
    required this.theme,
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: theme.surface,
      borderRadius: BorderRadius.circular(theme.cardRadius),
      child: InkWell(
        borderRadius: BorderRadius.circular(theme.cardRadius),
        onTap: () {},
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          decoration: BoxDecoration(
            border: Border.all(color: theme.border),
            borderRadius: BorderRadius.circular(theme.cardRadius),
          ),
          child: Column(
            children: [
              Icon(icon, color: theme.primary, size: 22),
              const SizedBox(height: 6),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: theme.textPrimary,
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
