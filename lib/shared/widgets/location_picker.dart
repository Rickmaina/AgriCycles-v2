import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../domain/location_catalog.dart';

/// Result of a location selection. All fields are consistent by
/// construction: the picker only lets the user choose a sub-county
/// that exists in the selected county, and a ward that exists in the
/// selected sub-county.
class LocationSelection {
  final String county;
  final String subCounty;
  final String ward;

  const LocationSelection({
    required this.county,
    required this.subCounty,
    required this.ward,
  });
}

/// Cascading county → sub-county → ward picker with type-ahead search.
///
/// Replaces the old free-text sub-county / area fields that allowed
/// the Siaya-as-sub-county-of-Nakuru bug. Because each step's options
/// are filtered by [LocationCatalog], it is impossible to select a
/// mismatched pair through the UI.
///
/// Usage:
/// ```dart
/// LocationPicker(
///   initial: LocationSelection(county: 'Nakuru', subCounty: '', ward: ''),
///   onChanged: (sel) => setState(() => _location = sel),
///   onValidationError: (msg) => setState(() => _error = msg),
/// )
/// ```
class LocationPicker extends StatefulWidget {
  final LocationSelection? initial;
  final ValueChanged<LocationSelection>? onChanged;
  final ValueChanged<String?>? onValidationError;
  final bool required;
  final String? label;

  const LocationPicker({
    super.key,
    this.initial,
    this.onChanged,
    this.onValidationError,
    this.required = true,
    this.label,
  });

  @override
  State<LocationPicker> createState() => _LocationPickerState();
}

class _LocationPickerState extends State<LocationPicker> {
  late final TextEditingController _countyCtrl;
  late final TextEditingController _subCountyCtrl;
  late final TextEditingController _wardCtrl;

  LocationCatalog? _catalog;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _countyCtrl = TextEditingController(text: widget.initial?.county ?? '');
    _subCountyCtrl =
        TextEditingController(text: widget.initial?.subCounty ?? '');
    _wardCtrl = TextEditingController(text: widget.initial?.ward ?? '');
    _loadCatalog();
  }

  Future<void> _loadCatalog() async {
    final catalog = await LocationCatalog.load();
    if (!mounted) return;
    setState(() {
      _catalog = catalog;
      _loading = false;
    });
  }

  @override
  void dispose() {
    _countyCtrl.dispose();
    _subCountyCtrl.dispose();
    _wardCtrl.dispose();
    super.dispose();
  }

  void _commit() {
    final catalog = _catalog;
    if (catalog == null) return;

    final county = _countyCtrl.text.trim();
    final subCounty = _subCountyCtrl.text.trim();
    final ward = _wardCtrl.text.trim();

    // Validate consistency.
    if (widget.required && county.isEmpty) {
      _setError('County is required');
      return;
    }
    if (widget.required && subCounty.isEmpty) {
      _setError('Sub-county is required');
      return;
    }
    if (county.isNotEmpty && subCounty.isNotEmpty) {
      if (!catalog.isValidPair(county, subCounty)) {
        _setError('"$subCounty" is not a sub-county of $county');
        return;
      }
    }
    if (county.isNotEmpty && subCounty.isNotEmpty && ward.isNotEmpty) {
      if (!catalog.isValidWard(county, subCounty, ward)) {
        _setError('"$ward" is not a ward of $subCounty');
        return;
      }
    }

    _setError(null);
    widget.onChanged?.call(LocationSelection(
      county: county,
      subCounty: subCounty,
      ward: ward,
    ));
  }

  void _setError(String? msg) {
    setState(() => _error = msg);
    widget.onValidationError?.call(msg);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    final catalog = _catalog!;
    final countyLocked = _countyCtrl.text.trim().isEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.label != null) ...[
          Text(
            widget.label!,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
        ],

        // County
        _SearchField(
          controller: _countyCtrl,
          label: 'County',
          placeholder: 'Start typing…',
          optionsFor: (q) => catalog.searchCounties(q),
          onSelected: (v) {
            setState(() {
              _countyCtrl.text = v;
              // Clear downstream fields — they may not be valid under
              // the new county.
              _subCountyCtrl.clear();
              _wardCtrl.clear();
              _error = null;
            });
            _commit();
          },
        ),
        const SizedBox(height: 12),

        // Sub-county — only enabled after county is chosen
        _SearchField(
          controller: _subCountyCtrl,
          label: 'Sub-county',
          placeholder: countyLocked
              ? 'Select a county first'
              : 'Start typing…',
          enabled: !countyLocked,
          optionsFor: (q) => countyLocked
              ? const []
              : catalog.searchSubCounties(_countyCtrl.text.trim(), q),
          onSelected: (v) {
            setState(() {
              _subCountyCtrl.text = v;
              _wardCtrl.clear();
              _error = null;
            });
            _commit();
          },
        ),
        const SizedBox(height: 12),

        // Ward — optional, only enabled after sub-county is chosen
        _SearchField(
          controller: _wardCtrl,
          label: 'Ward / Area (optional)',
          placeholder: _subCountyCtrl.text.trim().isEmpty
              ? 'Select a sub-county first'
              : 'Start typing…',
          enabled: _subCountyCtrl.text.trim().isNotEmpty,
          optionsFor: (q) => _subCountyCtrl.text.trim().isEmpty
              ? const []
              : catalog.searchWards(
                  _countyCtrl.text.trim(),
                  _subCountyCtrl.text.trim(),
                  q,
                ),
          onSelected: (v) {
            setState(() {
              _wardCtrl.text = v;
              _error = null;
            });
            _commit();
          },
        ),

        if (_error != null) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.danger.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppColors.danger.withValues(alpha: 0.25),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline,
                    size: 16, color: AppColors.danger),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _error!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.danger,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

/// A single-step search field. Tapping it opens a bottom sheet of
/// matching options; picking one calls [onSelected].
class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String placeholder;
  final bool enabled;
  final List<String> Function(String query) optionsFor;
  final ValueChanged<String> onSelected;

  const _SearchField({
    required this.controller,
    required this.label,
    required this.placeholder,
    required this.optionsFor,
    required this.onSelected,
    this.enabled = true,
  });

  Future<void> _open(BuildContext context) async {
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _SearchSheet(
        title: label,
        placeholder: placeholder,
        optionsFor: optionsFor,
      ),
    );
    if (result != null) onSelected(result);
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enabled ? () => _open(context) : null,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: enabled ? AppColors.surfaceAlt : AppColors.surfaceAlt.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: enabled ? AppColors.border : AppColors.border.withValues(alpha: 0.5),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: enabled
                          ? AppColors.textMuted
                          : AppColors.textMuted.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    controller.text.isEmpty ? placeholder : controller.text,
                    style: TextStyle(
                      fontSize: 14,
                      color: controller.text.isEmpty
                          ? AppColors.textMuted
                          : AppColors.textPrimary,
                      fontWeight: controller.text.isEmpty
                          ? FontWeight.w400
                          : FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.expand_more,
              size: 20,
              color: enabled
                  ? AppColors.textMuted
                  : AppColors.textMuted.withValues(alpha: 0.4),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchSheet extends StatefulWidget {
  final String title;
  final String placeholder;
  final List<String> Function(String query) optionsFor;

  const _SearchSheet({
    required this.title,
    required this.placeholder,
    required this.optionsFor,
  });

  @override
  State<_SearchSheet> createState() => _SearchSheetState();
}

class _SearchSheetState extends State<_SearchSheet> {
  final _search = TextEditingController();
  List<String> _results = const [];

  @override
  void initState() {
    super.initState();
    _results = widget.optionsFor('');
    _search.addListener(_onSearch);
  }

  void _onSearch() {
    setState(() => _results = widget.optionsFor(_search.text));
  }

  @override
  void dispose() {
    _search.removeListener(_onSearch);
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: viewInsets),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  widget.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                controller: _search,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: widget.placeholder,
                  prefixIcon: const Icon(Icons.search, size: 20),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Flexible(
              child: _results.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(32),
                      child: Text(
                        'No matches',
                        style: TextStyle(color: AppColors.textMuted),
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: _results.length,
                      itemBuilder: (_, i) {
                        final item = _results[i];
                        return ListTile(
                          title: Text(item),
                          onTap: () => Navigator.pop(context, item),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
