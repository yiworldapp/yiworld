import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/theme/app_colors.dart';
import 'privilege_detail_screen.dart';

class PrivilegesScreen extends StatefulWidget {
  const PrivilegesScreen({super.key});

  @override
  State<PrivilegesScreen> createState() => _PrivilegesScreenState();
}

class _PrivilegesScreenState extends State<PrivilegesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black,
      appBar: AppBar(
        title: const Text('Privileges'),
        backgroundColor: AppColors.black,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.green,
          unselectedLabelColor: AppColors.textMuted,
          indicatorColor: AppColors.green,
          dividerColor: AppColors.divider,
          tabs: const [
            Tab(icon: Icon(Icons.language_outlined, size: 16), text: 'Online'),
            Tab(icon: Icon(Icons.storefront_outlined, size: 16), text: 'Offline'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _OnlineTab(),
          _OfflineTab(),
        ],
      ),
    );
  }
}

// ── Online Tab ──────────────────────────────────────────────────────────────

class _OnlineTab extends StatelessWidget {
  const _OnlineTab();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: Supabase.instance.client
          .from('online_offers')
          .select('*')
          .eq('is_active', true)
          .order('created_at', ascending: false),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppColors.green));
        }
        final data = snap.data as List? ?? [];
        if (data.isEmpty) {
          return const _EmptyState(icon: Icons.language_outlined, message: 'No online offers available');
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: data.length,
          itemBuilder: (ctx, i) {
            final offer = data[i] as Map<String, dynamic>;
            return GestureDetector(
              onTap: () => Navigator.push(ctx, MaterialPageRoute(
                builder: (_) => OnlineOfferDetailScreen(offer: offer),
              )),
              child: _OnlineOfferCard(offer: offer),
            );
          },
        );
      },
    );
  }
}

class _OnlineOfferCard extends StatelessWidget {
  final Map<String, dynamic> offer;
  const _OnlineOfferCard({required this.offer});

  @override
  Widget build(BuildContext context) {
    final brandName = offer['brand_name'] as String? ?? '';
    final initial = brandName.isNotEmpty ? brandName[0].toUpperCase() : '?';
    final expiryDate = offer['expiry_date'] as String?;
    final logoUrl = offer['logo_url'] as String?;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (offer['banner_url'] != null)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
              child: CachedNetworkImage(
                imageUrl: offer['banner_url'] as String,
                width: double.infinity, fit: BoxFit.fitWidth,
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (logoUrl != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: CachedNetworkImage(
                          imageUrl: logoUrl,
                          width: 36, height: 36, fit: BoxFit.contain,
                        ),
                      )
                    else
                      Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceAlt, borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(child: Text(initial, style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textMuted,
                        ))),
                      ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(brandName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                          if (offer['category'] != null)
                            Text(offer['category'] as String, style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
                        ],
                      ),
                    ),
                    _Badge(label: 'Online', color: AppColors.green, icon: Icons.language_outlined),
                  ],
                ),
                const SizedBox(height: 10),
                Text(offer['title'] as String? ?? '', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                if (offer['discount_label'] != null) ...[
                  const SizedBox(height: 4),
                  Text(offer['discount_label'] as String,
                    style: const TextStyle(color: AppColors.green, fontWeight: FontWeight.bold, fontSize: 22)),
                ],
                if (expiryDate != null) ...[
                  const SizedBox(height: 6),
                  Row(children: [
                    const Icon(Icons.schedule_outlined, size: 12, color: AppColors.textMuted),
                    const SizedBox(width: 4),
                    Text('Expires $expiryDate', style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
                  ]),
                ],
                const SizedBox(height: 8),
                const Text('Tap to view offer details', style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Offline Tab ─────────────────────────────────────────────────────────────

class _OfflineTab extends StatelessWidget {
  const _OfflineTab();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: Supabase.instance.client
          .from('offline_offers')
          .select('*')
          .eq('is_active', true)
          .order('created_at', ascending: false),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppColors.green));
        }
        final data = snap.data as List? ?? [];
        if (data.isEmpty) {
          return const _EmptyState(icon: Icons.storefront_outlined, message: 'No offline offers available');
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: data.length,
          itemBuilder: (ctx, i) {
            final offer = data[i] as Map<String, dynamic>;
            return GestureDetector(
              onTap: () => Navigator.push(ctx, MaterialPageRoute(
                builder: (_) => OfflineOfferDetailScreen(offer: offer),
              )),
              child: _OfflineOfferCard(offer: offer),
            );
          },
        );
      },
    );
  }
}

class _OfflineOfferCard extends StatelessWidget {
  final Map<String, dynamic> offer;
  const _OfflineOfferCard({required this.offer});

  @override
  Widget build(BuildContext context) {
    final businessName = offer['business_name'] as String? ?? '';
    final initial = businessName.isNotEmpty ? businessName[0].toUpperCase() : '?';
    final city = offer['city'] as String?;
    final expiryDate = offer['expiry_date'] as String?;
    final logoUrl = offer['logo_url'] as String?;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (offer['banner_url'] != null)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
              child: CachedNetworkImage(
                imageUrl: offer['banner_url'] as String,
                width: double.infinity, fit: BoxFit.fitWidth,
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (logoUrl != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: CachedNetworkImage(
                          imageUrl: logoUrl,
                          width: 36, height: 36, fit: BoxFit.contain,
                        ),
                      )
                    else
                      Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceAlt, borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(child: Text(initial, style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textMuted,
                        ))),
                      ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(businessName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                          if (offer['category'] != null || city != null)
                            Text(
                              [if (offer['category'] != null) offer['category'] as String, if (city != null) city].join(' · '),
                              style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                            ),
                        ],
                      ),
                    ),
                    _Badge(label: 'In-Store', color: AppColors.orange, icon: Icons.storefront_outlined),
                  ],
                ),
                const SizedBox(height: 10),
                Text(offer['offer_description'] as String? ?? '', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                if (offer['discount_label'] != null) ...[
                  const SizedBox(height: 4),
                  Text(offer['discount_label'] as String,
                    style: const TextStyle(color: AppColors.orange, fontWeight: FontWeight.bold, fontSize: 22)),
                ],
                if (expiryDate != null) ...[
                  const SizedBox(height: 6),
                  Row(children: [
                    const Icon(Icons.schedule_outlined, size: 12, color: AppColors.textMuted),
                    const SizedBox(width: 4),
                    Text('Expires $expiryDate', style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
                  ]),
                ],
                const SizedBox(height: 8),
                const Text('Tap to view offer details', style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Shared Widgets ───────────────────────────────────────────────────────────

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;
  const _Badge({required this.label, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 3),
          Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  const _EmptyState({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 48, color: AppColors.textMuted),
          const SizedBox(height: 12),
          Text(message, style: const TextStyle(color: AppColors.textMuted)),
        ],
      ),
    );
  }
}
