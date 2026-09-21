import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/navigation/main_shell.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/aurora_background.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/widgets/primary_button.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

/// Reached either right after a new Google sign-in (see `LoginPage`'s
/// `AuthLoginSuccess` handling) or, on a later app launch, from the
/// startup check in `main.dart` when the server says the profile still
/// isn't complete (`UserEntity.profileCompleted == false`). The user is
/// already authenticated either way, so this screen is a
/// profile-completion step, not a credentials form: no email/password
/// fields, no "sign up with Google" — Google is how they got here.
///
/// [initialName]/[photoUrl]/[email] are prefilled from whichever source
/// reached this screen (the Google account on first sign-in, or
/// `GET /auth/me` on a later launch) — name stays editable, it's the only
/// mandatory field. Submitting calls `PATCH /auth/me` via `AuthBloc`.
class CreateAccountPage extends StatefulWidget {
  final String? initialName;
  final String? photoUrl;
  final String? email;

  const CreateAccountPage({
    super.key,
    this.initialName,
    this.photoUrl,
    this.email,
  });

  @override
  State<CreateAccountPage> createState() => _CreateAccountPageState();
}

class _CreateAccountPageState extends State<CreateAccountPage> {
  final _formKey = GlobalKey<FormState>();
  late final _nameController = TextEditingController(text: widget.initialName);
  final _mobileController = TextEditingController();

  String? _photoUrl;
  File? _pickedPhoto;
  bool _agreedToTerms = false;

  @override
  void initState() {
    super.initState();
    _photoUrl = widget.photoUrl;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _mobileController.dispose();
    super.dispose();
  }

  Future<void> _showPhotoSourceSheet() async {
    await showCupertinoModalPopup<void>(
      context: context,
      builder: (sheetContext) => CupertinoActionSheet(
        title: const Text('Profile Photo'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(sheetContext);
              _pickImage(ImageSource.camera);
            },
            child: const Text('Take Photo'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(sheetContext);
              _pickImage(ImageSource.gallery);
            },
            child: const Text('Choose from Library'),
          ),
          if (_pickedPhoto != null || _photoUrl != null)
            CupertinoActionSheetAction(
              isDestructiveAction: true,
              onPressed: () {
                Navigator.pop(sheetContext);
                setState(() {
                  _pickedPhoto = null;
                  _photoUrl = null;
                });
              },
              child: const Text('Remove Photo'),
            ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(sheetContext),
          child: const Text('Cancel'),
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final picked = await ImagePicker().pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 1024,
    );
    if (picked == null) return;
    setState(() {
      _pickedPhoto = File(picked.path);
      _photoUrl = null;
    });
  }

  void _submit() {
    if (!_agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please agree to the Terms and Privacy Policy to continue.',
          ),
        ),
      );
      return;
    }
    if (!_formKey.currentState!.validate()) return;
    context.read<AuthBloc>().add(
      AuthProfileCompletionRequested(
        name: _nameController.text.trim(),
        // photoFile (a freshly picked local image) takes priority — the
        // bloc uploads it first via UploadProfilePhotoUseCase. Otherwise
        // photoUrl carries the Google-provided photo through unchanged if
        // the user didn't replace or remove it.
        photoFile: _pickedPhoto,
        photoUrl: _pickedPhoto == null ? _photoUrl : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: BlocConsumer<AuthBloc, AuthState>(
          listener: (context, state) {
            if (state is AuthFailure) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(state.message)));
            } else if (state is AuthProfileCompleteSuccess) {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const MainShell()),
              );
            }
          },
          builder: (context, state) {
            final isSubmitting = state is AuthLoading;
            return _buildBody(context, isSubmitting);
          },
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, bool isSubmitting) {
    return AuroraBackground(
      child: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(24.w, 8.h, 24.w, 32.h),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Align(alignment: Alignment.centerLeft, child: _BackButton()),
                SizedBox(height: 12.h),
                _AvatarPicker(
                  photoFile: _pickedPhoto,
                  photoUrl: _photoUrl,
                  onTap: _showPhotoSourceSheet,
                ),
                SizedBox(height: 20.h),
                Text(
                  'Complete Your Profile',
                  style: TextStyle(
                    color: AppColors.white,
                    fontSize: 22.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 6.h),
                Text(
                  'Just a couple of details to finish setting up.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.secondaryText,
                    fontSize: 13.sp,
                  ),
                ),
                if (widget.email != null) ...[
                  SizedBox(height: 12.h),
                  _SignedInAsChip(email: widget.email!),
                ],
                SizedBox(height: 24.h),
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
                        icon: CupertinoIcons.person,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Name is required';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 18.h),
                      _FieldLabel('Mobile Number (optional)'),
                      SizedBox(height: 8.h),
                      _GlassTextField(
                        controller: _mobileController,
                        hint: 'Enter your mobile number',
                        icon: CupertinoIcons.phone,
                        keyboardType: TextInputType.phone,
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
                          // Stays tappable even when terms aren't agreed to
                          // yet, so _submit() can show a corrective snackbar
                          // instead of the tap silently doing nothing — only
                          // dim it (enabled: false) as the visual cue.
                          onTap: isSubmitting ? null : _submit,
                          enabled: _agreedToTerms && !isSubmitting,
                          child: isSubmitting
                              ? SizedBox(
                                  width: 18.r,
                                  height: 18.r,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.background,
                                  ),
                                )
                              : Text(
                                  'Continue',
                                  style: TextStyle(fontSize: 14.sp),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
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
        child: Icon(CupertinoIcons.back, color: AppColors.white, size: 18.r),
      ),
    );
  }
}

/// Circular avatar showing (in priority order) a freshly-picked local
/// photo, the prefilled Google [photoUrl], or a placeholder icon — with a
/// small edit badge that opens an iOS-style action sheet.
class _AvatarPicker extends StatelessWidget {
  final File? photoFile;
  final String? photoUrl;
  final VoidCallback onTap;

  const _AvatarPicker({
    required this.photoFile,
    required this.photoUrl,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final size = 96.r;
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: size + 12.r,
        height: size + 12.r,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.glassFill,
                border: Border.all(
                  color: AppColors.neonEmerald.withValues(alpha: 0.4),
                  width: 1.5,
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: photoFile != null
                  ? Image.file(photoFile!, fit: BoxFit.cover)
                  : (photoUrl != null
                        ? Image.network(
                            photoUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _placeholderIcon(),
                          )
                        : _placeholderIcon()),
            ),
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: 30.r,
                height: 30.r,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.neonEmerald,
                  border: Border.all(color: AppColors.background, width: 2),
                ),
                child: Icon(
                  CupertinoIcons.camera_fill,
                  size: 14.r,
                  color: AppColors.background,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholderIcon() {
    return Icon(
      CupertinoIcons.person_fill,
      size: 40.r,
      color: AppColors.secondaryText,
    );
  }
}

class _SignedInAsChip extends StatelessWidget {
  final String email;
  const _SignedInAsChip({required this.email});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20.r),
        color: AppColors.glassFill.withValues(alpha: 0.4),
        border: Border.all(
          color: AppColors.neonEmerald.withValues(alpha: 0.18),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            CupertinoIcons.checkmark_seal_fill,
            size: 13.r,
            color: AppColors.neonEmerald,
          ),
          SizedBox(width: 6.w),
          Text(
            'Signed in as $email',
            style: TextStyle(color: AppColors.secondaryText, fontSize: 11.sp),
          ),
        ],
      ),
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
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  const _GlassTextField({
    required this.controller,
    required this.hint,
    required this.icon,
    this.keyboardType,
    this.validator,
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
          keyboardType: widget.keyboardType,
          validator: widget.validator,
          style: TextStyle(color: AppColors.white, fontSize: 13.sp),
          cursorColor: AppColors.neonEmerald,
          decoration: InputDecoration(
            hintText: widget.hint,
            hintStyle: TextStyle(
              color: AppColors.secondaryText.withValues(alpha: 0.6),
              fontSize: 13.sp,
            ),
            prefixIcon: Icon(
              widget.icon,
              color: AppColors.secondaryText,
              size: 18.r,
            ),
            border: InputBorder.none,
            errorStyle: TextStyle(fontSize: 11.sp),
            contentPadding: EdgeInsets.symmetric(
              vertical: 14.h,
              horizontal: 4.w,
            ),
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
                ? Icon(
                    Icons.check_rounded,
                    size: 13.r,
                    color: AppColors.background,
                  )
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
                  const TextSpan(
                    text:
                        'By continuing, I confirm that I have read and agree to the ',
                  ),
                  TextSpan(
                    text: 'Terms and Conditions',
                    style: TextStyle(color: AppColors.neonEmerald),
                  ),
                  const TextSpan(text: ' and '),
                  TextSpan(
                    text: 'Privacy Policy',
                    style: TextStyle(color: AppColors.neonEmerald),
                  ),
                  const TextSpan(text: '.'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
