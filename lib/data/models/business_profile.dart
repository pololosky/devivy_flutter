class BusinessProfile {
  final String businessName;
  final String address;
  final String? slogan;
  final String? signaturePath; // local file path to PNG
  final String? logoPath;      // local file path to logo image

  const BusinessProfile({
    required this.businessName,
    required this.address,
    this.slogan,
    this.signaturePath,
    this.logoPath,
  });

  bool get hasSignature => signaturePath != null && signaturePath!.isNotEmpty;
  bool get hasLogo => logoPath != null && logoPath!.isNotEmpty;

  BusinessProfile copyWith({
    String? businessName,
    String? address,
    String? slogan,
    String? signaturePath,
    String? logoPath,
  }) =>
      BusinessProfile(
        businessName: businessName ?? this.businessName,
        address: address ?? this.address,
        slogan: slogan ?? this.slogan,
        signaturePath: signaturePath ?? this.signaturePath,
        logoPath: logoPath ?? this.logoPath,
      );

  Map<String, String> toPrefsMap() => {
        'businessName': businessName,
        'address': address,
        'slogan': slogan ?? '',
        'signaturePath': signaturePath ?? '',
        'logoPath': logoPath ?? '',
      };

  factory BusinessProfile.fromPrefsMap(Map<String, String> map) =>
      BusinessProfile(
        businessName: map['businessName'] ?? '',
        address: map['address'] ?? '',
        slogan: map['slogan']?.isEmpty ?? true ? null : map['slogan'],
        signaturePath: map['signaturePath']?.isEmpty ?? true
            ? null
            : map['signaturePath'],
        logoPath: map['logoPath']?.isEmpty ?? true ? null : map['logoPath'],
      );

  static const empty = BusinessProfile(businessName: '', address: '');
}
