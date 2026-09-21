import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../core/theme/app_theme_colors.dart';
import '../../../auth/domain/entities/user_entity.dart';

/// Top curved header showing the ambient glow, user avatar, and name.
class ProfileTopHeader extends StatelessWidget {
  final UserEntity? user;
  final bool isLoading;
  final VoidCallback onEditTap;

  const ProfileTopHeader({
    super.key,
    required this.user,
    required this.isLoading,
    required this.onEditTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final displayName = (user != null && user!.name.isNotEmpty)
        ? user!.name
        : (isLoading ? 'Loading…' : 'Jasam');

    return ClipRRect(
      borderRadius: BorderRadius.vertical(bottom: Radius.circular(30.r)),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: colors.headerGradient,
            stops: const [0.0, 0.50, 1.0],
          ),
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(30.r)),
          border: Border(
            bottom: BorderSide(color: colors.cardBorder, width: 1.0),
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned(
              top: 25.h,
              child: IgnorePointer(
                child: Container(
                  width: 200.w,
                  height: 150.h,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: colors.headerGlow,
                    ),
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: Opacity(
                opacity: 0.5,
                child: Image.asset(
                  'assets/images/painter 2.png',
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
            ),
            SafeArea(
              bottom: false,
              child: Padding(
                padding: EdgeInsets.fromLTRB(20.w, 6.h, 20.w, 14.h),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Align(
                      alignment: Alignment.topRight,
                      child: InkWell(
                        onTap: onEditTap,
                        borderRadius: BorderRadius.circular(20.r),
                        child: Container(
                          width: 36.r,
                          height: 36.r,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: colors.iconContainerBg.withValues(alpha: 0.90),
                            border: Border.all(
                              color: colors.neonEmerald.withValues(alpha: 0.35),
                              width: 1.2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: colors.neonEmerald.withValues(alpha: 0.15),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.edit_outlined,
                            color: colors.neonEmerald,
                            size: 17.r,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 2.h),
                    _AvatarWithGlowRing(photoUrl: user?.photoUrl, onTap: onEditTap),
                    SizedBox(height: 10.h),
                    Text(
                      displayName,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 19.sp,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AvatarWithGlowRing extends StatelessWidget {
  final String? photoUrl;
  final VoidCallback onTap;

  const _AvatarWithGlowRing({required this.photoUrl, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final outerSize = 98.r;
    final innerSize = 68.r;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: outerSize,
        height: outerSize,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: colors.avatarOuterGradient,
          ),
          border: Border.all(
            color: colors.neonEmerald.withValues(alpha: 0.38),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: colors.neonEmerald.withValues(alpha: 0.22),
              blurRadius: 18,
              spreadRadius: 1,
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Container(
          width: innerSize,
          height: innerSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: colors.iconContainerBg,
            border: Border.all(
              color: colors.neonEmerald.withValues(alpha: 0.25),
              width: 1,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: photoUrl != null && photoUrl!.isNotEmpty
              ? Image.network(
                  photoUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _silhouetteIcon(colors, innerSize),
                )
              : _silhouetteIcon(colors, innerSize),
        ),
      ),
    );
  }

  Widget _silhouetteIcon(AppThemeColors colors, double size) {
    return Icon(
      Icons.person_rounded,
      color: colors.neonEmerald.withValues(alpha: 0.75),
      size: size * 0.60,
    );
  }
}