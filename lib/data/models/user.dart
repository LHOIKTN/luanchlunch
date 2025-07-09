class UserProfile {
  final String id;
  final String email;
  final String? nickname;

  UserProfile({required this.id, required this.email, this.nickname});

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      email: json['email'] as String,
      nickname: json['nickname'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'nickname': nickname,
      };
} 