import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/di/injection_container.dart';
import '../../domain/entities/ai_analysis_entity.dart';
import '../../domain/entities/safety_engine_entity.dart';
import '../bloc/ai_analysis_bloc.dart';
import '../bloc/ai_analysis_event.dart';
import '../bloc/ai_analysis_state.dart';
import 'ai_result_card.dart';

/// Below this share of recognised ingredients our database result is "weak"
/// and the AI button is offered. Same value as the backend's `SAFE_MIN_COVERAGE`.
const double kAiCoverageThreshold = 0.7;

/// The AI offer card is a flat, opaque surface (not glass) so it reads as a
/// different kind of card from the translucent ones. Change the colours here.
const Color kAiCardSurface = Color(0xFF17232F);
const Color kAiCardInk = Color(0xFF0F1A24); // text on the white button

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

/// Slim one-row bar (not a card): sparkle, short text, compact button.
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
    return Container(
      padding: EdgeInsets.fromLTRB(16.w, 12.h, 12.w, 12.h),
      decoration: BoxDecoration(
        color: kAiCardSurface,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          Icon(Icons.auto_awesome_rounded, color: Colors.white70, size: 18.r),
          SizedBox(width: 10.w),
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
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 11.sp),
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
    final retryable = switch (failure.kind) {
      AiFailureKind.unavailable || AiFailureKind.network || AiFailureKind.other => true,
      _ => false,
    };
    return _InfoCard(
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
  final String title;
  final String body;
  final Widget? footer;
  final bool loading;

  const _InfoCard({required this.title, required this.body, this.footer, this.loading = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(18.r),
      decoration: BoxDecoration(
        color: kAiCardSurface,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              loading
                  ? SizedBox(
                      width: 14.r,
                      height: 14.r,
                      child: const CircularProgressIndicator(strokeWidth: 2, color: Colors.white70),
                    )
                  : Icon(Icons.auto_awesome_rounded, color: Colors.white70, size: 15.r),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(color: Colors.white, fontSize: 14.5.sp, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          SizedBox(height: 6.h),
          Text(body, style: TextStyle(color: Colors.white.withValues(alpha: 0.65), fontSize: 12.5.sp, height: 1.4)),
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

/// White pill; dimmed and inert when [onTap] is null.
class _AiButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  const _AiButton({required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: onTap == null ? 0.45 : 1,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20.r),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20.r),
            color: Colors.white,
          ),
          child: Text(
            label,
            style: TextStyle(color: kAiCardInk, fontSize: 12.5.sp, fontWeight: FontWeight.w800),
          ),
        ),
      ),
    );
  }
}
