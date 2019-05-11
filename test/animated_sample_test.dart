import 'package:box_plot/box_plot_helper.dart';
import 'package:box_plot/sample_set.dart';
import 'package:box_plot/src/range_mapping.dart';
import 'package:test/test.dart';

void main() {
  group('RangeMapping', () {
    test('example 1', () {
      final map = RangeMapping(
          sourceLow: -10, sourceHigh: 10, topScreenRow: 5, bottomScreenRow: 95);

      final expected = <num, num>{
        -10: 95,
        0: 50,
        10: 5,
      };

      final actual = Map<num, num>.fromEntries(
          expected.keys.map((n) => MapEntry(n, map.scaleAndFlip(n))));

      expect(actual, expected);
    });

    test('example 2', () {
      final map = RangeMapping(
          sourceLow: -10,
          sourceHigh: 10,
          topScreenRow: -7,
          bottomScreenRow: 105);

      final expected = <num, num>{
        -10: 105,
        0: 49,
        10: -7,
      };

      final actual = Map<num, num>.fromEntries(
          expected.keys.map((n) => MapEntry(n, map.scaleAndFlip(n))));

      expect(actual, expected);
    });
  });

  test('BoxPlotSilly', () {
    final silly = BoxPlotHelper();

    expect(silly.min, null);
    expect(silly.max, null);

    final data = SampleSet(source: [1, 2, 3]).data;

    silly.data = data;

    expect(silly.min.source, 1);
    expect(silly.max.source, 3);
    expect(silly.min.mapped, null);
    expect(silly.max.mapped, null);

    silly.setRangeMapping(RangeMapping(
      sourceLow: -10,
      sourceHigh: 10,
      topScreenRow: 0,
      bottomScreenRow: 100,
    ));

    expect(silly.min.mapped, closeTo(45, 0.0001));
    expect(silly.max.mapped, 35);
  });
}
