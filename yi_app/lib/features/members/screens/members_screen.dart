import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/verticals_cache.dart';
import '../../../core/theme/app_colors.dart';

class MembersScreen extends StatefulWidget {
  const MembersScreen({super.key});

  @override
  State<MembersScreen> createState() => _MembersScreenState();
}

class _MembersScreenState extends State<MembersScreen> {
  static const _pageSize = 20;
  final _pagingController =
      PagingController<int, Map<String, dynamic>>(firstPageKey: 0);
  final _supabase = Supabase.instance.client;
  String? _selectedIndustry;
  String? _selectedBusinessTag;
  String? _selectedHobbyTag;
  String _search = '';
  int _totalCount = 0;
  final _searchCtrl = TextEditingController();

  int get _activeFilterCount => [
    _selectedIndustry, _selectedBusinessTag, _selectedHobbyTag,
  ].where((f) => f != null).length;

  @override
  void initState() {
    super.initState();
    _pagingController.addPageRequestListener(_fetchPage);
  }

  @override
  void dispose() {
    _pagingController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchPage(int pageKey) async {
    try {
      var query = _supabase
          .from('profiles')
          .select('id, first_name, last_name, headshot_url, job_title, company_name, yi_vertical, yi_position, member_type, city, industry, phone, personal_bio, business_bio')
          .eq('onboarding_done', true)
          .neq('member_type', 'super_admin')
          .eq('is_test_user', false);

      if (_selectedIndustry != null) {
        query = query.eq('industry', _selectedIndustry!);
      }
      if (_selectedBusinessTag != null) {
        query = query.contains('business_tags', [_selectedBusinessTag!]);
      }
      if (_selectedHobbyTag != null) {
        query = query.contains('hobby_tags', [_selectedHobbyTag!]);
      }
      if (_search.isNotEmpty) {
        query = query.or(
          'first_name.ilike.%$_search%,last_name.ilike.%$_search%,personal_bio.ilike.%$_search%,business_bio.ilike.%$_search%,job_title.ilike.%$_search%,company_name.ilike.%$_search%,industry.ilike.%$_search%',
        );
      }

      // On first page, fetch total count via a lightweight ID-only query
      if (pageKey == 0) {
        var countQuery = _supabase
            .from('profiles')
            .select('id')
            .eq('onboarding_done', true)
            .neq('member_type', 'super_admin')
            .eq('is_test_user', false);
        if (_selectedIndustry != null) countQuery = countQuery.eq('industry', _selectedIndustry!);
        if (_selectedBusinessTag != null) countQuery = countQuery.contains('business_tags', [_selectedBusinessTag!]);
        if (_selectedHobbyTag != null) countQuery = countQuery.contains('hobby_tags', [_selectedHobbyTag!]);
        if (_search.isNotEmpty) {
          countQuery = countQuery.or(
            'first_name.ilike.%$_search%,last_name.ilike.%$_search%,personal_bio.ilike.%$_search%,business_bio.ilike.%$_search%,job_title.ilike.%$_search%,company_name.ilike.%$_search%,industry.ilike.%$_search%',
          );
        }
        final countData = await countQuery;
        if (mounted) setState(() => _totalCount = (countData as List).length);
      }

      final data = List<Map<String, dynamic>>.from(
        await query.order('first_name').range(pageKey, pageKey + _pageSize - 1),
      );
      final isLast = data.length < _pageSize;
      if (isLast) {
        _pagingController.appendLastPage(data);
      } else {
        _pagingController.appendPage(data, pageKey + _pageSize);
      }
    } catch (e) {
      _pagingController.error = e;
    }
  }

  void _refresh() => _pagingController.refresh();

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _MembersFilterSheet(
        selectedIndustry: _selectedIndustry,
        selectedBusinessTag: _selectedBusinessTag,
        selectedHobbyTag: _selectedHobbyTag,
        onApply: (industry, businessTag, hobbyTag) {
          setState(() {
            _selectedIndustry = industry;
            _selectedBusinessTag = businessTag;
            _selectedHobbyTag = hobbyTag;
          });
          _refresh();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: AppColors.black,
            pinned: true,
            title: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text('Members', style: TextStyle(fontWeight: FontWeight.w700)),
                if (_totalCount > 0) ...[
                  const SizedBox(width: 8),
                  Text('$_totalCount members',
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 13, fontWeight: FontWeight.normal)),
                ],
              ],
            ),
            actions: [
              Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.tune_rounded),
                    onPressed: _showFilterSheet,
                  ),
                  if (_activeFilterCount > 0)
                    Positioned(
                      right: 8, top: 8,
                      child: Container(
                        width: 16, height: 16,
                        decoration: const BoxDecoration(
                          color: AppColors.green,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text('$_activeFilterCount',
                              style: const TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.w700)),
                        ),
                      ),
                    ),
                ],
              ),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(52),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                child: TextField(
                  controller: _searchCtrl,
                  decoration: InputDecoration(
                    hintText: 'Search by name, bio, job, company...',
                    prefixIcon: const Icon(Icons.search, color: AppColors.textMuted, size: 20),
                    suffixIcon: _search.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 16),
                            onPressed: () {
                              _searchCtrl.clear();
                              setState(() => _search = '');
                              _refresh();
                            },
                          )
                        : null,
                    isDense: true,
                  ),
                  onChanged: (v) {
                    setState(() => _search = v);
                    Future.delayed(const Duration(milliseconds: 500), _refresh);
                  },
                ),
              ),
            ),
          ),

          // Active filter chips row
          if (_activeFilterCount > 0)
            SliverToBoxAdapter(
              child: SizedBox(
                height: 44,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                  scrollDirection: Axis.horizontal,
                  children: [
                    if (_selectedIndustry != null)
                      _activeChip(_selectedIndustry!, AppColors.green,
                          onRemove: () { setState(() => _selectedIndustry = null); _refresh(); }),
                    if (_selectedBusinessTag != null)
                      _activeChip(_selectedBusinessTag!, AppColors.orange,
                          onRemove: () { setState(() => _selectedBusinessTag = null); _refresh(); }),
                    if (_selectedHobbyTag != null)
                      _activeChip(_selectedHobbyTag!, AppColors.green,
                          onRemove: () { setState(() => _selectedHobbyTag = null); _refresh(); }),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _selectedIndustry = null;
                          _selectedBusinessTag = null;
                          _selectedHobbyTag = null;
                        });
                        _refresh();
                      },
                      child: const Text('Clear all',
                          style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                    ),
                  ],
                ),
              ),
            ),

          SliverPadding(
            padding: const EdgeInsets.only(top: 8),
            sliver: PagedSliverList<int, Map<String, dynamic>>(
              pagingController: _pagingController,
              builderDelegate: PagedChildBuilderDelegate(
                itemBuilder: (ctx, member, i) => MemberCard(member: member),
                firstPageProgressIndicatorBuilder: (_) => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(color: AppColors.green),
                  ),
                ),
                newPageProgressIndicatorBuilder: (_) => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(color: AppColors.green, strokeWidth: 2),
                  ),
                ),
                noItemsFoundIndicatorBuilder: (_) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(48),
                    child: Column(
                      children: [
                        const Icon(Icons.people_outline, size: 48, color: AppColors.textMuted),
                        const SizedBox(height: 12),
                        const Text('No members found',
                            style: TextStyle(color: AppColors.textMuted)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _activeChip(String label, Color color, {required VoidCallback onRemove}) =>
      Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.fromLTRB(10, 0, 4, 0),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
            const SizedBox(width: 4),
            GestureDetector(
              onTap: onRemove,
              child: Icon(Icons.close, size: 14, color: color),
            ),
          ],
        ),
      );
}

class MemberCard extends StatelessWidget {
  final Map<String, dynamic> member;

  const MemberCard({super.key, required this.member});

  @override
  Widget build(BuildContext context) {
    final yiVertical = member['yi_vertical'] as String?;
    final verticalColor = VerticalsCache.colorForSlug(yiVertical);
    final firstName = member['first_name'] as String? ?? '';
    final lastName = member['last_name'] as String? ?? '';
    final fullName = '$firstName $lastName'.trim();
    final initials = [
      if (firstName.isNotEmpty) firstName[0],
      if (lastName.isNotEmpty) lastName[0],
    ].join().toUpperCase();
    final isCommittee = member['member_type'] == 'committee';
    final yiPosition = member['yi_position'] as String?;
    final city = member['city'] as String?;

    final subtitle = [
      member['job_title'],
      if (member['company_name'] != null) member['company_name'],
    ].whereType<String>().join(' @ ');

    final positionText = (yiPosition != null && yiPosition != 'none')
        ? AppConstants.positionLabel(yiPosition)
        : null;

    return GestureDetector(
      onTap: () => context.pushNamed('member-detail',
          pathParameters: {'id': member['id'] as String}),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Avatar
            Stack(
              children: [
                Container(
                  width: 52, height: 52,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: verticalColor.withOpacity(0.5), width: 2),
                  ),
                  child: ClipOval(
                    child: member['headshot_url'] != null
                        ? CachedNetworkImage(
                            imageUrl: member['headshot_url'] as String,
                            fit: BoxFit.cover,
                          )
                        : Container(
                            color: verticalColor.withOpacity(0.12),
                            child: Center(
                              child: Text(
                                initials.isEmpty ? '?' : initials,
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  color: verticalColor,
                                ),
                              ),
                            ),
                          ),
                  ),
                ),
                if (isCommittee)
                  Positioned(
                    bottom: 0, right: 0,
                    child: Container(
                      width: 17, height: 17,
                      decoration: BoxDecoration(
                        color: AppColors.green,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.black, width: 2),
                      ),
                      child: const Icon(Icons.star, size: 9, color: Colors.white),
                    ),
                  ),
              ],
            ),

            const SizedBox(width: 14),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    fullName.isEmpty ? 'Member' : fullName,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                  ),

                  if ((yiVertical != null && yiVertical != 'none') || isCommittee) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        if (yiVertical != null && yiVertical != 'none')
                          _badge(VerticalsCache.labelForSlug(yiVertical), verticalColor)
                        else
                          _badge('COMMITTEE', AppColors.green),
                        if (positionText != null) ...[
                          const SizedBox(width: 6),
                          Text(
                            positionText,
                            style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                          ),
                        ] else if (isCommittee && yiVertical != null && yiVertical != 'none') ...[
                          const SizedBox(width: 6),
                          _badge('COMMITTEE', AppColors.green),
                        ],
                      ],
                    ),
                  ],

                  if (subtitle.isNotEmpty) ...[
                    const SizedBox(height: 5),
                    Text(
                      subtitle,
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],

                  if (city != null && city.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined, size: 12, color: AppColors.textMuted),
                        const SizedBox(width: 3),
                        Text(city, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            const Icon(Icons.chevron_right, color: AppColors.textMuted, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _badge(String label, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Text(
          label,
          style: TextStyle(
              color: color, fontSize: 10, fontWeight: FontWeight.w600),
        ),
      );
}

// ── Members Filter Sheet ──────────────────────────────────────────────────────
class _MembersFilterSheet extends StatefulWidget {
  final String? selectedIndustry;
  final String? selectedBusinessTag;
  final String? selectedHobbyTag;
  final void Function(String? industry, String? businessTag, String? hobbyTag) onApply;

  const _MembersFilterSheet({
    required this.selectedIndustry,
    required this.selectedBusinessTag,
    required this.selectedHobbyTag,
    required this.onApply,
  });

  @override
  State<_MembersFilterSheet> createState() => _MembersFilterSheetState();
}

class _MembersFilterSheetState extends State<_MembersFilterSheet> {
  late String? _industry;
  late String? _businessTag;
  late String? _hobbyTag;
  List<String> _businessTags = [];
  List<String> _hobbyTags = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _industry = widget.selectedIndustry;
    _businessTag = widget.selectedBusinessTag;
    _hobbyTag = widget.selectedHobbyTag;
    _loadTags();
  }

  Future<void> _loadTags() async {
    final data = await Supabase.instance.client
        .from('profiles')
        .select('business_tags, hobby_tags')
        .eq('onboarding_done', true)
        .eq('is_test_user', false);
    final bSet = <String>{};
    final hSet = <String>{};
    for (final row in data) {
      bSet.addAll((row['business_tags'] as List?)?.cast<String>() ?? []);
      hSet.addAll((row['hobby_tags'] as List?)?.cast<String>() ?? []);
    }
    if (mounted) {
      setState(() {
        _businessTags = bSet.toList()..sort();
        _hobbyTags = hSet.toList()..sort();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    final industries = AppConstants.industries.where((i) => i != 'N/A').toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.85,
      expand: false,
      builder: (_, scrollCtrl) => Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.symmetric(vertical: 10),
            width: 36, height: 4,
            decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 16, 12),
            child: Row(
              children: [
                const Text('Filter Members',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.white)),
                const Spacer(),
                TextButton(
                  onPressed: () => setState(() { _industry = null; _businessTag = null; _hobbyTag = null; }),
                  child: const Text('Reset', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
                ),
              ],
            ),
          ),
          Container(height: 1, color: AppColors.divider),
          Expanded(
            child: ListView(
              controller: scrollCtrl,
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              children: [
                // INDUSTRY
                _dropdownLabel('INDUSTRY'),
                _searchableDropdown(
                  value: _industry,
                  hint: 'All Industries',
                  items: industries,
                  onChanged: (v) => setState(() => _industry = v),
                ),
                const SizedBox(height: 20),

                // BUSINESS KEYWORDS
                _dropdownLabel('BUSINESS KEYWORDS'),
                _loading
                    ? _loadingBox()
                    : _searchableDropdown(
                        value: _businessTag,
                        hint: 'Any Keyword',
                        items: _businessTags,
                        onChanged: (v) => setState(() => _businessTag = v),
                      ),
                const SizedBox(height: 20),

                // INTERESTED (HOBBIES)
                _dropdownLabel('INTERESTED IN'),
                _loading
                    ? _loadingBox()
                    : _searchableDropdown(
                        value: _hobbyTag,
                        hint: 'Any Interest',
                        items: _hobbyTags,
                        onChanged: (v) => setState(() => _hobbyTag = v),
                      ),

                SizedBox(height: bottomPad + 8),
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
                  widget.onApply(_industry, _businessTag, _hobbyTag);
                },
                child: const Text('Apply Filters'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dropdownLabel(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                color: AppColors.textMuted, letterSpacing: 0.8)),
      );

  Widget _loadingBox() => Container(
        height: 48,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        child: const SizedBox(
          width: 18, height: 18,
          child: CircularProgressIndicator(color: AppColors.green, strokeWidth: 2),
        ),
      );

  Widget _searchableDropdown({
    required String? value,
    required String hint,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    return GestureDetector(
      onTap: () async {
        final selected = await showModalBottomSheet<String>(
          context: context,
          isScrollControlled: true,
          backgroundColor: AppColors.surface,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          builder: (_) => _OptionPickerSheet(
            title: hint,
            items: items,
            selected: value,
          ),
        );
        if (selected != null) {
          onChanged(selected == '__clear__' ? null : selected);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: value != null ? AppColors.green.withOpacity(0.5) : AppColors.border,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                value ?? hint,
                style: TextStyle(
                  color: value != null ? AppColors.white : AppColors.textMuted,
                  fontSize: 14,
                ),
              ),
            ),
            if (value != null)
              GestureDetector(
                onTap: () => onChanged(null),
                child: const Icon(Icons.close, size: 16, color: AppColors.textMuted),
              )
            else
              const Icon(Icons.keyboard_arrow_down, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}

// ── Option Picker Sheet ───────────────────────────────────────────────────────
class _OptionPickerSheet extends StatefulWidget {
  final String title;
  final List<String> items;
  final String? selected;

  const _OptionPickerSheet({required this.title, required this.items, this.selected});

  @override
  State<_OptionPickerSheet> createState() => _OptionPickerSheetState();
}

class _OptionPickerSheetState extends State<_OptionPickerSheet> {
  String _search = '';
  final _ctrl = TextEditingController();

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    final filtered = widget.items
        .where((i) => i.toLowerCase().contains(_search.toLowerCase()))
        .toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (_, scrollCtrl) => Column(
        children: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 10),
            width: 36, height: 4,
            decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: TextField(
              controller: _ctrl,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Search ${widget.title.toLowerCase()}...',
                prefixIcon: const Icon(Icons.search, size: 18, color: AppColors.textMuted),
                suffixIcon: _search.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 16),
                        onPressed: () { _ctrl.clear(); setState(() => _search = ''); },
                      )
                    : null,
                isDense: true,
              ),
              onChanged: (v) => setState(() => _search = v),
            ),
          ),
          Container(height: 1, color: AppColors.divider),
          Expanded(
            child: ListView(
              controller: scrollCtrl,
              children: [
                // Clear option
                if (widget.selected != null)
                  ListTile(
                    leading: const Icon(Icons.clear_all, color: AppColors.textMuted, size: 18),
                    title: const Text('Clear selection',
                        style: TextStyle(color: AppColors.textMuted, fontSize: 14)),
                    onTap: () => Navigator.pop(context, '__clear__'),
                  ),
                ...filtered.map((item) {
                  final isSelected = item == widget.selected;
                  return ListTile(
                    title: Text(item,
                        style: TextStyle(
                          color: isSelected ? AppColors.green : AppColors.white,
                          fontSize: 14,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        )),
                    trailing: isSelected
                        ? const Icon(Icons.check, color: AppColors.green, size: 18)
                        : null,
                    onTap: () => Navigator.pop(context, item),
                  );
                }),
                SizedBox(height: bottomPad + 16),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

