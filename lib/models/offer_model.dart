// class OfferImage {
//   final String url;
//   final String actionType; // 'none' | 'internal' | 'external'
//   final String actionValue;

//   const OfferImage({
//     required this.url,
//     required this.actionType,
//     required this.actionValue,
//   });

//   factory OfferImage.fromJson(dynamic json) {
//     if (json is String) {
//       return OfferImage(url: json, actionType: 'none', actionValue: '');
//     }
//     final m = json as Map<String, dynamic>;
//     return OfferImage(
//       url: m['url'] as String? ?? '',
//       actionType: m['actionType'] as String? ?? 'none',
//       actionValue: m['actionValue'] as String? ?? '',
//     );
//   }
// }

// class OfferModel {
//   final String id;
//   final List<OfferImage> images;
//   final int displayOrder;

//   const OfferModel({
//     required this.id,
//     required this.images,
//     required this.displayOrder,
//   });

//   factory OfferModel.fromJson(Map<String, dynamic> json) => OfferModel(
//         id: json['_id'] as String? ?? '',
//         images: (json['images'] as List? ?? [])
//             .map((e) => OfferImage.fromJson(e))
//             .where((e) => e.url.isNotEmpty)
//             .toList(),
//         displayOrder: json['displayOrder'] as int? ?? 0,
//       );
// }
