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
      case 'elektronik':
        return Icons.devices_rounded;
      case 'perlengkapan-rumah':
        return Icons.home_outlined;
      case 'furnitur':
        return Icons.chair_outlined;
      case 'buku-hobi':
      case 'buku':
      case 'hobi':
        return Icons.menu_book_outlined;
      case 'gratis':
        return Icons.volunteer_activism_outlined;
      default:
        return Icons.grid_view_rounded;
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
      id: 'cat_elektronik',
      name: 'Elektronik',
      slug: 'elektronik',
      icon: Icons.devices_rounded,
    ),
    CategoryModel(
      id: 'cat_perlengkapan_rumah',
      name: 'Perlengkapan Rumah',
      slug: 'perlengkapan-rumah',
      icon: Icons.home_outlined,
    ),
    CategoryModel(
      id: 'cat_furnitur',
      name: 'Furnitur',
      slug: 'furnitur',
      icon: Icons.chair_outlined,
    ),
    CategoryModel(
      id: 'cat_buku_hobi',
      name: 'Buku & Hobi',
      slug: 'buku-hobi',
      icon: Icons.menu_book_outlined,
    ),
    CategoryModel(
      id: 'cat_gratis',
      name: 'Gratis',
      slug: 'gratis',
      icon: Icons.volunteer_activism_outlined,
    ),
  ];
}
