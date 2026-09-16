import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/extensions.dart';
import 'controllers/orders_controller.dart';

class RateOrderScreen extends ConsumerStatefulWidget {
  final String orderId;
  const RateOrderScreen({super.key, required this.orderId});

  @override
  ConsumerState<RateOrderScreen> createState() => _RateOrderScreenState();
}

class _RateOrderScreenState extends ConsumerState<RateOrderScreen> {
  int _stars = 0;
  final _comment = TextEditingController();

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  void _submit() {
    if (_stars == 0) {
      context.showSnack('Pick a star rating first');
      return;
    }
    ref.read(ordersControllerProvider).advance(widget.orderId);
    context.showSnack('Thanks for rating');
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Rate transaction')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 12),
              const Text(
                'How did it go?',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 20, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              const Text(
                'Your rating helps other farmers trade with confidence.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (i) {
                  final n = i + 1;
                  final filled = n <= _stars;
                  return IconButton(
                    onPressed: () => setState(() => _stars = n),
                    iconSize: 44,
                    icon: Icon(
                      filled ? Icons.star : Icons.star_border,
                      color: filled
                          ? AppColors.accent
                          : AppColors.textMuted,
                    ),
                  );
                }),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _comment,
                maxLines: 4,
                maxLength: 200,
                decoration: const InputDecoration(
                  labelText: 'Comment (optional)',
                  hintText: 'Quality, timing, communication…',
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _submit,
                child: const Text('Submit rating'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
