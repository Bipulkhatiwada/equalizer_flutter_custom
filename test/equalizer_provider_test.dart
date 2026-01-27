import 'package:flutter_test/flutter_test.dart';
import 'package:equalizer_flutter_custom/src/EqalizerProvider/EqualizerProvider.dart';

void main() {
  test('dedupePresets removes duplicates while preserving order', () {
    final raw = ['Normal', 'Bass', 'Normal', 'Treble', 'Bass'];
    final deduped = EqualizerProvider.dedupePresets(raw);

    expect(deduped, equals(['Normal', 'Bass', 'Treble']));
  });

  test('dropdown value guards against missing preset', () {
    final presets = EqualizerProvider.dedupePresets(['Preset A', 'Preset B']);
    final currentp = 'Normal';
    final value = presets.contains(currentp) ? currentp : null;

    expect(value, isNull);
  });
}
