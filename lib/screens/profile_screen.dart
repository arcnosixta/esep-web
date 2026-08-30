import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../theme/app_colors.dart';
import '../l10n/app_strings.dart';
import '../widgets/information_tile.dart';
import '../widgets/status_badge.dart';
import '../services/supabase_service.dart';
import '../utils/formatters.dart';
import '../utils/iin_validator.dart';
import 'egov_screen.dart';
import 'settings_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  Map<String, dynamic>? _profile;
  List<Map<String, dynamic>> _properties = [];
  List<Map<String, dynamic>> _history = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final results = await Future.wait([
        SupabaseService.getProfile(),
        SupabaseService.getProperties(),
        SupabaseService.getApplications(),
      ]);
      if (mounted) {
        setState(() {
          _profile = results[0] as Map<String, dynamic>?;
          _properties = results[1] as List<Map<String, dynamic>>;
          _history = results[2] as List<Map<String, dynamic>>;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _getInitials() {
    final name = _profile?['full_name'] ?? '';
    if (name.isEmpty) return '?';
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.substring(0, name.length.clamp(0, 2)).toUpperCase();
  }

  void _openEditProfile() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EditProfileSheet(
        profile: _profile,
        onSaved: () {
          _loadData();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final s = AppStrings.of(context);
    final isCompactWeb = kIsWeb && MediaQuery.of(context).size.width < 640;

    if (_loading) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: c.accent),
        ),
      );
    }

    final name = _profile?['full_name'] ?? '';
    final iin = _profile?['iin'] ?? '';
    final phone = _profile?['phone'] ?? '';
    final email = _profile?['email'] ??
        SupabaseService.currentUser?.email ??
        '';
    final roleKey = _profile?['role'];
    final role = roleKey == 'appraiser'
        ? s.profileRoleAppraiser
        : roleKey == 'admin'
            ? s.profileRoleAdmin
            : s.profileRoleClient;

    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                isCompactWeb ? 14 : 24,
                20,
                isCompactWeb ? 14 : 24,
                0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    s.profileTitle,
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: c.textPrimary,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      color: c.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: c.border, width: 1),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      labelColor: c.accent,
                      unselectedLabelColor: c.textSecondary,
                      indicatorColor: c.accent,
                      indicatorSize: TabBarIndicatorSize.tab,
                      indicatorPadding: const EdgeInsets.all(3),
                      indicator: BoxDecoration(
                        color: c.accent.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(9),
                      ),
                      labelStyle: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      unselectedLabelStyle: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      ),
                      dividerColor: Colors.transparent,
                      tabs: [
                        Tab(text: s.profileTab),
                        Tab(text: s.settingsTab),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  RefreshIndicator(
                    onRefresh: _loadData,
                    color: c.accent,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics(),
                      ),
                      padding: EdgeInsets.fromLTRB(
                        isCompactWeb ? 14 : 24,
                        20,
                        isCompactWeb ? 14 : 24,
                        32,
                      ),
                      children: [
                        Container(
                          padding: EdgeInsets.fromLTRB(
                            isCompactWeb ? 14 : 20,
                            16,
                            isCompactWeb ? 14 : 20,
                            isCompactWeb ? 16 : 20,
                          ),
                          decoration: BoxDecoration(
                            color: _profile?['cover_url'] == null ? c.surface : null,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                                color: c.border, width: 1),
                            image: _profile?['cover_url'] != null
                                ? DecorationImage(
                                    image: NetworkImage(_profile!['cover_url']),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                            boxShadow: [
                              BoxShadow(
                                color:
                                    Colors.black.withValues(alpha: 0.04),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: isCompactWeb ? 8 : 10,
                                      vertical: isCompactWeb ? 4 : 5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: c.accent.withValues(alpha: 0.08),
                                      borderRadius:
                                          BorderRadius.circular(8),
                                      border: Border.all(
                                        color: c.accent.withValues(alpha: 0.15),
                                      ),
                                    ),
                                    child: Text(
                                      role,
                                      style: TextStyle(
                                        fontSize: isCompactWeb ? 11 : 12,
                                        fontWeight: FontWeight.w600,
                                        color: c.accent,
                                      ),
                                    ),
                                  ),
                                  const Spacer(),
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: isCompactWeb ? 8 : 10,
                                      vertical: isCompactWeb ? 4 : 5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: c.gold
                                          .withValues(alpha: 0.12),
                                      borderRadius:
                                          BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(Icons.verified_rounded,
                                            size: isCompactWeb ? 12 : 14,
                                            color: c.gold),
                                        SizedBox(width: isCompactWeb ? 3 : 4),
                                        Text(
                                          s.profileVerified,
                                          style: TextStyle(
                                            fontSize: isCompactWeb ? 10 : 11,
                                            fontWeight: FontWeight.w600,
                                            color: c.gold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(width: isCompactWeb ? 6 : 8),
                                  IconButton(
                                    onPressed: _openEditProfile,
                                    icon: Icon(Icons.edit_rounded,
                                        size: isCompactWeb ? 16 : 18, color: c.accent),
                                    tooltip: s.profileEdit,
                                  ),
                                ],
                              ),
                              SizedBox(height: isCompactWeb ? 12 : 16),
                              Container(
                                width: isCompactWeb ? 64 : 80,
                                height: isCompactWeb ? 64 : 80,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: c.surface, width: 4),
                                  image: _profile?['avatar_url'] != null
                                      ? DecorationImage(
                                          image: NetworkImage(
                                              _profile!['avatar_url']),
                                          fit: BoxFit.cover,
                                        )
                                      : null,
                                  color: c.accent,
                                ),
                                child: _profile?['avatar_url'] == null
                                    ? Center(
                                        child: Text(
                                          _getInitials(),
                                          style: TextStyle(
                                            fontSize: isCompactWeb ? 22 : 26,
                                            fontWeight: FontWeight.w800,
                                            color: Colors.white,
                                          ),
                                        ),
                                      )
                                    : null,
                              ),
                              SizedBox(height: isCompactWeb ? 10 : 12),
                              Text(
                                name.isNotEmpty ? name : '—',
                                style: TextStyle(
                                  fontSize: isCompactWeb ? 18 : 20,
                                  fontWeight: FontWeight.w800,
                                  color: c.textPrimary,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              if (iin.isNotEmpty) ...[
                                SizedBox(height: isCompactWeb ? 3 : 4),
                                Text(
                                  iin,
                                  style: TextStyle(
                                    fontSize: isCompactWeb ? 11 : 12,
                                    color: c.textSecondary,
                                  ),
                                ),
                              ],
                              SizedBox(height: isCompactWeb ? 14 : 18),
                              if (isCompactWeb)
                                Wrap(
                                  spacing: 24,
                                  runSpacing: 10,
                                  alignment: WrapAlignment.center,
                                  children: [
                                    _ProfileStat(
                                      value: '${_properties.length}',
                                      label: s.profileObjects,
                                    ),
                                    _ProfileStat(
                                      value: '${_history.length}',
                                      label: s.profileEvaluations,
                                    ),
                                    _ProfileStat(
                                      value: _profile?['documents_count'] != null
                                          ? '${_profile!['documents_count']}'
                                          : '0',
                                      label: s.profileDocuments,
                                    ),
                                  ],
                                )
                              else
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    _ProfileStat(
                                      value: '${_properties.length}',
                                      label: s.profileObjects,
                                    ),
                                    _ProfileStat(
                                      value: '${_history.length}',
                                      label: s.profileEvaluations,
                                    ),
                                    _ProfileStat(
                                      value: _profile?['documents_count'] != null
                                          ? '${_profile!['documents_count']}'
                                          : '0',
                                      label: s.profileDocuments,
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: c.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                                color: c.border, width: 1),
                          ),
                          child: Column(
                            children: [
                              infoRow(context, s.profileIin, iin),
                              divider(context),
                              infoRow(context, s.profilePhone, phone),
                              divider(context),
                              infoRow(context, s.profileEmail, email),
                              divider(context),
                              infoRow(context, s.profileRole, role),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: c.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                                color: c.border, width: 1),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                s.profileEgovTitle,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: c.textSecondary,
                                  letterSpacing: 0.8,
                                ),
                              ),
                              const SizedBox(height: 14),
                              Row(
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: c.info
                                          .withValues(alpha: 0.1),
                                      borderRadius:
                                          BorderRadius.circular(10),
                                    ),
                                    child: Icon(
                                      Icons.account_balance_rounded,
                                      color: c.info,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          s.profileEcpStatus,
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: c.textPrimary,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          s.profileEgovSubtitle,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color:
                                                c.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton(
                                  onPressed: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) =>
                                            const EgovScreen()),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    side: BorderSide(
                                        color: c.info, width: 1),
                                    shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(12),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 24, vertical: 12),
                                  ),
                                  child: Text(
                                    s.profileEgovOpen,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: c.info,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              s.profileMyProperty,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: c.textSecondary,
                                letterSpacing: 0.8,
                              ),
                            ),
                            Text(
                              '${_properties.length}',
                              style: TextStyle(
                                fontSize: 12,
                                color: c.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        if (_properties.isEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 14),
                            child: Text(
                              s.profileNoProperty,
                              style: TextStyle(
                                fontSize: 14,
                                color: c.textHint,
                              ),
                            ),
                          )
                        else
                          Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: Container(
                              decoration: BoxDecoration(
                                color: c.surface,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                    color: c.border, width: 1),
                              ),
                              child: Column(
                                children: [
                                  for (int i = 0;
                                      i < _properties.length;
                                      i++) ...[
                                    _buildPropertyRow(context, _properties[i]),
                                    if (i < _properties.length - 1)
                                      Container(
                                        height: 1,
                                        margin: const EdgeInsets.only(
                                            left: 72),
                                        color: c.divider,
                                      ),
                                  ],
                                ],
                              ),
                            ),
                          ),

                        const SizedBox(height: 24),
                        Text(
                          s.profileHistory,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: c.textSecondary,
                            letterSpacing: 0.8,
                          ),
                        ),
                        if (_history.isEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 14),
                            child: Text(
                              s.profileNoHistory,
                              style: TextStyle(
                                fontSize: 14,
                                color: c.textHint,
                              ),
                            ),
                          )
                        else
                          Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: Container(
                              decoration: BoxDecoration(
                                color: c.surface,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                    color: c.border, width: 1),
                              ),
                              child: Column(
                                children: [
                                  for (int i = 0;
                                      i < _history.length;
                                      i++) ...[
                                    _buildHistoryRow(context, _history[i]),
                                    if (i < _history.length - 1)
                                      Container(
                                        height: 1,
                                        margin: const EdgeInsets.only(
                                            left: 72),
                                        color: c.divider,
                                      ),
                                  ],
                                ],
                              ),
                            ),
                          ),

                        const SizedBox(height: 28),
                        Container(
                          decoration: BoxDecoration(
                            color: c.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                                color: c.border, width: 1),
                          ),
                          child: Column(
                            children: [
                              _settingsRow(
                                  Icons.help_rounded, s.profileHelp),
                              Container(
                                height: 1,
                                margin: const EdgeInsets.only(left: 52),
                                color: c.divider,
                              ),
                              _settingsRow(Icons.info_outline_rounded,
                                  s.profileAbout),
                              Container(
                                height: 1,
                                margin: const EdgeInsets.only(left: 52),
                                color: c.divider,
                              ),
                              _settingsRow(
                                  Icons.logout_rounded, s.profileSignOut,
                                  color: c.error,
                                  onTap: _signOut),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SettingsScreen(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPropertyRow(BuildContext context, Map<String, dynamic> item) {
    final c = AppColors.of(context);
    final type = item['type'] ?? '';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: propertyTypeColor(context, type).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              propertyTypeIcon(type),
              color: propertyTypeColor(context, type),
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  propertyTypeLabel(context, type),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: c.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${item['area'] ?? 0} м² · ${item['address'] ?? ''}',
                  style: TextStyle(
                    fontSize: 12,
                    color: c.textSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right_rounded,
            color: c.textHint,
            size: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryRow(BuildContext context, Map<String, dynamic> item) {
    final c = AppColors.of(context);
    final status = item['status'] ?? 'new';
    final prop = item['properties'];
    final propType = prop != null ? (prop['type'] ?? '') : '';
    final price = item['estimated_price'];
    final priceStr =
        price != null ? '${price.toStringAsFixed(0)} ₸' : '';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: c.accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                () {
                  final rawId = (item['id'] ?? '').toString();
                  final short = rawId.length >= 4
                      ? rawId.substring(0, 4).toUpperCase()
                      : rawId.toUpperCase();
                  return '#$short';
                }(),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: c.accent,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      propertyTypeLabel(context, propType),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: c.textPrimary,
                      ),
                    ),
                    StatusBadge(
                      status: badgeStatusFromKey(status),
                      label: statusLabel(context, status),
                      small: true,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  priceStr.isNotEmpty ? priceStr : '—',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: c.accent,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _settingsRow(IconData icon, String label,
      {Color? color, VoidCallback? onTap}) {
    final c = AppColors.of(context);
    final effectiveColor = color ?? c.textPrimary;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Icon(icon, size: 20, color: effectiveColor),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: effectiveColor,
                ),
              ),
            ),
            if (color == null)
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: c.textHint,
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _signOut() async {
    final c = AppColors.of(context);
    final s = AppStrings.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: c.surface,
        title: Text(s.profileSignOutTitle,
            style: TextStyle(color: c.textPrimary)),
        content: Text(s.profileSignOutContent,
            style: TextStyle(color: c.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(s.cancel,
                style: TextStyle(color: c.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(s.profileSignOut,
                style: TextStyle(color: c.error)),
          ),
        ],
      ),
    );
    if (confirm == true && mounted) {
      await SupabaseService.signOut();
    }
  }
}

class _ProfileStat extends StatelessWidget {
  final String value;
  final String label;

  const _ProfileStat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: c.textPrimary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: c.textSecondary,
          ),
        ),
      ],
    );
  }
}

// ============================================
// EDIT PROFILE SHEET
// ============================================

class _EditProfileSheet extends StatefulWidget {
  final Map<String, dynamic>? profile;
  final VoidCallback onSaved;

  const _EditProfileSheet({required this.profile, required this.onSaved});

  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _iinController;
  late final TextEditingController _orgNameController;
  late bool _isOrg;
  String? _iinError;
  bool _saving = false;
  String? _avatarPath;
  String? _coverPath;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
        text: widget.profile?['full_name'] ?? '');
    _phoneController = TextEditingController(
        text: widget.profile?['phone'] ?? '');
    _iinController = TextEditingController(
        text: widget.profile?['iin'] ?? widget.profile?['bin'] ?? '');
    _orgNameController = TextEditingController(
        text: widget.profile?['org_name'] ?? '');
    _isOrg = (widget.profile?['client_type'] ?? 'person') == 'org';
    _avatarPath = widget.profile?['avatar_url'] as String?;
    _coverPath = widget.profile?['cover_url'] as String?;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _iinController.dispose();
    _orgNameController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUpload({
    required ImageSource source,
    required bool isAvatar,
  }) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: source,
      maxWidth: isAvatar ? 1200 : 1600,
      maxHeight: isAvatar ? 1200 : 700,
      imageQuality: 88,
    );
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    final oldPath = isAvatar ? _avatarPath : _coverPath;
    try {
      final path = await SupabaseService.uploadProfileAvatar(bytes, oldPath: oldPath ?? '');
      if (!mounted) return;
      setState(() {
        if (isAvatar) _avatarPath = path;
        else _coverPath = path;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _save() async {
    final s = AppStrings.of(context);
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.profileNameEmpty)),
      );
      return;
    }

    // Валидация ИИН/БИН (обязателен: это основа идентификации клиента).
    final idNumber = _iinController.text.trim();
    if (idNumber.isEmpty) {
      setState(() => _iinError = s.profileIinRequired);
      return;
    }
    final idCheck = IinValidator.validate(idNumber);
    if (!idCheck.valid) {
      setState(() => _iinError = idCheck.error);
      return;
    }
    if (_isOrg && !idCheck.isOrg) {
      setState(() => _iinError = s.profileIinOrgMismatch);
      return;
    }
    if (!_isOrg && idCheck.isOrg) {
      setState(() => _iinError = s.profileBinPersonMismatch);
      return;
    }
    if (_isOrg && _orgNameController.text.trim().isEmpty) {
      setState(() => _iinError = s.profileOrgNameRequired);
      return;
    }

    setState(() => _saving = true);

    try {
      await SupabaseService.updateProfile(
        fullName: name,
        phone: _phoneController.text.trim(),
        iin: _isOrg ? null : idNumber,
        clientType: _isOrg ? 'org' : 'person',
        orgName: _isOrg ? _orgNameController.text.trim() : null,
        bin: _isOrg ? idNumber : null,
        avatarUrl: _avatarPath,
        coverUrl: _coverPath,
      );
      if (mounted) {
        widget.onSaved();
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(s.profileUpdated)),
        );
      }
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString();
      // Уникальный индекс profiles_iin_unique → код 23505 (unique_violation).
      if (msg.contains('23505') || msg.contains('duplicate key')) {
        setState(() => _iinError = s.profileIinTaken);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final s = AppStrings.of(context);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: c.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                s.profileEditTitle,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: c.textPrimary,
                ),
              ),
              const SizedBox(height: 24),
              _MediaPickerRow(
                title: 'Фото профиля',
                subtitle: 'Поменять аватар',
                path: _avatarPath,
                borderRadius: 36,
                maxHeight: 96,
                isAvatar: true,
                onPickAvatar: () => _showImageSourceSheet(true),
                onPickCover: () => _showImageSourceSheet(false),
              ),
              const SizedBox(height: 12),
              _MediaPickerRow(
                title: 'Обложка профиля',
                subtitle: 'Фон как на YouTube',
                path: _coverPath,
                borderRadius: 16,
                maxHeight: 140,
                isAvatar: false,
                onPickAvatar: () => _showImageSourceSheet(true),
                onPickCover: () => _showImageSourceSheet(false),
              ),
              const SizedBox(height: 24),
              _buildField(
                controller: _nameController,
                label: s.profileName,
                icon: Icons.person_rounded,
                keyboardType: TextInputType.name,
              ),
              const SizedBox(height: 16),
              _buildField(
                controller: _phoneController,
                label: s.profilePhone,
                icon: Icons.phone_rounded,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              // Тип клиента: физлицо (ИИН) / юрлицо (БИН + организация)
              Row(
                children: [
                  _typeChip(s.profileClientTypePerson, !_isOrg, () {
                    setState(() {
                      _isOrg = false;
                      _iinError = null;
                    });
                  }),
                  const SizedBox(width: 12),
                  _typeChip(s.profileClientTypeOrg, _isOrg, () {
                    setState(() {
                      _isOrg = true;
                      _iinError = null;
                    });
                  }),
                ],
              ),
              const SizedBox(height: 16),
              if (_isOrg) ...[
                _buildField(
                  controller: _orgNameController,
                  label: s.profileOrgName,
                  icon: Icons.business_rounded,
                  keyboardType: TextInputType.text,
                ),
                const SizedBox(height: 16),
              ],
              _buildField(
                controller: _iinController,
                label: _isOrg ? s.profileBin : s.profileIin,
                icon: Icons.badge_rounded,
                keyboardType: TextInputType.number,
                maxLength: 12,
              ),
              if (_iinError != null) ...[
                const SizedBox(height: 8),
                Text(
                  _iinError!,
                  style: TextStyle(
                    color: c.error,
                    fontSize: 12.5,
                    height: 1.3,
                  ),
                ),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: c.accent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          s.save,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _typeChip(String label, bool selected, VoidCallback onTap) {
    final c = AppColors.of(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? c.accent : c.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? c.accent : c.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : c.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    int? maxLength,
  }) {
    final c = AppColors.of(context);
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLength: maxLength,
      style: TextStyle(
        fontSize: 15,
        color: c.textPrimary,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          fontSize: 14,
          color: c.textSecondary,
        ),
        prefixIcon: Icon(icon, size: 20, color: c.textSecondary),
        counterText: '',
        filled: true,
        fillColor: c.background,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: c.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: c.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: c.accent, width: 1.5),
        ),
      ),
    );
  }

  void _showImageSourceSheet(bool forAvatar) {
    final canUseCamera = !kIsWeb && defaultTargetPlatform != TargetPlatform.linux;
    final c = AppColors.of(context);
    final label = forAvatar ? 'Изменить аватар' : 'Изменить обложку';
    showModalBottomSheet(
      context: context,
      backgroundColor: c.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: c.muted,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                Text(label, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: c.textPrimary)),
                const SizedBox(height: 16),
                if (canUseCamera)
                  _imageSourceOption(Icons.camera_alt_rounded, 'Камера', () {
                    Navigator.pop(ctx);
                    _pickAndUpload(source: ImageSource.camera, isAvatar: forAvatar);
                  }),
                if (canUseCamera) const SizedBox(height: 8),
                _imageSourceOption(Icons.photo_library_rounded, 'Галерея', () {
                  Navigator.pop(ctx);
                  _pickAndUpload(source: ImageSource.gallery, isAvatar: forAvatar);
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _imageSourceOption(IconData icon, String label, VoidCallback onTap) {
    final c = AppColors.of(context);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: c.inputFill,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: c.accent, size: 20),
            const SizedBox(width: 14),
            Text(label, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: c.textPrimary)),
          ],
        ),
      ),
    );
  }
}

class _MediaPickerRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? path;
  final double borderRadius;
  final double maxHeight;
  final bool isAvatar;
  final VoidCallback onPickAvatar;
  final VoidCallback onPickCover;

  const _MediaPickerRow({
    required this.title,
    required this.subtitle,
    this.path,
    required this.borderRadius,
    required this.maxHeight,
    required this.isAvatar,
    required this.onPickAvatar,
    required this.onPickCover,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final hasImage = path != null && path!.startsWith('http');
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: isAvatar ? onPickAvatar : onPickCover,
      child: Container(
        constraints: BoxConstraints(maxHeight: maxHeight),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: c.border, width: 1),
        ),
        child: Row(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: c.textPrimary)),
                    const SizedBox(height: 4),
                    Text(subtitle, style: TextStyle(fontSize: 12, color: c.textSecondary)),
                  ],
                ),
              ),
            ),
            Container(
              width: isAvatar ? 52 : 88,
              height: isAvatar ? 52 : 44,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: c.inputFill,
                borderRadius: BorderRadius.circular(borderRadius),
                border: Border.all(color: c.border),
                image: hasImage ? DecorationImage(image: NetworkImage(path!), fit: BoxFit.cover) : null,
              ),
              child: !hasImage
                  ? Icon(Icons.add_photo_alternate_rounded, color: c.textHint, size: isAvatar ? 22 : 18)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
