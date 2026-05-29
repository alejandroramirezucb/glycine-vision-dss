import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'application/DiagnoseUseCase.dart';
import 'domain/Diagnoser.dart';
import 'domain/Protocols.dart';
import 'infrastructure/Classifier.dart'
    if (dart.library.js_interop) 'infrastructure/ClassifierWebStub.dart';
import 'infrastructure/HttpDiagnoser.dart';
import 'infrastructure/LocalDiagnoser.dart'
    if (dart.library.js_interop) 'infrastructure/LocalDiagnoserWebStub.dart';
import 'infrastructure/TfliteSegmenter.dart'
    if (dart.library.js_interop) 'infrastructure/TfliteSegmenterWebStub.dart';
import 'infrastructure/OnsetEstimatorImpl.dart';
import 'infrastructure/OpenMeteoClient.dart';
import 'infrastructure/TreatmentRepo.dart';
import 'presentation/Theme.dart';
import 'presentation/screens/DiagnoseResult.dart';
import 'presentation/screens/HomeScreen.dart';
import 'presentation/state/AppState.dart';
import 'presentation/widgets/AppHeader.dart';

const _serverBase = 'http://localhost:8001';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    final treatmentRepo = await JsonTreatmentRepository.load();
    final climateRepo = OpenMeteoClient();
    const onsetEstimator = OnsetEstimatorImpl();
    final diagnoser = await _buildDiagnoser(
      treatmentRepo: treatmentRepo,
      climateRepo: climateRepo,
      onsetEstimator: onsetEstimator,
    );

    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AppState()),
          Provider<TreatmentRepository>.value(value: treatmentRepo),
          Provider<ClimateRepository>.value(value: climateRepo),
          Provider<OnsetEstimator>.value(value: onsetEstimator),
          Provider<Diagnoser>.value(value: diagnoser),
          Provider(create: (ctx) => DiagnoseUseCase(ctx.read<Diagnoser>())),
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

Future<Diagnoser> _buildDiagnoser({
  required TreatmentRepository treatmentRepo,
  required ClimateRepository climateRepo,
  required OnsetEstimator onsetEstimator,
}) async {
  if (kIsWeb) {
    return HttpDiagnoser(
      endpoint: '$_serverBase/api/diagnose',
      treatments: treatmentRepo,
      onsetEstimator: onsetEstimator,
    );
  }
  final healthModel = await TfliteClassifier.load(
    modelAsset: 'assets/models/hs/model.tflite',
    labelsAsset: 'assets/models/hs/labels.txt',
    inputSize: 240,
  );
  final diseaseModel = await TfliteClassifier.load(
    modelAsset: 'assets/models/pd/model_unquant.tflite',
    labelsAsset: 'assets/models/pd/labels.txt',
    thresholdsAsset: 'assets/models/pd/thresholds.json',
  );
  TfliteSegmenter? segmenter;
  try {
    segmenter = await TfliteSegmenter.load(
      modelAsset: 'assets/models/seg/model_seg.tflite',
    );
  } catch (_) {}
  return LocalDiagnoser(
    healthModel: healthModel,
    diseaseModel: diseaseModel,
    segmenter: segmenter,
    treatments: treatmentRepo,
    climateRepo: climateRepo,
    onsetEstimator: onsetEstimator,
  );
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

  Widget _renderScreen(Screen screen) => switch (screen) {
        Screen.home => const HomeScreen(),
        Screen.diagnoseResult => const DiagnoseResult(),
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
                        child: _renderScreen(state.currentScreen),
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
