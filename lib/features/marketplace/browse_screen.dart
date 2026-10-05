import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/enums.dart';
import '../../core/theme/role_theme.dart';
import '../../data/models/listing_model.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/seed/seed_listings.dart';
import '../../domain/transport_estimator.dart';
import '../../shared/widgets/listing_card.dart';
import 'controllers/marketplace_controller.dart';
import 'screens/make_offer_screen.dart';

/// Role-aware browse. Farmer sees a photo grid. Company sees a dense
/// row list with distance-from-base and a Make-offer CTA.
class BrowseScreen extends ConsumerStatefulWidget {
  const BrowseScreen({super.key});

  @override
  ConsumerState<BrowseScreen> createState() => _BrowseScreenState();
}

class _BrowseScreenState extends ConsumerState<BrowseScreen> {
  String _category = 'All';
  String? _county;
  String _search = '';
  String _sort = 'Nearest';
  double _minQuantity = 0;
  final _searchCtrl = TextEditingController();

  static const _sorts = ['Nearest', 'Cheapest', 'Newest', 'Most quantity'];
  static const _minQuantities = [0.0, 1.0, 5.0, 10.0];

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() {
      setState(() => _search = _searchCtrl.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<ListingModel> _filtered(List<ListingModel> source, String baseCounty) {
    final results = source.where((l) {
      if (!l.isVisibleToPublic) return false;
      final matchCat = _category == 'All' || l.category == _category;
      final matchCounty = _county == null || l.county == _county;
      final matchSearch = _search.isEmpty ||
          l.resourceType.toLowerCase().contains(_search) ||
          (l.description ?? '').toLowerCase().contains(_search);
      final matchQty = l.quantity >= _minQuantity;
      return matchCat && matchCounty && matchSearch && matchQty;
    }).toList();

    switch (_sort) {
      case 'Cheapest':
        results.sort((a, b) => a.pricePerUnit.compareTo(b.pricePerUnit));
        break;
      case 'Newest':
        // Listings don't have createdAt exposed here; fall back to id
        results.sort((a, b) => b.id.compareTo(a.id));
        break;
      case 'Most quantity':
        results.sort((a, b) => b.quantity.compareTo(a.quantity));
        break;
      case 'Nearest':
      default:
        results.sort((a, b) {
          final da = TransportEstimator.distanceKm(
            pickupCounty: baseCounty,
            deliveryCounty: a.county,
          );
          final db = TransportEstimator.distanceKm(
            pickupCounty: baseCounty,
            deliveryCounty: b.county,
          );
          return da.compareTo(db);
        });
    }
    return results;
  }

  @override
  Widget build(BuildContext context) {
    const theme = RoleTheme.farmer;
    final user = ref.watch(authProvider);
    if (user == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final isCompany = user.role == UserRole.company;
    final baseCounty = user.county ?? 'Nairobi';
    final all = ref.watch(allListingsProvider);
    final results = _filtered(all, baseCounty);
    final counties = all.map((l) => l.county).toSet().toList()..sort();

    return Container(
      color: theme.background,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (isCompany) _companyFilterBar(baseCounty),
          _searchBar(theme),
          _categoryChips(theme),
          _countyFilter(theme, counties),
          _resultCount(theme, results.length),
          Expanded(
            child: results.isEmpty
                ? _emptyState(theme)
                : isCompany
                    ? _companyList(results, baseCounty)
                    : _farmerGrid(results),
          ),
        ],
      ),
    );
  }

  Widget _farmerGrid(List<ListingModel> results) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.72,
      ),
      itemCount: results.length,
      itemBuilder: (_, i) {
        final l = results[i];
        return ListingCard(
          listing: l,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => MakeOfferScreen(listing: l),
            ),
          ),
        );
      },
    );
  }

  Widget _companyList(List<ListingModel> results, String baseCounty) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: results.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) => _CompanyRow(
        listing: results[i],
        baseCounty: baseCounty,
      ),
    );
  }

  Widget _searchBar(RoleTheme theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: TextField(
        controller: _searchCtrl,
        decoration: InputDecoration(
          hintText: 'Search supply',
          prefixIcon: const Icon(Icons.search),
          filled: true,
          fillColor: theme.surface,
          contentPadding:
              const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
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
    );
  }

  Widget _companyFilterBar(String baseCounty) {
    const theme = RoleTheme.company;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          Expanded(
            child: _CompanyDropdown<String>(
              value: _sort,
              label: 'Sort',
              options: _sorts,
              theme: theme,
              onChanged: (v) => setState(() => _sort = v),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _CompanyDropdown<double>(
              value: _minQuantity,
              label: 'Min quantity',
              options: _minQuantities,
              theme: theme,
              display: (v) =>
                  v == 0 ? 'Any' : '${v.toStringAsFixed(0)}+ t',
              onChanged: (v) => setState(() => _minQuantity = v),
            ),
          ),
        ],
      ),
    );
  }

  Widget _categoryChips(RoleTheme theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: SizedBox(
        height: 40,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: SeedListings.categories.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (_, i) {
            final c = SeedListings.categories[i];
            final active = c == _category;
            return ChoiceChip(
              label: Text(c),
              selected: active,
              onSelected: (_) => setState(() => _category = c),
              labelStyle: TextStyle(
                color: active ? Colors.white : theme.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
              selectedColor: theme.primary,
              backgroundColor: theme.surface,
              side: BorderSide(color: theme.border),
            );
          },
        ),
      ),
    );
  }

  Widget _countyFilter(RoleTheme theme, List<String> counties) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: theme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.border),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String?>(
            value: _county,
            isExpanded: true,
            hint: Text(
              'All counties',
              style: TextStyle(fontSize: 14, color: theme.textSecondary),
            ),
            items: [
              const DropdownMenuItem<String?>(
                value: null,
                child: Text('All counties'),
              ),
              ...counties.map(
                (c) => DropdownMenuItem<String?>(
                  value: c,
                  child: Text(c),
                ),
              ),
            ],
            onChanged: (v) => setState(() => _county = v),
          ),
        ),
      ),
    );
  }

  Widget _resultCount(RoleTheme theme, int count) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Text(
        '$count listing${count == 1 ? '' : 's'}',
        style: TextStyle(fontSize: 12, color: theme.textMuted),
      ),
    );
  }

  Widget _emptyState(RoleTheme theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off, size: 56, color: theme.textMuted),
            const SizedBox(height: 12),
            Text(
              'Nothing matches',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: theme.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Try changing the filters.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: theme.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Company row
// ─────────────────────────────────────────────────────────────

class _CompanyRow extends StatelessWidget {
  final ListingModel listing;
  final String baseCounty;

  const _CompanyRow({required this.listing, required this.baseCounty});

  @override
  Widget build(BuildContext context) {
    const theme = RoleTheme.company;
    final km = TransportEstimator.distanceKm(
      pickupCounty: baseCounty,
      deliveryCounty: listing.county,
    );

    return Material(
      color: theme.surface,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => MakeOfferScreen(listing: listing),
          ),
        ),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: theme.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      listing.resourceType,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: theme.textPrimary,
                        height: 1.2,
                      ),
                    ),
                  ),
                  if (listing.sellerVerification ==
                      VerificationStatus.approved) ...[
                    const SizedBox(width: 6),
                    Icon(Icons.verified,
                        size: 16, color: theme.primary),
                  ],
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '${listing.sellerName}  ·  ${listing.county}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  color: theme.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    '${listing.quantity} ${listing.unit}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: theme.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 3,
                    height: 3,
                    decoration: BoxDecoration(
                      color: theme.textMuted,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'KES ${listing.pricePerUnit.round()} / ${listing.unit}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: theme.primary,
                    ),
                  ),
                  const Spacer(),
                  if (km > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: theme.primaryMuted,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${km.toStringAsFixed(0)} km',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: theme.primary,
                        ),
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

// ─────────────────────────────────────────────────────────────
// Company dropdown helper
// ─────────────────────────────────────────────────────────────

class _CompanyDropdown<T> extends StatelessWidget {
  final T value;
  final String label;
  final List<T> options;
  final RoleTheme theme;
  final String Function(T)? display;
  final ValueChanged<T> onChanged;

  const _CompanyDropdown({
    required this.value,
    required this.label,
    required this.options,
    required this.theme,
    required this.onChanged,
    this.display,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: theme.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          hint: Text(
            label,
            style: TextStyle(fontSize: 13, color: theme.textSecondary),
          ),
          items: options
              .map((o) => DropdownMenuItem<T>(
                    value: o,
                    child: Text(
                      display != null ? display!(o) : o.toString(),
                      style: const TextStyle(fontSize: 13),
                    ),
                  ))
              .toList(),
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ),
    );
  }
}
