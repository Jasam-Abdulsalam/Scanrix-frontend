import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/navigation/tab_scope.dart';
import '../../../../core/theme/app_theme_colors.dart';
import '../../../../core/widgets/bottom_nav_bar.dart';
import '../../../../core/widgets/bold_card.dart';
import '../../../../core/widgets/toast.dart';
import '../../../products/presentation/pages/product_detail_page.dart';
import '../../../products/presentation/widgets/product_row_card.dart';
import '../../domain/entities/routine_entity.dart';
import '../../reminders/reminders_cubit.dart';
import '../bloc/routine_bloc.dart';
import '../bloc/routine_event.dart';
import '../bloc/routine_state.dart';

/// My Routine tab: the morning and evening steps (drag to reorder, swipe left to remove, tap to open), plus
/// this slot's reminder. Uses the app-wide [RoutineBloc] and [RemindersCubit].
///
/// Lives in `MainShell`'s `IndexedStack` (no Scaffold of its own). [slot] is owned by the shell so
/// Home's "Today" card can open the tab on the current slot; `MainShell` reloads the routine when
/// the tab is selected.
class RoutinePage extends StatelessWidget {
  final ValueNotifier<RoutineSlot> slot;

  const RoutinePage({super.key, required this.slot});

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<RoutineBloc, RoutineState>(
          listenWhen: (a, b) => b.notice != null && a.notice != b.notice,
          listener: (context, s) {
            if (canShowToastHere(context)) {
              showToast(context, s.notice!, icon: Icons.error_outline_rounded);
            }
          },
        ),
        BlocListener<RemindersCubit, RemindersState>(
          listenWhen: (a, b) => b.notice != null && a.notice != b.notice,
          listener: (context, s) {
            if (canShowToastHere(context)) {
              showToast(
                context,
                s.notice!,
                icon: Icons.notifications_off_outlined,
              );
            }
          },
        ),
      ],
      child: SafeArea(
        bottom: false,
        child: ValueListenableBuilder<RoutineSlot>(
          valueListenable: slot,
          builder: (context, current, _) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _Header(),
              Padding(
                padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 0),
                child: _SlotSwitch(
                  slot: current,
                  onChanged: (s) => slot.value = s,
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 4.h),
                child: _ReminderCard(slot: current),
              ),
              Expanded(
                // The floating nav bar overlays the bottom: end the list above it.
                child: Padding(
                  padding: EdgeInsets.only(bottom: navBarReserve(context)),
                  child: _Steps(slot: current),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 12.h, 12.w, 8.h),
      child: Text(
        'My Routine',
        style: TextStyle(
          color: Colors.white,
          fontSize: 26.sp,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

/// Morning / Evening segmented switch, each with its step count.
class _SlotSwitch extends StatelessWidget {
  final RoutineSlot slot;
  final ValueChanged<RoutineSlot> onChanged;

  const _SlotSwitch({required this.slot, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final routine = context.select((RoutineBloc b) => b.state.routine);
    return Container(
      padding: EdgeInsets.all(4.r),
      decoration: BoxDecoration(
        color: boldCardFill(colors),
        borderRadius: BorderRadius.circular(30.r),
      ),
      child: Row(
        children: [
          for (final s in RoutineSlot.values)
            Expanded(
              child: Semantics(
                button: true,
                selected: s == slot,
                label: '${s.label} routine, ${routine.slot(s).length} steps',
                excludeSemantics: true,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    if (s == slot) return;
                    HapticFeedback.selectionClick();
                    onChanged(s);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOutCubic,
                    padding: EdgeInsets.symmetric(vertical: 11.h),
                    decoration: BoxDecoration(
                      color: s == slot
                          ? boldAccent(context)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(26.r),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          s.icon,
                          size: 17.r,
                          color: s == slot ? kOnAccent : colors.secondaryText,
                        ),
                        SizedBox(width: 6.w),
                        Flexible(
                          child: Text(
                            '${s.label} · ${routine.slot(s).length}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: s == slot ? kOnAccent : Colors.white,
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// "Remind me at 8:00 AM" for the shown slot: a switch (shared by both slots and Profile) and the time.
class _ReminderCard extends StatelessWidget {
  final RoutineSlot slot;

  const _ReminderCard({required this.slot});

  Future<void> _pickTime(BuildContext context, TimeOfDay current) async {
    final cubit = context.read<RemindersCubit>();
    final picked = await showTimePicker(context: context, initialTime: current);
    if (picked != null) await cubit.setTime(slot, picked);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final reminders = context.watch<RemindersCubit>().state;
    final time = reminders.timeFor(slot);
    final timeText = MaterialLocalizations.of(context).formatTimeOfDay(time);
    return BoldCard(
      padding: EdgeInsets.fromLTRB(14.w, 10.h, 8.w, 10.h),
      child: Row(
        children: [
          IconTile(
            icon: Icons.alarm_rounded,
            color: boldAccent(context),
            size: 36.r,
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => _pickTime(context, time),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    reminders.enabled
                        ? 'Reminds you at $timeText'
                        : 'Reminders are off',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    'Tap to change the ${slot.label.toLowerCase()} time',
                    style: TextStyle(
                      color: colors.secondaryText,
                      fontSize: 11.5.sp,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Switch.adaptive(
            value: reminders.enabled,
            activeTrackColor: boldAccent(context),
            onChanged: (on) => context.read<RemindersCubit>().setEnabled(on),
          ),
        ],
      ),
    );
  }
}

class _Steps extends StatelessWidget {
  final RoutineSlot slot;

  const _Steps({required this.slot});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return BlocBuilder<RoutineBloc, RoutineState>(
      builder: (context, state) {
        final steps = state.routine.slot(slot);
        if (steps.isEmpty) {
          if (state.status == RoutineStatus.loading ||
              state.status == RoutineStatus.initial) {
            return Center(
              child: CircularProgressIndicator(color: colors.neonEmerald),
            );
          }
          if (state.status == RoutineStatus.failure) {
            return _Message(
              icon: Icons.cloud_off_rounded,
              title: "Couldn't load your routine",
              body:
                  state.failureMessage ??
                  'Check your connection and try again.',
              actionLabel: 'Try again',
              onAction: () =>
                  context.read<RoutineBloc>().add(const RoutineRequested()),
            );
          }
          return _Message(
            icon: slot.icon,
            title: 'No ${slot.label.toLowerCase()} steps yet',
            body:
                'Scan a cosmetic and tap "Add to routine" to build your ${slot.label.toLowerCase()} routine.',
          );
        }
        return ReorderableListView.builder(
          padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 32.h),
          itemCount: steps.length,
          buildDefaultDragHandles: false,
          onReorderItem: (from, to) {
            HapticFeedback.selectionClick();
            context.read<RoutineBloc>().add(RoutineStepMoved(slot, from, to));
          },
          itemBuilder: (context, i) => _StepTile(
            key: ValueKey('${slot.name}-${steps[i].barcode}'),
            slot: slot,
            index: i,
            item: steps[i],
          ),
        );
      },
    );
  }
}

class _StepTile extends StatelessWidget {
  final RoutineSlot slot;
  final int index;
  final RoutineItemEntity item;

  const _StepTile({
    super.key,
    required this.slot,
    required this.index,
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: EdgeInsets.only(bottom: 10.h),
      child: Dismissible(
        key: ValueKey('dismiss-${slot.name}-${item.barcode}'),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: EdgeInsets.only(right: 22.w),
          decoration: BoxDecoration(
            color: const Color(0xFFE5484D),
            borderRadius: BorderRadius.circular(20.r),
          ),
          child: Icon(
            Icons.delete_outline_rounded,
            color: Colors.white,
            size: 24.r,
          ),
        ),
        onDismissed: (_) {
          HapticFeedback.mediumImpact();
          context.read<RoutineBloc>().add(
            RoutineStepRemoved(slot, item.barcode),
          );
        },
        child: Row(
          children: [
            Container(
              width: 26.r,
              height: 26.r,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: boldAccent(context).withValues(alpha: 0.16),
                shape: BoxShape.circle,
              ),
              child: Text(
                '${index + 1}',
                style: TextStyle(
                  color: boldAccent(context),
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: ProductRowCard(
                name: item.name.isEmpty ? null : item.name,
                brand: item.brand,
                imageUrl: item.imageUrl,
                verdict: item.verdict,
                subtitle: item.productType == null
                    ? 'Step ${index + 1}'
                    : 'Step ${index + 1} · ${item.productType!.label}',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => ProductDetailPage(barcode: item.barcode),
                  ),
                ),
              ),
            ),
            ReorderableDragStartListener(
              index: index,
              child: Padding(
                padding: EdgeInsets.only(left: 6.w),
                child: Icon(
                  Icons.drag_indicator_rounded,
                  color: colors.secondaryText,
                  size: 24.r,
                  semanticLabel: 'Reorder',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _Message({
    required this.icon,
    required this.title,
    required this.body,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 36.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: colors.secondaryText, size: 44.r),
            SizedBox(height: 14.h),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 16.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 6.h),
            Text(
              body,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colors.secondaryText,
                fontSize: 13.sp,
                height: 1.4,
              ),
            ),
            if (actionLabel != null) ...[
              SizedBox(height: 18.h),
              TextButton(
                onPressed: onAction,
                child: Text(
                  actionLabel!,
                  style: TextStyle(
                    color: colors.neonEmerald,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
