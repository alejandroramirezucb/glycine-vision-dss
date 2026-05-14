import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import '../../domain/DiagnoseResult.dart';

enum Screen { home, diagnoseResult }

class AppState extends ChangeNotifier {
  final List<Screen> _stack = [Screen.home];
  XFile? _currentImage;
  DiagnoseResult? _diagnoseResult;
  bool _isLoading = false;
  String? _error;

  Screen get currentScreen => _stack.last;
  bool get canGoBack => _stack.length > 1;
  XFile? get currentImage => _currentImage;
  DiagnoseResult? get diagnoseResult => _diagnoseResult;
  bool get isLoading => _isLoading;
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
    _diagnoseResult = null;
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
    _diagnoseResult = null;
    notifyListeners();
  }

  void setDiagnoseResult(DiagnoseResult result) {
    _diagnoseResult = result;
    notifyListeners();
  }
}
