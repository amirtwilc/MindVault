import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final connectivityProvider = StreamProvider<bool>((ref) async* {
  final conn = Connectivity();
  final initial = await conn.checkConnectivity();
  yield initial.any((r) => r != ConnectivityResult.none);
  yield* conn.onConnectivityChanged.map(
    (results) => results.any((r) => r != ConnectivityResult.none),
  );
});
