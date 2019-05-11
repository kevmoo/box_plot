import 'package:meta/meta.dart';

import 'graph_math.dart';

class RangeMapping {
  final double sourceLow, sourceHigh, topScreenRow, bottomScreenRow;

  // TODO: horrible hack to handle equality and hashCode – should fix
  final String _toString;

  RangeMapping({
    @required this.sourceLow,
    @required this.sourceHigh,
    @required this.topScreenRow,
    @required this.bottomScreenRow,
  }) : _toString =
            [sourceLow, sourceHigh, topScreenRow, bottomScreenRow].toString() {
    assert(validNum(sourceLow));
    assert(validNum(sourceHigh));
    assert(validNum(topScreenRow));
    assert(validNum(bottomScreenRow));
  }

  /// Scales [input] and flips the value for screens – where the Y axis
  /// increases as you go down.
  double scaleAndFlip(num input) =>
      (topScreenRow + bottomScreenRow) -
      scaleNumberInRange(
          input, sourceLow, sourceHigh, topScreenRow, bottomScreenRow);

  @override
  int get hashCode => _toString.hashCode;

  @override
  bool operator ==(Object other) =>
      other is RangeMapping && _toString == other._toString;

  @override
  String toString() => _toString;
}
