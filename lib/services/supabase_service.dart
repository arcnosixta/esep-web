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
    return await supabase.auth.signUp(
      email: email,
      password: password,
      data: {
        'full_name': fullName,
        'phone': phone,
      },
    );
  }

  static Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  static Future<void> signOut() async {
    await supabase.auth.signOut();
  }

  static Stream<AuthState> get authStateChanges =>
      supabase.auth.onAuthStateChange;

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

  static Future<List<Map<String, dynamic>>> getDocuments() async {
    if (userId == null) return [];
    final data = await supabase
        .from('documents')
        .select()
        .eq('user_id', userId!)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(data);
  }

  static Future<Map<String, dynamic>> addDocument({
    String? propertyId,
    required String name,
    required String fileUrl,
    required String fileType,
    double? fileSize,
  }) async {
    final data = await supabase.from('documents').insert({
      'user_id': userId,
      'property_id': propertyId,
      'name': name,
      'file_url': fileUrl,
      'file_type': fileType,
      'file_size': fileSize,
    }).select().single();
    return data;
  }

  static Future<void> deleteDocument(String id) async {
    await supabase.from('documents').delete().eq('id', id);
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
