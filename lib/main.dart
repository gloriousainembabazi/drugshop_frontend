// lib/main.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'providers/auth_provider.dart';
import 'providers/medicine_provider.dart';
import 'providers/sale_provider.dart';
import 'providers/report_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/expense_provider.dart';
import 'providers/credit_provider.dart';
import 'providers/prescription_provider.dart';

import 'services/api_service.dart';
import 'services/auth_service.dart';
import 'services/storage_service.dart';

import 'screens/splash_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/auth/forgot_password_screen.dart';
import 'screens/auth/otp_verification_screen.dart';
import 'screens/auth/reset_password_screen.dart';

import 'screens/home/home_screen.dart';

import 'screens/medicines/medicine_list_screen.dart';
import 'screens/medicines/add_medicine_screen.dart';
import 'screens/medicines/medicine_detail_screen.dart';

import 'screens/sales/sale_list_screen.dart';
import 'screens/sales/new_sale_screen.dart';
import 'screens/sales/sale_detail_screen.dart';

import 'screens/reports/report_dashboard.dart';
import 'screens/reports/sales_report_screen.dart';
import 'screens/reports/inventory_report_screen.dart';
import 'screens/reports/staff_report_screen.dart';

import 'screens/profile/profile_screen.dart';

import 'screens/settings/settings_screen.dart';
import 'screens/settings/change_password_screen.dart';
import 'screens/settings/about_screen.dart';

import 'screens/inventory/stock_take_screen.dart';

import 'screens/expenses/expense_screen.dart';
import 'screens/credit/credit_screen.dart';
import 'screens/prescriptions/prescription_screen.dart';

import 'screens/scan/qr_scanner_screen.dart';
import 'screens/more/more_screen.dart';

import 'utils/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final storageService = StorageService();
  await storageService.init();

  final apiService = ApiService(storageService);
  final authService = AuthService(apiService, storageService);

  final prefs = await SharedPreferences.getInstance();
  final onboardingCompleted = prefs.getBool('onboarding_completed') ?? false;

  runApp(
    MyApp(
      apiService: apiService,
      authService: authService,
      storageService: storageService,
      onboardingCompleted: onboardingCompleted,
    ),
  );
}

class MyApp extends StatelessWidget {
  final ApiService apiService;
  final AuthService authService;
  final StorageService storageService;
  final bool onboardingCompleted;

  const MyApp({
    super.key,
    required this.apiService,
    required this.authService,
    required this.storageService,
    required this.onboardingCompleted,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider(authService, storageService),
        ),
        ChangeNotifierProvider(
          create: (_) => MedicineProvider(apiService),
        ),
        ChangeNotifierProvider(
          create: (_) => SaleProvider(apiService),
        ),
        ChangeNotifierProvider(
          create: (_) => ReportProvider(apiService),
        ),
        ChangeNotifierProvider(
          create: (_) => SettingsProvider(storageService),
        ),
        ChangeNotifierProvider(
          create: (_) => ExpenseProvider(apiService),
        ),
        ChangeNotifierProvider(
          create: (_) => CreditProvider(apiService),
        ),
        ChangeNotifierProvider(
          create: (_) => PrescriptionProvider(apiService),
        ),
      ],
      child: Consumer2<AuthProvider, SettingsProvider>(
        builder: (context, authProvider, settingsProvider, child) {
          return MaterialApp(
            title: 'His Grace Drugshop',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: settingsProvider.getThemeMode(),
            initialRoute: _getInitialRoute(authProvider, onboardingCompleted),
            routes: {
              '/splash': (context) => const SplashScreen(),
              '/onboarding': (context) => const OnboardingScreen(),
              '/login': (context) => const LoginScreen(),
              '/register': (context) => const RegisterScreen(),
              '/forgot-password': (context) => const ForgotPasswordScreen(),
              '/home': (context) => const HomeScreen(),
              '/medicines': (context) => const MedicineListScreen(),
              '/add-medicine': (context) => const AddMedicineScreen(),
              '/sales': (context) => const SaleListScreen(),
              '/new-sale': (context) => const NewSaleScreen(),
              '/reports': (context) => const ReportDashboard(),
              '/sales-report': (context) => const SalesReportScreen(),
              '/inventory-report': (context) => const InventoryReportScreen(),
              '/staff-report': (context) => const StaffReportScreen(),
              '/profile': (context) => const ProfileScreen(),
              '/settings': (context) => const SettingsScreen(),
              '/change-password': (context) => const ChangePasswordScreen(),
              '/about': (context) => const AboutScreen(),
              '/stock-take': (context) => const StockTakeScreen(),
              '/expenses': (context) => const ExpenseScreen(),
              '/credit': (context) => const CreditScreen(),
              '/prescriptions': (context) => const PrescriptionScreen(),
              '/qr-scanner': (context) => const QRScannerScreen(),
              '/more': (context) => const MoreScreen(),
            },
            onGenerateRoute: (settings) {
              // MEDICINE DETAIL
              if (settings.name == '/medicine-detail') {
                final args = settings.arguments as Map<String, dynamic>?;
                final medicineId = args?['id'] ?? 0;
                return MaterialPageRoute(
                  builder: (context) => MedicineDetailScreen(
                    medicineId: medicineId,
                  ),
                );
              }

              // SALE DETAIL
              if (settings.name == '/sale-detail') {
                final args = settings.arguments as Map<String, dynamic>?;
                final saleId = args?['sale_id'] ?? '';
                if (saleId.isEmpty) {
                  return MaterialPageRoute(
                    builder: (context) => const Scaffold(
                      body: Center(child: Text('Invalid sale ID')),
                    ),
                  );
                }
                return MaterialPageRoute(
                  builder: (context) => SaleDetailScreen(
                    saleId: saleId,
                  ),
                );
              }

              // OTP VERIFICATION
              if (settings.name == '/otp-verification') {
                final args = settings.arguments;
                if (args is String) {
                  return MaterialPageRoute(
                    builder: (context) => OtpVerificationScreen(
                      destination: args,
                      type: 'email',
                      purpose: 'verification',
                    ),
                  );
                }
                if (args is Map<String, dynamic>) {
                  return MaterialPageRoute(
                    builder: (context) => OtpVerificationScreen(
                      destination: args['destination'] ?? '',
                      type: args['type'] ?? 'email',
                      purpose: args['purpose'] ?? 'verification',
                    ),
                  );
                }
                return MaterialPageRoute(
                  builder: (context) => const OtpVerificationScreen(
                    destination: '',
                    type: 'email',
                    purpose: 'verification',
                  ),
                );
              }

              // OTP RESET
              if (settings.name == '/otp-verification-reset') {
                final args = settings.arguments as Map<String, dynamic>?;
                return MaterialPageRoute(
                  builder: (context) => OtpVerificationScreen(
                    destination: args?['destination'] ?? '',
                    type: args?['type'] ?? 'email',
                    purpose: 'reset',
                  ),
                );
              }

              // RESET PASSWORD
              if (settings.name == '/reset-password') {
                final args = settings.arguments as Map<String, dynamic>?;
                return MaterialPageRoute(
                  builder: (context) => ResetPasswordScreen(
                    email: args?['email'] ?? '',
                    otp: args?['otp']?.toString(),
                  ),
                );
              }

              return null;
            },
          );
        },
      ),
    );
  }

  String _getInitialRoute(AuthProvider authProvider, bool onboardingCompleted) {
    if (authProvider.isLoading) {
      return '/splash';
    }
    if (authProvider.isAuthenticated) {
      return '/home';
    }
    if (!onboardingCompleted) {
      return '/onboarding';
    }
    return '/login';
  }
}
