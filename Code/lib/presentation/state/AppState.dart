import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import '../../domain/Entities.dart';

enum Screen { home, healthResult, diseaseResult }

class AppState extends ChangeNotifier {
  final List<Screen> _stack = [Screen.home];
  XFile? currentImage;
  PredictionResult? healthResult;
  PredictionResult? diseaseResult;
  bool isLoading = false;
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
}
