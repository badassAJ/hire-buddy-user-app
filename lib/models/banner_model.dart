class BannerModel {
  final String id;
  final String? title;
  final String? subtitle;
  final String? imageUrl;
  final double height;
  final double opacity;
  final String titleColor;
  final String subtitleColor;
  final String gradientStart;
  final String gradientEnd;
  final double gradientOpacity;
  final String? linkToCategory;
  final bool isDark;

  BannerModel({
    required this.id,
    this.title,
    this.subtitle,
    this.imageUrl,
    required this.height,
    required this.opacity,
    required this.titleColor,
    required this.subtitleColor,
    required this.gradientStart,
    required this.gradientEnd,
    required this.gradientOpacity,
    this.linkToCategory,
    this.isDark = true,
  });

  factory BannerModel.fromJson(Map<String, dynamic> json) {
    return BannerModel(
      id: json['_id'] ?? '',
      title: json['title'],
      subtitle: json['subtitle'],
      imageUrl: json['imageUrl'],
      height: (json['height'] ?? 220).toDouble(),
      opacity: (json['opacity'] ?? 0.6).toDouble(),
      titleColor: json['titleColor'] ?? '#ffffff',
      subtitleColor: json['subtitleColor'] ?? '#f1f5f9',
      gradientStart: json['gradientStart'] ?? '#000000',
      gradientEnd: json['gradientEnd'] ?? '#000000',
      gradientOpacity: (json['gradientOpacity'] ?? 0.4).toDouble(),
      linkToCategory: json['linkToCategory']?['_id'] ?? json['linkToCategory'],
      isDark: json['isDark'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'title': title,
      'subtitle': subtitle,
      'imageUrl': imageUrl,
      'height': height,
      'opacity': opacity,
      'titleColor': titleColor,
      'subtitleColor': subtitleColor,
      'gradientStart': gradientStart,
      'gradientEnd': gradientEnd,
      'gradientOpacity': gradientOpacity,
      'linkToCategory': linkToCategory,
      'isDark': isDark,
    };
  }
}
