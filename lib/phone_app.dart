import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'providers/auth_provider.dart';
import 'screens/phone/phone_home_screen.dart';
import 'screens/welcome_screen.dart';
import 'screens/auth_tab_screen.dart';
import 'screens/host_login_screen.dart';
import 'screens/host_dashboard_screen.dart';
import 'screens/host_coach_code_screen.dart';
import 'screens/host_coach_workout_list_screen.dart';
import 'screens/host_settings_screen.dart';
import 'screens/host_manage_coaches_screen.dart';

class PhoneApp extends StatelessWidget {
  const PhoneApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: MaterialApp(
        title: 'SPRTN STUDIO',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blue,
            brightness: Brightness.light,
          ),
          useMaterial3: true,
          fontFamily: GoogleFonts.barlow().fontFamily,
          textTheme: GoogleFonts.barlowTextTheme(
            Theme.of(context).textTheme,
          ),
        ),
        darkTheme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blue,
            brightness: Brightness.dark,
          ),
          useMaterial3: true,
          fontFamily: GoogleFonts.barlow().fontFamily,
          textTheme: GoogleFonts.barlowTextTheme(
            ThemeData.dark().textTheme,
          ),
        ),
        home: const PhoneNavigator(),
        routes: {
          '/welcome': (context) => const WelcomeScreen(),
          '/auth': (context) => const AuthTabScreen(),
          '/host-login': (context) => const HostLoginScreen(),
          '/home': (context) => const PhoneHomeScreen(),
          '/host-dashboard': (context) => const HostDashboardScreen(),
          '/host-coach-code': (context) => const HostCoachCodeScreen(),
          '/host-coach-workouts': (context) => const HostCoachWorkoutListScreen(),
          '/host-settings': (context) => const HostSettingsScreen(),
          '/host-manage-coaches': (context) => const HostManageCoachesScreen(),
        },
      ),
    );
  }
}

class PhoneNavigator extends StatelessWidget {
  const PhoneNavigator({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        // Show host dashboard if authenticated as admin and viewing coach code
        if (authProvider.isAuthenticated &&
            authProvider.isAdmin &&
            authProvider.hostCoachCode != null) {
          return const HostCoachWorkoutListScreen();
        }

        // Show host dashboard if authenticated as admin
        if (authProvider.isAuthenticated && authProvider.isAdmin) {
          return const HostDashboardScreen();
        }

        // Show home if authenticated as regular coach
        if (authProvider.isAuthenticated) {
          return const PhoneHomeScreen();
        }

        // Default to welcome screen
        return const WelcomeScreen();
      },
    );
  }
}
