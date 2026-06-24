import 'package:flutter/material.dart';
import 'package:hirebuddy/screens/home/home_screen.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../onboarding_screen.dart';
import 'edit_profile_screen.dart';
import 'manage_address_screen.dart';
import 'notification_preferences_screen.dart';
import '../support/help_support_screen.dart';
import '../about/about_us_screen.dart';
import 'disputes_screen.dart';
import '../../services/app_review_service.dart';
import '../../widgets/rate_app_dialog.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ScrollController _scrollController = ScrollController();

  void _handleLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Logout', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: -0.5)),
        content: const Text('Are you sure you want to exit your session?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w800)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Logout', style: TextStyle(fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.logout();

      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const OnboardingScreen()),
          (route) => false,
        );
      }
    }
  }

  void _handleDeleteAccount(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Delete Account', style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.error)),
        content: const Text('Are you sure you want to delete your account? This action is permanent and cannot be undone. All your data will be permanently removed.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w800)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Delete', style: TextStyle(fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator(color: AppColors.error)),
      );

      final success = await authProvider.deleteAccount();

      if (context.mounted) {
        Navigator.pop(context); // Remove loading indicator

        if (success) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const OnboardingScreen()),
            (route) => false,
          );
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Account deleted successfully'),
              backgroundColor: Colors.black,
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(authProvider.error ?? 'Failed to delete account'),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildSliverHeader(context, user),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  const Text(
                    'MY ACTIVITY',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 1.5),
                  ),
                  const SizedBox(height: 20),
                  _buildModernMenuItem(
                    icon: Icons.shopping_bag_outlined,
                    title: 'My Bookings',
                    subtitle: 'Track and manage your bookings',
                    iconColor: const Color(0xFF10B981),
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HomeScreen())), //booking screen
                  ),
                  const SizedBox(height: 40),
                  const Text(
                    'PERSONAL SETTINGS',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 1.5),
                  ),
                  const SizedBox(height: 20),
                  _buildProfileMenu(context),
                  const SizedBox(height: 40),
                  const Text(
                    'MORE OPTIONS',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 1.5),
                  ),
                  const SizedBox(height: 20),
                  _buildMoreMenu(context),
                   const SizedBox(height: 32),
                  _buildLogoutButton(context),
                  const SizedBox(height: 16),
                  _buildDeleteAccountButton(context),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }

  Widget _buildSliverHeader(BuildContext context, dynamic user) {
    return SliverAppBar(
      expandedHeight: 260,
      pinned: true,
      elevation: 0,
      backgroundColor: Colors.white,
      leading: Navigator.canPop(context) 
        ? IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black, size: 22), 
            onPressed: () => Navigator.pop(context),
          ) 
        : const SizedBox(width: 24),
      flexibleSpace: LayoutBuilder(
        builder: (context, constraints) {
          final double percentage = ((constraints.maxHeight - kToolbarHeight) / (260 - kToolbarHeight)).clamp(0.0, 1.0);
          
          return FlexibleSpaceBar(
            centerTitle: false,
            titlePadding: EdgeInsets.lerp(
              const EdgeInsets.only(left: 16, bottom: 10), // Collapsed padding
              const EdgeInsets.only(left: 0, bottom: 0), // Expanded padding (not used due to stack)
              percentage,
            ),
            title: percentage < 0.2 // show title only when collapsed enough
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                      backgroundImage: user?.avatar != null ? NetworkImage(user!.avatar!) : null,
                      child: user?.avatar == null
                          ? Text(
                              user?.fullName?.isNotEmpty == true ? user!.fullName![0].toUpperCase() : 'U',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: AppColors.primary),
                            )
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.fullName ?? 'Guest User',
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.textPrimary, letterSpacing: -0.5),
                        ),
                        Text(
                          user?.mobileNumber != null ? '+91 ${user!.mobileNumber}' : 'Let\'s complete your profile',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.grey),
                        ),
                      ],
                    ),
                  ],
                )
              : null,
            background: Container(
              color: Colors.white,
              child: Opacity(
                opacity: percentage,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 40),
                    Stack(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,                          ),
                          child: CircleAvatar(
                            radius: 56,
                            backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                            backgroundImage: user?.avatar != null ? NetworkImage(user!.avatar!) : null,
                            child: user?.avatar == null
                                ? Text(
                                    user?.fullName?.isNotEmpty == true ? user!.fullName![0].toUpperCase() : 'U',
                                    style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w900, color: AppColors.primary),
                                  )
                                : null,
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 4,
                          child: GestureDetector(
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const EditProfileScreen())),
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 4),                              ),
                              child: const Icon(Icons.edit_rounded, color: Colors.white, size: 20),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text(
                      user?.fullName ?? 'Guest User',
                      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: AppColors.textPrimary, letterSpacing: -1.0),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user?.mobileNumber != null ? '+91 ${user!.mobileNumber}' : 'Let\'s complete your profile',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileMenu(BuildContext context) {
    return Column(
      children: [
        _buildModernMenuItem(
          icon: Icons.person_outline_rounded,
          title: 'Personal Info',
          subtitle: 'Update your name and profile photo',
          iconColor: Colors.blue,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const EditProfileScreen())),
        ),
        const SizedBox(height: 16),
        const SizedBox(height: 16),
        _buildModernMenuItem(
          icon: Icons.location_on_outlined,
          title: 'My Addresses',
          subtitle: 'Manage your saved work and home locations',
          iconColor: Colors.orange,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ManageAddressScreen())),
        ),
        const SizedBox(height: 16),
        _buildModernMenuItem(
          icon: Icons.notifications_outlined,
          title: 'Notification Settings',
          subtitle: 'Choose what alerts you receive',
          iconColor: Colors.purple,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const NotificationPreferencesScreen())),
        ),
      ],
    );
  }

  Widget _buildMoreMenu(BuildContext context) {
    return Column(
      children: [
        _buildModernMenuItem(
          icon: Icons.gavel_rounded,
          title: 'Disputes',
          subtitle: 'Track and respond to your disputes',
          iconColor: Colors.orange,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const DisputesScreen())),
        ),
        const SizedBox(height: 16),
        _buildModernMenuItem(
          icon: Icons.star_rate_rounded,
          title: 'Rate the App',
          subtitle: 'Tell us how we’re doing',
          iconColor: Colors.amber,
          onTap: () => _openRateApp(context),
        ),
        const SizedBox(height: 16),
        _buildModernMenuItem(
          icon: Icons.help_outline_rounded,
          title: 'Help & Support',
          subtitle: 'FAQs and direct support chat',
          iconColor: Colors.purple,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const HelpSupportScreen())),
        ),
        const SizedBox(height: 16),
        _buildModernMenuItem(
          icon: Icons.verified_user_outlined,
          title: 'Privacy Policy',
          subtitle: 'Your data and security info',
          iconColor: Colors.teal,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AboutUsScreen())),
        ),
      ],
    );
  }

  Future<void> _openRateApp(BuildContext context) async {
    final status = await AppReviewService().getStatus();
    if (!context.mounted) return;
    await RateAppDialog.show(
      context,
      initialRating: status?.currentRating,
      initialComment: status?.currentComment,
    );
  }

  Widget _buildModernMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(26),        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(icon, color: iconColor, size: 26),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.textPrimary)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.grey)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return GestureDetector(
      onTap: () => _handleLogout(context),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 22),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(26),
        ),
        child: const Center(
          child: Text(
            'Logout from Account',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.error),
          ),
        ),
      ),
    );
  }
  Widget _buildDeleteAccountButton(BuildContext context) {
    return GestureDetector(
      onTap: () => _handleDeleteAccount(context),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 22),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: AppColors.error.withValues(alpha: 0.2)),
        ),
        child: const Center(
          child: Text(
            'Delete my account permanently',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.error, decoration: TextDecoration.underline),
          ),
        ),
      ),
    );
  }
}
