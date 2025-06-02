import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'screens/home_screen.dart';
import 'providers/video_provider.dart';
import 'providers/tracking_provider.dart';
import 'providers/overlay_provider.dart';
import 'services/opencv_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Request necessary permissions
  await _requestPermissions();
  
  // Initialize OpenCV
  await OpenCVService.initialize();
  
  runApp(const MotionTrackerApp());
}

Future<void> _requestPermissions() async {
  await [
    Permission.camera,
    Permission.storage,
    Permission.photos,
    Permission.videos,
  ].request();
}

class MotionTrackerApp extends StatelessWidget {
  const MotionTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => VideoProvider()),
        ChangeNotifierProvider(create: (_) => TrackingProvider()),
        ChangeNotifierProvider(create: (_) => OverlayProvider()),
      ],
      child: MaterialApp(
        title: 'Motion Tracker',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          useMaterial3: true,
          brightness: Brightness.dark,
          scaffoldBackgroundColor: const Color(0xFF1A1A1A),
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF2D2D2D),
            foregroundColor: Colors.white,
          ),
        ),
        home: const HomeScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

