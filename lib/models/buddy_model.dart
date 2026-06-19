class BuddyModel {
  final String id;

  final String? fullName;
  final String? profilePhoto;
  final String? city;

  final String? bio;

  final bool isOnline;

  final double rating;
  final int totalRatings;
  final int totalTasksCompleted;

  final double acceptanceRate;

  final List<ApprovedCategory> approvedCategories;

  final GeoLocation? currentLocation;

  BuddyModel({
    required this.id,
    this.fullName,
    this.profilePhoto,
    this.city,
    this.bio,
    required this.isOnline,
    required this.rating,
    required this.totalRatings,
    required this.totalTasksCompleted,
    required this.acceptanceRate,
    required this.approvedCategories,
    this.currentLocation,
  });

  factory BuddyModel.fromJson(Map<String, dynamic> json) {
    return BuddyModel(
      id: json['_id'] ?? '',

      fullName: json['fullName'],
      profilePhoto: json['profilePhoto'],
      city: json['city'],

      bio: json['bio'],

      isOnline: json['isOnline'] ?? false,

      rating: (json['rating'] ?? 0).toDouble(),
      totalRatings: json['totalRatings'] ?? 0,
      totalTasksCompleted: json['totalTasksCompleted'] ?? 0,

      acceptanceRate:
          (json['acceptanceRate'] ?? 0).toDouble(),

      approvedCategories:
          json['approvedCategories'] != null
              ? (json['approvedCategories'] as List)
                    .map(
                      (e) =>
                          ApprovedCategory.fromJson(e),
                    )
                    .toList()
              : [],

      currentLocation:
          json['currentLocation'] != null
              ? GeoLocation.fromJson(
                  json['currentLocation'],
                )
              : null,
    );
  }

  String get initials {
  final name = fullName?.trim();

  if (name == null || name.isEmpty) {
    return "B";
  }

  final parts = name.split(' ');

  if (parts.length >= 2) {
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  return parts.first[0].toUpperCase();
}
}


class ApprovedCategory {
  final String categoryId;
  final String status;
  final DateTime? approvedAt;

  ApprovedCategory({
    required this.categoryId,
    required this.status,
    this.approvedAt,
  });

  factory ApprovedCategory.fromJson(
    Map<String, dynamic> json,
  ) {
    return ApprovedCategory(
      categoryId: json['categoryId'] ?? '',
      status: json['status'] ?? '',
      approvedAt: json['approvedAt'] != null
          ? DateTime.parse(json['approvedAt'])
          : null,
    );
  }
}



class GeoLocation {
  final double latitude;
  final double longitude;

  GeoLocation({
    required this.latitude,
    required this.longitude,
  });

  factory GeoLocation.fromJson(
    Map<String, dynamic> json,
  ) {
    final coords = json['coordinates'] ?? [];

    return GeoLocation(
      longitude: coords[0] ?? 0,
      latitude: coords[1] ?? 0,
    );
  }
}