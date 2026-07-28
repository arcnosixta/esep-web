enum UserRole { client, appraiser, admin }

class UserProfile {
  final String id;
  final String userId;
  final String fullName;
  final String iin;
  final String phone;
  final String email;
  final UserRole role;
  final String? avatarUrl;
  final bool isBlocked;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserProfile({
    required this.id,
    required this.userId,
    required this.fullName,
    required this.iin,
    required this.phone,
    required this.email,
    required this.role,
    this.avatarUrl,
    this.isBlocked = false,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      fullName: json['full_name'] as String? ?? '',
      iin: json['iin'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      email: json['email'] as String? ?? '',
      role: _parseRole(json['role'] as String?),
      avatarUrl: json['avatar_url'] as String?,
      isBlocked: json['is_blocked'] as bool? ?? false,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at'] as String? ?? '') ?? DateTime.now(),
    );
  }

  static UserRole _parseRole(String? role) {
    switch (role) {
      case 'appraiser':
        return UserRole.appraiser;
      case 'admin':
        return UserRole.admin;
      default:
        return UserRole.client;
    }
  }

  String get initials {
    if (fullName.isEmpty) return '?';
    final parts = fullName.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return fullName.substring(0, fullName.length.clamp(0, 2)).toUpperCase();
  }

  String get roleLabel {
    switch (role) {
      case UserRole.client:
        return 'Клиент';
      case UserRole.appraiser:
        return 'Оценщик';
      case UserRole.admin:
        return 'Администратор';
    }
  }
}
