import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/services/verticals_cache.dart';
import '../../../core/theme/app_colors.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;

    return Scaffold(
      backgroundColor: AppColors.black,
      body: FutureBuilder(
        future: Supabase.instance.client
            .from('profiles').select('*').eq('id', user!.id).single(),
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.green));
          }
          final p = snap.data as Map<String, dynamic>? ?? {};

          final firstName  = p['first_name'] as String? ?? '';
          final lastName   = p['last_name']  as String? ?? '';
          final fullName   = '$firstName $lastName'.trim();
          final initials   = [
            if (firstName.isNotEmpty) firstName[0],
            if (lastName.isNotEmpty)  lastName[0],
          ].join().toUpperCase();
          final yiVertical    = p['yi_vertical'] as String?;
          final yiPosition    = p['yi_position'] as String?;
          final verticalColor = VerticalsCache.colorForSlug(yiVertical);
          final dob = p['dob'] != null ? DateTime.tryParse(p['dob'] as String) : null;
          final memberSinceYear    = p['yi_member_since'] as int?;
          final relationshipStatus = p['relationship_status'] as String?;
          final isMarried          = relationshipStatus == 'married';
          final anniversaryDate    = p['anniversary_date'] != null
              ? DateTime.tryParse(p['anniversary_date'] as String) : null;
          final businessTags = (p['business_tags'] as List?)?.cast<String>() ?? [];
          final hobbyTags    = (p['hobby_tags']    as List?)?.cast<String>() ?? [];

          String address() => [
            p['address_line1'], p['address_line2'],
            p['city'], p['state'], p['country'],
          ].whereType<String>().where((s) => s.isNotEmpty).join(', ');

          return CustomScrollView(
            slivers: [
              // ── Hero App Bar ──────────────────────────────────────────────
              SliverAppBar(
                expandedHeight: 260,
                pinned: true,
                backgroundColor: AppColors.black,
                automaticallyImplyLeading: false,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                  onPressed: () => context.pop(),
                ),
                actions: [
                  TextButton.icon(
                    onPressed: () => context.push('/profile/edit'),
                    icon: const Icon(Icons.edit_outlined, size: 16, color: AppColors.green),
                    label: const Text('Edit', style: TextStyle(color: AppColors.green, fontWeight: FontWeight.w600)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.logout_outlined, size: 20),
                    onPressed: () async {
                      await Supabase.instance.client.auth.signOut();
                      if (ctx.mounted) context.go('/login');
                    },
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [verticalColor.withOpacity(0.2), AppColors.black],
                          ),
                        ),
                      ),
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(height: 56),
                            Container(
                              width: 96, height: 96,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: verticalColor, width: 2.5),
                              ),
                              child: ClipOval(
                                child: p['headshot_url'] != null
                                    ? CachedNetworkImage(
                                        imageUrl: p['headshot_url'] as String, fit: BoxFit.cover)
                                    : Container(
                                        color: AppColors.surfaceAlt,
                                        child: Center(
                                          child: Text(
                                            initials.isEmpty ? '?' : initials,
                                            style: TextStyle(fontSize: 34, fontWeight: FontWeight.bold, color: verticalColor),
                                          ),
                                        ),
                                      ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              fullName.isEmpty ? 'Member' : fullName,
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                            if ((p['job_title'] as String?)?.isNotEmpty == true) ...[
                              const SizedBox(height: 3),
                              Text(
                                [p['job_title'], if ((p['company_name'] as String?)?.isNotEmpty == true) p['company_name']]
                                    .whereType<String>().join(' @ '),
                                style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Badges ──────────────────────────────────────────
                      Wrap(
                        spacing: 8, runSpacing: 8,
                        children: [
                          if (yiVertical != null && yiVertical != 'none')
                            _labeledBadge('Vertical', VerticalsCache.labelForSlug(yiVertical), verticalColor),
                          if (yiPosition != null && yiPosition != 'none')
                            _labeledBadge('Position', AppConstants.positionLabel(yiPosition), AppColors.orange),
                          _badge(
                            (p['member_type'] as String? ?? 'member') == 'super_admin' ? 'Admin'
                                : (p['member_type'] as String? ?? 'member') == 'committee' ? 'Committee' : 'Member',
                            AppColors.green,
                          ),
                        ],
                      ),

                      // ── Personal Bio ─────────────────────────────────────
                      if ((p['personal_bio'] as String?)?.isNotEmpty == true) ...[
                        const SizedBox(height: 16),
                        Text(
                          p['personal_bio'] as String,
                          style: const TextStyle(color: AppColors.textMuted, fontSize: 14, height: 1.6),
                        ),
                      ],

                      // ── Social ───────────────────────────────────────────
                      if (_hasSocial(p)) ...[
                        _sectionHeader('Social'),
                        if ((p['linkedin_url']  as String?)?.isNotEmpty == true)
                          _linkRow(context, Icons.link, 'LinkedIn', p['linkedin_url'] as String),
                        if ((p['instagram_url'] as String?)?.isNotEmpty == true)
                          _linkRow(context, Icons.camera_alt_outlined, 'Instagram', p['instagram_url'] as String),
                        if ((p['twitter_url']   as String?)?.isNotEmpty == true)
                          _linkRow(context, Icons.alternate_email, 'Twitter / X', p['twitter_url'] as String),
                        if ((p['facebook_url']  as String?)?.isNotEmpty == true)
                          _linkRow(context, Icons.facebook, 'Facebook', p['facebook_url'] as String),
                      ],

                      // ── Contact ──────────────────────────────────────────
                      _sectionHeader('Contact'),
                      if ((p['phone'] as String?)?.isNotEmpty == true)
                        _detailRow(Icons.phone_outlined, 'Phone', p['phone'] as String),
                      if ((p['secondary_phone'] as String?)?.isNotEmpty == true)
                        _detailRow(Icons.phone_outlined, 'Alt Phone', p['secondary_phone'] as String),
                      if ((p['primary_email'] as String?)?.isNotEmpty == true)
                        _detailRow(Icons.email_outlined, 'Email', p['primary_email'] as String, copyable: true),
                      if ((p['secondary_email'] as String?)?.isNotEmpty == true)
                        _detailRow(Icons.email_outlined, 'Alt Email', p['secondary_email'] as String),
                      if (address().isNotEmpty)
                        _detailRow(Icons.location_on_outlined, 'Address', address()),

                      // ── Professional ─────────────────────────────────────
                      if ((p['job_title'] as String?)?.isNotEmpty == true ||
                          (p['company_name'] as String?)?.isNotEmpty == true ||
                          (p['industry'] as String?)?.isNotEmpty == true ||
                          (p['business_bio'] as String?)?.isNotEmpty == true) ...[
                        _sectionHeader('Professional'),
                        if ((p['job_title'] as String?)?.isNotEmpty == true)
                          _detailRow(Icons.work_outline, 'Job Title', p['job_title'] as String),
                        if ((p['company_name'] as String?)?.isNotEmpty == true)
                          _detailRow(Icons.business_outlined, 'Company', p['company_name'] as String),
                        if ((p['industry'] as String?)?.isNotEmpty == true)
                          _detailRow(Icons.category_outlined, 'Industry', p['industry'] as String),
                        if ((p['business_bio'] as String?)?.isNotEmpty == true)
                          _detailRow(Icons.info_outline, 'About Business', p['business_bio'] as String),
                        if ((p['business_website'] as String?)?.isNotEmpty == true)
                          _linkRow(context, Icons.link_outlined, 'Website', p['business_website'] as String),
                      ],

                      // ── Young Indians ────────────────────────────────────
                      _sectionHeader('Young Indians'),
                      if (yiVertical != null && yiVertical != 'none')
                        _detailRow(Icons.groups_outlined, 'Vertical', VerticalsCache.labelForSlug(yiVertical)),
                      if (yiPosition != null && yiPosition != 'none')
                        _detailRow(Icons.badge_outlined, 'Position', AppConstants.positionLabel(yiPosition)),
                      if (memberSinceYear != null)
                        _detailRow(Icons.verified_outlined, 'YI Member Since', memberSinceYear.toString()),
                      _detailRow(Icons.calendar_today_outlined, 'App Member Since',
                          DateFormat('MMMM yyyy').format(DateTime.parse(p['created_at'] as String).toLocal())),

                      // ── Personal ─────────────────────────────────────────
                      if (dob != null ||
                          (p['blood_group'] as String?)?.isNotEmpty == true ||
                          relationshipStatus != null) ...[
                        _sectionHeader('Personal'),
                        if (dob != null)
                          _detailRow(Icons.cake_outlined, 'Birthday', DateFormat('d MMMM yyyy').format(dob)),
                        if ((p['blood_group'] as String?)?.isNotEmpty == true)
                          _detailRow(Icons.bloodtype_outlined, 'Blood Group', p['blood_group'] as String),
                        if (relationshipStatus != null)
                          _detailRow(Icons.favorite_outline, 'Relationship', isMarried ? 'Married' : 'Single'),
                        if (isMarried && (p['spouse_name'] as String?)?.isNotEmpty == true)
                          _detailRow(Icons.person_outline, 'Spouse', p['spouse_name'] as String),
                        if (isMarried && p['is_spouse_yi_member'] == true)
                          _detailRow(Icons.groups_outlined, 'Spouse YI Member', 'Yes'),
                        if (isMarried && anniversaryDate != null)
                          _detailRow(Icons.celebration_outlined, 'Anniversary',
                              DateFormat('d MMMM yyyy').format(anniversaryDate)),
                      ],

                      // ── Business Tags ────────────────────────────────────
                      if (businessTags.isNotEmpty) ...[
                        _sectionHeader('Business'),
                        _tagWrap(businessTags, AppColors.orange),
                        const SizedBox(height: 8),
                      ],

                      // ── Hobby Tags ───────────────────────────────────────
                      if (hobbyTags.isNotEmpty) ...[
                        _sectionHeader('Hobbies'),
                        _tagWrap(hobbyTags, AppColors.green),
                        const SizedBox(height: 8),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  bool _hasSocial(Map<String, dynamic> p) =>
      (p['linkedin_url']  as String?)?.isNotEmpty == true ||
      (p['instagram_url'] as String?)?.isNotEmpty == true ||
      (p['twitter_url']   as String?)?.isNotEmpty == true ||
      (p['facebook_url']  as String?)?.isNotEmpty == true;

  Widget _sectionHeader(String title) => Padding(
    padding: const EdgeInsets.only(top: 4, bottom: 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(color: AppColors.divider),
        const SizedBox(height: 12),
        Text(title.toUpperCase(),
            style: const TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.8)),
        const SizedBox(height: 8),
      ],
    ),
  );

  Widget _labeledBadge(String title, String value, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
    decoration: BoxDecoration(
      color: color.withOpacity(0.10),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: color.withOpacity(0.3)),
    ),
    child: RichText(
      text: TextSpan(children: [
        TextSpan(text: '$title  ',
            style: const TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.w500)),
        TextSpan(text: value,
            style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
      ]),
    ),
  );

  Widget _badge(String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
    decoration: BoxDecoration(
      color: color.withOpacity(0.12),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: color.withOpacity(0.3)),
    ),
    child: Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
  );

  Widget _detailRow(IconData icon, String label, String value, {bool copyable = false}) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppColors.textMuted),
        const SizedBox(width: 10),
        SizedBox(width: 120,
            child: Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 14))),
        Expanded(
          child: GestureDetector(
            onTap: copyable ? () => Clipboard.setData(ClipboardData(text: value)) : null,
            child: Text(value,
                textAlign: TextAlign.right,
                style: TextStyle(
                  color: copyable ? AppColors.green : AppColors.white,
                  fontSize: 14,
                  decoration: copyable ? TextDecoration.underline : null,
                )),
          ),
        ),
      ],
    ),
  );

  Widget _linkRow(BuildContext context, IconData icon, String label, String url) => GestureDetector(
    onTap: () => launchUrl(Uri.parse(url)),
    child: Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.textMuted),
          const SizedBox(width: 10),
          SizedBox(width: 120,
              child: Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 14))),
          Expanded(
            child: Text(
              url.replaceAll(RegExp(r'^https?://(www\.)?'), '').split('/').first,
              style: const TextStyle(color: AppColors.green, fontSize: 14),
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 4),
          const Icon(Icons.open_in_new, size: 12, color: AppColors.green),
        ],
      ),
    ),
  );

  Widget _tagWrap(List<String> tags, Color color) => Wrap(
    spacing: 8, runSpacing: 8,
    children: tags.map((t) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Text(t, style: TextStyle(color: color, fontSize: 12)),
    )).toList(),
  );
}
