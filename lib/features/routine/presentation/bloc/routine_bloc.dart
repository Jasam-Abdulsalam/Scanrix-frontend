import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/usecase/usecase.dart';
import '../../domain/entities/routine_entity.dart';
import '../../domain/usecases/add_to_routine_usecase.dart';
import '../../domain/usecases/get_routine_usecase.dart';
import '../../domain/usecases/remove_from_routine_usecase.dart';
import '../../domain/usecases/reorder_routine_usecase.dart';
import '../../domain/usecases/routine_step_params.dart';
import '../../domain/usecases/set_routine_product_type_usecase.dart';
import 'routine_event.dart';
import 'routine_state.dart';

/// App-wide (provided in app.dart): the result screen's "Add to routine" button, the Routine page and the
/// reminders all read it. Changes are optimistic: the screen updates at once, and a failed request puts the
/// previous routine back (then reloads, in case part of a multi-step change went through).
class RoutineBloc extends Bloc<RoutineEvent, RoutineState> {
  final GetRoutineUseCase getRoutineUseCase;
  final AddToRoutineUseCase addToRoutineUseCase;
  final RemoveFromRoutineUseCase removeFromRoutineUseCase;
  final ReorderRoutineUseCase reorderRoutineUseCase;
  final SetRoutineProductTypeUseCase setProductTypeUseCase;

  RoutineBloc({
    required this.getRoutineUseCase,
    required this.addToRoutineUseCase,
    required this.removeFromRoutineUseCase,
    required this.reorderRoutineUseCase,
    required this.setProductTypeUseCase,
  }) : super(const RoutineState()) {
    on<RoutineRequested>(_onRequested, transformer: droppable());
    // sequential: each optimistic change starts from the result of the previous one.
    on<RoutineSlotsSaved>(_onSlotsSaved, transformer: sequential());
    on<RoutineStepRemoved>(_onRemoved, transformer: sequential());
    on<RoutineStepMoved>(_onMoved, transformer: sequential());
    on<RoutineReset>((_, emit) => emit(const RoutineState()));
  }

  Future<void> _onRequested(
    RoutineRequested event,
    Emitter<RoutineState> emit,
  ) async {
    final keep = event.silent && state.status == RoutineStatus.loaded;
    if (!keep) emit(state.copyWith(status: RoutineStatus.loading));
    try {
      emit(
        state.copyWith(
          status: RoutineStatus.loaded,
          routine: await getRoutineUseCase(const NoParams()),
        ),
      );
    } catch (e) {
      if (keep) return; // a failed silent refresh keeps what the user sees
      emit(
        state.copyWith(
          status: RoutineStatus.failure,
          failureMessage: _messageFor(e),
        ),
      );
    }
  }

  Future<void> _onSlotsSaved(
    RoutineSlotsSaved event,
    Emitter<RoutineState> emit,
  ) async {
    final before = state.routine;
    final current = before.slotsOf(event.item.barcode);
    final toAdd = event.slots.difference(current);
    final toRemove = current.difference(event.slots);
    // The label only exists while the product is in a slot (the backend drops it on removal).
    final type = event.slots.isEmpty ? null : event.productType;
    final typeChanged =
        event.slots.isNotEmpty &&
        type != before.productTypeOf(event.item.barcode);
    if (toAdd.isEmpty && toRemove.isEmpty && !typeChanged) return;

    final item = event.item.withProductType(type);
    var next = before;
    for (final s in toAdd) {
      next = next.withSlot(s, [...next.slot(s), item]);
    }
    for (final s in toRemove) {
      next = next.withSlot(
        s,
        next.slot(s).where((i) => i.barcode != item.barcode).toList(),
      );
    }
    if (typeChanged) next = next.withProductType(item.barcode, type);
    emit(state.copyWith(routine: next));
    try {
      for (final s in toAdd) {
        await addToRoutineUseCase(RoutineStepParams(s, item.barcode));
      }
      for (final s in toRemove) {
        await removeFromRoutineUseCase(RoutineStepParams(s, item.barcode));
      }
      // After the adds: the backend only labels a product that is in a slot.
      if (typeChanged)
        await setProductTypeUseCase(ProductTypeParams(item.barcode, type));
    } catch (e) {
      await _undo(
        emit,
        before,
        "Couldn't update your routine. ${_messageFor(e)}",
      );
    }
  }

  Future<void> _onRemoved(
    RoutineStepRemoved event,
    Emitter<RoutineState> emit,
  ) async {
    final before = state.routine;
    emit(
      state.copyWith(
        routine: before.withSlot(
          event.slot,
          before
              .slot(event.slot)
              .where((i) => i.barcode != event.barcode)
              .toList(),
        ),
      ),
    );
    try {
      await removeFromRoutineUseCase(
        RoutineStepParams(event.slot, event.barcode),
      );
    } catch (e) {
      await _undo(emit, before, "Couldn't remove this step. ${_messageFor(e)}");
    }
  }

  Future<void> _onMoved(
    RoutineStepMoved event,
    Emitter<RoutineState> emit,
  ) async {
    final before = state.routine;
    final items = [...before.slot(event.slot)];
    if (event.oldIndex < 0 || event.oldIndex >= items.length) return;
    final target = event.newIndex.clamp(0, items.length - 1);
    if (target == event.oldIndex) return;
    items.insert(target, items.removeAt(event.oldIndex));
    emit(state.copyWith(routine: before.withSlot(event.slot, items)));
    try {
      await reorderRoutineUseCase(
        ReorderParams(event.slot, [for (final i in items) i.barcode]),
      );
    } catch (e) {
      await _undo(
        emit,
        before,
        "Couldn't save the new order. ${_messageFor(e)}",
      );
    }
  }

  /// Put [before] back with a [notice], then reload quietly: a multi-step change may have partly
  /// gone through, or the routine changed on another phone (`order_mismatch`).
  Future<void> _undo(
    Emitter<RoutineState> emit,
    RoutineEntity before,
    String notice,
  ) async {
    emit(state.copyWith(routine: before, notice: notice));
    try {
      emit(state.copyWith(routine: await getRoutineUseCase(const NoParams())));
    } catch (_) {
      // Offline: keep the restored routine; the next load fixes it.
    }
  }

  String _messageFor(Object e) {
    if (e is ServerException &&
        (e.code == 'routine_slot_full' || e.code == 'not_cosmetic'))
      return e.message;
    if (e is ServerException && e.code == 'order_mismatch')
      return 'Your routine changed. It has been reloaded.';
    return e is NetworkException || e is ServerException
        ? e.toString()
        : 'Something went wrong. Please try again.';
  }
}
