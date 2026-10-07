import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/role_theme.dart';
import '../../data/services/platform_rules_service.dart';

class RulesScreen extends ConsumerWidget {
  const RulesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rules = ref.watch(platformRulesProvider);
    final svc = ref.read(platformRulesProvider.notifier);
    const theme = RoleTheme.admin;

    return Container(
      color: theme.background,
      child: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          const _SectionHeader(title: 'Bidding', theme: theme),
          _NumberRow(
            theme: theme,
            label: 'Max bid increment',
            sub: 'Per counter-offer round',
            value: rules.maxBidIncrementPct,
            unit: '%',
            onSave: (v) => svc.update((r) => r.copyWith(maxBidIncrementPct: v)),
          ),
          _NumberRow(
            theme: theme,
            label: 'Counter-offer limit',
            sub: 'Rounds before forced close',
            value: rules.counterOfferLimit.toDouble(),
            unit: 'rounds',
            isInt: true,
            onSave: (v) =>
                svc.update((r) => r.copyWith(counterOfferLimit: v.round())),
          ),
          _NumberRow(
            theme: theme,
            label: 'Offer expiry',
            sub: 'Auto-close unanswered offers',
            value: rules.offerExpiryHours.toDouble(),
            unit: 'hrs',
            isInt: true,
            onSave: (v) =>
                svc.update((r) => r.copyWith(offerExpiryHours: v.round())),
          ),
          const SizedBox(height: 16),
          const _SectionHeader(title: 'Payment', theme: theme),
          _NumberRow(
            theme: theme,
            label: 'Payment window',
            sub: 'Pay after offer accepted',
            value: rules.paymentWindowHours.toDouble(),
            unit: 'hrs',
            isInt: true,
            onSave: (v) =>
                svc.update((r) => r.copyWith(paymentWindowHours: v.round())),
          ),
          _NumberRow(
            theme: theme,
            label: 'Platform commission',
            sub: 'Fee per completed order',
            value: rules.commissionPct,
            unit: '%',
            onSave: (v) => svc.update((r) => r.copyWith(commissionPct: v)),
          ),
          const SizedBox(height: 16),
          const _SectionHeader(title: 'Listings', theme: theme),
          _NumberRow(
            theme: theme,
            label: 'Min listing amount',
            sub: 'Reject listings below this',
            value: rules.minListingAmountKes,
            unit: 'KES',
            onSave: (v) =>
                svc.update((r) => r.copyWith(minListingAmountKes: v)),
          ),
          _ToggleRow(
            theme: theme,
            label: 'Listings need review',
            sub: 'Approve before going live',
            value: rules.listingsNeedReview,
            onChanged: (v) =>
                svc.update((r) => r.copyWith(listingsNeedReview: v)),
          ),
          const SizedBox(height: 16),
          const _SectionHeader(title: 'Features', theme: theme),
          _ToggleRow(
            theme: theme,
            label: 'Community orders',
            sub: 'Allow group-buy',
            value: rules.communityOrdersEnabled,
            onChanged: (v) =>
                svc.update((r) => r.copyWith(communityOrdersEnabled: v)),
          ),
          _ToggleRow(
            theme: theme,
            label: 'Driver auto-assign',
            sub: 'Match nearest driver',
            value: rules.driverAutoAssign,
            onChanged: (v) =>
                svc.update((r) => r.copyWith(driverAutoAssign: v)),
          ),
          _ToggleRow(
            theme: theme,
            label: 'Hot demand alerts',
            sub: 'Notify farmers of high demand',
            value: rules.hotDemandAlerts,
            onChanged: (v) =>
                svc.update((r) => r.copyWith(hotDemandAlerts: v)),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final RoleTheme theme;
  const _SectionHeader({required this.title, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 2, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
          color: theme.textMuted,
        ),
      ),
    );
  }
}

class _NumberRow extends StatefulWidget {
  final RoleTheme theme;
  final String label;
  final String sub;
  final double value;
  final String unit;
  final bool isInt;
  final ValueChanged<double> onSave;

  const _NumberRow({
    required this.theme,
    required this.label,
    required this.sub,
    required this.value,
    required this.unit,
    required this.onSave,
    this.isInt = false,
  });

  @override
  State<_NumberRow> createState() => _NumberRowState();
}

class _NumberRowState extends State<_NumberRow> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: _fmt(widget.value));
  }

  @override
  void didUpdateWidget(covariant _NumberRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value && !_dirty) {
      _ctrl.text = _fmt(widget.value);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  bool get _dirty => double.tryParse(_ctrl.text.trim()) != widget.value;

  String _fmt(double v) =>
      widget.isInt ? v.round().toString() : v.toString();

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(theme.cardRadius),
        border: Border.all(color: theme.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: theme.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.sub,
                  style: TextStyle(fontSize: 11, color: theme.textMuted),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 68,
            child: TextField(
              controller: _ctrl,
              keyboardType: TextInputType.numberWithOptions(
                decimal: !widget.isInt,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(
                  widget.isInt ? RegExp(r'[0-9]') : RegExp(r'[0-9.]'),
                ),
              ],
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: theme.textPrimary,
              ),
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 8,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: BorderSide(color: theme.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: BorderSide(color: theme.border),
                ),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          const SizedBox(width: 6),
          SizedBox(
            width: 44,
            child: Text(
              widget.unit,
              style: TextStyle(fontSize: 11, color: theme.textMuted),
            ),
          ),
          _dirty
              ? ElevatedButton(
                  onPressed: () {
                    final v = double.tryParse(_ctrl.text.trim());
                    if (v == null) return;
                    widget.onSave(v);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    minimumSize: const Size(0, 34),
                  ),
                  child: const Text('Save', style: TextStyle(fontSize: 11)),
                )
              : const SizedBox(width: 52),
        ],
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  final RoleTheme theme;
  final String label;
  final String sub;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleRow({
    required this.theme,
    required this.label,
    required this.sub,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(theme.cardRadius),
        border: Border.all(color: theme.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: theme.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(sub, style: TextStyle(fontSize: 11, color: theme.textMuted)),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: theme.primary,
          ),
        ],
      ),
    );
  }
}
