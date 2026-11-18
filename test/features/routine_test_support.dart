import 'package:scanrix_frontend/core/network/api_client.dart';
import 'package:scanrix_frontend/core/usecase/usecase.dart';
import 'package:scanrix_frontend/features/routine/domain/entities/routine_entity.dart';
import 'package:scanrix_frontend/features/routine/domain/usecases/add_to_routine_usecase.dart';
import 'package:scanrix_frontend/features/routine/domain/usecases/get_routine_usecase.dart';
import 'package:scanrix_frontend/features/routine/domain/usecases/remove_from_routine_usecase.dart';
import 'package:scanrix_frontend/features/routine/domain/usecases/reorder_routine_usecase.dart';
import 'package:scanrix_frontend/features/routine/domain/usecases/routine_step_params.dart';
import 'package:scanrix_frontend/features/routine/domain/usecases/set_routine_product_type_usecase.dart';
import 'package:scanrix_frontend/features/routine/presentation/bloc/routine_bloc.dart';

// Shared by routine_test.dart and any widget test that shows the product page (it reads RoutineBloc).

/// In-memory backend: the use cases share it, and can be told to fail.
class FakeServer {
  RoutineEntity routine;
  Object? failWith;
  final calls = <String>[];

  FakeServer([this.routine = RoutineEntity.empty]);
}

class _Get implements GetRoutineUseCase {
  final FakeServer s;
  _Get(this.s);
  @override
  ApiClient get apiClient => throw UnimplementedError();
  @override
  Future<RoutineEntity> call(NoParams p) async {
    s.calls.add('get');
    return s.routine;
  }
}

class _Add implements AddToRoutineUseCase {
  final FakeServer s;
  _Add(this.s);
  @override
  ApiClient get apiClient => throw UnimplementedError();
  @override
  Future<void> call(RoutineStepParams p) async {
    s.calls.add('add:${p.slot.name}:${p.barcode}');
    if (s.failWith != null) throw s.failWith!;
  }
}

class _Remove implements RemoveFromRoutineUseCase {
  final FakeServer s;
  _Remove(this.s);
  @override
  ApiClient get apiClient => throw UnimplementedError();
  @override
  Future<void> call(RoutineStepParams p) async {
    s.calls.add('remove:${p.slot.name}:${p.barcode}');
    if (s.failWith != null) throw s.failWith!;
  }
}

class _Reorder implements ReorderRoutineUseCase {
  final FakeServer s;
  _Reorder(this.s);
  @override
  ApiClient get apiClient => throw UnimplementedError();
  @override
  Future<void> call(ReorderParams p) async {
    s.calls.add('reorder:${p.slot.name}:${p.barcodes.join(',')}');
    if (s.failWith != null) throw s.failWith!;
  }
}

class _SetType implements SetRoutineProductTypeUseCase {
  final FakeServer s;
  _SetType(this.s);
  @override
  ApiClient get apiClient => throw UnimplementedError();
  @override
  Future<void> call(ProductTypeParams p) async {
    s.calls.add('type:${p.barcode}:${p.productType?.name}');
    if (s.failWith != null) throw s.failWith!;
  }
}

RoutineBloc blocFor(FakeServer s) => RoutineBloc(
  getRoutineUseCase: _Get(s),
  addToRoutineUseCase: _Add(s),
  removeFromRoutineUseCase: _Remove(s),
  reorderRoutineUseCase: _Reorder(s),
  setProductTypeUseCase: _SetType(s),
);
