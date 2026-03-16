import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF0A0A0A),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  // Portrait lock doesn't apply on web — browsers handle orientation differently
  if (!kIsWeb) {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  // On web, Netlify blocks .env files so credentials are embedded directly.
  // Supabase anon keys are designed to be public — security is enforced via RLS.
  String supabaseUrl;
  String supabaseAnonKey;
  if (kIsWeb) {
    supabaseUrl = 'https://wluqvfoenfyawnmynpuw.supabase.co';
    supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6IndsdXF2Zm9lbmZ5YXdubXlucHV3Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzMzMDQ0NDAsImV4cCI6MjA4ODg4MDQ0MH0.CwR2Qmpaxv5Wn01esDoH9_PqEoo1RgzPMZ6_FtjhXxA';
  } else {
    await dotenv.load(fileName: '.env');
    supabaseUrl = dotenv.env['SUPABASE_URL']!;
    supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY']!;
  }

  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
  );

  runApp(const ProviderScope(child: YIApp()));
}
