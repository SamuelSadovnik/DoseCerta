enum TreatmentFilter { active, ended }

extension TreatmentFilterX on TreatmentFilter {
  String get label => switch (this) {
    TreatmentFilter.active => 'Ativos',
    TreatmentFilter.ended => 'Encerrados',
  };
}

class StockListState {
  const StockListState({this.query = '', this.filter = TreatmentFilter.active});

  final String query;
  final TreatmentFilter filter;

  StockListState copyWith({String? query, TreatmentFilter? filter}) {
    return StockListState(
      query: query ?? this.query,
      filter: filter ?? this.filter,
    );
  }
}
