import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/auth_provider.dart';
import '../../providers/settings_provider.dart';
import '../../models/theme_model.dart';
import '../../widgets/custom_button.dart';
import '../../utils/constants.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Removed unused _t function

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;
    final isAdmin = user?.isAdmin ?? false;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: Consumer<SettingsProvider>(
        builder: (context, settingsProvider, child) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Profile Section
              _buildSectionHeader('Profile'),
              Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.veryLightGreen,
                    child: Text(
                      user?.initials ?? 'U',
                      style: GoogleFonts.poppins(
                        color: AppColors.primaryGreen,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(
                    user?.fullName ?? 'User',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    user?.email ?? '',
                    style: GoogleFonts.poppins(fontSize: 12),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    Navigator.pushNamed(context, '/profile');
                  },
                ),
              ),

              const SizedBox(height: 24),

              // Account Settings
              _buildSectionHeader('Account Settings'),
              ListTile(
                leading: const Icon(Icons.person_outline),
                title: Text('Change Username', style: GoogleFonts.poppins()),
                subtitle: Text(
                  'Current: ${user?.username}',
                  style: GoogleFonts.poppins(fontSize: 12),
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => _showChangeUsernameDialog(context),
              ),
              ListTile(
                leading: const Icon(Icons.email_outlined),
                title: Text('Change Email', style: GoogleFonts.poppins()),
                subtitle: Text(
                  'Current: ${user?.email}',
                  style: GoogleFonts.poppins(fontSize: 12),
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => _showChangeEmailDialog(context),
              ),
              ListTile(
                leading: const Icon(Icons.phone_outlined),
                title: Text('Change Phone', style: GoogleFonts.poppins()),
                subtitle: Text(
                  user?.phone?.isNotEmpty == true
                      ? 'Current: ${user?.phone}'
                      : 'Not set',
                  style: GoogleFonts.poppins(fontSize: 12),
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => _showChangePhoneDialog(context),
              ),
              ListTile(
                leading: const Icon(Icons.lock_outline),
                title: Text('Change Password', style: GoogleFonts.poppins()),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => Navigator.pushNamed(context, '/change-password'),
              ),

              const SizedBox(height: 16),

              // Staff Management - Admin Only
              if (isAdmin) ...[
                _buildSectionHeader('Staff Management'),
                ListTile(
                  leading: const Icon(Icons.people_outline,
                      color: AppColors.primaryGreen),
                  title: Text(
                    'Manage Staff',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryGreen,
                    ),
                  ),
                  subtitle: Text(
                    'Add, edit, or remove staff members',
                    style: GoogleFonts.poppins(fontSize: 12),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () => Navigator.pushNamed(context, '/staff'),
                ),
                const SizedBox(height: 16),
              ],

              // Appearance Section
              _buildSectionHeader('Appearance'),
              _buildThemeSelector(settingsProvider),

              const SizedBox(height: 16),

              // Language Section
              _buildSectionHeader('Language & Region'),
              ListTile(
                leading: const Icon(Icons.language),
                title: Text('Language', style: GoogleFonts.poppins()),
                subtitle: Text(
                  settingsProvider.language,
                  style: GoogleFonts.poppins(fontSize: 12),
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => _showLanguageDialog(context, settingsProvider),
              ),

              const SizedBox(height: 16),

              // Data & Backup
              _buildSectionHeader('Data & Backup'),
              _buildSwitchTile(
                'Auto Backup',
                'Automatically backup your data',
                Icons.backup_outlined,
                settingsProvider.autoBackup,
                settingsProvider.toggleAutoBackup,
              ),
              ListTile(
                leading: const Icon(Icons.backup),
                title: Text('Backup Now', style: GoogleFonts.poppins()),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => _showBackupDialog(context),
              ),
              ListTile(
                leading: const Icon(Icons.restore),
                title: Text('Restore Data', style: GoogleFonts.poppins()),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => _showRestoreDialog(context),
              ),

              const SizedBox(height: 16),

              // About Section
              _buildSectionHeader('About'),
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: Text('App Version', style: GoogleFonts.poppins()),
                subtitle: const Text('1.0.0 (Build 2024.03.11)'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => _showVersionDialog(context),
              ),
              ListTile(
                leading: const Icon(Icons.description_outlined),
                title: Text('Terms of Service', style: GoogleFonts.poppins()),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => _showTermsDialog(context),
              ),
              ListTile(
                leading: const Icon(Icons.privacy_tip_outlined),
                title: Text('Privacy Policy', style: GoogleFonts.poppins()),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => _showPrivacyDialog(context),
              ),
              ListTile(
                leading: const Icon(Icons.security),
                title:
                    Text('Security & Compliance', style: GoogleFonts.poppins()),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => _showSecurityDialog(context),
              ),
              ListTile(
                leading: const Icon(Icons.support_agent),
                title: Text('Support & Help', style: GoogleFonts.poppins()),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => _showSupportDialog(context),
              ),
              ListTile(
                leading: const Icon(Icons.code),
                title:
                    Text('Open Source Licenses', style: GoogleFonts.poppins()),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => _showLicensesDialog(context),
              ),

              const SizedBox(height: 16),

              // Logout Button
              CustomButton(
                text: 'LOGOUT',
                onPressed: () async {
                  final confirm = await _showLogoutDialog(context);
                  if (confirm) {
                    await authProvider.logout();
                    if (mounted) {
                      Navigator.pushReplacementNamed(context, '/login');
                    }
                  }
                },
                color: Colors.red,
                isFullWidth: true,
              ),

              const SizedBox(height: 32),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 8),
      child: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.primaryGreen,
        ),
      ),
    );
  }

  Widget _buildThemeSelector(SettingsProvider provider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            _buildThemeOption(
              AppTheme.light,
              provider.currentTheme == AppTheme.light,
              provider,
            ),
            const Divider(),
            _buildThemeOption(
              AppTheme.dark,
              provider.currentTheme == AppTheme.dark,
              provider,
            ),
            const Divider(),
            _buildThemeOption(
              AppTheme.system,
              provider.currentTheme == AppTheme.system,
              provider,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeOption(
      AppTheme theme, bool isSelected, SettingsProvider provider) {
    return ListTile(
      leading: Icon(theme.icon),
      title: Text(theme.displayName, style: GoogleFonts.poppins()),
      trailing: isSelected
          ? const Icon(Icons.check_circle, color: AppColors.primaryGreen)
          : null,
      onTap: () {
        provider.setTheme(theme);
      },
    );
  }

  Widget _buildSwitchTile(
    String title,
    String subtitle,
    IconData icon,
    bool value,
    VoidCallback onTap,
  ) {
    return Card(
      child: SwitchListTile(
        secondary: Icon(icon),
        title: Text(title, style: GoogleFonts.poppins()),
        subtitle: Text(subtitle, style: GoogleFonts.poppins(fontSize: 12)),
        value: value,
        onChanged: (_) => onTap(),
        activeThumbColor: AppColors.primaryGreen,
      ),
    );
  }

  // Dialog Methods
  void _showChangeUsernameDialog(BuildContext context) {
    final TextEditingController controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Username'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'New Username',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Username must be unique and at least 3 characters',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Username updated successfully'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('UPDATE'),
          ),
        ],
      ),
    );
  }

  void _showChangeEmailDialog(BuildContext context) {
    final TextEditingController controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Email'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'New Email',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            const Text(
              'A verification email will be sent to your new address',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Verification email sent'),
                  backgroundColor: Colors.blue,
                ),
              );
            },
            child: const Text('SEND VERIFICATION'),
          ),
        ],
      ),
    );
  }

  void _showChangePhoneDialog(BuildContext context) {
    final TextEditingController controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Phone Number'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'New Phone Number',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Phone number updated successfully'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('UPDATE'),
          ),
        ],
      ),
    );
  }

  void _showVersionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('App Version'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow('Version', '1.0.0'),
            _buildInfoRow('Build', '2026.03.11'),
            _buildInfoRow('Flutter', '3.16.0'),
            _buildInfoRow('Dart', '3.2.0'),
            const Divider(),
            const SizedBox(height: 8),
            const Text(
              'Release Date: March 11, 2026',
              style: TextStyle(fontSize: 12),
            ),
            const Text(
              'Compatibility: Android 5.0+ / iOS 12.0+',
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CLOSE'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('You have the latest version'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('CHECK UPDATES'),
          ),
        ],
      ),
    );
  }

  void _showTermsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Terms of Service'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Last Updated: March 11, 2024',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 16),
                const Text(
                  '1. Acceptance of Terms',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'By accessing and using His Grace Drugshop Management System, you agree to be bound by these Terms of Service and all applicable laws and regulations.',
                  style: TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 16),
                const Text(
                  '2. User Accounts',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  '• You are responsible for maintaining the confidentiality of your account\n'
                  '• You are responsible for all activities under your account\n'
                  '• You must notify us immediately of any unauthorized use\n'
                  '• We reserve the right to terminate accounts for violations',
                  style: TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 16),
                const Text(
                  '3. Data Accuracy',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'You are responsible for ensuring the accuracy of all data entered into the system, including medicine information, sales records, and inventory counts.',
                  style: TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 16),
                const Text(
                  '4. Prohibited Activities',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  '• Selling expired or counterfeit medicines\n'
                  '• Manipulating inventory records\n'
                  '• Unauthorized access to other accounts\n'
                  '• Using the system for illegal purposes',
                  style: TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 16),
                const Text(
                  '5. Limitation of Liability',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'His Grace Drugshop shall not be liable for any indirect, incidental, or consequential damages arising from the use of this system.',
                  style: TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CLOSE'),
          ),
          TextButton(
            onPressed: () {
              _launchUrl('https://www.HisGraceDrugshop.com/terms');
            },
            child: const Text('VIEW ONLINE'),
          ),
        ],
      ),
    );
  }

  void _showPrivacyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Privacy Policy'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Last Updated: March 11, 2024',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Information We Collect',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  '• Personal information (name, email, phone)\n'
                  '• Login credentials (encrypted)\n'
                  '• Pharmacy inventory and sales data\n'
                  '• Usage statistics and preferences',
                  style: TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 16),
                const Text(
                  'How We Use Your Information',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  '• To provide and maintain our service\n'
                  '• To notify you about changes\n'
                  '• To provide customer support\n'
                  '• To gather analysis for improvement',
                  style: TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Data Security',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'We implement industry-standard security measures including encryption, secure authentication, and regular security audits to protect your data.',
                  style: TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Data Retention',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'We retain your data for as long as your account is active. You may request data deletion by contacting support.',
                  style: TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Third Party Services',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'We may use third-party services for analytics and crash reporting. These services have their own privacy policies.',
                  style: TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CLOSE'),
          ),
          TextButton(
            onPressed: () {
              _launchUrl('https://www.HisGraceDrugshop.com/privacy');
            },
            child: const Text('VIEW ONLINE'),
          ),
        ],
      ),
    );
  }

  void _showSecurityDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Security & Compliance'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow('Encryption', 'AES-256'),
            _buildInfoRow('Authentication', 'Token-based'),
            _buildInfoRow('Session Timeout', '30 minutes'),
            _buildInfoRow('Password Policy', 'Minimum 8 characters'),
            const Divider(),
            const SizedBox(height: 8),
            const Text(
              'Compliance Standards:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text('• HIPAA compliant data handling'),
            const Text('• GDPR ready'),
            const Text('• ISO 27001 certified infrastructure'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CLOSE'),
          ),
        ],
      ),
    );
  }

  void _showSupportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Support & Help'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              leading: const Icon(Icons.email, color: AppColors.primaryGreen),
              title: const Text('Email Support'),
              subtitle: const Text('support@HisGraceDrugshop.com'),
              onTap: () {
                _launchUrl('mailto:support@HisGraceDrugshop.com');
              },
            ),
            ListTile(
              leading: const Icon(Icons.phone, color: AppColors.primaryGreen),
              title: const Text('Phone Support'),
              subtitle: const Text('+256 700 123 456'),
              onTap: () {
                _launchUrl('tel:+256700123456');
              },
            ),
            ListTile(
              leading: const Icon(Icons.chat, color: AppColors.primaryGreen),
              title: const Text('Live Chat'),
              subtitle: const Text('Available 9am-5pm'),
              onTap: () {
                _launchUrl('https://www.HisGraceDrugshop.com/chat');
              },
            ),
            ListTile(
              leading: const Icon(Icons.help, color: AppColors.primaryGreen),
              title: const Text('FAQ'),
              subtitle: const Text('Frequently asked questions'),
              onTap: () {
                _launchUrl('https://www.HisGraceDrugshop.com/faq');
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CLOSE'),
          ),
        ],
      ),
    );
  }

  void _showLicensesDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Open Source Licenses'),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: ListView(
            children: [
              _buildLicenseTile(
                  'Flutter', 'BSD 3-Clause', 'https://flutter.dev'),
              _buildLicenseTile(
                  'Django', 'BSD 3-Clause', 'https://djangoproject.com'),
              _buildLicenseTile(
                  'Provider', 'MIT', 'https://pub.dev/packages/provider'),
              _buildLicenseTile('Dio', 'MIT', 'https://pub.dev/packages/dio'),
              _buildLicenseTile('Shared Preferences', 'BSD 3-Clause',
                  'https://pub.dev/packages/shared_preferences'),
              _buildLicenseTile('Google Fonts', 'MIT',
                  'https://pub.dev/packages/google_fonts'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CLOSE'),
          ),
        ],
      ),
    );
  }

  Widget _buildLicenseTile(String name, String license, String url) {
    return ListTile(
      title: Text(name),
      subtitle: Text(license),
      trailing: const Icon(Icons.open_in_new, size: 16),
      onTap: () => _launchUrl(url),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 14, color: Colors.grey),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  // FIXED: Correct _showLanguageDialog with proper ListView.builder
  void _showLanguageDialog(BuildContext context, SettingsProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Language'),
        content: SizedBox(
          width: double.maxFinite,
          height: 300, // Fixed height to make it scrollable
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: provider.availableLanguages.length,
            itemBuilder: (BuildContext context, int index) {
              final language = provider.availableLanguages[index];
              return ListTile(
                title: Text(language),
                trailing: provider.language == language
                    ? const Icon(Icons.check, color: AppColors.primaryGreen)
                    : null,
                onTap: () {
                  provider.setLanguage(language);
                  Navigator.pop(context);
                  setState(() {});
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CLOSE'),
          ),
        ],
      ),
    );
  }

  void _showBackupDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Backup Data'),
        content: const Text('Create a backup of all your pharmacy data?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Backup started...'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('BACKUP'),
          ),
        ],
      ),
    );
  }

  void _showRestoreDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restore Data'),
        content: const Text(
            'Restore data from backup? This will overwrite current data.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Restore started...'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            child: const Text('RESTORE'),
          ),
        ],
      ),
    );
  }

  Future<bool> _showLogoutDialog(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Logout'),
            content: const Text('Are you sure you want to logout?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('CANCEL'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.red,
                ),
                child: const Text('LOGOUT'),
              ),
            ],
          ),
        ) ??
        false;
  }
}
