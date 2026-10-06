import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/role_theme.dart';
import '../controllers/orders_controller.dart';

/// Rate order dialog. Star picker + optional comment. On submit,
/// advances the order to `rated` and closes.
Future<void> showRateOrderDialog({
  required BuildContext context,
  required WidgetRef ref,
  required String orderId,
}) async {
  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => _RateOrderDialog(
      orderId: orderId,
      onSubmit: () {
        ref.read(ordersControllerProvider).advance(orderId);
      },
    ),
  );
}

class _RateOrderDialog extends StatefulWidget {
  final String orderId;
  final VoidCallback onSubmit;

  const _RateOrderDialog({
    required this.orderId,
    required this.onSubmit,
  });

  @override
  State<_RateOrderDialog> createState() => _RateOrderDialogState();
}

class _RateOrderDialogState extends State<_RateOrderDialog> {
  int _stars = 0;
  final _comment = TextEditingController();

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  void _submit() {
    if (_stars == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pick a star rating first'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    widget.onSubmit();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    const theme = RoleTheme.farmer;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'How did it go?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: theme.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Your rating helps other farmers trade with confidence.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: theme.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 22),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (i) {
                  final n = i + 1;
                  final filled = n <= _stars;
                  return IconButton(
                    onPressed: () => setState(() => _stars = n),
                    iconSize: 40,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 44,
                      minHeight: 44,
                    ),
                    icon: Icon(
                      filled ? Icons.star : Icons.star_border,
                      color: filled ? theme.accent : theme.textMuted,
                    ),
                  );
                }),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _comment,
                maxLines: 3,
                maxLength: 200,
                decoration: InputDecoration(
                  labelText: 'Comment (optional)',
                  hintText: 'Quality, timing, communication',
                  filled: true,
                  fillColor: theme.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: theme.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: theme.border),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(46),
                        foregroundColor: theme.textSecondary,
                        side: BorderSide(color: theme.border),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(46),
                      ),
                      child: const Text('Submit'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
