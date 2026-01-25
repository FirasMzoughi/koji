import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:koji/core/router.dart';
import 'package:koji/core/theme.dart';
import 'package:koji/core/theme_provider.dart';

import 'package:koji/core/supabase_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Supabase
  await SupabaseConfig.initialize();
  
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}



class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    
    return MaterialApp.router(
      title: 'Kôji',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightThemeData(context),
      darkTheme: AppTheme.darkThemeData(context),
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}
