/// Entity biểu diễn thông tin người dùng được quản lý trên hệ thống
class AppUser {
  final String id; // Firebase UID
  final String email;
  final String displayName;
  final String photoUrl;

  const AppUser({
    required this.id,
    required this.email,
    this.displayName = '',
    this.photoUrl = '',
  });

  String get displayTitle =>
      displayName.isNotEmpty ? displayName : email.split('@').first;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppUser &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          email == other.email;

  @override
  int get hashCode => id.hashCode ^ email.hashCode;

  @override
  String toString() => 'AppUser(id: $id, email: $email, name: $displayName)';
}
