import 'dart:convert';

import 'package:flutter/services.dart';

/// Loads the Kenya administrative hierarchy (county → sub-county → ward)
/// from a bundled JSON asset and exposes cascading lookups.
///
/// Pure Dart logic — no widgets. The [LocationPicker] widget consumes
/// this; screens never touch the JSON directly.
///
/// Fixes the original bug where any string could be entered as a
/// sub-county of any county: [isValidPair] and the cascading lookup
/// methods make a mismatched pair structurally impossible from the UI.
class LocationCatalog {
  LocationCatalog._({
    required this.counties,
    required Map<String, List<String>> subCountiesByCounty,
    required Map<String, List<String>> wardsBySubCountyKey,
  })  : _subCountiesByCounty = subCountiesByCounty,
        _wardsBySubCountyKey = wardsBySubCountyKey;

  /// All county names, sorted alphabetically.
  final List<String> counties;

  final Map<String, List<String>> _subCountiesByCounty;
  final Map<String, List<String>> _wardsBySubCountyKey;

  static LocationCatalog? _instance;

  static LocationCatalog? get instanceOrNull => _instance;

  /// Loads the bundled dataset once and caches it.
  /// Throws [StateError] if the asset is missing or malformed.
  static Future<LocationCatalog> load() async {
    if (_instance != null) return _instance!;

    final raw = await rootBundle.loadString('assets/data/kenya_locations.json');
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    final countyList =
        (decoded['counties'] as List).cast<Map<String, dynamic>>();
    if (countyList.length != 47) {
      throw StateError(
        'Kenya location dataset invalid: expected 47 counties, found ${countyList.length}.',
      );
    }

    final subMap = <String, List<String>>{};
    final wardMap = <String, List<String>>{};
    final countyNames = <String>[];

    for (final county in countyList) {
      final countyName = county['name'] as String;
      countyNames.add(countyName);

      final subs =
          (county['sub_counties'] as List).cast<Map<String, dynamic>>();
      subMap[countyName] = subs.map((s) => s['name'] as String).toList();

      for (final sub in subs) {
        final subName = sub['name'] as String;
        final wards = (sub['wards'] as List).cast<String>();
        wardMap[_key(countyName, subName)] = wards;
      }
    }

    countyNames.sort();

    _instance = LocationCatalog._(
      counties: List.unmodifiable(countyNames),
      subCountiesByCounty: Map.unmodifiable(subMap),
      wardsBySubCountyKey: Map.unmodifiable(wardMap),
    );
    return _instance!;
  }

  /// Synchronous accessor — safe to call after [load] has completed.
  /// Throws if called before load.
  static LocationCatalog get instance {
    final i = _instance;
    if (i == null) {
      throw StateError(
        'LocationCatalog.load() must be called before instance is accessed.',
      );
    }
    return i;
  }

  // ─────────────────────────────────────────────────────────────
  // Cascading lookups
  // ─────────────────────────────────────────────────────────────

  /// All sub-counties that actually belong to [county].
  /// Returns empty if [county] is unknown.
  List<String> subCountiesFor(String county) {
    return _subCountiesByCounty[county] ?? const [];
  }

  /// All wards that actually belong to ([county], [subCounty]).
  /// Returns empty if the pair is unknown.
  List<String> wardsFor(String county, String subCounty) {
    return _wardsBySubCountyKey[_key(county, subCounty)] ?? const [];
  }

  /// True when [subCounty] is a real sub-county of [county].
  /// This is the validation the old free-text picker could not do.
  bool isValidPair(String county, String subCounty) {
    return subCountiesFor(county).contains(subCounty);
  }

  /// True when [ward] belongs to ([county], [subCounty]).
  bool isValidWard(String county, String subCounty, String ward) {
    if (ward.isEmpty) return true; // ward is optional
    return wardsFor(county, subCounty).contains(ward);
  }

  // ─────────────────────────────────────────────────────────────
  // Type-ahead support
  // ─────────────────────────────────────────────────────────────

  /// Counties whose name starts with [query] (case-insensitive).
  /// Empty [query] returns all counties.
  List<String> searchCounties(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return counties;
    return counties.where((c) => c.toLowerCase().startsWith(q)).toList();
  }

  /// Sub-counties of [county] whose name starts with [query].
  List<String> searchSubCounties(String county, String query) {
    final list = subCountiesFor(county);
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return list;
    return list.where((s) => s.toLowerCase().startsWith(q)).toList();
  }

  /// Wards of ([county], [subCounty]) whose name starts with [query].
  List<String> searchWards(String county, String subCounty, String query) {
    final list = wardsFor(county, subCounty);
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return list;
    return list.where((w) => w.toLowerCase().startsWith(q)).toList();
  }

  static String _key(String county, String subCounty) => '$county::$subCounty';
}
