import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:video_player_win/video_player_win_plugin.dart';
import 'dart:io' show Platform;
import 'providers/categories_provider.dart';
import 'providers/animals_provider.dart';
import 'providers/purchase_provider.dart';
import 'providers/locale_provider.dart';
import 'utils/app_router.dart';
import 'widgets/app_error_fallback.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isWindows) {
    WindowsVideoPlayer.registerWith();
  }
  
  // Инициализация Firebase
  try {
    // Windows: инициализируем через web-конфиг, чтобы тянуть реальные данные из Firestore.
    if (Platform.isWindows) {
      await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: 'AIzaSyBhL-nacZ_T2FMiLClgx7coFAuU_B6EO4Q',
          authDomain: 'deti-zhivotnie-prod.firebaseapp.com',
          projectId: 'deti-zhivotnie-prod',
          storageBucket: 'deti-zhivotnie-prod.firebasestorage.app',
          messagingSenderId: '854781909795',
          appId: '1:854781909795:web:8cb72a24ef9853e3ea4a96',
          measurementId: 'G-T58Y1GM92L',
        ),
      );
    } else {
      // Для iOS/Android: требуется стандартная настройка (GoogleService-Info.plist / google-services.json)
      await Firebase.initializeApp();
    }
    debugPrint('Firebase initialized successfully');
  } catch (e) {
    debugPrint('Firebase initialization failed: $e');
  }

  ErrorWidget.builder = (FlutterErrorDetails details) {
    return AppErrorFallback(error: details.exception);
  };

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CategoriesProvider()),
        ChangeNotifierProvider(create: (_) => AnimalsProvider()),
        ChangeNotifierProvider(create: (_) => PurchaseProvider()),
        ChangeNotifierProvider(create: (_) => LocaleProvider()..load()),
      ],
      child: Consumer<LocaleProvider>(
        builder: (context, localeProvider, _) {
          return MaterialApp.router(
            title: 'Дети и Животные',
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFF6366F1),
                brightness: Brightness.light,
              ),
              useMaterial3: true,
              fontFamily: 'SF Pro Rounded',
              fontFamilyFallback: const ['SF Pro Text', 'Segoe UI', 'Roboto'],
            ),
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('ru', 'RU'),
              Locale('en', 'US'),
              Locale('es', 'ES'),
              Locale('hi', 'IN'),
            ],
            locale: localeProvider.locale,
            routerConfig: appRouter,
          );
        },
      ),
    );
  }
}
