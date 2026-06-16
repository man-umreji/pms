import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:pms/screens/change_password_screen/view_model/change_password_view_model.dart';
import 'package:pms/screens/dashbord/view_model/dashbord_view_model.dart';
import 'package:pms/screens/get_action_point_view_screen/view_model/get_action_view_view_model.dart';
import 'package:pms/screens/login_screen/view_model/login_screen_view_model.dart';
import 'package:pms/screens/meating_action_point_screen/view_mode/meating_action_point_view_model.dart';
import 'package:pms/screens/meating_screen/view_model/meating_view_model.dart';
import 'package:pms/screens/splash_screen/view_model/splash_screen_view_model.dart';
import 'package:provider/provider.dart';
import 'package:pms/screens/splash_screen/view/splash_screen_view.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
         ChangeNotifierProvider(create: (_) => SplashProvider()),
         ChangeNotifierProvider(create: (_) => LoginProvider()),
         ChangeNotifierProvider(create: (_) => ChangePasswordViewModel()),
         ChangeNotifierProvider(create: (_) => MeetingViewModel()),
         ChangeNotifierProvider(create: (_) => MeatingActionPointViewModel()),
         ChangeNotifierProvider(create: (_) => DashbordViewModel()),
         ChangeNotifierProvider(create: (_) => GetActionPointViewModel()),

      ],
      child: ScreenUtilInit(
        designSize: const Size(375, 812),
        minTextAdapt: true,
        splitScreenMode: true,
        builder: (context, child) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'PMS',
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
              useMaterial3: true,
            ),
            home: const SplashScreenSimple(),
          );
        },
      ),
    );
  }
}