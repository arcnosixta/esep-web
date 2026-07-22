import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart';

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

  static Future<Map<String, dynamic>?> getProfile() async {
    if (userId == null) return null;
    final data = await supabase
        .from('profiles')
        .select()
        .eq('user_id', userId!)
        .maybeSingle();
    return data;
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
        .select('*, properties(type, address, area)')
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
}
