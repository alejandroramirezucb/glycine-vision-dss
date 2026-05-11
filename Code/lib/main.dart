import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'application/DiseaseCase.dart';
import 'application/HealthCase.dart';
import 'infrastructure/Classifier.dart'
    if (dart.library.js_interop) 'infrastructure/ClassifierStub.dart';
import 'infrastructure/HttpClassifier.dart';
import 'domain/Protocols.dart';
import 'infrastructure/TreatmentRepo.dart';
import 'presentation/screens/DiseaseResult.dart';
import 'presentation/screens/HealthResult.dart';
import 'presentation/screens/HomeScreen.dart';
import 'presentation/state/AppState.dart';
import 'presentation/Theme.dart';
import 'presentation/widgets/AppHeader.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const serverBase = 'http://localhost:8001';

  try {
    final ImageClassifier healthClassifier;
    final ImageClassifier diseaseClassifier;

    if (kIsWeb) {
      healthClassifier =
          const HttpClassifier('$serverBase/api/classify/health');
      diseaseClassifier =
          const HttpClassifier('$serverBase/api/classify/disease');
    } else {
      healthClassifier = await TfliteClassifier.load(
        'assets/models/hs/model.tflite',
        'assets/models/hs/labels.txt',
      );
      diseaseClassifier = await TfliteClassifier.load(
        'assets/models/pd/model_unquant.tflite',
        'assets/models/pd/labels.txt',
      );
    }

    final treatmentRepo = await JsonTreatmentRepository.load();

    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AppState()),
          Provider.value(value: PredictHealthUseCase(healthClassifier)),
          Provider.value(value: PredictDiseaseUseCase(diseaseClassifier)),
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
                child: Container(
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
