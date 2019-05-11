import 'package:box_plot/sample_set.dart';
import 'package:box_plot/src/graph_math.dart';
import 'package:test/test.dart';

void main() {
  group('graph scale', () {
    // sheets values - some day
    /*
    final inputs = const {
      [0, 1]: [0, .25, .5, .75, 1],
      [0, 8]: [0, 2, 4, 6, 8],
      [0, 9]: [0, 2, 4, 6, 8, 10],
      [0, 10]: [0, 2, 4, 6, 8, 10],
      [-10, 10]: [-10, -5, 0, 5, 10],
      [-10, 11]: [-10, -5, 0, 5, 10, 15]
    };
    */

    final inputs = const {
      [0, 0]: [0, 50, 100],
      [1, 1]: [0, 1],
      [0, 8]: [0, 10],
      [0, 9]: [0, 10],
      [0, 10]: [0, 10],
      [0, 11]: [0, 20],
      [0, 30]: [0, 30],
      [0, 50]: [0, 100],
      [0, 90]: [0, 100],
      [0, 100]: [0, 100],
      [-8, -8]: [-10, 0],
      [0.1, 0.11]: [0.1, 0.11],
      [0, 1]: [0, 1],
      [-10, 10]: [-10, 0, 10],
      [-10, 11]: [-10, 0, 20],
      [60, 70]: [60, 70],
      [60, 61]: [60, 61],
      [61, 62]: [61, 62],
      [-300, 300]: [-500, 0, 500],
      [39, 189]: [0, 200],
    };

    for (var value in inputs.entries) {
      assert(value.key.length == 2);
      final low = value.key[0];
      final high = value.key[1];
      assert(low <= high);
      test('$low to $high', () {
        final result = getLines(low, high);
        expect(result, value.value);
      });
    }
  });

  group('SampleSet', () {
    void checkValues(StatData data) {
      expect(data.max, 3);
      expect(data.min, 1);
      expect(data.count, 3);
      expect(data.median, 2);
      expect(data.mean, 2);
      expect(data.standardDeviation, closeTo(0.82, 0.01));
      expect(data.standardError, closeTo(0.4714, 0.01));
    }

    test('simple', () {
      final data = SampleSet(source: [1, 2, 3]).data;
      checkValues(data);
    });

    test('scaled', () {
      final data = SampleSet(source: [20, 30, 40]).data;

      final scaled = scaleStatsInRange(data, 1, 3);
      checkValues(scaled);
    });

    group('wikipedia', () {
      // values from https://en.wikipedia.org/w/index.php?title=Quartile&oldid=872370666

      test('example 1', () {
        final data =
            SampleSet(source: [6, 7, 15, 36, 39, 40, 41, 42, 43, 47, 49]).data;
        expect(data.quartile1, 25.5);
        expect(data.median, 40);
        expect(data.quartile3, 42.5);
      });

      test('example 2', () {
        final data = SampleSet(source: [7, 15, 36, 39, 40, 41]).data;

        expect(data.quartile1, 15);
        expect(data.median, 37.5);
        expect(data.quartile3, 40);
      });
    });

    test('even quartiles', () {
      // In this case, there is an exact value for q1, q2, q3
      final data = SampleSet(source: [6, 7, 15, 36, 39, 40, 41, 42, 43]).data;
      expect(data.quartile1, 15);
      expect(data.median, 39);
      expect(data.quartile3, 41);
    });
  });

  test('scale number in range', () {
    expect(scaleNumberInRange(0, 0, 10, 0, 10), 0);
    expect(scaleNumberInRange(5, 0, 10, 0, 10), 5);
    expect(scaleNumberInRange(10, 0, 10, 0, 10), 10);

    expect(scaleNumberInRange(0, 0, 10, 20, 30), 20);
    expect(scaleNumberInRange(5, 0, 10, 20, 30), 25);
    expect(scaleNumberInRange(10, 0, 10, 20, 30), 30);

    expect(scaleNumberInRange(0, 0, 10, -30, 30), -30);
    expect(scaleNumberInRange(5, 0, 10, -30, 30), 0);
    expect(scaleNumberInRange(10, 0, 10, -30, 30), 30);
  });
}
