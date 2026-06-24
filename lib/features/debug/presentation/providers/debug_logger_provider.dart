import 'package:flutter_riverpod/flutter_riverpod.dart';

class DebugLogState {
  final String? lastRequest;
  final String? lastResponse;

  const DebugLogState({this.lastRequest, this.lastResponse});
}

class DebugLogNotifier extends StateNotifier<DebugLogState> {
  DebugLogNotifier() : super(const DebugLogState());

  void logRequest(String req) {
    state = DebugLogState(lastRequest: req, lastResponse: state.lastResponse);
  }

  void logResponse(String res) {
    state = DebugLogState(lastRequest: state.lastRequest, lastResponse: res);
  }
}

final debugLogProvider = StateNotifierProvider<DebugLogNotifier, DebugLogState>(
  (ref) {
    return DebugLogNotifier();
  },
);
