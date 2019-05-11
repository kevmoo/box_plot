import 'dart:math' as math;

double scaleNumberInRange(num value, num min, num max, num newMin, num newMax) {
  assert(validNum(min));
  assert(validNum(max));
  assert(validNum(newMin));
  assert(validNum(newMax));
  assert(newMin <= newMax);

  assert(validNum(value));
  //assert(value >= low);
  //assert(value <= high);
  var pct = (value - min) / (max - min);
  if (pct.isNaN || pct.isInfinite) {
    pct = 0;
  }
  //assert(pct >= 0 && pct <= 1);
  return (newMin + pct * (newMax - newMin)).toDouble();
}

bool orderedRange(num first, num middle, num end) =>
    first <= middle && middle <= end;

bool validNum(num value) {
  if (value == null) {
    return false;
  }

  if (value is double) {
    return value.isFinite;
  }

  return true;
}

List<double> getLines(num min, num max) {
  assert(max >= min);

  if (min == max) {
    if (min == 0) {
      return [0, 50, 100];
    }

    if (min < 0) {
      max = 0;
    } else {
      min = 0;
    }
  }

  final range = max - min;
  final theLog = math.log(range) * math.log10e;

  final multiplier = math.pow(10, theLog.round());
  assert(multiplier >= 0);

  final minCoefficient = (min / multiplier).floorToDouble();
  final maxCoefficient = (max / multiplier).ceilToDouble();

  /*
  print({
    'multiplier': multiplier,
    'min': min,
    'max': max,
    'minCoefficient': minCoefficient,
    'maxCoefficient': maxCoefficient
  }.entries.join('\n'));
  */

  var minLine = minCoefficient * multiplier;
  var maxLine = maxCoefficient * multiplier;

  if (minLine < 0 && maxLine > 0) {
    assert(minLine <= min);
    assert(maxLine >= max);

    // shrink the span by 2x if it's more than 2x too big
    while (minLine / 2 < min && maxLine / 2 > max) {
      // TOOD: eh...not sure this is what we want here...
      minLine = minLine / 2;
      maxLine = maxLine / 2;
    }

    return [minLine, 0, maxLine];
  }

  return [minLine, maxLine];
}
