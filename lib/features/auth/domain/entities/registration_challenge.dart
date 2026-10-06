class RegistrationChallenge {
  final String email;
  final int expiresIn;
  final int resendAfter;

  const RegistrationChallenge({
    required this.email,
    required this.expiresIn,
    required this.resendAfter,
  });

  factory RegistrationChallenge.fromJson(Map<String, dynamic> json) {
    return RegistrationChallenge(
      email: json['email'] as String? ?? '',
      expiresIn: (json['expiresIn'] as num?)?.toInt() ?? 600,
      resendAfter: (json['resendAfter'] as num?)?.toInt() ?? 60,
    );
  }
}
