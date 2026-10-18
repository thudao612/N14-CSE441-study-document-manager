import '../../domain/entities/app_user.dart';

/// DTO chuyển đổi thông tin người dùng từ bảng users trên Supabase
class AppUserModel {
  final String id;
  final String email;
  final String displayName;
  final String photoUrl;

  const AppUserModel({
    required this.id,
    required this.email,
    this.displayName = '',
    this.photoUrl = '',
  });

  factory AppUserModel.fromJson(Map<String, dynamic> json) {
    return AppUserModel(
      id: json['id'] as String? ?? '',
      email: json['email'] as String? ?? '',
      displayName: json['displayName'] as String? ??
          (json['display_name'] as String? ?? ''),
      photoUrl: json['photoUrl'] as String? ??
          (json['photo_url'] as String? ?? ''),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'display_name': displayName,
      'photo_url': photoUrl,
    };
  }

  AppUser toEntity() {
    return AppUser(
      id: id,
      email: email,
      displayName: displayName,
      photoUrl: photoUrl,
    );
  }
}
