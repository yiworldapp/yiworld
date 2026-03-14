import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _supabase = Supabase.instance.client;
  final _picker   = ImagePicker();
  bool _loading   = true;
  bool _saving    = false;
  File? _newHeadshot;
  String? _existingHeadshotUrl;

  // ── Identity & Contact ────────────────────────────────────────────────────
  final _firstNameCtrl      = TextEditingController();
  final _lastNameCtrl       = TextEditingController();
  final _primaryEmailCtrl   = TextEditingController();
  final _secondaryEmailCtrl = TextEditingController();
  String _countryCode          = '+91';
  final _primaryPhoneCtrl      = TextEditingController();
  String _secondaryCountryCode = '+91';
  final _secondaryPhoneCtrl    = TextEditingController();
  DateTime? _dob;

  // ── Location ──────────────────────────────────────────────────────────────
  final _address1Ctrl = TextEditingController();
  final _address2Ctrl = TextEditingController();
  String _country     = 'India';
  String? _state;
  final _cityCtrl     = TextEditingController();

  // ── Professional ──────────────────────────────────────────────────────────
  final _companyCtrl     = TextEditingController();
  final _jobTitleCtrl    = TextEditingController();
  String? _industry;
  final _businessBioCtrl = TextEditingController();
  final _businessWebCtrl = TextEditingController();
  String _yiVertical     = 'none';
  String _yiPosition     = 'none';
  final _memberSinceYearCtrl = TextEditingController();

  // ── Social ────────────────────────────────────────────────────────────────
  final _linkedinCtrl  = TextEditingController();
  final _instagramCtrl = TextEditingController();
  final _twitterCtrl   = TextEditingController();
  final _facebookCtrl  = TextEditingController();

  // ── Personal & Tags ───────────────────────────────────────────────────────
  final _personalBioCtrl = TextEditingController();
  String? _relationshipStatus;
  bool _isSpouseYiMember  = false;
  DateTime? _anniversaryDate;
  final _spouseCtrl       = TextEditingController();
  String? _bloodGroup;
  final Set<String> _businessTags = {};
  final Set<String> _hobbyTags    = {};
  final _customBusinessTag = TextEditingController();
  final _customHobbyTag    = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProfile();
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
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final data = await _supabase
        .from('profiles').select('*')
        .eq('id', _supabase.auth.currentUser!.id).single();

    setState(() {
      _existingHeadshotUrl = data['headshot_url'] as String?;
      _firstNameCtrl.text      = data['first_name']      ?? '';
      _lastNameCtrl.text       = data['last_name']       ?? '';
      _primaryEmailCtrl.text   = data['primary_email']   ?? '';
      _secondaryEmailCtrl.text = data['secondary_email'] ?? '';
      _countryCode             = data['phone_country_code']           ?? '+91';
      _primaryPhoneCtrl.text   = data['phone']                        ?? '';
      _secondaryCountryCode    = data['secondary_phone_country_code'] ?? '+91';
      _secondaryPhoneCtrl.text = data['secondary_phone']              ?? '';
      _dob = data['dob'] != null ? DateTime.tryParse(data['dob'] as String) : null;

      _address1Ctrl.text = data['address_line1'] ?? '';
      _address2Ctrl.text = data['address_line2'] ?? '';
      _country           = data['country']       ?? 'India';
      _state             = data['state']         as String?;
      _cityCtrl.text     = data['city']          ?? '';

      _companyCtrl.text     = data['company_name']     ?? '';
      _jobTitleCtrl.text    = data['job_title']        ?? '';
      _industry             = data['industry']         as String?;
      _businessBioCtrl.text = data['business_bio']     ?? '';
      _businessWebCtrl.text = data['business_website'] ?? '';
      _yiVertical           = data['yi_vertical']      ?? 'none';
      _yiPosition           = data['yi_position']      ?? 'none';
      final sinceYear = data['yi_member_since'];
      _memberSinceYearCtrl.text = sinceYear != null ? sinceYear.toString() : '';

      _linkedinCtrl.text  = data['linkedin_url']  ?? '';
      _instagramCtrl.text = data['instagram_url'] ?? '';
      _twitterCtrl.text   = data['twitter_url']   ?? '';
      _facebookCtrl.text  = data['facebook_url']  ?? '';

      _personalBioCtrl.text  = data['personal_bio']  ?? '';
      _relationshipStatus    = data['relationship_status'] as String?;
      _isSpouseYiMember      = data['is_spouse_yi_member'] as bool? ?? false;
      _anniversaryDate       = data['anniversary_date'] != null
          ? DateTime.tryParse(data['anniversary_date'] as String) : null;
      _spouseCtrl.text       = data['spouse_name'] ?? '';
      _bloodGroup            = data['blood_group']  as String?;

      final bt = data['business_tags'] as List?;
      final ht = data['hobby_tags']    as List?;
      if (bt != null) _businessTags.addAll(bt.cast<String>());
      if (ht != null) _hobbyTags.addAll(ht.cast<String>());

      _loading = false;
    });
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      String? headshotUrl = _existingHeadshotUrl;
      if (_newHeadshot != null) {
        final userId = _supabase.auth.currentUser!.id;
        final path   = '$userId/avatar.jpg';
        await _supabase.storage.from('avatars').upload(
          path, _newHeadshot!,
          fileOptions: const FileOptions(upsert: true, contentType: 'image/jpeg'),
        );
        headshotUrl = _supabase.storage.from('avatars').getPublicUrl(path);
      }

      await _supabase.from('profiles').update({
        'first_name':          _firstNameCtrl.text.trim().isEmpty      ? null : _firstNameCtrl.text.trim(),
        'last_name':           _lastNameCtrl.text.trim().isEmpty        ? null : _lastNameCtrl.text.trim(),
        'primary_email':       _primaryEmailCtrl.text.trim().isEmpty    ? null : _primaryEmailCtrl.text.trim(),
        'secondary_email':     _secondaryEmailCtrl.text.trim().isEmpty  ? null : _secondaryEmailCtrl.text.trim(),
        'phone_country_code':           _countryCode,
        'secondary_phone_country_code': _secondaryCountryCode,
        'secondary_phone':              _secondaryPhoneCtrl.text.trim().isEmpty ? null : _secondaryPhoneCtrl.text.trim(),
        'dob':                 _dob?.toIso8601String().substring(0, 10),
        if (headshotUrl != null) 'headshot_url': headshotUrl,
        'address_line1':       _address1Ctrl.text.trim().isEmpty        ? null : _address1Ctrl.text.trim(),
        'address_line2':       _address2Ctrl.text.trim().isEmpty        ? null : _address2Ctrl.text.trim(),
        'country':             _country,
        'state':               _state,
        'city':                _cityCtrl.text.trim().isEmpty            ? null : _cityCtrl.text.trim(),
        'company_name':        _companyCtrl.text.trim().isEmpty         ? null : _companyCtrl.text.trim(),
        'job_title':           _jobTitleCtrl.text.trim().isEmpty        ? null : _jobTitleCtrl.text.trim(),
        'industry':            _industry,
        'business_bio':        _businessBioCtrl.text.trim().isEmpty     ? null : _businessBioCtrl.text.trim(),
        'business_website':    _businessWebCtrl.text.trim().isEmpty     ? null : _businessWebCtrl.text.trim(),
        'yi_vertical':         _yiVertical,
        'yi_position':         _yiVertical == 'none' ? 'none' : _yiPosition,
        'yi_member_since':     int.tryParse(_memberSinceYearCtrl.text.trim()),
        'linkedin_url':        _linkedinCtrl.text.trim().isEmpty        ? null : _linkedinCtrl.text.trim(),
        'instagram_url':       _instagramCtrl.text.trim().isEmpty       ? null : _instagramCtrl.text.trim(),
        'twitter_url':         _twitterCtrl.text.trim().isEmpty         ? null : _twitterCtrl.text.trim(),
        'facebook_url':        _facebookCtrl.text.trim().isEmpty        ? null : _facebookCtrl.text.trim(),
        'personal_bio':        _personalBioCtrl.text.trim().isEmpty     ? null : _personalBioCtrl.text.trim(),
        'relationship_status': _relationshipStatus,
        'spouse_name':         _relationshipStatus == 'married'
            ? (_spouseCtrl.text.trim().isEmpty ? null : _spouseCtrl.text.trim()) : null,
        'is_spouse_yi_member': _relationshipStatus == 'married' ? _isSpouseYiMember : null,
        'anniversary_date':    _relationshipStatus == 'married'
            ? _anniversaryDate?.toIso8601String().substring(0, 10) : null,
        'blood_group':         _bloodGroup,
        'business_tags':       _businessTags.toList(),
        'hobby_tags':          _hobbyTags.toList(),
      }).eq('id', _supabase.auth.currentUser!.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated!')),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: AppColors.black,
        body: Center(child: CircularProgressIndicator(color: AppColors.green)),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.black,
      appBar: AppBar(
        title: const Text('Edit Profile'),
        backgroundColor: AppColors.black,
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(width: 18, height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.green))
                : const Text('Save',
                    style: TextStyle(color: AppColors.green, fontWeight: FontWeight.w600, fontSize: 16)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Avatar ─────────────────────────────────────────────────────
            Center(
              child: GestureDetector(
                onTap: () async {
                  final file = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
                  if (file != null) setState(() => _newHeadshot = File(file.path));
                },
                child: Stack(
                  children: [
                    Container(
                      width: 90, height: 90,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.green, width: 2),
                      ),
                      child: ClipOval(
                        child: _newHeadshot != null
                            ? Image.file(_newHeadshot!, fit: BoxFit.cover)
                            : _existingHeadshotUrl != null
                                ? Image.network(_existingHeadshotUrl!, fit: BoxFit.cover)
                                : Container(
                                    color: AppColors.surfaceAlt,
                                    child: Center(
                                      child: Text(
                                        _firstNameCtrl.text.isNotEmpty ? _firstNameCtrl.text[0].toUpperCase() : '?',
                                        style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.green),
                                      ),
                                    ),
                                  ),
                      ),
                    ),
                    Positioned(
                      bottom: 0, right: 0,
                      child: Container(
                        width: 28, height: 28,
                        decoration: BoxDecoration(
                          color: AppColors.green, shape: BoxShape.circle,
                          border: Border.all(color: AppColors.black, width: 2),
                        ),
                        child: const Icon(Icons.camera_alt, size: 14, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 28),

            // ── Identity & Contact ─────────────────────────────────────────
            _sectionHeader('Identity & Contact'),
            Row(children: [
              Expanded(child: _field('First Name *', _firstNameCtrl)),
              const SizedBox(width: 12),
              Expanded(child: _field('Last Name *', _lastNameCtrl)),
            ]),
            _field('Primary Email', _primaryEmailCtrl, type: TextInputType.emailAddress),
            _field('Secondary Email', _secondaryEmailCtrl, type: TextInputType.emailAddress),
            _label('Primary Phone (WhatsApp)'),
            const SizedBox(height: 6),
            IntrinsicHeight(
              child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                _countryCodePicker(
                  value: _countryCode,
                  onChanged: (v) => setState(() => _countryCode = v),
                ),
                const SizedBox(width: 8),
                Expanded(child: _textField(_primaryPhoneCtrl, hint: 'Phone number', type: TextInputType.phone)),
              ]),
            ),
            const SizedBox(height: 16),
            _label('Secondary Phone'),
            const SizedBox(height: 6),
            IntrinsicHeight(
              child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                _countryCodePicker(
                  value: _secondaryCountryCode,
                  onChanged: (v) => setState(() => _secondaryCountryCode = v),
                ),
                const SizedBox(width: 8),
                Expanded(child: _textField(_secondaryPhoneCtrl, hint: 'Phone number', type: TextInputType.phone)),
              ]),
            ),
            const SizedBox(height: 16),
            _label('Date of Birth'),
            const SizedBox(height: 6),
            _dateTile(
              value: _dob,
              hint: 'Select date of birth',
              onTap: () async {
                final d = await _pickDate(lastDate: DateTime.now().subtract(const Duration(days: 365 * 16)));
                if (d != null) setState(() => _dob = d);
              },
            ),
            const SizedBox(height: 16),

            // ── Location ───────────────────────────────────────────────────
            _sectionHeader('Location'),
            _field('Address Line 1', _address1Ctrl, hint: 'Street / Building'),
            _field('Address Line 2', _address2Ctrl, hint: 'Apartment / Area'),
            _label('Country *'),
            const SizedBox(height: 6),
            _dropdown<String>(
              value: _country,
              items: AppConstants.countries,
              label: (v) => v,
              onChanged: (v) => setState(() { _country = v; _state = null; }),
            ),
            const SizedBox(height: 16),
            _label(_country == 'India' ? 'State *' : 'State / Province'),
            const SizedBox(height: 6),
            if (_country == 'India')
              _dropdown<String>(
                value: _state,
                placeholder: 'Select state',
                items: AppConstants.indianStates,
                label: (v) => v,
                onChanged: (v) => setState(() => _state = v),
              )
            else
              _textField(
                TextEditingController(text: _state),
                hint: 'State / Province',
                onChanged: (v) => setState(() => _state = v),
              ),
            const SizedBox(height: 16),
            _field('City', _cityCtrl, hint: 'City / Town'),

            // ── Professional ───────────────────────────────────────────────
            _sectionHeader('Professional'),
            _field('Company Name', _companyCtrl),
            _field('Job Title', _jobTitleCtrl, hint: 'e.g. CEO, Engineer'),
            _label('Industry'),
            const SizedBox(height: 6),
            _dropdown<String>(
              value: _industry,
              placeholder: 'Select industry',
              items: AppConstants.industries.where((i) => i != 'N/A').toList(),
              label: (v) => v,
              onChanged: (v) => setState(() => _industry = v),
            ),
            const SizedBox(height: 16),
            _field('Business Bio', _businessBioCtrl, hint: 'Brief description of your work', maxLines: 3),
            _field('Business Website', _businessWebCtrl, hint: 'https://example.com', type: TextInputType.url),
            _label('YI Vertical'),
            const SizedBox(height: 6),
            _dropdown<Map<String, String>>(
              value: AppConstants.yiVerticals.firstWhere((v) => v['value'] == _yiVertical),
              items: AppConstants.yiVerticals,
              label: (v) => v['label']!,
              onChanged: (v) => setState(() {
                _yiVertical = v['value']!;
                if (_yiVertical == 'none') _yiPosition = 'none';
              }),
            ),
            if (_yiVertical != 'none') ...[
              const SizedBox(height: 16),
              _label('YI Position'),
              const SizedBox(height: 6),
              _dropdown<Map<String, String>>(
                value: AppConstants.yiPositions.firstWhere((p) => p['value'] == _yiPosition),
                items: AppConstants.yiPositions,
                label: (v) => v['label']!,
                onChanged: (v) => setState(() => _yiPosition = v['value']!),
              ),
            ],
            const SizedBox(height: 16),
            _field('YI Kanpur Joining Year', _memberSinceYearCtrl, hint: 'e.g. 2023', type: TextInputType.number),

            // ── Social Media ───────────────────────────────────────────────
            _sectionHeader('Social Media'),
            _socialField(Icons.work_outline, 'LinkedIn', _linkedinCtrl, hint: 'linkedin.com/in/you'),
            _socialField(Icons.camera_alt_outlined, 'Instagram', _instagramCtrl, hint: 'instagram.com/you'),
            _socialField(Icons.alternate_email, 'X (Twitter)', _twitterCtrl, hint: 'x.com/you'),
            _socialField(Icons.facebook_outlined, 'Facebook', _facebookCtrl, hint: 'facebook.com/you'),

            // ── Personal ───────────────────────────────────────────────────
            _sectionHeader('Personal'),
            _field('Personal Bio', _personalBioCtrl, hint: 'Tell the community about yourself…', maxLines: 4),
            _label('Relationship Status'),
            const SizedBox(height: 8),
            _radioGroup<String>(
              value: _relationshipStatus,
              options: const [('married', 'Married'), ('single', 'Single (for now)')],
              onChanged: (v) => setState(() {
                _relationshipStatus = v;
                if (v != 'married') {
                  _spouseCtrl.clear();
                  _isSpouseYiMember = false;
                  _anniversaryDate  = null;
                }
              }),
            ),
            if (_relationshipStatus == 'married') ...[
              const SizedBox(height: 16),
              _field('Spouse Name', _spouseCtrl, hint: 'Full name'),
              _label('Is Spouse a YI Member?'),
              const SizedBox(height: 8),
              _radioGroup<bool>(
                value: _isSpouseYiMember,
                options: const [(true, 'Yes'), (false, 'No')],
                onChanged: (v) => setState(() => _isSpouseYiMember = v),
              ),
              const SizedBox(height: 16),
              _label('Anniversary Date'),
              const SizedBox(height: 6),
              _dateTile(
                value: _anniversaryDate,
                hint: 'Select anniversary date',
                onTap: () async {
                  final d = await _pickDate(initialDate: _anniversaryDate ?? DateTime(2015));
                  if (d != null) setState(() => _anniversaryDate = d);
                },
              ),
              const SizedBox(height: 16),
            ],
            _label('Blood Group'),
            const SizedBox(height: 6),
            _dropdown<String>(
              value: _bloodGroup,
              placeholder: 'Select blood group',
              items: AppConstants.bloodGroups,
              label: (v) => v,
              onChanged: (v) => setState(() => _bloodGroup = v),
            ),
            const SizedBox(height: 24),

            // ── Business Tags ──────────────────────────────────────────────
            _tagSection(
              title: 'Business Tags (up to 3)',
              predefined: AppConstants.businessTags,
              selected: _businessTags,
              customCtrl: _customBusinessTag,
              onToggle: (tag) => setState(() {
                if (_businessTags.contains(tag)) _businessTags.remove(tag);
                else if (_businessTags.length < 3) _businessTags.add(tag);
              }),
              onAddCustom: () {
                final tag = _customBusinessTag.text.trim();
                if (tag.isNotEmpty && _businessTags.length < 3) {
                  setState(() { _businessTags.add(tag); _customBusinessTag.clear(); });
                }
              },
            ),
            const SizedBox(height: 24),

            // ── Hobby Tags ────────────────────────────────────────────────
            _tagSection(
              title: 'Hobby Tags (up to 3)',
              predefined: AppConstants.hobbyTags,
              selected: _hobbyTags,
              customCtrl: _customHobbyTag,
              onToggle: (tag) => setState(() {
                if (_hobbyTags.contains(tag)) _hobbyTags.remove(tag);
                else if (_hobbyTags.length < 3) _hobbyTags.add(tag);
              }),
              onAddCustom: () {
                final tag = _customHobbyTag.text.trim();
                if (tag.isNotEmpty && _hobbyTags.length < 3) {
                  setState(() { _hobbyTags.add(tag); _customHobbyTag.clear(); });
                }
              },
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  Future<DateTime?> _pickDate({DateTime? initialDate, DateTime? lastDate}) => showDatePicker(
    context: context,
    initialDate: initialDate ?? DateTime(1995, 1, 1),
    firstDate: DateTime(1940),
    lastDate: lastDate ?? DateTime.now(),
    builder: (ctx, child) => Theme(
      data: Theme.of(ctx).copyWith(colorScheme: const ColorScheme.dark(primary: AppColors.green)),
      child: child!,
    ),
  );

  Widget _sectionHeader(String title) => Padding(
    padding: const EdgeInsets.only(top: 8, bottom: 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(color: AppColors.divider),
        const SizedBox(height: 12),
        Text(title.toUpperCase(), style: const TextStyle(
          color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.8,
        )),
        const SizedBox(height: 4),
      ],
    ),
  );

  Widget _label(String text) => Text(text,
    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textMuted));

  Widget _field(String label, TextEditingController ctrl, {
    String? hint, TextInputType? type, int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(label),
        const SizedBox(height: 6),
        _textField(ctrl, hint: hint ?? label, type: type, maxLines: maxLines),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _textField(TextEditingController ctrl, {
    String hint = '', TextInputType? type, int maxLines = 1, ValueChanged<String>? onChanged,
  }) {
    return TextField(
      controller: ctrl,
      keyboardType: type,
      maxLines: maxLines,
      onChanged: onChanged,
      style: const TextStyle(color: AppColors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.textMuted),
        filled: true, fillColor: AppColors.card,
        border:        OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.green)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );
  }

  Widget _countryCodePicker({required String value, required ValueChanged<String> onChanged}) {
    return Container(
      height: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: AppColors.card, borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          dropdownColor: AppColors.card,
          style: const TextStyle(color: AppColors.white, fontSize: 14),
          items: AppConstants.countryCodes.map((c) => DropdownMenuItem<String>(
            value: c['code'], child: Text('${c['flag']} ${c['code']}'),
          )).toList(),
          onChanged: (v) { if (v != null) onChanged(v); },
        ),
      ),
    );
  }

  Widget _dropdown<T>({
    required T? value, String? placeholder,
    required List<T> items, required String Function(T) label,
    required ValueChanged<T> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.card, borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value, isExpanded: true, dropdownColor: AppColors.card,
          style: const TextStyle(color: AppColors.white, fontSize: 15),
          hint: Text(placeholder ?? 'Select', style: const TextStyle(color: AppColors.textMuted)),
          items: items.map((item) => DropdownMenuItem<T>(value: item, child: Text(label(item)))).toList(),
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
          color: AppColors.card, borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                value == null ? hint : DateFormat('dd MMM yyyy').format(value),
                style: TextStyle(color: value == null ? AppColors.textMuted : AppColors.white, fontSize: 15),
              ),
            ),
            const Icon(Icons.calendar_today_outlined, size: 18, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }

  Widget _socialField(IconData icon, String label, TextEditingController ctrl, {required String hint}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Icon(icon, size: 16, color: AppColors.textMuted),
          const SizedBox(width: 6),
          _label(label),
        ]),
        const SizedBox(height: 6),
        _textField(ctrl, hint: hint, type: TextInputType.url),
        const SizedBox(height: 16),
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
              border: Border.all(color: selected ? AppColors.green : AppColors.border),
            ),
            child: Row(
              children: [
                Container(
                  width: 18, height: 18,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: selected ? AppColors.green : AppColors.textMuted, width: 2),
                  ),
                  child: selected
                      ? Center(child: Container(width: 8, height: 8,
                          decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.green)))
                      : null,
                ),
                const SizedBox(width: 12),
                Text(optLabel, style: TextStyle(
                  color: selected ? AppColors.white : AppColors.textMuted, fontSize: 15,
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
          _label(title),
          const Spacer(),
          Text('${selected.length}/3', style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
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
                  border: Border.all(color: isSelected ? AppColors.green : AppColors.border),
                ),
                child: Text(tag, style: TextStyle(
                  fontSize: 13,
                  color: isSelected ? AppColors.green : AppColors.textMuted,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                )),
              ),
            );
          }).toList(),
        ),
        if (selected.length < 3) ...[
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
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border:        OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: const BorderSide(color: AppColors.border)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: const BorderSide(color: AppColors.border)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: const BorderSide(color: AppColors.green)),
                ),
                onSubmitted: (_) => onAddCustom(),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(onPressed: onAddCustom, icon: const Icon(Icons.add_circle, color: AppColors.green)),
          ]),
        ],
        if (selected.any((t) => !predefined.contains(t))) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: selected
                .where((t) => !predefined.contains(t))
                .map((tag) => Chip(
                      label: Text(tag, style: const TextStyle(fontSize: 12, color: AppColors.green)),
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
