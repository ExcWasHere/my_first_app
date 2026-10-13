import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app_router.dart';
import 'features/auth/presentation/providers/auth_providers.dart';
import 'features/notifications/data/fcm_push_repository.dart';
import 'features/notifications/presentation/providers/push_providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  final push = FcmPushRepository();
  await push.init();

  runApp(ProviderScope(
    overrides: [pushRepositoryProvider.overrideWithValue(push)],
    child: const MyApp(),
  ));
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  StreamSubscription<String>? _routeSub;

  @override
  void initState() {
    super.initState();

    final router = ref.read(routerProvider);
    final push = ref.read(pushRepositoryProvider);
    _routeSub = push.routes.listen(router.go);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref.read(authStateProvider.future);
      final route = await push.takeLaunchRoute();
      if (route != null) router.go(route);
    });
  }

  @override
  void dispose() {
    _routeSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'Campus Notify',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF4F7DC9),
        useMaterial3: true,
      ),
      routerConfig: router,
    );
  }
}
