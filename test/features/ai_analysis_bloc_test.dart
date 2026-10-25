import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:scanrix_frontend/core/error/exceptions.dart';
import 'package:scanrix_frontend/features/products/domain/entities/ai_analysis_entity.dart';
import 'package:scanrix_frontend/features/products/presentation/bloc/ai_analysis_bloc.dart';
import 'package:scanrix_frontend/features/products/presentation/bloc/ai_analysis_event.dart';
import 'package:scanrix_frontend/features/products/presentation/bloc/ai_analysis_state.dart';

import 'ai_analysis_test_support.dart';

const _request = AiAnalysisRequest.barcode('8901');
final _credits = AiCredits(limit: 6, remaining: 5, resetsAt: DateTime.utc(2026, 10, 19));

AiAnalysisBloc _bloc(FakeAnalyzeWithAi analyze, {AiCredits? credits}) =>
    AiAnalysisBloc(analyzeWithAiUseCase: analyze, getAiCreditsUseCase: FakeGetAiCredits(credits));

Future<AiAnalysisState> _settled(AiAnalysisBloc bloc, AiAnalysisStatus status) =>
    bloc.stream.firstWhere((s) => s.status == status).timeout(const Duration(seconds: 2));

void main() {
  test('success: loading then loaded with the analysis', () async {
    final bloc = _bloc(FakeAnalyzeWithAi((_) async => sampleAnalysis));
    bloc.add(const AiAnalysisRequested(_request));
    final loaded = await _settled(bloc, AiAnalysisStatus.loaded);
    expect(loaded.analysis, sampleAnalysis);
    expect(loaded.failure, isNull);
    await bloc.close();
  });

  test('droppable: a double tap (3 rapid events) makes exactly ONE AI call', () async {
    final completer = Completer<AiAnalysis>();
    final fake = FakeAnalyzeWithAi((_) => completer.future);
    final bloc = _bloc(fake);

    bloc
      ..add(const AiAnalysisRequested(_request))
      ..add(const AiAnalysisRequested(_request))
      ..add(const AiAnalysisRequested(_request));
    await Future<void>.delayed(Duration.zero);
    expect(fake.calls, 1);
    expect(bloc.state.isLoading, isTrue);

    completer.complete(sampleAnalysis);
    await _settled(bloc, AiAnalysisStatus.loaded);
    expect(fake.calls, 1, reason: 'dropped events must not run after the first finishes');
    await bloc.close();
  });

  test('after a request finishes a new one is accepted again (retry)', () async {
    var n = 0;
    final fake = FakeAnalyzeWithAi((_) async {
      if (++n == 1) throw const ServerException(message: 'x', statusCode: 503, code: 'ai_unavailable');
      return sampleAnalysis;
    });
    final bloc = _bloc(fake);
    bloc.add(const AiAnalysisRequested(_request));
    await _settled(bloc, AiAnalysisStatus.failure);
    bloc.add(const AiAnalysisRequested(_request));
    final loaded = await _settled(bloc, AiAnalysisStatus.loaded);
    expect(fake.calls, 2);
    expect(loaded.failure, isNull, reason: 'a successful retry clears the old failure');
    await bloc.close();
  });

  Future<AiFailure> failureFor(Object error) async {
    final bloc = _bloc(FakeAnalyzeWithAi((_) async => throw error));
    bloc.add(const AiAnalysisRequested(_request));
    final s = await _settled(bloc, AiAnalysisStatus.failure);
    await bloc.close();
    return s.failure!;
  }

  test('maps each backend error to a failure kind', () async {
    expect((await failureFor(const ServerException(message: 'm', statusCode: 422, code: 'ingredients_missing'))).kind,
        AiFailureKind.ingredientsMissing);
    expect((await failureFor(const ServerException(message: 'm', statusCode: 503, code: 'ai_unavailable'))).kind,
        AiFailureKind.unavailable);
    expect((await failureFor(const ServerException(message: 'm', statusCode: 404))).kind, AiFailureKind.notFound);
    expect((await failureFor(const ServerException(message: 'm', statusCode: 500))).kind, AiFailureKind.other);
    expect((await failureFor(const NetworkException())).kind, AiFailureKind.network);
    expect((await failureFor(StateError('boom'))).kind, AiFailureKind.other);
  });

  test('a 422 without the ingredients_missing code is not mistaken for it', () async {
    expect((await failureFor(const ServerException(message: 'm', statusCode: 422))).kind, AiFailureKind.other);
  });

  test('429 carries resets_at and zeroes the known credit balance', () async {
    final bloc = _bloc(
      FakeAnalyzeWithAi((_) async => throw const ServerException(
            message: 'm',
            statusCode: 429,
            code: 'ai_credits_exhausted',
            details: {'resets_at': '2026-10-19T00:00:00+00:00'},
          )),
      credits: _credits,
    );
    bloc.add(const AiCreditsRequested());
    await bloc.stream.firstWhere((s) => s.credits != null);
    bloc.add(const AiAnalysisRequested(_request));
    final s = await _settled(bloc, AiAnalysisStatus.failure);
    expect(s.failure!.kind, AiFailureKind.creditsExhausted);
    expect(s.failure!.resetsAt, DateTime.utc(2026, 10, 19));
    expect(s.credits!.remaining, 0);
    await bloc.close();
  });

  test('credits: loaded on request, and updated from the analysis response', () async {
    final analysis = AiAnalysis(
      verdict: AiVerdict.caution,
      score: 55,
      summary: 's',
      creditsRemaining: 4,
      generatedAt: DateTime.utc(2026, 10, 14),
    );
    final bloc = _bloc(FakeAnalyzeWithAi((_) async => analysis), credits: _credits);
    bloc.add(const AiCreditsRequested());
    expect((await bloc.stream.firstWhere((s) => s.credits != null)).credits!.remaining, 5);
    bloc.add(const AiAnalysisRequested(_request));
    final s = await _settled(bloc, AiAnalysisStatus.loaded);
    expect(s.credits!.remaining, 4);
    await bloc.close();
  });

  test('a failed credits lookup is silent', () async {
    final bloc = _bloc(FakeAnalyzeWithAi((_) async => sampleAnalysis));
    bloc.add(const AiCreditsRequested());
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(bloc.state.status, AiAnalysisStatus.idle);
    expect(bloc.state.credits, isNull);
    await bloc.close();
  });
}
