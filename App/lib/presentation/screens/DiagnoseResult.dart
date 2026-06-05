import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../domain/DiagnoseResult.dart' as domain;
import '../Theme.dart';
import '../state/AppState.dart';
import '../widgets/CompositeTreatmentCard.dart';
import '../widgets/DiagnosisImageSection.dart';
import '../widgets/DiseaseFindingCard.dart';
import '../widgets/DiseaseSummaryBanner.dart';
import '../widgets/HealthyBanner.dart';
import '../widgets/OnsetBadge.dart';
import '../widgets/SeverityPanel.dart';

class DiagnoseResult extends StatefulWidget {
  const DiagnoseResult({super.key});

  @override
  State<DiagnoseResult> createState() => _DiagnoseResultState();
}

class _DiagnoseResultState extends State<DiagnoseResult> {
  int _tabIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, _) {
        final result = state.diagnoseResult;
        if (result == null)
          return const Center(child: Text('Sin resultado de diagnóstico'));
        return _ResultLayout(
          image: state.currentImage,
          result: result,
          tabIndex: _tabIndex,
          onTabChanged: (i) => setState(() => _tabIndex = i),
        );
      },
    );
  }
}

class _ResultLayout extends StatelessWidget {
  final dynamic image;
  final domain.DiagnoseResult result;
  final int tabIndex;
  final ValueChanged<int> onTabChanged;

  const _ResultLayout({
    required this.image,
    required this.result,
    required this.tabIndex,
    required this.onTabChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 12),
        const _Title(),
        const SizedBox(height: 10),
        DiagnosisImageSection(image: image, result: result),
        const SizedBox(height: 12),
        _TabSelector(index: tabIndex, onChanged: onTabChanged),
        const SizedBox(height: 12),
        AnimatedSwitcher(
          duration: AppTheme.animNormal,
          switchInCurve: AppTheme.easeOutCurve,
          switchOutCurve: Curves.easeIn,
          transitionBuilder: (child, anim) => FadeTransition(
            opacity: anim,
            child: ScaleTransition(
              scale: Tween(begin: 0.97, end: 1.0).animate(anim),
              child: child,
            ),
          ),
          child: tabIndex == 0
              ? _DiagnosisTab(key: const ValueKey('diag'), result: result)
              : _TreatmentTab(key: const ValueKey('treat'), result: result),
        ),
        const SizedBox(height: 16),
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

class _TabSelector extends StatelessWidget {
  final int index;
  final ValueChanged<int> onChanged;

  const _TabSelector({required this.index, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 38,
      decoration: BoxDecoration(
        color: AppTheme.accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppTheme.radiusBtn),
        border: Border.all(color: AppTheme.accent.withValues(alpha: 0.18)),
      ),
      child: Stack(
        children: [
          AnimatedPositioned(
            duration: AppTheme.animNormal,
            curve: AppTheme.easeOutCurve,
            left: index == 0 ? 2 : null,
            right: index == 1 ? 2 : null,
            top: 2,
            bottom: 2,
            width: MediaQuery.of(context).size.width / 2 - 16,
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.accent,
                borderRadius: BorderRadius.circular(AppTheme.radiusBtn - 2),
              ),
            ),
          ),
          Row(
            children: [
              Expanded(child: _Tab(label: '🔬 Diagnóstico', active: index == 0, onTap: () => onChanged(0))),
              Expanded(child: _Tab(label: '💊 Tratamiento', active: index == 1, onTap: () => onChanged(1))),
            ],
          ),
        ],
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _Tab({required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: active ? Colors.white : AppTheme.accent,
            letterSpacing: -0.1,
          ),
        ),
      ),
    );
  }
}

class _DiagnosisTab extends StatelessWidget {
  final domain.DiagnoseResult result;

  const _DiagnosisTab({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (result.hasSegmentation) ...[
          SeverityPanel(result: result),
          const SizedBox(height: 10),
        ],
        if (result.isHealthy)
          const HealthyBanner()
        else
          DiseaseSummaryBanner(findings: result.findings),
      ],
    );
  }
}

class _TreatmentTab extends StatelessWidget {
  final domain.DiagnoseResult result;

  const _TreatmentTab({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < result.findings.length; i++) ...[
          _StaggeredCard(index: i, child: DiseaseFindingCard(finding: result.findings[i])),
          const SizedBox(height: 10),
        ],
        if (result.onset != null) ...[
          _StaggeredCard(
            index: result.findings.length,
            child: OnsetBadge(onset: result.onset!),
          ),
          const SizedBox(height: 12),
        ],
        if (!result.treatmentPlan.isEmpty)
          _StaggeredCard(
            index: result.findings.length + 1,
            child: CompositeTreatmentCard(
              plan: result.treatmentPlan,
              climateAvailable: result.climate != null,
            ),
          ),
      ],
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
        child: Transform.translate(
          offset: Offset(0, _slide.value),
          child: child,
        ),
      ),
      child: widget.child,
    );
  }
}
