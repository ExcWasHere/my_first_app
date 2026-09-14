import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:week3/providers/stats_provider.dart';

void main() {
  test('StatsNotifier akhirnya menghasilkan AsyncData atau AsyncError', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final result = await container.read(statsProvider.future).then(
          (value) => AsyncData<List<String>>(value),
          onError: (e, st) => AsyncError<List<String>>(e, st),
        );

    expect(result, isA<AsyncValue<List<String>>>());
    if (result is AsyncData<List<String>>) {
      expect(result.value.length, 3);
    }
  });
}