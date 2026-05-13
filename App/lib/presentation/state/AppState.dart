import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import '../../domain/Entities.dart';
import '../../domain/ZoneAnalysis.dart';
import '../../domain/ClimateData.dart';
import '../../domain/OnsetEstimate.dart';

enum Screen { home, healthResult, diseaseResult, zoneResult }

class AppState extends ChangeNotifier {
  final List<Screen> _stack = [Screen.home];
  XFile? _currentImage;
  PredictionResult? _healthResult;
  PredictionResult? _diseaseResult;
  ZoneAnalysis? _zoneAnalysis;
  ClimateData? _climate;
  OnsetEstimate? _onset;
  bool _isLoading = false;
  bool _climateLoading = false;
  String? _error;

  Screen get currentScreen => _stack.last;
  bool get canGoBack => _stack.length > 1;
  XFile? get currentImage => _currentImage;
  PredictionResult? get healthResult => _healthResult;
  PredictionResult? get diseaseResult => _diseaseResult;
  ZoneAnalysis? get zoneAnalysis => _zoneAnalysis;
  ClimateData? get climate => _climate;
  OnsetEstimate? get onset => _onset;
  bool get isLoading => _isLoading;
  bool get climateLoading => _climateLoading;
  String? get error => _error;

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
    _stack
      ..clear()
      ..add(Screen.home);
    _currentImage = null;
    _healthResult = null;
    _diseaseResult = null;
    _zoneAnalysis = null;
    _climate = null;
    _onset = null;
    _error = null;
    notifyListeners();
  }

  void setError(String? err) {
    _error = err;
    notifyListeners();
  }

  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void selectImage(XFile image) {
    _currentImage = image;
    _healthResult = null;
    _diseaseResult = null;
    _zoneAnalysis = null;
    _onset = null;
    notifyListeners();
  }

  void setHealthResult(PredictionResult result) {
    _healthResult = result;
    notifyListeners();
  }

  void setDiseaseResult(PredictionResult result) {
    _diseaseResult = result;
    notifyListeners();
  }

  void setZoneAnalysis(ZoneAnalysis analysis) {
    _zoneAnalysis = analysis;
    notifyListeners();
  }

  void setClimate(ClimateData? data) {
    _climate = data;
    notifyListeners();
  }

  void setClimateLoading(bool v) {
    _climateLoading = v;
    notifyListeners();
  }

  void setOnset(OnsetEstimate? est) {
    _onset = est;
    notifyListeners();
  }
}
