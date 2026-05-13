// lib/screens/seeker/search_results_screen.dart
//
// PURPOSE: Shows search results when a user searches from the home screen.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../core/routes.dart';
import '../../models/service_model.dart';
import '../../providers/service_provider.dart';
import '../../widgets/service_card.dart';

enum _SortBy { relevant, priceLow, priceHigh, rating }

class SearchResultsScreen extends StatefulWidget {
  final String query;

  const SearchResultsScreen({
    super.key,
    required this.query,
  });

  @override
  State<SearchResultsScreen> createState() => _SearchResultsScreenState();
}

class _SearchResultsScreenState extends State<SearchResultsScreen> {
  late TextEditingController _searchController;
  _SortBy _sortBy = _SortBy.relevant;
  String _currentQuery = '';

  @override
  void initState() {
    super.initState();
    _currentQuery = widget.query;
    _searchController = TextEditingController(text: widget.query);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ServiceProvider>().search(_currentQuery);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    setState(() => _currentQuery = query);
    context.read<ServiceProvider>().search(query);
  }

  void _onSearchSubmitted(String query) {
    setState(() => _currentQuery = query);
    context.read<ServiceProvider>().search(query);
    FocusScope.of(context).unfocus();
  }

  List<ServiceModel> _sorted(List<ServiceModel> results) {
    final list = List<ServiceModel>.from(results);
    switch (_sortBy) {
      case _SortBy.relevant:
        break;
      case _SortBy.priceLow:
        list.sort((a, b) => a.basePrice.compareTo(b.basePrice));
        break;
      case _SortBy.priceHigh:
        list.sort((a, b) => b.basePrice.compareTo(a.basePrice));
        break;
      case _SortBy.rating:
        list.sort((a, b) => b.rating.compareTo(a.rating));
        break;
    }
    return list;
  }

  String get _sortLabel {
    switch (_sortBy) {
      case _SortBy.relevant:
        return 'Relevant';
      case _SortBy.priceLow:
        return 'Price ↑';
      case _SortBy.priceHigh:
        return 'Price ↓';
      case _SortBy.rating:
        return 'Top Rated';
    }
  }

  @override
  Widget build(BuildContext context) {
    final sp = context.watch<ServiceProvider>();
    final results = _sorted(sp.filteredServices);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,

      // ── APP BAR ───────────────────────────────────────────────────────
      appBar: AppBar(
        backgroundColor: AppColors.backgroundWhite,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: AppColors.textPrimary,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        titleSpacing: 0,
        title: TextField(
          controller: _searchController,
          autofocus: false,
          onChanged: _onSearchChanged,
          onSubmitted: _onSearchSubmitted,
          textInputAction: TextInputAction.search,
          style: const TextStyle(
            fontSize: 15,
            color: AppColors.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: 'Search services...',
            hintStyle: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 15,
            ),
            border: InputBorder.none,
            filled: true,
            fillColor: AppColors.backgroundField,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            suffixIcon: _currentQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(
                      Icons.close_rounded,
                      size: 18,
                      color: AppColors.textSecondary,
                    ),
                    onPressed: () {
                      _searchController.clear();
                      _onSearchChanged('');
                    },
                  )
                : null,
          ),
        ),
        actions: const [SizedBox(width: AppSpacing.md)],
      ),

      body: Column(
        children: [
          // ── RESULTS COUNT + SORT ROW ─────────────────────────────────
          Container(
            color: AppColors.backgroundWhite,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenPadding,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              children: [
                Text(
                  sp.isLoading
                      ? 'Searching...'
                      : '${results.length} result${results.length == 1 ? '' : 's'}'
                          '${_currentQuery.isNotEmpty ? ' for "$_currentQuery"' : ''}',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: _showSortSheet,
                  child: Row(
                    children: [
                      const Icon(
                        Icons.sort_rounded,
                        size: 16,
                        color: AppColors.accent,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _sortLabel,
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.accent,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: AppColors.border),

          // ── RESULTS LIST ─────────────────────────────────────────────
          Expanded(
            child: sp.isLoading
                ? _buildLoadingState()
                : results.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.screenPadding,
                          vertical: AppSpacing.md,
                        ),
                        physics: const BouncingScrollPhysics(),
                        itemCount: results.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.only(
                              bottom: AppSpacing.md,
                            ),
                            child: ServiceCard(
                              service: results[index],
                              onTap: () => Navigator.pushNamed(
                                context,
                                AppRoutes.serviceDetail,
                                arguments: results[index],
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

  // ── SORT BOTTOM SHEET ─────────────────────────────────────────────────────

  void _showSortSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.backgroundWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              const Text('Sort by', style: AppTextStyles.heading2),
              const SizedBox(height: AppSpacing.md),
              _buildSortTile(
                label: 'Most Relevant',
                subtitle: 'Best match for your search',
                icon: Icons.auto_awesome_rounded,
                value: _SortBy.relevant,
              ),
              _buildSortTile(
                label: 'Price: Low to High',
                subtitle: 'Cheapest services first',
                icon: Icons.arrow_upward_rounded,
                value: _SortBy.priceLow,
              ),
              _buildSortTile(
                label: 'Price: High to Low',
                subtitle: 'Premium services first',
                icon: Icons.arrow_downward_rounded,
                value: _SortBy.priceHigh,
              ),
              _buildSortTile(
                label: 'Top Rated',
                subtitle: 'Highest rated first',
                icon: Icons.star_rounded,
                value: _SortBy.rating,
              ),
              const SizedBox(height: AppSpacing.md),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSortTile({
    required String label,
    required String subtitle,
    required IconData icon,
    required _SortBy value,
  }) {
    final isSelected = _sortBy == value;
    return GestureDetector(
      onTap: () {
        setState(() => _sortBy = value);
        Navigator.pop(context);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.06)
              : AppColors.backgroundField,
          borderRadius: AppRadius.lgRadius,
          border: Border.all(
            color: isSelected
                ? AppColors.primary.withValues(alpha: 0.3)
                : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary.withValues(alpha: 0.1)
                    : AppColors.backgroundWhite,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 18,
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: AppTextStyles.body.copyWith(
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.textPrimary,
                    ),
                  ),
                  Text(subtitle, style: AppTextStyles.caption),
                ],
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle_rounded,
                color: AppColors.primary,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  // ── EMPTY STATE ───────────────────────────────────────────────────────────

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.backgroundField,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.search_off_rounded,
                size: 40,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            const Text('No results found', style: AppTextStyles.heading2),
            const SizedBox(height: AppSpacing.xs),
            Text(
              _currentQuery.isNotEmpty
                  ? 'No services match "$_currentQuery".\nTry a different keyword.'
                  : 'Start typing to search for services.',
              style: AppTextStyles.subtitle,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),
            ElevatedButton.icon(
              onPressed: () {
                _searchController.clear();
                _onSearchChanged('');
              },
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Clear search'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: AppRadius.pillRadius,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── LOADING STATE ─────────────────────────────────────────────────────────

  Widget _buildLoadingState() {
    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      itemCount: 4,
      itemBuilder: (_, __) => Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
        height: 160,
        decoration: BoxDecoration(
          color: AppColors.backgroundField,
          borderRadius: AppRadius.lgRadius,
        ),
      ),
    );
  }
}
