import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/app_theme_colors.dart';
import '../../../../core/widgets/bold_card.dart';
import '../../domain/entities/natural_remedy_entity.dart';

/// Leafy green for the natural-remedy feature (not the brand accent: the result
/// screen's one accent block stays the verdict card).
const kRemedyGreen = Color(0xFF8BD17C);

/// Soft amber for the patch test and cautions (a warning, not an error).
const _amber = Color(0xFFFFC56B);

/// The line under the header: was this free (saved) or did it use a credit?
String remedyCreditHint(NaturalRemedyResult r) {
  if (r.cached) return 'Saved answer · no credit used';
  final left = r.creditsRemaining;
  return left == null ? 'Used 1 AI credit' : 'Used 1 AI credit · $left left this week';
}

/// The recipe page body: hints, the patch-test box first (read before
/// making anything), one card per remedy, then the disclaimer. Sections fade
/// and rise in one after another, unless reduce-motion is on.
class RemedyRecipeList extends StatefulWidget {
  final NaturalRemedyResult result;

  const RemedyRecipeList({super.key, required this.result});

  @override
  State<RemedyRecipeList> createState() => _RemedyRecipeListState();
}

class _RemedyRecipeListState extends State<RemedyRecipeList> with SingleTickerProviderStateMixin {
  static const _stagger = 90; // ms between sections
  static const _duration = 420; // ms per section

  late final List<Widget> _sections = [
    _Hints(result: widget.result),
    _PatchTest(note: widget.result.patchTestNote),
    for (final r in widget.result.remedies) _RemedyCard(remedy: r),
    _Disclaimer(text: widget.result.disclaimer),
  ];
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: Duration(milliseconds: _duration + _stagger * _sections.length),
  );
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    MediaQuery.disableAnimationsOf(context) ? _c.value = 1 : _c.forward();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Widget _animated(int i) {
    final total = _c.duration!.inMilliseconds;
    final start = (i * _stagger) / total;
    final end = ((i * _stagger + _duration) / total).clamp(0.0, 1.0);
    final anim = CurvedAnimation(parent: _c, curve: Interval(start, end, curve: Curves.easeOutCubic));
    return FadeTransition(
      opacity: anim,
      child: SlideTransition(
        position: Tween(begin: const Offset(0, 0.08), end: Offset.zero).animate(anim),
        child: Padding(padding: EdgeInsets.only(bottom: 12.h), child: _sections[i]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 24.h),
      children: [for (var i = 0; i < _sections.length; i++) _animated(i)],
    );
  }
}

class _Hints extends StatelessWidget {
  final NaturalRemedyResult result;

  const _Hints({required this.result});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Center(
      child: Column(
        children: [
          Text('AI suggestion · not medical advice', style: TextStyle(color: colors.secondaryText, fontSize: 12.sp)),
          SizedBox(height: 2.h),
          Text(remedyCreditHint(result), style: TextStyle(color: colors.secondaryText, fontSize: 11.sp)),
        ],
      ),
    );
  }
}

class _PatchTest extends StatelessWidget {
  final String note;

  const _PatchTest({required this.note});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        color: _amber.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.back_hand_outlined, color: _amber, size: 20.r),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Patch test first',
                    style: TextStyle(color: _amber, fontSize: 13.sp, fontWeight: FontWeight.w800)),
                SizedBox(height: 3.h),
                Text(note, style: TextStyle(color: Colors.white, fontSize: 13.sp, height: 1.35)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RemedyCard extends StatelessWidget {
  final NaturalRemedyEntity remedy;

  const _RemedyCard({required this.remedy});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final r = remedy;
    return BoldCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconTile(icon: Icons.eco_rounded, color: kRemedyGreen, size: 36.r),
              SizedBox(width: 12.w),
              Expanded(
                child: Text(r.name,
                    style: TextStyle(color: Colors.white, fontSize: 17.sp, fontWeight: FontWeight.w800, height: 1.2)),
              ),
            ],
          ),
          if (r.replaces.isNotEmpty) ...[
            SizedBox(height: 8.h),
            Text('Instead of your ${r.replaces}', style: TextStyle(color: colors.secondaryText, fontSize: 12.sp)),
          ],
          const _Label('Ingredients'),
          for (final i in r.ingredients) _IngredientRow(ingredient: i),
          const _Label('Steps'),
          for (var n = 0; n < r.steps.length; n++) _StepRow(number: n + 1, text: r.steps[n]),
          if (r.howOften != null || r.keepsFor != null) ...[
            SizedBox(height: 14.h),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (r.howOften != null) Expanded(child: _Fact(icon: Icons.event_repeat_rounded, label: 'How often', value: r.howOften!)),
                if (r.howOften != null && r.keepsFor != null) SizedBox(width: 10.w),
                if (r.keepsFor != null) Expanded(child: _Fact(icon: Icons.timer_outlined, label: 'Keeps for', value: r.keepsFor!)),
              ],
            ),
          ],
          if (r.why != null) _Note(icon: Icons.lightbulb_outline_rounded, color: kRemedyGreen, text: r.why!),
          if (r.caution != null) _Note(icon: Icons.warning_amber_rounded, color: _amber, text: r.caution!),
        ],
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;

  const _Label(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: 16.h, bottom: 8.h),
      child: Text(text.toUpperCase(),
          style: TextStyle(
              color: context.colors.secondaryText, fontSize: 11.sp, fontWeight: FontWeight.w800, letterSpacing: 0.8)),
    );
  }
}

class _IngredientRow extends StatelessWidget {
  final RemedyIngredient ingredient;

  const _IngredientRow({required this.ingredient});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 6.h),
      child: Row(
        children: [
          Container(
            width: 6.r,
            height: 6.r,
            decoration: const BoxDecoration(color: kRemedyGreen, shape: BoxShape.circle),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(ingredient.item,
                style: TextStyle(color: Colors.white, fontSize: 14.sp, fontWeight: FontWeight.w600)),
          ),
          if (ingredient.amount.isNotEmpty)
            Text(ingredient.amount, style: TextStyle(color: context.colors.secondaryText, fontSize: 13.sp)),
        ],
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  final int number;
  final String text;

  const _StepRow({required this.number, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 10.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24.r,
            height: 24.r,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: kRemedyGreen.withValues(alpha: 0.18), shape: BoxShape.circle),
            child: Text('$number',
                style: TextStyle(color: kRemedyGreen, fontSize: 12.sp, fontWeight: FontWeight.w800)),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(top: 2.h),
              child: Text(text, style: TextStyle(color: Colors.white, fontSize: 14.sp, height: 1.35)),
            ),
          ),
        ],
      ),
    );
  }
}

class _Fact extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _Fact({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: colors.secondaryText, size: 14.r),
              SizedBox(width: 5.w),
              Text(label, style: TextStyle(color: colors.secondaryText, fontSize: 11.sp, fontWeight: FontWeight.w700)),
            ],
          ),
          SizedBox(height: 4.h),
          Text(value, style: TextStyle(color: Colors.white, fontSize: 13.sp, fontWeight: FontWeight.w600, height: 1.3)),
        ],
      ),
    );
  }
}

class _Note extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;

  const _Note({required this.icon, required this.color, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: 12.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 18.r),
          SizedBox(width: 10.w),
          Expanded(child: Text(text, style: TextStyle(color: Colors.white, fontSize: 13.sp, height: 1.35))),
        ],
      ),
    );
  }
}

class _Disclaimer extends StatelessWidget {
  final String text;

  const _Disclaimer({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      child: Text(text, style: TextStyle(color: context.colors.secondaryText, fontSize: 11.sp, height: 1.4)),
    );
  }
}

/// Centred icon + title + body, with an optional action (empty and failure states).
class RemedyMessage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  final String? actionLabel;
  final VoidCallback? onAction;

  const RemedyMessage({super.key, required this.icon, required this.title, required this.body, this.actionLabel, this.onAction});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 36.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: colors.secondaryText, size: 44.r),
            SizedBox(height: 14.h),
            Text(title,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, fontSize: 16.sp, fontWeight: FontWeight.w700)),
            SizedBox(height: 6.h),
            Text(body,
                textAlign: TextAlign.center,
                style: TextStyle(color: colors.secondaryText, fontSize: 13.sp, height: 1.4)),
            if (actionLabel != null) ...[
              SizedBox(height: 18.h),
              TextButton(
                onPressed: onAction,
                child: Text(actionLabel!, style: TextStyle(color: colors.neonEmerald, fontWeight: FontWeight.w700)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
