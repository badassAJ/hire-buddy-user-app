class BookingModel {
  final String id;
  final String bookingNumber;
  final String userId;
  final ServiceInfo? serviceId;
  final CategoryInfo? categoryId;
  final ProviderInfo? providerId;
  final String bookingStatus;
  final DateTime scheduledDateTime;
  final String? scheduledTimeSlot;
  final PricingInfo? pricing;
  final PaymentInfo? payment;
  final AddressSnapshot? addressSnapshot;
  final DateTime createdAt;
  final String? completionOtp;

  BookingModel({
    required this.id,
    required this.bookingNumber,
    required this.userId,
    this.serviceId,
    this.categoryId,
    this.providerId,
    required this.bookingStatus,
    required this.scheduledDateTime,
    this.scheduledTimeSlot,
    this.pricing,
    this.payment,
    this.addressSnapshot,
    required this.createdAt,
    this.completionOtp,
  });

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    return BookingModel(
      id: json['_id'] ?? '',
      bookingNumber: json['bookingNumber'] ?? '',
      userId: json['userId'] ?? '',
      serviceId: json['serviceId'] != null
          ? ServiceInfo.fromJson(json['serviceId'])
          : null,
      categoryId: json['categoryId'] != null
          ? CategoryInfo.fromJson(json['categoryId'])
          : null,
      providerId: json['providerId'] != null
          ? ProviderInfo.fromJson(json['providerId'])
          : null,
      bookingStatus: json['bookingStatus'] ?? 'pending',
      scheduledDateTime: DateTime.parse(
        json['scheduledDateTime'] ?? DateTime.now().toIso8601String(),
      ),
      scheduledTimeSlot: json['scheduledTimeSlot'],
      pricing: json['pricing'] != null
          ? PricingInfo.fromJson(json['pricing'])
          : null,
      payment: json['payment'] != null
          ? PaymentInfo.fromJson(json['payment'])
          : null,
      addressSnapshot: json['addressSnapshot'] != null
          ? AddressSnapshot.fromJson(json['addressSnapshot'])
          : null,
      createdAt: DateTime.parse(
        json['createdAt'] ?? DateTime.now().toIso8601String(),
      ),
      completionOtp: json['completionOtp'] as String?,
    );
  }

  String get statusLabel {
    switch (bookingStatus) {
      case 'pending':
        return 'Pending';
      case 'searching_provider':
        return 'Searching Provider';
      case 'provider_assigned':
        return 'Provider Assigned';
      case 'provider_on_the_way':
        return 'Provider On The Way';
      case 'work_started':
        return 'Work Started';
      case 'completed':
        return 'Completed';
      case 'cancelled_by_user':
        return 'Cancelled';
      case 'cancelled_by_provider':
        return 'Cancelled by Provider';
      default:
        return bookingStatus;
    }
  }


  String get displayCategoryName {
  return serviceId?.serviceName ??
      categoryId?.categoryName ??
      "Service";
}

String get buddyName {
  return providerId?.fullName ?? "Buddy Assigned";
}

String get buddyInitials {
  final name = providerId?.fullName ?? "Buddy";
  final parts = name.trim().split(' ');

  if (parts.length >= 2) {
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  return parts.first.substring(0, 1).toUpperCase();
}

double get rating {
  return providerId?.averageRating ?? 4.8;
}

String get bookingType {
  return bookingStatus == "pending"
      ? "Pre-booked"
      : "Scheduled";
}
}

class ServiceInfo {
  final String id;
  final String serviceName;
  final List<ServiceImage>? images;

  ServiceInfo({required this.id, required this.serviceName, this.images});

  factory ServiceInfo.fromJson(Map<String, dynamic> json) {
    return ServiceInfo(
      id: json['_id'] ?? '',
      serviceName: json['serviceName'] ?? '',
      images: json['images'] != null
          ? (json['images'] as List)
                .map((img) => ServiceImage.fromJson(img))
                .toList()
          : null,
    );
  }

  String? get primaryImageUrl {
    if (images == null || images!.isEmpty) return null;
    final primary = images!.where((img) => img.isPrimary).firstOrNull;
    return primary?.url ?? images!.first.url;
  }
}

class ServiceImage {
  final String url;
  final bool isPrimary;

  ServiceImage({required this.url, required this.isPrimary});

  factory ServiceImage.fromJson(Map<String, dynamic> json) {
    return ServiceImage(
      url: json['url'] ?? '',
      isPrimary: json['isPrimary'] ?? false,
    );
  }
}

class CategoryInfo {
  final String id;
  final String categoryName;

  CategoryInfo({required this.id, required this.categoryName});

  factory CategoryInfo.fromJson(Map<String, dynamic> json) {
    return CategoryInfo(
      id: json['_id'] ?? '',
      categoryName: json['categoryName'] ?? '',
    );
  }
}

class ProviderInfo {
  final String? fullName;
  final String? mobileNumber;
  final double? averageRating;
  final int? totalRatings;

  ProviderInfo({this.fullName, this.mobileNumber, this.averageRating, this.totalRatings});

  factory ProviderInfo.fromJson(Map<String, dynamic> json) {
    // Check if nested in 'profile' or 'stats' which backend often does
    final profile = json['profile'] as Map<String, dynamic>?;
    final stats = json['stats'] as Map<String, dynamic>?;

    return ProviderInfo(
      fullName: profile?['fullName'] ?? json['fullName'],
      mobileNumber: json['mobileNumber'],
      averageRating: (stats?['averageRating'] ?? json['averageRating'] ?? 0).toDouble(),
      totalRatings: stats?['totalRatings'] ?? json['totalRatings'] ?? 0,
    );
  }
}

class PricingInfo {
  final double totalAmount;
  final double servicePrice;
  final double tax;
  final double platformCommission;
  final double providerCommission;

  PricingInfo({
    required this.totalAmount,
    required this.servicePrice,
    required this.tax,
    this.platformCommission = 0,
    this.providerCommission = 0,
  });

  factory PricingInfo.fromJson(Map<String, dynamic> json) {
    return PricingInfo(
      totalAmount: (json['totalAmount'] ?? 0).toDouble(),
      servicePrice: (json['servicePrice'] ?? 0).toDouble(),
      tax: (json['tax'] ?? 0).toDouble(),
      platformCommission: (json['platformCommission'] ?? 0).toDouble(),
      providerCommission: (json['providerCommission'] ?? 0).toDouble(),
    );
  }
}

class PaymentInfo {
  final String method;
  final String status;

  PaymentInfo({required this.method, required this.status});

  factory PaymentInfo.fromJson(Map<String, dynamic> json) {
    return PaymentInfo(
      method: json['method'] ?? 'cash',
      status: json['status'] ?? 'pending',
    );
  }
}

class AddressSnapshot {
  final String? city;
  final String? society;
  final String? flatNumber;
  final String? flatType;
  final String? block;
  final String? tower;
  final String? landmark;

  AddressSnapshot({
    this.city,
    this.society,
    this.flatNumber,
    this.flatType,
    this.block,
    this.tower,
    this.landmark,
  });

  factory AddressSnapshot.fromJson(Map<String, dynamic> json) {
    return AddressSnapshot(
      city: json['city'],
      society: json['society'],
      flatNumber: json['flatNumber'],
      flatType: json['flatType'],
      block: json['block'],
      tower: json['tower'],
      landmark: json['landmark'],
    );
  }

  String get fullAddress {
    final parts = <String>[];
    if (flatNumber != null && flatNumber!.isNotEmpty) {
      final prefix = flatType != null && flatType!.isNotEmpty ? flatType! : 'Flat';
      parts.add('$prefix $flatNumber');
    }
    if (tower != null && tower!.isNotEmpty) parts.add('Tower $tower');
    if (block != null && block!.isNotEmpty) parts.add('Block $block');
    if (society != null && society!.isNotEmpty) parts.add(society!);
    if (landmark != null && landmark!.isNotEmpty) parts.add('Near $landmark');
    if (city != null && city!.isNotEmpty) parts.add(city!);
    return parts.isEmpty ? 'Address not available' : parts.join(', ');
  }
}
