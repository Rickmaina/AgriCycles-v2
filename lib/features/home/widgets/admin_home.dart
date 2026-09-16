import 'package:flutter/material.dart';

import 'info_card.dart';

class AdminHome extends StatelessWidget {
  const AdminHome({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        InfoCard(
          icon: Icons.verified_user,
          title: 'Verification queue',
          body: 'Approve or reject vet, company, and vehicle submissions.',
        ),
        SizedBox(height: 12),
        InfoCard(
          icon: Icons.local_shipping,
          title: 'Logistics',
          body:
              'Every accepted order waits here for pickup assignment.',
        ),
        SizedBox(height: 12),
        InfoCard(
          icon: Icons.gavel,
          title: 'Disputes',
          body:
              'Review quality and payment disputes raised on orders.',
        ),
      ],
    );
  }
}
