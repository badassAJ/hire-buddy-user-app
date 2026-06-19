class ProductModel {
  final String id;
  final String productName;
  final String? description;
  final ProductPricing pricing;
  final String unit;
  final int? stock;
  final List<String> images;
  final String? categoryId;
  final String? categoryName;
  final bool isActive;
  final String approvalStatus;
  final ProductProvider? provider;

  const ProductModel({
    required this.id,
    required this.productName,
    this.description,
    required this.pricing,
    required this.unit,
    this.stock,
    required this.images,
    this.categoryId,
    this.categoryName,
    required this.isActive,
    required this.approvalStatus,
    this.provider,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    List<String> imgs = [];
    if (json['images'] != null) {
      for (final img in json['images'] as List) {
        if (img is String) imgs.add(img);
        else if (img is Map && img['url'] != null) imgs.add(img['url'] as String);
      }
    }

    return ProductModel(
      id: json['_id'] as String? ?? '',
      productName: json['productName'] as String? ?? '',
      description: json['description'] as String?,
      pricing: ProductPricing.fromJson(json['pricing'] as Map<String, dynamic>? ?? {}),
      unit: json['unit'] as String? ?? 'piece',
      stock: json['stock'] as int?,
      images: imgs,
      categoryId: json['categoryId'] is Map ? (json['categoryId'] as Map)['_id'] as String? : json['categoryId'] as String?,
      categoryName: json['categoryId'] is Map ? (json['categoryId'] as Map)['categoryName'] as String? : null,
      isActive: json['isActive'] as bool? ?? true,
      approvalStatus: json['approvalStatus'] as String? ?? 'approved',
      provider: json['providerId'] is Map
          ? ProductProvider.fromJson(json['providerId'] as Map<String, dynamic>)
          : null,
    );
  }

  String get primaryImage => images.isNotEmpty ? images.first : '';

  Map<String, dynamic> toJson() => {
        '_id': id,
        'productName': productName,
        'description': description,
        'pricing': {
          'basePrice': pricing.basePrice,
          'commissionRate': pricing.commissionRate,
          'commissionAmount': pricing.commissionAmount,
          'finalPrice': pricing.finalPrice,
        },
        'unit': unit,
        'stock': stock,
        'images': images,
        'isActive': isActive,
        'approvalStatus': approvalStatus,
        if (provider != null)
          'providerId': {
            '_id': provider!.id,
            'profile': {'fullName': provider!.fullName},
            'baseCity': provider!.baseCity,
          },
      };
}

class ProductPricing {
  final double basePrice;
  final double commissionRate;
  final double commissionAmount;
  final double finalPrice;

  const ProductPricing({
    required this.basePrice,
    required this.commissionRate,
    required this.commissionAmount,
    required this.finalPrice,
  });

  factory ProductPricing.fromJson(Map<String, dynamic> json) => ProductPricing(
        basePrice: (json['basePrice'] as num?)?.toDouble() ?? 0,
        commissionRate: (json['commissionRate'] as num?)?.toDouble() ?? 0,
        commissionAmount: (json['commissionAmount'] as num?)?.toDouble() ?? 0,
        finalPrice: (json['finalPrice'] as num?)?.toDouble() ?? 0,
      );
}

class ProductProvider {
  final String id;
  final String? fullName;
  final String? baseCity;

  const ProductProvider({required this.id, this.fullName, this.baseCity});

  factory ProductProvider.fromJson(Map<String, dynamic> json) => ProductProvider(
        id: json['_id'] as String? ?? '',
        fullName: (json['profile'] as Map<String, dynamic>?)?['fullName'] as String?,
        baseCity: json['baseCity'] as String?,
      );
}

class AddressModel {
  final String id;
  final String fullAddress;
  final String city;
  final String state;
  final String? flatNumber;
  final String? society;
  final String? landmark;
  final String? addressType;
  final String? nickname;
  final bool isDefault;
  final double? latitude;
  final double? longitude;

  const AddressModel({
    required this.id,
    required this.fullAddress,
    required this.city,
    required this.state,
    this.flatNumber,
    this.society,
    this.landmark,
    this.addressType,
    this.nickname,
    required this.isDefault,
    this.latitude,
    this.longitude,
  });

  String get displayLabel {
    if (nickname != null && nickname!.isNotEmpty) return nickname!;
    switch (addressType?.toLowerCase()) {
      case 'work': return 'Work';
      case 'other': return 'Other';
      default: return 'Home';
    }
  }

  factory AddressModel.fromJson(Map<String, dynamic> json) {
    final parts = <String>[];
    if (json['flatNumber'] != null) parts.add('Flat ${json['flatNumber']}');
    if (json['block'] != null) parts.add('Block ${json['block']}');
    if (json['tower'] != null) parts.add('Tower ${json['tower']}');
    if (json['society'] != null) parts.add(json['society'] as String);
    if (json['landmark'] != null) parts.add(json['landmark'] as String);

    final loc = json['location'] as Map<String, dynamic>?;

    return AddressModel(
      id: json['_id'] as String? ?? '',
      fullAddress: parts.isNotEmpty ? parts.join(', ') : (json['fullAddress'] as String? ?? ''),
      city: json['city'] as String? ?? '',
      state: json['state'] as String? ?? '',
      flatNumber: json['flatNumber'] as String?,
      society: json['society'] as String?,
      landmark: json['landmark'] as String?,
      addressType: json['addressType'] as String?,
      nickname: json['nickname'] as String?,
      isDefault: json['isDefault'] as bool? ?? false,
      latitude: (loc?['latitude'] as num?)?.toDouble(),
      longitude: (loc?['longitude'] as num?)?.toDouble(),
    );
  }
}

class ProductOrder {
  final String id;
  final String orderNumber;
  final String orderStatus;
  final List<OrderItem> items;
  final OrderPricing pricing;
  final String paymentMethod;
  final String paymentStatus;
  final OrderDeliveryAddress? deliveryAddress;
  final String? providerId;
  final String? providerName;
  final DateTime createdAt;

  const ProductOrder({
    required this.id,
    required this.orderNumber,
    required this.orderStatus,
    required this.items,
    required this.pricing,
    required this.paymentMethod,
    required this.paymentStatus,
    this.deliveryAddress,
    this.providerId,
    this.providerName,
    required this.createdAt,
  });

  factory ProductOrder.fromJson(Map<String, dynamic> json) => ProductOrder(
        id: json['_id'] as String? ?? '',
        orderNumber: json['orderNumber'] as String? ?? '',
        orderStatus: json['orderStatus'] as String? ?? 'pending',
        items: (json['items'] as List? ?? [])
            .map((e) => OrderItem.fromJson(e as Map<String, dynamic>))
            .toList(),
        pricing: OrderPricing.fromJson(json['pricing'] as Map<String, dynamic>? ?? {}),
        paymentMethod: (json['payment'] as Map<String, dynamic>?)?['method'] as String? ?? 'cod',
        paymentStatus: (json['payment'] as Map<String, dynamic>?)?['status'] as String? ?? 'pending',
        deliveryAddress: json['deliveryAddress'] is Map
            ? OrderDeliveryAddress.fromJson(json['deliveryAddress'] as Map<String, dynamic>)
            : null,
        providerId: (json['providerId'] is Map)
            ? (json['providerId'] as Map)['_id'] as String?
            : json['providerId'] as String?,
        providerName: (json['providerId'] is Map)
            ? ((json['providerId'] as Map<String, dynamic>)['profile'] != null
                ? ((json['providerId'] as Map<String, dynamic>)['profile'] as Map<String, dynamic>)['fullName'] as String?
                : null)
            : null,
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
      );

  bool get canCancel => orderStatus == 'pending' || orderStatus == 'confirmed';

  String get statusLabel {
    switch (orderStatus) {
      case 'pending': return 'Pending';
      case 'confirmed': return 'Confirmed';
      case 'preparing': return 'Preparing';
      case 'out_for_delivery': return 'Out for Delivery';
      case 'delivered': return 'Delivered';
      case 'cancelled': return 'Cancelled';
      default: return orderStatus;
    }
  }
}

class OrderItem {
  final String productId;
  final String productName;
  final int quantity;
  final double pricePerUnit;
  final double totalPrice;
  final List<String> images;

  const OrderItem({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.pricePerUnit,
    required this.totalPrice,
    required this.images,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    List<String> imgs = [];
    if (json['productId'] is Map) {
      final prod = json['productId'] as Map<String, dynamic>;
      if (prod['images'] != null) {
        for (final img in prod['images'] as List) {
          if (img is String) imgs.add(img);
          else if (img is Map && img['url'] != null) imgs.add(img['url'] as String);
        }
      }
    }
    return OrderItem(
      productId: (json['productId'] is Map)
          ? (json['productId'] as Map)['_id'] as String? ?? ''
          : json['productId'] as String? ?? '',
      productName: json['productName'] as String? ?? '',
      quantity: json['quantity'] as int? ?? 1,
      pricePerUnit: (json['pricePerUnit'] as num?)?.toDouble() ?? 0,
      totalPrice: (json['totalPrice'] as num?)?.toDouble() ?? 0,
      images: imgs,
    );
  }
}

class OrderPricing {
  final double subtotal;
  final double deliveryCharge;
  final double platformCommission;
  final double totalAmount;

  const OrderPricing({
    required this.subtotal,
    required this.deliveryCharge,
    required this.platformCommission,
    required this.totalAmount,
  });

  factory OrderPricing.fromJson(Map<String, dynamic> json) => OrderPricing(
        subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0,
        deliveryCharge: (json['deliveryCharge'] as num?)?.toDouble() ?? 0,
        platformCommission: (json['platformCommission'] as num?)?.toDouble() ?? 0,
        totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0,
      );
}

class OrderDeliveryAddress {
  final String? city;
  final String? state;
  final String? fullAddress;

  const OrderDeliveryAddress({this.city, this.state, this.fullAddress});

  factory OrderDeliveryAddress.fromJson(Map<String, dynamic> json) {
    final parts = <String>[];
    final flatNumber = json['flatNumber'] as String?;
    final flatType = json['flatType'] as String?;
    final block = json['block'] as String?;
    final tower = json['tower'] as String?;
    final society = json['society'] as String?;
    final landmark = json['landmark'] as String?;

    if (flatNumber != null && flatNumber.isNotEmpty) {
      final prefix = (flatType != null && flatType.isNotEmpty) ? flatType : 'Flat';
      parts.add('$prefix $flatNumber');
    }
    if (tower != null && tower.isNotEmpty) parts.add('Tower $tower');
    if (block != null && block.isNotEmpty) parts.add('Block $block');
    if (society != null && society.isNotEmpty) parts.add(society);
    if (landmark != null && landmark.isNotEmpty) parts.add('Near $landmark');

    return OrderDeliveryAddress(
      city: json['city'] as String?,
      state: json['state'] as String?,
      fullAddress: parts.isNotEmpty ? parts.join(', ') : (json['fullAddress'] as String?),
    );
  }

  String get display {
    final parts = <String>[];
    if (fullAddress != null && fullAddress!.isNotEmpty) parts.add(fullAddress!);
    if (city != null && city!.isNotEmpty) parts.add(city!);
    if (state != null && state!.isNotEmpty) parts.add(state!);
    return parts.isEmpty ? 'Address not available' : parts.join(', ');
  }
}
