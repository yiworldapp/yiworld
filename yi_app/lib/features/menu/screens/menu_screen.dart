import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_colors.dart';
import 'mous_screen.dart';

class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black,
      appBar: AppBar(
        backgroundColor: AppColors.black,
        title: const Text('Menu', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
        children: [
          // ── Account ────────────────────────────────────────────────────────
          _sectionHeader('Account'),
          _MenuCard(
            children: [
              _MenuTile(
                icon: Icons.person_outline,
                label: 'View Profile',
                trailing: Icons.chevron_right,
                onTap: () => context.push('/profile'),
              ),
              const Divider(color: AppColors.divider, height: 1),
              _MenuTile(
                icon: Icons.edit_outlined,
                label: 'Edit Profile',
                trailing: Icons.chevron_right,
                onTap: () => context.push('/profile/edit'),
              ),
              const Divider(color: AppColors.divider, height: 1),
              _MenuTile(
                icon: Icons.logout_outlined,
                label: 'Logout',
                destructive: true,
                onTap: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (_) => AlertDialog(
                      backgroundColor: AppColors.surface,
                      title: const Text('Logout'),
                      content: const Text('Are you sure you want to logout?',
                          style: TextStyle(color: AppColors.textMuted)),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel',
                              style: TextStyle(color: AppColors.textMuted)),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Logout',
                              style: TextStyle(color: AppColors.error)),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true && context.mounted) {
                    await Supabase.instance.client.auth.signOut();
                    if (context.mounted) context.go('/login');
                  }
                },
              ),
            ],
          ),

          // ── Organization ───────────────────────────────────────────────────
          _sectionHeader('Organization'),
          _MenuCard(
            children: [
              _MenuTile(
                icon: Icons.description_outlined,
                label: 'MOUs',
                trailing: Icons.chevron_right,
                onTap: () => Navigator.push(context, MaterialPageRoute(
                  builder: (_) => const MOUsScreen(),
                )),
              ),
            ],
          ),

          // ── Legal ──────────────────────────────────────────────────────────
          _sectionHeader('Legal'),
          _MenuCard(
            children: [
              _MenuTile(
                icon: Icons.privacy_tip_outlined,
                label: 'Privacy Policy',
                trailing: Icons.open_in_new,
                onTap: () => launchUrl(Uri.parse('https://youngindians.net/privacy-policy')),
              ),
              const Divider(color: AppColors.divider, height: 1),
              _MenuTile(
                icon: Icons.info_outline,
                label: 'About App',
                trailing: Icons.chevron_right,
                onTap: () => showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    backgroundColor: AppColors.surface,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    title: Row(
                      children: [
                        Container(
                          width: 48, height: 48,
                          decoration: BoxDecoration(
                            color: AppColors.white,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.all(6),
                          child: Image.asset(
                            'assets/images/yi_logo.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                        const SizedBox(width: 14),
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('YiWorld', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                            Text('v1.0.0 · YI Kanpur', style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
                          ],
                        ),
                      ],
                    ),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'YiWorld is the member app for Young Indians (YI) Kanpur Chapter — '
                          'an initiative of the Confederation of Indian Industry (CII).',
                          style: TextStyle(fontSize: 13, color: AppColors.textMuted),
                        ),
                        const Divider(color: AppColors.divider, height: 24),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            GestureDetector(
                              onTap: () => launchUrl(Uri.parse('https://www.brandhero.design/'), mode: LaunchMode.externalApplication),
                              child: Container(
                                width: 48, height: 48,
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceAlt,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: AppColors.border),
                                ),
                                padding: const EdgeInsets.all(6),
                                child: Image.asset(
                                  'assets/images/brandhero_logo.png',
                                  fit: BoxFit.contain,
                                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Brandhero',
                                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.white)),
                                  SizedBox(height: 3),
                                  Text(
                                    'Brand strategy, design & storytelling — your dedicated design & marketing arm.',
                                    style: TextStyle(fontSize: 11, color: AppColors.textMuted, height: 1.4),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Close', style: TextStyle(color: AppColors.green)),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          // ── Brandhero credit ───────────────────────────────────────────────
          const SizedBox(height: 32),
          Center(
            child: Column(
              children: [
                const Text(
                  'DESIGNED & DEVELOPED BY',
                  style: TextStyle(
                    fontSize: 10,
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Image.asset(
                  'assets/images/brandhero_logo.png',
                  height: 28,
                  errorBuilder: (_, __, ___) => const Text(
                    'Brandhero',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 20, 4, 8),
        child: Text(
          title.toUpperCase(),
          style: const TextStyle(
            color: AppColors.textMuted,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.8,
          ),
        ),
      );
}

class _MenuCard extends StatelessWidget {
  final List<Widget> children;

  const _MenuCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(children: children),
    );
  }
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final IconData? trailing;
  final bool destructive;
  final VoidCallback onTap;

  const _MenuTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.trailing,
    this.destructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = destructive ? AppColors.error : AppColors.white;
    final iconColor = destructive ? AppColors.error : AppColors.textMuted;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 20, color: iconColor),
            const SizedBox(width: 14),
            Expanded(
              child: Text(label,
                  style: TextStyle(fontSize: 15, color: color, fontWeight: FontWeight.w500)),
            ),
            if (trailing != null)
              Icon(trailing, size: 16, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}
