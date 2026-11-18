import 'package:equatable/equatable.dart';

import '../../domain/entities/routine_entity.dart';

abstract class RoutineEvent extends Equatable {
  const RoutineEvent();

  @override
  List<Object?> get props => [];
}

/// Load the routine. [silent]: keep showing the current one while it refreshes.
class RoutineRequested extends RoutineEvent {
  final bool silent;

  const RoutineRequested({this.silent = false});

  @override
  List<Object?> get props => [silent];
}

/// The add sheet's Save: [item] should be in exactly these [slots] (added as the last step of a newly
/// ticked slot, removed from an unticked one), labelled [productType]. An empty set removes it from the
/// routine (and its label with it).
class RoutineSlotsSaved extends RoutineEvent {
  final RoutineItemEntity item;
  final Set<RoutineSlot> slots;
  final RoutineProductType? productType;

  const RoutineSlotsSaved(this.item, this.slots, {this.productType});

  @override
  List<Object?> get props => [item, slots, productType];
}

class RoutineStepRemoved extends RoutineEvent {
  final RoutineSlot slot;
  final String barcode;

  const RoutineStepRemoved(this.slot, this.barcode);

  @override
  List<Object?> get props => [slot, barcode];
}

/// A drag in the list: the step at [oldIndex] now sits at [newIndex] (its final position, as
/// `ReorderableListView.onReorderItem` reports it).
class RoutineStepMoved extends RoutineEvent {
  final RoutineSlot slot;
  final int oldIndex;
  final int newIndex;

  const RoutineStepMoved(this.slot, this.oldIndex, this.newIndex);

  @override
  List<Object?> get props => [slot, oldIndex, newIndex];
}

/// Logout: forget this account's routine.
class RoutineReset extends RoutineEvent {
  const RoutineReset();
}
