import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Row of pill-style toggles. Used for:
///   - Market tab: Browse / Mine / Offers
///   - Orders tab: Buying / Selling
///   - Verification queue: All / Vets / Companies / Vehicles
/// One component, any number of options.
class SegmentedToggle extends StatelessWidget {
  final List<String> options;
  final int selectedIndex;
  final ValueChanged<int> onChanged;
  final bool expand;

  const SegmentedToggle({
    super.key,
    required this.options,
    required this.selectedIndex,
    required this.onChanged,
    this.expand = true,
  });

  @override
  Widget build(BuildContext context) {
    final children = List.generate(options.length, (i) {
      return _Pill(
        label: options[i],
        active: i == selectedIndex,
        onTap: () => onChanged(i),
        expand: expand,
      );
    });

    if (!expand) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (var i = 0; i < children.length; i++) ...[
              children[i],
              if (i < children.length - 1) const SizedBox(width: 6),
            ],
          ],
        ),
      );
    }

    return Row(
      children: [
        for (var i = 0; i < children.length; i++) ...[
          Expanded(child: children[i]),
          if (i < children.length - 1) const SizedBox(width: 6),
        ],
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  final bool expand;

  const _Pill({
    required this.label,
    required this.active,
    required this.onTap,
    required this.expand,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: active ? AppColors.primary : AppColors.surface,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(
            vertical: 10,
            horizontal: expand ? 0 : 16,
          ),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            border: Border.all(
              color: active ? AppColors.primary : AppColors.border,
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: active ? Colors.white : AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}
