import 'package:flutter/material.dart';

class CategoryModel {
  final String id;
  final String name;
  final String slug;
  final IconData icon;
  final bool isActive;

  CategoryModel({
    required this.id,
    required this.name,
    required this.slug,
    required this.icon,
    this.isActive = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'slug': slug,
      'is_active': isActive ? 1 : 0,
    };
  }

  factory CategoryModel.fromMap(Map<String, dynamic> map) {
    return CategoryModel(
      id: map['id'] as String,
      name: map['name'] as String,
      slug: map['slug'] as String,
      icon: _getIconForSlug(map['slug'] as String),
      isActive: (map['is_active'] == 1 || map['is_active'] == true),
    );
  }

  static IconData _getIconForSlug(String slug) {
    switch (slug) {
      case 'furnitur':
        return Icons.chair_rounded;
      case 'elektronik':
        return Icons.devices_rounded;
      case 'buku':
        return Icons.menu_book_rounded;
      case 'pakaian':
        return Icons.checkroom_rounded;
      case 'perlengkapan-rumah':
        return Icons.home_rounded;
      case 'alat-olahraga':
        return Icons.fitness_center_rounded;
      case 'hobi-mainan':
        return Icons.sports_esports_rounded;
      default:
        return Icons.category_rounded;
    }
  }

  static List<CategoryModel> defaultCategories = [
    CategoryModel(
      id: 'cat_all',
      name: 'Semua',
      slug: 'semua',
      icon: Icons.grid_view_rounded,
    ),
    CategoryModel(
      id: 'cat_1',
      name: 'Furnitur',
      slug: 'furnitur',
      icon: Icons.chair_rounded,
    ),
    CategoryModel(
      id: 'cat_2',
      name: 'Elektronik',
      slug: 'elektronik',
      icon: Icons.devices_rounded,
    ),
    CategoryModel(
      id: 'cat_3',
      name: 'Buku',
      slug: 'buku',
      icon: Icons.menu_book_rounded,
    ),
    CategoryModel(
      id: 'cat_4',
      name: 'Pakaian',
      slug: 'pakaian',
      icon: Icons.checkroom_rounded,
    ),
    CategoryModel(
      id: 'cat_5',
      name: 'Perlengkapan Rumah',
      slug: 'perlengkapan-rumah',
      icon: Icons.home_rounded,
    ),
    CategoryModel(
      id: 'cat_6',
      name: 'Alat Olahraga',
      slug: 'alat-olahraga',
      icon: Icons.fitness_center_rounded,
    ),
    CategoryModel(
      id: 'cat_7',
      name: 'Hobi & Mainan',
      slug: 'hobi-mainan',
      icon: Icons.sports_esports_rounded,
    ),
  ];
}
