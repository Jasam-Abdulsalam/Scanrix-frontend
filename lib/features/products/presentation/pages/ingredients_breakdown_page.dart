import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/app_theme_colors.dart';
import '../../domain/entities/safety_engine_entity.dart';
import '../widgets/findings_list_card.dart';
import '../widgets/not_assessed_section.dart';
import '../widgets/safety_disclaimer.dart';

enum BreakdownTab { watchOut, good, notAssessed }

/// Ingredient detail screen for engine results: three tabs (Watch out /
/// Good / Not assessed) so the result screen itself stays short. Pure
/// presentation; the selected tab is local UI state.
class IngredientsBreakdownPage extends StatefulWidget {
  final SafetyEngine engine;
  final String? productName;
  final BreakdownTab initialTab;

  const IngredientsBreakdownPage({
    super.key,
    required this.engine,
    this.productName,
    this.initialTab = BreakdownTab.watchOut,
  });

  @override
  State<IngredientsBreakdownPage> createState() => _IngredientsBreakdownPageState();
}

class _IngredientsBreakdownPageState extends State<IngredientsBreakdownPage> {
  late BreakdownTab _tab = widget.initialTab;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final flagged = widget.engine.flagged;
    final good = widget.engine.clear;
    final notAssessed = [
      for (final f in widget.engine.notAssessed)
        if (f.rawName.trim().isNotEmpty) f.rawName.trim(),
    ];
    final counts = {
      BreakdownTab.watchOut: flagged.length,
      BreakdownTab.good: good.length,
      BreakdownTab.notAssessed: notAssessed.length,
    };
    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.background,
        elevation: 0,
        title: Text(
          widget.productName?.trim().isNotEmpty == true ? widget.productName! : 'Ingredients',
          style: TextStyle(color: Colors.white, fontSize: 16.sp, fontWeight: FontWeight.w700),
        ),
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 32.h),
        children: [
          Wrap(
            spacing: 8.w,
            children: [
              for (final t in BreakdownTab.values)
                ChoiceChip(
                  label: Text('${_label(t)} (${counts[t]})'),
                  selected: _tab == t,
                  onSelected: (_) => setState(() => _tab = t),
                ),
            ],
          ),
          SizedBox(height: 16.h),
          switch (_tab) {
            BreakdownTab.watchOut => _listOrEmpty(
              flagged.isEmpty,
              'No ingredient is classified as a hazard in our database.',
              FindingsListCard(title: 'Watch out', findings: flagged),
            ),
            BreakdownTab.good => _listOrEmpty(
              good.isEmpty,
              'No recognised ingredient could be confirmed as free of classified hazards.',
              FindingsListCard(title: 'Good ingredients', findings: good),
            ),
            BreakdownTab.notAssessed => _listOrEmpty(
              notAssessed.isEmpty,
              'Every ingredient was found in our database.',
              NotAssessedSection(names: notAssessed),
            ),
          },
          SizedBox(height: 20.h),
          SafetyDisclaimer(text: widget.engine.disclaimer),
        ],
      ),
    );
  }

  static String _label(BreakdownTab t) => switch (t) {
    BreakdownTab.watchOut => 'Watch out',
    BreakdownTab.good => 'Good',
    BreakdownTab.notAssessed => 'Not assessed',
  };

  Widget _listOrEmpty(bool empty, String emptyText, Widget list) {
    if (!empty) return list;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 24.h),
      child: Text(
        emptyText,
        textAlign: TextAlign.center,
        style: TextStyle(color: context.colors.secondaryText, fontSize: 13.sp, height: 1.4),
      ),
    );
  }
}
