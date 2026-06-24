// import 'dart:convert';
// import 'package:flutter/material.dart';
// import '../models/product_model.dart';
// import '../services/storage_service.dart';

// class CartItem {
//   final ProductModel product;
//   int quantity;

//   CartItem({required this.product, this.quantity = 1});
// }

// class CartProvider extends ChangeNotifier {
//   final List<CartItem> _items = [];
//   String? _vendorId;
//   bool _loaded = false;

//   CartProvider() {
//     _loadCart();
//   }

//   List<CartItem> get items => List.unmodifiable(_items);
//   String? get vendorId => _vendorId;
//   bool get isEmpty => _items.isEmpty;
//   int get totalItems => _items.fold(0, (s, i) => s + i.quantity);

//   double get totalAmount =>
//       _items.fold(0.0, (s, i) => s + i.product.pricing.finalPrice * i.quantity);

//   int quantityOf(String productId) =>
//       _items.where((i) => i.product.id == productId).fold(0, (s, i) => s + i.quantity);

//   bool isFromDifferentVendor(ProductModel product) =>
//       _vendorId != null && _vendorId != product.provider?.id;

//   bool addItem(ProductModel product) {
//     if (isFromDifferentVendor(product)) return false;

//     _vendorId = product.provider?.id;
//     final idx = _items.indexWhere((i) => i.product.id == product.id);
//     if (idx >= 0) {
//       _items[idx].quantity++;
//     } else {
//       _items.add(CartItem(product: product));
//     }
//     notifyListeners();
//     _saveCart();
//     return true;
//   }

//   void removeItem(String productId) {
//     _items.removeWhere((i) => i.product.id == productId);
//     if (_items.isEmpty) _vendorId = null;
//     notifyListeners();
//     _saveCart();
//   }

//   void decreaseQuantity(String productId) {
//     final idx = _items.indexWhere((i) => i.product.id == productId);
//     if (idx < 0) return;
//     if (_items[idx].quantity <= 1) {
//       removeItem(productId);
//     } else {
//       _items[idx].quantity--;
//       notifyListeners();
//       _saveCart();
//     }
//   }

//   void clearCart() {
//     _items.clear();
//     _vendorId = null;
//     notifyListeners();
//     _saveCart();
//   }

//   List<Map<String, dynamic>> toOrderItems() =>
//       _items.map((i) => {'productId': i.product.id, 'quantity': i.quantity}).toList();

//   /// Clears the cart and populates it with items from a previous order.
//   void reorderItems(List<OrderItem> items, String? vendorId) {
//     _items.clear();
//     _vendorId = vendorId;
//     for (final item in items) {
//       final product = ProductModel(
//         id: item.productId,
//         productName: item.productName,
//         pricing: ProductPricing(
//           basePrice: item.pricePerUnit,
//           commissionRate: 0,
//           commissionAmount: 0,
//           finalPrice: item.pricePerUnit,
//         ),
//         unit: 'piece',
//         images: item.images,
//         isActive: true,
//         approvalStatus: 'approved',
//         provider: vendorId != null ? ProductProvider(id: vendorId) : null,
//       );
//       _items.add(CartItem(product: product, quantity: item.quantity));
//     }
//     notifyListeners();
//     _saveCart();
//   }

//   Future<void> _saveCart() async {
//     final storage = StorageService();
//     final data = json.encode({
//       'vendorId': _vendorId,
//       'items': _items.map((i) => {
//         'quantity': i.quantity,
//         'product': i.product.toJson(),
//       }).toList(),
//     });
//     await storage.saveCart(data);
//   }

//   Future<void> _loadCart() async {
//     if (_loaded) return;
//     _loaded = true;
//     try {
//       final storage = StorageService();
//       final raw = await storage.getCart();
//       if (raw == null || raw.isEmpty) return;
//       final data = json.decode(raw) as Map<String, dynamic>;
//       _vendorId = data['vendorId'] as String?;
//       final itemsList = data['items'] as List? ?? [];
//       for (final entry in itemsList) {
//         final product = ProductModel.fromJson(
//             entry['product'] as Map<String, dynamic>);
//         final qty = entry['quantity'] as int? ?? 1;
//         _items.add(CartItem(product: product, quantity: qty));
//       }
//       notifyListeners();
//     } catch (_) {
//       // corrupt data — start fresh
//       await StorageService().clearCart();
//     }
//   }
// }
