import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/listing_provider.dart';
import '../../widgets/listing_card.dart';
import '../../widgets/empty_state.dart';
import '../listing/listing_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<ListingProvider>(context, listen: false);
    _searchController.text = provider.searchQuery;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showFilterModal(BuildContext context, ListingProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Filter & Urutkan Barang',
                          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                        ),
                        TextButton(
                          onPressed: () {
                            provider.resetFilters();
                            _searchController.clear();
                            setModalState(() {});
                            Navigator.pop(ctx);
                          },
                          child: const Text('Reset'),
                        ),
                      ],
                    ),
                    const Divider(),

                    // Free Items Switch
                    Material(
                      color: Colors.transparent,
                      child: SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Hanya Barang Gratis (Rp 0)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                        subtitle: const Text('Tampilkan barang hibah/pemberian cuma-cuma', style: TextStyle(fontSize: 12)),
                        value: provider.onlyFree,
                        activeThumbColor: AppColors.freeBadge,
                        onChanged: (val) {
                          provider.setOnlyFree(val);
                          setModalState(() {});
                        },
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Category Filter
                    const Text('Kategori Pilihan:', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildCategoryChip(provider, null, 'Semua Kategori', setModalState),
                        ...provider.categories.map((c) => _buildCategoryChip(provider, c.slug, c.name, setModalState)),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Sort By
                    const Text('Urutkan Berdasarkan:', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        _buildSortChip(provider, 'terbaru', 'Terbaru', setModalState),
                        _buildSortChip(provider, 'terdekat', 'Terdekat (LBS)', setModalState),
                        _buildSortChip(provider, 'termurah', 'Harga Termurah', setModalState),
                        _buildSortChip(provider, 'termahal', 'Harga Termahal', setModalState),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Condition Filter
                    const Text('Kondisi Barang:', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        _buildConditionChip(provider, null, 'Semua Kondisi', setModalState),
                        _buildConditionChip(provider, 'Baru', 'Baru', setModalState),
                        _buildConditionChip(provider, 'Sangat Baik', 'Sangat Baik', setModalState),
                        _buildConditionChip(provider, 'Baik', 'Baik', setModalState),
                        _buildConditionChip(provider, 'Perlu Perbaikan', 'Perlu Perbaikan', setModalState),
                      ],
                    ),
                    const SizedBox(height: 24),

                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 46),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Terapkan Filter'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildCategoryChip(ListingProvider provider, String? slug, String label, StateSetter setModalState) {
    final isSelected = (slug == null && (provider.selectedCategorySlug.isEmpty || provider.selectedCategorySlug == 'semua')) ||
        (slug != null && provider.selectedCategorySlug == slug);
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: isSelected ? Colors.white : AppColors.textPrimary,
        ),
      ),
      selected: isSelected,
      selectedColor: AppColors.primary,
      onSelected: (_) {
        provider.setCategory(slug ?? 'semua');
        setModalState(() {});
      },
    );
  }

  Widget _buildSortChip(ListingProvider provider, String sortKey, String label, StateSetter setModalState) {
    final isSelected = provider.sortBy == sortKey;
    return ChoiceChip(
      label: Text(label, style: TextStyle(fontSize: 12, color: isSelected ? Colors.white : AppColors.textPrimary)),
      selected: isSelected,
      selectedColor: AppColors.primary,
      onSelected: (_) {
        provider.setSortBy(sortKey);
        setModalState(() {});
      },
    );
  }

  Widget _buildConditionChip(ListingProvider provider, String? cond, String label, StateSetter setModalState) {
    final isSelected = provider.selectedCondition == cond;
    return ChoiceChip(
      label: Text(label, style: TextStyle(fontSize: 12, color: isSelected ? Colors.white : AppColors.textPrimary)),
      selected: isSelected,
      selectedColor: AppColors.primary,
      onSelected: (_) {
        provider.setCondition(cond);
        setModalState(() {});
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final listingProvider = Provider.of<ListingProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final currentUserId = authProvider.user?.id ?? 'user-current-1';

    final userLat = listingProvider.userLocation['latitude'];
    final userLng = listingProvider.userLocation['longitude'];
    final results = listingProvider.listings;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        titleSpacing: 0,
        title: TextField(
          controller: _searchController,
          autofocus: false,
          decoration: InputDecoration(
            hintText: 'Cari barang, perlengkapan, furnitur...',
            hintStyle: const TextStyle(color: AppColors.textTertiary, fontSize: 14),
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            filled: false,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 18, color: AppColors.textSecondary),
                    onPressed: () {
                      _searchController.clear();
                      listingProvider.setSearchQuery('');
                      setState(() {});
                    },
                  )
                : null,
          ),
          onChanged: (val) {
            listingProvider.setSearchQuery(val);
            setState(() {});
          },
        ),
        actions: [
          IconButton(
            icon: Stack(
              children: [
                const Icon(Icons.tune_rounded, color: AppColors.textPrimary),
                if (listingProvider.onlyFree ||
                    listingProvider.selectedCondition != null ||
                    listingProvider.sortBy != 'terbaru')
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.secondary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            onPressed: () => _showFilterModal(context, listingProvider),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Filter Chips summary row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.white,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  // Only Free Chip
                  FilterChip(
                    label: const Text('Gratis', style: TextStyle(fontSize: 12)),
                    selected: listingProvider.onlyFree,
                    selectedColor: AppColors.freeBadgeBg,
                    checkmarkColor: AppColors.freeBadge,
                    onSelected: (val) => listingProvider.setOnlyFree(val),
                  ),
                  const SizedBox(width: 8),

                  // Sort Label Chip
                  InputChip(
                    avatar: const Icon(Icons.sort, size: 14),
                    label: Text(
                      'Urutan: ${listingProvider.sortBy.toUpperCase()}',
                      style: const TextStyle(fontSize: 12),
                    ),
                    onPressed: () => _showFilterModal(context, listingProvider),
                  ),
                  const SizedBox(width: 8),

                  // Active Category Chip
                  if (listingProvider.selectedCategorySlug.isNotEmpty &&
                      listingProvider.selectedCategorySlug != 'semua') ...[
                    InputChip(
                      avatar: const Icon(Icons.category_outlined, size: 14),
                      label: Text(
                        'Kategori: ${listingProvider.categories.firstWhere((c) => c.slug == listingProvider.selectedCategorySlug, orElse: () => listingProvider.categories.first).name}',
                        style: const TextStyle(fontSize: 12),
                      ),
                      onDeleted: () => listingProvider.setCategory('semua'),
                    ),
                    const SizedBox(width: 8),
                  ],

                  // Active Condition Chip
                  if (listingProvider.selectedCondition != null) ...[
                    InputChip(
                      label: Text(
                        'Kondisi: ${listingProvider.selectedCondition}',
                        style: const TextStyle(fontSize: 12),
                      ),
                      onDeleted: () => listingProvider.setCondition(null),
                    ),
                    const SizedBox(width: 8),
                  ],
                ],
              ),
            ),
          ),
          const Divider(height: 1),

          // Results Grid
          Expanded(
            child: results.isEmpty
                ? const EmptyState(
                    icon: Icons.search_off_rounded,
                    title: 'Barang Tidak Ditemukan',
                    message: 'Tidak ada barang yang cocok dengan kata kunci atau filter saat ini. Coba gunakan kata kunci umum atau ubah filter Anda.',
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.58,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: results.length,
                    itemBuilder: (context, index) {
                      final item = results[index];
                      return ListingCard(
                        listing: item,
                        userLatitude: userLat,
                        userLongitude: userLng,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ListingDetailScreen(listingId: item.id),
                            ),
                          );
                        },
                        onFavoriteToggle: () {
                          listingProvider.toggleFavorite(currentUserId, item);
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
