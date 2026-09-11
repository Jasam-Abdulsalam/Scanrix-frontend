import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/aurora_background.dart';
import '../../../../core/widgets/glass_button.dart';
import '../../../../core/widgets/google_logo.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  void _continueWithGoogle(BuildContext context) {
    // TODO: wire up the actual Google Sign-In flow (auth_bloc + backend
    // OAuth endpoint don't exist yet).
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Google Sign-In coming soon')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: AuroraBackground(
          child: SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 28.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Spacer(flex: 5),
                  Image.asset(
                    'assets/logo.png',
                    height: 280.h,
                    fit: BoxFit.contain,
                  ),
                  const Spacer(flex: 4),
                  SizedBox(
                    width: double.infinity,
                    child: GlassButton(
                      onPressed: () => _continueWithGoogle(context),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          GoogleLogo(size: 20.r),
                          SizedBox(width: 12.w),
                          Text(
                            'Continue with Google',
                            style: textTheme.titleMedium?.copyWith(
                              color: AppColors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Spacer(flex: 2),
                  SizedBox(
                    width: double.infinity,
                    child: _TermsFooter(textTheme: textTheme),
                  ),
                  SizedBox(height: 16.h),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TermsFooter extends StatelessWidget {
  final TextTheme textTheme;

  const _TermsFooter({required this.textTheme});

  @override
  Widget build(BuildContext context) {
    final baseStyle = textTheme.bodySmall?.copyWith(color: AppColors.secondaryText);
    final linkStyle = baseStyle?.copyWith(
      color: AppColors.neonEmerald,
      decoration: TextDecoration.underline,
      decorationColor: AppColors.neonEmerald,
    );

    return Center(
      child: Text.rich(
        TextSpan(
          style: baseStyle,
          children: [
            const TextSpan(text: 'By continuing, you agree to our '),
            TextSpan(text: 'Terms of Service', style: linkStyle),
            const TextSpan(text: ' and '),
            TextSpan(text: 'Privacy Policy', style: linkStyle),
            const TextSpan(text: '.'),
          ],
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
