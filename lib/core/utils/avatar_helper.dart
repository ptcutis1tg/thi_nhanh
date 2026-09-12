import 'dart:convert';
import 'package:flutter/material.dart';

/// Parses an avatar string which may be an HTTP/HTTPS URL, a Base64 data URI,
/// or a raw Base64 string, and returns an appropriate [ImageProvider].
///
/// Returns `null` if the input is null, empty, or unparseable.
ImageProvider? parseAvatarImage(String? avatarUrl) {
  if (avatarUrl == null) return null;
  final cleanUrl = avatarUrl.trim();
  if (cleanUrl.isEmpty) return null;

  // 1. External Web Image (e.g. Google avatar, Supabase Storage URL)
  if (cleanUrl.startsWith('http://') || cleanUrl.startsWith('https://')) {
    return NetworkImage(cleanUrl);
  }

  // 2. Base64 Image (data URI or raw Base64)
  try {
    final base64Str = cleanUrl.contains(',') ? cleanUrl.split(',').last : cleanUrl;
    final normalized = base64Str.replaceAll(RegExp(r'\s+'), '');
    final bytes = base64Decode(normalized);
    if (bytes.isEmpty) return null;
    return MemoryImage(bytes);
  } catch (_) {
    return null;
  }
}
