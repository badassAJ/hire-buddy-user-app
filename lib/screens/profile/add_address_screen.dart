import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../services/user_service.dart';

class AddAddressScreen extends StatefulWidget {
  final bool isEditing;

  const AddAddressScreen({super.key, required this.isEditing});

  @override
  State<AddAddressScreen> createState() => _AddAddressScreenState();
}

class _AddAddressScreenState extends State<AddAddressScreen> {
  final _formKey = GlobalKey<FormState>();
  final _cityController = TextEditingController();
  final _societyController = TextEditingController();
  final _blockController = TextEditingController();
  final _towerController = TextEditingController();
  final _flatNumberController = TextEditingController();
  final _landmarkController = TextEditingController();

  String? _selectedFlatType;
  double? _latitude;
  double? _longitude;
  String? _detectedAddress;
  bool _isLoading = false;
  bool _isFetchingLocation = false;

  final List<String> _flatTypes = ['1BHK', '2BHK', '3BHK', '4BHK', '5BHK', 'Villa', 'Studio'];

  @override
  void initState() {
    super.initState();
    if (widget.isEditing) _loadCurrentAddress();
  }

  @override
  void dispose() {
    _cityController.dispose();
    _societyController.dispose();
    _blockController.dispose();
    _towerController.dispose();
    _flatNumberController.dispose();
    _landmarkController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentAddress() async {
    final user = Provider.of<AuthProvider>(context, listen: false).currentUser;
    if (user?.address != null) {
      final address = user!.address!;
      setState(() {
        _cityController.text = address.city;
        _societyController.text = address.street;
        if (address.block != null) _blockController.text = address.block!;
        if (address.tower != null) _towerController.text = address.tower!;
        if (address.flatNumber != null) _flatNumberController.text = address.flatNumber!;
        if (address.flatType != null) _selectedFlatType = address.flatType;
        if (address.landmark != null) _landmarkController.text = address.landmark!;
        if (address.location?.coordinates != null && address.location!.coordinates.length >= 2) {
          _latitude = address.location!.coordinates[1];
          _longitude = address.location!.coordinates[0];
        }
      });
      if (_latitude != null && _longitude != null) await _getAddressFromCoordinates(_latitude!, _longitude!);
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isFetchingLocation = true);
    try {
      final status = await Permission.location.request();
      if (!status.isGranted) throw Exception('Location permission denied');
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
      });
      await _getAddressFromCoordinates(position.latitude, position.longitude);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Location detected successfully!', style: TextStyle(fontWeight: FontWeight.w700)),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString()),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } finally {
      setState(() => _isFetchingLocation = false);
    }
  }

  Future<void> _getAddressFromCoordinates(double latitude, double longitude) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(latitude, longitude);
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        setState(() {
          _detectedAddress = '${place.name}, ${place.street}, ${place.subLocality}';
          if (_cityController.text.isEmpty) _cityController.text = place.locality ?? '';
          if (_societyController.text.isEmpty) _societyController.text = place.name ?? place.street ?? '';
        });
      }
    } catch (e) { print(e); }
  }

  Future<void> _saveAddress() async {
    if (!_formKey.currentState!.validate()) return;
    if (_latitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please detect your location first'), backgroundColor: AppColors.warning, behavior: SnackBarBehavior.floating));
      return;
    }
    setState(() => _isLoading = true);
    try {
      final userService = UserService();
      final result = await userService.updateAddress(
        city: _cityController.text.trim(),
        society: _societyController.text.trim(),
        block: _blockController.text.trim(),
        tower: _towerController.text.trim(),
        flatNumber: _flatNumberController.text.trim(),
        flatType: _selectedFlatType,
        landmark: _landmarkController.text.trim(),
        latitude: _latitude,
        longitude: _longitude,
      );
      if (result['success'] == true && mounted) {
        await Provider.of<AuthProvider>(context, listen: false).loadCurrentUser();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Address saved successfully!'), backgroundColor: AppColors.success, behavior: SnackBarBehavior.floating));
        Navigator.pop(context, true);
      }
    } catch (e) { print(e); } finally { setState(() => _isLoading = false); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Edit Address' : 'New Address', style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.textPrimary, letterSpacing: -0.5)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black, size: 22),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          children: [
            const SizedBox(height: 24),
            _buildLocationCard(),
            const SizedBox(height: 40),
            const Text('PROPERTY DETAILS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 1.5)),
            const SizedBox(height: 20),
            _buildModernField(controller: _cityController, hint: 'City Name', icon: Icons.location_city_rounded, required: true),
            const SizedBox(height: 16),
            _buildModernField(controller: _societyController, hint: 'Society / Building Name', icon: Icons.apartment_rounded, required: true),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildModernField(controller: _blockController, hint: 'Block', icon: Icons.grid_view_rounded)),
                const SizedBox(width: 12),
                Expanded(child: _buildModernField(controller: _towerController, hint: 'Tower', icon: Icons.business_rounded)),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildModernField(controller: _flatNumberController, hint: 'Flat No.', icon: Icons.door_front_door_rounded)),
                const SizedBox(width: 12),
                Expanded(child: _buildTypeDropdown()),
              ],
            ),
            const SizedBox(height: 16),
            _buildModernField(controller: _landmarkController, hint: 'Landmark (Optional)', icon: Icons.place_rounded, maxLines: 2),
            const SizedBox(height: 48),
            _buildSaveButton(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16)),
                child: const Icon(Icons.my_location_rounded, color: AppColors.primary, size: 24),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Text('Current Location', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.textPrimary)),
              ),
              if (_latitude != null) const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 20),
            ],
          ),
          if (_detectedAddress != null) ...[
            const SizedBox(height: 20),
            Text(_detectedAddress!, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.grey, height: 1.4)),
          ],
          const SizedBox(height: 24),
          GestureDetector(
            onTap: _isFetchingLocation ? null : _getCurrentLocation,
            child: Container(
              height: 52,
              decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(18),),
              child: Center(
                child: _isFetchingLocation 
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text(_latitude != null ? 'Update Location' : 'Pin Auto Location', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernField({required TextEditingController controller, required String hint, required IconData icon, bool required = false, int maxLines = 1}) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.textPrimary, fontSize: 15),
      validator: required ? (v) => v!.isEmpty ? 'Required' : null : null,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w500),
        prefixIcon: Icon(icon, color: AppColors.primary, size: 22),
        filled: true,
        fillColor: Colors.grey[50],
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(vertical: 18),
      ),
    );
  }

  Widget _buildTypeDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(20)),
      child: DropdownButtonFormField<String>(
        value: _selectedFlatType,
        decoration: const InputDecoration(border: InputBorder.none, prefixIcon: Icon(Icons.home_rounded, color: AppColors.primary, size: 22)),
        hint: const Text('Type', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500)),
        items: _flatTypes.map((t) => DropdownMenuItem(value: t, child: Text(t, style: const TextStyle(fontWeight: FontWeight.w800)))).toList(),
        onChanged: (v) => setState(() => _selectedFlatType = v),
      ),
    );
  }

  Widget _buildSaveButton() {
    return GestureDetector(
      onTap: _isLoading ? null : _saveAddress,
      child: Container(
        height: 58,
        decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(20),),
        child: Center(
          child: _isLoading 
            ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : const Text('Save Address Details', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
        ),
      ),
    );
  }
}
