import 'sample_set.dart';
import 'src/graph_helper.dart';
import 'src/graph_math.dart';

class BoxPlotHelper extends GraphHelper<StatData> {
  BoxPlotHelper()
      : super([
          GraphHelperValueItem('min', (sd) => sd.min.toDouble()),
          GraphHelperValueItem('max', (sd) => sd.max.toDouble()),
          AnimatedGraphHelperValueItem('median', (sd) => sd.median.toDouble()),
          AnimatedGraphHelperValueItem(
              'quartile1', (sd) => sd.quartile1.toDouble()),
          AnimatedGraphHelperValueItem(
              'quartile3', (sd) => sd.quartile3.toDouble()),
          AnimatedGraphHelperValueItem('lowest', (sd) => sd.lowest.toDouble()),
          AnimatedGraphHelperValueItem(
              'highest', (sd) => sd.highest.toDouble()),
          GraphHelperValueIterable('lines', (sd) => getLines(sd.min, sd.max)),
        ]);

  MappedValue get min => getMappedValue('min');

  MappedValue get max => getMappedValue('max');

  AnimatedMappedValue get median => getAnimatedMappedValue('median');

  AnimatedMappedValue get quartile1 => getAnimatedMappedValue('quartile1');

  AnimatedMappedValue get quartile3 => getAnimatedMappedValue('quartile3');

  AnimatedMappedValue get lowest => getAnimatedMappedValue('lowest');

  AnimatedMappedValue get highest => getAnimatedMappedValue('highest');

  Iterable<MappedValue> get lines => getMappedIterableValue('lines');
}
