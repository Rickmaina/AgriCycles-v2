import 'package:flutter/material.dart';

import '../../core/constants/enums.dart';
import '../../core/theme/app_colors.dart';

/// One badge for vet, company, or vehicle verification status
/// (Section 4.2). Only the underlying label differs.
class VerificationBadge extends StatelessWidget {
  final VerificationStatus status;
  final String? labelOverride;
  final bool compact;

  const VerificationBadge({
    super.key,
    required this.status,
    this.labelOverride,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final (label, color, icon) = _style();
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: compact ? 12 : 14, color: color),
          SizedBox(width: compact ? 4 : 5),
          Text(
            labelOverride ?? label,
            style: TextStyle(
              fontSize: compact ? 11 : 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  (String, Color, IconData) _style() {
    switch (status) {
      case VerificationStatus.unverified:
        return ('Unverified', AppColors.textMuted, Icons.help_outline);
      case VerificationStatus.pending:
        return ('Pending review', AppColors.warning, Icons.schedule);
      case VerificationStatus.approved:
        return ('Verified', AppColors.success, Icons.verified);
      case VerificationStatus.rejected:
        return ('Rejected', AppColors.danger, Icons.cancel_outlined);
      case VerificationStatus.suspended:
        return ('Suspended', AppColors.danger, Icons.block);
    }
  }
}
