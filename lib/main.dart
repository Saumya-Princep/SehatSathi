import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'theme.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/app_localizations.dart';
import 'providers/auth_provider.dart';
import 'providers/language_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/patient/patient_dashboard.dart';
import 'screens/doctor/doctor_dashboard.dart';
import 'screens/pharmacist/pharmacist_dashboard.dart';
import 'screens/admin/admin_dashboard.dart';
import 'screens/lab/lab_dashboard.dart';
import 'models/user_model.dart';

import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const SehatSathiApp());
}

class SehatSathiApp extends StatelessWidget {
  const SehatSathiApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
      ],
      child: Consumer2<AuthProvider, LanguageProvider>(
        builder: (context, authProvider, languageProvider, _) {
          return MaterialApp(
            title: 'SehatSathi',
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: authProvider.themeMode,
            debugShowCheckedModeBanner: false,
            localizationsDelegates: [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('en', ''),
              Locale('hi', ''),
              Locale('bn', ''),
              Locale('te', ''),
              Locale('mr', ''),
              Locale('ta', ''),
              Locale('gu', ''),
            ],
            locale: languageProvider.currentLocale,
            home: const InitialRouteHandler(),
          );
        },
      ),
    );
  }
}

class InitialRouteHandler extends StatelessWidget {
  const InitialRouteHandler({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        if (authProvider.isLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (authProvider.isAuthenticated && authProvider.userModel != null) {
          switch (authProvider.userModel!.role) {
            case UserRole.patient:
              return const PatientDashboard();
            case UserRole.doctor:
              return const DoctorDashboard();
            case UserRole.pharmacist:
              return const PharmacistDashboard();
            case UserRole.admin:
              return const AdminDashboard();
            case UserRole.lab_technician:
              return const LabDashboard();
          }
        }
        return const LoginScreen();
      },
    );
  }
}
