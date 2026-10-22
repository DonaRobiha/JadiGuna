import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/listing_provider.dart';
import '../../widgets/listing_card.dart';
import '../../widgets/empty_state.dart';
import 'listing_detail_screen.dart';
import 'add_edit_listing_screen.dart';

class MyListingsScreen extends StatefulWidget {
  const MyListingsScreen({super.key});

  @override
  State<MyListingsScreen> createState() => _MyListingsScreenState();
}

class _MyListingsScreenState extends State<MyListingsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final listingProvider = Provider.of<ListingProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final currentUserId = authProvider.user?.id ?? 'user-current-1';

    final myListings = listingProvider.myListings;
    final availableListings = myListings.where((l) => l.isAvailable).toList();
    final completedListings = myListings.where((l) => l.isCompleted || l.isNegotiating).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Iklan Saya'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          tabs: [
            Tab(text: 'Semua (${myListings.length})'),
            Tab(text: 'Tersedia (${availableListings.length})'),
            Tab(text: 'Proses/Selesai (${completedListings.length})'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildListingsGrid(context, myListings, listingProvider, currentUserId),
          _buildListingsGrid(context, availableListings, listingProvider, currentUserId),
          _buildListingsGrid(context, completedListings, listingProvider, currentUserId),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddEditListingScreen()),
          );
        },
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Pasang Iklan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildListingsGrid(
    BuildContext context,
    List listings,
    ListingProvider listingProvider,
    String currentUserId,
  ) {
    if (listings.isEmpty) {
      return EmptyState(
        icon: Icons.inventory_2_outlined,
        title: 'Belum Ada Iklan',
        message: 'Anda belum memasang iklan di kategori status ini. Mulai tawarkan barang bekas Anda sekarang!',
        buttonText: 'Pasang Iklan Sekarang',
        onButtonPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddEditListingScreen()),
          );
        },
      );
    }

    final userLat = listingProvider.userLocation['latitude'];
    final userLng = listingProvider.userLocation['longitude'];

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.58,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: listings.length,
      itemBuilder: (context, index) {
        final item = listings[index];
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
        );
      },
    );
  }
}
