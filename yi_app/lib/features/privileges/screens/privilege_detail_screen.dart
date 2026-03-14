import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_colors.dart';

// ── Online Offer Detail ──────────────────────────────────────────────────────

class OnlineOfferDetailScreen extends StatefulWidget {
  final Map<String, dynamic> offer;
  const OnlineOfferDetailScreen({super.key, required this.offer});

  @override
  State<OnlineOfferDetailScreen> createState() => _OnlineOfferDetailScreenState();
}

class _OnlineOfferDetailScreenState extends State<OnlineOfferDetailScreen> {
  bool _copied = false;

  void _copyCode(String code) {
    Clipboard.setData(ClipboardData(text: code));
    setState(() => _copied = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final offer = widget.offer;
    final brandName = offer['brand_name'] as String? ?? '';
    final initial = brandName.isNotEmpty ? brandName[0].toUpperCase() : '?';
    final couponCode = offer['coupon_code'] as String?;
    final websiteUrl = offer['website_url'] as String?;
    final expiryDate = offer['expiry_date'] as String?;
    final aboutOffer = offer['about_offer'] as String?;
    final howToClaim = offer['how_to_claim'] as String?;
    final termsAndConditions = offer['terms_and_conditions'] as String?;
    final logoUrl = offer['logo_url'] as String?;

    return Scaffold(
      backgroundColor: AppColors.black,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: AppColors.black,
            pinned: true,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (offer['banner_url'] != null)
                  CachedNetworkImage(
                    imageUrl: offer['banner_url'] as String,
                    width: double.infinity,
                    fit: BoxFit.fitWidth,
                  ),
                Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Brand header
                  Row(
                    children: [
                      if (logoUrl != null)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: CachedNetworkImage(
                            imageUrl: logoUrl,
                            width: 48, height: 48, fit: BoxFit.contain,
                          ),
                        )
                      else
                        Container(
                          width: 48, height: 48,
                          decoration: BoxDecoration(
                            color: AppColors.surfaceAlt,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Center(child: Text(initial, style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textMuted,
                          ))),
                        ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(brandName, style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 18,
                            )),
                            if (offer['category'] != null)
                              Text(offer['category'] as String, style: const TextStyle(
                                color: AppColors.textMuted, fontSize: 13,
                              )),
                          ],
                        ),
                      ),
                      _Badge(label: 'Online', color: AppColors.green, icon: Icons.language_outlined),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Title
                  Text(offer['title'] as String? ?? '',
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 17)),

                  // Discount label
                  if (offer['discount_label'] != null) ...[
                    const SizedBox(height: 6),
                    Text(offer['discount_label'] as String,
                      style: const TextStyle(
                        color: AppColors.green, fontWeight: FontWeight.bold, fontSize: 28,
                      )),
                  ],

                  // About this offer
                  if (aboutOffer != null && aboutOffer.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    const Divider(color: AppColors.divider),
                    const SizedBox(height: 16),
                    const Text('About this offer', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                    const SizedBox(height: 8),
                    Text(aboutOffer, style: const TextStyle(
                      color: AppColors.textMuted, fontSize: 13, height: 1.6,
                    )),
                  ],

                  // Coupon code — prominent section
                  if (couponCode != null) ...[
                    const SizedBox(height: 20),
                    const Divider(color: AppColors.divider),
                    const SizedBox(height: 16),
                    const Text('Coupon Code', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                    const SizedBox(height: 10),
                    GestureDetector(
                      onTap: () => _copyCode(couponCode),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
                        decoration: BoxDecoration(
                          color: AppColors.green.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _copied
                                ? AppColors.green
                                : AppColors.green.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(couponCode, style: const TextStyle(
                              fontFamily: 'monospace', fontSize: 24,
                              fontWeight: FontWeight.bold, letterSpacing: 4,
                              color: AppColors.green,
                            )),
                            const SizedBox(width: 14),
                            Icon(
                              _copied ? Icons.check_circle : Icons.copy_outlined,
                              color: AppColors.green, size: 22,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Center(
                      child: Text(
                        _copied ? 'Code copied to clipboard!' : 'Tap to copy code',
                        style: TextStyle(
                          color: _copied ? AppColors.green : AppColors.textMuted,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],

                  // How to Claim
                  if (howToClaim != null && howToClaim.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    const Divider(color: AppColors.divider),
                    const SizedBox(height: 16),
                    const Row(
                      children: [
                        Icon(Icons.info_outline, size: 16, color: AppColors.green),
                        SizedBox(width: 6),
                        Text('How to Claim', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceAlt,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Text(howToClaim, style: const TextStyle(
                        color: AppColors.textMuted, fontSize: 13, height: 1.6,
                      )),
                    ),
                  ],

                  // Terms & Conditions
                  if (termsAndConditions != null && termsAndConditions.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    const Divider(color: AppColors.divider),
                    const SizedBox(height: 16),
                    const Text('Terms & Conditions', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                    const SizedBox(height: 8),
                    Text(termsAndConditions, style: const TextStyle(
                      color: AppColors.textMuted, fontSize: 13, height: 1.6,
                    )),
                  ],

                  // Expiry date
                  if (expiryDate != null) ...[
                    const SizedBox(height: 14),
                    Row(children: [
                      const Icon(Icons.schedule_outlined, size: 13, color: AppColors.textMuted),
                      const SizedBox(width: 5),
                      Text('Expires $expiryDate',
                        style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                    ]),
                  ],

                  const SizedBox(height: 28),

                  // Visit Website button
                  if (websiteUrl != null && websiteUrl.isNotEmpty)
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: () => launchUrl(
                          Uri.parse(websiteUrl),
                          mode: LaunchMode.externalApplication,
                        ),
                        icon: const Icon(Icons.open_in_new, size: 18),
                        label: const Text('Visit Website', style: TextStyle(fontSize: 15)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.green,
                          foregroundColor: AppColors.black,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Offline Offer Detail ─────────────────────────────────────────────────────

class OfflineOfferDetailScreen extends StatelessWidget {
  final Map<String, dynamic> offer;
  const OfflineOfferDetailScreen({super.key, required this.offer});

  @override
  Widget build(BuildContext context) {
    final businessName = offer['business_name'] as String? ?? '';
    final initial = businessName.isNotEmpty ? businessName[0].toUpperCase() : '?';
    final address = offer['address'] as String?;
    final mapUrl = offer['map_url'] as String?;
    final phone = offer['phone'] as String?;
    final city = offer['city'] as String?;
    final expiryDate = offer['expiry_date'] as String?;
    final howToAvail = offer['how_to_avail'] as String?;
    final hasPhone = phone != null && phone.isNotEmpty;
    final hasAddress = address != null && address.isNotEmpty;
    final hasMap = (mapUrl != null && mapUrl.isNotEmpty) || hasAddress;
    final logoUrl = offer['logo_url'] as String?;

    return Scaffold(
      backgroundColor: AppColors.black,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: AppColors.black,
            pinned: true,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (offer['banner_url'] != null)
                  CachedNetworkImage(
                    imageUrl: offer['banner_url'] as String,
                    width: double.infinity,
                    fit: BoxFit.fitWidth,
                  ),
                Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Business header
                  Row(
                    children: [
                      if (logoUrl != null)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: CachedNetworkImage(
                            imageUrl: logoUrl,
                            width: 48, height: 48, fit: BoxFit.contain,
                          ),
                        )
                      else
                        Container(
                          width: 48, height: 48,
                          decoration: BoxDecoration(
                            color: AppColors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.orange.withOpacity(0.3)),
                          ),
                          child: Center(child: Text(initial, style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.orange,
                          ))),
                        ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(businessName, style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 18,
                            )),
                            if (offer['category'] != null || city != null)
                              Text(
                                [if (offer['category'] != null) offer['category'] as String,
                                  if (city != null) city].join(' · '),
                                style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                              ),
                          ],
                        ),
                      ),
                      _Badge(label: 'In-Store', color: AppColors.orange, icon: Icons.storefront_outlined),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Offer description
                  Text(offer['offer_description'] as String? ?? '',
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 17)),

                  // Discount label
                  if (offer['discount_label'] != null) ...[
                    const SizedBox(height: 6),
                    Text(offer['discount_label'] as String,
                      style: const TextStyle(
                        color: AppColors.orange, fontWeight: FontWeight.bold, fontSize: 28,
                      )),
                  ],

                  // How to Avail
                  if (howToAvail != null && howToAvail.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    const Divider(color: AppColors.divider),
                    const SizedBox(height: 16),
                    const Row(
                      children: [
                        Icon(Icons.info_outline, size: 16, color: AppColors.orange),
                        SizedBox(width: 6),
                        Text('How to Avail', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceAlt,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Text(howToAvail, style: const TextStyle(
                        color: AppColors.textMuted, fontSize: 13, height: 1.6,
                      )),
                    ),
                  ],

                  // Address
                  if (hasAddress) ...[
                    const SizedBox(height: 20),
                    const Divider(color: AppColors.divider),
                    const SizedBox(height: 16),
                    const Row(
                      children: [
                        Icon(Icons.location_on_outlined, size: 16, color: AppColors.orange),
                        SizedBox(width: 6),
                        Text('Location', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(address!, style: const TextStyle(
                      color: AppColors.textMuted, fontSize: 13, height: 1.5,
                    )),
                  ],

                  // Expiry date
                  if (expiryDate != null) ...[
                    const SizedBox(height: 14),
                    Row(children: [
                      const Icon(Icons.schedule_outlined, size: 13, color: AppColors.textMuted),
                      const SizedBox(width: 5),
                      Text('Expires $expiryDate',
                        style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                    ]),
                  ],

                  const SizedBox(height: 28),

                  // Action buttons
                  if (hasPhone || hasMap)
                    Row(
                      children: [
                        if (hasPhone)
                          Expanded(
                            child: SizedBox(
                              height: 52,
                              child: OutlinedButton.icon(
                                onPressed: () => launchUrl(Uri.parse('tel:$phone')),
                                icon: const Icon(Icons.phone_outlined, size: 18),
                                label: const Text('Call', style: TextStyle(fontSize: 15)),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.white,
                                  side: BorderSide(color: AppColors.border),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                            ),
                          ),
                        if (hasPhone && hasMap) const SizedBox(width: 10),
                        if (hasMap)
                          Expanded(
                            child: SizedBox(
                              height: 52,
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  final url = (mapUrl != null && mapUrl.isNotEmpty)
                                      ? mapUrl
                                      : 'https://maps.google.com/?q=${Uri.encodeComponent(address!)}';
                                  launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                                },
                                icon: const Icon(Icons.map_outlined, size: 18),
                                label: const Text('Directions', style: TextStyle(fontSize: 15)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.orange,
                                  foregroundColor: AppColors.black,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Shared ───────────────────────────────────────────────────────────────────

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;
  const _Badge({required this.label, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 3),
          Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
