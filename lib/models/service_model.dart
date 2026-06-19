class ServiceModel {
  final String id;
  final String serviceName;
  final String? serviceSlug;
  final String? description;
  final CategoryInfo? categoryId;
  final PricingInfo? pricing;
  final List<ServiceImage> images;
  final bool isActive;
  final DateTime? createdAt;
  final double avgRating;
  final int totalRatings;

  ServiceModel({
    required this.id,
    required this.serviceName,
    this.serviceSlug,
    this.description,
    this.categoryId,
    this.pricing,
    this.images = const [],
    required this.isActive,
    this.createdAt,
    this.avgRating = 0.0,
    this.totalRatings = 0,
  });

  factory ServiceModel.fromJson(Map<String, dynamic> json) {
    final stats = json['stats'] as Map<String, dynamic>?;
    return ServiceModel(
      id: json['_id'] ?? '',
      serviceName: json['serviceName'] ?? '',
      serviceSlug: json['serviceSlug'],
      description: json['description'],
      categoryId: json['categoryId'] != null
          ? CategoryInfo.fromJson(json['categoryId'])
          : null,
      pricing: json['pricing'] != null
          ? PricingInfo.fromJson(json['pricing'])
          : null,
      images: json['images'] != null
          ? (json['images'] as List)
                .map((img) => ServiceImage.fromJson(img))
                .toList()
          : [],
      isActive: json['isActive'] ?? true,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
      avgRating: (stats?['avgRating'] ?? 0).toDouble(),
      totalRatings: (stats?['totalRatings'] ?? 0).toInt(),
    );
  }

  String? get primaryImageUrl {
    final primary = images.where((img) => img.isPrimary).firstOrNull;
    return primary?.url ?? images.firstOrNull?.url;
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'serviceName': serviceName,
      'serviceSlug': serviceSlug,
      'description': description,
      'categoryId': categoryId?.toJson(),
      'pricing': pricing?.toJson(),
      'images': images.map((img) => img.toJson()).toList(),
      'isActive': isActive,
      'createdAt': createdAt?.toIso8601String(),
    };
  }
}

class CategoryInfo {
  final String id;
  final String categoryName;
  final ParentCategoryInfo? parentCategoryId;

  CategoryInfo({
    required this.id,
    required this.categoryName,
    this.parentCategoryId,
  });

  factory CategoryInfo.fromJson(Map<String, dynamic> json) {
    return CategoryInfo(
      id: json['_id'] ?? '',
      categoryName: json['categoryName'] ?? '',
      parentCategoryId: json['parentCategoryId'] != null
          ? ParentCategoryInfo.fromJson(json['parentCategoryId'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'categoryName': categoryName,
      'parentCategoryId': parentCategoryId?.toJson(),
    };
  }
}

class ParentCategoryInfo {
  final String id;
  final String categoryName;

  ParentCategoryInfo({required this.id, required this.categoryName});

  factory ParentCategoryInfo.fromJson(Map<String, dynamic> json) {
    return ParentCategoryInfo(
      id: json['_id'] ?? '',
      categoryName: json['categoryName'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'_id': id, 'categoryName': categoryName};
  }
}

class PricingInfo {
  final double basePrice;
  final double retailPrice;

  PricingInfo({required this.basePrice, required this.retailPrice});

  factory PricingInfo.fromJson(Map<String, dynamic> json) {
    return PricingInfo(
      basePrice: (json['basePrice'] ?? 0).toDouble(),
      retailPrice: (json['retailPrice'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {'basePrice': basePrice, 'retailPrice': retailPrice};
  }
}

class ServiceImage {
  final String url;
  final bool isPrimary;
  final int displayOrder;

  ServiceImage({
    required this.url,
    required this.isPrimary,
    required this.displayOrder,
  });

  factory ServiceImage.fromJson(Map<String, dynamic> json) {
    return ServiceImage(
      url: json['url'] ?? '',
      isPrimary: json['isPrimary'] ?? false,
      displayOrder: json['displayOrder'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {'url': url, 'isPrimary': isPrimary, 'displayOrder': displayOrder};
  }
}
