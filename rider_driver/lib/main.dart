import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:device_preview/device_preview.dart';

import 'package:rider_driver/pages/launch.dart';
import 'package:rider_driver/provider/current_location_provider.dart';
import 'package:rider_driver/provider/delivery_provider.dart';

import 'package:rider_driver/utils/app_colors.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(DevicePreview(enabled: kDebugMode, builder: (_) => const DriverApp()));
}

class DriverApp extends StatelessWidget {
  const DriverApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CurrentLocationProvider()),
        ChangeNotifierProvider(
          create: (_) => DeliveryProvider()..initializeOrder(), // 🔥 IMPORTANT
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Rider Driver',

        locale: DevicePreview.locale(context),
        builder: DevicePreview.appBuilder,

        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: AppColors.primary,
            background: AppColors.background,
          ),
          useMaterial3: true,
          scaffoldBackgroundColor: AppColors.background,
        ),

        home: const LaunchPage(),
      ),
    );
  }
}
