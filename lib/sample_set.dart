import 'dart:async';
import 'dart:collection';
import 'dart:math' as math;

import 'package:meta/meta.dart';

import 'src/graph_math.dart';

class SampleSet<T extends num> with IterableMixin<T> {
  final _controller = StreamController<Null>.broadcast();
  final List<T> _storage;
  StatData<T> _statCache;

  SampleSet({Iterable<T> source}) : _storage = List.from(source ?? <T>[]) {
    assert(_storage.every(validNum));
  }

  Stream<void> get onUpdate => _controller.stream;

  StatData<T> get data => _statCache ?? _updateThings();

  @override
  Iterator<T> get iterator => _storage.iterator;

  void addValue(T value) {
    assert(validNum(value));
    _storage.add(value);
    _updated();
  }

  void removeAt(int index) {
    _storage.removeAt(index);
    _updated();
  }

  void _updated() {
    _statCache = null;
    _controller.add(null);
  }

  StatData<T> _updateThings() {
    if (_storage.isEmpty) {
      return null;
    }

    _storage.sort();

    final count = _storage.length;

    final max = _storage.last;
    final min = _storage.first;

    final sum = _storage.fold(0, (num sum, next) => sum + next);

    final mean = sum / count;

    // variance
    // The average of the squared difference from the Mean

    num sumOfSquaredDiffFromMean = 0;
    for (var value in _storage) {
      final squareDiffFromMean = math.pow(value - mean, 2);
      sumOfSquaredDiffFromMean += squareDiffFromMean;
    }

    final variance = sumOfSquaredDiffFromMean / count;

    // standardDeviation: sqrt of the variance
    final standardDeviation = math.sqrt(variance);

    final median = _middleValue(0, count);
    num q1, q3;
    // Calculating q1 and q3 using "Method 2" as described
    // https://en.wikipedia.org/w/index.php?title=Quartile&oldid=872370666
    final middleIndex = _middleIndex(0, count);
    if (count % 2 == 1) {
      // include median value in q1/q2 calc
      q1 = _middleValue(0, middleIndex + 1);
      q3 = _middleValue(middleIndex, length - middleIndex);
    } else {
      // split in half for q1/q2
      q1 = _middleValue(0, middleIndex + 1);
      q3 = _middleValue(middleIndex + 1, length - (middleIndex + 1));
    }

    final iqr = q3 - q1;
    assert(iqr >= 0);
    final lowIrqCutoff = q1 - 1.5 * iqr;
    final lowest = _storage.firstWhere((v) => v >= lowIrqCutoff);

    final highIrqCutoff = q3 + 1.5 * iqr;
    final highest = _storage.lastWhere((v) => v <= highIrqCutoff);

    return StatData._(
      count: count,
      mean: mean,
      median: median,
      quartile1: q1,
      quartile3: q3,
      max: max,
      min: min,
      standardDeviation: standardDeviation,
      lowest: lowest,
      highest: highest,
    );
  }

  int _middleIndex(int startIndex, int length) =>
      startIndex + (length / 2 - 0.5).toInt();

  num _middleValue(int startIndex, int length) {
    if (length % 2 == 1) {
      return _storage[_middleIndex(startIndex, length)];
    } else {
      final middleB = startIndex + length ~/ 2;
      final middleA = middleB - 1;
      return (_storage[middleA] + _storage[middleB]) / 2.0;
    }
  }
}

StatData scaleStatsInRange(StatData data, num newLow, num newHigh) =>
    StatData._(
      count: data.count,
      min: scaleNumberInRange(data.min, data.min, data.max, newLow, newHigh),
      max: scaleNumberInRange(data.max, data.min, data.max, newLow, newHigh),
      lowest:
          scaleNumberInRange(data.lowest, data.min, data.max, newLow, newHigh),
      highest:
          scaleNumberInRange(data.highest, data.min, data.max, newLow, newHigh),
      median:
          scaleNumberInRange(data.median, data.min, data.max, newLow, newHigh),
      quartile1: scaleNumberInRange(
          data.quartile1, data.min, data.max, newLow, newHigh),
      quartile3: scaleNumberInRange(
          data.quartile3, data.min, data.max, newLow, newHigh),
      mean: scaleNumberInRange(data.mean, data.min, data.max, newLow, newHigh),
      standardDeviation: scaleNumberInRange(
          data.standardDeviation, 0, data.max - data.min, 0, newHigh - newLow),
    );

class StatData<T extends num> {
  final int count;
  final double mean;
  final num median;
  final T max;
  final T min;
  final num quartile1;
  final num quartile3;
  final double standardDeviation;
  final double standardError;
  final T lowest;
  final T highest;

  // TODO: horrible hack to handle equality and hashCode – should fix
  final String _toString;

  /// An alias for [median].
  num get quartile2 => median;

  StatData._({
    @required this.count,
    @required this.mean,
    @required this.quartile1,
    @required this.median,
    @required this.quartile3,
    @required this.max,
    @required this.min,
    @required this.standardDeviation,
    @required this.lowest,
    @required this.highest,
  })  : assert(count > 0),
        assert(orderedRange(min, median, max)),
        assert(orderedRange(min, mean, max)),
        assert(orderedRange(min, quartile1, median)),
        assert(orderedRange(median, quartile3, max)),
        assert(orderedRange(min, lowest, quartile1)),
        assert(orderedRange(quartile3, highest, max)),
        assert(standardDeviation >= 0),
        standardError = standardDeviation / math.sqrt(count),
        _toString = [
          count,
          mean,
          median,
          max,
          min,
          quartile1,
          quartile3,
          lowest,
          highest,
          standardDeviation,
        ].toString();

  @override
  int get hashCode => _toString.hashCode;

  @override
  bool operator ==(Object other) =>
      other is StatData && other._toString == _toString;
}
