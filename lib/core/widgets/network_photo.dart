import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../constants/api_constants.dart';

/// A photo from the network, for every product/alternative image in the app:
/// - kept on the phone (disk cache via `cached_network_image`), so it shows instantly after the
///   first load, also after an app restart;
/// - [placeholder] while loading and on error (never an empty box), then a short fade-in;
/// - a Cloudinary photo (products are copied there by the backend) is requested at the size it is
///   shown, e.g. 256 px for a 62 px thumbnail instead of the stored 800 px.
///
/// Only the image itself: the caller keeps its own frame, clip and background.
class NetworkPhoto extends StatelessWidget {
  /// Absolute URL, or a backend-relative path (`/static/...`), or null (shows [placeholder]).
  final String? url;
  final Widget placeholder;

  /// Shown on error; defaults to [placeholder].
  final Widget? error;
  final BoxFit fit;
  final double? width;
  final double? height;

  /// Decode size limits in pixels (for big non-Cloudinary originals, e.g. shop photos).
  final int? memCacheWidth;
  final int? memCacheHeight;

  const NetworkPhoto({
    super.key,
    required this.url,
    required this.placeholder,
    this.error,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.memCacheWidth,
    this.memCacheHeight,
  });

  @override
  Widget build(BuildContext context) {
    final resolved = ApiConstants.resolveMediaUrl(url);
    if (resolved == null || resolved.isEmpty) return placeholder;
    return LayoutBuilder(
      builder: (context, box) {
        final side = _displaySide(box);
        final px = side == null
            ? null
            : (side * MediaQuery.devicePixelRatioOf(context)).ceil();
        return CachedNetworkImage(
          imageUrl: px == null ? resolved : cloudinarySized(resolved, px),
          fit: fit,
          width: width,
          height: height,
          memCacheWidth: memCacheWidth,
          memCacheHeight: memCacheHeight,
          fadeInDuration: const Duration(milliseconds: 200),
          fadeOutDuration: Duration.zero,
          placeholder: (_, _) => placeholder,
          errorWidget: (_, _, _) => error ?? placeholder,
        );
      },
    );
  }

  /// The larger side the photo is drawn at (logical px), when known.
  double? _displaySide(BoxConstraints box) {
    final w = width ?? (box.hasBoundedWidth ? box.maxWidth : null);
    final h = height ?? (box.hasBoundedHeight ? box.maxHeight : null);
    if (w == null && h == null) return null;
    return [w ?? 0, h ?? 0].reduce((a, b) => a > b ? a : b);
  }
}

/// Size steps asked from Cloudinary: few distinct sizes = more cache hits (CDN and phone).
const _cloudinarySteps = [128, 256, 512, 800];

/// For a Cloudinary upload URL without its own transformation, asks for a version at most
/// [px] wide/high (rounded up to a step; never upscaled). Any other URL is returned unchanged.
String cloudinarySized(String url, int px) {
  final uri = Uri.tryParse(url);
  if (uri == null || uri.host != 'res.cloudinary.com') return url;
  final segments = uri.pathSegments;
  final at = segments.indexOf('upload');
  if (at < 2 || segments[at - 1] != 'image' || at + 1 >= segments.length) {
    return url;
  }
  // A transformation segment is comma-separated short params (`w_200,c_fill`); a folder such as
  // `product_images` or a version `v123` is not.
  final transformation = RegExp(r'^[a-z]{1,3}_[^,/]+(,[a-z]{1,3}_[^,/]+)*$');
  if (transformation.hasMatch(segments[at + 1])) return url; // keep its own
  final step = _cloudinarySteps.firstWhere(
    (s) => s >= px,
    orElse: () => _cloudinarySteps.last,
  );
  return uri
      .replace(
        pathSegments: [
          ...segments.take(at + 1),
          'c_limit,w_$step,h_$step,q_auto',
          ...segments.skip(at + 1),
        ],
      )
      .toString();
}
