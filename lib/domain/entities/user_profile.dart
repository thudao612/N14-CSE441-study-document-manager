class AppUserProfile {
  final String id;
  final String email;
  final String fullName;
  final String? avatarUrl;
  final bool isAuthenticated;

  const AppUserProfile({
    required this.id,
    required this.email,
    required this.fullName,
    this.avatarUrl,
    this.isAuthenticated = true,
  });

  factory AppUserProfile.demo() {
    return const AppUserProfile(
      id: 'demo-user',
      email: 'demo@student.local',
      fullName: 'Demo Student',
      avatarUrl: null,
      isAuthenticated: true,
    );
  }
}
