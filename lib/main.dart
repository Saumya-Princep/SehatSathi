import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'theme.dart';
import 'providers/auth_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/patient/patient_dashboard.dart';
import 'screens/doctor/doctor_dashboard.dart';
import 'screens/pharmacist/pharmacist_dashboard.dart';
import 'screens/admin/admin_dashboard.dart';
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
      ],
      child: MaterialApp(
        title: 'SehatSathi',
        theme: AppTheme.lightTheme,
        debugShowCheckedModeBanner: false,
        home: const InitialRouteHandler(),
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
          }
        }
        return const LoginScreen();
      },
    );
  }
}
