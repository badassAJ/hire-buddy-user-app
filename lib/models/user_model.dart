class UserModel {
  final String id;
  final String name;
  final String phone;
  final String role;
  final String? profilePhoto;
  final bool isActive;
  final AddressModel? address;
  final bool isSuspended;
  final String? email;

  String? get avatar => profilePhoto;
  String get fullName => name;
  String get mobileNumber => phone;

  UserModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.role,
    this.address,
    this.profilePhoto,
    this.email,
    required this.isActive,
    required this.isSuspended,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? json['_id'] ?? '',
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      role: json['role'] ?? 'user',
      profilePhoto: json['profilePhoto'],
      email: json['email'],
      isActive: json['isActive'] ?? true,
      isSuspended: json['isSuspended'] ?? false,
      // Maps the address sub-object safely if the backend provides it
      address: json['address'] != null 
          ? AddressModel.fromJson(json['address']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'phone': phone,
      'role': role,
      'profilePhoto': profilePhoto,
      'email': email,
      'isActive': isActive,
      'isSuspended': isSuspended,
      'address': address?.toJson(),
    };
  }
}

class AddressModel {
  final String city;
  final String street; // Maps to 'society' field from backend
  final String? block;
  final String? tower;
  final String? flatNumber;
  final String? flatType;
  final String? landmark;
  final LocationModel? location;

  AddressModel({
    required this.city,
    required this.street,
    this.block,
    this.tower,
    this.flatNumber,
    this.flatType,
    this.landmark,
    this.location,
  });

  // NEW: Factory parser for the address structure
  factory AddressModel.fromJson(Map<String, dynamic> json) {
    return AddressModel(
      city: json['city'] ?? '',
      // Falls back to checking both 'street' and your backend's 'society' field name safely
      street: json['street'] ?? json['society'] ?? '', 
      block: json['block'],
      tower: json['tower'],
      flatNumber: json['flatNumber'] ?? json['flatNo'], // Gracefully covers common backend variations
      flatType: json['flatType'],
      landmark: json['landmark'],
      // Feeds the geolocation sub-object safely directly to your LocationModel constructor
      location: json['location'] != null 
          ? LocationModel.fromJson(json['location']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'city': city,
      'society': street, // Sends 'society' back to match what the backend expects
      'block': block,
      'tower': tower,
      'flatNumber': flatNumber,
      'flatType': flatType,
      'landmark': landmark,
      'location': location?.toJson(),
    };
  }
}


class LocationModel {
  final String type;
  final List<double> coordinates;

  LocationModel({this.type = 'Point', required this.coordinates});

  factory LocationModel.fromJson(Map<String, dynamic> json) {
    // Handle both formats: coordinates array OR latitude/longitude fields
    List<double> coords;
    if (json['coordinates'] != null && json['coordinates'] is List) {
      coords = List<double>.from(json['coordinates']);
    } else if (json['latitude'] != null && json['longitude'] != null) {
      // Backend format fallback: [longitude, latitude]
      coords = [
        (json['longitude'] as num).toDouble(),
        (json['latitude'] as num).toDouble(),
      ];
    } else {
      coords = [0.0, 0.0];
    }

    return LocationModel(type: json['type'] ?? 'Point', coordinates: coords);
  }

  Map<String, dynamic> toJson() {
    return {'type': type, 'coordinates': coordinates};
  }
}