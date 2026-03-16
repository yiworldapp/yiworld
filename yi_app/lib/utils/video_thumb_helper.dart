// Conditional export: web uses dart:html canvas, mobile uses video_thumbnail package.
// Both export the same `getVideoThumbnail(String url) → Future<Uint8List?>` function.
export 'video_thumb_helper_io.dart'
    if (dart.library.html) 'video_thumb_helper_web.dart';