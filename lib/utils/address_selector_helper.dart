import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/product_model.dart' show AddressModel;
import '../../providers/location_provider.dart';
import '../screens/booking/saved_address_picker_sheet.dart';

class AddressSelectorHelper {
  static Future<void> selectOrAddAddress(BuildContext context) async {
    // 1. Launch your pre-existing sheet layout
    final AddressModel? pickedAddress = await showSavedAddressPicker(context);

    if (pickedAddress != null && context.mounted) {
      final locationProvider = Provider.of<LocationProvider>(
        context,
        listen: false,
      );

      // 2. Extract nickname or fallback to address type text
      final String shortTitle = pickedAddress.nickname?.isNotEmpty == true
          ? pickedAddress.nickname!
          : pickedAddress.addressType ?? 'Location';

      // 3. Compile full presentation address string
      final String flat = pickedAddress.flatNumber?.isNotEmpty == true
          ? '${pickedAddress.flatNumber}, '
          : '';
      final String society = pickedAddress.society?.isNotEmpty == true
          ? '${pickedAddress.society}, '
          : '';
      final String city = pickedAddress.city;

      final String stateStr = pickedAddress.state.isNotEmpty
          ? ', ${pickedAddress.state}'
          : '';

      final String computedFullAddress = '$flat$society$city$stateStr'.trim();

      // 4. Update the global provider variables to refresh the Home Screen instantly
      locationProvider.setAddress(title: shortTitle, full: computedFullAddress);

      // 5. Success confirmation toast overlay
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Address switched to "$shortTitle"'),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }
}
