import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';

import 'controllers/orders_controller.dart';

// ─────────────────────────────────────────────────────────────────────────────
// PaymentCardScreen
//
// Shown when the order needs payment evidence.
// Farmer pays externally (M-Pesa / bank / cash), then submits proof here.
//
// Drop this anywhere with:
//   Get.to(() => PaymentCardScreen(
//     orderId: order.id,
//     amount: order.agreedTotal,
//     currency: 'KES',
//     resourceName: order.resourceName,
//   ));
//
// On submit → call your OrdersController:
//   Get.find<OrdersController>().submitPaymentEvidence(...)
// ─────────────────────────────────────────────────────────────────────────────

class PaymentCardScreen extends ConsumerStatefulWidget {
  const PaymentCardScreen({
    super.key,
    required this.orderId,
    required this.amount,
    this.currency = 'KES',
    required this.resourceName,
  });

  final String orderId;
  final double amount;
  final String currency;
  final String resourceName;

  @override
  ConsumerState<PaymentCardScreen> createState() => _PaymentCardScreenState();
}

class _PaymentCardScreenState extends ConsumerState<PaymentCardScreen> {
  // Design tokens
  static const _green = Color(0xFF2E7D32);
  static const _amber = Color(0xFFF59E0B);
  static const _text1 = Color(0xFF1A2E1A);
  static const _text2 = Color(0xFF546E4F);
  static const _text3 = Color(0xFF8FA888);
  static const _border = Color(0xFFDDE8DD);
  static const _bg = Color(0xFFF5F7F5);

  final _formKey = GlobalKey<FormState>();
  final _refCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();

  String _method = 'mpesa';
  DateTime _paymentDate = DateTime.now();
  bool _submitting = false;

  // ── Payment instructions per method ──────────────────────────────────────
  static const _mpesaDetails = {
    'name': 'AgriCycles Ltd',
    'number': '0712 345 678', // replace with real paybill/number
    'type': 'Send Money / Lipa na M-Pesa',
  };
  static const _bankDetails = {
    'account': '1234567890',
    'bank': 'Equity Bank',
    'branch': 'Nakuru',
    'name': 'AgriCycles Ltd',
  };

  @override
  void dispose() {
    _refCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 1,
        shadowColor: _border,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: _text1),
          onPressed: () => Get.back(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Submit Payment',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: _text1,
              ),
            ),
            Text(
              '#${_shortId(widget.orderId)}',
              style: const TextStyle(fontSize: 11, color: _text3),
            ),
          ],
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Amount banner ─────────────────────────────────────────────
              _AmountBanner(
                amount: widget.amount,
                currency: widget.currency,
                resourceName: widget.resourceName,
                orderId: widget.orderId,
              ),
              const SizedBox(height: 20),

              // ── How did you pay? ──────────────────────────────────────────
              const _Label('How did you pay?'),
              const SizedBox(height: 8),
              Row(
                children: [
                  _MethodTile(
                    id: 'mpesa',
                    icon: '📱',
                    label: 'M-Pesa',
                    selected: _method,
                    onTap: (v) => setState(() => _method = v),
                  ),
                  const SizedBox(width: 8),
                  _MethodTile(
                    id: 'bank',
                    icon: '🏦',
                    label: 'Bank',
                    selected: _method,
                    onTap: (v) => setState(() => _method = v),
                  ),
                  const SizedBox(width: 8),
                  _MethodTile(
                    id: 'cash',
                    icon: '💵',
                    label: 'Cash',
                    selected: _method,
                    onTap: (v) => setState(() => _method = v),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // ── Instructions card ─────────────────────────────────────────
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: _InstructionsCard(
                  key: ValueKey(_method),
                  method: _method,
                  mpesa: _mpesaDetails,
                  bank: _bankDetails,
                ),
              ),
              const SizedBox(height: 20),

              // ── Reference number ──────────────────────────────────────────
              const _Label('Transaction / Reference Number'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _refCtrl,
                textCapitalization: TextCapitalization.characters,
                decoration: _field(
                  hint: _method == 'mpesa'
                      ? 'e.g. QHJ4K8X2R9'
                      : _method == 'bank'
                          ? 'e.g. TRF2024001234'
                          : 'CASH or receipt number',
                  icon: Icons.tag_outlined,
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Enter the reference number from your payment';
                  }
                  if (v.trim().length < 4) return 'Reference too short';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // ── Date paid ─────────────────────────────────────────────────
              const _Label('Date paid'),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _pickDate,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _border),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.calendar_today_outlined,
                        size: 18,
                        color: _text3,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        _formatDate(_paymentDate),
                        style: const TextStyle(
                          fontSize: 14,
                          color: _text1,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Spacer(),
                      const Text(
                        'Change',
                        style: TextStyle(
                          fontSize: 13,
                          color: _green,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ── Optional note ─────────────────────────────────────────────
              const _Label('Note (optional)'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _noteCtrl,
                maxLines: 2,
                decoration: _field(
                  hint: 'Any extra details about your payment',
                  icon: Icons.notes_outlined,
                ),
              ),
              const SizedBox(height: 24),

              // ── Warning ───────────────────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _amber.withValues(alpha: 0.35)),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('⚠️', style: TextStyle(fontSize: 16)),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Only submit after you have actually paid. '
                        'False submissions will suspend your account.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF92400E),
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // ── Submit button ─────────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _submitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _green,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    disabledBackgroundColor: _green.withValues(alpha: 0.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _submitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : const Text(
                          'Submit Payment Evidence',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _paymentDate,
      firstDate: DateTime.now().subtract(const Duration(days: 7)),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: Color(0xFF2E7D32)),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _paymentDate = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        backgroundColor: Colors.white,
        title: const Text(
          'Submit payment?',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 17,
            color: _text1,
          ),
        ),
        content: Text(
          'Reference: ${_refCtrl.text.trim().toUpperCase()}\n\n'
          'Our team will verify this within a few hours.',
          style: const TextStyle(color: _text2, height: 1.5, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: _text3),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D32),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Yes, Submit'),
          ),
        ],
      ),
    );

    if (ok != true) return;

    setState(() => _submitting = true);

    try {
      ref.read(ordersControllerProvider).submitPaymentEvidence(
            orderId: widget.orderId,
            method: _method,
            reference: _refCtrl.text.trim().toUpperCase(),
            date: _paymentDate,
            note: _noteCtrl.text.trim(),
          );

      await Future<void>.delayed(const Duration(milliseconds: 500));

      if (!mounted) return;
      _showSuccess();
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      _showErrorSnack('Could not submit. Please try again.');
    }
  }

  void _showSuccess() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
        ),
        backgroundColor: Colors.white,
        contentPadding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 68,
              height: 68,
              decoration: const BoxDecoration(
                color: Color(0xFFDCFCE7),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_rounded,
                color: Color(0xFF2E7D32),
                size: 34,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Payment submitted ✓',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: _text1,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Our team will verify your payment and notify you. This usually takes a few hours.',
              style: TextStyle(
                fontSize: 13,
                color: _text2,
                height: 1.55,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  Get.back(); // back to order detail
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Back to Order',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showErrorSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                msg,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFFDC2626),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  InputDecoration _field({required String hint, required IconData icon}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: _text3, fontSize: 14),
      prefixIcon: Icon(icon, size: 18, color: _text3),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF2E7D32), width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFDC2626)),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    );
  }

  String _shortId(String id) =>
      id.length > 8 ? id.substring(0, 8).toUpperCase() : id.toUpperCase();

  String _formatDate(DateTime d) {
    const months = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${d.day} ${months[d.month]} ${d.year}';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Amount Banner
// ─────────────────────────────────────────────────────────────────────────────

class _AmountBanner extends StatelessWidget {
  const _AmountBanner({
    required this.amount,
    required this.currency,
    required this.resourceName,
    required this.orderId,
  });

  final double amount;
  final String currency, resourceName, orderId;

  @override
  Widget build(BuildContext context) {
    final formatted = '$currency ${_fmt(amount)}';
    final shortId = orderId.length > 8
        ? orderId.substring(0, 8).toUpperCase()
        : orderId.toUpperCase();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFF4CAF50).withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          const Text(
            'Amount to pay',
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF546E4F),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            formatted,
            style: const TextStyle(
              fontSize: 38,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1B5E20),
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'For: $resourceName',
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF546E4F),
            ),
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: () {
              Clipboard.setData(ClipboardData(text: orderId));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Order ID copied'),
                  duration: Duration(seconds: 2),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(99),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Order: $shortId',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2E7D32),
                      fontFamily: 'monospace',
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.copy_outlined,
                    size: 13,
                    color: Color(0xFF2E7D32),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _fmt(double v) => v.toStringAsFixed(0).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (m) => '${m[1]},',
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Method Tile
// ─────────────────────────────────────────────────────────────────────────────

class _MethodTile extends StatelessWidget {
  const _MethodTile({
    required this.id,
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String id, icon, label, selected;
  final ValueChanged<String> onTap;

  bool get _active => selected == id;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(id),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: _active ? const Color(0xFF2E7D32) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color:
                  _active ? const Color(0xFF2E7D32) : const Color(0xFFDDE8DD),
              width: _active ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Text(icon, style: const TextStyle(fontSize: 22)),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _active ? Colors.white : const Color(0xFF546E4F),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Instructions Card — animated switch between methods
// ─────────────────────────────────────────────────────────────────────────────

class _InstructionsCard extends StatelessWidget {
  const _InstructionsCard({
    super.key,
    required this.method,
    required this.mpesa,
    required this.bank,
  });

  final String method;
  final Map<String, String> mpesa, bank;

  @override
  Widget build(BuildContext context) {
    final steps = switch (method) {
      'mpesa' => [
          'Open M-Pesa on your phone',
          'Select Lipa na M-Pesa → ${mpesa['type']}',
          'Enter number: ${mpesa['number']}',
          'Enter the exact amount shown above',
          'Use your Order ID as the account reference',
          'Save your M-Pesa confirmation message',
          'Enter the confirmation code below',
        ],
      'bank' => [
          'Log in to your mobile banking app or go to a branch',
          'Transfer to: ${bank['name']}',
          'Bank: ${bank['bank']} — Branch: ${bank['branch']}',
          'Account number: ${bank['account']}',
          'Use your Order ID as the payment reference',
          'Save your transaction receipt',
          'Enter the transaction reference below',
        ],
      _ => [
          'Prepare the exact amount listed above',
          'Pay the driver or admin when they arrive',
          'The driver will give you a receipt',
          'Enter "CASH" or the receipt number below',
        ],
    };

    final (icon, title) = switch (method) {
      'mpesa' => ('📱', 'Pay via M-Pesa'),
      'bank' => ('🏦', 'Pay via Bank Transfer'),
      _ => ('💵', 'Pay Cash on Pickup'),
    };

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFDDE8DD)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(icon, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A2E1A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...steps.asMap().entries.map(
                (e) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 22,
                        height: 22,
                        decoration: const BoxDecoration(
                          color: Color(0xFFE8F5E9),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '${e.key + 1}',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF2E7D32),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          e.value,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF546E4F),
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Micro helpers
// ─────────────────────────────────────────────────────────────────────────────

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: Color(0xFF546E4F),
      ),
    );
  }
}
