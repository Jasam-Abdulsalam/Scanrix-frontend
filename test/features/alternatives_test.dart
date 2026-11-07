import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scanrix_frontend/core/error/exceptions.dart';
import 'package:scanrix_frontend/core/network/api_client.dart';
import 'package:scanrix_frontend/core/theme/app_theme_colors.dart';
import 'package:scanrix_frontend/features/alternatives/data/models/alternative_product_model.dart';
import 'package:scanrix_frontend/features/alternatives/domain/entities/alternative_product_entity.dart';
import 'package:scanrix_frontend/features/alternatives/domain/usecases/get_alternatives_usecase.dart';
import 'package:scanrix_frontend/features/alternatives/presentation/bloc/alternatives_bloc.dart';
import 'package:scanrix_frontend/features/alternatives/presentation/bloc/alternatives_event.dart';
import 'package:scanrix_frontend/features/alternatives/presentation/bloc/alternatives_state.dart';
import 'package:scanrix_frontend/features/alternatives/presentation/widgets/alternative_style.dart';
import 'package:scanrix_frontend/features/alternatives/presentation/widgets/alternatives_carousel.dart';

class _FakeGetAlternatives implements GetAlternativesUseCase {
  final AlternativesResult? result;
  final Object? error;
  final Duration latency;
  int calls = 0;

  _FakeGetAlternatives({this.result, this.error, this.latency = Duration.zero});

  @override
  ApiClient get apiClient => throw UnimplementedError();

  @override
  Future<AlternativesResult> call(String barcode) async {
    calls++;
    await Future<void>.delayed(latency);
    if (error != null) throw error!;
    return result!;
  }
}

const _a = AlternativeProductEntity(
    name: 'Gentle Wash', brand: 'Acme', size: '100 ml', priceInr: 299, whyBetter: 'No fragrance', avoids: ['Linalool']);
const _b = AlternativeProductEntity(name: 'Calm Wash', brand: 'Beta', priceInr: 500, whyBetter: 'Soap-free');
const _result = AlternativesResult(productType: 'face wash', originalPriceInr: 250, alternatives: [_a, _b], disclaimer: 'd');

Map<String, dynamic> _json() => {
      'product_type': 'foaming face wash',
      'original_price_inr': 250,
      'alternatives': [
        {'name': 'Gentle Wash', 'brand': 'Acme', 'size': '100 ml', 'price_inr': 299, 'why_better': 'x', 'avoids': ['Linalool', 3]},
        {'name': '', 'brand': 'NoName', 'why_better': 'dropped: no name'},
        'junk',
      ],
      'cached': false,
      'credits_remaining': 3,
      'disclaimer': 'AI suggestions.',
    };

void main() {
  group('AlternativesResultModel', () {
    test('parses the backend response and drops unusable items', () {
      final r = AlternativesResultModel.fromJson(_json());
      expect(r.productType, 'foaming face wash');
      expect(r.originalPriceInr, 250);
      expect(r.alternatives.map((a) => a.name), ['Gentle Wash']);
      expect(r.alternatives.first.avoids, ['Linalool']);
      expect(r.cached, isFalse);
      expect(r.creditsRemaining, 3);
    });

    test('only https photos are kept', () {
      AlternativeProductEntity first(Object? url) => AlternativesResultModel.fromJson({
            'alternatives': [
              {'name': 'n', 'brand': 'b', 'why_better': 'w', 'image_url': url}
            ]
          }).alternatives.first;
      expect(first('https://img.example/a.jpg').imageUrl, 'https://img.example/a.jpg');
      expect(first('http://img.example/a.jpg').imageUrl, isNull);
      expect(first(null).imageUrl, isNull);
    });

    test('missing / wrong-typed fields never throw', () {
      final r = AlternativesResultModel.fromJson({'alternatives': 'nope', 'original_price_inr': -5});
      expect(r.productType, 'product');
      expect(r.originalPriceInr, isNull);
      expect(r.alternatives, isEmpty);
      expect(r.disclaimer, isNotEmpty);
    });
  });

  group('style helpers', () {
    test('prices are approximate and use Indian grouping', () {
      expect(_a.priceLabel, '≈ ₹299');
      expect(formatInr(125000), '₹1,25,000');
      expect(formatInr(1299), '₹1,299');
      expect(const AlternativeProductEntity(name: 'x', brand: 'y', whyBetter: '').priceLabel, isNull);
    });

    test('price comparison with the scanned product', () {
      expect(_a.priceComparedTo(400), 'Cheaper than yours');
      expect(_a.priceComparedTo(290), 'Similar price');
      expect(_b.priceComparedTo(250), '≈ 2.0× yours');
      expect(_a.priceComparedTo(null), isNull);
    });

    test('avoids label', () {
      expect(_a.avoidsLabel, 'Avoids 1 flagged ingredient');
      expect(_b.avoidsLabel, isNull);
    });
  });

  group('AlternativesBloc', () {
    test('loading then loaded', () async {
      final b = AlternativesBloc(getAlternativesUseCase: _FakeGetAlternatives(result: _result));
      final states = b.stream.take(2).toList();
      b.add(const AlternativesRequested('8901'));
      expect(await states, [const AlternativesLoading(), const AlternativesLoaded(_result)]);
      await b.close();
    });

    Future<AlternativesFailure> failWith(Object error) async {
      final b = AlternativesBloc(getAlternativesUseCase: _FakeGetAlternatives(error: error));
      b.add(const AlternativesRequested('8901'));
      final s = await b.stream.firstWhere((s) => s is AlternativesFailure) as AlternativesFailure;
      await b.close();
      return s;
    }

    test('out of credits: no retry, shows when credits come back', () async {
      final s = await failWith(const ServerException(
          message: 'x', statusCode: 429, code: 'ai_credits_exhausted', details: {'resets_at': '2030-01-07T00:00:00+00:00'}));
      expect(s.kind, AlternativesFailureKind.creditsExhausted);
      expect(s.canRetry, isFalse);
      expect(s.resetsAt, DateTime.utc(2030, 1, 7));
    });

    test('AI unavailable says the user was not charged and can retry', () async {
      final s = await failWith(const ServerException(message: 'x', statusCode: 503, code: 'ai_unavailable'));
      expect(s.kind, AlternativesFailureKind.unavailable);
      expect(s.message, contains('not charged'));
      expect(s.canRetry, isTrue);
    });

    test('missing ingredients and network errors', () async {
      expect((await failWith(const ServerException(message: 'x', statusCode: 422, code: 'ingredients_missing'))).kind,
          AlternativesFailureKind.ingredientsMissing);
      expect((await failWith(const NetworkException())).kind, AlternativesFailureKind.network);
    });

    test('a double tap fires one request (droppable)', () async {
      final fake = _FakeGetAlternatives(result: _result, latency: const Duration(milliseconds: 30));
      final b = AlternativesBloc(getAlternativesUseCase: fake);
      b
        ..add(const AlternativesRequested('8901'))
        ..add(const AlternativesRequested('8901'));
      await b.stream.firstWhere((s) => s is AlternativesLoaded);
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(fake.calls, 1);
      await b.close();
    });
  });

  testWidgets('carousel shows AI cards; side tap turns the wheel, centre tap opens', (tester) async {
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
            onOpen: (item, _) async => opened.add(item.name),
          ),
        ),
      ),
    ));
    await tester.pump();
    expect(find.text('Gentle Wash'), findsOneWidget);
    expect(find.text('≈ ₹299'), findsOneWidget);
    expect(find.text('Avoids 1 flagged ingredient'), findsOneWidget);
    expect(find.text('AI Suggestion'), findsWidgets);

    final size = tester.getSize(find.byType(AlternativesCarousel));
    await tester.tapAt(Offset(size.width * 0.95, size.height * 0.4));
    await tester.pumpAndSettle();
    expect(opened, isEmpty);

    await tester.tapAt(Offset(size.width / 2, size.height * 0.4));
    await tester.pumpAndSettle();
    expect(opened, ['Calm Wash']);
  });
}
