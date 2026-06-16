import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'providers/tray_provider.dart';
import 'providers/iot_provider.dart';
import 'screens/home_dashboard.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => TrayProvider()),
        ChangeNotifierProvider(create: (_) => IotProvider()),
      ],
      child: const BellaBotApp(),
    ),
  );
}

class BellaBotApp extends StatelessWidget {
  const BellaBotApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(360, 800),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp(
          title: 'BellaBot Pro Management',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            brightness: Brightness.dark,
            scaffoldBackgroundColor: const Color(0xFF121212),
            primaryColor: const Color(0xFF00AEEF),
            textTheme: GoogleFonts.montserratTextTheme(
              ThemeData.dark().textTheme,
            ).apply(
              bodyColor: Colors.white,
              displayColor: Colors.white,
            ),
            useMaterial3: true,
          ),
          home: const HomeDashboard(),
        );
      },
    );
  }
}
