import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/enums.dart';
import '../../core/theme/role_theme.dart';
import '../../data/services/auth_service.dart';
import 'location_picker.dart';

/// Location input with an opt-in "same as registered" shortcut.
///
/// When the current user has a registered location, shows a checkbox
/// at the top:
///
///   [✓] Same as my registered location
///       Kiambu, Ruiru, Kamakis
///
/// When checked, [onChanged] is called with the registered location
/// and the picker is hidden.
///
/// When the user has no registered location, or unchecks, the full
/// cascading picker is shown.
class RegisteredLocationField extends ConsumerStatefulWidget {
  final LocationSelection? initial;
  final ValueChanged<LocationSelection> onChanged;
  final ValueChanged<String?>? onValidationError;
  final bool required;
  final String checkboxLabel;

  const RegisteredLocationField({
    super.key,
    this.initial,
    required this.onChanged,
    this.onValidationError,
    this.required = true,
    this.checkboxLabel = 'Same as usual',
  });

  @override
  ConsumerState<RegisteredLocationField> createState() =>
      _RegisteredLocationFieldState();
}

class _RegisteredLocationFieldState
    extends ConsumerState<RegisteredLocationField> {
  bool _useRegistered = false;
  late LocationSelection? _manual;

  @override
  void initState() {
    super.initState();
    _manual = widget.initial;
    _useRegistered = _hasRegistered();
    if (_useRegistered) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final reg = _registeredSelection();
        if (reg != null) widget.onChanged(reg);
      });
    }
  }

  bool _hasRegistered() {
    final user = ref.read(authProvider);
    if (user == null) return false;
    return (user.county ?? '').isNotEmpty &&
        (user.subCounty ?? '').isNotEmpty;
  }

  LocationSelection? _registeredSelection() {
    final user = ref.read(authProvider);
    if (user == null) return null;
    if ((user.county ?? '').isEmpty || (user.subCounty ?? '').isEmpty) {
      return null;
    }
    return LocationSelection(
      county: user.county!,
      subCounty: user.subCounty!,
      ward: user.area ?? '',
    );
  }

  String _registeredLabel() {
    final user = ref.watch(authProvider);
    if (user == null) return '';
    final parts = [user.area, user.subCounty, user.county]
        .whereType<String>()
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    return parts.join(', ');
  }

  String get _effectiveLabel {
    // Allow callers to override
    if (widget.checkboxLabel != 'Same as usual') {
      return widget.checkboxLabel;
    }
    // Role-aware default
    final user = ref.read(authProvider);
    if (user?.role == UserRole.company) {
      return 'Use my base location';
    }
    return 'Same as usual';
  }

  @override
  Widget build(BuildContext context) {
    const theme = RoleTheme.farmer;
    final hasRegistered = _hasRegistered();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (hasRegistered) ...[
          _registeredCard(theme),
          const SizedBox(height: 12),
        ],
        if (!_useRegistered) ...[
          LocationPicker(
            initial: _manual,
            onChanged: (sel) {
              setState(() => _manual = sel);
              widget.onChanged(sel);
              widget.onValidationError?.call(null);
            },
            onValidationError: widget.onValidationError,
          ),
        ],
      ],
    );
  }

  Widget _registeredCard(RoleTheme theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _useRegistered ? theme.primary : theme.border,
          width: _useRegistered ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          Checkbox(
            value: _useRegistered,
            onChanged: (v) {
              setState(() => _useRegistered = v ?? false);
              if (_useRegistered) {
                final reg = _registeredSelection();
                if (reg != null) widget.onChanged(reg);
                widget.onValidationError?.call(null);
              }
            },
            activeColor: theme.primary,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _effectiveLabel,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: theme.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _registeredLabel(),
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
