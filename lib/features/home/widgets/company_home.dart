import 'package:flutter/material.dart';

import 'info_card.dart';

class CompanyHome extends StatelessWidget {
  const CompanyHome({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        InfoCard(
          icon: Icons.storefront,
          title: 'Procurement',
          body:
              'Browse listings and make offers. Track open orders in the Orders tab.',
        ),
        SizedBox(height: 12),
        InfoCard(
          icon: Icons.verified,
          title: 'Verified company',
          body:
              'Your badge gives you access to pre-orders and aggregated procurement.',
        ),
        SizedBox(height: 12),
        InfoCard(
          icon: Icons.local_shipping,
          title: 'Admin-mediated pickup',
          body:
              'Every accepted order is picked up and delivered by an Admin-assigned transporter.',
        ),
      ],
    );
  }
}
