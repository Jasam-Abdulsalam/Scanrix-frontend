import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/app_theme_colors.dart';
import '../../../../core/widgets/bold_card.dart';
import '../../../products/domain/entities/ai_analysis_entity.dart';
import '../pages/natural_remedy_page.dart';
import 'remedy_sections.dart' show kRemedyGreen;

/// "Natural option" entry card on a cosmetic's result screen (the
/// `naturalRemedySection` slot of `AnalysisResultView`). Tapping opens
/// [NaturalRemedyPage], which makes the request; nothing is charged by just
/// showing this card.
class NaturalRemedyCard extends StatelessWidget {
  final AiAnalysisRequest request;

  const NaturalRemedyCard({super.key, required this.request});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Semantics(
      button: true,
      label: 'Natural option. A simple homemade swap. Uses 1 AI credit if new.',
      excludeSemantics: true,
      child: Pressable(
        onTap: () {
          HapticFeedback.selectionClick();
          Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => NaturalRemedyPage(request: request)));
        },
        child: BoldCard(
          padding: EdgeInsets.all(16.r),
          child: Row(
            children: [
              IconTile(icon: Icons.eco_rounded, color: kRemedyGreen, size: 44.r),
              SizedBox(width: 14.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Natural option',
                      style: TextStyle(color: Colors.white, fontSize: 16.sp, fontWeight: FontWeight.w800),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      'A simple swap you can make at home',
                      style: TextStyle(color: colors.secondaryText, fontSize: 12.sp),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      'AI suggestion · 1 credit if new',
                      style: TextStyle(color: colors.secondaryText.withValues(alpha: 0.7), fontSize: 11.sp),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 10.w),
              CircleIcon(icon: Icons.arrow_forward_rounded, background: kRemedyGreen, foreground: kOnAccent, size: 36.r),
            ],
          ),
        ),
      ),
    );
  }
}
