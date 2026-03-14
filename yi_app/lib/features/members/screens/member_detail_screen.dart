import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/services/verticals_cache.dart';
import '../../../core/theme/app_colors.dart';

class MemberDetailScreen extends StatelessWidget {
  final String memberId;

  const MemberDetailScreen({super.key, required this.memberId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black,
      body: FutureBuilder(
        future: Supabase.instance.client
            .from('profiles').select('*').eq('id', memberId).single(),
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: AppColors.green));
          }
          if (!snap.hasData) {
            return const Center(child: Text('Member not found'));
          }

          final m = snap.data as Map<String, dynamic>;
          final yiVertical = m['yi_vertical'] as String?;
          final verticalColor = VerticalsCache.colorForSlug(yiVertical);
          final firstName = m['first_name'] as String? ?? '';
          final lastName = m['last_name'] as String? ?? '';
          final fullName = '$firstName $lastName'.trim();
          final initials = [
            if (firstName.isNotEmpty) firstName[0],
            if (lastName.isNotEmpty) lastName[0],
          ].join().toUpperCase();
          final dob = m['dob'] != null ? DateTime.tryParse(m['dob'] as String) : null;
          final memberSinceYear = m['yi_member_since'] as int?;
          final relationshipStatus = m['relationship_status'] as String?;
          final isMarried = relationshipStatus == 'married';
          final anniversaryDate = m['anniversary_date'] != null
              ? DateTime.tryParse(m['anniversary_date'] as String)
              : null;
          final phone = m['phone'] as String?;
          final businessTags = (m['business_tags'] as List?)?.cast<String>() ?? [];
          final hobbyTags = (m['hobby_tags'] as List?)?.cast<String>() ?? [];

          String s(String? v) => (v == null || v.trim().isEmpty) ? '–' : v.trim();

          String address() {
            final parts = [
              m['address_line1'], m['address_line2'],
              m['city'], m['state'], m['country'],
            ].whereType<String>().where((x) => x.isNotEmpty).toList();
            return parts.isEmpty ? '–' : parts.join(', ');
          }

          return CustomScrollView(
            slivers: [
              // ── App Bar ──────────────────────────────────────────────────
              SliverAppBar(
                expandedHeight: 260,
                pinned: true,
                backgroundColor: AppColors.black,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => context.pop(),
                ),
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
                                child: m['headshot_url'] != null
                                    ? CachedNetworkImage(
                                        imageUrl: m['headshot_url'] as String,
                                        fit: BoxFit.cover)
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
                            if ((m['job_title'] as String?)?.isNotEmpty == true) ...[
                              const SizedBox(height: 3),
                              Text(
                                [
                                  m['job_title'] as String,
                                  if ((m['company_name'] as String?)?.isNotEmpty == true) m['company_name'] as String,
                                ].join(' @ '),
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
                      // ── Badges ────────────────────────────────────────────
                      if ((yiVertical != null && yiVertical != 'none') ||
                          (m['yi_position'] != null && m['yi_position'] != 'none') ||
                          m['member_type'] == 'super_admin')
                        Wrap(
                          spacing: 8, runSpacing: 8,
                          children: [
                            if (yiVertical != null && yiVertical != 'none')
                              _labeledBadge('Vertical', VerticalsCache.labelForSlug(yiVertical), verticalColor),
                            if (m['yi_position'] != null && m['yi_position'] != 'none')
                              _labeledBadge('Position', AppConstants.positionLabel(m['yi_position'] as String), AppColors.orange),
                            if (m['member_type'] == 'super_admin')
                              _badge('Admin', AppColors.green),
                          ],
                        ),

                      // ── Call / WhatsApp ───────────────────────────────────
                      if (phone != null && phone.isNotEmpty) ...[
                        if ((yiVertical != null && yiVertical != 'none') ||
                            (m['yi_position'] != null && m['yi_position'] != 'none') ||
                            m['member_type'] == 'super_admin')
                          const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => launchUrl(Uri.parse('tel:$phone')),
                                icon: const Icon(Icons.phone_outlined, size: 16),
                                label: const Text('Call'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.green,
                                  side: const BorderSide(color: AppColors.green, width: 1),
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  final digits = phone.replaceAll(RegExp(r'[^\d]'), '');
                                  launchUrl(Uri.parse('https://wa.me/$digits'));
                                },
                                icon: const FaIcon(FontAwesomeIcons.whatsapp, size: 16),
                                label: const Text('WhatsApp'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFF25D366),
                                  side: const BorderSide(color: Color(0xFF25D366), width: 1),
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],

                      // ── Personal Bio ──────────────────────────────────────
                      if ((m['personal_bio'] as String?)?.isNotEmpty == true) ...[
                        const SizedBox(height: 16),
                        Text(
                          m['personal_bio'] as String,
                          style: const TextStyle(color: AppColors.textMuted, fontSize: 14, height: 1.6),
                        ),
                      ],

                      // ── Social ────────────────────────────────────────────
                      _sectionHeader('Social'),
                      _linkOrDash(Icons.link, 'LinkedIn', m['linkedin_url'] as String?),
                      _linkOrDash(Icons.camera_alt_outlined, 'Instagram', m['instagram_url'] as String?),
                      _linkOrDash(Icons.alternate_email, 'Twitter / X', m['twitter_url'] as String?),
                      _linkOrDash(Icons.facebook, 'Facebook', m['facebook_url'] as String?),

                      // ── Contact ───────────────────────────────────────────
                      _sectionHeader('Contact'),
                      _detailRow(Icons.phone_outlined, 'Phone', s(phone)),
                      _detailRow(Icons.phone_outlined, 'Alt Phone', s(m['secondary_phone'] as String?)),
                      _detailRow(Icons.email_outlined, 'Email', s(m['primary_email'] as String?),
                          copyable: (m['primary_email'] as String?)?.isNotEmpty == true),
                      _detailRow(Icons.email_outlined, 'Alt Email', s(m['secondary_email'] as String?)),
                      _detailRow(Icons.location_on_outlined, 'Address', address()),

                      // ── Professional ──────────────────────────────────────
                      _sectionHeader('Professional'),
                      _detailRow(Icons.work_outline, 'Job Title', s(m['job_title'] as String?)),
                      _detailRow(Icons.business_outlined, 'Company', s(m['company_name'] as String?)),
                      _detailRow(Icons.category_outlined, 'Industry', s(m['industry'] as String?)),
                      _detailRow(Icons.info_outline, 'About Business', s(m['business_bio'] as String?)),
                      _linkOrDash(Icons.link_outlined, 'Website', m['business_website'] as String?),

                      // ── Young Indians ─────────────────────────────────────
                      _sectionHeader('Young Indians'),
                      if (yiVertical != null && yiVertical != 'none')
                        _detailRow(Icons.groups_outlined, 'Vertical', VerticalsCache.labelForSlug(yiVertical)),
                      if (m['yi_position'] != null && m['yi_position'] != 'none')
                        _detailRow(Icons.badge_outlined, 'Position',
                            AppConstants.positionLabel(m['yi_position'] as String)),
                      _detailRow(Icons.verified_outlined, 'YI Member Since',
                          memberSinceYear != null ? memberSinceYear.toString() : '–'),

                      // ── Personal ──────────────────────────────────────────
                      _sectionHeader('Personal'),
                      _detailRow(Icons.cake_outlined, 'Birthday',
                          dob != null ? DateFormat('d MMMM yyyy').format(dob) : '–'),
                      _detailRow(Icons.bloodtype_outlined, 'Blood Group', s(m['blood_group'] as String?)),
                      _detailRow(Icons.favorite_outline, 'Relationship',
                          relationshipStatus == 'married' ? 'Married'
                          : relationshipStatus == 'single' ? 'Single' : '–'),
                      if (isMarried) ...[
                        _detailRow(Icons.person_outline, 'Spouse', s(m['spouse_name'] as String?)),
                        _detailRow(Icons.groups_outlined, 'Spouse YI Member',
                            m['is_spouse_yi_member'] == true ? 'Yes'
                            : m['is_spouse_yi_member'] == false ? 'No' : '–'),
                        _detailRow(Icons.celebration_outlined, 'Anniversary',
                            anniversaryDate != null ? DateFormat('d MMMM yyyy').format(anniversaryDate) : '–'),
                      ],

                      // ── Business Tags ─────────────────────────────────────
                      _sectionHeader('Business'),
                      businessTags.isNotEmpty
                          ? Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: Wrap(
                                spacing: 8, runSpacing: 8,
                                children: businessTags.map((t) => _tagChip(t, AppColors.orange)).toList(),
                              ),
                            )
                          : Padding(
                              padding: const EdgeInsets.only(bottom: 14),
                              child: Text('–', style: const TextStyle(color: AppColors.textMuted, fontSize: 14)),
                            ),

                      // ── Hobby Tags ────────────────────────────────────────
                      _sectionHeader('Hobbies'),
                      hobbyTags.isNotEmpty
                          ? Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: Wrap(
                                spacing: 8, runSpacing: 8,
                                children: hobbyTags.map((t) => _tagChip(t, AppColors.green)).toList(),
                              ),
                            )
                          : Padding(
                              padding: const EdgeInsets.only(bottom: 14),
                              child: Text('–', style: const TextStyle(color: AppColors.textMuted, fontSize: 14)),
                            ),

                      const SizedBox(height: 8),
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

  Widget _sectionHeader(String title) => Padding(
        padding: const EdgeInsets.only(top: 4, bottom: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Divider(color: AppColors.divider),
            const SizedBox(height: 12),
            Text(title.toUpperCase(),
                style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.8)),
            const SizedBox(height: 8),
          ],
        ),
      );

  Widget _detailRow(IconData icon, String label, String value,
      {bool copyable = false}) {
    final isDash = value == '–';
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppColors.textMuted),
          const SizedBox(width: 10),
          SizedBox(
            width: 110,
            child: Text(label,
                style: const TextStyle(color: AppColors.textMuted, fontSize: 14)),
          ),
          Expanded(
            child: GestureDetector(
              onTap: copyable && !isDash
                  ? () => Clipboard.setData(ClipboardData(text: value))
                  : null,
              child: Text(
                value,
                textAlign: TextAlign.right,
                style: TextStyle(
                  color: isDash
                      ? AppColors.textHint
                      : copyable ? AppColors.green : AppColors.white,
                  fontSize: 14,
                  decoration: copyable && !isDash ? TextDecoration.underline : null,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _linkOrDash(IconData icon, String label, String? url) {
    final hasUrl = url != null && url.isNotEmpty;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: GestureDetector(
        onTap: hasUrl ? () => launchUrl(Uri.parse(url!)) : null,
        child: Row(
          children: [
            Icon(icon, size: 16, color: AppColors.textMuted),
            const SizedBox(width: 10),
            SizedBox(
              width: 110,
              child: Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 14)),
            ),
            if (hasUrl) ...[
              Expanded(
                child: Text(
                  url!.replaceAll(RegExp(r'^https?://(www\.)?'), '').split('/').first,
                  style: const TextStyle(color: AppColors.green, fontSize: 14),
                  textAlign: TextAlign.right,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.open_in_new, size: 12, color: AppColors.green),
            ] else
              Expanded(
                child: Text('–',
                    textAlign: TextAlign.right,
                    style: const TextStyle(color: AppColors.textHint, fontSize: 14)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _labeledBadge(String title, String value, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: color.withOpacity(0.10),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: '$title  ',
                style: const TextStyle(
                    color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.w500),
              ),
              TextSpan(
                text: value,
                style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      );

  Widget _badge(String label, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Text(label,
            style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
      );

  Widget _tagChip(String label, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Text(label, style: TextStyle(color: color, fontSize: 12)),
      );
}
