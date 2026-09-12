import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onthi_community/core/utils/avatar_helper.dart';

void main() {
  group('AvatarHelper parseAvatarImage Tests', () {
    test('returns null for null, empty or whitespace strings', () {
      expect(parseAvatarImage(null), isNull);
      expect(parseAvatarImage(''), isNull);
      expect(parseAvatarImage('   '), isNull);
    });

    test('returns NetworkImage for http and https URLs', () {
      const googleUrl =
          'https://lh3.googleusercontent.com/a/ACg8ocIx8JEiFo424OguNirRpw1K2vG44AUbvmg';
      final imageProvider = parseAvatarImage(googleUrl);
      expect(imageProvider, isA<NetworkImage>());
      expect((imageProvider as NetworkImage).url, googleUrl);

      const httpUrl = 'http://example.com/avatar.png';
      final httpProvider = parseAvatarImage(httpUrl);
      expect(httpProvider, isA<NetworkImage>());
      expect((httpProvider as NetworkImage).url, httpUrl);
    });

    test('returns MemoryImage for valid base64 strings and data URIs', () {
      final sampleBytes = utf8.encode('test image content');
      final rawBase64 = base64Encode(sampleBytes);
      final dataUri = 'data:image/png;base64,$rawBase64';

      final rawProvider = parseAvatarImage(rawBase64);
      expect(rawProvider, isA<MemoryImage>());
      expect((rawProvider as MemoryImage).bytes, sampleBytes);

      final uriProvider = parseAvatarImage(dataUri);
      expect(uriProvider, isA<MemoryImage>());
      expect((uriProvider as MemoryImage).bytes, sampleBytes);
    });

    test('returns null gracefully without throwing for invalid/malformed base64 strings', () {
      expect(parseAvatarImage('invalid base64 content with special symbols @@@!'), isNull);
    });
  });
}
