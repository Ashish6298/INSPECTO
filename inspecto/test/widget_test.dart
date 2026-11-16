import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:inspecto/main.dart';
import 'package:inspecto/presentation/providers/theme_provider.dart';
import 'package:inspecto/presentation/providers/request_provider.dart';
import 'package:inspecto/presentation/providers/collection_provider.dart';
import 'package:inspecto/presentation/providers/environment_provider.dart';
import 'package:inspecto/presentation/providers/history_provider.dart';
import 'package:inspecto/data/repositories/api_repository_impl.dart';
import 'package:inspecto/data/repositories/collection_repository_impl.dart';
import 'package:inspecto/data/repositories/environment_repository_impl.dart';
import 'package:inspecto/data/datasources/api_remote_data_source.dart';
import 'package:inspecto/data/datasources/history_local_data_source.dart';
import 'package:inspecto/presentation/screens/splash_screen.dart';

void main() {
  testWidgets('InspectoApp smoke test - initializes and renders SplashScreen',
      (WidgetTester tester) async {
    final apiRemoteDataSource = ApiRemoteDataSource();
    final apiRepository = ApiRepositoryImpl(
      remoteDataSource: apiRemoteDataSource,
    );
    final collectionRepository = CollectionRepositoryImpl();
    final environmentRepository = EnvironmentRepositoryImpl();
    final historyLocalDataSource = HistoryLocalDataSource();

    await tester.pumpWidget(
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
            create: (_) =>
                EnvironmentProvider(repository: environmentRepository),
          ),
          ChangeNotifierProvider(
            create: (_) =>
                HistoryProvider(dataSource: historyLocalDataSource),
          ),
        ],
        child: const InspectoApp(),
      ),
    );

    expect(find.byType(SplashScreen), findsOneWidget);
    expect(find.text('PROFESSIONAL API TOOLKIT'), findsOneWidget);

    // Advance past the splash timer and transition
    await tester.pump(const Duration(milliseconds: 3600));
    await tester.pump(const Duration(milliseconds: 1000));
  });
}
