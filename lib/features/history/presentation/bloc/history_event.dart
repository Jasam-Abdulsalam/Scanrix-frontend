import 'package:equatable/equatable.dart';

abstract class HistoryEvent extends Equatable {
  const HistoryEvent();

  @override
  List<Object?> get props => [];
}

class HistoryRequested extends HistoryEvent {
  final int limit;

  const HistoryRequested({this.limit = 50});

  @override
  List<Object?> get props => [limit];
}
