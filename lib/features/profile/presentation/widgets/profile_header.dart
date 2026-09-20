import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../core/theme/app_colors.dart';
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
    final displayName = (user != null && user!.name.isNotEmpty)
        ? user!.name
        : (isLoading ? 'Loading…' : 'Jasam');

    return ClipRRect(
      borderRadius: BorderRadius.vertical(bottom: Radius.circular(30.r)),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0C2417),
              Color(0xFF071810),
              Color(0xFF040E0A),
            ],
            stops: [0.0, 0.50, 1.0],
          ),
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(30.r)),
          border: const Border(
            bottom: BorderSide(color: Color(0xFF133825), width: 1.0),
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
                      colors: [
                        const Color(0xFF1F5C3E).withValues(alpha: 0.55),
                        const Color(0xFF0F3824).withValues(alpha: 0.20),
                        Colors.transparent,
                      ],
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
                            color: const Color(0xFF0A2218).withValues(alpha: 0.85),
                            border: Border.all(
                              color: AppColors.neonEmerald.withValues(alpha: 0.35),
                              width: 1.2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.neonEmerald.withValues(alpha: 0.12),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.edit_outlined,
                            color: AppColors.neonEmerald,
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
    final outerSize = 98.r;
    final innerSize = 68.r;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: outerSize,
        height: outerSize,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1A4530), Color(0xFF0E281C)],
          ),
          border: Border.all(
            color: AppColors.neonEmerald.withValues(alpha: 0.38),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.neonEmerald.withValues(alpha: 0.22),
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
            color: const Color(0xFF091F15),
            border: Border.all(
              color: AppColors.neonEmerald.withValues(alpha: 0.25),
              width: 1,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: photoUrl != null && photoUrl!.isNotEmpty
              ? Image.network(
                  photoUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _silhouetteIcon(innerSize),
                )
              : _silhouetteIcon(innerSize),
        ),
      ),
    );
  }

  Widget _silhouetteIcon(double size) {
    return Icon(
      Icons.person_rounded,
      color: AppColors.neonEmerald.withValues(alpha: 0.75),
      size: size * 0.60,
    );
  }
}