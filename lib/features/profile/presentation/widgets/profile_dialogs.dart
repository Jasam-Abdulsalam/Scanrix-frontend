import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../auth/domain/entities/user_entity.dart';

/// Bottom sheet showing account email + edit/logout/delete actions.
void showAccountSheet({
  required BuildContext context,
  required UserEntity? user,
  required VoidCallback onEditProfile,
  required VoidCallback onLogout,
  required VoidCallback onDelete,
}) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => Container(
      padding: EdgeInsets.fromLTRB(24.w, 18.h, 24.w, 32.h),
      decoration: BoxDecoration(
        color: const Color(0xFF0C1D14),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
        border: Border.all(color: AppColors.neonEmerald.withValues(alpha: 0.18)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
          ),
          SizedBox(height: 20.h),
          Text(
            'Account Details',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16.h),
          if (user?.email != null) ...[
            Text('Email', style: TextStyle(color: AppColors.secondaryText, fontSize: 12.sp)),
            SizedBox(height: 4.h),
            Text(
              user!.email,
              style: TextStyle(color: Colors.white, fontSize: 14.sp, fontWeight: FontWeight.w500),
            ),
            SizedBox(height: 16.h),
          ],
          _sheetTile(
            icon: Icons.edit_outlined,
            iconColor: AppColors.neonEmerald,
            label: 'Edit Profile',
            onTap: () {
              Navigator.pop(sheetContext);
              onEditProfile();
            },
          ),
          Divider(color: Colors.white.withValues(alpha: 0.08), height: 20.h),
          _sheetTile(
            icon: Icons.logout_rounded,
            iconColor: const Color(0xFFFF5252),
            label: 'Log out',
            onTap: () {
              Navigator.pop(sheetContext);
              onLogout();
            },
          ),
          Divider(color: Colors.white.withValues(alpha: 0.08), height: 20.h),
          _sheetTile(
            icon: Icons.delete_outline_rounded,
            iconColor: const Color(0xFFFF4444),
            label: 'Delete Account',
            onTap: () {
              Navigator.pop(sheetContext);
              onDelete();
            },
          ),
        ],
      ),
    ),
  );
}

Widget _sheetTile({
  required IconData icon,
  required Color iconColor,
  required String label,
  required VoidCallback onTap,
}) {
  return ListTile(
    contentPadding: EdgeInsets.zero,
    leading: Container(
      padding: EdgeInsets.all(8.r),
      decoration: BoxDecoration(shape: BoxShape.circle, color: iconColor.withValues(alpha: 0.12)),
      child: Icon(icon, color: iconColor, size: 18.r),
    ),
    title: Text(
      label,
      style: TextStyle(color: iconColor == AppColors.neonEmerald ? Colors.white : iconColor, fontSize: 14.sp, fontWeight: FontWeight.w500),
    ),
    trailing: Icon(Icons.chevron_right_rounded, color: AppColors.secondaryText, size: 20.r),
    onTap: onTap,
  );
}

/// Confirmation dialog for signing out.
void confirmLogoutDialog(BuildContext context, VoidCallback onConfirm) {
  showDialog(
    context: context,
    builder: (dialogCtx) => AlertDialog(
      backgroundColor: const Color(0xFF0C1D14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.r),
        side: BorderSide(color: AppColors.neonEmerald.withValues(alpha: 0.2)),
      ),
      title: Text('Sign Out', style: TextStyle(color: AppColors.white, fontSize: 17.sp, fontWeight: FontWeight.bold)),
      content: Text(
        'Are you sure you want to sign out of your account?',
        style: TextStyle(color: AppColors.secondaryText, fontSize: 13.sp, height: 1.45),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogCtx).pop(),
          child: Text('Cancel', style: TextStyle(color: AppColors.secondaryText, fontSize: 14.sp)),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(dialogCtx).pop();
            onConfirm();
          },
          child: Text(
            'Sign Out',
            style: TextStyle(color: const Color(0xFFFF6B6B), fontSize: 14.sp, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    ),
  );
}

/// Confirmation dialog for deleting the account.
void confirmDeleteDialog(BuildContext context, VoidCallback onConfirm) {
  showDialog(
    context: context,
    builder: (dialogCtx) => AlertDialog(
      backgroundColor: const Color(0xFF0C1D14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.r),
        side: BorderSide(color: const Color(0xFFFF6B6B).withValues(alpha: 0.3)),
      ),
      title: Text('Delete Account', style: TextStyle(color: AppColors.white, fontSize: 17.sp, fontWeight: FontWeight.bold)),
      content: Text(
        'This permanently deletes your account, scan history, and all '
        'associated data. This cannot be undone.',
        style: TextStyle(color: AppColors.secondaryText, fontSize: 13.sp, height: 1.45),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogCtx).pop(),
          child: Text('Cancel', style: TextStyle(color: AppColors.secondaryText, fontSize: 14.sp)),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(dialogCtx).pop();
            onConfirm();
          },
          child: Text(
            'Delete Account',
            style: TextStyle(color: const Color(0xFFFF4444), fontSize: 14.sp, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    ),
  );
}
