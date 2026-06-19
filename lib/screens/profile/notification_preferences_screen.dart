import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../services/user_service.dart';

class NotificationPreferencesScreen extends StatefulWidget {
  const NotificationPreferencesScreen({super.key});

  @override
  State<NotificationPreferencesScreen> createState() => _NotificationPreferencesScreenState();
}

class _NotificationPreferencesScreenState extends State<NotificationPreferencesScreen> {
  final UserService _userService = UserService();

  bool _loading = true;
  bool _saving = false;
  String? _error;

  bool _bookingUpdates = true;
  bool _promoOffers = true;
  bool _paymentUpdates = true;
  bool _systemAlerts = true;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final result = await _userService.getNotificationPreferences();
    if (!mounted) return;
    if (result['success'] == true && result['data'] != null) {
      final data = result['data'] as Map<String, dynamic>;
      setState(() {
        _bookingUpdates = data['bookingUpdates'] ?? true;
        _promoOffers    = data['promoOffers']    ?? true;
        _paymentUpdates = data['paymentUpdates'] ?? true;
        _systemAlerts   = data['systemAlerts']   ?? true;
        _loading = false;
      });
    } else {
      setState(() {
        _error = result['error'] ?? 'Failed to load preferences';
        _loading = false;
      });
    }
  }

  Future<void> _toggle(String key, bool value) async {
    setState(() => _saving = true);

    final result = await _userService.updateNotificationPreferences({key: value});

    if (!mounted) return;
    if (result['success'] == true) {
      setState(() {
        switch (key) {
          case 'bookingUpdates': _bookingUpdates = value; break;
          case 'promoOffers':    _promoOffers    = value; break;
          case 'paymentUpdates': _paymentUpdates = value; break;
          case 'systemAlerts':   _systemAlerts   = value; break;
        }
        _saving = false;
      });
    } else {
      setState(() => _saving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['error'] ?? 'Failed to update'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Notifications',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.black, letterSpacing: -0.5),
        ),
        actions: [
          if (_saving) const Padding(
            padding: EdgeInsets.only(right: 16),
            child: Center(child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary))),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_error!, style: const TextStyle(color: Colors.grey)),
                      const SizedBox(height: 16),
                      TextButton(onPressed: _loadPreferences, child: const Text('Retry')),
                    ],
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    const Text(
                      'Choose which notifications you want to receive as push alerts on your device.',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey, height: 1.5),
                    ),
                    const SizedBox(height: 28),
                    _buildSection('BOOKINGS & SERVICES', [
                      _buildTile(
                        icon: Icons.calendar_today_outlined,
                        iconColor: AppColors.primary,
                        title: 'Booking Updates',
                        subtitle: 'Status changes, provider assignment, completion',
                        value: _bookingUpdates,
                        onChanged: (v) => _toggle('bookingUpdates', v),
                      ),
                    ]),
                    const SizedBox(height: 24),
                    _buildSection('PAYMENTS', [
                      _buildTile(
                        icon: Icons.payment_outlined,
                        iconColor: const Color(0xFF10B981),
                        title: 'Payment Updates',
                        subtitle: 'Receipts, refunds, and transaction alerts',
                        value: _paymentUpdates,
                        onChanged: (v) => _toggle('paymentUpdates', v),
                      ),
                    ]),
                    const SizedBox(height: 24),
                    _buildSection('OFFERS & PROMOTIONS', [
                      _buildTile(
                        icon: Icons.local_offer_outlined,
                        iconColor: Colors.orange,
                        title: 'Promo & Offers',
                        subtitle: 'Discounts, deals, and special campaigns',
                        value: _promoOffers,
                        onChanged: (v) => _toggle('promoOffers', v),
                      ),
                    ]),
                    const SizedBox(height: 24),
                    _buildSection('SYSTEM', [
                      _buildTile(
                        icon: Icons.notifications_outlined,
                        iconColor: Colors.purple,
                        title: 'System Alerts',
                        subtitle: 'Account changes and important app updates',
                        value: _systemAlerts,
                        onChanged: (v) => _toggle('systemAlerts', v),
                      ),
                    ]),
                  ],
                ),
    );
  }

  Widget _buildSection(String label, List<Widget> tiles) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 1.5),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: AppColors.grey50,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.grey100),
          ),
          child: Column(children: tiles),
        ),
      ],
    );
  }

  Widget _buildTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.black87)),
                const SizedBox(height: 3),
                Text(subtitle, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey)),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: _saving ? null : onChanged,
            activeColor: AppColors.primary,
          ),
        ],
      ),
    );
  }
}
