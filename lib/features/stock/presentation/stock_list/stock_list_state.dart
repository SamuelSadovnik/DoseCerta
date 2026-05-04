class StockListState {
  const StockListState({this.query = ''});

  final String query;

  StockListState copyWith({String? query}) {
    return StockListState(query: query ?? this.query);
  }
}
