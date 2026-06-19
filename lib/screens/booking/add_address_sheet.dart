import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../../core/theme/app_colors.dart';
import '../../models/saved_address.dart';
import '../../models/product_model.dart'
    show AddressModel; // For global state format matching
import '../../services/address_service.dart';

class AddAddressSheet extends StatefulWidget {
  final VoidCallback onSaved;

  /// Pass an existing SavedAddress to enter edit mode.
  final SavedAddress? existing;

  const AddAddressSheet({super.key, required this.onSaved, this.existing});

  @override
  State<AddAddressSheet> createState() => _AddAddressSheetState();
}

class _AddAddressSheetState extends State<AddAddressSheet> {
  final _mapController = MapController();
  final _flatCtrl = TextEditingController();
  final _landmarkCtrl = TextEditingController();
  final _nicknameCtrl = TextEditingController();
  final _addressService = AddressService();

  Timer? _debounce;

  LatLng _center = const LatLng(28.6139, 77.2090);
  String _addressTitle = '';
  String _addressFull = '';
  String _city = '';
  String _society = '';
  String _saveAs = 'Home'; // Home | Work | Other
  bool _locating = true;
  bool _saving = false;
  bool _mapReady = false;

  @override
  void initState() {
    super.initState();
    _prefillExisting();
  }

  void _prefillExisting() {
    final e = widget.existing;
    if (e != null) {
      _flatCtrl.text = e.flatNumber ?? '';
      _landmarkCtrl.text = e.landmark ?? '';
      _nicknameCtrl.text = e.nickname ?? '';
      _saveAs = e.addressType == 'work'
          ? 'Work'
          : e.addressType == 'other'
          ? 'Other'
          : 'Home';

      if (e.latitude != null && e.longitude != null) {
        _center = LatLng(e.latitude!, e.longitude!);
        _city = e.city;
        _society = e.society ?? '';
        _addressTitle = _society.isNotEmpty ? _society : _city;
        _addressFull = [
          if (e.flatNumber?.isNotEmpty == true) e.flatNumber!,
          if (_society.isNotEmpty) _society,
          if (_city.isNotEmpty) _city,
        ].join(', ');
        _locating = false;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_mapReady) _mapController.move(_center, 16);
        });
      } else {
        _detectGPS();
      }
    } else {
      _detectGPS();
    }
  }

  Future<void> _detectGPS() async {
    if (mounted) setState(() => _locating = true);
    try {
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.whileInUse ||
          perm == LocationPermission.always) {
        final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 8),
        );
        final latlng = LatLng(pos.latitude, pos.longitude);
        if (!mounted) return;
        setState(() => _center = latlng);
        if (_mapReady) _mapController.move(latlng, 16);
        await _reverseGeocode(latlng);
      }
    } catch (_) {}
    if (mounted) setState(() => _locating = false);
  }

  Future<void> _reverseGeocode(LatLng latlng) async {
    try {
      final marks = await placemarkFromCoordinates(
        latlng.latitude,
        latlng.longitude,
      );
      if (marks.isEmpty || !mounted) return;
      final p = marks.first;
      final parts = <String>[
        if (p.thoroughfare?.isNotEmpty == true) p.thoroughfare!,
        if (p.subLocality?.isNotEmpty == true) p.subLocality!,
        if (p.locality?.isNotEmpty == true) p.locality!,
        if (p.administrativeArea?.isNotEmpty == true) p.administrativeArea!,
        if (p.postalCode?.isNotEmpty == true) p.postalCode!,
        if (p.country?.isNotEmpty == true) p.country!,
      ];
      final seen = <String>{};
      setState(() {
        _addressTitle =
            p.thoroughfare ?? p.subLocality ?? p.locality ?? 'Your Location';
        _city = p.locality ?? p.subAdministrativeArea ?? '';
        _society = [
          if (p.thoroughfare?.isNotEmpty == true) p.thoroughfare!,
          if (p.subLocality?.isNotEmpty == true) p.subLocality!,
        ].join(', ');
        _addressFull = parts.where((e) => seen.add(e)).join(', ');
      });
    } catch (_) {}
  }

  void _onPositionChanged(MapCamera camera, bool hasGesture) {
    if (!hasGesture) return;
    final latlng = camera.center;
    setState(() {
      _center = latlng;
      _locating = true;
    });
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 600), () async {
      await _reverseGeocode(latlng);
      if (mounted) setState(() => _locating = false);
    });
  }

  Future<void> _save() async {
    if (_flatCtrl.text.trim().isEmpty) {
      _showSnack('Please enter your house / flat number');
      return;
    }
    if (_saveAs == 'Other' && _nicknameCtrl.text.trim().isEmpty) {
      _showSnack('Please enter a name for this address');
      return;
    }
    setState(() => _saving = true);
    try {
      final type = _saveAs == 'Work'
          ? 'work'
          : _saveAs == 'Other'
          ? 'other'
          : 'home';
      final city = _city.isNotEmpty ? _city : _addressTitle;
      final society = _society.isNotEmpty ? _society : _addressFull;

      dynamic responseResult;

      if (widget.existing != null) {
        responseResult = await _addressService.updateAddress(
          widget.existing!.id,
          addressType: type,
          nickname: _saveAs == 'Other' ? _nicknameCtrl.text.trim() : null,
          city: city,
          society: society,
          flatNumber: _flatCtrl.text.trim(),
          landmark: _landmarkCtrl.text.trim().isNotEmpty
              ? _landmarkCtrl.text.trim()
              : null,
          latitude: _center.latitude,
          longitude: _center.longitude,
        );
      } else {
        responseResult = await _addressService.createAddress(
          addressType: type,
          nickname: _saveAs == 'Other' ? _nicknameCtrl.text.trim() : null,
          city: city,
          society: society,
          flatNumber: _flatCtrl.text.trim(),
          landmark: _landmarkCtrl.text.trim().isNotEmpty
              ? _landmarkCtrl.text.trim()
              : null,
          latitude: _center.latitude,
          longitude: _center.longitude,
        );
      }

      AddressModel? computedReturnAddress;

      if (responseResult != null && responseResult is Map<String, dynamic>) {
        final nestedWrapper = responseResult['data'] ?? {};
        final Map<String, dynamic> actualAddressMap = Map<String, dynamic>.from(
          nestedWrapper is Map && nestedWrapper.containsKey('data')
              ? nestedWrapper['data']
              : responseResult['data'] ?? responseResult,
        );

        final String resFlat =
            actualAddressMap['flatNumber'] ?? _flatCtrl.text.trim();
        final String resSociety = actualAddressMap['society'] ?? society;
        final String combinedString =
            resFlat.isNotEmpty && resSociety.isNotEmpty
            ? '$resFlat, $resSociety'
            : '$resFlat$resSociety';

        computedReturnAddress = AddressModel(
          id: actualAddressMap['id'] ?? actualAddressMap['_id'] ?? '',
          city: actualAddressMap['city'] ?? city,
          state: actualAddressMap['state'] ?? widget.existing?.state ?? '',
          flatNumber: resFlat,
          society: resSociety,
          nickname:
              actualAddressMap['nickname'] ??
              (_saveAs == 'Other' ? _nicknameCtrl.text.trim() : _saveAs),
          addressType: actualAddressMap['addressType'] ?? type,
          landmark: actualAddressMap['landmark'],
          latitude: _center.latitude,
          longitude: _center.longitude,
          isDefault:
              actualAddressMap['isDefault'] ??
              widget.existing?.isDefault ??
              false,
          fullAddress: combinedString,
        );
      } else {
        final String localFlat = _flatCtrl.text.trim();
        final String localCombined = localFlat.isNotEmpty && society.isNotEmpty
            ? '$localFlat, $society'
            : '$localFlat$society';

        computedReturnAddress = AddressModel(
          id: widget.existing?.id ?? '',
          city: city,
          state: widget.existing?.state ?? '',
          flatNumber: localFlat,
          society: society,
          nickname: _saveAs == 'Other' ? _nicknameCtrl.text.trim() : _saveAs,
          addressType: type,
          landmark: _landmarkCtrl.text.trim().isNotEmpty
              ? _landmarkCtrl.text.trim()
              : null,
          latitude: _center.latitude,
          longitude: _center.longitude,
          isDefault: widget.existing?.isDefault ?? false,
          fullAddress: localCombined,
        );
      }

      if (!mounted) return;
      widget.onSaved();

      Navigator.of(context).pop(computedReturnAddress);
    } catch (e) {
      if (mounted) _showSnack(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showSnack(String msg) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(msg),
      backgroundColor: AppColors.error,
      behavior: SnackBarBehavior.floating,
    ),
  );

  @override
  void dispose() {
    _debounce?.cancel();
    _flatCtrl.dispose();
    _landmarkCtrl.dispose();
    _nicknameCtrl.dispose();
    super.dispose();
  }

  // 🌟 FIXED: Loose validation ensures users can save even if GPS/Geocoding is lagging
  bool get _canSave =>
      _flatCtrl.text.trim().isNotEmpty &&
      (_saveAs != 'Other' || _nicknameCtrl.text.trim().isNotEmpty);

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      height: MediaQuery.of(context).size.height * 0.90,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // ── Map ─────────────────────────────────────────────
          SizedBox(
            height: 220,
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(28),
              ),
              child: Stack(
                children: [
                  FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: _center,
                      initialZoom: 16,
                      onMapReady: () {
                        setState(() => _mapReady = true);
                        _mapController.move(_center, 16);
                      },
                      onPositionChanged: _onPositionChanged,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.hirebuddy.app',
                      ),
                    ],
                  ),
                  const Align(
                    alignment: Alignment.center,
                    child: Padding(
                      padding: EdgeInsets.only(bottom: 36),
                      child: Icon(
                        Icons.location_on_rounded,
                        color: Color(0xFF5C35D5),
                        size: 44,
                        shadows: [Shadow(blurRadius: 8, color: Colors.black26)],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 56,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xCC1A1A1A),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Move map to place pin accurately',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 14,
                    bottom: 14,
                    child: GestureDetector(
                      onTap: _detectGPS,
                      child: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.12),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.my_location_rounded,
                          size: 20,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Form ────────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(20, 0, 20, bottom + 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Container(
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ),

                  // Detected address row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                if (_locating) ...[
                                  const SizedBox(
                                    width: 12,
                                    height: 12,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Color(0xFF5C35D5),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                ],
                                Flexible(
                                  child: Text(
                                    _locating
                                        ? 'Detecting...'
                                        : (_addressTitle.isNotEmpty
                                              ? _addressTitle
                                              : 'Move map to set location'),
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF1A1A1A),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            if (_addressFull.isNotEmpty) ...[
                              const SizedBox(height: 3),
                              Text(
                                _addressFull,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[500],
                                  height: 1.4,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton(
                        onPressed: _detectGPS,
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(
                            color: Color(0xFF5C35D5),
                            width: 1.5,
                          ),
                          foregroundColor: const Color(0xFF5C35D5),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text(
                          'Use GPS',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),
                  const Divider(height: 1, color: Color(0xFFF0F0F0)),
                  const SizedBox(height: 20),

                  _Field(
                    controller: _flatCtrl,
                    hint: 'House / Flat Number *',
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 12),
                  _Field(
                    controller: _landmarkCtrl,
                    hint: 'Landmark (Optional)',
                  ),

                  const SizedBox(height: 24),

                  // Save as chips
                  const Text(
                    'Save as',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1A1A1A),
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: ['Home', 'Work', 'Other'].map((label) {
                      final sel = _saveAs == label;
                      return GestureDetector(
                        onTap: () => setState(() => _saveAs = label),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          margin: const EdgeInsets.only(right: 10),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: sel ? const Color(0xFF1A1A1A) : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: sel
                                  ? const Color(0xFF1A1A1A)
                                  : const Color(0xFFE0E0E0),
                              width: 1.5,
                            ),
                          ),
                          child: Text(
                            label,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: sel
                                  ? Colors.white
                                  : const Color(0xFF1A1A1A),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  // Nickname field — shown when "Other" is selected
                  if (_saveAs == 'Other') ...[
                    const SizedBox(height: 16),
                    _Field(
                      controller: _nicknameCtrl,
                      hint: 'Name this address (e.g. Mom\'s house) *',
                      onChanged: (_) => setState(() {}),
                    ),
                  ],

                  const SizedBox(height: 28),

                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: (_saving || !_canSave) ? null : _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _canSave
                            ? const Color(0xFF1A1A1A)
                            : const Color(0xFFE8E8E8),
                        foregroundColor: _canSave ? Colors.white : Colors.grey,
                        disabledBackgroundColor: const Color(0xFFE8E8E8),
                        disabledForegroundColor: Colors.grey,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: _saving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              widget.existing != null
                                  ? 'Update Address'
                                  : 'Save Address',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final ValueChanged<String>? onChanged;

  const _Field({required this.controller, required this.hint, this.onChanged});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(
          color: Color(0xFFB0B0B0),
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        filled: true,
        fillColor: const Color(0xFFF7F7F7),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF1A1A1A), width: 1.5),
        ),
      ),
    );
  }
}
