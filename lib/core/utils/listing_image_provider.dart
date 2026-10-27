import 'dart:io';

import 'package:flutter/material.dart';

ImageProvider<Object> listingImageProvider(String path) {
  if (path.startsWith('http://') || path.startsWith('https://')) {
    return NetworkImage(path);
  }
  if (path.startsWith('assets/')) {
    return AssetImage(path);
  }
  return FileImage(File(path));
}
