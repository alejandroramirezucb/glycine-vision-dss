import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import '../../domain/DiagnoseResult.dart';

enum Screen { home, diagnoseResult, treatment }

enum DiagnosisStep { idle, analyzing, classifying, fetching, done }

class AppState extends ChangeNotifier {
  final List<Screen> _stack = [Screen.home];
  XFile? _currentImage;
  DiagnoseResult? _diagnoseResult;
  bool _isLoading = false;
  DiagnosisStep _diagnosisStep = DiagnosisStep.idle;
  String? _error;
  bool _cancelled = false;

  Screen get currentScreen => _stack.last;
  bool get canGoBack => _stack.length > 1;
  XFile? get currentImage => _currentImage;
  DiagnoseResult? get diagnoseResult => _diagnoseResult;
  bool get isLoading => _isLoading;
  DiagnosisStep get diagnosisStep => _diagnosisStep;
  String? get error => _error;
  bool get isCancelled => _cancelled;

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
    _diagnoseResult = null;
    _error = null;
    _isLoading = false;
    _diagnosisStep = DiagnosisStep.idle;
    _cancelled = false;
    notifyListeners();
  }

  void setError(String? err) {
    _error = err;
    notifyListeners();
  }

  void setLoading(bool loading) {
    _isLoading = loading;
    if (!loading) _diagnosisStep = DiagnosisStep.idle;
    notifyListeners();
  }

  void setDiagnosisStep(DiagnosisStep step) {
    _diagnosisStep = step;
    notifyListeners();
  }

  void cancelDiagnosis() {
    _cancelled = true;
    _isLoading = false;
    _diagnosisStep = DiagnosisStep.idle;
    _error = null;
    notifyListeners();
  }

  void selectImage(XFile image) {
    _currentImage = image;
    _diagnoseResult = null;
    _cancelled = false;
    _error = null;
    notifyListeners();
  }

  void setDiagnoseResult(DiagnoseResult result) {
    _diagnoseResult = result;
    notifyListeners();
  }
}
