import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/enums.dart';
import '../../core/theme/role_theme.dart';
import '../../data/models/order_model.dart';
import '../../data/services/auth_service.dart';
import '../../shared/widgets/farmer_status_icon.dart';
import '../../shared/widgets/segmented_toggle.dart';
import 'controllers/orders_controller.dart';

/// Role-aware orders list.
///
/// Farmer sees Buying / Selling. Company sees Action needed /
/// In progress / Completed / Issues, with denser rows.
class OrdersListScreen extends ConsumerStatefulWidget {
  const OrdersListScreen({super.key});

  @override
  ConsumerState<OrdersListScreen> createState() => _OrdersListScreenState();
}

class _OrdersListScreenState extends ConsumerState<OrdersListScreen> {
  int _tab = 0;

  static const _farmerTabs = ['Buying', 'Selling'];
  static const _companyTabs = [
    'Action needed',
    'In progress',
    'Completed',
    'Issues',
  ];

  @override
  Widget build(BuildContext context) {
    const theme = RoleTheme.farmer;
    final user = ref.watch(authProvider);
    if (user == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final isCompany = user.role == UserRole.company;
    final tabs = isCompany ? _companyTabs : _farmerTabs;

    final orders = isCompany
        ? _companyOrders(user.id, _tab)
        : _farmerOrders(user.id, _tab);

    return Container(
      color: theme.background,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: SegmentedToggle(
              options: tabs,
              selectedIndex: _tab,
              onChanged: (i) => setState(() => _tab = i),
              expand: !isCompany,
            ),
          ),
          Expanded(
            child: orders.isEmpty
                ? _empty(theme, isCompany, _tab)
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    itemCount: orders.length,
                    separatorBuilder: (_, __) =>
                        SizedBox(height: isCompany ? 8 : 10),
                    itemBuilder: (_, i) => _OrderRow(
                      order: orders[i],
                      isBuyer: isCompany || _tab == 0,
                      isCompany: isCompany,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // ── Farmer: Buying / Selling ────────────────────────────────
  List<OrderModel> _farmerOrders(String userId, int tab) {
    return tab == 0
        ? ref.watch(buyingOrdersProvider(userId))
        : ref.watch(sellingOrdersProvider(userId));
  }

  // ── Company: Action / In progress / Completed / Issues ──────
  List<OrderModel> _companyOrders(String userId, int tab) {
    final all = ref.watch(buyingOrdersProvider(userId));
    switch (tab) {
      case 0: // Action needed
        return all.where(_needsCompanyAction).toList();
      case 1: // In progress
        return all.where((o) {
          return o.state == OrderState.paymentSecured ||
              o.state == OrderState.pickupScheduled ||
              o.state == OrderState.qualityConfirmed;
        }).toList();
      case 2: // Completed
        return all.where((o) {
          return o.state == OrderState.completed ||
              o.state == OrderState.paymentReleased ||
              o.state == OrderState.rated;
        }).toList();
      case 3: // Issues
        return all.where((o) {
          return o.state == OrderState.disputed ||
              o.state == OrderState.declined ||
              o.state == OrderState.expired;
        }).toList();
      default:
        return [];
    }
  }

  bool _needsCompanyAction(OrderModel o) {
    return o.state == OrderState.accepted ||
        o.state == OrderState.qualityConfirmed ||
        o.state == OrderState.completed ||
        o.state == OrderState.negotiation;
  }

  Widget _empty(RoleTheme theme, bool isCompany, int tab) {
    final (title, subtitle) = isCompany
        ? _companyEmptyCopy(tab)
        : _farmerEmptyCopy(tab);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 56,
              color: theme.textMuted,
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: theme.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: theme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  (String, String) _farmerEmptyCopy(int tab) {
    return tab == 0
        ? ('No orders yet', 'Find something you need and make an offer.')
        : ('No sales yet', 'Your listings will show orders here.');
  }

  (String, String) _companyEmptyCopy(int tab) {
    switch (tab) {
      case 0:
        return ('Nothing to action', 'You are all caught up.');
      case 1:
        return ('No orders in progress', 'Active procurement shows here.');
      case 2:
        return ('No completed orders yet', 'Finished deals appear here.');
      case 3:
        return ('No issues', 'Disputes and declines would show here.');
      default:
        return ('No orders', '');
    }
  }
}

// ─────────────────────────────────────────────────────────────
// Order row
// ─────────────────────────────────────────────────────────────

class _OrderRow extends StatelessWidget {
  final OrderModel order;
  final bool isBuyer;
  final bool isCompany;

  const _OrderRow({
    required this.order,
    required this.isBuyer,
    required this.isCompany,
  });

  @override
  Widget build(BuildContext context) {
    const theme = RoleTheme.farmer;
    final tone = farmerToneForOrder(order.state);
    final counterparty = isBuyer ? order.sellerName : order.buyerName;
    final prefix = isBuyer ? 'from' : 'to';

    return Material(
      color: theme.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => context.push('/orders/${order.id}'),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: isCompany ? 12 : 14,
            vertical: isCompany ? 10 : 14,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: theme.border, width: 1.5),
          ),
          child: Row(
            children: [
              FarmerStatusIcon(
                tone: tone,
                size: isCompany
                    ? FarmerStatusSize.small
                    : FarmerStatusSize.large,
              ),
              SizedBox(width: isCompany ? 10 : 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            order.resourceType,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: isCompany ? 14 : 16,
                              fontWeight: FontWeight.w700,
                              color: theme.textPrimary,
                              height: 1.2,
                            ),
                          ),
                        ),
                        if (isCompany) ...[
                          const SizedBox(width: 8),
                          _StateChip(state: order.state, theme: theme),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$prefix $counterparty  ·  ${_total()}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: isCompany ? 12 : 13,
                        color: theme.textSecondary,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (!isCompany)
                Icon(
                  Icons.chevron_right,
                  color: theme.textMuted,
                  size: 22,
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _total() {
    final total = order.quantity * order.pricePerUnit;
    final rounded = total.round();
    final s = rounded.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return 'KES ${buf.toString()}';
  }
}

class _StateChip extends StatelessWidget {
  final OrderState state;
  final RoleTheme theme;

  const _StateChip({required this.state, required this.theme});

  @override
  Widget build(BuildContext context) {
    final (label, color) = _style();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  (String, Color) _style() {
    switch (state) {
      case OrderState.requested:
        return ('Requested', theme.accent);
      case OrderState.negotiation:
        return ('Negotiating', theme.accent);
      case OrderState.accepted:
        return ('Payment due', theme.danger);
      case OrderState.paymentSecured:
        return ('Awaiting pickup', theme.info);
      case OrderState.pickupScheduled:
        return ('Pickup set', theme.info);
      case OrderState.qualityConfirmed:
        return ('Confirm quality', theme.accent);
      case OrderState.completed:
        return ('Release payment', theme.accent);
      case OrderState.paymentReleased:
        return ('Paid', theme.primary);
      case OrderState.rated:
        return ('Rated', theme.primary);
      case OrderState.declined:
        return ('Declined', theme.danger);
      case OrderState.expired:
        return ('Expired', theme.textMuted);
      case OrderState.disputed:
        return ('Disputed', theme.danger);
    }
  }
}
