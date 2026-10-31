import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/di/injection_container.dart';
import '../../domain/entities/ai_analysis_entity.dart';
import '../../domain/entities/safety_engine_entity.dart';
import '../bloc/ai_analysis_bloc.dart';
import '../bloc/ai_analysis_event.dart';
import '../bloc/ai_analysis_state.dart';
import '../../../../core/theme/app_theme_colors.dart';
import '../../../../core/widgets/bold_card.dart';
import '../pages/ai_verdict_page.dart';
import 'ai_verdict_style.dart';

/// Below this share of recognised ingredients our database result is "weak"
/// and the AI button is offered. Same value as the backend's `SAFE_MIN_COVERAGE`.
const double kAiCoverageThreshold = 0.7;

/// The opt-in "Get AI verdict" block, placed beside (never replacing) the
/// database result via `AnalysisResultView.aiSection`.
///
/// Offered only when our result is weak: verdict `unknown`, or coverage below
/// [kAiCoverageThreshold]. An already-generated AI result ([initial], or
/// loaded now) is always shown. Owns its own [AiAnalysisBloc] (one per
/// screen, created from the service locator).
class AiVerdictSection extends StatelessWidget {
  final AiAnalysisRequest request;
  final SafetyEngine? engine;

  /// The database verdict (`safe` | `caution` | `avoid` | `unknown` ...).
  final String verdict;

  /// A cached AI result that came with the product (`GET /products/{barcode}`).
  final AiAnalysis? initial;

  const AiVerdictSection({
    super.key,
    required this.request,
    required this.engine,
    required this.verdict,
    this.initial,
  });

  static bool shouldOffer({required SafetyEngine? engine, required String verdict}) =>
      verdict == 'unknown' || (engine != null && engine.coverage < kAiCoverageThreshold);

  @override
  Widget build(BuildContext context) {
    final offer = shouldOffer(engine: engine, verdict: verdict);
    if (!offer && initial == null) return const SizedBox.shrink();
    return BlocProvider<AiAnalysisBloc>(
      create: (_) {
        final bloc = sl<AiAnalysisBloc>();
        if (initial == null) bloc.add(const AiCreditsRequested());
        return bloc;
      },
      child: _AiVerdictBody(request: request, engine: engine, initial: initial),
    );
  }
}

class _AiVerdictBody extends StatelessWidget {
  final AiAnalysisRequest request;
  final SafetyEngine? engine;
  final AiAnalysis? initial;

  const _AiVerdictBody({required this.request, required this.engine, required this.initial});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AiAnalysisBloc, AiAnalysisState>(
      builder: (context, state) {
        void open() => AiVerdictPage.open(context, request: request, initial: initial);
        void ask() {
          context.read<AiAnalysisBloc>().add(AiAnalysisRequested(request));
          open();
        }

        final analysis = state.analysis ?? initial;
        if (analysis != null) return _ResultRow(analysis: analysis, onTap: open);
        return switch (state.status) {
          AiAnalysisStatus.loading => _LoadingRow(onTap: open),
          AiAnalysisStatus.failure => _FailureCard(failure: state.failure!, onRetry: ask),
          _ => _OfferCard(engine: engine, credits: state.credits, onAsk: ask),
        };
      },
    );
  }
}

/// The answer, folded to one tappable row; the full result lives on [AiVerdictPage].
class _ResultRow extends StatelessWidget {
  final AiAnalysis analysis;
  final VoidCallback onTap;

  const _ResultRow({required this.analysis, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final accent = analysis.verdict.color(context.colors);
    return _RowShell(
      onTap: onTap,
      leading: Container(
        width: 42.r,
        height: 42.r,
        alignment: Alignment.center,
        decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: accent, width: 3)),
        child: Text(
          '${analysis.score}',
          style: TextStyle(color: Colors.white, fontSize: 13.sp, fontWeight: FontWeight.w700),
        ),
      ),
      title: analysis.verdict.label,
      titleColor: accent,
      subtitle: 'AI estimate · unverified',
    );
  }
}

class _LoadingRow extends StatelessWidget {
  final VoidCallback onTap;

  const _LoadingRow({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return _RowShell(
      onTap: onTap,
      leading: SizedBox.square(
        dimension: 42.r,
        child: Center(
          child: SizedBox.square(
            dimension: 20.r,
            child: CircularProgressIndicator(strokeWidth: 2.5, color: boldAccent(context)),
          ),
        ),
      ),
      title: 'Analysing with AI…',
      titleColor: Colors.white,
      subtitle: 'Tap to watch progress',
    );
  }
}

class _RowShell extends StatelessWidget {
  final VoidCallback onTap;
  final Widget leading;
  final String title;
  final Color titleColor;
  final String subtitle;

  const _RowShell({
    required this.onTap,
    required this.leading,
    required this.title,
    required this.titleColor,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: BoldCard(
        padding: EdgeInsets.fromLTRB(14.w, 12.h, 12.w, 12.h),
        child: Row(
          children: [
            leading,
            SizedBox(width: 14.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(color: titleColor, fontSize: 15.sp, fontWeight: FontWeight.w700)),
                  SizedBox(height: 2.h),
                  Text(subtitle, style: TextStyle(color: context.colors.secondaryText, fontSize: 12.sp)),
                ],
              ),
            ),
            SizedBox(width: 10.w),
            CircleIcon(icon: Icons.arrow_forward_rounded, background: boldAccent(context), foreground: kOnAccent, size: 38.r),
          ],
        ),
      ),
    );
  }
}

/// One dark card: icon tile, short text, compact accent button.
class _OfferCard extends StatelessWidget {
  final SafetyEngine? engine;
  final AiCredits? credits;
  final VoidCallback onAsk;

  const _OfferCard({required this.engine, required this.credits, required this.onAsk});

  @override
  Widget build(BuildContext context) {
    final noCredits = credits != null && credits!.remaining <= 0;
    final e = engine;
    final known = e != null && e.totalCount > 0 ? 'Only ${e.recognisedCount} of ${e.totalCount} known' : 'Little data';
    return BoldCard(
      padding: EdgeInsets.fromLTRB(14.w, 12.h, 12.w, 12.h),
      child: Row(
        children: [
          IconTile(icon: Icons.psychology_rounded, color: boldAccent(context)),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Not enough data for a full verdict',
                  style: TextStyle(color: Colors.white, fontSize: 13.sp, fontWeight: FontWeight.w700),
                ),
                SizedBox(height: 2.h),
                Text(
                  '$known · ${_creditsLine(credits)}',
                  style: TextStyle(color: context.colors.secondaryText, fontSize: 11.sp),
                ),
              ],
            ),
          ),
          SizedBox(width: 10.w),
          _AiButton(label: 'Get AI verdict', onTap: noCredits ? null : onAsk),
        ],
      ),
    );
  }

  static String _creditsLine(AiCredits? c) {
    if (c == null) return '1 credit';
    if (c.remaining <= 0) return 'resets ${formatResetDate(c.resetsAt)}';
    return '${c.remaining} of ${c.limit} left';
  }
}

class _FailureCard extends StatelessWidget {
  final AiFailure failure;
  final VoidCallback onRetry;

  const _FailureCard({required this.failure, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return _InfoCard(
      title: failure.title,
      body: failure.userMessage,
      footer: failure.retryable
          ? Padding(
              padding: EdgeInsets.only(top: 12.h),
              child: TextButton(
                onPressed: onRetry,
                style: TextButton.styleFrom(foregroundColor: boldAccent(context)),
                child: const Text('Try again'),
              ),
            )
          : null,
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final String body;
  final Widget? footer;

  const _InfoCard({required this.title, required this.body, this.footer});

  @override
  Widget build(BuildContext context) {
    return BoldCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconTile(icon: Icons.psychology_rounded, color: context.colors.secondaryText, size: 30.r),
              SizedBox(width: 10.w),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(color: Colors.white, fontSize: 14.5.sp, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          SizedBox(height: 6.h),
          Text(body, style: TextStyle(color: context.colors.secondaryText, fontSize: 12.5.sp, height: 1.4)),
          if (footer != null) footer!,
        ],
      ),
    );
  }
}

/// Accent pill; dimmed and inert when [onTap] is null.
class _AiButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  const _AiButton({required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: onTap == null ? 0.45 : 1,
      child: Pressable(
        onTap: onTap == null
            ? null
            : () {
                HapticFeedback.selectionClick();
                onTap!();
              },
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
          alignment: Alignment.center,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(20.r), color: boldAccent(context)),
          child: Text(
            label,
            style: TextStyle(color: kOnAccent, fontSize: 12.5.sp, fontWeight: FontWeight.w800),
          ),
        ),
      ),
    );
  }
}
