import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class AboutUsScreen extends StatelessWidget {
  const AboutUsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('About Us', style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.textPrimary, letterSpacing: -0.5)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black, size: 22),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        children: [
          const SizedBox(height: 32),
          _buildEliteLogoHeader(),
          const SizedBox(height: 48),
          const Text(
            'OUR STORY',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 1.5),
          ),
          const SizedBox(height: 20),
          _buildStoryCard(
            Icons.flag_rounded,
            'Our Mission',
            'To provide reliable, professional, and affordable home services at your doorstep. We connect you with verified professionals to make your life effortless.',
            Colors.blue,
          ),
          const SizedBox(height: 16),
          _buildStoryCard(
            Icons.verified_rounded,
            'Why Choose Us',
            '• Verified professionals only\n• Transparent pricing model\n• Secure end-to-end payments\n• 24/7 Premium support',
            Colors.green,
          ),
          const SizedBox(height: 40),
          const Text(
            'LEGAL & PRIVACY',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 1.5),
          ),
          const SizedBox(height: 20),
          _buildLegalHub(),
          const SizedBox(height: 40),
          const Text(
            'CONNECT WITH US',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 1.5),
          ),
          const SizedBox(height: 20),
          _buildSocialRow(),
          const SizedBox(height: 60),
          _buildFooter(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildEliteLogoHeader() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,          ),
          child: const Icon(Icons.home_repair_service_rounded, size: 64, color: AppColors.primary),
        ),
        const SizedBox(height: 24),
        const Text(
          'HomeCare Services',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.textPrimary, letterSpacing: -0.5),
        ),
        const SizedBox(height: 6),
        const Text(
          'Version 1.0.0 (Flagship)',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildStoryCard(IconData icon, String title, String content, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(14)),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 16),
              Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.textPrimary)),
            ],
          ),
          const SizedBox(height: 16),
          Text(content, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.grey, height: 1.5)),
        ],
      ),
    );
  }

  Widget _buildLegalHub() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),      ),
      child: Column(
        children: [
          _buildLegalLink('Privacy Policy', Icons.security_rounded),
          _buildLegalLink('Terms of Service', Icons.gavel_rounded),
          _buildLegalLink('Refund & Cancellation', Icons.refresh_rounded),
        ],
      ),
    );
  }

  Widget _buildLegalLink(String title, IconData icon) {
    return InkWell(
      onTap: () {},
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Icon(icon, color: Colors.grey, size: 20),
            const SizedBox(width: 16),
            Expanded(child: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: AppColors.textPrimary))),
            const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildSocialRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildSocialItem(Icons.facebook_rounded, const Color(0xFF1877F2)),
        _buildSocialItem(Icons.camera_alt_rounded, const Color(0xFFE4405F)),
        _buildSocialItem(Icons.play_arrow_rounded, const Color(0xFF1DA1F2)),
        _buildSocialItem(Icons.business_rounded, const Color(0xFF0A66C2)),
      ],
    );
  }

  Widget _buildSocialItem(IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.08), shape: BoxShape.circle),
      child: Icon(icon, color: color, size: 24),
    );
  }

  Widget _buildFooter() {
    return const Column(
      children: [
        Text('© 2024 HomeCare Services', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.grey)),
        SizedBox(height: 6),
        Text('Made with ❤️ in India', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.grey)),
      ],
    );
  }
}
