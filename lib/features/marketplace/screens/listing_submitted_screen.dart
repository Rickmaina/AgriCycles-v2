import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_routes.dart';
import '../../../core/theme/role_theme.dart';
import '../../../data/models/listing_model.dart';
import '../../../shared/widgets/farmer_action_button.dart';

/// Success screen shown after a farmer submits a listing for review.
///
/// The listing is in `pendingReview` — it does not appear in the
/// public market until an admin approves it. This screen sets clear
/// expectations and gives two next actions.
class ListingSubmittedScreen extends ConsumerWidget {
  final ListingModel listing;
  const ListingSubmittedScreen({super.key, required this.listing});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const theme = RoleTheme.farmer;

    return Scaffold(
      backgroundColor: theme.background,
      appBar: AppBar(
        backgroundColor: theme.surface,
        foregroundColor: theme.textPrimary,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text('Listing submitted'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 88,
                        height: 88,
                        decoration: BoxDecoration(
                          color: theme.accent.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.schedule,
                          size: 48,
                          color: theme.accent,
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    Text(
                      'Sent for checking',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: theme.textPrimary,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Our team will review your listing before it appears '
                      'in the market. This usually takes a few hours.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: theme.textSecondary,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Preview of what was submitted
                    _preview(theme),

                    const SizedBox(height: 20),
                    _nextSteps(theme),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
              child: Column(
                children: [
                  FarmerActionButton(
                    label: 'Back to home',
                    icon: Icons.home_outlined,
                    onPressed: () => context.go(AppRoutes.home),
                  ),
                  const SizedBox(height: 10),
                  FarmerActionButton(
                    label: 'Sell another',
                    icon: Icons.add,
                    variant: FarmerButtonVariant.secondary,
                    onPressed: () => context.push(AppRoutes.createListing),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _preview(RoleTheme theme) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.border, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your listing',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: theme.textSecondary,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            listing.resourceType,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: theme.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          _line(
            theme,
            'Quantity',
            '${listing.quantity} ${listing.unit}',
          ),
          const SizedBox(height: 4),
          _line(
            theme,
            'Price',
            'KES ${listing.pricePerUnit.round()} / ${listing.unit}',
          ),
          const SizedBox(height: 4),
          _line(
            theme,
            'Pickup',
            '${listing.area}, ${listing.subCounty}, ${listing.county}',
          ),
        ],
      ),
    );
  }

  Widget _line(RoleTheme theme, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 76,
          child: Text(
            label,
            style: TextStyle(fontSize: 12, color: theme.textMuted),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: theme.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _nextSteps(RoleTheme theme) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.primaryMuted,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'What happens next',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: theme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          _bullet(theme, 'We check your listing is accurate.'),
          _bullet(theme, 'Once approved, it appears in the market.'),
          _bullet(
            theme,
            'You will be notified when a buyer shows interest.',
          ),
        ],
      ),
    );
  }

  Widget _bullet(RoleTheme theme, String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 6, right: 8),
            child: Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                color: theme.primary,
                shape: BoxShape.circle,
              ),
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                color: theme.textSecondary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
