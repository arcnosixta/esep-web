import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart';
import '../models/user_profile.dart';

class SupabaseService {
  SupabaseService._();

  // ============================================
  // AUTH
  // ============================================

  static User? get currentUser => supabase.auth.currentUser;
  static String? get userId => currentUser?.id;

  static Future<AuthResponse> signUp({
    required String email,
    required String password,
    String fullName = '',
    String phone = '',
  }) async {
    final response = await supabase.auth.signUp(
      email: email,
      password: password,
      data: {
        'full_name': fullName,
        'phone': phone,
      },
    );

    if (response.user != null) {
      await _ensureProfile(
        fullName: fullName,
        email: email,
        phone: phone,
      );
    }

    return response;
  }

  static Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    final response = await supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );

    if (response.user != null) {
      await _ensureProfile(
        fullName: response.user!.userMetadata?['full_name'] ?? '',
        email: email,
        phone: response.user!.userMetadata?['phone'] ?? '',
      );
    }

    return response;
  }

  static Future<void> signOut() async {
    await supabase.auth.signOut();
  }

  static Stream<AuthState> get authStateChanges =>
      supabase.auth.onAuthStateChange;

  // ============================================
  // PROFILE FALLBACK (если триггер не сработал)
  // ============================================

  static Future<void> _ensureProfile({
    String fullName = '',
    String email = '',
    String phone = '',
  }) async {
    if (userId == null) return;

    final existing = await supabase
        .from('profiles')
        .select('id')
        .eq('user_id', userId!)
        .maybeSingle();

    if (existing == null) {
      await supabase.from('profiles').insert({
        'user_id': userId!,
        'full_name': fullName,
        'email': email,
        'phone': phone,
      });
    } else if (fullName.isNotEmpty || phone.isNotEmpty) {
      final updates = <String, dynamic>{};
      if (fullName.isNotEmpty) updates['full_name'] = fullName;
      if (phone.isNotEmpty) updates['phone'] = phone;
      if (updates.isNotEmpty) {
        await supabase.from('profiles').update(updates).eq('user_id', userId!);
      }
    }
  }

  // ============================================
  // PROFILES
  // ============================================

  static Future<UserProfile?> getUserProfile() async {
    if (userId == null) return null;
    final data = await supabase
        .from('profiles')
        .select()
        .eq('user_id', userId!)
        .maybeSingle();
    if (data == null) return null;
    return UserProfile.fromJson(data);
  }

  static Future<Map<String, dynamic>?> getProfile() async {
    if (userId == null) return null;
    final data = await supabase
        .from('profiles')
        .select()
        .eq('user_id', userId!)
        .maybeSingle();
    return data;
  }

  static Future<UserRole?> getUserRole() async {
    final profile = await getUserProfile();
    return profile?.role;
  }

  static Future<void> updateProfile({
    String? fullName,
    String? iin,
    String? phone,
    String? email,
  }) async {
    if (userId == null) return;
    final updates = <String, dynamic>{};
    if (fullName != null) updates['full_name'] = fullName;
    if (iin != null) updates['iin'] = iin;
    if (phone != null) updates['phone'] = phone;
    if (email != null) updates['email'] = email;
    if (updates.isNotEmpty) {
      await supabase.from('profiles').update(updates).eq('user_id', userId!);
    }
  }

  // ============================================
  // PROPERTIES
  // ============================================

  static Future<List<Map<String, dynamic>>> getProperties() async {
    if (userId == null) return [];
    final data = await supabase
        .from('properties')
        .select()
        .eq('user_id', userId!)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(data);
  }

  static Future<Map<String, dynamic>> addProperty({
    required String type,
    required String address,
    required double area,
    int? rooms,
    int? floor,
    int? totalFloors,
  }) async {
    final data = await supabase.from('properties').insert({
      'user_id': userId,
      'type': type,
      'address': address,
      'area': area,
      'rooms': rooms,
      'floor': floor,
      'total_floors': totalFloors,
    }).select().single();
    return data;
  }

  // ============================================
  // DOCUMENTS
  // ============================================

  static const _storageBucket = 'user-docs';

  static String _storagePath(String fileName) {
    return '$userId/$fileName';
  }

  static Future<void> ensureStorageBucket() async {
    try {
      await supabase.storage.getBucket(_storageBucket);
    } catch (_) {
      try {
        await supabase.storage.createBucket(
          _storageBucket,
          BucketOptions(
            public: false,
            fileSizeLimit: '10485760',
            allowedMimeTypes: ['application/pdf', 'image/jpeg', 'image/png'],
          ),
        );
      } catch (e) {
        throw Exception(
          'Не удалось создать хранилище. Создай bucket "user-docs" вручную в Supabase Dashboard → Storage → New bucket.',
        );
      }
    }
  }

  static Future<List<Map<String, dynamic>>> getDocuments() async {
    if (userId == null) return [];
    final data = await supabase
        .from('documents')
        .select()
        .eq('user_id', userId!)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(data);
  }

  static Future<Map<String, dynamic>> uploadDocument(File file) async {
    if (userId == null) throw Exception('Не авторизован');

    final originalName = file.uri.pathSegments.last;
    final ext = originalName.contains('.')
        ? originalName.substring(originalName.lastIndexOf('.'))
        : '';
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final safeName = '$timestamp$ext';
    final path = _storagePath(safeName);

    await supabase.storage.from(_storageBucket).upload(
      path,
      file,
      fileOptions: const FileOptions(upsert: true),
    );

    final fileSize = await file.length();
    final fileType = ext.replaceFirst('.', '').toLowerCase();

    final data = await supabase
        .from('documents')
        .insert({
          'user_id': userId!,
          'name': originalName,
          'file_url': path,
          'file_type': fileType,
          'file_size': fileSize,
        })
        .select()
        .single();
    return data;
  }

  static Future<void> deleteDocument(String id, {String? filePath}) async {
    if (filePath != null) {
      try {
        await supabase.storage.from(_storageBucket).remove([filePath]);
      } catch (_) {}
    }
    await supabase.from('documents').delete().eq('id', id);
  }

  static String getDocumentUrl(String filePath) {
    return supabase.storage.from(_storageBucket).getPublicUrl(filePath);
  }

  // ============================================
  // APPLICATIONS
  // ============================================

  static Future<List<Map<String, dynamic>>> getApplications() async {
    if (userId == null) return [];
    final data = await supabase
        .from('applications')
        .select('*, properties(type, address, area, rooms, floor)')
        .eq('user_id', userId!)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(data);
  }

  static Future<Map<String, dynamic>> createApplication({
    required String propertyId,
  }) async {
    final data = await supabase.from('applications').insert({
      'user_id': userId,
      'property_id': propertyId,
      'status': 'new',
    }).select().single();
    return data;
  }

  static Future<Map<String, dynamic>> getApplication(String id) async {
    final data = await supabase
        .from('applications')
        .select('*, properties(type, address, area, rooms, floor)')
        .eq('id', id)
        .single();
    return data;
  }

  // ============================================
  // APPRAISALS
  // ============================================

  static Future<Map<String, dynamic>?> getAppraisal(String applicationId) async {
    final data = await supabase
        .from('appraisals')
        .select()
        .eq('application_id', applicationId)
        .maybeSingle();
    return data;
  }

  static Future<Map<String, dynamic>> createAppraisal({
    required String applicationId,
    required double estimatedPrice,
    String? reportUrl,
  }) async {
    final data = await supabase.from('appraisals').insert({
      'application_id': applicationId,
      'estimated_price': estimatedPrice,
      'report_url': reportUrl,
    }).select().single();
    return data;
  }

  static Future<void> updateAppraisal({
    required String applicationId,
    double? estimatedPrice,
    String? reportPdfUrl,
    String? signatureData,
  }) async {
    final updates = <String, dynamic>{};
    if (estimatedPrice != null) updates['estimated_price'] = estimatedPrice;
    if (reportPdfUrl != null) updates['report_pdf_url'] = reportPdfUrl;
    if (signatureData != null) {
      updates['signature_data'] = signatureData;
      updates['signed_at'] = DateTime.now().toIso8601String();
    }
    if (updates.isNotEmpty) {
      await supabase
          .from('appraisals')
          .update(updates)
          .eq('application_id', applicationId);
    }
  }

  // ============================================
  // APPRAISER METHODS
  // ============================================

  static Future<List<Map<String, dynamic>>> getAppraiserApplications() async {
    if (userId == null) return [];
    final data = await supabase
        .from('applications')
        .select('*, profiles!applications_appraiser_id_fkey(full_name, email)')
        .eq('appraiser_id', userId!)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(data);
  }

  static Future<List<Map<String, dynamic>>> getAvailableApplications() async {
    final data = await supabase
        .from('applications')
        .select('*, profiles!applications_user_id_fkey(full_name, email, iin)')
        .eq('status', 'new')
        .isFilter('appraiser_id', null)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(data);
  }

  static Future<void> assignApplication(String applicationId) async {
    if (userId == null) return;
    await supabase.from('applications').update({
      'appraiser_id': userId!,
      'status': 'in_progress',
    }).eq('id', applicationId);

    await logActivity(
      action: 'application_assigned',
      entityType: 'application',
      entityId: applicationId,
    );
  }

  static Future<void> updateApplicationStatus(
    String applicationId,
    String status,
  ) async {
    await supabase
        .from('applications')
        .update({'status': status})
        .eq('id', applicationId);
    await logActivity(
      action: 'application_status_changed',
      entityType: 'application',
      entityId: applicationId,
      details: {'new_status': status},
    );
  }

  static Future<List<Map<String, dynamic>>> getAppraiserStats() async {
    if (userId == null) return [];
    final data = await supabase
        .from('applications')
        .select('status')
        .eq('appraiser_id', userId!);
    return List<Map<String, dynamic>>.from(data);
  }

  // ============================================
  // MARKET DATA
  // ============================================

  static Future<List<Map<String, dynamic>>> getMarketData({
    String? type,
    String? source,
    int limit = 50,
  }) async {
    var query = supabase.from('market_data').select();
    if (type != null) query = query.eq('type', type);
    if (source != null) query = query.eq('source', source);
    final data = await query
        .order('parsed_at', ascending: false)
        .limit(limit);
    return List<Map<String, dynamic>>.from(data);
  }

  // ============================================
  // ADMIN METHODS
  // ============================================

  static Future<List<Map<String, dynamic>>> getAllProfiles() async {
    debugPrint('[Admin] getAllProfiles: userId=$userId');
    final data = await supabase
        .from('profiles')
        .select()
        .order('created_at', ascending: false);
    debugPrint('[Admin] getAllProfiles: got ${data.length} profiles');
    return List<Map<String, dynamic>>.from(data);
  }

  static Future<List<Map<String, dynamic>>> getAllApplications() async {
    debugPrint('[Admin] getAllApplications: userId=$userId');
    try {
      final data = await supabase
          .from('applications')
          .select('*, profiles!applications_user_id_fkey(full_name, email, iin), properties(type, address, area)')
          .order('created_at', ascending: false);
      debugPrint('[Admin] getAllApplications: got ${data.length} applications (with joins)');
      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      debugPrint('[Admin] getAllApplications join failed: $e — falling back to simple query');
      final data = await supabase
          .from('applications')
          .select()
          .order('created_at', ascending: false);
      debugPrint('[Admin] getAllApplications: got ${data.length} applications (simple)');
      return List<Map<String, dynamic>>.from(data);
    }
  }

  static Future<void> updateUserRole(String userUserId, String role) async {
    await supabase
        .from('profiles')
        .update({'role': role})
        .eq('user_id', userUserId);
    await logActivity(
      action: 'user_role_changed',
      entityType: 'profile',
      entityId: userUserId,
      details: {'new_role': role},
    );
  }

  static Future<void> toggleUserBlock(String userUserId, bool blocked) async {
    await supabase
        .from('profiles')
        .update({'is_blocked': blocked})
        .eq('user_id', userUserId);
    await logActivity(
      action: blocked ? 'user_blocked' : 'user_unblocked',
      entityType: 'profile',
      entityId: userUserId,
    );
  }

  static Future<void> updateUserProfile(
    String userUserId, {
    String? fullName,
    String? phone,
    String? iin,
    String? email,
    String? role,
  }) async {
    final updates = <String, dynamic>{};
    if (fullName != null) updates['full_name'] = fullName;
    if (phone != null) updates['phone'] = phone;
    if (iin != null) updates['iin'] = iin;
    if (email != null) updates['email'] = email;
    if (role != null) updates['role'] = role;
    if (updates.isNotEmpty) {
      await supabase.from('profiles').update(updates).eq('user_id', userUserId);
      await logActivity(
        action: 'user_profile_updated',
        entityType: 'profile',
        entityId: userUserId,
        details: updates,
      );
    }
  }

  static Future<Map<String, int>> getAdminStats() async {
    debugPrint('[Admin] getAdminStats: userId=$userId');
    final profiles = await supabase.from('profiles').select('id');
    final applications = await supabase.from('applications').select('id, status');
    final appraisers = await supabase
        .from('profiles')
        .select('id')
        .eq('role', 'appraiser');

    final allApps = List<Map<String, dynamic>>.from(applications);
    final completed = allApps.where((a) => a['status'] == 'completed').length;
    final inProgress = allApps.where((a) => a['status'] == 'in_progress').length;

    final stats = {
      'totalUsers': profiles.length,
      'totalApplications': allApps.length,
      'totalAppraisers': appraisers.length,
      'completedApplications': completed,
      'inProgressApplications': inProgress,
    };
    debugPrint('[Admin] getAdminStats: $stats');
    return stats;
  }

  static Future<List<Map<String, dynamic>>> getAdminActivityLogs({
    int limit = 50,
  }) async {
    debugPrint('[Admin] getAdminActivityLogs: userId=$userId');
    try {
      final data = await supabase
          .from('activity_logs')
          .select('*, profiles!activity_logs_user_id_fkey(full_name)')
          .order('created_at', ascending: false)
          .limit(limit);
      debugPrint('[Admin] getAdminActivityLogs: got ${data.length} logs (with joins)');
      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      debugPrint('[Admin] getAdminActivityLogs join failed: $e — falling back to simple query');
      final data = await supabase
          .from('activity_logs')
          .select()
          .order('created_at', ascending: false)
          .limit(limit);
      debugPrint('[Admin] getAdminActivityLogs: got ${data.length} logs (simple)');
      return List<Map<String, dynamic>>.from(data);
    }
  }

  static Future<Map<String, dynamic>?> getApplicationDetail(String id) async {
    try {
      final data = await supabase
          .from('applications')
          .select('*, profiles!applications_user_id_fkey(full_name, email, iin, phone), profiles!applications_appraiser_id_fkey(full_name, email) as appraiser_profile, properties(type, address, area, rooms, floor, total_floors)')
          .eq('id', id)
          .maybeSingle();
      return data;
    } catch (e) {
      debugPrint('[Admin] getApplicationDetail join failed: $e — falling back');
      final data = await supabase
          .from('applications')
          .select('*, properties(type, address, area, rooms, floor, total_floors)')
          .eq('id', id)
          .maybeSingle();
      return data;
    }
  }

  static Future<List<Map<String, dynamic>>> getApplicationDocuments(String userId) async {
    final data = await supabase
        .from('documents')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(data);
  }

  static Future<List<Map<String, dynamic>>> getAllDocuments() async {
    debugPrint('[Admin] getAllDocuments: userId=$userId');
    try {
      final data = await supabase
          .from('documents')
          .select('*, profiles!documents_user_id_fkey(full_name, email)')
          .order('created_at', ascending: false);
      debugPrint('[Admin] getAllDocuments: got ${data.length} documents (with joins)');
      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      debugPrint('[Admin] getAllDocuments join failed: $e — falling back to simple query');
      final data = await supabase
          .from('documents')
          .select()
          .order('created_at', ascending: false);
      debugPrint('[Admin] getAllDocuments: got ${data.length} documents (simple)');
      return List<Map<String, dynamic>>.from(data);
    }
  }

  // ============================================
  // ACTIVITY LOGS
  // ============================================

  static Future<void> logActivity({
    required String action,
    String? entityType,
    String? entityId,
    Map<String, dynamic>? details,
  }) async {
    if (userId == null) return;
    await supabase.from('activity_logs').insert({
      'user_id': userId!,
      'action': action,
      'entity_type': entityType,
      'entity_id': entityId,
      'details': details,
    });
  }

  // ============================================
  // STATS (для home_screen)
  // ============================================

  static Future<Map<String, int>> getStats() async {
    if (userId == null) return {'total': 0, 'inProgress': 0, 'completed': 0};

    final all = await supabase
        .from('applications')
        .select('id')
        .eq('user_id', userId!);

    final inProgress = await supabase
        .from('applications')
        .select('id')
        .eq('user_id', userId!)
        .eq('status', 'in_progress');

    final completed = await supabase
        .from('applications')
        .select('id')
        .eq('user_id', userId!)
        .eq('status', 'completed');

    return {
      'total': all.length,
      'inProgress': inProgress.length,
      'completed': completed.length,
    };
  }

  // ============================================
  // AI CONVERSATIONS
  // ============================================

  static Future<List<Map<String, dynamic>>> getConversations() async {
    final uid = userId;
    if (uid == null) {
      debugPrint('[Supabase] getConversations: userId is null');
      return [];
    }
    try {
      return await supabase
          .from('ai_conversations')
          .select('id, title, updated_at')
          .eq('user_id', uid)
          .order('updated_at', ascending: false);
    } catch (e) {
      debugPrint('[Supabase] getConversations error: $e');
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> getConversation(String id) async {
    final result = await supabase
        .from('ai_conversations')
        .select('id, title, messages')
        .eq('id', id)
        .maybeSingle();
    return result != null ? [result] : [];
  }

  static Future<String> createConversation({
    required String title,
    required List<Map<String, dynamic>> messages,
  }) async {
    final result = await supabase
        .from('ai_conversations')
        .insert({
          'user_id': userId!,
          'title': title,
          'messages': messages,
        })
        .select('id')
        .single();
    return result['id'] as String;
  }

  static Future<void> updateConversation({
    required String id,
    required String title,
    required List<Map<String, dynamic>> messages,
  }) async {
    await supabase
        .from('ai_conversations')
        .update({
          'title': title,
          'messages': messages,
        })
        .eq('id', id);
  }

  static Future<void> deleteConversation(String id) async {
    await supabase
        .from('ai_conversations')
        .delete()
        .eq('id', id);
  }
}
