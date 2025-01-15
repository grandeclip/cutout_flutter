import 'package:flutter/material.dart';

import 'routes.dart';
import 'screens/home_screen.dart';
import 'screens/u2net_screen.dart';
import 'screens/sam_screen.dart';

const title = 'CutOut Example';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: title,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      initialRoute: AppRoutes.home,
      routes: {
        AppRoutes.home: (context) => const HomeScreen(),
        AppRoutes.u2net: (context) => const U2NetScreen(),
        AppRoutes.sam: (context) => const SAMScreen(),
      },
    );
  }
}
