class AppConstants {
  AppConstants._();

  // ── YI Verticals ─────────────────────────────────────────────────────────
  static const List<Map<String, String>> yiVerticals = [
    {'value': 'none',              'label': 'None (General Member)'},
    {'value': 'yuva',             'label': 'YUVA'},
    {'value': 'thalir',           'label': 'THALIR'},
    {'value': 'rural_initiatives','label': 'Rural Initiatives'},
    {'value': 'masoom',           'label': 'MASOOM'},
    {'value': 'road_safety',      'label': 'Road Safety'},
    {'value': 'health',           'label': 'Health'},
    {'value': 'accessibility',    'label': 'Accessibility'},
    {'value': 'climate_change',   'label': 'Climate Change'},
    {'value': 'entrepreneurship', 'label': 'Entrepreneurship'},
    {'value': 'innovation',       'label': 'Innovation'},
    {'value': 'learning',         'label': 'Learning'},
    {'value': 'branding',         'label': 'Branding'},
  ];

  // ── YI Positions (shown only when vertical != none) ───────────────────────
  static const List<Map<String, String>> yiPositions = [
    {'value': 'none',       'label': 'Select Position'},
    {'value': 'chair',      'label': 'Chair'},
    {'value': 'co_chair',   'label': 'Co-Chair'},
    {'value': 'joint_chair','label': 'Joint Chair'},
    {'value': 'ec_member',  'label': 'EC Member'},
    {'value': 'mentor',     'label': 'Mentor'},
  ];

  // ── Blood Groups ──────────────────────────────────────────────────────────
  static const List<String> bloodGroups = [
    'A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-',
  ];

  // ── Industries ────────────────────────────────────────────────────────────
  static const List<String> industries = [
    'N/A',
    'Agriculture',
    'Automotive',
    'Banking & Finance',
    'Construction & Real Estate',
    'Consumer Goods',
    'Defence',
    'Education',
    'Energy & Utilities',
    'Entertainment & Media',
    'Food & Beverage',
    'Government & Public Sector',
    'Healthcare & Pharma',
    'Hospitality & Tourism',
    'Information Technology',
    'Insurance',
    'Legal & Compliance',
    'Logistics & Supply Chain',
    'Manufacturing',
    'NGO & Social Sector',
    'Retail',
    'Sports & Fitness',
    'Telecommunications',
    'Textiles & Apparel',
    'Other',
  ];

  // ── Business Tags (predefined chips, pick up to 3) ────────────────────────
  static const List<String> businessTags = [
    'Angel Investor',
    'B2B',
    'B2C',
    'Bootstrapped',
    'Co-Founder',
    'Consultant',
    'Exporter',
    'Franchise',
    'Manufacturer',
    'Mentor',
    'Product Company',
    'Service Company',
    'Social Entrepreneur',
    'Startup',
    'VC-Funded',
  ];

  // ── Hobby Tags (predefined chips, pick up to 3) ───────────────────────────
  static const List<String> hobbyTags = [
    'Art & Craft',
    'Chess',
    'Cooking',
    'Cricket',
    'Cycling',
    'Fitness & Gym',
    'Gaming',
    'Gardening',
    'Hiking',
    'Music',
    'Photography',
    'Reading',
    'Travel',
    'Yoga',
  ];

  // ── Country calling codes ─────────────────────────────────────────────────
  static const List<Map<String, String>> countryCodes = [
    {'code': '+91',  'flag': '🇮🇳', 'name': 'India'},
    {'code': '+1',   'flag': '🇺🇸', 'name': 'United States'},
    {'code': '+44',  'flag': '🇬🇧', 'name': 'United Kingdom'},
    {'code': '+61',  'flag': '🇦🇺', 'name': 'Australia'},
    {'code': '+971', 'flag': '🇦🇪', 'name': 'UAE'},
    {'code': '+65',  'flag': '🇸🇬', 'name': 'Singapore'},
    {'code': '+60',  'flag': '🇲🇾', 'name': 'Malaysia'},
    {'code': '+1',   'flag': '🇨🇦', 'name': 'Canada'},
    {'code': '+49',  'flag': '🇩🇪', 'name': 'Germany'},
    {'code': '+33',  'flag': '🇫🇷', 'name': 'France'},
    {'code': '+81',  'flag': '🇯🇵', 'name': 'Japan'},
    {'code': '+86',  'flag': '🇨🇳', 'name': 'China'},
    {'code': '+27',  'flag': '🇿🇦', 'name': 'South Africa'},
    {'code': '+55',  'flag': '🇧🇷', 'name': 'Brazil'},
    {'code': '+7',   'flag': '🇷🇺', 'name': 'Russia'},
  ];

  // ── Countries (for address) ───────────────────────────────────────────────
  static const List<String> countries = [
    'India',
    'United States',
    'United Kingdom',
    'Australia',
    'UAE',
    'Singapore',
    'Malaysia',
    'Canada',
    'Germany',
    'France',
    'Japan',
    'China',
    'South Africa',
    'Brazil',
    'Russia',
    'Other',
  ];

  // ── Indian States (used when country == India) ────────────────────────────
  static const List<String> indianStates = [
    'Andhra Pradesh',
    'Arunachal Pradesh',
    'Assam',
    'Bihar',
    'Chhattisgarh',
    'Goa',
    'Gujarat',
    'Haryana',
    'Himachal Pradesh',
    'Jharkhand',
    'Karnataka',
    'Kerala',
    'Madhya Pradesh',
    'Maharashtra',
    'Manipur',
    'Meghalaya',
    'Mizoram',
    'Nagaland',
    'Odisha',
    'Punjab',
    'Rajasthan',
    'Sikkim',
    'Tamil Nadu',
    'Telangana',
    'Tripura',
    'Uttar Pradesh',
    'Uttarakhand',
    'West Bengal',
    'Andaman and Nicobar Islands',
    'Chandigarh',
    'Dadra and Nagar Haveli and Daman & Diu',
    'Delhi',
    'Jammu & Kashmir',
    'Ladakh',
    'Lakshadweep',
    'Puducherry',
  ];

  // ── Vertical label helper ─────────────────────────────────────────────────
  static String verticalLabel(String? value) {
    if (value == null) return 'NONE';
    return yiVerticals
        .firstWhere((v) => v['value'] == value, orElse: () => {'label': value})['label']!
        .toUpperCase();
  }

  // ── Position label helper ─────────────────────────────────────────────────
  static String positionLabel(String? value) {
    if (value == null || value == 'none') return '';
    return yiPositions
        .firstWhere((p) => p['value'] == value, orElse: () => {'label': value})['label']!;
  }
}
