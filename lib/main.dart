import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app_shell.dart';

const SUPABASE_URL = "https://ficlrtvrrzfiakmciwel.supabase.co";
const SUPABASE_ANON_KEY =
    "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZpY2xydHZycnpmaWFrbWNpd2VsIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjcxMjk0MDQsImV4cCI6MjA4MjcwNTQwNH0.xWuH_-amYd_24R8PURbZXMUDjz--Q9R_RASOdGzsZJI";

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: SUPABASE_URL,
    anonKey: SUPABASE_ANON_KEY,
    debug: true,
  );

  runApp(const TheYoungShallGrowApp());
}

class TheYoungShallGrowApp extends StatelessWidget {
  const TheYoungShallGrowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'theyoungshallgrow',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        cardTheme: const CardThemeData(elevation: 0),
      ),
      home: const AppShell(),
    );
  }
}