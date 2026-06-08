import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/auth_provider.dart';
import '../../providers/settings_provider.dart';
import '../../models/theme_model.dart';
import '../../widgets/custom_button.dart';
import '../../utils/constants.dart';
import '../../services/translation_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _t(String key) {
    return TranslationService().translate(key);
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;
    final isAdmin = user?.isAdmin ?? false;

    return Scaffold(
      appBar: AppBar(
        title: Text(_t('Settings')),
      ),
      body: Consumer<SettingsProvider>(
        builder: (context, settingsProvider, child) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Profile Section - Visible to all users
              _buildSectionHeader(_t('Profile')),
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

              // Account Settings - Visible to all users (self-management)
              _buildSectionHeader(_t('Account Settings')),
              ListTile(
                leading: const Icon(Icons.person_outline),
                title: Text(
                  _t('Change Username'),
                  style: GoogleFonts.poppins(),
                ),
                subtitle: Text(
                  '${_t('Current')}: ${user?.username}',
                  style: GoogleFonts.poppins(fontSize: 12),
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  _showChangeUsernameDialog(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.email_outlined),
                title: Text(
                  _t('Change Email'),
                  style: GoogleFonts.poppins(),
                ),
                subtitle: Text(
                  '${_t('Current')}: ${user?.email}',
                  style: GoogleFonts.poppins(fontSize: 12),
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  _showChangeEmailDialog(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.phone_outlined),
                title: Text(
                  _t('Change Phone'),
                  style: GoogleFonts.poppins(),
                ),
                subtitle: Text(
                  user?.phone?.isNotEmpty == true 
                      ? '${_t('Current')}: ${user?.phone}' 
                      : _t('Not set'),
                  style: GoogleFonts.poppins(fontSize: 12),
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  _showChangePhoneDialog(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.lock_outline),
                title: Text(
                  _t('Change Password'),
                  style: GoogleFonts.poppins(),
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  Navigator.pushNamed(context, '/change-password');
                },
              ),

              const SizedBox(height: 16),

              // Staff Management - Admin Only
              if (isAdmin) ...[
                _buildSectionHeader(_t('Staff Management')),
                ListTile(
                  leading: const Icon(Icons.people_outline, color: AppColors.primaryGreen),
                  title: Text(
                    _t('Manage Staff'),
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryGreen,
                    ),
                  ),
                  subtitle: Text(
                    _t('Add, edit, or remove staff members'),
                    style: GoogleFonts.poppins(fontSize: 12),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    Navigator.pushNamed(context, '/staff');
                  },
                ),
                const SizedBox(height: 16),
              ],

              // Appearance Section
              _buildSectionHeader(_t('Appearance')),
              _buildThemeSelector(settingsProvider),

              const SizedBox(height: 16),

              // Language Section
              _buildSectionHeader(_t('Language & Region')),
              ListTile(
                leading: const Icon(Icons.language),
                title: Text(
                  _t('Language'),
                  style: GoogleFonts.poppins(),
                ),
                subtitle: Text(
                  settingsProvider.language,
                  style: GoogleFonts.poppins(fontSize: 12),
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  _showLanguageDialog(context, settingsProvider);
                },
              ),

              const SizedBox(height: 16),

              // Data & Backup
              _buildSectionHeader(_t('Data & Backup')),
              _buildSwitchTile(
                _t('Auto Backup'),
                _t('Automatically backup your data'),
                Icons.backup_outlined,
                settingsProvider.autoBackup,
                settingsProvider.toggleAutoBackup,
              ),
              ListTile(
                leading: const Icon(Icons.backup),
                title: Text(
                  _t('Backup Now'),
                  style: GoogleFonts.poppins(),
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  _showBackupDialog(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.restore),
                title: Text(
                  _t('Restore Data'),
                  style: GoogleFonts.poppins(),
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  _showRestoreDialog(context);
                },
              ),

              const SizedBox(height: 16),

              // About Section with Complete Details
              _buildSectionHeader(_t('About')),
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: Text(
                  _t('App Version'),
                  style: GoogleFonts.poppins(),
                ),
                subtitle: const Text('1.0.0 (Build 2024.03.11)'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  _showVersionDialog(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.description_outlined),
                title: Text(
                  _t('Terms of Service'),
                  style: GoogleFonts.poppins(),
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  _showTermsDialog(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.privacy_tip_outlined),
                title: Text(
                  _t('Privacy Policy'),
                  style: GoogleFonts.poppins(),
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  _showPrivacyDialog(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.security),
                title: Text(
                  _t('Security & Compliance'),
                  style: GoogleFonts.poppins(),
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  _showSecurityDialog(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.support_agent),
                title: Text(
                  _t('Support & Help'),
                  style: GoogleFonts.poppins(),
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  _showSupportDialog(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.code),
                title: Text(
                  _t('Open Source Licenses'),
                  style: GoogleFonts.poppins(),
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  _showLicensesDialog(context);
                },
              ),

              const SizedBox(height: 16),

              // Logout Button
              CustomButton(
                text: _t('LOGOUT'),
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

  Widget _buildThemeOption(AppTheme theme, bool isSelected, SettingsProvider provider) {
    return ListTile(
      leading: Icon(theme.icon),
      title: Text(
        _t(theme.displayName),
        style: GoogleFonts.poppins(),
      ),
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
        title: Text(
          title,
          style: GoogleFonts.poppins(),
        ),
        subtitle: Text(
          subtitle,
          style: GoogleFonts.poppins(fontSize: 12),
        ),
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
        title: Text(_t('Change Username')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              decoration: InputDecoration(
                labelText: _t('New Username'),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _t('Username must be unique and at least 3 characters'),
              style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(_t('CANCEL')),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(_t('Username updated successfully')),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: Text(_t('UPDATE')),
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
        title: Text(_t('Change Email')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              decoration: InputDecoration(
                labelText: _t('New Email'),
                border: const OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            Text(
              _t('A verification email will be sent to your new address'),
              style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(_t('CANCEL')),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(_t('Verification email sent')),
                  backgroundColor: Colors.blue,
                ),
              );
            },
            child: Text(_t('SEND VERIFICATION')),
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
        title: Text(_t('Change Phone Number')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              decoration: InputDecoration(
                labelText: _t('New Phone Number'),
                border: const OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(_t('CANCEL')),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(_t('Phone number updated successfully')),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: Text(_t('UPDATE')),
          ),
        ],
      ),
    );
  }

  void _showVersionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_t('App Version')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow(_t('Version'), '1.0.0'),
            _buildInfoRow(_t('Build'), '2024.03.11'),
            _buildInfoRow(_t('Flutter'), '3.16.0'),
            _buildInfoRow(_t('Dart'), '3.2.0'),
            const Divider(),
            const SizedBox(height: 8),
            Text(
              _t('Release Date: March 11, 2024'),
              style: GoogleFonts.poppins(fontSize: 12),
            ),
            Text(
              _t('Compatibility: Android 5.0+ / iOS 12.0+'),
              style: GoogleFonts.poppins(fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(_t('CLOSE')),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(_t('You have the latest version')),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: Text(_t('CHECK UPDATES')),
          ),
        ],
      ),
    );
  }

  void _showTermsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_t('Terms of Service')),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Last Updated: March 11, 2024',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  '1. Acceptance of Terms',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'By accessing and using His Grace Drugshop Management System, you agree to be bound by these Terms of Service and all applicable laws and regulations.',
                  style: GoogleFonts.poppins(fontSize: 14),
                ),
                const SizedBox(height: 16),
                Text(
                  '2. User Accounts',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '• You are responsible for maintaining the confidentiality of your account\n'
                  '• You are responsible for all activities under your account\n'
                  '• You must notify us immediately of any unauthorized use\n'
                  '• We reserve the right to terminate accounts for violations',
                  style: GoogleFonts.poppins(fontSize: 14),
                ),
                const SizedBox(height: 16),
                Text(
                  '3. Data Accuracy',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'You are responsible for ensuring the accuracy of all data entered into the system, including medicine information, sales records, and inventory counts.',
                  style: GoogleFonts.poppins(fontSize: 14),
                ),
                const SizedBox(height: 16),
                Text(
                  '4. Prohibited Activities',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '• Selling expired or counterfeit medicines\n'
                  '• Manipulating inventory records\n'
                  '• Unauthorized access to other accounts\n'
                  '• Using the system for illegal purposes',
                  style: GoogleFonts.poppins(fontSize: 14),
                ),
                const SizedBox(height: 16),
                Text(
                  '5. Limitation of Liability',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'His Grace Drugshop shall not be liable for any indirect, incidental, or consequential damages arising from the use of this system.',
                  style: GoogleFonts.poppins(fontSize: 14),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(_t('CLOSE')),
          ),
          TextButton(
            onPressed: () {
              _launchUrl('https://www.HisGraceDrugshop.com/terms');
            },
            child: Text(_t('VIEW ONLINE')),
          ),
        ],
      ),
    );
  }

  void _showPrivacyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_t('Privacy Policy')),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Last Updated: March 11, 2024',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Information We Collect',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '• Personal information (name, email, phone)\n'
                  '• Login credentials (encrypted)\n'
                  '• Pharmacy inventory and sales data\n'
                  '• Usage statistics and preferences',
                  style: GoogleFonts.poppins(fontSize: 14),
                ),
                const SizedBox(height: 16),
                Text(
                  'How We Use Your Information',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '• To provide and maintain our service\n'
                  '• To notify you about changes\n'
                  '• To provide customer support\n'
                  '• To gather analysis for improvement',
                  style: GoogleFonts.poppins(fontSize: 14),
                ),
                const SizedBox(height: 16),
                Text(
                  'Data Security',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'We implement industry-standard security measures including encryption, secure authentication, and regular security audits to protect your data.',
                  style: GoogleFonts.poppins(fontSize: 14),
                ),
                const SizedBox(height: 16),
                Text(
                  'Data Retention',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'We retain your data for as long as your account is active. You may request data deletion by contacting support.',
                  style: GoogleFonts.poppins(fontSize: 14),
                ),
                const SizedBox(height: 16),
                Text(
                  'Third Party Services',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'We may use third-party services for analytics and crash reporting. These services have their own privacy policies.',
                  style: GoogleFonts.poppins(fontSize: 14),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(_t('CLOSE')),
          ),
          TextButton(
            onPressed: () {
              _launchUrl('https://www.HisGraceDrugshop.com/privacy');
            },
            child: Text(_t('VIEW ONLINE')),
          ),
        ],
      ),
    );
  }

  void _showSecurityDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_t('Security & Compliance')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow(_t('Encryption'), 'AES-256'),
            _buildInfoRow(_t('Authentication'), 'Token-based'),
            _buildInfoRow(_t('Session Timeout'), '30 minutes'),
            _buildInfoRow(_t('Password Policy'), 'Minimum 8 characters'),
            const Divider(),
            const SizedBox(height: 8),
            Text(
              _t('Compliance Standards:'),
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
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
            child: Text(_t('CLOSE')),
          ),
        ],
      ),
    );
  }

  void _showSupportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_t('Support & Help')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              leading: const Icon(Icons.email, color: AppColors.primaryGreen),
              title: Text(_t('Email Support')),
              subtitle: const Text('support@HisGraceDrugshop.com'),
              onTap: () {
                _launchUrl('mailto:support@HisGraceDrugshop.com');
              },
            ),
            ListTile(
              leading: const Icon(Icons.phone, color: AppColors.primaryGreen),
              title: Text(_t('Phone Support')),
              subtitle: const Text('+256 700 123 456'),
              onTap: () {
                _launchUrl('tel:+256700123456');
              },
            ),
            ListTile(
              leading: const Icon(Icons.chat, color: AppColors.primaryGreen),
              title: Text(_t('Live Chat')),
              subtitle: Text(_t('Available 9am-5pm')),
              onTap: () {
                _launchUrl('https://www.HisGraceDrugshop.com/chat');
              },
            ),
            ListTile(
              leading: const Icon(Icons.help, color: AppColors.primaryGreen),
              title: Text(_t('FAQ')),
              subtitle: Text(_t('Frequently asked questions')),
              onTap: () {
                _launchUrl('https://www.HisGraceDrugshop.com/faq');
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(_t('CLOSE')),
          ),
        ],
      ),
    );
  }

  void _showLicensesDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_t('Open Source Licenses')),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: ListView(
            children: [
              _buildLicenseTile('Flutter', 'BSD 3-Clause', 'https://flutter.dev'),
              _buildLicenseTile('Django', 'BSD 3-Clause', 'https://djangoproject.com'),
              _buildLicenseTile('Provider', 'MIT', 'https://pub.dev/packages/provider'),
              _buildLicenseTile('Dio', 'MIT', 'https://pub.dev/packages/dio'),
              _buildLicenseTile('Shared Preferences', 'BSD 3-Clause', 'https://pub.dev/packages/shared_preferences'),
              _buildLicenseTile('Google Fonts', 'MIT', 'https://pub.dev/packages/google_fonts'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(_t('CLOSE')),
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
            style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey),
          ),
          Text(
            value,
            style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500),
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

  void _showLanguageDialog(BuildContext context, SettingsProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_t('Select Language')),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: provider.availableLanguages.length,
            itemBuilder: (context, index) {
              final language = provider.availableLanguages[index];
              return ListTile(
                title: Text(language),
                trailing: provider.language == language
                    ? const Icon(Icons.check, color: AppColors.primaryGreen)
                    : null,
                onTap: () {
                  provider.setLanguage(language);
                  TranslationService().setLanguage(language);
                  Navigator.pop(context);
                  setState(() {});
                },
              );
            },
          ),
        ),
      ),
    );
  }

  void _showBackupDialog(BuildContext context) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_t('Backup Data')),
        content: Text(_t('Create a backup of all your pharmacy data?')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(_t('CANCEL')),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(_t('Backup started...')),
                  backgroundColor: Colors.green,
                ),
              );
              // Implement actual backup logic
            },
            child: Text(_t('BACKUP')),
          ),
        ],
      ),
    );
  }

  void _showRestoreDialog(BuildContext context) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_t('Restore Data')),
        content: Text(_t('Restore data from backup? This will overwrite current data.')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(_t('CANCEL')),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(_t('Restore started...')),
                  backgroundColor: Colors.orange,
                ),
              );
              // Implement actual restore logic
            },
            child: Text(_t('RESTORE')),
          ),
        ],
      ),
    );
  }

  Future<bool> _showLogoutDialog(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(_t('Logout')),
            content: Text(_t('Are you sure you want to logout?')),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(_t('CANCEL')),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.red,
                ),
                child: Text(_t('LOGOUT')),
              ),
            ],
          ),
        ) ??
        false;
  }
}