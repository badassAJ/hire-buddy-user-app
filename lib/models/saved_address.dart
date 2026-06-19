class SavedAddress {
  final String id;
  final String addressType; // home | work | other
  final String? nickname;
  final String city;
  final String? state;
  final String? society;
  final String? flatNumber;
  final String? landmark;
  final double? latitude;
  final double? longitude;
  final bool isDefault;

  const SavedAddress({
    required this.id,
    required this.addressType,
    this.nickname,
    required this.city,
    this.society,
    this.flatNumber,
    this.landmark,
    this.state,
    this.latitude,
    this.longitude,
    this.isDefault = false,
  });

  factory SavedAddress.fromJson(Map<String, dynamic> json) {
    final loc = json['location'] as Map<String, dynamic>?;
    return SavedAddress(
      id: json['_id'] as String,
      addressType: json['addressType'] as String? ?? 'home',
      nickname: json['nickname'] as String?,
      city: json['city'] as String? ?? '',
      state: json['state'] as String? ?? '',
      society: json['society'] as String?,
      flatNumber: json['flatNumber'] as String?,
      landmark: json['landmark'] as String?,
      latitude: (loc?['latitude'] as num?)?.toDouble(),
      longitude: (loc?['longitude'] as num?)?.toDouble(),
      isDefault: json['isDefault'] as bool? ?? false,
    );
  }

  String get label {
    if (nickname != null && nickname!.isNotEmpty) return nickname!;
    switch (addressType) {
      case 'home': return 'Home';
      case 'work': return 'Work';
      default: return 'Other';
    }
  }

  String get displayLine {
    final parts = <String>[
      if (flatNumber?.isNotEmpty == true) flatNumber!,
      if (society?.isNotEmpty == true) society!,
      if (city.isNotEmpty) city,
    ];
    return parts.join(', ');
  }
}
