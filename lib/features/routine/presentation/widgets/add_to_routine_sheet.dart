import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/app_theme_colors.dart';
import '../../../../core/widgets/bold_card.dart';
import '../../../../core/widgets/toast.dart';
import '../../domain/entities/routine_entity.dart';
import '../../reminders/reminders_cubit.dart';
import '../bloc/routine_bloc.dart';
import '../bloc/routine_event.dart';

/// Bottom sheet from the result screen's "Add to routine": pick Morning, Evening or both, the product's
/// type, and the reminder. Opens with the product's current slots and type ticked, so the same sheet also
/// moves, relabels or removes it.
///
/// The reminder time belongs to the whole routine (one notification per routine, listing its steps), not
/// to this product: changing it here changes it for every step of that routine, same as on My Routine.
/// Nothing is applied until Save.
Future<void> showAddToRoutineSheet(
  BuildContext context,
  RoutineItemEntity item,
) {
  final bloc = context.read<RoutineBloc>();
  final reminders = context.read<RemindersCubit>();
  final routine = bloc.state.routine;
  return showModalBottomSheet<void>(
    context: context,
    useSafeArea: true,
    showDragHandle: true,
    // Taller than the default 9/16 of the screen on small phones.
    isScrollControlled: true,
    backgroundColor: context.colors.background,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
    ),
    // Passed through explicitly: the sheet's route doesn't sit under the caller's providers.
    builder: (_) => MultiBlocProvider(
      providers: [
        BlocProvider.value(value: bloc),
        BlocProvider.value(value: reminders),
      ],
      child: AddToRoutineSheet(
        item: item,
        initial: routine.slotsOf(item.barcode),
        initialType: routine.productTypeOf(item.barcode),
      ),
    ),
  );
}

class AddToRoutineSheet extends StatefulWidget {
  final RoutineItemEntity item;
  final Set<RoutineSlot> initial;
  final RoutineProductType? initialType;

  const AddToRoutineSheet({
    super.key,
    required this.item,
    required this.initial,
    this.initialType,
  });

  @override
  State<AddToRoutineSheet> createState() => _AddToRoutineSheetState();
}

class _AddToRoutineSheetState extends State<AddToRoutineSheet> {
  late final Set<RoutineSlot> _slots = {...widget.initial};
  late RoutineProductType? _type = widget.initialType;

  // Local copies of the reminder settings: applied on Save.
  late final RemindersState _remindersBefore = context
      .read<RemindersCubit>()
      .state;
  late bool _remindersOn = _remindersBefore.enabled;
  late final Map<RoutineSlot, TimeOfDay> _times = {
    for (final s in RoutineSlot.values) s: _remindersBefore.timeFor(s),
  };
  bool _saving = false;

  Future<void> _save() async {
    if (_saving) return;
    _saving = true;
    HapticFeedback.selectionClick();
    final reminders = context.read<RemindersCubit>();

    // Reminders first: turning them on may show the system permission prompt over this sheet.
    if (_slots.isNotEmpty) {
      if (_remindersOn != _remindersBefore.enabled) {
        await reminders.setEnabled(_remindersOn);
        if (!mounted) return;
        if (_remindersOn && !reminders.state.enabled) {
          showToast(
            context,
            reminders.state.notice ?? 'Notifications are off for Scanrix.',
            icon: Icons.notifications_off_outlined,
          );
        }
      }
      for (final s in _slots) {
        if (_times[s] != _remindersBefore.timeFor(s))
          await reminders.setTime(s, _times[s]!);
      }
      if (!mounted) return;
    }

    context.read<RoutineBloc>().add(
      RoutineSlotsSaved(widget.item, {..._slots}, productType: _type),
    );
    // Toast from the sheet's own context: it goes into the app's overlay, so it stays on screen after the
    // sheet closes (the sheet's context is gone once popped).
    final message = _savedMessage();
    if (message != null)
      showToast(context, message, icon: Icons.check_circle_outline_rounded);
    Navigator.of(context).pop();
  }

  String? _savedMessage() {
    final slotsChanged =
        !(_slots.length == widget.initial.length &&
            _slots.containsAll(widget.initial));
    if (!slotsChanged)
      return _slots.isNotEmpty && _type != widget.initialType
          ? 'Routine updated'
          : null;
    if (_slots.isEmpty) return 'Removed from your routine';
    if (_slots.length == 2) return 'Added to your morning and evening routine';
    return 'Added to your ${_slots.first.label.toLowerCase()} routine';
  }

  Future<void> _pickTime(RoutineSlot slot) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _times[slot]!,
    );
    if (picked != null && mounted) setState(() => _times[slot] = picked);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final inRoutine = widget.initial.isNotEmpty;
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 20.h),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            inRoutine ? 'In your routine' : 'Add to your routine',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18.sp,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            widget.item.name.isNotEmpty ? widget.item.name : 'This product',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: colors.secondaryText, fontSize: 13.sp),
          ),
          SizedBox(height: 16.h),
          Row(
            children: [
              for (final slot in RoutineSlot.values) ...[
                if (slot != RoutineSlot.values.first) SizedBox(width: 10.w),
                Expanded(
                  child: _SlotToggle(
                    slot: slot,
                    selected: _slots.contains(slot),
                    onTap: () => setState(
                      () => _slots.contains(slot)
                          ? _slots.remove(slot)
                          : _slots.add(slot),
                    ),
                  ),
                ),
              ],
            ],
          ),
          if (_slots.isNotEmpty) ...[
            SizedBox(height: 20.h),
            const _SectionLabel('Product type'),
            SizedBox(height: 10.h),
            Wrap(
              spacing: 8.w,
              runSpacing: 8.h,
              children: [
                for (final t in RoutineProductType.values)
                  _TypeChip(
                    label: t.label,
                    selected: _type == t,
                    // Tapping the selected one again clears it: the type is optional.
                    onTap: () => setState(() => _type = _type == t ? null : t),
                  ),
              ],
            ),
            SizedBox(height: 20.h),
            _ReminderSection(
              on: _remindersOn,
              onChanged: (v) => setState(() => _remindersOn = v),
              slots: [
                for (final s in RoutineSlot.values)
                  if (_slots.contains(s)) s,
              ],
              times: _times,
              onPickTime: _pickTime,
            ),
          ],
          SizedBox(height: 18.h),
          Pressable(
            onTap: _save,
            child: Container(
              height: 52.r,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: boldAccent(context),
                borderRadius: BorderRadius.circular(30.r),
              ),
              child: Text(
                _slots.isEmpty && inRoutine ? 'Remove from routine' : 'Save',
                style: TextStyle(
                  color: kOnAccent,
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;

  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) => Text(
    text.toUpperCase(),
    style: TextStyle(
      color: context.colors.secondaryText,
      fontSize: 11.5.sp,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.8,
    ),
  );
}

class _SlotToggle extends StatelessWidget {
  final RoutineSlot slot;
  final bool selected;
  final VoidCallback onTap;

  const _SlotToggle({
    required this.slot,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final accent = boldAccent(context);
    return Semantics(
      button: true,
      selected: selected,
      label: '${slot.label} routine',
      excludeSemantics: true,
      child: Pressable(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: EdgeInsets.symmetric(vertical: 16.h),
          decoration: BoxDecoration(
            color: selected
                ? accent.withValues(alpha: 0.16)
                : boldCardFill(colors),
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(
              color: selected ? accent : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Column(
            children: [
              Icon(
                slot.icon,
                color: selected ? accent : colors.secondaryText,
                size: 26.r,
              ),
              SizedBox(height: 6.h),
              Text(
                slot.label,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 2.h),
              Icon(
                selected
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked_rounded,
                color: selected
                    ? accent
                    : colors.secondaryText.withValues(alpha: 0.6),
                size: 18.r,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TypeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final accent = boldAccent(context);
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: Pressable(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 9.h),
          decoration: BoxDecoration(
            color: selected
                ? accent.withValues(alpha: 0.16)
                : boldCardFill(colors),
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(
              color: selected ? accent : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : colors.secondaryText,
              fontSize: 13.sp,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

/// "Remind me" switch (the app-wide reminders setting) and, when on, the time of each ticked routine.
class _ReminderSection extends StatelessWidget {
  final bool on;
  final ValueChanged<bool> onChanged;
  final List<RoutineSlot> slots;
  final Map<RoutineSlot, TimeOfDay> times;
  final ValueChanged<RoutineSlot> onPickTime;

  const _ReminderSection({
    required this.on,
    required this.onChanged,
    required this.slots,
    required this.times,
    required this.onPickTime,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final accent = boldAccent(context);
    final localizations = MaterialLocalizations.of(context);
    return BoldCard(
      padding: EdgeInsets.fromLTRB(14.w, 8.h, 8.w, on ? 12.h : 8.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.alarm_rounded, color: accent, size: 20.r),
              SizedBox(width: 10.w),
              Expanded(
                child: Text(
                  'Remind me',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Switch.adaptive(
                value: on,
                activeTrackColor: accent,
                onChanged: (v) {
                  HapticFeedback.selectionClick();
                  onChanged(v);
                },
              ),
            ],
          ),
          if (on) ...[
            for (final s in slots)
              Padding(
                padding: EdgeInsets.only(top: 6.h, right: 6.w),
                child: Row(
                  children: [
                    Icon(s.icon, color: colors.secondaryText, size: 16.r),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(
                        '${s.label} routine',
                        style: TextStyle(
                          color: colors.secondaryText,
                          fontSize: 13.sp,
                        ),
                      ),
                    ),
                    Pressable(
                      onTap: () => onPickTime(s),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 14.w,
                          vertical: 7.h,
                        ),
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(18.r),
                          border: Border.all(
                            color: accent.withValues(alpha: 0.6),
                          ),
                        ),
                        child: Text(
                          localizations.formatTimeOfDay(times[s]!),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            SizedBox(height: 8.h),
            Text(
              'One reminder per routine for all its steps. Changing a time here changes it for the whole routine.',
              style: TextStyle(
                color: colors.secondaryText.withValues(alpha: 0.8),
                fontSize: 11.sp,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
