import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
class StatsNotifier extends AsyncNotifier<List<String>> {
  @override
  Future<List<String>> build() async {
    return _fetchStats();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetchStats);
  }

  Future<List<String>> _fetchStats() async {
    await Future.delayed(const Duration(seconds: 2));
    if (Random().nextDouble() < 0.3) {
      throw Exception('Gagal mengambil data statistik');
    }
    return ['Pengguna aktif: 128', 'Transaksi: 47', 'Rating: 4.6'];
  }
}

final statsProvider =
    AsyncNotifierProvider<StatsNotifier, List<String>>(StatsNotifier.new);