import 'package:flutter/material.dart';

class LocationProvider extends ChangeNotifier {
  String _addressTitle = '';
  String _addressFull = '';

  String get addressTitle => _addressTitle;
  String get addressFull => _addressFull;

  void setAddress({required String title, required String full}) {
    _addressTitle = title;
    _addressFull = full;
    notifyListeners();
  }
}
