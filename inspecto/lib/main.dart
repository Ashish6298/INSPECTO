import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'presentation/providers/request_provider.dart';
import 'presentation/providers/collection_provider.dart';
import 'presentation/providers/environment_provider.dart';
import 'presentation/providers/theme_provider.dart';
import 'data/repositories/api_repository_impl.dart';
import 'data/repositories/collection_repository_impl.dart';
import 'data/repositories/environment_repository_impl.dart';
import 'data/datasources/api_remote_data_source.dart';
import 'presentation/screens/splash_screen.dart';

void main() {
  final apiRemoteDataSource = ApiRemoteDataSource();
  final apiRepository = ApiRepositoryImpl(
    remoteDataSource: apiRemoteDataSource,
  );
  final collectionRepository = CollectionRepositoryImpl();
  final environmentRepository = EnvironmentRepositoryImpl();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(
          create: (_) => RequestProvider(apiRepository: apiRepository),
        ),
        ChangeNotifierProvider(
          create: (_) => CollectionProvider(repository: collectionRepository),
        ),
        ChangeNotifierProvider(
          create: (_) => EnvironmentProvider(repository: environmentRepository),
        ),
      ],
      child: const InspectoApp(),
    ),
  );
}

class InspectoApp extends StatelessWidget {
  const InspectoApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return MaterialApp(
      title: 'Inspecto',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeProvider.themeMode,
      home: const SplashScreen(),
    );
  }
}
