import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'stock_list_state.dart';

class StockListViewModel extends StateNotifier<StockListState> {
  StockListViewModel() : super(const StockListState());

  void onQueryChanged(String value) {
    state = state.copyWith(query: value);
  }
}

final stockListViewModelProvider =
    StateNotifierProvider.autoDispose<StockListViewModel, StockListState>((
      ref,
    ) {
      return StockListViewModel();
    });
