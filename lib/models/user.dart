enum UserRole { admin, guru, siswa }

class UserProfile {
  final String id;
  final String name;
  final String username;
  final String password;
  final UserRole role;
  final String avatar;
  final String? subject; // For guru
  final String? kelas;   // For siswa
  final String? nipNis;  // NIP for guru, NIS for siswa
  final String? position; // Added for student structure roles

  UserProfile({
    required this.id,
    required this.name,
    required this.username,
    required this.password,
    required this.role,
    this.avatar = '',
    this.subject,
    this.kelas,
    this.nipNis,
    this.position,
  });

  UserProfile copyWith({
    String? id,
    String? name,
    String? username,
    String? password,
    UserRole? role,
    String? avatar,
    String? subject,
    String? kelas,
    String? nipNis,
    String? position,
  }) {
    return UserProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      username: username ?? this.username,
      password: password ?? this.password,
      role: role ?? this.role,
      avatar: avatar ?? this.avatar,
      subject: subject ?? this.subject,
      kelas: kelas ?? this.kelas,
      nipNis: nipNis ?? this.nipNis,
      position: position ?? this.position,
    );
  }
}
