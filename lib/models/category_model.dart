class CategoryModel {
  final String id;
  final String categoryName;
  final String? categorySlug;
  final String? description;
  final String? icon;
  final int displayOrder;
  final bool isActive;
  final String? parentCategoryId;
  final double hourlyRate;

  CategoryModel({
    required this.id,
    required this.categoryName,
    this.categorySlug,
    this.description,
    this.icon,
    required this.displayOrder,
    required this.isActive,
    this.parentCategoryId,
     required this.hourlyRate,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['_id'] ?? '',
      categoryName: json['categoryName'] ?? '',
      categorySlug: json['categorySlug'],
      description: json['description'],
      icon: json['icon'],
      displayOrder: json['displayOrder'] ?? 0,
      isActive: json['isActive'] ?? true,
      parentCategoryId: json['parentCategoryId'] is String
          ? json['parentCategoryId']
          : json['parentCategoryId']?['_id'],
      hourlyRate: (json['hourlyRate'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'categoryName': categoryName,
      'categorySlug': categorySlug,
      'description': description,
      'icon': icon,
      'displayOrder': displayOrder,
      'isActive': isActive,
      'parentCategoryId': parentCategoryId,
      'hourlyRate': hourlyRate,
    };
  }
}
