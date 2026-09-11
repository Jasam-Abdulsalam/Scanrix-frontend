import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/get_product_usecase.dart';
import 'product_event.dart';
import 'product_state.dart';

class ProductBloc extends Bloc<ProductEvent, ProductState> {
  final GetProductUseCase getProductUseCase;

  ProductBloc({required this.getProductUseCase}) : super(ProductInitial()) {
    on<ProductRequested>(_onProductRequested);
  }

  Future<void> _onProductRequested(
    ProductRequested event,
    Emitter<ProductState> emit,
  ) async {
    emit(ProductLoading());
    try {
      final product = await getProductUseCase(event.barcode);
      emit(ProductLoaded(product));
    } catch (e) {
      emit(ProductFailure(e.toString()));
    }
  }
}
