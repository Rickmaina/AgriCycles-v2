import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/role_theme.dart';
import '../../data/models/listing_model.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/seed/seed_listings.dart';
import '../../shared/widgets/farmer_distance.dart';
import '../../shared/widgets/farmer_empty_actions.dart';
import '../../shared/widgets/listing_card.dart';
import 'controllers/marketplace_controller.dart';
import 'farmer_listing_detail_screen.dart';

/// Farmer-facing browse. Photo-first cards, one price, one location.
class BrowseScreen extends ConsumerStatefulWidget {
  const BrowseScreen({super.key});

  @override
  ConsumerState<BrowseScreen> createState() => _BrowseScreenState();
}

class _BrowseScreenState extends ConsumerState<BrowseScreen> {
  String _category = 'All';
  String? _county;
  String _search = '';
  final _searchCtrl = TextEditingController();

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

  List<ListingModel> _filtered(List<ListingModel> source) {
    return source.where((l) {
      if (!l.isVisibleToPublic) return false;
      final matchCat = _category == 'All' || l.category == _category;
      final matchCounty = _county == null || l.county == _county;
      final matchSearch = _search.isEmpty ||
          l.resourceType.toLowerCase().contains(_search) ||
          (l.description ?? '').toLowerCase().contains(_search);
      return matchCat && matchCounty && matchSearch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    const theme = RoleTheme.farmer;
    final user = ref.watch(authProvider);
    final all = ref.watch(allListingsProvider);
    final results = _filtered(all);
    final counties = all.map((l) => l.county).toSet().toList()..sort();
    final from = viewerLocationOf(user);

    return Container(
      color: theme.background,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _searchBar(theme),
          _categoryChips(theme),
          _countyFilter(theme, counties),
          _resultCount(theme, results.length),
          Expanded(
            child: results.isEmpty
                ? const FarmerEmptyActions(
                    header: 'Nothing matches. Try selling, buying, or asking.',
                  )
                : GridView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
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
                        distanceLabel: farmerDistanceLabel(
                          listing: l,
                          from: from,
                        ),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                FarmerListingDetailScreen(listing: l),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _searchBar(RoleTheme theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: TextField(
        controller: _searchCtrl,
        decoration: InputDecoration(
          hintText: 'Search what you need',
          prefixIcon: const Icon(Icons.search),
          filled: true,
          fillColor: theme.surface,
          contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
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
}
