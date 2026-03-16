import 'dart:typed_data';
import 'package:video_thumbnail/video_thumbnail.dart';

/// Native (Android/iOS) implementation — uses the video_thumbnail package.
Future<Uint8List?> getVideoThumbnail(String url) async {
  return VideoThumbnail.thumbnailData(
    video: url,
    imageFormat: ImageFormat.JPEG,
    maxWidth: 220,
    quality: 70,
  );
}