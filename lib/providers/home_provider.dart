import 'package:flutter/material.dart';
import '../models/banner_model.dart';
import '../models/category_model.dart';
import '../models/service_model.dart';
import '../services/api_service.dart';
import '../services/service_service.dart';
import '../core/constants/api_constants.dart';

class HomeProvider extends ChangeNotifier {
  final ServiceService _serviceService = ServiceService();
  final ApiService _api = ApiService();

  List<BannerModel> _banners = [];
  List<CategoryModel> _mainCategories = [];
  List<CategoryModel> _allCategories = [];
  List<ServiceModel> _popularServices = [];
   String _offersDisplayType = 'carousel';
  List<Map<String, dynamic>> _topReviews = [];
  bool _isLoading = false;
  String? _error;

  List<BannerModel> get banners => _banners;
  List<CategoryModel> get mainCategories => _mainCategories;
  List<CategoryModel> get allCategories => _allCategories;
  List<ServiceModel> get popularServices => _popularServices;

  String get offersDisplayType => _offersDisplayType;
  List<Map<String, dynamic>> get topReviews => _topReviews;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchHomeData() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _serviceService.getBanners(),
        _serviceService.getCategories(includeSubcategories: true),
        _fetchPopularServices(),
        _fetchTopReviews(),
 
      ]);

      final bannerResult = results[0];
      final categoriesResult = results[1];

      if (bannerResult['success'] == true) {
        _banners = (bannerResult['data']['data'] as List)
            .map((json) => BannerModel.fromJson(json))
            .toList();
      }

      if (categoriesResult['success'] == true) {
        _allCategories = (categoriesResult['data']['data'] as List)
            .map((json) => CategoryModel.fromJson(json))
            .where((cat) => cat.isActive)
            .toList();
        _mainCategories = _allCategories
            .where((cat) => cat.parentCategoryId == null)
            .toList();
        _mainCategories.sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
      }
    } catch (e) {
      _error = e.toString();
      debugPrint('HomeProvider Error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }





  Future<Map<String, dynamic>> _fetchPopularServices() async {
    try {
      final res = await _api.get(ApiConstants.popularServices);
      final data = res.data as Map<String, dynamic>;
      if (data['success'] == true) {
        _popularServices = (data['data'] as List)
            .map((json) => ServiceModel.fromJson(json as Map<String, dynamic>))
            .where((s) => s.isActive)
            .toList();
      }
    } catch (e) {
      debugPrint('Popular services fetch error: $e');
    }
    return {'success': true};
  }

  Future<Map<String, dynamic>> _fetchTopReviews() async {
    try {
      final res = await _api.get(ApiConstants.topReviews);
      final data = res.data as Map<String, dynamic>;
      if (data['success'] == true) {
        _topReviews = List<Map<String, dynamic>>.from(data['data'] ?? []);
      }
    } catch (e) {
      debugPrint('Top reviews fetch error: $e');
    }
    return {'success': true};
  }

 
}
