import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'application/DiagnoseUseCase.dart';
import 'domain/Diagnoser.dart';
import 'domain/Protocols.dart';
import 'infrastructure/DiagnoserFactory.dart';
import 'infrastructure/OpenMeteoClient.dart';
import 'infrastructure/TreatmentRepo.dart';
import 'presentation/Theme.dart';
import 'presentation/screens/DiagnoseResult.dart';
import 'presentation/screens/HomeScreen.dart';
import 'presentation/state/AppState.dart';
import 'presentation/widgets/AppHeader.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    final treatmentRepo = await JsonTreatmentRepository.load();
    final climateRepo = OpenMeteoClient();
    final diagnoser = await DiagnoserFactory.build(
      treatments: treatmentRepo,
      climateRepo: climateRepo,
    );
    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AppState()),
          Provider<TreatmentRepository>.value(value: treatmentRepo),
          Provider<ClimateRepository>.value(value: climateRepo),
          Provider<Diagnoser>.value(value: diagnoser),
          Provider(create: (ctx) => DiagnoseUseCase(ctx.read<Diagnoser>())),
        ],
        child: const GlycineVisionApp(),
      ),
    );
  } catch (e) {
    runApp(MaterialApp(
      home: Scaffold(body: Center(child: Text('Error al iniciar: $e'))),
    ));
  }
}

class GlycineVisionApp extends StatelessWidget {
  const GlycineVisionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Glycine Vision DSS',
      theme: AppTheme.themeData(),
      home: const MainScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, _) {
        final isDesktop = switch (Theme.of(context).platform) {
          TargetPlatform.windows ||
          TargetPlatform.macOS ||
          TargetPlatform.linux => true,
          _ => false,
        };
        final width = isDesktop
            ? AppTheme.phoneWidth
            : MediaQuery.of(context).size.width.clamp(0.0, AppTheme.phoneWidth);

        return Scaffold(
          backgroundColor: AppTheme.bgPage,
          body: SafeArea(
            child: Column(
              children: [
                Center(
                  child: SizedBox(
                    width: width,
                    child: AppHeader(
                      canGoBack: state.canGoBack,
                      onHome: state.goHome,
                      onBack: state.pop,
                    ),
                  ),
                ),
                Expanded(
                  child: switch (state.currentScreen) {
                    Screen.home => Center(
                        child: SizedBox(
                          width: width,
                          child: const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 10),
                            child: HomeScreen(),
                          ),
                        ),
                      ),
                    Screen.diagnoseResult => SingleChildScrollView(
                        child: Center(
                          child: Container(
                            width: width,
                            padding: const EdgeInsets.all(10),
                            child: const DiagnoseResult(),
                          ),
                        ),
                      ),
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
