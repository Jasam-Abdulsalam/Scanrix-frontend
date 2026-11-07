import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_theme_colors.dart';
import '../../../../core/widgets/bold_card.dart';
import '../../../products/domain/entities/ai_analysis_entity.dart';
import '../bloc/natural_remedy_bloc.dart';
import '../bloc/natural_remedy_event.dart';
import '../bloc/natural_remedy_state.dart';
import '../widgets/remedy_sections.dart';

/// Homemade alternative(s) for a cosmetic, as a simple recipe page
/// (`POST /ai/natural-remedy`). Costs 1 weekly AI credit the first time anyone
/// asks for this product / label; after that the saved answer is free.
/// Owns its own [NaturalRemedyBloc] (one per screen).
class NaturalRemedyPage extends StatelessWidget {
  final AiAnalysisRequest request;

  const NaturalRemedyPage({super.key, required this.request});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<NaturalRemedyBloc>()..add(NaturalRemedyRequested(request)),
      child: _NaturalRemedyView(request: request),
    );
  }
}

class _NaturalRemedyView extends StatelessWidget {
  final AiAnalysisRequest request;

  const _NaturalRemedyView({required this.request});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: BlocBuilder<NaturalRemedyBloc, NaturalRemedyState>(
          builder: (context, state) {
            final result = state is NaturalRemedyLoaded ? state.result : null;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Header(productType: result?.productType),
                Expanded(child: _body(context, state)),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _body(BuildContext context, NaturalRemedyState state) {
    return switch (state) {
      NaturalRemedyLoaded(:final result) when result.remedies.isEmpty => RemedyMessage(
          icon: Icons.do_not_disturb_on_outlined,
          title: 'No safe homemade swap',
          body: result.noRemedyReason ?? 'No homemade swap passed our safety checks for this product.',
        ),
      NaturalRemedyLoaded(:final result) => RemedyRecipeList(result: result),
      NaturalRemedyFailure() => RemedyMessage(
          icon: switch (state.kind) {
            NaturalRemedyFailureKind.creditsExhausted => Icons.hourglass_bottom_rounded,
            NaturalRemedyFailureKind.ingredientsMissing => Icons.document_scanner_outlined,
            NaturalRemedyFailureKind.notCosmetic => Icons.spa_outlined,
            _ => Icons.cloud_off_rounded,
          },
          title: state.kind == NaturalRemedyFailureKind.creditsExhausted
              ? 'Out of AI credits'
              : "Couldn't load a natural option",
          body: state.resetsAt == null ? state.message : '${state.message} ${_resetsText(state.resetsAt!)}',
          actionLabel: state.canRetry ? 'Try again' : null,
          onAction: () => context.read<NaturalRemedyBloc>().add(NaturalRemedyRequested(request)),
        ),
      NaturalRemedyLoading() => const _Loading(),
    };
  }
}

String _resetsText(DateTime resetsAt) {
  const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  final t = resetsAt.toLocal();
  return 'New credits on ${days[t.weekday - 1]}, ${t.day} ${months[t.month - 1]}.';
}

class _Header extends StatelessWidget {
  final String? productType;

  const _Header({this.productType});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 0),
      child: Row(
        children: [
          Pressable(
            onTap: () {
              HapticFeedback.selectionClick();
              Navigator.of(context).maybePop();
            },
            child: CircleIcon(
              icon: Icons.arrow_back_ios_new_rounded,
              background: boldCardFill(colors),
              foreground: Colors.white,
              size: 42.r,
            ),
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Natural option',
                  style: TextStyle(color: Colors.white, fontSize: 20.sp, fontWeight: FontWeight.w800),
                ),
                Text(
                  productType == null ? 'A simple homemade swap' : 'Homemade swap for your $productType',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: colors.secondaryText, fontSize: 12.sp),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: colors.neonEmerald),
          SizedBox(height: 16.h),
          Text('Finding a simple kitchen swap…', style: TextStyle(color: colors.secondaryText, fontSize: 13.sp)),
        ],
      ),
    );
  }
}

