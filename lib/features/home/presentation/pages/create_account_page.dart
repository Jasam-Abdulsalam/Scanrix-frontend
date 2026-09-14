import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/aurora_background.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/widgets/primary_button.dart';

class CreateAccountPage extends StatefulWidget {
  const CreateAccountPage({super.key});

  @override
  State<CreateAccountPage> createState() => _CreateAccountPageState();
}

class _CreateAccountPageState extends State<CreateAccountPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _agreedToTerms = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: AuroraBackground(
          child: SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(24.w, 8.h, 24.w, 32.h),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _BackButton(),
                    SizedBox(height: 20.h),
                    const _LogoMark(),
                    SizedBox(height: 20.h),
                    const _HeaderText(),
                    SizedBox(height: 28.h),
                    GlassCard(
                      padding: EdgeInsets.all(20.r),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _FieldLabel('Full Name'),
                          SizedBox(height: 8.h),
                          _GlassTextField(
                            controller: _nameController,
                            hint: 'Enter your full name',
                            icon: Icons.person_outline_rounded,
                          ),
                          SizedBox(height: 18.h),
                          _FieldLabel('Email'),
                          SizedBox(height: 8.h),
                          _GlassTextField(
                            controller: _emailController,
                            hint: 'you@example.com',
                            icon: Icons.mail_outline_rounded,
                            keyboardType: TextInputType.emailAddress,
                          ),
                          SizedBox(height: 18.h),
                          _FieldLabel('Password'),
                          SizedBox(height: 8.h),
                          _GlassTextField(
                            controller: _passwordController,
                            hint: 'Create a password',
                            icon: Icons.lock_outline_rounded,
                            obscure: _obscurePassword,
                            trailing: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off_rounded
                                    : Icons.visibility_rounded,
                                color: AppColors.secondaryText,
                                size: 18.r,
                              ),
                              onPressed: () => setState(
                                  () => _obscurePassword = !_obscurePassword),
                            ),
                          ),
                          SizedBox(height: 18.h),
                          _FieldLabel('Confirm Password'),
                          SizedBox(height: 8.h),
                          _GlassTextField(
                            controller: _confirmController,
                            hint: 'Re-enter your password',
                            icon: Icons.lock_outline_rounded,
                            obscure: _obscureConfirm,
                            trailing: IconButton(
                              icon: Icon(
                                _obscureConfirm
                                    ? Icons.visibility_off_rounded
                                    : Icons.visibility_rounded,
                                color: AppColors.secondaryText,
                                size: 18.r,
                              ),
                              onPressed: () => setState(
                                  () => _obscureConfirm = !_obscureConfirm),
                            ),
                          ),
                          SizedBox(height: 18.h),
                          _TermsCheckbox(
                            value: _agreedToTerms,
                            onChanged: (v) =>
                                setState(() => _agreedToTerms = v ?? false),
                          ),
                          SizedBox(height: 22.h),
                          SizedBox(
                            width: double.infinity,
                            child: PrimaryButton(
                              onTap: _agreedToTerms
                                  ? () {
                                      if (_formKey.currentState!.validate()) {
                                        // TODO: wire up account creation
                                      }
                                    }
                                  : null,
                              child: Text(
                                'Create Account',
                                style: TextStyle(fontSize: 14.sp),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 24.h),
                    const _DividerWithText(text: 'or sign up with'),
                    SizedBox(height: 20.h),
                    Row(
                      children: [
                        Expanded(
                          child: _SocialButton(
                            icon: Icons.g_mobiledata_rounded,
                            label: 'Google',
                          ),
                        ),
                        SizedBox(width: 14.w),
                        Expanded(
                          child: _SocialButton(
                            icon: Icons.apple_rounded,
                            label: 'Apple',
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 28.h),
                    Center(
                      child: RichText(
                        text: TextSpan(
                          style: TextStyle(
                            color: AppColors.secondaryText,
                            fontSize: 13.sp,
                          ),
                          children: [
                            const TextSpan(text: 'Already have an account? '),
                            TextSpan(
                              text: 'Sign In',
                              style: TextStyle(
                                color: AppColors.neonEmerald,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton();

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.of(context).maybePop(),
      borderRadius: BorderRadius.circular(20.r),
      child: Container(
        width: 38.r,
        height: 38.r,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.glassFill.withValues(alpha: 0.4),
          border: Border.all(
            color: AppColors.neonEmerald.withValues(alpha: 0.18),
          ),
        ),
        child: Icon(Icons.arrow_back_ios_new_rounded,
            color: AppColors.white, size: 16.r),
      ),
    );
  }
}

class _LogoMark extends StatelessWidget {
  const _LogoMark();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.eco_rounded, color: AppColors.neonEmerald, size: 24.r),
        SizedBox(width: 8.w),
        Text(
          'Scanrix',
          style: TextStyle(
            color: AppColors.white,
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class _HeaderText extends StatelessWidget {
  const _HeaderText();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(
          TextSpan(
            style: TextStyle(
              fontSize: 22.sp,
              fontWeight: FontWeight.bold,
              color: AppColors.white,
            ),
            children: [
              const TextSpan(text: 'Create Your '),
              TextSpan(
                text: 'Account',
                style: TextStyle(color: AppColors.neonEmerald),
              ),
            ],
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          'Join Scanrix and start scanning smarter.',
          style: TextStyle(color: AppColors.secondaryText, fontSize: 13.sp),
        ),
      ],
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: AppColors.secondaryText,
        fontSize: 12.sp,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

/// Glass-style input: matches the card treatment — dark translucent fill,
/// faint emerald border, glows on focus.
class _GlassTextField extends StatefulWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool obscure;
  final Widget? trailing;
  final TextInputType? keyboardType;

  const _GlassTextField({
    required this.controller,
    required this.hint,
    required this.icon,
    this.obscure = false,
    this.trailing,
    this.keyboardType,
  });

  @override
  State<_GlassTextField> createState() => _GlassTextFieldState();
}

class _GlassTextFieldState extends State<_GlassTextField> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    return Focus(
      onFocusChange: (f) => setState(() => _focused = f),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14.r),
          color: AppColors.background.withValues(alpha: 0.5),
          border: Border.all(
            color: _focused
                ? AppColors.neonEmerald.withValues(alpha: 0.7)
                : AppColors.neonEmerald.withValues(alpha: 0.15),
            width: _focused ? 1.4 : 1,
          ),
          boxShadow: _focused
              ? [
                  BoxShadow(
                    color: AppColors.neonEmerald.withValues(alpha: 0.18),
                    blurRadius: 12,
                  ),
                ]
              : [],
        ),
        child: TextFormField(
          controller: widget.controller,
          obscureText: widget.obscure,
          keyboardType: widget.keyboardType,
          style: TextStyle(color: AppColors.white, fontSize: 13.sp),
          cursorColor: AppColors.neonEmerald,
          decoration: InputDecoration(
            hintText: widget.hint,
            hintStyle: TextStyle(
              color: AppColors.secondaryText.withValues(alpha: 0.6),
              fontSize: 13.sp,
            ),
            prefixIcon: Icon(widget.icon,
                color: AppColors.secondaryText, size: 18.r),
            suffixIcon: widget.trailing,
            border: InputBorder.none,
            contentPadding:
                EdgeInsets.symmetric(vertical: 14.h, horizontal: 4.w),
          ),
        ),
      ),
    );
  }
}

class _TermsCheckbox extends StatelessWidget {
  final bool value;
  final ValueChanged<bool?> onChanged;

  const _TermsCheckbox({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(!value),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 18.r,
            height: 18.r,
            margin: EdgeInsets.only(top: 1.h),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4.r),
              color: value
                  ? AppColors.neonEmerald
                  : AppColors.background.withValues(alpha: 0.5),
              border: Border.all(
                color: AppColors.neonEmerald.withValues(alpha: 0.5),
              ),
            ),
            child: value
                ? Icon(Icons.check_rounded,
                    size: 13.r, color: AppColors.background)
                : null,
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: TextStyle(
                  color: AppColors.secondaryText,
                  fontSize: 12.sp,
                  height: 1.4,
                ),
                children: [
                  const TextSpan(text: 'I agree to the '),
                  TextSpan(
                    text: 'Terms of Service',
                    style: TextStyle(color: AppColors.neonEmerald),
                  ),
                  const TextSpan(text: ' and '),
                  TextSpan(
                    text: 'Privacy Policy',
                    style: TextStyle(color: AppColors.neonEmerald),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DividerWithText extends StatelessWidget {
  final String text;
  const _DividerWithText({required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Divider(
            color: AppColors.neonEmerald.withValues(alpha: 0.15),
            height: 1,
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 12.w),
          child: Text(
            text,
            style: TextStyle(color: AppColors.secondaryText, fontSize: 11.sp),
          ),
        ),
        Expanded(
          child: Divider(
            color: AppColors.neonEmerald.withValues(alpha: 0.15),
            height: 1,
          ),
        ),
      ],
    );
  }
}

class _SocialButton extends StatelessWidget {
  final IconData icon;
  final String label;

  const _SocialButton({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 13.h),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14.r),
        color: AppColors.glassFill.withValues(alpha: 0.4),
        border: Border.all(
          color: AppColors.neonEmerald.withValues(alpha: 0.18),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: AppColors.white, size: 20.r),
          SizedBox(width: 8.w),
          Text(
            label,
            style: TextStyle(
              color: AppColors.white,
              fontSize: 13.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}