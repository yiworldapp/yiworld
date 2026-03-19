import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:confetti/confetti.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/theme/app_colors.dart';

class BirthdaysScreen extends StatefulWidget {
  const BirthdaysScreen({super.key});

  @override
  State<BirthdaysScreen> createState() => _BirthdaysScreenState();
}

class _BirthdaysScreenState extends State<BirthdaysScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late ConfettiController _confettiController;
  final _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                   'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 12,
      vsync: this,
      initialIndex: DateTime.now().month - 1,
    );
    _confettiController = ConfettiController(duration: const Duration(seconds: 2));
    // Delay slightly so the layout is fully settled before blasting confetti
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _confettiController.play();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black,
      appBar: AppBar(
        title: const Text('Birthdays'),
        backgroundColor: AppColors.black,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          labelColor: AppColors.yellow,
          unselectedLabelColor: AppColors.textMuted,
          indicatorColor: AppColors.yellow,
          dividerColor: AppColors.divider,
          tabs: _months.map((m) => Tab(text: m)).toList(),
        ),
      ),
      body: Stack(
        children: [
          TabBarView(
            controller: _tabController,
            children: List.generate(12, (i) => _BirthdayMonthView(month: i + 1)),
          ),
          IgnorePointer(
            child: SizedBox.expand(
              child: Stack(
                children: [
                  Align(
                    alignment: Alignment.topCenter,
                    child: ConfettiWidget(
                      confettiController: _confettiController,
                      blastDirectionality: BlastDirectionality.explosive,
                      numberOfParticles: 40,
                      gravity: 0.3,
                      minBlastForce: 8,
                      maxBlastForce: 30,
                      shouldLoop: false,
                      colors: const [
                        AppColors.yellow,
                        Colors.pink,
                        Colors.blue,
                        Colors.green,
                        Colors.orange,
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BirthdayMonthView extends StatelessWidget {
  final int month;

  const _BirthdayMonthView({required this.month});

  String _relativeDate(int? daysUntil) {
    if (daysUntil == null) return '';
    if (daysUntil == 0) return 'Today!';
    if (daysUntil == 1) return 'Tomorrow';
    if (daysUntil == -1) return 'Yesterday';
    if (daysUntil > 0 && daysUntil <= 7) return 'In $daysUntil days';
    if (daysUntil < 0 && daysUntil >= -7) return '${-daysUntil} days ago';
    return ''; // Show actual date
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: Supabase.instance.client.rpc(
        'get_birthdays_by_month',
        params: {'target_month': month},
      ),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppColors.yellow));
        }

        final data = snap.data as List? ?? [];
        if (data.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.cake_outlined, size: 48, color: AppColors.textMuted),
                const SizedBox(height: 12),
                Text(
                  'No birthdays in ${DateFormat('MMMM').format(DateTime(0, month))}',
                  style: const TextStyle(color: AppColors.textMuted),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: data.length,
          itemBuilder: (ctx, i) {
            final member = data[i] as Map<String, dynamic>;
            final dob = member['dob'] != null ? DateTime.parse(member['dob'] as String).toLocal() : null;
            final daysUntil = member['days_until'] as int?;
            final ageTurning = member['age_turning'] as int?;
            final relDate = _relativeDate(daysUntil);
            final isToday = daysUntil == 0;
            final isPast = (daysUntil ?? 0) < 0;
            final dateText = relDate.isNotEmpty
              ? relDate
              : dob != null ? DateFormat('d MMM').format(dob) : '';

            final displayName = (member['full_name'] as String? ?? '').trim();
            final initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : '?';

            final jobTitle = member['job_title'] as String?;
            final company = member['company_name'] as String?;
            bool _isValid(String? s) => s != null && s.isNotEmpty && s.trim().toLowerCase() != 'na';
            final jobLine = [
              if (_isValid(jobTitle)) jobTitle!,
              if (_isValid(company)) company!,
            ].join(' @ ');

            final memberId = member['id'] as String?;
            final ageLabel = ageTurning != null
                ? (isToday ? 'Turning $ageTurning 🎂' : isPast ? 'Turned $ageTurning' : 'Turning $ageTurning')
                : null;

            return GestureDetector(
              onTap: memberId != null
                  ? () => context.pushNamed('member-detail', pathParameters: {'id': memberId})
                  : null,
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isToday
                    ? AppColors.yellow.withOpacity(0.08)
                    : AppColors.card,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isToday ? AppColors.yellow.withOpacity(0.4) : AppColors.border,
                    width: isToday ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    // Avatar
                    Container(
                      width: 52, height: 52,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isToday ? AppColors.yellow : AppColors.border,
                          width: isToday ? 2 : 1,
                        ),
                      ),
                      child: ClipOval(
                        child: member['headshot_url'] != null
                          ? CachedNetworkImage(
                              imageUrl: member['headshot_url'] as String,
                              fit: BoxFit.cover,
                            )
                          : Container(
                              color: AppColors.surfaceAlt,
                              child: Center(
                                child: Text(
                                  initial,
                                  style: TextStyle(
                                    fontSize: 20, fontWeight: FontWeight.bold,
                                    color: isToday ? AppColors.yellow : AppColors.green,
                                  ),
                                ),
                              ),
                            ),
                      ),
                    ),

                    const SizedBox(width: 14),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  displayName.isEmpty ? 'Member' : displayName,
                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                decoration: BoxDecoration(
                                  color: isToday
                                    ? AppColors.yellow.withOpacity(0.15)
                                    : AppColors.surfaceAlt,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  dateText,
                                  style: TextStyle(
                                    color: isToday ? AppColors.yellow : AppColors.textMuted,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (ageLabel != null || jobLine.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            if (ageLabel != null)
                              Text(
                                ageLabel,
                                style: TextStyle(
                                  color: isToday ? AppColors.yellow : isPast ? AppColors.textMuted : AppColors.textMuted,
                                  fontSize: 12,
                                  fontWeight: isToday ? FontWeight.w600 : FontWeight.normal,
                                ),
                              ),
                            if (jobLine.isNotEmpty)
                              Text(
                                jobLine,
                                style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ],
                      ),
                    ),

                    if (memberId != null)
                      const Icon(Icons.chevron_right, size: 16, color: AppColors.textMuted),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
