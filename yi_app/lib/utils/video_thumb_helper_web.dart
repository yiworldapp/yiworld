import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

/// Web implementation — uses an HTML <video> element + Canvas to capture
/// the first frame of a video, matching the mobile experience.
Future<Uint8List?> getVideoThumbnail(String url) async {
  final completer = Completer<Uint8List?>();

  final video = html.VideoElement()
    ..src = url
    ..crossOrigin = 'anonymous'
    ..muted = true
    ..preload = 'auto';

  Timer? timeout;

  void finish(Uint8List? result) {
    if (completer.isCompleted) return;
    timeout?.cancel();
    completer.complete(result);
    try {
      video.src = '';
      video.remove();
    } catch (_) {}
  }

  timeout = Timer(const Duration(seconds: 8), () => finish(null));

  video.onError.listen((_) => finish(null));

  video.onLoadedData.listen((_) async {
    try {
      video.currentTime = 0;
      // Give the browser a moment to seek to frame 0
      await Future.delayed(const Duration(milliseconds: 200));

      final w = video.videoWidth > 0 ? video.videoWidth : 320;
      final h = video.videoHeight > 0 ? video.videoHeight : 180;

      final canvas = html.CanvasElement(width: w, height: h);
      canvas.context2D.drawImage(video, 0, 0);

      final dataUrl = canvas.toDataUrl('image/jpeg', 0.7);
      final base64Str = dataUrl.split(',').last;
      finish(base64Decode(base64Str));
    } catch (_) {
      finish(null);
    }
  });

  return completer.future;
}