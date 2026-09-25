import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/role_theme.dart';
import '../../data/models/order_model.dart';
import '../../data/services/auth_service.dart';
import '../../shared/widgets/farmer_status_icon.dart';
import '../../shared/widgets/segmented_toggle.dart';
import 'controllers/orders_controller.dart';
import 'order_detail_screen.dart';

/// Farmer orders. Buying / Selling, then one line per order.
class OrdersListScreen extends ConsumerStatefulWidget {
  const OrdersListScreen({super.key});

  @override
  ConsumerState<OrdersListScreen> createState() => _OrdersListScreenState();
}

class _OrdersListScreenState extends ConsumerState<OrdersListScreen> {
  int _tab = 0;

  static const _tabs = ['Buying', 'Selling'];

  @override
  Widget build(BuildContext context) {
    const theme = RoleTheme.farmer;
    final user = ref.watch(authProvider);
    if (user == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final orders = _tab == 0
        ? ref.watch(buyingOrdersProvider(user.id))
        : ref.watch(sellingOrdersProvider(user.id));

    return Container(
      color: theme.background,
      child: Column(
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
            child: orders.isEmpty
                ? _empty(theme)
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    itemCount: orders.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) => _OrderRow(
                      order: orders[i],
                      isBuying: _tab == 0,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _empty(RoleTheme theme) {
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
              _tab == 0 ? 'No orders yet' : 'No sales yet',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: theme.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _tab == 0
                  ? 'Find something you need and make an offer.'
                  : 'Your listings will show orders here.',
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
}

class _OrderRow extends StatelessWidget {
  final OrderModel order;
  final bool isBuying;

  const _OrderRow({required this.order, required this.isBuying});

  @override
  Widget build(BuildContext context) {
    const theme = RoleTheme.farmer;
    final tone = farmerToneForOrder(order.state);
    final counterparty = isBuying ? order.sellerName : order.buyerName;
    final prefix = isBuying ? 'from' : 'to';

    return Material(
      color: theme.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => OrderDetailScreen(orderId: order.id),
          ),
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: theme.border, width: 1.5),
          ),
          child: Row(
            children: [
              FarmerStatusIcon(tone: tone, size: FarmerStatusSize.large),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      order.resourceType,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: theme.textPrimary,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$prefix $counterparty  ·  ${_total()}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        color: theme.textSecondary,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
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
