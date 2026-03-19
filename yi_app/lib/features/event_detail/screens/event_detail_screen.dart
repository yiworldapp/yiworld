import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:chewie/chewie.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';
import '../../../core/services/verticals_cache.dart';
import '../../../utils/video_thumb_helper.dart';
import '../../../core/theme/app_colors.dart';

class EventDetailScreen extends StatefulWidget {
  final String eventId;

  const EventDetailScreen({super.key, required this.eventId});

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  final _supabase = Supabase.instance.client;
  Map<String, dynamic>? _event;
  List<Map<String, dynamic>> _gallery = [];
  List<Map<String, dynamic>> _attendees = [];
  List<Map<String, dynamic>> _organizers = [];
  bool _loading = true;
  bool _userRsvped = false;

  @override
  void initState() {
    super.initState();
    _loadEvent();
  }

  Future<void> _loadEvent() async {
    final userId = _supabase.auth.currentUser?.id;
    final futures = await Future.wait<dynamic>([
      _supabase.from('events')
        .select('*, verticals(label, slug, color_hex)')
        .eq('id', widget.eventId)
        .single(),
      _supabase.from('event_gallery')
        .select('*')
        .eq('event_id', widget.eventId)
        .order('sort_order'),
      _supabase.from('event_rsvps')
        .select('*, profiles(id, first_name, last_name, headshot_url, job_title, company_name, yi_vertical)')
        .eq('event_id', widget.eventId)
        .eq('status', 'going'),
      _supabase.from('event_organizers')
        .select('*, profiles(id, first_name, last_name, headshot_url, yi_position, yi_vertical)')
        .eq('event_id', widget.eventId),
    ]);

    final rsvps = List<Map<String, dynamic>>.from(futures[2] as List);
    final myRsvp = userId != null
      ? rsvps.where((r) => r['profile_id'] == userId).isNotEmpty
      : false;

    if (mounted) {
      setState(() {
        _event = futures[0] as Map<String, dynamic>;
        _gallery = List<Map<String, dynamic>>.from(futures[1] as List);
        _attendees = rsvps;
        _organizers = List<Map<String, dynamic>>.from(futures[3] as List);
        _userRsvped = myRsvp;
        _loading = false;
      });
    }
  }

  Future<void> _toggleRsvp() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    if (_userRsvped) {
      await _supabase.from('event_rsvps')
        .delete().eq('event_id', widget.eventId).eq('profile_id', userId);
    } else {
      await _supabase.from('event_rsvps').upsert({
        'event_id': widget.eventId,
        'profile_id': userId,
        'status': 'going',
      });
    }
    _loadEvent();
  }

  void _showAttendees() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Row(
              children: [
                Text(
                  'Attendees (${_attendees.length})',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(color: AppColors.divider, height: 1),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _attendees.length,
              itemBuilder: (ctx, i) {
                final profile = _attendees[i]['profiles'] as Map<String, dynamic>?;
                final fullName = [profile?['first_name'], profile?['last_name']]
                    .whereType<String>().join(' ').trim();
                final jobTitle = profile?['job_title'] as String?;
                final company = profile?['company_name'] as String?;
                final jobLine = [
                  if (jobTitle?.isNotEmpty == true) jobTitle!,
                  if (company?.isNotEmpty == true) company!,
                ].join(' @ ');
                final verticalColor = VerticalsCache.colorForSlug(profile?['yi_vertical'] as String?);
                final initial = ((profile?['first_name'] as String? ?? '?')[0]).toUpperCase();

                return GestureDetector(
                  onTap: profile?['id'] != null
                      ? () {
                          Navigator.pop(ctx);
                          context.pushNamed('member-detail', pathParameters: {'id': profile!['id'] as String});
                        }
                      : null,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 22,
                          backgroundColor: AppColors.surfaceAlt,
                          backgroundImage: profile?['headshot_url'] != null
                            ? CachedNetworkImageProvider(profile!['headshot_url'] as String)
                            : null,
                          child: profile?['headshot_url'] == null
                            ? Text(initial, style: TextStyle(color: verticalColor, fontWeight: FontWeight.bold, fontSize: 15))
                            : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                fullName.isEmpty ? 'Member' : fullName,
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: AppColors.white),
                              ),
                              if (jobLine.isNotEmpty)
                                Text(
                                  jobLine,
                                  style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                                  overflow: TextOverflow.ellipsis,
                                ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right, size: 16, color: AppColors.textMuted),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openLocation() async {
    final event = _event!;
    final locationUrl = event['location_url'] as String?;
    final lat = event['location_lat'] as double?;
    final lng = event['location_lng'] as double?;

    String? url;
    if (locationUrl != null && locationUrl.isNotEmpty) {
      url = locationUrl;
    } else if (lat != null && lng != null) {
      url = 'https://www.google.com/maps/search/?api=1&query=$lat,$lng';
    }

    if (url != null) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }
  }

  void _openGallery(int initialIndex) {
    final pageCtrl = PageController(initialPage: initialIndex);
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black.withOpacity(0.95),
        pageBuilder: (_, __, ___) => _GalleryViewer(items: _gallery, pageCtrl: pageCtrl, initialIndex: initialIndex),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: AppColors.black,
        body: Center(child: CircularProgressIndicator(color: AppColors.green)),
      );
    }

    final event = _event!;
    final vertical = event['verticals'] as Map<String, dynamic>?;
    final verticalColor = VerticalsCache.colorForSlug(vertical?['slug'] as String?);
    final startsAt = DateTime.parse(event['starts_at'] as String).toLocal();
    final isRemote = event['is_remote'] == true;
    final coverUrl = event['cover_image_url'] as String?;

    final topPad = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: AppColors.black,
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Cover image (or placeholder) ──────────────────────────
                if (coverUrl == null)
                  Container(
                    height: 260,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          verticalColor.withOpacity(0.3),
                          verticalColor.withOpacity(0.08),
                          AppColors.black,
                        ],
                        stops: const [0.0, 0.6, 1.0],
                      ),
                    ),
                    child: Center(
                      child: Icon(Icons.event_outlined, size: 72, color: verticalColor.withOpacity(0.25)),
                    ),
                  )
                else
                  Stack(
                    children: [
                      CachedNetworkImage(
                        imageUrl: coverUrl,
                        width: double.infinity,
                        height: 300,
                        fit: BoxFit.cover,
                      ),
                      Positioned(
                        bottom: 0, left: 0, right: 0,
                        child: Container(
                          height: 80,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Colors.transparent, AppColors.black.withOpacity(0.7)],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                // ── Content ────────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Vertical badge
                  if (vertical != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: verticalColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: verticalColor.withOpacity(0.3)),
                      ),
                      child: Text(
                        (vertical['label'] as String).toUpperCase(),
                        style: TextStyle(color: verticalColor, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ),
                  const SizedBox(height: 12),

                  // Title
                  Text(
                    event['title'] as String,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.white),
                  ),
                  const SizedBox(height: 20),

                  // Date
                  _infoRow(
                    Icons.calendar_today_outlined,
                    () {
                      final endsAtStr = event['ends_at'] as String?;
                      if (endsAtStr != null) {
                        final endsAt = DateTime.parse(endsAtStr).toLocal();
                        final sameDay = startsAt.year == endsAt.year &&
                            startsAt.month == endsAt.month &&
                            startsAt.day == endsAt.day;
                        if (!sameDay) {
                          return '${DateFormat('dd/MM').format(startsAt)} – ${DateFormat('dd/MM/yyyy').format(endsAt)}';
                        }
                      }
                      return DateFormat('EEEE, dd/MM/yyyy').format(startsAt);
                    }(),
                    subtitle: () {
                      final endsAtStr = event['ends_at'] as String?;
                      if (endsAtStr != null) {
                        final endsAt = DateTime.parse(endsAtStr).toLocal();
                        final sameDay = startsAt.year == endsAt.year &&
                            startsAt.month == endsAt.month &&
                            startsAt.day == endsAt.day;
                        if (sameDay) {
                          return '${DateFormat('h:mm a').format(startsAt)} – ${DateFormat('h:mm a').format(endsAt)}';
                        } else {
                          return '${DateFormat('EEE, h:mm a').format(startsAt)} – ${DateFormat('EEE, h:mm a').format(endsAt)}';
                        }
                      }
                      return DateFormat('h:mm a').format(startsAt);
                    }(),
                  ),
                  const SizedBox(height: 12),

                  // Location
                  GestureDetector(
                    onTap: isRemote ? () async {
                      final url = event['location_url'] as String?;
                      if (url != null) await launchUrl(Uri.parse(url));
                    } : _openLocation,
                    child: _infoRow(
                      isRemote ? Icons.videocam_outlined : Icons.location_on_outlined,
                      isRemote ? 'Remote Event' : (event['location_name'] as String? ?? 'Location TBD'),
                      subtitle: isRemote ? 'Tap to join' : 'Tap for directions',
                      trailingColor: isRemote ? AppColors.orange : AppColors.green,
                    ),
                  ),

                  // Attendees row
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      // Avatar stack
                      SizedBox(
                        width: _attendees.length > 3 ? 80 : (_attendees.length * 22.0 + 20),
                        height: 36,
                        child: Stack(
                          children: [
                            ..._attendees.take(4).toList().asMap().entries.map((e) {
                              final profile = e.value['profiles'] as Map<String, dynamic>?;
                              return Positioned(
                                left: e.key * 22.0,
                                child: Container(
                                  width: 34, height: 34,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(color: AppColors.black, width: 2),
                                  ),
                                  child: CircleAvatar(
                                    backgroundColor: AppColors.surfaceAlt,
                                    backgroundImage: profile?['headshot_url'] != null
                                      ? CachedNetworkImageProvider(profile!['headshot_url'] as String)
                                      : null,
                                    child: profile?['headshot_url'] == null
                                      ? Text(
                                          (profile?['first_name'] as String? ?? '?')[0],
                                          style: const TextStyle(fontSize: 11, color: AppColors.green),
                                        )
                                      : null,
                                  ),
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: _attendees.isNotEmpty ? _showAttendees : null,
                        child: Text(
                          '${_attendees.length} attending',
                          style: const TextStyle(color: AppColors.textMuted, fontSize: 14),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),
                  const Divider(color: AppColors.divider),
                  const SizedBox(height: 16),

                  // Description
                  if (event['description'] != null) ...[
                    const Text('About', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.white)),
                    const SizedBox(height: 10),
                    Text(
                      event['description'] as String,
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 15, height: 1.6),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Gallery
                  if (_gallery.isNotEmpty) ...[
                    const Text('Gallery', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.white)),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 110,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _gallery.length,
                        itemBuilder: (ctx, i) {
                          final item = _gallery[i];
                          final isVideo = (item['media_type'] as String?) == 'video';
                          return GestureDetector(
                            onTap: () => _openGallery(i),
                            child: Container(
                              width: 110,
                              margin: EdgeInsets.only(right: i < _gallery.length - 1 ? 10 : 0),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                color: AppColors.surfaceAlt,
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    if (!isVideo)
                                      CachedNetworkImage(
                                        imageUrl: item['media_url'] as String,
                                        fit: BoxFit.cover,
                                      )
                                    else
                                      _VideoThumbnail(url: item['media_url'] as String),
                                    if (isVideo)
                                      Center(
                                        child: Container(
                                          width: 36, height: 36,
                                          decoration: BoxDecoration(
                                            color: Colors.black.withOpacity(0.55),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(Icons.play_arrow, color: Colors.white, size: 22),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Organizers
                  if (_organizers.isNotEmpty) ...[
                    const Text('Organizers', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.white)),
                    const SizedBox(height: 12),
                    ..._organizers.map((o) {
                      final profile = o['profiles'] as Map<String, dynamic>?;
                      final profileId = profile?['id'] as String?;
                      return GestureDetector(
                        onTap: profileId != null ? () => context.push('/members/$profileId') : null,
                        child: Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.card,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 22,
                              backgroundColor: AppColors.surfaceAlt,
                              backgroundImage: profile?['headshot_url'] != null
                                ? CachedNetworkImageProvider(profile!['headshot_url'] as String)
                                : null,
                              child: profile?['headshot_url'] == null
                                ? Text((profile?['first_name'] as String? ?? '?')[0].toUpperCase(),
                                    style: const TextStyle(color: AppColors.green, fontWeight: FontWeight.bold))
                                : null,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    [profile?['first_name'], profile?['last_name']].whereType<String>().join(' ').trim().isEmpty ? 'Organizer' : [profile?['first_name'], profile?['last_name']].whereType<String>().join(' ').trim(),
                                    style: const TextStyle(fontWeight: FontWeight.w600),
                                  ),
                                  if (profile?['yi_vertical'] != null || profile?['yi_position'] != null) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      [
                                        if (profile?['yi_vertical'] != null && profile?['yi_vertical'] != 'none')
                                          (profile!['yi_vertical'] as String).replaceAll('_', ' '),
                                        if (profile?['yi_position'] != null && profile?['yi_position'] != 'none')
                                          (profile!['yi_position'] as String).replaceAll('_', ' '),
                                      ].join(' - '),
                                      style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            if (profileId != null)
                              const Icon(Icons.chevron_right, color: AppColors.textMuted, size: 18),
                          ],
                        ),
                      ));
                    }),
                    const SizedBox(height: 12),
                  ],

                  const SizedBox(height: 100), // bottom padding for buttons
                ],
              ),
            ),
              ],
            ),
          ),
          // ── Back button overlaid ─────────────────────────────────────────
          Positioned(
            top: topPad + 8, left: 8,
            child: GestureDetector(
              onTap: () => context.pop(),
              child: Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: AppColors.black.withOpacity(0.6),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_back, size: 20, color: AppColors.white),
              ),
            ),
          ),
        ],
      ),

      // Bottom action buttons
      bottomNavigationBar: Container(
        padding: EdgeInsets.fromLTRB(20, 12, 20, MediaQuery.of(context).padding.bottom + 12),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.divider)),
        ),
        child: Row(
          children: [
            if (!isRemote)
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _openLocation,
                  icon: const Icon(Icons.map_outlined, size: 18),
                  label: const Text('Directions'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.orange,
                    side: const BorderSide(color: AppColors.orange),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            if (!isRemote) const SizedBox(width: 12),
            if (isRemote)
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final url = event['location_url'] as String?;
                    if (url != null) await launchUrl(Uri.parse(url));
                  },
                  icon: const Icon(Icons.videocam_outlined, size: 18),
                  label: const Text('Join Meeting'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.orange,
                    side: const BorderSide(color: AppColors.orange),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            if (isRemote) const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: _toggleRsvp,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _userRsvped ? AppColors.surfaceAlt : AppColors.green,
                  foregroundColor: _userRsvped ? AppColors.textMuted : AppColors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(_userRsvped ? 'Cancel RSVP' : 'RSVP'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String title, {String? subtitle, Color? trailingColor}) {
    return Row(
      children: [
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            color: AppColors.surfaceAlt,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: AppColors.textMuted),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w500, color: AppColors.white)),
              if (subtitle != null)
                Text(subtitle, style: TextStyle(color: trailingColor ?? AppColors.textMuted, fontSize: 12)),
            ],
          ),
        ),
        if (trailingColor != null)
          Icon(Icons.chevron_right, color: trailingColor, size: 18),
      ],
    );
  }
}

class _GalleryViewer extends StatefulWidget {
  final List<Map<String, dynamic>> items;
  final PageController pageCtrl;
  final int initialIndex;

  const _GalleryViewer({required this.items, required this.pageCtrl, required this.initialIndex});

  @override
  State<_GalleryViewer> createState() => _GalleryViewerState();
}

class _GalleryViewerState extends State<_GalleryViewer> {
  late int _current;

  @override
  void initState() {
    super.initState();
    _current = widget.initialIndex;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PageView.builder(
            controller: widget.pageCtrl,
            itemCount: widget.items.length,
            onPageChanged: (i) => setState(() => _current = i),
            itemBuilder: (ctx, i) {
              final item = widget.items[i];
              final isVideo = (item['media_type'] as String?) == 'video';
              final url = item['media_url'] as String;

              if (isVideo) {
                return _VideoPlayerItem(url: url);
              }

              return InteractiveViewer(
                child: CachedNetworkImage(
                  imageUrl: url,
                  fit: BoxFit.contain,
                  width: double.infinity,
                  height: double.infinity,
                ),
              );
            },
          ),
          // Close button
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            right: 12,
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 20),
              ),
            ),
          ),
          // Counter
          Positioned(
            top: MediaQuery.of(context).padding.top + 14,
            left: 0, right: 0,
            child: Center(
              child: Text(
                '${_current + 1} / ${widget.items.length}',
                style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VideoThumbnail extends StatefulWidget {
  final String url;
  const _VideoThumbnail({required this.url});

  @override
  State<_VideoThumbnail> createState() => _VideoThumbnailState();
}

class _VideoThumbnailState extends State<_VideoThumbnail> {
  Uint8List? _thumb;

  @override
  void initState() {
    super.initState();
    _generate();
  }

  Future<void> _generate() async {
    final bytes = await getVideoThumbnail(widget.url);
    if (mounted && bytes != null) setState(() => _thumb = bytes);
  }

  @override
  Widget build(BuildContext context) {
    if (_thumb == null) {
      return Container(
        color: AppColors.surface,
        child: const Center(child: Icon(Icons.videocam_outlined, size: 28, color: AppColors.textMuted)),
      );
    }
    return Image.memory(_thumb!, fit: BoxFit.cover, width: double.infinity, height: double.infinity);
  }
}

class _VideoPlayerItem extends StatefulWidget {
  final String url;
  const _VideoPlayerItem({required this.url});

  @override
  State<_VideoPlayerItem> createState() => _VideoPlayerItemState();
}

class _VideoPlayerItemState extends State<_VideoPlayerItem> {
  late VideoPlayerController _vpCtrl;
  ChewieController? _chewieCtrl;
  bool _initialized = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _vpCtrl = VideoPlayerController.networkUrl(Uri.parse(widget.url));
    _vpCtrl.initialize().then((_) {
      if (mounted) {
        _chewieCtrl = ChewieController(
          videoPlayerController: _vpCtrl,
          autoPlay: true,
          looping: false,
          allowFullScreen: true,
          materialProgressColors: ChewieProgressColors(
            playedColor: const Color(0xFF4CAF50),
            handleColor: const Color(0xFF4CAF50),
            bufferedColor: Colors.white24,
            backgroundColor: Colors.white12,
          ),
        );
        setState(() => _initialized = true);
      }
    }).catchError((e) {
      if (mounted) setState(() => _error = 'Could not load video');
    });
  }

  @override
  void dispose() {
    _chewieCtrl?.dispose();
    _vpCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.white54, size: 48),
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: Colors.white54, fontSize: 14)),
          ],
        ),
      );
    }
    if (!_initialized) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF4CAF50)));
    }
    return Center(child: AspectRatio(
      aspectRatio: _vpCtrl.value.aspectRatio,
      child: Chewie(controller: _chewieCtrl!),
    ));
  }
}
