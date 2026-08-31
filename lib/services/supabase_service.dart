import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
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

  /// JWT-токен текущей сессии (для авторизации в /api/chat и storage).
  static String? get accessToken => supabase.auth.currentSession?.accessToken;

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
    String? clientType,
    String? orgName,
    String? bin,
    String? avatarUrl,
    String? coverUrl,
  }) async {
    if (userId == null) return;
    final updates = <String, dynamic>{};
    if (clientType != null) {
      updates['client_type'] = clientType;
      if (clientType == 'org') {
        updates['iin'] = '';
      } else {
        updates['bin'] = '';
        updates['org_name'] = '';
      }
    }
    if (fullName != null) updates['full_name'] = fullName;
    if (iin != null) updates['iin'] = iin;
    if (phone != null) updates['phone'] = phone;
    if (email != null) updates['email'] = email;
    if (orgName != null) updates['org_name'] = orgName;
    if (bin != null) updates['bin'] = bin;
    if (avatarUrl != null) updates['avatar_url'] = avatarUrl;
    if (coverUrl != null) updates['cover_url'] = coverUrl;
    if (updates.isNotEmpty) {
      await supabase.from('profiles').update(updates).eq('user_id', userId!);
    }
  }

  static Future<String?> uploadProfileAvatar(Uint8List bytes, {String? oldPath}) async {
    if (userId == null) throw Exception('Не авторизован');
    try {
      await ensureStorageBucket();
    } catch (_) {}
    final safeName = 'profile_${userId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final path = _storagePath(safeName);
    await supabase.storage.from(_storageBucket).uploadBinary(
      path,
      bytes,
      fileOptions: const FileOptions(upsert: true, contentType: 'image/jpeg'),
    );

    final signedUrl = await supabase.storage.from(_storageBucket).createSignedUrl(path, 31536000);

    if (oldPath != null && oldPath.isNotEmpty) {
      try {
        String? pathToRemove = oldPath;
        if (oldPath.startsWith('http')) {
          final uri = Uri.tryParse(oldPath);
          final segments = uri?.pathSegments ?? [];
          final signIdx = segments.indexOf('sign');
          final publicIdx = segments.indexOf('public');
          int startIdx = -1;
          if (signIdx != -1 && signIdx + 1 < segments.length) {
            startIdx = signIdx + 1;
          } else if (publicIdx != -1 && publicIdx + 1 < segments.length) {
            startIdx = publicIdx + 1;
          }
          if (startIdx != -1) {
            pathToRemove = segments.sublist(startIdx).join('/');
          }
        }
        if (pathToRemove != null && pathToRemove.isNotEmpty) {
          await supabase.storage.from(_storageBucket).remove([pathToRemove]);
        }
      } catch (_) {}
    }
    return signedUrl;
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
    String? condition,
  }) async {
    final data = await supabase.from('properties').insert({
      'user_id': userId,
      'type': type,
      'address': address,
      'area': area,
      'rooms': rooms,
      'floor': floor,
      'total_floors': totalFloors,
      'condition': condition,
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

  static Future<Map<String, dynamic>> uploadDocument({
    required String fileName,
    required Uint8List bytes,
  }) async {
    if (userId == null) throw Exception('Не авторизован');

    final originalName = fileName;
    final ext = originalName.contains('.')
        ? originalName.substring(originalName.lastIndexOf('.'))
        : '';
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final safeName = '$timestamp$ext';
    final path = _storagePath(safeName);

    await supabase.storage.from(_storageBucket).uploadBinary(
      path,
      bytes,
      fileOptions: const FileOptions(upsert: true),
    );

    final fileSize = bytes.length;
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

  static Future<String> getDocumentUrl(String filePath) async {
    return supabase.storage.from(_storageBucket).createSignedUrl(filePath, 3600);
  }

  /// Вызвать RPC-функцию в Supabase (например, next_report_number()).
  static Future<dynamic> rpc(String fn, [Map<String, dynamic>? params]) async {
    return supabase.rpc(fn, params: params);
  }

  // ============================================
  // REPORT PHOTOS (фото объекта в заявке, до 10)
  // ============================================

  /// Загрузить фото объекта оценки в storage (user-docs/report_photos/).
  /// Возвращает путь в storage (сохраняется в applications.photo_urls).
  static Future<String> uploadReportPhoto({
    required Uint8List bytes,
    String applicationId = 'draft',
    int index = 0,
  }) async {
    final ts = DateTime.now().millisecondsSinceEpoch;
    final path = 'report_photos/${applicationId}_${ts}_$index.jpg';
    await supabase.storage.from(_storageBucket).uploadBinary(
          path,
          bytes,
          fileOptions: const FileOptions(upsert: true, contentType: 'image/jpeg'),
        );
    return path;
  }

  /// Сохранить список путей фото в заявке.
  static Future<void> updateApplicationPhotos(
    String applicationId,
    List<String> paths,
  ) async {
    await supabase
        .from('applications')
        .update({'photo_urls': paths})
        .eq('id', applicationId);
  }

  /// Скачать байты файла из storage по пути (для вставки фото в PDF).
  static Future<Uint8List?> downloadStorageBytes(String filePath) async {
    try {
      final signed = await getDocumentUrl(filePath);
      final resp = await http.get(Uri.parse(signed));
      if (resp.statusCode == 200) return resp.bodyBytes;
    } catch (e) {
      debugPrint('[Storage] download error $filePath: $e');
    }
    return null;
  }

  /// Загрузить фото заявки (пути) и вернуть байты (до 10).
  static Future<List<Uint8List>> loadApplicationPhotos(
    List<dynamic>? photoUrls,
  ) async {
    final out = <Uint8List>[];
    if (photoUrls == null) return out;
    for (final p in photoUrls.take(10)) {
      final bytes = await downloadStorageBytes(p.toString());
      if (bytes != null) out.add(bytes);
    }
    return out;
  }

  /// Удалить файл из storage по пути (игнорирует ошибки).
  static Future<void> deleteStorageFile(String filePath) async {
    try {
      await supabase.storage.from(_storageBucket).remove([filePath]);
    } catch (e) {
      debugPrint('[Storage] delete error $filePath: $e');
    }
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
        .eq('source', 'ai')
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(data);
  }

  static Future<Map<String, dynamic>> createApplication({
    required String propertyId,
    String source = 'manual',
    double? estimatedPrice,
  }) async {
    final data = await supabase.from('applications').insert({
      'user_id': userId,
      'property_id': propertyId,
      'status': 'new',
      'source': source,
      'estimated_price': ?estimatedPrice,
    }).select().single();
    return data;
  }

  /// Прикрепить реальную CMS-подпись (ЭЦП через NCALayer) к заявке.
  ///
  /// Загружает .cms в storage (bucket user-docs) и сохраняет данные
  /// подписанта в таблице applications. Возвращает путь в storage.
  static Future<String> attachCmsSignature({
    required String applicationId,
    required Uint8List cmsBytes,
    required String signerName,
    required String signerIin,
  }) async {
    if (userId == null) throw Exception('Не авторизован');

    final ts = DateTime.now().millisecondsSinceEpoch;
    final path = _storagePath('ecp_signatures/${applicationId}_$ts.cms');

    await supabase.storage.from(_storageBucket).uploadBinary(
          path,
          cmsBytes,
          fileOptions: const FileOptions(upsert: true),
        );

    await supabase.from('applications').update({
      'signature': 'ECP-CMS',
      'signature_path': path,
      'signed_by': userId,
      'signed_at': DateTime.now().toIso8601String(),
      'signer_name': signerName,
      'signer_iin': signerIin,
    }).eq('id', applicationId);

    return path;
  }

  static Future<Map<String, dynamic>> getApplication(String id) async {
    final data = await supabase
        .from('applications')
        .select()
        .eq('id', id)
        .single();

    final propId = data['property_id'] as String?;
    if (propId != null) {
      final propData = await supabase
          .from('properties')
          .select()
          .eq('id', propId)
          .maybeSingle();
      data['properties'] = propData;
    }

    final profilesData = await supabase
        .from('profiles')
        .select('user_id, full_name, iin, bin, org_name, client_type, phone, email')
        .eq('user_id', data['user_id'])
        .maybeSingle();
    data['profiles'] = profilesData;

    return data;
  }

  // ============================================
  // REPORTS (отчёты об оценке, привязанные к заявкам)
  // ============================================

  /// Получить отчёт по заявке (если есть).
  static Future<Map<String, dynamic>?> getReportForApplication(
      String applicationId) async {
    final data = await supabase
        .from('reports')
        .select()
        .eq('application_id', applicationId)
        .maybeSingle();
    return data;
  }

  /// Ссылка на PDF отчёта для скачивания.
  ///
  /// [pathOrUrl] — путь в storage bucket 'reports' (новый формат) или уже
  /// готовый http-URL (старые записи из публичного бакета). Для путей
  /// создаётся временная signed-ссылка (бакет приватный).
  static Future<String> getReportPdfUrl(String pathOrUrl) async {
    if (pathOrUrl.startsWith('http://') || pathOrUrl.startsWith('https://')) {
      return pathOrUrl;
    }
    return supabase.storage.from('reports').createSignedUrl(pathOrUrl, 3600);
  }

  /// Создать черновик отчёта для заявки (status = draft).
  ///
  /// [ownerId] — владелец отчёта (клиент-владелец заявки). По умолчанию —
  /// текущий пользователь (сам клиент создаёт черновик при заказе).
  static Future<Map<String, dynamic>> createReport({
    required String applicationId,
    String? ownerId,
    String? reportNumber,
    Map<String, dynamic>? reportData,
  }) async {
    final data = await supabase.from('reports').insert({
      'application_id': applicationId,
      'user_id': ownerId ?? userId,
      'status': 'draft',
      'report_number': reportNumber,
      'report_data': reportData,
    }).select().single();
    return data;
  }

  /// Обновить отчёт (статус, ссылку на PDF, данные, подпись).
  static Future<void> updateReport(
    String reportId, {
    String? status,
    String? fileUrl,
    String? pdfPath,
    Map<String, dynamic>? reportData,
    String? signerName,
    String? signerIin,
    String? signaturePath,
  }) async {
    final updates = <String, dynamic>{};
    if (status != null) updates['status'] = status;
    if (fileUrl != null) updates['file_url'] = fileUrl;
    if (pdfPath != null) updates['pdf_path'] = pdfPath;
    if (reportData != null) updates['report_data'] = reportData;
    if (signerName != null) updates['signer_name'] = signerName;
    if (signerIin != null) updates['signer_iin'] = signerIin;
    if (signaturePath != null) updates['signature_path'] = signaturePath;
    if (updates.isNotEmpty) {
      await supabase.from('reports').update(updates).eq('id', reportId);
    }
  }

  /// Отметить отчёт как подписанный (после ЭЦП).
  ///
  /// Не понижает статус `paid` → `signed`: оплаченный отчёт уже официальный,
  /// и клиент должен продолжать видеть его как оплаченный.
  static Future<void> markReportSigned(
    String reportId, {
    required String signerName,
    required String signerIin,
    String? signaturePath,
  }) async {
    String? status = 'signed';
    try {
      final row = await supabase
          .from('reports')
          .select('status')
          .eq('id', reportId)
          .maybeSingle();
      if (row != null && row['status'] == 'paid') status = null;
    } catch (_) {}
    await updateReport(
      reportId,
      status: status,
      signerName: signerName,
      signerIin: signerIin,
      signaturePath: signaturePath,
    );
  }

  /// Отметить отчёт как оплаченный (клиент может скачать официальный PDF).
  static Future<void> markReportPaid(String reportId) async {
    await updateReport(reportId, status: 'paid');
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
    final appsData = await supabase
        .from('applications')
        .select()
        .eq('appraiser_id', userId!)
        .eq('source', 'ai')
        .order('created_at', ascending: false);

    debugPrint('[Appraiser] apps count: ${appsData.length}');
    for (final app in appsData) {
      debugPrint('[Appraiser] app ${app['id']}: property_id=${app['property_id']}, status=${app['status']}');
    }

    final profilesData = await supabase.from('profiles').select('user_id, full_name, email');
    final profilesMap = {for (var p in profilesData) p['user_id']: p};

    final propIds = appsData
        .map((a) => a['property_id'] as String?)
        .where((id) => id != null)
        .toSet()
        .toList();
    debugPrint('[Appraiser] property IDs to fetch: $propIds');

    final propsData = propIds.isNotEmpty
        ? await supabase.from('properties').select().inFilter('id', propIds)
        : <Map<String, dynamic>>[];
    debugPrint('[Appraiser] properties fetched: ${propsData.length}');
    for (final p in propsData) {
      debugPrint('[Appraiser] prop ${p['id']}: address=${p['address']}, area=${p['area']}, floor=${p['floor']}');
    }

    final propsMap = {for (var p in propsData) p['id']: p};

    final result = List<Map<String, dynamic>>.from(appsData).map((app) {
      app['profiles'] = profilesMap[app['user_id']];
      app['properties'] = propsMap[app['property_id']];
      return app;
    }).toList();
    return result;
  }

  static Future<List<Map<String, dynamic>>> getAvailableApplications() async {
    final appsData = await supabase
        .from('applications')
        .select()
        .eq('status', 'new')
        .eq('source', 'ai')
        .isFilter('appraiser_id', null)
        .order('created_at', ascending: false);

    debugPrint('[Available] apps count: ${appsData.length}');
    for (final app in appsData) {
      debugPrint('[Available] app ${app['id']}: property_id=${app['property_id']}, user_id=${app['user_id']}');
    }

    final profilesData = await supabase.from('profiles').select('user_id, full_name, email, iin');
    final profilesMap = {for (var p in profilesData) p['user_id']: p};

    final propIds = appsData
        .map((a) => a['property_id'] as String?)
        .where((id) => id != null)
        .toSet()
        .toList();

    final propsData = propIds.isNotEmpty
        ? await supabase.from('properties').select().inFilter('id', propIds)
        : <Map<String, dynamic>>[];
    debugPrint('[Available] properties fetched: ${propsData.length}');
    final propsMap = {for (var p in propsData) p['id']: p};

    final result = List<Map<String, dynamic>>.from(appsData).map((app) {
      app['profiles'] = profilesMap[app['user_id']];
      app['properties'] = propsMap[app['property_id']];
      return app;
    }).toList();
    return result;
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
    final appsData = await supabase
        .from('applications')
        .select()
        .order('created_at', ascending: false);

    final profilesData = await supabase.from('profiles').select('user_id, full_name, email, iin');
    final profilesMap = {for (var p in profilesData) p['user_id']: p};

    final propertiesData = await supabase.from('properties').select('id, type, address, area');
    final propertiesMap = {for (var p in propertiesData) p['id']: p};

    final result = List<Map<String, dynamic>>.from(appsData).map((app) {
      app['profiles'] = profilesMap[app['user_id']];
      if (app['property_id'] != null) {
        app['properties'] = propertiesMap[app['property_id']];
      }
      return app;
    }).toList();

    debugPrint('[Admin] getAllApplications: got ${result.length} applications');
    return result;
  }

  static Future<List<Map<String, dynamic>>> getDocumentsForUser(String userId) async {
    final data = await supabase
        .from('documents')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(data);
  }

  static Future<List<Map<String, dynamic>>> getApplicationsForUser(String userId) async {
    final data = await supabase
        .from('applications')
        .select('*, properties(type, address, area, rooms, floor)')
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(data);
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
    final logsData = await supabase
        .from('activity_logs')
        .select()
        .order('created_at', ascending: false)
        .limit(limit);

    final profilesData = await supabase.from('profiles').select('user_id, full_name');
    final profilesMap = {for (var p in profilesData) p['user_id']: p};

    final result = List<Map<String, dynamic>>.from(logsData).map((log) {
      log['profiles'] = profilesMap[log['user_id']];
      return log;
    }).toList();

    debugPrint('[Admin] getAdminActivityLogs: got ${result.length} logs');
    return result;
  }

  static Future<Map<String, dynamic>?> getApplicationDetail(String id) async {
    final appData = await supabase
        .from('applications')
        .select('*, properties(type, address, area, rooms, floor, total_floors)')
        .eq('id', id)
        .maybeSingle();
    if (appData == null) return null;

    // Fetch owner profile
    if (appData['user_id'] != null) {
      final ownerProfile = await supabase
          .from('profiles')
          .select('full_name, email, iin, phone')
          .eq('user_id', appData['user_id'])
          .maybeSingle();
      appData['profiles'] = ownerProfile;
    }

    // Fetch appraiser profile
    if (appData['appraiser_id'] != null) {
      final appraiserProfile = await supabase
          .from('profiles')
          .select('full_name, email')
          .eq('user_id', appData['appraiser_id'])
          .maybeSingle();
      appData['appraiser_profile'] = appraiserProfile;
    }

    return appData;
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
    final docsData = await supabase
        .from('documents')
        .select()
        .order('created_at', ascending: false);

    final profilesData = await supabase.from('profiles').select('user_id, full_name, email');
    final profilesMap = {for (var p in profilesData) p['user_id']: p};

    final result = List<Map<String, dynamic>>.from(docsData).map((doc) {
      doc['profiles'] = profilesMap[doc['user_id']];
      return doc;
    }).toList();

    debugPrint('[Admin] getAllDocuments: got ${result.length} documents');
    return result;
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
        .eq('user_id', userId!)
        .eq('source', 'ai');

    final inProgress = await supabase
        .from('applications')
        .select('id')
        .eq('user_id', userId!)
        .eq('source', 'ai')
        .eq('status', 'in_progress');

    final completed = await supabase
        .from('applications')
        .select('id')
        .eq('user_id', userId!)
        .eq('source', 'ai')
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

  // ============================================
  // B2B: companies, members, api key requests
  // ============================================

  static Future<Map<String, dynamic>?> getMyCompany() async {
    if (userId == null) return null;
    final rows = await supabase
        .from('companies')
        .select()
        .eq('owner_id', userId!)
        .maybeSingle();
    return rows;
  }

  static Future<Map<String, dynamic>> createCompany({
    required String name,
    required String bin,
    required String contactName,
    required String contactEmail,
    required String contactPhone,
  }) async {
    if (userId == null) throw Exception('Не авторизован');
    final data = await supabase
        .from('companies')
        .insert({
          'name': name,
          'bin': bin,
          'contact_name': contactName,
          'contact_email': contactEmail,
          'contact_phone': contactPhone,
          'owner_id': userId!,
        })
        .select()
        .single();
    return data;
  }

  static Future<Map<String, dynamic>> requestApiKey({
    required String companyId,
    String reason = '',
  }) async {
    if (userId == null) throw Exception('Не авторизован');
    final data = await supabase
        .from('api_key_requests')
        .insert({
          'company_id': companyId,
          'user_id': userId!,
          'reason': reason,
        })
        .select()
        .single();
    return data;
  }

  static Future<List<Map<String, dynamic>>> getMyApiKeyRequests() async {
    if (userId == null) return [];
    final data = await supabase
        .from('api_key_requests')
        .select('*, companies(name, bin)')
        .eq('user_id', userId!)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(data);
  }

  static Future<List<Map<String, dynamic>>> getAllApiKeyRequests() async {
    final data = await supabase
        .from('api_key_requests')
        .select('*, companies(name, bin), profiles(full_name, email)')
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(data);
  }

  static Future<void> approveApiKeyRequest(String requestId) async {
    if (userId == null) throw Exception('Не авторизован');
    await supabase
        .from('api_key_requests')
        .update({
          'status': 'approved',
          'reviewed_by': userId!,
          'reviewed_at': DateTime.now().toIso8601String(),
        })
        .eq('id', requestId);
  }

  static Future<void> rejectApiKeyRequest(String requestId) async {
    if (userId == null) throw Exception('Не авторизован');
    await supabase
        .from('api_key_requests')
        .update({
          'status': 'rejected',
          'reviewed_by': userId!,
          'reviewed_at': DateTime.now().toIso8601String(),
        })
        .eq('id', requestId);
  }

  static Future<List<Map<String, dynamic>>> getAllCompanies() async {
    final data = await supabase
        .from('companies')
        .select('*, profiles(full_name, email)')
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(data);
  }

  static Future<void> updateCompanyStatus(String companyId, String status) async {
    await supabase
        .from('companies')
        .update({'status': status})
        .eq('id', companyId);
  }
}
