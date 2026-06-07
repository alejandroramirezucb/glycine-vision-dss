import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../domain/DiagnoseResult.dart' as domain;
import '../Theme.dart';
import '../state/AppState.dart';
import '../widgets/DiagnosisImageSection.dart';
import '../widgets/DiseaseFindingCard.dart';
import '../widgets/HealthyBanner.dart';

class DiagnoseResult extends StatelessWidget {
  const DiagnoseResult({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, _) {
        final result = state.diagnoseResult;
        if (result == null)
          return const Center(child: Text('Sin resultado de diagnóstico'));
        return _ResultPage(image: state.currentImage, result: result);
      },
    );
  }
}

class _ResultPage extends StatefulWidget {
  final dynamic image;
  final domain.DiagnoseResult result;

  const _ResultPage({required this.image, required this.result});

  @override
  State<_ResultPage> createState() => _ResultPageState();
}

class _ResultPageState extends State<_ResultPage> {
  @override
  Widget build(BuildContext context) {
    final result = widget.result;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 12),
        const _Title(),
        const SizedBox(height: 10),
        DiagnosisImageSection(image: widget.image, result: result),
        const SizedBox(height: 12),
        if (result.isHealthy)
          const HealthyBanner()
        else ...[
          for (var i = 0; i < result.findings.length; i++) ...[
            _StaggeredCard(
              index: i,
              child: DiseaseFindingCard(finding: result.findings[i]),
            ),
            const SizedBox(height: 10),
          ],
          const SizedBox(height: 28),
          _TreatmentNavButton(
            onTap: () => context.read<AppState>().push(Screen.treatment),
          ),
          const SizedBox(height: 24),
        ],
      ],
    );
  }
}

class _Title extends StatelessWidget {
  const _Title();

  @override
  Widget build(BuildContext context) {
    return const Text(
      'Diagnóstico',
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: AppTheme.accentDark,
      ),
    );
  }
}

class _TreatmentNavButton extends StatefulWidget {
  final VoidCallback onTap;

  const _TreatmentNavButton({required this.onTap});

  @override
  State<_TreatmentNavButton> createState() => _TreatmentNavButtonState();
}

class _TreatmentNavButtonState extends State<_TreatmentNavButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: AppTheme.animFast,
        child: Container(
          height: AppTheme.btnHeight,
          decoration: BoxDecoration(
            color: AppTheme.accentDark,
            borderRadius: BorderRadius.circular(AppTheme.radiusBtn),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.medical_services_outlined, size: 18, color: Colors.white),
              SizedBox(width: 8),
              Text(
                'Ver tratamiento',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.1,
                ),
              ),
              SizedBox(width: 6),
              Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _StaggeredCard extends StatefulWidget {
  final int index;
  final Widget child;

  const _StaggeredCard({required this.index, required this.child});

  @override
  State<_StaggeredCard> createState() => _StaggeredCardState();
}

class _StaggeredCardState extends State<_StaggeredCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _opacity;
  late final Animation<double> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: AppTheme.animNormal);
    _opacity = CurvedAnimation(parent: _ctrl, curve: AppTheme.easeOutCurve);
    _slide = Tween(begin: 12.0, end: 0.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: AppTheme.easeOutCurve));
    Future.delayed(AppTheme.staggerDelay * widget.index, () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, child) => Opacity(
        opacity: _opacity.value,
        child: Transform.translate(offset: Offset(0, _slide.value), child: child),
      ),
      child: widget.child,
    );
  }
}
