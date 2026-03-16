import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/services/verticals_cache.dart';
import '../../../core/theme/app_colors.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _events = [];
  bool _loading = true;

  // Filter state
  String _timeFilter = 'upcoming'; // 'all' | 'upcoming' | 'past'
  String _formatFilter = 'all'; // 'all' | 'in-person' | 'remote'
  String? _selectedVertical; // null = all, or slug value
  String _search = '';
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  int get _activeFilterCount {
    int count = 0;
    if (_timeFilter != 'upcoming') count++;
    if (_formatFilter != 'all') count++;
    if (_selectedVertical != null) count++;
    return count;
  }

  Future<void> _loadEvents() async {
    setState(() => _loading = true);

    var query = _supabase
        .from('events')
        .select('*, verticals(label, slug, color_hex)')
        .eq('is_published', true);

    final now = DateTime.now();
    if (_timeFilter == 'upcoming') {
      query = query.gte('starts_at', now.toIso8601String());
    } else if (_timeFilter == 'past') {
      query = query.lt('starts_at', now.toIso8601String());
    } else if (_timeFilter == 'this_month') {
      final firstOfMonth = DateTime(now.year, now.month, 1);
      final firstOfNext = DateTime(now.year, now.month + 1, 1);
      query = query
          .gte('starts_at', firstOfMonth.toIso8601String())
          .lt('starts_at', firstOfNext.toIso8601String());
    } else if (_timeFilter == 'next_month') {
      final firstOfNext = DateTime(now.year, now.month + 1, 1);
      final firstOfNextNext = DateTime(now.year, now.month + 2, 1);
      query = query
          .gte('starts_at', firstOfNext.toIso8601String())
          .lt('starts_at', firstOfNextNext.toIso8601String());
    } else if (_timeFilter == 'this_week') {
      final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
      final startOfDay = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
      final endOfWeek = startOfDay.add(const Duration(days: 7));
      query = query
          .gte('starts_at', startOfDay.toIso8601String())
          .lt('starts_at', endOfWeek.toIso8601String());
    } else if (_timeFilter == 'next_week') {
      final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
      final startOfDay = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
      final nextWeekStart = startOfDay.add(const Duration(days: 7));
      final nextWeekEnd = startOfDay.add(const Duration(days: 14));
      query = query
          .gte('starts_at', nextWeekStart.toIso8601String())
          .lt('starts_at', nextWeekEnd.toIso8601String());
    }

    if (_formatFilter == 'remote') {
      query = query.eq('is_remote', true);
    } else if (_formatFilter == 'in-person') {
      query = query.eq('is_remote', false);
    }

    if (_selectedVertical != null) {
      final verticalId = await _getVerticalId(_selectedVertical!);
      if (verticalId != null) {
        query = query.eq('vertical_id', verticalId);
      }
    }

    if (_search.isNotEmpty) {
      query = query.ilike('title', '%$_search%');
    }

    final ascending = _timeFilter != 'past';
    final data = await query.order('starts_at', ascending: ascending);

    if (mounted) {
      setState(() {
        _events = List<Map<String, dynamic>>.from(data);
        _loading = false;
      });
    }
  }

  Future<String?> _getVerticalId(String slug) async {
    try {
      final data = await _supabase
          .from('verticals').select('id').eq('slug', slug).single();
      return data['id'];
    } catch (_) {
      return null;
    }
  }

  void _clearFilters() {
    setState(() {
      _timeFilter = 'upcoming';
      _formatFilter = 'all';
      _selectedVertical = null;
    });
    _loadEvents();
  }

  void _openFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _FilterSheet(
        timeFilter: _timeFilter,
        formatFilter: _formatFilter,
        selectedVertical: _selectedVertical,
        onApply: (time, format, vertical) {
          setState(() {
            _timeFilter = time;
            _formatFilter = format;
            _selectedVertical = vertical;
          });
          _loadEvents();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: AppColors.black,
      body: CustomScrollView(
        slivers: [
          // ── App Bar ──────────────────────────────────────────────────────
          SliverAppBar(
            pinned: true,
            backgroundColor: AppColors.black,
            elevation: 0,
            scrolledUnderElevation: 0,
            toolbarHeight: 56,
            automaticallyImplyLeading: false,
            title: Row(
              children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.all(4),
                  child: Image.asset(
                    'assets/images/yi_logo.png',
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const Center(
                      child: Text('YI', style: TextStyle(color: AppColors.black, fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Young Indians',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.orange, height: 1.2),
                    ),
                    Text(
                      'YI Kanpur Chapter',
                      style: TextStyle(fontSize: 10, color: AppColors.accentGreen, height: 1.2),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.menu_outlined, color: AppColors.white),
                onPressed: () => context.push('/menu'),
              ),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(57),
              child: Column(
                children: [
                  Container(height: 1, color: AppColors.divider),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _searchCtrl,
                            decoration: InputDecoration(
                              hintText: 'Search events...',
                              prefixIcon: const Icon(Icons.search, color: AppColors.textMuted, size: 20),
                              suffixIcon: _search.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear, size: 16),
                                    onPressed: () {
                                      _searchCtrl.clear();
                                      setState(() => _search = '');
                                      _loadEvents();
                                    },
                                  )
                                : null,
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                            ),
                            onChanged: (v) {
                              setState(() => _search = v);
                              Future.delayed(const Duration(milliseconds: 500), _loadEvents);
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: _openFilterSheet,
                          child: Container(
                            width: 44, height: 44,
                            decoration: BoxDecoration(
                              color: _activeFilterCount > 0 ? AppColors.green.withOpacity(0.15) : AppColors.surfaceAlt,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: _activeFilterCount > 0 ? AppColors.green.withOpacity(0.5) : AppColors.border,
                                width: _activeFilterCount > 0 ? 1.5 : 1,
                              ),
                            ),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Icon(
                                  Icons.tune_rounded,
                                  color: _activeFilterCount > 0 ? AppColors.green : AppColors.textMuted,
                                  size: 20,
                                ),
                                if (_activeFilterCount > 0)
                                  Positioned(
                                    top: 6, right: 6,
                                    child: Container(
                                      width: 14, height: 14,
                                      decoration: const BoxDecoration(
                                        color: AppColors.green,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Center(
                                        child: Text(
                                          '$_activeFilterCount',
                                          style: const TextStyle(color: AppColors.white, fontSize: 9, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Active filter chips ───────────────────────────────────────────
          if (_activeFilterCount > 0)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                child: Wrap(
                  spacing: 6, runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    if (_timeFilter != 'upcoming')
                      _ActiveChip(
                        label: _timeFilter == 'all' ? 'All time'
                            : _timeFilter == 'past' ? 'Past events'
                            : _timeFilter == 'this_month' ? 'This Month'
                            : _timeFilter == 'next_month' ? 'Next Month'
                            : _timeFilter == 'this_week' ? 'This Week'
                            : 'Next Week',
                        onRemove: () { setState(() => _timeFilter = 'upcoming'); _loadEvents(); },
                      ),
                    if (_formatFilter != 'all')
                      _ActiveChip(
                        label: _formatFilter == 'remote' ? 'Remote' : 'In-Person',
                        onRemove: () { setState(() => _formatFilter = 'all'); _loadEvents(); },
                      ),
                    if (_selectedVertical != null)
                      _ActiveChip(
                        label: AppConstants.yiVerticals
                            .firstWhere((v) => v['value'] == _selectedVertical, orElse: () => {'label': _selectedVertical!})['label']!,
                        onRemove: () { setState(() => _selectedVertical = null); _loadEvents(); },
                      ),
                    GestureDetector(
                      onTap: _clearFilters,
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 5),
                        child: Text('Clear all', style: TextStyle(color: AppColors.green, fontSize: 12, fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // ── Event count ───────────────────────────────────────────────────
          if (!_loading)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Text(
                  _events.isEmpty ? 'No events found' : '${_events.length} event${_events.length == 1 ? '' : 's'}',
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                ),
              ),
            ),

          // ── Content ───────────────────────────────────────────────────────
          if (_loading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator(color: AppColors.green)),
            )
          else if (_events.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.event_busy_outlined, size: 56, color: AppColors.textMuted),
                    const SizedBox(height: 16),
                    Text(
                      _activeFilterCount > 0 ? 'No events match your filters' : 'No events found',
                      style: const TextStyle(color: AppColors.textMuted),
                    ),
                    if (_activeFilterCount > 0) ...[
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: _clearFilters,
                        child: const Text('Clear filters'),
                      ),
                    ],
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (ctx, i) => EventCard(event: _events[i]),
                  childCount: _events.length,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Active chip ───────────────────────────────────────────────────────────────
class _ActiveChip extends StatelessWidget {
  final String label;
  final VoidCallback onRemove;

  const _ActiveChip({required this.label, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.green.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.green.withOpacity(0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: const TextStyle(color: AppColors.green, fontSize: 12, fontWeight: FontWeight.w500)),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onRemove,
            child: const Icon(Icons.close_rounded, size: 14, color: AppColors.green),
          ),
        ],
      ),
    );
  }
}

// ── Filter bottom sheet ───────────────────────────────────────────────────────
class _FilterSheet extends StatefulWidget {
  final String timeFilter;
  final String formatFilter;
  final String? selectedVertical;
  final void Function(String time, String format, String? vertical) onApply;

  const _FilterSheet({
    required this.timeFilter,
    required this.formatFilter,
    required this.selectedVertical,
    required this.onApply,
  });

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late String _time;
  late String _format;
  late String? _vertical;

  @override
  void initState() {
    super.initState();
    _time = widget.timeFilter;
    _format = widget.formatFilter;
    _vertical = widget.selectedVertical;
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.92,
      expand: false,
      builder: (_, scrollCtrl) => Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.symmetric(vertical: 10),
            width: 36, height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 16, 12),
            child: Row(
              children: [
                const Text('Filter Events', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.white)),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    setState(() { _time = 'upcoming'; _format = 'all'; _vertical = null; });
                  },
                  child: const Text('Reset', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
                ),
              ],
            ),
          ),
          Container(height: 1, color: AppColors.divider),
          // Scrollable content
          Expanded(
            child: ListView(
              controller: scrollCtrl,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                const SizedBox(height: 20),

                // TIME section
                const Text('TIME', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textMuted, letterSpacing: 0.8)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8, runSpacing: 8,
                  children: [
                    _SheetChip(label: 'Upcoming', value: 'upcoming', groupValue: _time, onTap: (v) => setState(() => _time = v)),
                    _SheetChip(label: 'This Week', value: 'this_week', groupValue: _time, onTap: (v) => setState(() => _time = v)),
                    _SheetChip(label: 'Next Week', value: 'next_week', groupValue: _time, onTap: (v) => setState(() => _time = v)),
                    _SheetChip(label: 'This Month', value: 'this_month', groupValue: _time, onTap: (v) => setState(() => _time = v)),
                    _SheetChip(label: 'Next Month', value: 'next_month', groupValue: _time, onTap: (v) => setState(() => _time = v)),
                    _SheetChip(label: 'Past', value: 'past', groupValue: _time, onTap: (v) => setState(() => _time = v)),
                    _SheetChip(label: 'All', value: 'all', groupValue: _time, onTap: (v) => setState(() => _time = v)),
                  ],
                ),

                const SizedBox(height: 24),

                // FORMAT section
                const Text('FORMAT', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textMuted, letterSpacing: 0.8)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8, runSpacing: 8,
                  children: [
                    _SheetChip(label: 'All', value: 'all', groupValue: _format, onTap: (v) => setState(() => _format = v)),
                    _SheetChip(label: 'In-Person', value: 'in-person', groupValue: _format, onTap: (v) => setState(() => _format = v)),
                    _SheetChip(label: 'Remote', value: 'remote', groupValue: _format, onTap: (v) => setState(() => _format = v)),
                  ],
                ),

                const SizedBox(height: 24),

                // VERTICAL section
                const Text('VERTICAL', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textMuted, letterSpacing: 0.8)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8, runSpacing: 8,
                  children: [
                    _SheetChip(
                      label: 'All',
                      value: '__all__',
                      groupValue: _vertical ?? '__all__',
                      onTap: (_) => setState(() => _vertical = null),
                    ),
                    ...AppConstants.yiVerticals
                        .where((v) => v['value'] != 'none')
                        .map((v) => _SheetChip(
                              label: v['label']!,
                              value: v['value']!,
                              groupValue: _vertical ?? '__all__',
                              onTap: (val) => setState(() => _vertical = val),
                            )),
                  ],
                ),

                SizedBox(height: bottomPad + 16),
              ],
            ),
          ),
          // Apply button
          Container(
            padding: EdgeInsets.fromLTRB(20, 12, 20, bottomPad + 12),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(top: BorderSide(color: AppColors.divider)),
            ),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  widget.onApply(_time, _format, _vertical);
                },
                child: const Text('Apply Filters'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SheetChip extends StatelessWidget {
  final String label;
  final String value;
  final String groupValue;
  final void Function(String) onTap;

  const _SheetChip({required this.label, required this.value, required this.groupValue, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final selected = value == groupValue;
    return GestureDetector(
      onTap: () => onTap(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.green.withOpacity(0.15) : AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.green.withOpacity(0.6) : AppColors.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? AppColors.green : AppColors.textMuted,
            fontSize: 13,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

// ── Event Card ────────────────────────────────────────────────────────────────
class EventCard extends StatelessWidget {
  final Map<String, dynamic> event;

  const EventCard({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    final vertical = event['verticals'] as Map<String, dynamic>?;
    final startsAt = DateTime.parse(event['starts_at'] as String).toLocal();
    final isPast = startsAt.isBefore(DateTime.now());
    final verticalColor = VerticalsCache.colorForSlug(vertical?['slug'] as String?);
    final hasCover = event['cover_image_url'] != null;

    return GestureDetector(
      onTap: () => context.pushNamed('event-detail', pathParameters: {'id': event['id']}),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover image or colored strip
            if (hasCover)
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                    child: CachedNetworkImage(
                      imageUrl: event['cover_image_url'] as String,
                      height: 160,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      placeholder: (ctx, url) => Container(
                        height: 160,
                        color: AppColors.surfaceAlt,
                        child: const Center(child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.green)),
                      ),
                    ),
                  ),
                  if (isPast)
                    Positioned(
                      top: 10, left: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.65),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text('Past', style: TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.w600)),
                      ),
                    ),
                ],
              )
            else
              Container(
                height: 130,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      verticalColor.withOpacity(0.25),
                      verticalColor.withOpacity(0.08),
                    ],
                  ),
                ),
                child: Stack(
                  children: [
                    Center(
                      child: Icon(Icons.event_outlined, size: 48, color: verticalColor.withOpacity(0.3)),
                    ),
                    if (isPast)
                      Positioned(
                        top: 10, left: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceAlt.withOpacity(0.85),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text('Past', style: TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.w600)),
                        ),
                      ),
                  ],
                ),
              ),

            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (vertical != null) ...[
                        _Tag(label: vertical['label'] as String, color: verticalColor),
                        const SizedBox(width: 6),
                      ],
                      if (event['is_remote'] == true)
                        _Tag(label: 'Remote', color: AppColors.orange),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    event['title'] as String,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: isPast ? AppColors.textMuted : AppColors.white,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined, size: 13, color: AppColors.textMuted),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          () {
                            final endsAtStr = event['ends_at'] as String?;
                            if (endsAtStr != null) {
                              final endsAt = DateTime.parse(endsAtStr).toLocal();
                              final sameDay = startsAt.year == endsAt.year &&
                                  startsAt.month == endsAt.month &&
                                  startsAt.day == endsAt.day;
                              if (sameDay) {
                                return '${DateFormat('EEE, MMM d · h:mm a').format(startsAt)} – ${DateFormat('h:mm a').format(endsAt)}';
                              } else {
                                return '${DateFormat('MMM d').format(startsAt)} – ${DateFormat('MMM d · h:mm a').format(endsAt)}';
                              }
                            }
                            return DateFormat('EEE, MMM d · h:mm a').format(startsAt);
                          }(),
                          style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  if (event['location_name'] != null || event['is_remote'] == true) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          event['is_remote'] == true ? Icons.videocam_outlined : Icons.location_on_outlined,
                          size: 13,
                          color: AppColors.textMuted,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            event['is_remote'] == true ? 'Online / Remote' : event['location_name'] as String,
                            style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String label;
  final Color color;

  const _Tag({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }
}
