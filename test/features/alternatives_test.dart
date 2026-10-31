import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scanrix_frontend/core/error/exceptions.dart';
import 'package:scanrix_frontend/core/network/api_client.dart';
import 'package:scanrix_frontend/core/theme/app_theme_colors.dart';
import 'package:scanrix_frontend/features/alternatives/data/mock/mock_alternatives.dart';
import 'package:scanrix_frontend/features/alternatives/data/models/alternative_product_model.dart';
import 'package:scanrix_frontend/features/alternatives/domain/entities/alternative_product_entity.dart';
import 'package:scanrix_frontend/features/alternatives/domain/usecases/get_alternatives_usecase.dart';
import 'package:scanrix_frontend/features/alternatives/presentation/bloc/alternatives_bloc.dart';
import 'package:scanrix_frontend/features/alternatives/presentation/bloc/alternatives_event.dart';
import 'package:scanrix_frontend/features/alternatives/presentation/bloc/alternatives_state.dart';
import 'package:scanrix_frontend/features/alternatives/presentation/widgets/alternative_style.dart';
import 'package:scanrix_frontend/features/alternatives/presentation/widgets/alternatives_carousel.dart';

class _FakeGetAlternatives implements GetAlternativesUseCase {
  final List<AlternativeProductEntity> result;
  final Object? error;
  final Duration latency;
  int calls = 0;

  _FakeGetAlternatives({this.result = const [], this.error, this.latency = Duration.zero});

  @override
  ApiClient get apiClient => throw UnimplementedError();

  @override
  Duration get mockDelay => Duration.zero;

  @override
  Future<List<AlternativeProductEntity>> call(String barcode) async {
    calls++;
    await Future<void>.delayed(latency);
    if (error != null) throw error!;
    return result;
  }
}

const _a = AlternativeProductEntity(barcode: 'a1', name: 'Gentle Wash', brand: 'Acme', overallScore: 90, verdict: 'safe');
const _b = AlternativeProductEntity(barcode: 'b1', name: 'Calm Wash', brand: 'Beta', overallScore: 70, verdict: 'caution');

void main() {
  group('AlternativeProductModel', () {
    test('parses an item', () {
      final m = AlternativeProductModel.fromJson({
        'barcode': '123',
        'name': 'Gentle Wash',
        'brand': 'Acme',
        'overall_score': 91,
        'verdict': 'safe',
        'concern_count': 2,
        'highlights': ['Fragrance-free', 7],
        'price': 3.5,
        'currency': 'USD',
      });
      expect(m.overallScore, 91);
      expect(m.concernCount, 2);
      expect(m.highlights, ['Fragrance-free']);
      expect(m.priceLabel, r'$3.50');
    });

    test('missing / wrong-typed fields never throw', () {
      final m = AlternativeProductModel.fromJson({'barcode': '1', 'name': 'X', 'verdict': null, 'highlights': 'nope'});
      expect(m.verdict, 'unknown');
      expect(m.overallScore, isNull);
      expect(m.highlights, isEmpty);
      expect(m.priceLabel, isNull);
    });

    test('list parsing accepts {items: [...]} or a bare list and drops malformed items', () {
      expect(AlternativeProductModel.listFromJson(mockAlternativesResponse), hasLength(4));
      final parsed = AlternativeProductModel.listFromJson([
        {'barcode': '1', 'name': 'ok'},
        {'barcode': '', 'name': 'no barcode'},
        'junk',
      ]);
      expect(parsed.map((a) => a.barcode), ['1']);
      expect(AlternativeProductModel.listFromJson(null), isEmpty);
    });
  });

  group('style helpers', () {
    test('score gain only when this one is higher', () {
      expect(_a.scoreGainOver(60), 30);
      expect(_a.scoreGainOver(95), isNull);
      expect(_a.scoreGainOver(null), isNull);
    });

    test('INR price without decimals', () {
      const p = AlternativeProductEntity(barcode: 'x', name: 'x', brand: 'x', verdict: 'safe', price: 399, currency: 'INR');
      expect(p.priceLabel, '₹399');
    });
  });

  test('mock use case never returns the scanned product itself', () async {
    final uc = GetAlternativesUseCase(apiClient: _NoApi(), mockDelay: Duration.zero);
    final all = await uc('nothing-matches');
    final scanned = all.first.barcode;
    expect((await uc(scanned)).map((a) => a.barcode), isNot(contains(scanned)));
  });

  group('AlternativesBloc', () {
    test('loading then loaded', () async {
      final b = AlternativesBloc(getAlternativesUseCase: _FakeGetAlternatives(result: [_a, _b]));
      final states = b.stream.take(2).toList();
      b.add(const AlternativesRequested('scanned'));
      expect(await states, [const AlternativesLoading(), const AlternativesLoaded([_a, _b])]);
      await b.close();
    });

    test('a network error becomes a failure with a friendly message', () async {
      final b = AlternativesBloc(getAlternativesUseCase: _FakeGetAlternatives(error: const NetworkException()));
      b.add(const AlternativesRequested('scanned'));
      final s = await b.stream.firstWhere((s) => s is AlternativesFailure);
      expect((s as AlternativesFailure).message, contains('No connection'));
      await b.close();
    });

    test('a double tap on retry fires one request (droppable)', () async {
      // Latency so the second tap lands while the first request is still running.
      final fake = _FakeGetAlternatives(result: [_a], latency: const Duration(milliseconds: 30));
      final b = AlternativesBloc(getAlternativesUseCase: fake);
      b
        ..add(const AlternativesRequested('scanned'))
        ..add(const AlternativesRequested('scanned'));
      await b.stream.firstWhere((s) => s is AlternativesLoaded);
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(fake.calls, 1);
      await b.close();
    });
  });

  testWidgets('carousel: side tap centres, centre tap opens', (tester) async {
    final opened = <String>[];
    tester.view
      ..physicalSize = const Size(375, 812)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(ScreenUtilInit(
      designSize: const Size(375, 812),
      builder: (_, _) => MaterialApp(
        theme: ThemeData(extensions: const [AppThemeColors.darkGreen]),
        home: Scaffold(
          body: AlternativesCarousel(
            items: const [_a, _b],
            originalScore: 50,
            onOpen: (item, _) async => opened.add(item.barcode),
          ),
        ),
      ),
    ));
    await tester.pump();
    expect(find.text('Gentle Wash'), findsOneWidget);
    expect(find.text('+40 vs. yours'), findsOneWidget);

    // Right of centre = the second card's page slot: first tap only centres it.
    final size = tester.getSize(find.byType(AlternativesCarousel));
    await tester.tapAt(Offset(size.width * 0.95, size.height * 0.4));
    await tester.pumpAndSettle();
    expect(opened, isEmpty);

    // Now it's centred: tapping the middle opens it.
    await tester.tapAt(Offset(size.width / 2, size.height * 0.4));
    await tester.pumpAndSettle();
    expect(opened, ['b1']);
  });
}

class _NoApi implements ApiClient {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}
