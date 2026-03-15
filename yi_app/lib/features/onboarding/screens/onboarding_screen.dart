import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageController = PageController();
  int _currentPage = 0;
  bool _saving = false;

  // ── Step 1: Identity & Contact ────────────────────────────────────────────
  File? _photoFile;
  final _firstNameCtrl      = TextEditingController();
  final _lastNameCtrl       = TextEditingController();
  final _primaryEmailCtrl   = TextEditingController();
  final _secondaryEmailCtrl = TextEditingController();
  String _countryCode          = '+91';
  final _primaryPhoneCtrl      = TextEditingController();
  String _secondaryCountryCode = '+91';
  final _secondaryPhoneCtrl    = TextEditingController();
  DateTime? _dob;

  // ── Step 2: Location ──────────────────────────────────────────────────────
  final _address1Ctrl = TextEditingController();
  final _address2Ctrl = TextEditingController();
  String _country     = 'India';
  String? _state;
  final _cityCtrl     = TextEditingController();

  // ── Step 3: Professional Details ──────────────────────────────────────────
  final _companyCtrl  = TextEditingController();
  final _jobTitleCtrl = TextEditingController();
  String? _industry;
  final _businessBioCtrl = TextEditingController();
  final _businessWebCtrl = TextEditingController();
  String _yiVertical  = 'none';
  String _yiPosition  = 'none';
  final _memberSinceYearCtrl = TextEditingController();

  // ── Step 4: Social Media ─────────────────────────────────────────────────
  final _linkedinCtrl  = TextEditingController();
  final _instagramCtrl = TextEditingController();
  final _twitterCtrl   = TextEditingController();
  final _facebookCtrl  = TextEditingController();

  // ── Step 5: Personal & Tags ───────────────────────────────────────────────
  final _personalBioCtrl   = TextEditingController();
  final _spouseCtrl        = TextEditingController();
  String? _relationshipStatus;
  bool _isSpouseYiMember   = false;
  DateTime? _anniversaryDate;
  String? _bloodGroup;
  final Set<String> _businessTags = {};
  final Set<String> _hobbyTags    = {};
  final _customBusinessTag = TextEditingController();
  final _customHobbyTag    = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Pre-fill primary phone from auth (read-only — auth phone is the login identity)
    final authPhone = Supabase.instance.client.auth.currentUser?.phone ?? '';
    // Strip country code prefix for display in the number field
    if (authPhone.startsWith('+91')) {
      _countryCode = '+91';
      _primaryPhoneCtrl.text = authPhone.substring(3);
    } else if (authPhone.startsWith('+')) {
      final spaceIdx = authPhone.indexOf(RegExp(r'\d'));
      _primaryPhoneCtrl.text = authPhone.substring(spaceIdx > 0 ? spaceIdx : 1);
    } else {
      _primaryPhoneCtrl.text = authPhone;
    }
  }

  @override
  void dispose() {
    for (final c in [
      _firstNameCtrl, _lastNameCtrl, _primaryEmailCtrl, _secondaryEmailCtrl,
      _primaryPhoneCtrl, _secondaryPhoneCtrl,
      _address1Ctrl, _address2Ctrl, _cityCtrl,
      _companyCtrl, _jobTitleCtrl, _businessBioCtrl, _businessWebCtrl,
      _memberSinceYearCtrl,
      _linkedinCtrl, _instagramCtrl, _twitterCtrl, _facebookCtrl,
      _personalBioCtrl, _spouseCtrl,
      _customBusinessTag, _customHobbyTag,
    ]) { c.dispose(); }
    _pageController.dispose();
    super.dispose();
  }

  String? _validateStep() {
    switch (_currentPage) {
      case 0:
        if (_firstNameCtrl.text.trim().isEmpty) return 'First name is required';
        if (_lastNameCtrl.text.trim().isEmpty)  return 'Last name is required';
        if (_primaryEmailCtrl.text.trim().isEmpty) return 'Primary email is required';
        if (_dob == null) return 'Date of birth is required';
        return null;
      case 1:
        if (_address1Ctrl.text.trim().isEmpty) return 'Address line 1 is required';
        if (_country == 'India' && (_state == null || _state!.isEmpty)) return 'State is required';
        if (_cityCtrl.text.trim().isEmpty) return 'City is required';
        return null;
      case 2:
        if (_companyCtrl.text.trim().isEmpty) return 'Company name is required (write "NA" if not applicable)';
        if (_jobTitleCtrl.text.trim().isEmpty) return 'Job title is required (write "NA" if not applicable)';
        if (_memberSinceYearCtrl.text.trim().isEmpty) return 'YI Kanpur joining year is required';
        if (int.tryParse(_memberSinceYearCtrl.text.trim()) == null) return 'Joining year must be a valid number';
        if (_yiVertical != 'none' && _yiPosition == 'none') return 'Please select your YI position';
        return null;
      case 3:
        return null; // social media all optional
      case 4:
        if (_relationshipStatus == null) return 'Relationship status is required';
        if (_relationshipStatus == 'married') {
          if (_spouseCtrl.text.trim().isEmpty) return 'Spouse name is required';
          if (_anniversaryDate == null) return 'Anniversary date is required';
        }
        return null;
      default:
        return null;
    }
  }

  void _next() {
    final error = _validateStep();
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    if (_currentPage < 4) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _submit();
    }
  }

  void _back() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final img = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (img != null) setState(() => _photoFile = File(img.path));
  }

  Future<DateTime?> _pickDate({DateTime? initialDate, DateTime? lastDate}) async {
    return showDatePicker(
      context: context,
      initialDate: initialDate ?? DateTime(1995, 1, 1),
      firstDate: DateTime(1940),
      lastDate: lastDate ?? DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.dark(primary: AppColors.green),
        ),
        child: child!,
      ),
    );
  }

  Future<void> _submit() async {
    setState(() => _saving = true);
    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser!.id;

      String? headshotUrl;
      if (_photoFile != null) {
        final path = '$userId/avatar.jpg';
        await supabase.storage.from('avatars').upload(
          path, _photoFile!,
          fileOptions: const FileOptions(upsert: true, contentType: 'image/jpeg'),
        );
        headshotUrl = supabase.storage.from('avatars').getPublicUrl(path);
      }

      await supabase.from('profiles').upsert({
        'id': userId,
        'first_name':         _firstNameCtrl.text.trim(),
        'last_name':          _lastNameCtrl.text.trim(),
        'primary_email':      _primaryEmailCtrl.text.trim().isEmpty ? null : _primaryEmailCtrl.text.trim(),
        'secondary_email':    _secondaryEmailCtrl.text.trim().isEmpty ? null : _secondaryEmailCtrl.text.trim(),
        'phone_country_code':           _countryCode,
        'secondary_phone_country_code': _secondaryCountryCode,
        'secondary_phone':              _secondaryPhoneCtrl.text.trim().isEmpty ? null : _secondaryPhoneCtrl.text.trim(),
        'dob':                _dob?.toIso8601String().substring(0, 10),
        if (headshotUrl != null) 'headshot_url': headshotUrl,
        'address_line1':      _address1Ctrl.text.trim().isEmpty ? null : _address1Ctrl.text.trim(),
        'address_line2':      _address2Ctrl.text.trim().isEmpty ? null : _address2Ctrl.text.trim(),
        'country':            _country,
        'state':              _state,
        'city':               _cityCtrl.text.trim().isEmpty ? null : _cityCtrl.text.trim(),
        'company_name':       _companyCtrl.text.trim().isEmpty ? null : _companyCtrl.text.trim(),
        'job_title':          _jobTitleCtrl.text.trim().isEmpty ? null : _jobTitleCtrl.text.trim(),
        'industry':           _industry,
        'business_bio':       _businessBioCtrl.text.trim().isEmpty ? null : _businessBioCtrl.text.trim(),
        'business_website':   _businessWebCtrl.text.trim().isEmpty ? null : _businessWebCtrl.text.trim(),
        'yi_vertical':        _yiVertical,
        'yi_position':        _yiVertical == 'none' ? 'none' : _yiPosition,
        'yi_member_since':    int.tryParse(_memberSinceYearCtrl.text.trim()),
        'linkedin_url':       _linkedinCtrl.text.trim().isEmpty ? null : _linkedinCtrl.text.trim(),
        'instagram_url':      _instagramCtrl.text.trim().isEmpty ? null : _instagramCtrl.text.trim(),
        'twitter_url':        _twitterCtrl.text.trim().isEmpty ? null : _twitterCtrl.text.trim(),
        'facebook_url':       _facebookCtrl.text.trim().isEmpty ? null : _facebookCtrl.text.trim(),
        'personal_bio':        _personalBioCtrl.text.trim().isEmpty ? null : _personalBioCtrl.text.trim(),
        'relationship_status': _relationshipStatus,
        'spouse_name':         _relationshipStatus == 'married'
            ? (_spouseCtrl.text.trim().isEmpty ? null : _spouseCtrl.text.trim())
            : null,
        'is_spouse_yi_member': _relationshipStatus == 'married' ? _isSpouseYiMember : null,
        'anniversary_date':    _relationshipStatus == 'married'
            ? _anniversaryDate?.toIso8601String().substring(0, 10)
            : null,
        'blood_group':         _bloodGroup,
        'business_tags':      _businessTags.toList(),
        'hobby_tags':         _hobbyTags.toList(),
        'onboarding_done':    true,
      }, onConflict: 'id');

      if (mounted) context.go('/events');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const stepTitles = [
      'Identity & Contact',
      'Location',
      'Professional Details',
      'Social Media',
      'Personal & Tags',
    ];

    return Scaffold(
      backgroundColor: AppColors.black,
      appBar: AppBar(
        backgroundColor: AppColors.black,
        automaticallyImplyLeading: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Step ${_currentPage + 1} of 5  •  ${stepTitles[_currentPage]}',
              style: const TextStyle(fontSize: 14, color: AppColors.textMuted),
            ),
            const SizedBox(height: 6),
            LinearProgressIndicator(
              value: (_currentPage + 1) / 5,
              backgroundColor: AppColors.surfaceAlt,
              color: AppColors.green,
            ),
          ],
        ),
      ),
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        onPageChanged: (p) => setState(() => _currentPage = p),
        children: [
          _buildStep1(),
          _buildStep2(),
          _buildStep3(),
          _buildStep4(),
          _buildStep5(),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Row(
            children: [
              if (_currentPage > 0)
                Expanded(
                  child: OutlinedButton(
                    onPressed: _saving ? null : _back,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.border),
                      foregroundColor: AppColors.white,
                    ),
                    child: const Text('Back'),
                  ),
                ),
              if (_currentPage > 0) const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: _saving ? null : _next,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.green,
                    foregroundColor: AppColors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 20, height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2, color: AppColors.black,
                          ),
                        )
                      : Text(
                          _currentPage == 4 ? 'Complete Profile' : 'Continue',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // STEP 1 — Identity & Contact
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildStep1() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: GestureDetector(
              onTap: _pickPhoto,
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 52,
                    backgroundColor: AppColors.surfaceAlt,
                    backgroundImage: _photoFile != null ? FileImage(_photoFile!) as ImageProvider : null,
                    child: _photoFile == null
                        ? const Icon(Icons.person, size: 52, color: AppColors.textMuted)
                        : null,
                  ),
                  Positioned(
                    bottom: 0, right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.green,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.black, width: 2),
                      ),
                      child: const Icon(Icons.camera_alt, size: 16, color: AppColors.black),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(children: [
            Expanded(child: _field('First Name *', _firstNameCtrl)),
            const SizedBox(width: 12),
            Expanded(child: _field('Last Name *', _lastNameCtrl)),
          ]),
          const SizedBox(height: 16),
          _field('Primary Email *', _primaryEmailCtrl, keyboard: TextInputType.emailAddress),
          const SizedBox(height: 16),
          _field('Secondary Email', _secondaryEmailCtrl, keyboard: TextInputType.emailAddress),
          const SizedBox(height: 16),
          _fieldLabel('Primary Phone (WhatsApp)'),
          const SizedBox(height: 6),
          IntrinsicHeight(
            child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              _countryCodePicker(
                value: _countryCode,
                onChanged: null, // read-only
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildTextField(_primaryPhoneCtrl,
                  keyboard: TextInputType.phone,
                  hint: 'Phone number',
                  readOnly: true),
              ),
            ]),
          ),
          const SizedBox(height: 4),
          Text(
            'Phone number linked to your account. You can change it later in Edit Profile.',
            style: TextStyle(fontSize: 11, color: AppColors.textMuted),
          ),
          const SizedBox(height: 16),
          _fieldLabel('Secondary Phone'),
          const SizedBox(height: 6),
          IntrinsicHeight(
            child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              _countryCodePicker(
                value: _secondaryCountryCode,
                onChanged: (v) => setState(() => _secondaryCountryCode = v),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildTextField(_secondaryPhoneCtrl,
                  keyboard: TextInputType.phone, hint: 'Phone number'),
              ),
            ]),
          ),
          const SizedBox(height: 16),
          _fieldLabel('Date of Birth *'),
          const SizedBox(height: 6),
          _dateTile(
            value: _dob,
            hint: 'Select date of birth',
            onTap: () async {
              final d = await _pickDate(
                lastDate: DateTime.now().subtract(const Duration(days: 365 * 16)),
              );
              if (d != null) setState(() => _dob = d);
            },
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // STEP 2 — Location
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildStep2() {
    final isIndia = _country == 'India';
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _field('Address Line 1 *', _address1Ctrl, hint: 'Street / Building'),
          const SizedBox(height: 16),
          _field('Address Line 2', _address2Ctrl, hint: 'Apartment / Area (optional)'),
          const SizedBox(height: 16),
          _fieldLabel('Country *'),
          const SizedBox(height: 6),
          _buildDropdown<String>(
            value: _country,
            items: AppConstants.countries,
            itemLabel: (v) => v,
            onChanged: (v) => setState(() { _country = v; _state = null; }),
          ),
          const SizedBox(height: 16),
          _fieldLabel(isIndia ? 'State *' : 'State / Province'),
          const SizedBox(height: 6),
          if (isIndia)
            _buildDropdown<String>(
              value: _state,
              placeholder: 'Select state',
              items: AppConstants.indianStates,
              itemLabel: (v) => v,
              onChanged: (v) => setState(() => _state = v),
            )
          else
            _buildTextField(
              TextEditingController(text: _state),
              hint: 'State / Province',
              onChanged: (v) => setState(() => _state = v),
            ),
          const SizedBox(height: 16),
          _field('City *', _cityCtrl, hint: 'City / Town'),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // STEP 3 — Professional Details
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildStep3() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _fieldLabel('Company Name *'),
          const SizedBox(height: 4),
          const Text(
            'Mention "NA" in case you do not run a business / brand',
            style: TextStyle(color: AppColors.textMuted, fontSize: 11),
          ),
          const SizedBox(height: 6),
          _buildTextField(_companyCtrl, hint: 'Your company or brand name'),
          const SizedBox(height: 16),
          _fieldLabel('Job Title *'),
          const SizedBox(height: 4),
          const Text(
            'Mention "NA" in case you do not own a business',
            style: TextStyle(color: AppColors.textMuted, fontSize: 11),
          ),
          const SizedBox(height: 6),
          _buildTextField(_jobTitleCtrl, hint: 'e.g. CEO, Engineer, Consultant'),
          const SizedBox(height: 16),
          _fieldLabel('Industry'),
          const SizedBox(height: 6),
          _buildDropdown<String>(
            value: _industry,
            placeholder: 'Select industry (optional)',
            items: AppConstants.industries.where((i) => i != 'N/A').toList(),
            itemLabel: (v) => v,
            onChanged: (v) => setState(() => _industry = v),
          ),
          const SizedBox(height: 16),
          _fieldLabel('Business Bio'),
          const SizedBox(height: 6),
          _buildTextField(_businessBioCtrl,
            hint: 'Brief description of your business / work', maxLines: 3),
          const SizedBox(height: 16),
          _field('Business Website', _businessWebCtrl,
              hint: 'https://example.com', keyboard: TextInputType.url),
          const SizedBox(height: 16),
          _fieldLabel('YI Vertical *'),
          const SizedBox(height: 6),
          _buildDropdown<Map<String, String>>(
            value: AppConstants.yiVerticals.firstWhere((v) => v['value'] == _yiVertical),
            items: AppConstants.yiVerticals,
            itemLabel: (v) => v['label']!,
            onChanged: (v) => setState(() {
              _yiVertical = v['value']!;
              if (_yiVertical == 'none') _yiPosition = 'none';
            }),
          ),
          if (_yiVertical != 'none') ...[
            const SizedBox(height: 16),
            _fieldLabel('YI Position *'),
            const SizedBox(height: 6),
            _buildDropdown<Map<String, String>>(
              value: AppConstants.yiPositions.firstWhere((p) => p['value'] == _yiPosition),
              items: AppConstants.yiPositions,
              itemLabel: (v) => v['label']!,
              onChanged: (v) => setState(() => _yiPosition = v['value']!),
            ),
          ],
          const SizedBox(height: 16),
          _field('YI Kanpur Joining Year *', _memberSinceYearCtrl,
            hint: 'e.g. 2023', keyboard: TextInputType.number),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // STEP 4 — Social Media
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildStep4() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Add your social profiles to help members connect with you.',
            style: TextStyle(color: AppColors.textMuted, fontSize: 14),
          ),
          const SizedBox(height: 24),
          _socialField(Icons.work_outline, 'LinkedIn', _linkedinCtrl,
              hint: 'linkedin.com/in/yourprofile'),
          const SizedBox(height: 16),
          _socialField(Icons.camera_alt_outlined, 'Instagram', _instagramCtrl,
              hint: 'instagram.com/yourhandle'),
          const SizedBox(height: 16),
          _socialField(Icons.alternate_email, 'X (Twitter)', _twitterCtrl,
              hint: 'x.com/yourhandle'),
          const SizedBox(height: 16),
          _socialField(Icons.facebook_outlined, 'Facebook', _facebookCtrl,
              hint: 'facebook.com/yourprofile'),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // STEP 5 — Personal & Tags
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildStep5() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _fieldLabel('Personal Bio'),
          const SizedBox(height: 6),
          _buildTextField(_personalBioCtrl,
            hint: 'Tell the YI community about yourself…', maxLines: 4),
          const SizedBox(height: 16),
          _fieldLabel('Relationship Status *'),
          const SizedBox(height: 8),
          _radioGroup<String>(
            value: _relationshipStatus,
            options: const [
              ('married', 'Married'),
              ('single',  'Single (for now)'),
            ],
            onChanged: (v) => setState(() {
              _relationshipStatus = v;
              if (v != 'married') {
                _spouseCtrl.clear();
                _isSpouseYiMember = false;
                _anniversaryDate = null;
              }
            }),
          ),
          if (_relationshipStatus == 'married') ...[
            const SizedBox(height: 16),
            _field('Spouse Name *', _spouseCtrl, hint: 'Full name'),
            const SizedBox(height: 16),
            _fieldLabel('Is Spouse a YI Member?'),
            const SizedBox(height: 8),
            _radioGroup<bool>(
              value: _isSpouseYiMember,
              options: const [(true, 'Yes'), (false, 'No')],
              onChanged: (v) => setState(() => _isSpouseYiMember = v),
            ),
            const SizedBox(height: 16),
            _fieldLabel('Anniversary Date *'),
            const SizedBox(height: 6),
            _dateTile(
              value: _anniversaryDate,
              hint: 'Select anniversary date',
              onTap: () async {
                final d = await showDatePicker(
                  context: context,
                  initialDate: _anniversaryDate ?? DateTime(2015, 1, 1),
                  firstDate: DateTime(1950),
                  lastDate: DateTime.now(),
                  builder: (ctx, child) => Theme(
                    data: Theme.of(ctx).copyWith(
                      colorScheme: const ColorScheme.dark(primary: AppColors.green),
                    ),
                    child: child!,
                  ),
                );
                if (d != null) setState(() => _anniversaryDate = d);
              },
            ),
          ],
          const SizedBox(height: 16),
          _fieldLabel('Blood Group'),
          const SizedBox(height: 6),
          _buildDropdown<String>(
            value: _bloodGroup,
            placeholder: 'Select blood group',
            items: AppConstants.bloodGroups,
            itemLabel: (v) => v,
            onChanged: (v) => setState(() => _bloodGroup = v),
          ),
          const SizedBox(height: 24),
          _tagSection(
            title: 'Business Tags (up to 4)',
            predefined: AppConstants.businessTags,
            selected: _businessTags,
            customCtrl: _customBusinessTag,
            onToggle: (tag) => setState(() {
              if (_businessTags.contains(tag)) {
                _businessTags.remove(tag);
              } else if (_businessTags.length < 4) {
                _businessTags.add(tag);
              }
            }),
            onAddCustom: () {
              final tag = _customBusinessTag.text.trim();
              if (tag.isNotEmpty && _businessTags.length < 4) {
                setState(() { _businessTags.add(tag); _customBusinessTag.clear(); });
              }
            },
          ),
          const SizedBox(height: 24),
          _tagSection(
            title: 'Hobby Tags (up to 4)',
            predefined: AppConstants.hobbyTags,
            selected: _hobbyTags,
            customCtrl: _customHobbyTag,
            onToggle: (tag) => setState(() {
              if (_hobbyTags.contains(tag)) {
                _hobbyTags.remove(tag);
              } else if (_hobbyTags.length < 4) {
                _hobbyTags.add(tag);
              }
            }),
            onAddCustom: () {
              final tag = _customHobbyTag.text.trim();
              if (tag.isNotEmpty && _hobbyTags.length < 4) {
                setState(() { _hobbyTags.add(tag); _customHobbyTag.clear(); });
              }
            },
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // WIDGET HELPERS
  // ══════════════════════════════════════════════════════════════════════════

  Widget _fieldLabel(String text) => Text(
    text,
    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textMuted),
  );

  Widget _field(String label, TextEditingController ctrl, {
    String? hint, TextInputType? keyboard, int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel(label),
        const SizedBox(height: 6),
        _buildTextField(ctrl, hint: hint ?? label, keyboard: keyboard, maxLines: maxLines),
      ],
    );
  }

  Widget _buildTextField(TextEditingController ctrl, {
    String hint = '',
    TextInputType? keyboard,
    int maxLines = 1,
    ValueChanged<String>? onChanged,
    bool readOnly = false,
  }) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboard,
      maxLines: maxLines,
      onChanged: onChanged,
      readOnly: readOnly,
      style: TextStyle(color: readOnly ? AppColors.textMuted : AppColors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.textMuted),
        filled: true,
        fillColor: readOnly ? AppColors.surfaceAlt : AppColors.card,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.green),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );
  }

  Widget _countryCodePicker({required String value, ValueChanged<String>? onChanged}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: onChanged == null ? AppColors.surfaceAlt : AppColors.card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          dropdownColor: AppColors.card,
          style: TextStyle(color: onChanged == null ? AppColors.textMuted : AppColors.white, fontSize: 14),
          items: AppConstants.countryCodes.map((c) => DropdownMenuItem<String>(
            value: c['code'],
            child: Text('${c['flag']} ${c['code']}'),
          )).toList(),
          onChanged: onChanged == null ? null : (v) { if (v != null) onChanged(v); },
        ),
      ),
    );
  }

  Widget _buildDropdown<T>({
    required T? value,
    String? placeholder,
    required List<T> items,
    required String Function(T) itemLabel,
    required ValueChanged<T> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          dropdownColor: AppColors.card,
          style: const TextStyle(color: AppColors.white, fontSize: 15),
          hint: Text(placeholder ?? 'Select',
              style: const TextStyle(color: AppColors.textMuted)),
          items: items.map((item) => DropdownMenuItem<T>(
            value: item,
            child: Text(itemLabel(item)),
          )).toList(),
          onChanged: (v) { if (v != null) onChanged(v); },
        ),
      ),
    );
  }

  Widget _dateTile({required DateTime? value, required String hint, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                value == null ? hint : DateFormat('dd MMM yyyy').format(value),
                style: TextStyle(
                  color: value == null ? AppColors.textMuted : AppColors.white,
                  fontSize: 15,
                ),
              ),
            ),
            const Icon(Icons.calendar_today_outlined, size: 18, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }

  Widget _socialField(IconData icon, String label, TextEditingController ctrl,
      {required String hint}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Icon(icon, size: 16, color: AppColors.textMuted),
          const SizedBox(width: 6),
          _fieldLabel(label),
        ]),
        const SizedBox(height: 6),
        _buildTextField(ctrl, hint: hint, keyboard: TextInputType.url),
      ],
    );
  }

  Widget _radioGroup<T>({
    required T? value,
    required List<(T, String)> options,
    required ValueChanged<T> onChanged,
  }) {
    return Column(
      children: options.map((opt) {
        final (optValue, optLabel) = opt;
        final selected = value == optValue;
        return GestureDetector(
          onTap: () => onChanged(optValue),
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: selected ? AppColors.green.withOpacity(0.08) : AppColors.card,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: selected ? AppColors.green : AppColors.border,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 18, height: 18,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: selected ? AppColors.green : AppColors.textMuted,
                      width: 2,
                    ),
                  ),
                  child: selected
                    ? Center(
                        child: Container(
                          width: 8, height: 8,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.green,
                          ),
                        ),
                      )
                    : null,
                ),
                const SizedBox(width: 12),
                Text(optLabel, style: TextStyle(
                  color: selected ? AppColors.white : AppColors.textMuted,
                  fontSize: 15,
                )),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _tagSection({
    required String title,
    required List<String> predefined,
    required Set<String> selected,
    required TextEditingController customCtrl,
    required void Function(String) onToggle,
    required VoidCallback onAddCustom,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          _fieldLabel(title),
          const Spacer(),
          Text('${selected.length}/4',
              style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
        ]),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8, runSpacing: 8,
          children: predefined.map((tag) {
            final isSelected = selected.contains(tag);
            return GestureDetector(
              onTap: () => onToggle(tag),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.green.withOpacity(0.15) : AppColors.card,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? AppColors.green : AppColors.border,
                  ),
                ),
                child: Text(
                  tag,
                  style: TextStyle(
                    fontSize: 13,
                    color: isSelected ? AppColors.green : AppColors.textMuted,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
            );
          }).toList(),
        ),

        if (selected.length < 4) ...[
          const SizedBox(height: 10),
          Row(children: [
            Expanded(
              child: TextField(
                controller: customCtrl,
                style: const TextStyle(color: AppColors.white, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Add custom tag…',
                  hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                  filled: true, fillColor: AppColors.card,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: const BorderSide(color: AppColors.green),
                  ),
                ),
                onSubmitted: (_) => onAddCustom(),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: onAddCustom,
              icon: const Icon(Icons.add_circle, color: AppColors.green),
            ),
          ]),
        ],

        if (selected.any((t) => !predefined.contains(t))) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: selected
                .where((t) => !predefined.contains(t))
                .map((tag) => Chip(
                      label: Text(tag,
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.green)),
                      backgroundColor: AppColors.green.withOpacity(0.1),
                      side: const BorderSide(color: AppColors.green),
                      deleteIconColor: AppColors.green,
                      onDeleted: () => setState(() => selected.remove(tag)),
                    ))
                .toList(),
          ),
        ],
      ],
    );
  }
}
