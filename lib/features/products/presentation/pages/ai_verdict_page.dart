import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/app_theme_colors.dart';
import '../../../../core/widgets/bold_card.dart';
import '../../domain/entities/ai_analysis_entity.dart';
import '../bloc/ai_analysis_bloc.dart';
import '../bloc/ai_analysis_event.dart';
import '../bloc/ai_analysis_state.dart';
import '../widgets/ai_thinking_view.dart';
import '../widgets/ai_verdict_style.dart';
import '../widgets/status_colors.dart';

/// Full screen for the AI verdict: the thinking animation while the request
/// runs, then the result, or the failure with Try again.
///
/// Shares the product page's [AiAnalysisBloc] (passed with
/// `BlocProvider.value`), so going back mid-request neither cancels nor
/// re-charges: the product page's row keeps showing progress and reopens
/// this screen.
class AiVerdictPage extends StatelessWidget {
  final AiAnalysisRequest request;

  /// Cached answer that came with the product, shown when the bloc has none.
  final AiAnalysis? initial;

  const AiVerdictPage({super.key, required this.request, this.initial});

  /// Pushes this screen with the caller's [AiAnalysisBloc].
  static Future<void> open(BuildContext context, {required AiAnalysisRequest request, AiAnalysis? initial}) {
    final bloc = context.read<AiAnalysisBloc>();
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BlocProvider.value(
          value: bloc,
          child: AiVerdictPage(request: request, initial: initial),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'AI verdict',
          style: TextStyle(color: Colors.white, fontSize: 16.sp, fontWeight: FontWeight.w600),
        ),
      ),
      body: BlocConsumer<AiAnalysisBloc, AiAnalysisState>(
        // One light tap of haptics when the answer lands: the moment worth marking.
        listenWhen: (a, b) => a.status == AiAnalysisStatus.loading && b.status == AiAnalysisStatus.loaded,
        listener: (_, _) => HapticFeedback.lightImpact(),
        builder: (context, state) {
          final analysis = state.analysis ?? initial;
          final Widget child;
          if (analysis != null) {
            child = _ResultView(key: const ValueKey('result'), analysis: analysis);
          } else if (state.status == AiAnalysisStatus.failure) {
            child = _FailureView(
              key: const ValueKey('failure'),
              failure: state.failure!,
              onRetry: () => context.read<AiAnalysisBloc>().add(AiAnalysisRequested(request)),
            );
          } else {
            child = const AiThinkingView(key: ValueKey('thinking'));
          }
          // The result "materialises": fade + a small scale-up, no bounce.
          return AnimatedSwitcher(
            duration: Duration(milliseconds: reduceMotion ? 200 : 450),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (child, anim) => FadeTransition(
              opacity: anim,
              child: reduceMotion
                  ? child
                  : ScaleTransition(scale: Tween(begin: 0.96, end: 1.0).animate(anim), child: child),
            ),
            child: child,
          );
        },
      ),
    );
  }
}

/// One-screen summary: a solid hero card with the verdict and score, the
/// short summary, a three-column breakdown that opens the full lists in
/// bottom sheets, and the biggest concern.
class _ResultView extends StatefulWidget {
  final AiAnalysis analysis;

  const _ResultView({super.key, required this.analysis});

  @override
  State<_ResultView> createState() => _ResultViewState();
}

class _ResultViewState extends State<_ResultView> with SingleTickerProviderStateMixin {
  /// Drives the score ring fill, the count-up and the staggered entrance.
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _c.value = 1;
    } else if (_c.value == 0) {
      _c.forward();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _showConcerns(List<AiConcern> concerns) => _openSheet(
        context,
        icon: Icons.warning_amber_rounded,
        color: kWarnAmber,
        title: 'Watch out',
        body: _Grouped(children: [for (final c in concerns) _ConcernRow(concern: c)]),
      );

  void _showPositives(List<String> positives) => _openSheet(
        context,
        icon: Icons.check_circle_outline_rounded,
        color: context.colors.neonEmerald,
        title: 'Good to know',
        body: _Grouped(children: [for (final p in positives) _PositiveRow(text: p)]),
      );

  void _showUnclear(List<String> names) => _openSheet(
        context,
        icon: Icons.help_outline_rounded,
        color: context.colors.secondaryText,
        title: names.length == 1 ? '1 ingredient couldn\'t be identified' : '${names.length} ingredients couldn\'t be identified',
        body: _UnclearList(names: names),
      );

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final a = widget.analysis;
    final accent = boldAccent(context);
    final concerns = a.identifiedConcerns;
    final unidentified = a.unidentifiedIngredients;

    final sections = <Widget>[
      _HeroCard(analysis: a, accent: accent, progress: _c),
      if (a.summary.isNotEmpty) _SummaryCard(text: a.summary, accent: accent),
      if (a.adjustedByDatabase)
        _Callout(
          icon: Icons.shield_outlined,
          color: kWarnAmber,
          text: 'We lowered this verdict because our database knows a hazard in this product.',
        ),
      StatColumnsCard(progress: _c, columns: [
        StatColumnData(
          icon: Icons.warning_amber_rounded,
          color: kWarnAmber,
          count: concerns.length,
          label: 'Watch out',
          onTap: () => _showConcerns(concerns),
        ),
        StatColumnData(
          icon: Icons.check_circle_outline_rounded,
          color: colors.neonEmerald,
          count: a.positives.length,
          label: 'Good',
          onTap: () => _showPositives(a.positives),
        ),
        StatColumnData(
          icon: Icons.help_outline_rounded,
          color: colors.secondaryText,
          count: unidentified.length,
          label: 'Unclear',
          onTap: () => _showUnclear(unidentified),
        ),
      ]),
      // The AI lists concerns most important first, so the first is the one to show.
      BoldCard(
        padding: EdgeInsets.all(14.r),
        child: concerns.isEmpty
            ? _Row(
                icon: Icons.check_rounded,
                color: colors.neonEmerald,
                title: 'Nothing specific stood out',
                subtitle: 'No specific concerns among the ingredients the AI recognised.',
              )
            : _ConcernRow(
                concern: concerns.first,
                label: concerns.length > 1 ? 'Biggest concern · ${concerns.length - 1} more' : 'Biggest concern',
                actionColor: accent,
                onTap: () => _showConcerns(concerns),
              ),
      ),
      _Footer(analysis: a),
    ];

    // Still scrollable as a safety net (small phones, large text), but sized
    // to fit one screen on a typical phone.
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 32.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < sections.length; i++) ...[
            if (i > 0) SizedBox(height: 12.h),
            _Reveal(controller: _c, index: i, child: sections[i]),
          ],
        ],
      ),
    );
  }
}

/// Staggered entrance: each section fades in and rises 12 px, a beat after
/// the previous one. Critically damped (ease-out, no overshoot).
class _Reveal extends StatelessWidget {
  final AnimationController controller;
  final int index;
  final Widget child;

  const _Reveal({required this.controller, required this.index, required this.child});

  @override
  Widget build(BuildContext context) {
    final start = math.min(index * 0.07, 0.5);
    final anim = CurvedAnimation(parent: controller, curve: Interval(start, start + 0.5, curve: Curves.easeOutCubic));
    return AnimatedBuilder(
      animation: anim,
      builder: (_, child) => Opacity(
        opacity: anim.value,
        child: Transform.translate(offset: Offset(0, 12.h * (1 - anim.value)), child: child),
      ),
      child: child,
    );
  }
}

/// The one solid accent card: verdict, what it means, and the score ring.
class _HeroCard extends StatelessWidget {
  final AiAnalysis analysis;
  final Color accent;
  final Animation<double> progress;

  const _HeroCard({required this.analysis, required this.accent, required this.progress});

  @override
  Widget build(BuildContext context) {
    final fill = CurvedAnimation(parent: progress, curve: const Interval(0.0, 0.8, curve: Curves.easeOutCubic));
    // Status color (emerald / amber / red / grey) only ever sits on black here.
    final status = analysis.verdict.color(context.colors);
    // Rounded notch in the top edge, like the stacked cards in the references.
    return ClipPath(
      clipper: TopNotchClipper(radius: 28.r, notchWidth: 56.w, notchDepth: 7.h),
      child: Container(
        padding: EdgeInsets.fromLTRB(20.w, 16.h, 16.w, 20.h),
        decoration: BoxDecoration(color: accent, borderRadius: BorderRadius.circular(28.r)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Flexible: large text sizes shrink the pill instead of overflowing the row.
                Flexible(
                  child: Container(
                    padding: EdgeInsets.fromLTRB(9.w, 5.h, 11.w, 5.h),
                    decoration: BoxDecoration(color: kOnAccent, borderRadius: BorderRadius.circular(20.r)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 7.r,
                          height: 7.r,
                          decoration: BoxDecoration(color: status, shape: BoxShape.circle),
                        ),
                        SizedBox(width: 6.w),
                        Flexible(
                          child: Text(
                            'AI estimate · unverified',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: Colors.white, fontSize: 11.sp, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                CircleIcon(icon: analysis.verdict.icon, background: kOnAccent, foreground: status, size: 38.r),
              ],
            ),
            SizedBox(height: 14.h),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        analysis.verdict.label,
                        style: TextStyle(
                          color: kOnAccent,
                          fontSize: 26.sp,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.8,
                          height: 1.05,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        analysis.verdict.meaning,
                        style: TextStyle(color: kOnAccent.withValues(alpha: 0.72), fontSize: 13.sp, height: 1.4),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 14.w),
                AnimatedBuilder(
                  animation: fill,
                  builder: (_, _) => AccentRing(size: 92.r, score: analysis.score, fraction: fill.value),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// The AI's summary, clamped to three lines with Read more when it is longer.
class _SummaryCard extends StatefulWidget {
  final String text;
  final Color accent;

  const _SummaryCard({required this.text, required this.accent});

  @override
  State<_SummaryCard> createState() => _SummaryCardState();
}

class _SummaryCardState extends State<_SummaryCard> {
  static const _clampLines = 3;
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(color: Colors.white.withValues(alpha: 0.86), fontSize: 14.5.sp, height: 1.5);
    final duration = MediaQuery.disableAnimationsOf(context) ? Duration.zero : const Duration(milliseconds: 280);
    return BoldCard(
      child: LayoutBuilder(
        builder: (context, box) {
          final painter = TextPainter(
            text: TextSpan(text: widget.text, style: style),
            maxLines: _clampLines,
            textDirection: Directionality.of(context),
            textScaler: MediaQuery.textScalerOf(context),
          )..layout(maxWidth: box.maxWidth);
          final overflows = painter.didExceedMaxLines;
          painter.dispose();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'In short',
                style: TextStyle(color: Colors.white, fontSize: 16.sp, fontWeight: FontWeight.w700, letterSpacing: -0.2),
              ),
              SizedBox(height: 8.h),
              AnimatedSize(
                duration: duration,
                curve: Curves.easeOutCubic,
                alignment: Alignment.topCenter,
                child: Text(
                  widget.text,
                  style: style,
                  maxLines: _expanded ? null : _clampLines,
                  overflow: _expanded ? null : TextOverflow.ellipsis,
                ),
              ),
              if (overflows || _expanded)
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _expanded = !_expanded);
                  },
                  child: Padding(
                    padding: EdgeInsets.only(top: 8.h),
                    child: Text(
                      _expanded ? 'Show less' : 'Read more',
                      style: TextStyle(color: widget.accent, fontSize: 13.sp, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

/// Full list in a bottom sheet (drag handle, rounded top), so the page itself
/// stays one screen long.
Future<void> _openSheet(
  BuildContext context, {
  required IconData icon,
  required Color color,
  required String title,
  required Widget body,
}) {
  final colors = context.colors;
  final maxHeight = MediaQuery.sizeOf(context).height * 0.75;
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    backgroundColor: colors.background,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28.r))),
    builder: (_) => ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 28.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 4.w),
              child: Row(
                children: [
                  Icon(icon, color: color, size: 20.r),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(color: Colors.white, fontSize: 18.sp, fontWeight: FontWeight.w700, letterSpacing: -0.3),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 14.h),
            body,
          ],
        ),
      ),
    ),
  );
}

/// Rows in one borderless card, split by dividers that start after the icon.
class _Grouped extends StatelessWidget {
  final List<Widget> children;

  const _Grouped({required this.children});

  @override
  Widget build(BuildContext context) {
    return BoldCard(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 4.h),
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) Divider(height: 1, thickness: 1, indent: 56.w, color: Colors.white.withValues(alpha: 0.07)),
            Padding(padding: EdgeInsets.symmetric(vertical: 10.h), child: children[i]),
          ],
        ],
      ),
    );
  }
}

/// Leading circle icon, text, and (when tappable) a solid circular arrow
/// button on the right.
class _Row extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String? label;
  final String? subtitle;
  final Widget? below;
  final VoidCallback? onTap;
  final Color? actionColor;

  const _Row({
    required this.icon,
    required this.color,
    required this.title,
    this.label,
    this.subtitle,
    this.below,
    this.onTap,
    this.actionColor,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final row = Row(
      children: [
        IconTile(icon: icon, color: color),
        SizedBox(width: 14.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (label != null) ...[
                Text(
                  label!,
                  style: TextStyle(color: colors.secondaryText, fontSize: 11.5.sp, fontWeight: FontWeight.w600),
                ),
                SizedBox(height: 2.h),
              ],
              Text(
                title,
                style: TextStyle(color: Colors.white, fontSize: 15.sp, fontWeight: FontWeight.w700, height: 1.3),
              ),
              if (subtitle != null) ...[
                SizedBox(height: 2.h),
                Text(subtitle!, style: TextStyle(color: colors.secondaryText, fontSize: 13.sp, height: 1.4)),
              ],
              if (below != null) ...[SizedBox(height: 8.h), below!],
            ],
          ),
        ),
        if (onTap != null) ...[
          SizedBox(width: 10.w),
          CircleIcon(
            icon: Icons.arrow_forward_rounded,
            background: actionColor ?? colors.neonEmerald,
            foreground: kOnAccent,
            size: 38.r,
          ),
        ],
      ],
    );
    return onTap == null
        ? row
        : Pressable(
            onTap: () {
              HapticFeedback.selectionClick();
              onTap!();
            },
            child: row,
          );
  }
}

class _ConcernRow extends StatelessWidget {
  final AiConcern concern;
  final String? label;
  final VoidCallback? onTap;
  final Color? actionColor;

  const _ConcernRow({required this.concern, this.label, this.onTap, this.actionColor});

  @override
  Widget build(BuildContext context) => _Row(
        icon: concernIcon(concern.effect),
        color: kWarnAmber,
        label: label,
        title: sentenceCase(concern.ingredient),
        subtitle: sentenceCase(concern.effect),
        onTap: onTap,
        actionColor: actionColor,
      );
}

/// "dimethicone (antifoaming, emollient)" -> icon by role, the name, and
/// one small pill per role.
class _PositiveRow extends StatelessWidget {
  final String text;

  const _PositiveRow({required this.text});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final p = splitPositive(text);
    return _Row(
      icon: positiveIcon(p.roles),
      color: colors.neonEmerald,
      title: sentenceCase(p.name),
      below: p.roles.isEmpty
          ? null
          : Wrap(
              spacing: 6.w,
              runSpacing: 6.h,
              children: [
                for (final role in p.roles)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.07),
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                    child: Text(
                      role,
                      style: TextStyle(color: colors.secondaryText, fontSize: 11.5.sp, fontWeight: FontWeight.w500),
                    ),
                  ),
              ],
            ),
    );
  }
}

/// Names the AI could not identify, shown in their own sheet: usually
/// label-scan misreads rather than something to worry about.
class _UnclearList extends StatelessWidget {
  final List<String> names;

  const _UnclearList({required this.names});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return BoldCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Often a misread from the label photo. Rescanning in good light can help.',
            style: TextStyle(color: colors.secondaryText, fontSize: 13.sp, height: 1.4),
          ),
          SizedBox(height: 14.h),
          Wrap(
            spacing: 6.w,
            runSpacing: 6.h,
            children: [
              for (final name in names)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: Text(name, style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12.sp)),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Callout extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;

  const _Callout({required this.icon, required this.color, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 18.r),
          SizedBox(width: 10.w),
          Expanded(child: Text(text, style: TextStyle(color: color, fontSize: 13.sp, height: 1.4))),
        ],
      ),
    );
  }
}

/// The disclaimer as one plain line of fine print (no box), so the page
/// ends quietly. It must always be shown: the answer is unverified.
class _Footer extends StatelessWidget {
  final AiAnalysis analysis;

  const _Footer({required this.analysis});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 8.w),
      child: Text(
        analysis.disclaimer.isNotEmpty
            ? analysis.disclaimer
            : 'AI-generated estimate. It has not been verified and is not medical advice.',
        textAlign: TextAlign.center,
        style: TextStyle(color: context.colors.secondaryText, fontSize: 11.sp, height: 1.45),
      ),
    );
  }
}

class _FailureView extends StatelessWidget {
  final AiFailure failure;
  final VoidCallback onRetry;

  const _FailureView({super.key, required this.failure, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 32.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleIcon(
              icon: switch (failure.kind) {
                AiFailureKind.network => Icons.wifi_off_rounded,
                AiFailureKind.creditsExhausted => Icons.hourglass_empty_rounded,
                AiFailureKind.ingredientsMissing => Icons.document_scanner_outlined,
                _ => Icons.cloud_off_rounded,
              },
              background: boldCardFill(colors),
              foreground: colors.secondaryText,
              size: 64.r,
            ),
            SizedBox(height: 20.h),
            Text(
              failure.title,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontSize: 19.sp, fontWeight: FontWeight.w700, letterSpacing: -0.3),
            ),
            SizedBox(height: 8.h),
            Text(
              failure.userMessage,
              textAlign: TextAlign.center,
              style: TextStyle(color: colors.secondaryText, fontSize: 14.sp, height: 1.45),
            ),
            if (failure.retryable) ...[
              SizedBox(height: 24.h),
              Pressable(
                onTap: onRetry,
                child: Container(
                  padding: EdgeInsets.fromLTRB(22.w, 6.h, 6.w, 6.h),
                  decoration: BoxDecoration(color: colors.neonEmerald, borderRadius: BorderRadius.circular(30.r)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Try again',
                        style: TextStyle(color: kOnAccent, fontSize: 14.sp, fontWeight: FontWeight.w700),
                      ),
                      SizedBox(width: 12.w),
                      CircleIcon(icon: Icons.refresh_rounded, background: kOnAccent, foreground: colors.neonEmerald, size: 36.r),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
