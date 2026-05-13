import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'application/DiseaseCase.dart';
import 'application/HealthCase.dart';
import 'application/ZoneAnalysisCase.dart';
import 'application/ClimateCase.dart';
import 'application/OnsetCase.dart';
import 'infrastructure/Classifier.dart'
    if (dart.library.js_interop) 'infrastructure/ClassifierStub.dart';
import 'infrastructure/HttpClassifier.dart';
import 'infrastructure/HttpZoneAnalyzer.dart';
import 'infrastructure/LocalZoneAnalyzer.dart'
    if (dart.library.js_interop) 'infrastructure/LocalZoneAnalyzerStub.dart';
import 'infrastructure/OpenMeteoClient.dart';
import 'infrastructure/OnsetEstimatorImpl.dart';
import 'domain/Protocols.dart';
import 'infrastructure/TreatmentRepo.dart';
import 'presentation/screens/DiseaseResult.dart';
import 'presentation/screens/HealthResult.dart';
import 'presentation/screens/HomeScreen.dart';
import 'presentation/screens/ZoneResult.dart';
import 'presentation/state/AppState.dart';
import 'presentation/Theme.dart';
import 'presentation/widgets/AppHeader.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const serverBase = 'http://localhost:8001';

  try {
    final ImageClassifier healthClassifier;
    final ImageClassifier diseaseClassifier;
    final ZoneAnalyzer zoneAnalyzer;

    if (kIsWeb) {
      healthClassifier =
          const HttpClassifier('$serverBase/api/classify/health');
      diseaseClassifier =
          const HttpClassifier('$serverBase/api/classify/disease');
      zoneAnalyzer = const HttpZoneAnalyzer('$serverBase/api/analyze/zones');
    } else {
      final healthLocal = await TfliteClassifier.load(
        'assets/models/hs/model.tflite',
        'assets/models/hs/labels.txt',
      );
      final diseaseLocal = await TfliteClassifier.load(
        'assets/models/pd/model_unquant.tflite',
        'assets/models/pd/labels.txt',
      );
      healthClassifier = healthLocal;
      diseaseClassifier = diseaseLocal;
      zoneAnalyzer = LocalZoneAnalyzer(
        healthModel: healthLocal,
        diseaseModel: diseaseLocal,
      );
    }

    final treatmentRepo = await JsonTreatmentRepository.load();
    final climateRepo = OpenMeteoClient();
    const onsetEstimator = OnsetEstimatorImpl();

    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AppState()),
          Provider.value(value: PredictHealthUseCase(healthClassifier)),
          Provider.value(value: PredictDiseaseUseCase(diseaseClassifier)),
          Provider.value(value: AnalyzeZonesUseCase(zoneAnalyzer)),
          Provider.value(value: FetchClimateUseCase(climateRepo)),
          Provider.value(value: const EstimateOnsetUseCase(onsetEstimator)),
          Provider<ClimateRepository>.value(value: climateRepo),
          Provider<OnsetEstimator>.value(value: onsetEstimator),
          Provider.value(value: treatmentRepo as TreatmentRepository),
        ],
        child: const GlycineVisionApp(),
      ),
    );
  } catch (e) {
    runApp(MaterialApp(
      home: Scaffold(
        body: Center(child: Text('Error al iniciar: $e')),
      ),
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

  Widget _buildScreen(Screen screen) => switch (screen) {
        Screen.home => const HomeScreen(),
        Screen.healthResult => const HealthResult(),
        Screen.diseaseResult => const DiseaseResult(),
        Screen.zoneResult => const ZoneResult(),
      };

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, _) {
        final isDesktop = switch (Theme.of(context).platform) {
          TargetPlatform.windows ||
          TargetPlatform.macOS ||
          TargetPlatform.linux =>
            true,
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
                  child: SingleChildScrollView(
                    child: Center(
                      child: Container(
                        width: width,
                        padding: const EdgeInsets.all(10),
                        child: _buildScreen(state.currentScreen),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
