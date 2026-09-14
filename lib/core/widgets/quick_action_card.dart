import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../theme/app_colors.dart';

class QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const QuickActionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18.r),
        color: AppColors.glassFill.withValues(alpha: 0.5),
        border: Border.all(color: AppColors.neonEmerald.withValues(alpha: 0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36.r,
                height: 36.r,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.neonEmerald.withValues(alpha: 0.14),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.neonEmerald.withValues(alpha: 0.25),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Icon(icon, color: AppColors.neonEmerald, size: 18.r),
              ),
              const Spacer(),
              Icon(Icons.chevron_right_rounded, color: AppColors.secondaryText, size: 18.r),
            ],
          ),
          SizedBox(height: 12.h),
          Text(title,
              style: TextStyle(color: AppColors.white, fontSize: 14.sp, fontWeight: FontWeight.bold)),
          SizedBox(height: 2.h),
          Text(subtitle, style: TextStyle(color: AppColors.secondaryText, fontSize: 12.sp)),
        ],
      ),
    );
  }
}