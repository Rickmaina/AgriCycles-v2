import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../data/models/listing_model.dart';
import '../../data/services/mock/mock_listings.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/listing_card.dart';
import 'controllers/marketplace_controller.dart';
import 'make_offer_screen.dart';

class BrowseScreen extends ConsumerStatefulWidget {
  const BrowseScreen({super.key});

  @override
  ConsumerState<BrowseScreen> createState() => _BrowseScreenState();
}

class _BrowseScreenState extends ConsumerState<BrowseScreen> {
  String _category = 'All';
  String? _county;

  List<ListingModel> _filtered(List<ListingModel> source) => source.where((l) {
        final matchCat = _category == 'All' || l.category == _category;
        final matchCounty = _county == null || l.county == _county;
        return matchCat && matchCounty;
      }).toList();

  @override
  Widget build(BuildContext context) {
    final all = ref.watch(allListingsProvider);
    final results = _filtered(all);
    final counties = all.map((l) => l.county).toSet().toList()..sort();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _CategoryChips(
          selected: _category,
          onSelect: (c) => setState(() => _category = c),
        ),
        _CountyFilter(
          counties: counties,
          selected: _county,
          onSelect: (c) => setState(() => _county = c),
        ),
        const Divider(height: 1, color: AppColors.border),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
          child: Text(
            '${results.length} listing${results.length == 1 ? '' : 's'}',
            style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
        ),
        Expanded(
          child: results.isEmpty
              ? const EmptyState(
                  icon: Icons.search_off,
                  title: 'No listings match your filters',
                  subtitle: 'Try clearing the category or county.',
                )
              : GridView.builder(
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
                ),
        ),
      ],
    );
  }
}

class _CategoryChips extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onSelect;

  const _CategoryChips({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: SizedBox(
        height: 40,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: MockListings.categories.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (_, i) {
            final c = MockListings.categories[i];
            final active = c == selected;
            return ChoiceChip(
              label: Text(c),
              selected: active,
              onSelected: (_) => onSelect(c),
              labelStyle: TextStyle(
                color: active ? Colors.white : AppColors.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
              selectedColor: AppColors.primary,
              backgroundColor: AppColors.surface,
              side: const BorderSide(color: AppColors.border),
            );
          },
        ),
      ),
    );
  }
}

class _CountyFilter extends StatelessWidget {
  final List<String> counties;
  final String? selected;
  final ValueChanged<String?> onSelect;

  const _CountyFilter({
    required this.counties,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          const Icon(Icons.filter_alt_outlined,
              size: 18, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String?>(
                value: selected,
                isExpanded: true,
                hint: const Text('All counties',
                    style: TextStyle(
                        fontSize: 14, color: AppColors.textSecondary)),
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('All counties'),
                  ),
                  ...counties.map((c) => DropdownMenuItem<String?>(
                        value: c,
                        child: Text(c),
                      )),
                ],
                onChanged: onSelect,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
