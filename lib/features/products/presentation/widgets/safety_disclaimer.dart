import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/app_theme_colors.dart';

/// `safety_engine.disclaimer`, shown at the bottom of the result screen.
class SafetyDisclaimer extends StatelessWidget {
  final String text;
  const SafetyDisclaimer({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    if (text.trim().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(color: context.colors.secondaryText, fontSize: 11.sp, height: 1.4),
      ),
    );
  }
}
