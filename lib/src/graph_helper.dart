import 'package:meta/meta.dart';

import 'body.dart';
import 'graph_math.dart';
import 'range_mapping.dart';

abstract class GraphHelperValue<InputDataType, ReturnDataType> {
  final String name;
  GraphHelper<InputDataType> _parent;

  GraphHelperValue(this.name) : assert(name != null && name.isNotEmpty);

  ReturnDataType getMappedValue();
}

class MappedValue {
  final double source, mapped;

  MappedValue(this.source, this.mapped)
      : assert(validNum(source)),
        assert(mapped == null || validNum(mapped));

  @override
  String toString() => '$source ($mapped)';
}

class AnimatedMappedValue extends MappedValue {
  final double animated;

  AnimatedMappedValue(double source, double mapped, this.animated)
      : assert(animated == null || validNum(mapped)),
        super(source, mapped);

  @override
  String toString() => '$source ($mapped)';
}

class GraphHelperValueItem<T> extends GraphHelperValue<T, MappedValue> {
  final double Function(T) _getValue;

  GraphHelperValueItem(String name, this._getValue) : super(name);

  @override
  MappedValue getMappedValue() {
    if (_parent.data == null) {
      return null;
    }

    final source = _getValue(_parent.data);

    final mappedValue = _parent._rangeMapping == null
        ? null
        : _parent._rangeMapping.scaleAndFlip(source);

    return MappedValue(source, mappedValue);
  }
}

class AnimatedGraphHelperValueItem<T> extends GraphHelperValueItem<T> {
  Body _body;

  AnimatedGraphHelperValueItem(String name, double Function(T) getValue)
      : super(name, getValue);

  @override
  AnimatedMappedValue getMappedValue() {
    final superValue = super.getMappedValue();

    return AnimatedMappedValue(superValue.source, superValue.mapped,
        _body?.location ?? superValue.mapped);
  }

  /// Returns `true` if there has been a change
  bool _update(Duration sinceLastFrame) {
    final superMappedValue = super.getMappedValue()?.mapped;

    if (superMappedValue == null) {
      if (_body != null) {
        _body = null;
        return true;
      }
      return false;
    }

    _body ??= Body(location: superMappedValue);

    var animationSeconds = sinceLastFrame.inMilliseconds / 60.0;
    if (animationSeconds == 0) {
      animationSeconds = 0.1;
    }
    assert(animationSeconds > 0);

    return _body.animate(animationSeconds,
        force: superMappedValue - _body.location,
        drag: .9,
        maxVelocity: 100,
        snapTo: superMappedValue);
  }
}

class GraphHelperValueIterable<T>
    extends GraphHelperValue<T, Iterable<MappedValue>> {
  final Iterable<double> Function(T) _getValue;

  GraphHelperValueIterable(String name, this._getValue) : super(name);

  @override
  Iterable<MappedValue> getMappedValue() {
    if (_parent.data == null) {
      return const [];
    }

    final source = _getValue(_parent.data);
    return source
        .map((v) => MappedValue(v, _parent._rangeMapping.scaleAndFlip(v)));
  }
}

// takes a set of numbers to be plotted and
// 1 - helps map them to the pixel space we will render to
// 2 - helps animate the values smoothly using – tricks
abstract class GraphHelper<T> {
  T _data;
  bool _dirty = false;

  RangeMapping _rangeMapping;

  final Map<String, GraphHelperValue<T, dynamic>> _valueItems;

  static Map<String, GraphHelperValue<T, dynamic>> _work<T>(
      Iterable<GraphHelperValue<T, dynamic>> items) {
    final value = <String, GraphHelperValue<T, dynamic>>{};

    for (var item in items) {
      assert(!value.containsKey(item.name));
      value[item.name] = item;
    }

    return value;
  }

  GraphHelper(Iterable<GraphHelperValue<T, dynamic>> items)
      : _valueItems = _work(items) {
    for (var item in _valueItems.values) {
      item._parent = this;
    }
  }

  RangeMapping get rangeMapping => _rangeMapping;

  void setRangeMapping(RangeMapping value, {bool resetAnimations = false}) {
    resetAnimations ??= false;

    if (value != _rangeMapping) {
      if (resetAnimations) {
        for (var item in _animatedItems) {
          item._body = null;
        }
      }

      _dirty = true;
    }
    _rangeMapping = value;
  }

  T get data => _data;

  set data(T value) {
    if (value != _data && !_dirty) {
      _dirty = true;
    }
    _data = value;
  }

  /// Returns `true` if the  model was updated during the call.
  bool update(Duration sinceLastUpdate) {
    var updated = _dirty;

    for (var animated in _animatedItems) {
      updated = animated._update(sinceLastUpdate) || updated;
    }

    _dirty = false;
    return updated;
  }

  Iterable<AnimatedGraphHelperValueItem> get _animatedItems =>
      _valueItems.values.whereType<AnimatedGraphHelperValueItem>();

  @protected
  MappedValue getMappedValue(String key) =>
      (_valueItems[key] as GraphHelperValueItem<T>).getMappedValue();

  @protected
  AnimatedMappedValue getAnimatedMappedValue(String key) =>
      (_valueItems[key] as AnimatedGraphHelperValueItem<T>).getMappedValue();

  @protected
  Iterable<MappedValue> getMappedIterableValue(String key) =>
      (_valueItems[key] as GraphHelperValueIterable<T>).getMappedValue();
}
