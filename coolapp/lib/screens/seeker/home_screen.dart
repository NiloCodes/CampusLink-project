// lib/screens/seeker/home_screen.dart
//
// PURPOSE: The main home feed screen for seekers.
// Shows categories, featured services, and a searchable full list.
//
// MATCHES WIREFRAME:
//   ✓ Avatar + "WELCOME BACK / Hi, {name} 👋" header
//   ✓ Bell notification icon
//   ✓ Rounded search bar + filter icon
//   ✓ Categories section with horizontal scroll + "See all"
//   ✓ "Featured for You" section
//   ✓ Vertical service card list
//   ✓ Home | Bookings | Profile bottom nav

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../core/routes.dart';
import '../../models/service_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/service_provider.dart';
import '../../widgets/service_card.dart';
import '../../widgets/category_chip.dart';
import 'service_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _searchController = TextEditingController();
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _navigateToDetail(BuildContext context, ServiceModel service) {
    context.read<ServiceProvider>().setSelectedService(service);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ServiceDetailScreen(service: service),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final sp = context.watch<ServiceProvider>();
    final user = auth.currentUser;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // ── HEADER ─────────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: _buildHeader(user?.fullName ?? 'there'),
            ),

            // ── SEARCH BAR ──────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: _buildSearchBar(sp),
            ),

            // ── CONTENT ─────────────────────────────────────────────────────
            if (sp.isLoading)
              // Loading skeleton
              SliverToBoxAdapter(child: _buildLoadingSkeleton())
            else if (sp.errorMessage != null)
              // Error state
              SliverToBoxAdapter(
                child: _buildErrorState(sp.errorMessage!),
              )
            else if (_isSearching || sp.selectedCategory != null)
              // Search / filtered results
              ..._buildFilteredResults(sp)
            else
              // Normal home feed
              ..._buildHomeFeed(sp),
          ],
        ),
      ),
    );
  }

  // ── HEADER ────────────────────────────────────────────────────────────────

  Widget _buildHeader(String name) {
    final firstName = name.split(' ').first;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenPadding,
        AppSpacing.lg,
        AppSpacing.screenPadding,
        AppSpacing.md,
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.2),
              ),
            ),
            child: Center(
              child: Text(
                firstName.isNotEmpty ? firstName[0].toUpperCase() : 'U',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),

          const SizedBox(width: AppSpacing.md),

          // Greeting
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'WELCOME BACK',
                  style: AppTextStyles.fieldLabel.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                Row(
                  children: [
                    Text(
                      'Hi, $firstName',
                      style: AppTextStyles.heading2,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    const Text('👋', style: TextStyle(fontSize: 18)),
                  ],
                ),
              ],
            ),
          ),

          // Notification bell
          GestureDetector(
            onTap: () {
              // TODO: Notifications screen — Sprint 3
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Notifications coming in Sprint 3'),
                  backgroundColor: AppColors.primary,
                  behavior: SnackBarBehavior.floating,
                  shape:
                      RoundedRectangleBorder(borderRadius: AppRadius.mdRadius),
                ),
              );
            },
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.backgroundWhite,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: const Icon(
                Icons.notifications_outlined,
                size: 22,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── SEARCH BAR ────────────────────────────────────────────────────────────

  Widget _buildSearchBar(ServiceProvider sp) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenPadding,
      ),
      child: Row(
        children: [
          // Search field
          Expanded(
            child: Container(
              height: 50,
              decoration: BoxDecoration(
                color: AppColors.backgroundWhite,
                borderRadius: AppRadius.pillRadius,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (value) {
                  setState(() => _isSearching = value.trim().isNotEmpty);
                  sp.search(value);
                },
                decoration: InputDecoration(
                  hintText: 'Search for tutors, tech repair...',
                  hintStyle: AppTextStyles.caption.copyWith(
                    color: AppColors.textHint,
                  ),
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: AppColors.textSecondary,
                    size: 20,
                  ),
                  suffixIcon: _isSearching
                      ? IconButton(
                          icon: const Icon(
                            Icons.close_rounded,
                            size: 18,
                            color: AppColors.textSecondary,
                          ),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _isSearching = false);
                            sp.clearSearch();
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 14,
                  ),
                  filled: false,
                ),
              ),
            ),
          ),

          const SizedBox(width: AppSpacing.sm),

          // Filter button
          GestureDetector(
            onTap: () => _showFilterSheet(context, sp),
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: sp.selectedCategory != null
                    ? AppColors.primary
                    : AppColors.backgroundWhite,
                borderRadius: AppRadius.mdRadius,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Icon(
                Icons.tune_rounded,
                size: 22,
                color: sp.selectedCategory != null
                    ? Colors.white
                    : AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── HOME FEED (normal state) ───────────────────────────────────────────────

  List<Widget> _buildHomeFeed(ServiceProvider sp) {
    return [
      // Categories section
      SliverToBoxAdapter(
        child: _buildCategoriesSection(sp),
      ),

      // Featured for You section header
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenPadding,
            AppSpacing.lg,
            AppSpacing.screenPadding,
            AppSpacing.md,
          ),
          child: const Text(
            'Featured for You',
            style: AppTextStyles.heading2,
          ),
        ),
      ),

      // Featured service cards
      SliverPadding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.screenPadding,
        ),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final service = sp.featuredServices[index];
              return ServiceCard(
                service: service,
                onTap: () => _navigateToDetail(context, service),
              );
            },
            childCount: sp.featuredServices.length,
          ),
        ),
      ),

      // Bottom padding
      const SliverToBoxAdapter(
        child: SizedBox(height: AppSpacing.xl),
      ),
    ];
  }

  // ── CATEGORIES SECTION ─────────────────────────────────────────────────────

  Widget _buildCategoriesSection(ServiceProvider sp) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenPadding,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Categories', style: AppTextStyles.heading2),
                GestureDetector(
                  onTap: () => _showAllCategories(context, sp),
                  child: Text(
                    'See all',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.accent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.md),

          // Horizontal scrolling category chips
          SizedBox(
            height: 92,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenPadding,
              ),
              itemCount: ServiceCategory.values.length,
              separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.md),
              itemBuilder: (context, index) {
                final category = ServiceCategory.values[index];
                return CategoryChip(
                  category: category,
                  isSelected: sp.selectedCategory == category,
                  onTap: () => sp.selectCategory(category),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ── FILTERED RESULTS ───────────────────────────────────────────────────────

  List<Widget> _buildFilteredResults(ServiceProvider sp) {
    final results = sp.filteredServices;

    return [
      // Results header
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenPadding,
            AppSpacing.lg,
            AppSpacing.screenPadding,
            AppSpacing.sm,
          ),
          child: Row(
            children: [
              Text(
                '${results.length} result${results.length == 1 ? '' : 's'}',
                style: AppTextStyles.heading2,
              ),
              const Spacer(),
              if (sp.isFiltering)
                GestureDetector(
                  onTap: () {
                    sp.clearAllFilters();
                    _searchController.clear();
                    setState(() => _isSearching = false);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.1),
                      borderRadius: AppRadius.pillRadius,
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.close_rounded,
                          size: 14,
                          color: AppColors.error,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Clear filters',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.error,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),

      // Results list or empty state
      if (results.isEmpty)
        SliverToBoxAdapter(child: _buildEmptyState())
      else
        SliverPadding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenPadding,
          ),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final service = results[index];
                return ServiceCard(
                  service: service,
                  onTap: () => _navigateToDetail(context, service),
                );
              },
              childCount: results.length,
            ),
          ),
        ),

      const SliverToBoxAdapter(
        child: SizedBox(height: AppSpacing.xl),
      ),
    ];
  }

  // ── LOADING SKELETON ────────────────────────────────────────────────────────

  Widget _buildLoadingSkeleton() {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      child: Column(
        children: List.generate(3, (index) {
          return Container(
            margin: const EdgeInsets.only(bottom: AppSpacing.md),
            height: 280,
            decoration: BoxDecoration(
              color: AppColors.backgroundField,
              borderRadius: AppRadius.lgRadius,
            ),
          );
        }),
      ),
    );
  }

  // ── EMPTY STATE ─────────────────────────────────────────────────────────────

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      child: Column(
        children: [
          const Icon(
            Icons.search_off_rounded,
            size: 64,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: AppSpacing.md),
          const Text(
            'No services found',
            style: AppTextStyles.heading2,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Try a different search or category.',
            style: AppTextStyles.subtitle,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.lg),
          TextButton(
            onPressed: () {
              context.read<ServiceProvider>().clearAllFilters();
              _searchController.clear();
              setState(() => _isSearching = false);
            },
            child: const Text('Clear filters'),
          ),
        ],
      ),
    );
  }

  // ── ERROR STATE ─────────────────────────────────────────────────────────────

  Widget _buildErrorState(String message) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      child: Column(
        children: [
          const Icon(
            Icons.wifi_off_rounded,
            size: 64,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            message,
            style: AppTextStyles.subtitle,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.lg),
          ElevatedButton(
            onPressed: () => context.read<ServiceProvider>().initFeed(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: AppRadius.pillRadius),
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  // ── FILTER BOTTOM SHEET ────────────────────────────────────────────────────

  void _showFilterSheet(BuildContext context, ServiceProvider sp) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.backgroundWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
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
            const Text('Filter by Category', style: AppTextStyles.heading2),
            const SizedBox(height: AppSpacing.lg),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: ServiceCategory.values.map((cat) {
                final isSelected = sp.selectedCategory == cat;
                return GestureDetector(
                  onTap: () {
                    sp.selectCategory(cat);
                    Navigator.pop(context);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.backgroundField,
                      borderRadius: AppRadius.pillRadius,
                    ),
                    child: Text(
                      '${cat.emoji}  ${cat.fullDisplayName}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color:
                            isSelected ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: AppSpacing.lg),
            if (sp.selectedCategory != null)
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () {
                    sp.clearCategoryFilter();
                    Navigator.pop(context);
                  },
                  child: const Text('Clear filter'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ── SEE ALL CATEGORIES ─────────────────────────────────────────────────────

  void _showAllCategories(BuildContext context, ServiceProvider sp) {
    _showFilterSheet(context, sp);
  }
}
