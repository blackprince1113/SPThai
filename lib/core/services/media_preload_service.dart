import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:superthai/core/viewmodels/lesson_view_model.dart';

class MediaPreloadService {
  /// Extracts all unique network image URLs from the given list of lesson steps.
  static Set<String> extractImageUrls(List<LessonStep> steps) {
    final Set<String> urls = {};
    for (final step in steps) {
      final rawUrl = step.rawData?.imageUrl.trim();
      if (rawUrl != null &&
          rawUrl.isNotEmpty &&
          (rawUrl.startsWith('http://') || rawUrl.startsWith('https://'))) {
        urls.add(rawUrl);
      }

      final wordUrl = step.word?.imageUrl.trim();
      if (wordUrl != null &&
          wordUrl.isNotEmpty &&
          (wordUrl.startsWith('http://') || wordUrl.startsWith('https://'))) {
        urls.add(wordUrl);
      }
    }
    return urls;
  }

  /// Filters out URLs that are already cached locally in parallel.
  static Future<List<String>> filterUncachedUrls(Iterable<String> urls) async {
    final cacheManager = DefaultCacheManager();
    final futures = urls.map((url) async {
      try {
        final fileInfo = await cacheManager.getFileFromCache(url);
        if (fileInfo == null || !await fileInfo.file.exists()) {
          return url;
        }
      } catch (_) {
        return url;
      }
      return null;
    });

    final results = await Future.wait(futures);
    return results.whereType<String>().toList();
  }

  /// Estimates the total byte size of the given image URLs via HTTP HEAD requests in parallel.
  static Future<int> getEstimatedTotalBytes(List<String> urls) async {
    if (urls.isEmpty) return 0;

    const int defaultFallbackBytes = 300 * 1024; // 300 KB fallback estimate

    final futures = urls.map((url) async {
      try {
        final response = await http
            .head(Uri.parse(url))
            .timeout(const Duration(milliseconds: 1000));
        if (response.statusCode == 200) {
          final contentLength = response.headers['content-length'];
          if (contentLength != null) {
            final bytes = int.tryParse(contentLength);
            if (bytes != null && bytes > 0) {
              return bytes;
            }
          }
        }
      } catch (_) {
        // Fall back to default estimate quickly if request fails/times out
      }
      return defaultFallbackBytes;
    });

    final results = await Future.wait(futures);
    int totalBytes = 0;
    for (final bytes in results) {
      totalBytes += bytes;
    }

    return totalBytes;
  }

  /// Formats byte size into human-readable string (e.g. "2.3 MB", "450.0 KB").
  static String formatBytes(int bytes) {
    if (bytes <= 0) return '0 B';
    if (bytes < 1024 * 1024) {
      final kb = (bytes / 1024).toStringAsFixed(1);
      return '$kb KB';
    }
    final mb = (bytes / (1024 * 1024)).toStringAsFixed(1);
    return '$mb MB';
  }

  /// Downloads and precaches a list of image URLs, invoking [onProgress] with (completed, total).
  static Future<void> preloadImages(
    List<String> urls,
    BuildContext context, {
    void Function(int completed, int total)? onProgress,
  }) async {
    if (urls.isEmpty) return;

    int completed = 0;
    final total = urls.length;
    onProgress?.call(completed, total);

    for (final url in urls) {
      try {
        await DefaultCacheManager().downloadFile(url).timeout(
          const Duration(seconds: 10),
        );
        if (context.mounted) {
          await precacheImage(
            CachedNetworkImageProvider(url),
            context,
          ).timeout(const Duration(seconds: 5));
        }
      } catch (e) {
        debugPrint('MediaPreloadService: Failed to precache image $url: $e');
      }

      completed++;
      if (context.mounted) {
        onProgress?.call(completed, total);
      }
    }
  }
}
