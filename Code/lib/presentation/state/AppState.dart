import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import '../../domain/Entities.dart';
import '../../domain/ZoneAnalysis.dart';
import '../../domain/ClimateData.dart';
import '../../domain/OnsetEstimate.dart';

enum Screen { home, healthResult, diseaseResult, zoneResult }

class AppState extends ChangeNotifier {
  final List<Screen> _stack = [Screen.home];
  XFile? currentImage;
  PredictionResult? healthResult;
  PredictionResult? diseaseResult;
  ZoneAnalysis? zoneAnalysis;
  ClimateData? climate;
  OnsetEstimate? onset;
  bool isLoading = false;
  bool climateLoading = false;
  String? error;

  Screen get currentScreen => _stack.last;
  bool get canGoBack => _stack.length > 1;

  void push(Screen screen) {
    _stack.add(screen);
    notifyListeners();
  }

  void pop() {
    if (canGoBack) {
      _stack.removeLast();
      notifyListeners();
    }
  }

  void goHome() {
    _stack.clear();
    _stack.add(Screen.home);
    currentImage = null;
    healthResult = null;
    diseaseResult = null;
    zoneAnalysis = null;
    climate = null;
    onset = null;
    error = null;
    notifyListeners();
  }

  void setError(String? err) {
    error = err;
    notifyListeners();
  }

  void setLoading(bool loading) {
    isLoading = loading;
    notifyListeners();
  }

  void selectImage(XFile image) {
    currentImage = image;
    healthResult = null;
    diseaseResult = null;
    zoneAnalysis = null;
    onset = null;
    notifyListeners();
  }

  void setHealthResult(PredictionResult result) {
    healthResult = result;
    notifyListeners();
  }

  void setDiseaseResult(PredictionResult result) {
    diseaseResult = result;
    notifyListeners();
  }

  void setZoneAnalysis(ZoneAnalysis analysis) {
    zoneAnalysis = analysis;
    notifyListeners();
  }

  void setClimate(ClimateData? data) {
    climate = data;
    notifyListeners();
  }

  void setClimateLoading(bool v) {
    climateLoading = v;
    notifyListeners();
  }

  void setOnset(OnsetEstimate? est) {
    onset = est;
    notifyListeners();
  }
}
