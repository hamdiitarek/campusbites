import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Shows an image stored either as a full URL or as a Firebase Storage path
/// (what the vendor app writes to `ImagePath`, e.g. `menu_images/latte.jpg`).
class StorageImage extends StatelessWidget {
  final String path;
  final double? width;
  final double? height;
  final BoxFit fit;
  final IconData fallbackIcon;

  const StorageImage(
    this.path, {
    super.key,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.fallbackIcon = Icons.restaurant,
  });

  static final Map<String, Future<String>> _urls = {};

  /// Resolves [path] to a download URL, caching the lookup per path.
  static Future<String> resolve(String path) {
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return SynchronousFuture(path);
    }
    return _urls.putIfAbsent(path, () {
      final storage = FirebaseStorage.instance;
      final ref =
          path.startsWith('gs://') ? storage.refFromURL(path) : storage.ref(path);
      return ref.getDownloadURL().catchError((Object e) {
        _urls.remove(path); // let the next build retry
        throw e;
      });
    });
  }

  Widget _box(Widget? child) => Container(
        width: width,
        height: height,
        color: Colors.grey[200],
        alignment: Alignment.center,
        child: child,
      );

  @override
  Widget build(BuildContext context) {
    if (path.isEmpty) return _box(Icon(fallbackIcon, color: Colors.grey[500]));

    return FutureBuilder<String>(
      future: resolve(path),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _box(Icon(Icons.broken_image, color: Colors.grey[500]));
        }
        if (!snapshot.hasData) return _box(null);
        return CachedNetworkImage(
          imageUrl: snapshot.data!,
          width: width,
          height: height,
          fit: fit,
          fadeInDuration: const Duration(milliseconds: 150),
          placeholder: (_, __) => _box(null),
          errorWidget: (_, __, ___) =>
              _box(Icon(Icons.broken_image, color: Colors.grey[500])),
        );
      },
    );
  }
}
