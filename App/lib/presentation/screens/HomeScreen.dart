import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../application/DiagnoseUseCase.dart';
import '../Theme.dart';
import '../state/AppState.dart';
import '../widgets/ImagePreview.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _picker = ImagePicker();

  Future<void> _pickGallery() async {
    final file = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1920,
      maxHeight: 1920,
      imageQuality: 90,
    );
    if (file != null && mounted) {
      context.read<AppState>().selectImage(file);
    }
  }

  Future<void> _pickCamera() async {
    final file = await _picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1920,
      maxHeight: 1920,
      imageQuality: 95,
    );
    if (file == null) return;
    final result = kIsWeb ? file : await _crop(file.path);
    if (result != null && mounted) {
      context.read<AppState>().selectImage(result);
    }
  }

  Future<XFile?> _crop(String sourcePath) async {
    final cropped = await ImageCropper().cropImage(
      sourcePath: sourcePath,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Recortar hoja',
          toolbarColor: AppTheme.accentDark,
          toolbarWidgetColor: Colors.white,
          activeControlsWidgetColor: AppTheme.accent,
          lockAspectRatio: false,
          initAspectRatio: CropAspectRatioPreset.original,
        ),
      ],
    );
    return cropped == null ? null : XFile(cropped.path);
  }

  Future<void> _diagnose() async {
    final state = context.read<AppState>();
    if (state.currentImage == null) {
      state.setError('Primero selecciona o captura una imagen.');
      return;
    }
    state.setError(null);
    state.setLoading(true);
    try {
      final coords = await _resolveCoords();
      final useCase = context.read<DiagnoseUseCase>();
      final result = await useCase.execute(
        state.currentImage!,
        lat: coords?.$1,
        lon: coords?.$2,
      );
      if (!mounted) return;
      state.setDiagnoseResult(result);
      state.push(Screen.diagnoseResult);
    } catch (e) {
      if (mounted) state.setError('Error en el diagnóstico: $e');
    } finally {
      if (mounted) state.setLoading(false);
    }
  }

  Future<(double, double)?> _resolveCoords() async {
    try {
      final permission = await Geolocator.requestPermission();
      if (permission != LocationPermission.always &&
          permission != LocationPermission.whileInUse) {
        return null;
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(timeLimit: Duration(seconds: 6)),
      );
      return (position.latitude, position.longitude);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 16),
          _AnimatedSubtitle(hasImage: state.currentImage != null),
          const SizedBox(height: 14),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 280),
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: ScaleTransition(
                  scale: Tween(begin: 0.96, end: 1.0).animate(animation),
                  child: child,
                ),
              ),
              child: _UploadArea(
                key: ValueKey(state.isLoading
                    ? 'loading'
                    : state.currentImage?.path ?? 'empty'),
                imageFile: state.currentImage,
                isLoading: state.isLoading,
              ),
            ),
          ),
          if (state.error != null) ...[
            const SizedBox(height: 10),
            _ErrorBanner(message: state.error!),
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _ActionButton(
                  onPressed: state.isLoading ? null : _pickGallery,
                  icon: Icons.photo_library_outlined,
                  label: 'Galería',
                  color: AppTheme.accent,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ActionButton(
                  onPressed: state.isLoading ? null : _pickCamera,
                  icon: Icons.camera_alt_outlined,
                  label: 'Cámara',
                  color: AppTheme.accentLight,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _ActionButton(
            onPressed: state.currentImage != null && !state.isLoading
                ? _diagnose
                : null,
            icon: Icons.biotech_outlined,
            label: state.isLoading ? 'Analizando...' : 'Diagnosticar',
            color: AppTheme.accentDark,
            loading: state.isLoading,
          ),
        ],
      ),
    );
  }
}

class _AnimatedSubtitle extends StatelessWidget {
  final bool hasImage;
  const _AnimatedSubtitle({required this.hasImage});

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      child: Text(
        key: ValueKey(hasImage),
        hasImage
            ? 'Imagen lista para diagnosticar'
            : 'Sube o captura una hoja de soya',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: hasImage ? AppTheme.accentDark : AppTheme.textPrimary,
          letterSpacing: -0.2,
        ),
      ),
    );
  }
}

class _ActionButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final IconData icon;
  final String label;
  final Color color;
  final bool loading;

  const _ActionButton({
    required this.onPressed,
    required this.icon,
    required this.label,
    required this.color,
    this.loading = false,
  });

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    return GestureDetector(
      onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
      onTapUp: enabled
          ? (_) {
              setState(() => _pressed = false);
              widget.onPressed!();
            }
          : null,
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: Container(
          height: AppTheme.btnHeight,
          decoration: BoxDecoration(
            color: enabled
                ? widget.color
                : widget.color.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(AppTheme.radiusBtn),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              widget.loading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : Icon(widget.icon, size: 18, color: Colors.white),
              const SizedBox(width: 7),
              Text(
                widget.label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UploadArea extends StatelessWidget {
  final dynamic imageFile;
  final bool isLoading;

  const _UploadArea({super.key, required this.imageFile, required this.isLoading});

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return _PlaceholderFrame(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            CircularProgressIndicator(color: AppTheme.accent, strokeWidth: 2),
            SizedBox(height: 12),
            Text(
              'Analizando imagen...',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppTheme.textMuted,
                fontSize: 13,
                letterSpacing: -0.1,
              ),
            ),
          ],
        ),
      );
    }

    if (imageFile == null) {
      return _PlaceholderFrame(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.add_photo_alternate_outlined,
                size: 40, color: AppTheme.accent),
            SizedBox(height: 10),
            Text(
              'Selecciona una imagen\npara comenzar',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppTheme.textMuted,
                fontSize: 13,
                height: 1.5,
                letterSpacing: -0.1,
              ),
            ),
          ],
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppTheme.radiusImg),
      child: ImagePreview(imageFile: imageFile, height: null),
    );
  }
}

class _PlaceholderFrame extends StatelessWidget {
  final Widget child;
  const _PlaceholderFrame({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.radiusImg),
        border: Border.all(
          color: AppTheme.accent.withValues(alpha: 0.35),
          width: 1.5,
          strokeAlign: BorderSide.strokeAlignInside,
        ),
        color: AppTheme.accent.withValues(alpha: 0.04),
      ),
      child: Center(child: child),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppTheme.radiusChip),
        border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Colors.red, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
