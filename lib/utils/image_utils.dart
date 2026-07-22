import 'dart:convert';
import 'package:flutter/material.dart';

ImageProvider getProfileImageProvider(String url) {
  if (url.startsWith('data:image')) {
    final base64String = url.split(',').last;
    return MemoryImage(base64Decode(base64String));
  }
  return NetworkImage(url);
}
