import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scanrix_frontend/core/network/api_client.dart';
import 'package:scanrix_frontend/core/theme/app_theme_colors.dart';
import 'package:scanrix_frontend/features/favorites/domain/entities/favorite_entity.dart';
import 'package:scanrix_frontend/features/favorites/presentation/bloc/favorites_bloc.dart';
import 'package:scanrix_frontend/features/favorites/presentation/pages/favorites_page.dart';
import 'package:scanrix_frontend/features/products/domain/entities/product_entity.dart';
import 'package:scanrix_frontend/features/products/domain/usecases/get_product_usecase.dart';
import 'package:scanrix_frontend/features/products/presentation/bloc/product_bloc.dart';
import 'package:scanrix_frontend/features/products/presentation/pages/product_detail_page.dart';

import 'favorites_test_support.dart';
import 'history_test_support.dart' show networkDown;

/// Fixed frames instead of `pumpAndSettle`: spinners/indicators never "settle".
Future<void> _settle(WidgetTester t) async {
  for (var i = 0; i < 6; i++) {
    await t.pump(const Duration(milliseconds: 150));
  }
}

Widget _app(Widget home, List<BlocProvider> providers) => ScreenUtilInit(
      designSize: const Size(375, 812),
      builder: (_, _) => MultiBlocProvider(
        providers: providers,
        child: MaterialApp(
          theme: ThemeData(extensions: const [AppThemeColors.darkGreen]),
          home: home,
        ),
      ),
    );

void _bigScreen(WidgetTester t) {
  t.view.physicalSize = const Size(1125, 2400);
  t.view.devicePixelRatio = 3;
  addTearDown(t.view.reset);
}

Future<FavFakes> _pumpPage(
  WidgetTester t, {
  List<FavoriteEntity> items = const [],
  Object? listError,
}) async {
  final fakes = FavFakes(items: items, listError: listError);
  _bigScreen(t);
  await t.pumpWidget(_app(const FavoritesPage(), [BlocProvider<FavoritesBloc>.value(value: fakes.bloc())]));
  await _settle(t);
  return fakes;
}

class _FakeGetProduct implements GetProductUseCase {
  final ProductEntity product;
  _FakeGetProduct(this.product);

  @override
  ApiClient get apiClient => throw UnimplementedError();

  @override
  Future<ProductEntity> call(String barcode) async => product;
}

final _product = ProductEntity(
  id: 'p1',
  barcode: 'b1',
  name: 'Milk Bikis',
  brand: 'Britannia',
  category: 'food',
  ingredients: const [],
  verdict: 'safe',
  overallScore: 80,
  source: 'test',
  createdAt: DateTime(2026, 10, 16),
);

void main() {
  group('FavoritesPage', () {
    testWidgets('lists saved products with name, brand and the "Saved ..." line', (t) async {
      await _pumpPage(t, items: [fav('1'), fav('2')]);
      expect(find.text('Saved products'), findsOneWidget);
      expect(find.text('Product 1'), findsOneWidget);
      expect(find.text('Product 2'), findsOneWidget);
      expect(find.textContaining('Saved '), findsWidgets);
      expect(find.text('No flags'), findsNWidgets(2));
    });

    testWidgets('empty state explains how to save one', (t) async {
      await _pumpPage(t);
      expect(find.text('No saved products yet'), findsOneWidget);
      expect(find.textContaining('Tap the heart'), findsOneWidget);
    });

    testWidgets('load failure shows the message and a retry button', (t) async {
      await _pumpPage(t, listError: networkDown);
      expect(find.text('No internet connection'), findsOneWidget);
      expect(find.text('Try again'), findsOneWidget);
    });

    testWidgets('swiping a row left removes it (and calls the API)', (t) async {
      final f = await _pumpPage(t, items: [fav('1'), fav('2')]);
      await t.drag(find.text('Product 1'), const Offset(-600, 0));
      await _settle(t);
      expect(find.text('Product 1'), findsNothing);
      expect(find.text('Product 2'), findsOneWidget);
      expect(f.remove.removed, ['b1']);
    });

    testWidgets('first page size follows the screen; scrolling to the end loads the next page', (t) async {
      final f = await _pumpPage(t, items: [for (var i = 0; i < 60; i++) fav('$i')]);
      final limit = f.list.requests.first.limit;
      expect(limit, inInclusiveRange(10, 50));
      expect(limit, isNot(50));
      await t.drag(find.byType(ListView), const Offset(0, -6000));
      await _settle(t);
      expect(f.list.requests.length, greaterThanOrEqualTo(2));
      expect(f.list.requests[1].cursor, 'c$limit');
    });
  });

  group('the heart on the product page', () {
    Future<FavFakes> pumpProduct(WidgetTester t, {Set<String> saved = const {}, Object? addError}) async {
      final fakes = FavFakes(saved: saved, addError: addError);
      _bigScreen(t);
      final errors = FlutterError.onError;
      // The test font is wider than the real one and overflows a pre-existing hero pill; ignore only that.
      FlutterError.onError = (d) {
        if (d.exceptionAsString().contains('overflowed')) return;
        errors?.call(d);
      };
      addTearDown(() => FlutterError.onError = errors);
      await t.pumpWidget(_app(
        ProductDetailPage(barcode: 'b1', initialProduct: _product),
        [
          BlocProvider<FavoritesBloc>.value(value: fakes.bloc()),
          BlocProvider<ProductBloc>.value(value: ProductBloc(getProductUseCase: _FakeGetProduct(_product))),
        ],
      ));
      await _settle(t);
      return fakes;
    }

    testWidgets('an unsaved product shows an empty heart; tapping saves it and fills the heart', (t) async {
      final f = await pumpProduct(t);
      expect(find.byIcon(Icons.favorite_border_rounded), findsOneWidget);
      await t.tap(find.byIcon(Icons.favorite_border_rounded));
      await _settle(t);
      expect(find.byIcon(Icons.favorite_rounded), findsOneWidget);
      expect(f.add.added, ['b1']);
    });

    testWidgets('a saved product shows a filled heart; tapping it removes it', (t) async {
      final f = await pumpProduct(t, saved: {'b1'});
      expect(find.byIcon(Icons.favorite_rounded), findsOneWidget);
      await t.tap(find.byIcon(Icons.favorite_rounded));
      await _settle(t);
      expect(find.byIcon(Icons.favorite_border_rounded), findsOneWidget);
      expect(f.remove.removed, ['b1']);
    });

    testWidgets('a failed save puts the heart back to empty', (t) async {
      await pumpProduct(t, addError: networkDown);
      await t.tap(find.byIcon(Icons.favorite_border_rounded));
      await _settle(t);
      expect(find.byIcon(Icons.favorite_border_rounded), findsOneWidget);
      await t.pump(const Duration(seconds: 3)); // let the toast finish
    });
  });
}
