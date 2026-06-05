import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../domain/DiagnoseResult.dart' as domain;
import '../../domain/DiseaseFinding.dart';
import '../LabelNames.dart';
import '../PathogenColors.dart';
import '../Theme.dart';
import '../state/AppState.dart';
import '../widgets/DiagnosisImageSection.dart';
import '../widgets/DiseaseFindingCard.dart';
import '../widgets/DiseaseSummaryBanner.dart';
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
          _CombinedSeverityPanel(result: result),
          const SizedBox(height: 10),
          DiseaseSummaryBanner(findings: result.findings),
          const SizedBox(height: 12),
          for (var i = 0; i < result.findings.length; i++) ...[
            _StaggeredCard(
              index: i,
              child: DiseaseFindingCard(finding: result.findings[i]),
            ),
            const SizedBox(height: 10),
          ],
          _TreatmentNavButton(
            onTap: () => context.read<AppState>().push(Screen.treatment),
          ),
          const SizedBox(height: 12),
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

class _CombinedSeverityPanel extends StatelessWidget {
  final domain.DiagnoseResult result;

  const _CombinedSeverityPanel({required this.result});

  @override
  Widget build(BuildContext context) {
    final sev = result.globalSeverityPct;
    final sevColor = AppTheme.severityPctColor(sev);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        border: Border.all(color: AppTheme.border),
        boxShadow: const [
          BoxShadow(color: Color(0x06000000), blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Severidad foliar',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              const Spacer(),
              Text(
                '${sev.toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: sevColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          _SeverityBar(pct: sev, color: sevColor),
          if (result.findings.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Divider(height: 1, color: AppTheme.border),
            const SizedBox(height: 10),
            for (final finding in result.findings) ...[
              _DiseaseSeverityRow(finding: finding, totalSev: sev),
              const SizedBox(height: 8),
            ],
          ],
        ],
      ),
    );
  }
}

class _SeverityBar extends StatelessWidget {
  final double pct;
  final Color color;

  const _SeverityBar({required this.pct, required this.color});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: LinearProgressIndicator(
        value: (pct / 100).clamp(0.0, 1.0),
        backgroundColor: AppTheme.border,
        valueColor: AlwaysStoppedAnimation<Color>(color),
        minHeight: 8,
      ),
    );
  }
}

class _DiseaseSeverityRow extends StatelessWidget {
  final DiseaseFinding finding;
  final double totalSev;

  const _DiseaseSeverityRow({required this.finding, required this.totalSev});

  @override
  Widget build(BuildContext context) {
    final color = pathogenColor(finding.pathogenClass);
    final pct = finding.avgSeverityPct;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                labelToEs(finding.pathogenClass),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
            ),
            Text(
              '${pct.toStringAsFixed(1)}%',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(
            value: (pct / 100).clamp(0.0, 1.0),
            backgroundColor: color.withValues(alpha: 0.12),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 5,
          ),
        ),
      ],
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
