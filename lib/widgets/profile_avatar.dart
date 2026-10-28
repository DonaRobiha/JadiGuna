import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

class ProfileAvatar extends StatelessWidget {
  final String? photo;
  final double radius;

  const ProfileAvatar({super.key, this.photo, this.radius = 30});

  bool _isUrl(String v) =>
      v.startsWith('http://') ||
      v.startsWith('https://') ||
      v.startsWith('blob:') ||
      kIsWeb;

  @override
  Widget build(BuildContext context) {
    final size = radius * 2;
    final placeholder = Icon(
      Icons.person,
      size: radius * 1.1,
      color: AppColors.primary,
    );

    if (photo == null || photo!.trim().isEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: AppColors.primarySurface,
        child: placeholder,
      );
    }

    final source = photo!.trim();
    Widget image;

    if (source.startsWith('assets/')) {
      image = Image.asset(
        source,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stack) => placeholder,
      );
    } else if (_isUrl(source)) {
      image = Image.network(
        source,
        width: size,
        height: size,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return const Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        },
        errorBuilder: (context, error, stack) {
          debugPrint('Foto profil gagal dimuat dari $source -> $error');
          return placeholder;
        },
      );
    } else if (!kIsWeb && File(source).existsSync()) {
      image = Image.file(
        File(source),
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stack) => placeholder,
      );
    } else {
      image = placeholder;
    }

    return CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.primarySurface,
      child: ClipOval(child: image),
    );
  }
}