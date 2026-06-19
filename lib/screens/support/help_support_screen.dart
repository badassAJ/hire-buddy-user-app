import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_colors.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $url');
    }
  }

  Future<void> _launchEmail() async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'support@homecare.com',
      query: 'subject=Help & Support',
    );
    if (!await launchUrl(emailUri)) throw Exception('Could not launch email');
  }

  Future<void> _launchPhone() async {
    final Uri phoneUri = Uri(scheme: 'tel', path: '+911234567890');
    if (!await launchUrl(phoneUri)) throw Exception('Could not launch phone');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Help & Support', style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.textPrimary, letterSpacing: -0.5)),
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
          const SizedBox(height: 24),
          _buildQuickSupports(),
          const SizedBox(height: 48),
          const Text(
            'FREQUENTLY ASKED QUESTIONS',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 1.5),
          ),
          const SizedBox(height: 24),
          _buildFAQItem('How do I book a service?', 'Browse services on the home screen, select the service you need, choose date & time, and confirm your booking.'),
          _buildFAQItem('Can I cancel my booking?', 'Yes, you can cancel your booking from the My Bookings screen before the service provider is assigned.'),
          _buildFAQItem('How do I track my booking?', 'Go to My Bookings tab to see all your active, completed, and cancelled bookings with real-time status updates.'),
          _buildFAQItem('What payment methods are accepted?', 'We accept cash on delivery and online payments through UPI, cards, and net banking.'),
          _buildFAQItem('What if I\'m not satisfied?', 'Contact our support team immediately. We\'ll resolve your issue or arrange a free re-service.'),
          const SizedBox(height: 40),
          _buildStillNeedHelp(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildQuickSupports() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildSupportCircle(Icons.chat_bubble_rounded, 'Chat', Colors.teal, () => _launchUrl('https://wa.me/911234567890')),
        _buildSupportCircle(Icons.phone_rounded, 'Call', Colors.green, _launchPhone),
        _buildSupportCircle(Icons.email_rounded, 'Mail', Colors.blue, _launchEmail),
        _buildSupportCircle(Icons.support_agent_rounded, 'FAQ', Colors.purple, () {}),
      ],
    );
  }

  Widget _buildSupportCircle(IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 10),
          Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: AppColors.textPrimary)),
        ],
      ),
    );
  }

  Widget _buildFAQItem(String question, String answer) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),      ),
      child: Theme(
        data: ThemeData(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          title: Text(question, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: AppColors.textPrimary)),
          iconColor: AppColors.primary,
          collapsedIconColor: Colors.grey,
          children: [
            Text(answer, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.grey, height: 1.5)),
          ],
        ),
      ),
    );
  }

  Widget _buildStillNeedHelp() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        children: [
          const Text('Still Need Assistance?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.textPrimary)),
          const SizedBox(height: 8),
          const Text('Our experts are available 24/7 to help you with your queries.', textAlign: TextAlign.center, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.grey)),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: _launchPhone,
            child: Container(
              height: 54,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(18),              ),
              child: const Center(
                child: Text('Speak with an Expert', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
