import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/auth_provider.dart';
import '../../utils/constants.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final isAdmin = authProvider.currentUser?.isAdmin ?? false;

    return Scaffold(
      appBar: AppBar(
        title: const Text('More Features'),
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primaryGreen,
                AppColors.primaryGreen.withOpacity(0.8),
              ],
            ),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionHeader('Financial'),
          _buildMenuItem(
            icon: Icons.credit_card,
            iconColor: Colors.purple,
            title: 'Credit Sales',
            subtitle: 'Manage customer credit and payments',
            onTap: () => Navigator.pushNamed(context, '/credit'),
          ),
          _buildMenuItem(
            icon: Icons.receipt,
            iconColor: Colors.red,
            title: 'Expenses',
            subtitle: 'Track pharmacy expenses',
            onTap: () => Navigator.pushNamed(context, '/expenses'),
          ),
          
          const SizedBox(height: 24),
          _buildSectionHeader('Inventory'),
          _buildMenuItem(
            icon: Icons.inventory,
            iconColor: Colors.brown,
            title: 'Stock Take',
            subtitle: 'Physical stock counting',
            onTap: () => Navigator.pushNamed(context, '/stock-take'),
          ),
          _buildMenuItem(
            icon: Icons.qr_code_scanner,
            iconColor: Colors.indigo,
            title: 'QR Scanner',
            subtitle: 'Scan medicine barcodes',
            onTap: () => Navigator.pushNamed(context, '/qr-scanner'),
          ),
          
          const SizedBox(height: 24),
          _buildSectionHeader('Clinical'),
          _buildMenuItem(
            icon: Icons.description,
            iconColor: Colors.teal,
            title: 'Prescriptions',
            subtitle: 'Manage patient prescriptions',
            onTap: () => Navigator.pushNamed(context, '/prescriptions'),
          ),
          
          if (isAdmin) ...[
            const SizedBox(height: 24),
            _buildSectionHeader('Administration'),
            _buildMenuItem(
              icon: Icons.people,
              iconColor: Colors.blue,
              title: 'Staff Management',
              subtitle: 'Manage staff accounts',
              onTap: () => Navigator.pushNamed(context, '/staff'),
            ),
            _buildMenuItem(
              icon: Icons.settings,
              iconColor: Colors.grey,
              title: 'Settings',
              subtitle: 'App settings and preferences',
              onTap: () => Navigator.pushNamed(context, '/settings'),
            ),
          ],
        ],
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

  Widget _buildMenuItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor, size: 24),
        ),
        title: Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
        trailing: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.arrow_forward_ios, size: 14),
        ),
        onTap: onTap,
      ),
    );
  }
}
