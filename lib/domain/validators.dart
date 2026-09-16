/// Pure validation functions. Return null when valid; return an error
/// string when invalid. Matches Flutter's TextFormField.validator
/// signature so callers can pass these directly.
class Validators {
  Validators._();

  // ─────────────────────────────────────────────────────────────
  // Identity
  // ─────────────────────────────────────────────────────────────

  static String? requiredText(String? v, {String label = 'Field'}) {
    if (v == null || v.trim().isEmpty) return '$label is required';
    return null;
  }

  static String? phone(String? v) {
    if (v == null || v.trim().isEmpty) return 'Phone is required';
    final digits = v.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 9) return 'Enter a valid phone number';
    if (digits.length > 13) return 'Phone number is too long';
    return null;
  }

  static String? email(String? v) {
    if (v == null || v.trim().isEmpty) return null; // email is optional
    final re = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!re.hasMatch(v.trim())) return 'Enter a valid email';
    return null;
  }

  // ─────────────────────────────────────────────────────────────
  // Numbers
  // ─────────────────────────────────────────────────────────────

  static String? positiveNumber(
    String? v, {
    String label = 'Value',
    double? max,
  }) {
    final d = double.tryParse(v?.trim() ?? '');
    if (d == null || d <= 0) return 'Enter a number';
    if (max != null && d > max) return 'Maximum is ${max.toStringAsFixed(0)}';
    return null;
  }

  static String? quantity(
    String? v, {
    required double available,
    String unit = '',
  }) {
    final d = double.tryParse(v?.trim() ?? '');
    if (d == null || d <= 0) return 'Enter a number';
    if (d > available) {
      final u = unit.isEmpty ? '' : ' $unit';
      return 'Only ${available.toStringAsFixed(1)}$u available';
    }
    return null;
  }

  // ─────────────────────────────────────────────────────────────
  // Vehicles
  // ─────────────────────────────────────────────────────────────

  static String? plateNumber(String? v) {
    if (v == null || v.trim().length < 5) return 'Enter plate number';
    if (v.trim().length > 10) return 'Plate number is too long';
    return null;
  }

  // ─────────────────────────────────────────────────────────────
  // Location
  // ─────────────────────────────────────────────────────────────

  static String? county(String? v) {
    if (v == null || v.trim().isEmpty) return 'Select a county';
    return null;
  }
}
