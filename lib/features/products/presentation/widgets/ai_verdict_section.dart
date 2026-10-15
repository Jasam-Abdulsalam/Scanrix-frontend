import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_theme_colors.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../domain/entities/ai_analysis_entity.dart';
import '../../domain/entities/safety_engine_entity.dart';
import '../bloc/ai_analysis_bloc.dart';
import '../bloc/ai_analysis_event.dart';
import '../bloc/ai_analysis_state.dart';
import 'ai_result_card.dart';

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
        final analysis = state.analysis ?? initial;
        if (analysis != null) return AiResultCard(analysis: analysis);
        void ask() => context.read<AiAnalysisBloc>().add(AiAnalysisRequested(request));
        return switch (state.status) {
          AiAnalysisStatus.loading => const _InfoCard(
              icon: Icons.auto_awesome_rounded,
              title: 'Analysing with AI…',
              body: 'This can take up to half a minute.',
              loading: true,
            ),
          AiAnalysisStatus.failure => _FailureCard(failure: state.failure!, onRetry: ask),
          _ => _OfferCard(engine: engine, credits: state.credits, onAsk: ask),
        };
      },
    );
  }
}

class _OfferCard extends StatelessWidget {
  final SafetyEngine? engine;
  final AiCredits? credits;
  final VoidCallback onAsk;

  const _OfferCard({required this.engine, required this.credits, required this.onAsk});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final noCredits = credits != null && credits!.remaining <= 0;
    final e = engine;
    final body = e != null && e.totalCount > 0
        ? 'Only ${e.recognisedCount} of ${e.totalCount} ingredients are in our database. '
            'Get an AI estimate for the whole product. It is shown separately and never changes our result.'
        : 'Get an AI estimate for this product. It is shown separately and never changes our result.';
    return _InfoCard(
      icon: Icons.auto_awesome_rounded,
      title: 'Not enough data for a full verdict',
      body: body,
      footer: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 14.h),
          SizedBox(
            width: double.infinity,
            child: PrimaryButton(
              enabled: !noCredits,
              onTap: noCredits ? null : onAsk,
              child: Center(child: Text('Get AI verdict', style: TextStyle(fontSize: 15.sp))),
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            _creditsLine(credits),
            style: TextStyle(color: colors.secondaryText, fontSize: 11.5.sp),
          ),
        ],
      ),
    );
  }

  static String _creditsLine(AiCredits? c) {
    if (c == null) return 'Uses 1 AI credit.';
    if (c.remaining <= 0) return 'No AI credits left. They reset ${formatResetDate(c.resetsAt)}.';
    return 'Uses 1 AI credit · ${c.remaining} of ${c.limit} left this week';
  }
}

class _FailureCard extends StatelessWidget {
  final AiFailure failure;
  final VoidCallback onRetry;

  const _FailureCard({required this.failure, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final retryable = switch (failure.kind) {
      AiFailureKind.unavailable || AiFailureKind.network || AiFailureKind.other => true,
      _ => false,
    };
    return _InfoCard(
      icon: Icons.info_outline_rounded,
      title: switch (failure.kind) {
        AiFailureKind.ingredientsMissing => 'No ingredient list yet',
        AiFailureKind.creditsExhausted => 'No AI credits left',
        _ => 'AI verdict unavailable',
      },
      body: failureMessage(failure),
      footer: retryable
          ? Padding(
              padding: EdgeInsets.only(top: 12.h),
              child: TextButton(onPressed: onRetry, child: const Text('Try again')),
            )
          : null,
    );
  }

  /// User-facing text per failure; never shows raw server output for known kinds.
  static String failureMessage(AiFailure f) => switch (f.kind) {
        AiFailureKind.ingredientsMissing =>
          'We have no ingredient list for this product. Go back and scan the ingredients label, then ask for the AI verdict.',
        AiFailureKind.creditsExhausted => f.resetsAt != null
            ? 'You have used all AI credits for this week. They reset ${formatResetDate(f.resetsAt!)}.'
            : 'You have used all AI credits for this week.',
        AiFailureKind.unavailable => 'AI is not available right now. You were not charged, so please try again later.',
        AiFailureKind.notFound => 'We could not find this product.',
        AiFailureKind.network => 'No internet connection. Check your connection and try again.',
        AiFailureKind.other => 'Something went wrong. Please try again.',
      };
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  final Widget? footer;
  final bool loading;

  const _InfoCard({required this.icon, required this.title, required this.body, this.footer, this.loading = false});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return GlassCard(
      padding: EdgeInsets.all(18.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              loading
                  ? SizedBox(
                      width: 20.r,
                      height: 20.r,
                      child: CircularProgressIndicator(strokeWidth: 2.4, color: colors.neonEmerald),
                    )
                  : Icon(icon, color: colors.neonEmerald, size: 20.r),
              SizedBox(width: 10.w),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(color: Colors.white, fontSize: 15.sp, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Text(body, style: TextStyle(color: colors.secondaryText, fontSize: 12.5.sp, height: 1.4)),
          if (footer != null) footer!,
        ],
      ),
    );
  }
}

/// "Mon 20 Oct" (local time) for the weekly credit reset.
String formatResetDate(DateTime resetsAt) {
  const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  final d = resetsAt.toLocal();
  return '${days[d.weekday - 1]} ${d.day} ${months[d.month - 1]}';
}
