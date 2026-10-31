import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/widgets/bold_card.dart';
import '../../../products/presentation/pages/product_detail_page.dart';
import '../../domain/entities/alternative_product_entity.dart';
import '../widgets/alternative_card.dart';
import '../widgets/alternative_style.dart';

const _ink = AltPalette.ink;

/// Opens [AlternativeDetailPage] with a fade, so the card's Hero flight is the
/// main motion.
Future<void> openAlternativeDetail(
  BuildContext context, {
  required AlternativeProductEntity item,
  required AltPalette palette,
  int? originalScore,
  String? originalName,
}) {
  return Navigator.of(context).push(
    PageRouteBuilder<void>(
      transitionDuration: const Duration(milliseconds: 550),
      reverseTransitionDuration: const Duration(milliseconds: 420),
      pageBuilder: (_, _, _) => AlternativeDetailPage(
        item: item,
        palette: palette,
        originalScore: originalScore,
        originalName: originalName,
      ),
      transitionsBuilder: (_, animation, _, child) => FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: const Interval(0.2, 1, curve: Curves.easeOut)),
        child: child,
      ),
    ),
  );
}

/// Full-screen detail of one alternative. The carousel card grows into the
/// background (Hero), the score counts up, and the rows slide up one by one.
/// Dark text on the card's bright gradient, so the status bar icons go dark too.
class AlternativeDetailPage extends StatefulWidget {
  final AlternativeProductEntity item;
  final AltPalette palette;
  final int? originalScore;
  final String? originalName;

  const AlternativeDetailPage({
    super.key,
    required this.item,
    required this.palette,
    this.originalScore,
    this.originalName,
  });

  @override
  State<AlternativeDetailPage> createState() => _AlternativeDetailPageState();
}

class _AlternativeDetailPageState extends State<AlternativeDetailPage> with SingleTickerProviderStateMixin {
  static const _rowStagger = 60; // ms between rows
  static const _rowDuration = 420; // ms per row

  late final List<Widget> _rows = _buildRows();
  late final AnimationController _rowsCtrl = AnimationController(
    vsync: this,
    duration: Duration(milliseconds: _rowDuration + _rowStagger * _rows.length),
  );
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (MediaQuery.disableAnimationsOf(context)) {
      _rowsCtrl.value = 1;
    } else {
      // Let the Hero flight land first.
      Future<void>.delayed(const Duration(milliseconds: 280), () {
        if (mounted) _rowsCtrl.forward();
      });
    }
  }

  @override
  void dispose() {
    _rowsCtrl.dispose();
    super.dispose();
  }

  List<Widget> _buildRows() {
    final item = widget.item;
    final gain = item.scoreGainOver(widget.originalScore);
    return [
      if (widget.originalScore != null && item.overallScore != null)
        _ComparisonRow(
          originalName: widget.originalName,
          originalScore: widget.originalScore!,
          score: item.overallScore!,
          gain: gain,
        ),
      _InfoRow(
        icon: item.concernCount == 0 ? Icons.verified_rounded : Icons.flag_rounded,
        label: item.concernLabel,
      ),
      if (item.priceLabel != null) _InfoRow(icon: Icons.sell_rounded, label: 'Around ${item.priceLabel}'),
      if (item.category != null) _InfoRow(icon: Icons.category_rounded, label: item.category!),
      if (item.highlights.isNotEmpty) const _SectionLabel('Why it\'s a better pick'),
      for (final h in item.highlights) _InfoRow(icon: Icons.check_rounded, label: h),
    ];
  }

  Widget _animatedRow(int i) {
    final total = _rowsCtrl.duration!.inMilliseconds;
    final start = (i * _rowStagger) / total;
    final end = ((i * _rowStagger) + _rowDuration) / total;
    final anim = CurvedAnimation(parent: _rowsCtrl, curve: Interval(start, end.clamp(0, 1), curve: Curves.easeOutCubic));
    return FadeTransition(
      opacity: anim,
      child: SlideTransition(
        position: Tween(begin: const Offset(0, 0.4), end: Offset.zero).animate(anim),
        child: Padding(padding: EdgeInsets.only(bottom: 10.h), child: _rows[i]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final palette = widget.palette;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: palette.edge,
        body: Stack(
          children: [
            Positioned.fill(
              child: Hero(
                tag: altCardHeroTag(item.barcode),
                flightShuttleBuilder: altCardFlightShuttle(palette),
                child: AlternativeCardBackground(palette: palette, radius: 0),
              ),
            ),
            SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 0),
                    child: Row(
                      children: [
                        Pressable(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            Navigator.of(context).maybePop();
                          },
                          child: CircleIcon(
                            icon: Icons.arrow_back_ios_new_rounded,
                            background: Colors.white.withValues(alpha: 0.5),
                            foreground: _ink,
                            size: 42.r,
                          ),
                        ),
                        const Spacer(),
                        AltThumb(url: item.imageUrl, size: 42.r),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 24.h),
                      children: [
                        Text(
                          item.brand,
                          style: TextStyle(color: _ink, fontSize: 15.sp, fontWeight: FontWeight.w800),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          item.name,
                          style: TextStyle(color: _ink, fontSize: 24.sp, fontWeight: FontWeight.w800, height: 1.2),
                        ),
                        SizedBox(height: 22.h),
                        Center(
                          child: Hero(
                            tag: altScoreHeroTag(item.barcode),
                            child: item.overallScore == null || reduceMotion
                                ? AltScoreText(score: item.overallScore, height: 110.h)
                                : TweenAnimationBuilder<int>(
                                    tween: IntTween(begin: 0, end: item.overallScore!),
                                    duration: const Duration(milliseconds: 800),
                                    curve: Curves.easeOutCubic,
                                    builder: (_, v, _) => AltScoreText(score: v, height: 110.h),
                                  ),
                          ),
                        ),
                        SizedBox(height: 10.h),
                        Center(child: AltVerdictChip(verdict: item.verdict)),
                        SizedBox(height: 28.h),
                        for (var i = 0; i < _rows.length; i++) _animatedRow(i),
                        SizedBox(height: 8.h),
                        Text(
                          'Scores come from our ingredient database. Always check the label before buying.',
                          style: TextStyle(color: _ink.withValues(alpha: 0.6), fontSize: 11.sp, height: 1.4),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 8.h),
                    child: _DarkButton(
                      label: 'View full analysis',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(builder: (_) => ProductDetailPage(barcode: item.barcode)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Solid dark pill: the emerald PrimaryButton clashes with the bright card
/// colours, so the detail screen uses ink instead.
class _DarkButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _DarkButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _ink,
      borderRadius: BorderRadius.circular(32.r),
      child: InkWell(
        borderRadius: BorderRadius.circular(32.r),
        onTap: onTap,
        child: SizedBox(
          width: double.infinity,
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 16.h),
            child: Center(
              child: Text(
                label,
                style: TextStyle(color: Colors.white, fontSize: 15.sp, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ComparisonRow extends StatelessWidget {
  final String? originalName;
  final int originalScore;
  final int score;
  final int? gain;

  const _ComparisonRow({this.originalName, required this.originalScore, required this.score, this.gain});

  @override
  Widget build(BuildContext context) {
    return _RowShell(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  originalName ?? 'Your scan',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: _ink.withValues(alpha: 0.6), fontSize: 12.sp),
                ),
                SizedBox(height: 2.h),
                Text(
                  '$originalScore → $score',
                  style: TextStyle(color: _ink, fontSize: 18.sp, fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
          if (gain != null)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
              decoration: BoxDecoration(color: _ink, borderRadius: BorderRadius.circular(14.r)),
              child: Text(
                '+$gain pts',
                style: TextStyle(color: Colors.white, fontSize: 13.sp, fontWeight: FontWeight.w800),
              ),
            ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoRow({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return _RowShell(
      child: Row(
        children: [
          Icon(icon, color: _ink, size: 18.r),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(label, style: TextStyle(color: _ink, fontSize: 14.sp, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;

  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: 8.h, left: 4.w),
      child: Text(
        text,
        style: TextStyle(color: _ink.withValues(alpha: 0.7), fontSize: 13.sp, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _RowShell extends StatelessWidget {
  final Widget child;

  const _RowShell({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(18.r),
      ),
      child: child,
    );
  }
}
