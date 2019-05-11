// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter_web/material.dart' hide TextStyle;
import 'package:flutter_web_ui/ui.dart';
import 'package:meta/meta.dart';

import 'box_plot_helper.dart';
import 'sample_set.dart';
import 'src/graph_math.dart';
import 'src/range_mapping.dart';

const _maxFrameDuration = Duration(milliseconds: 34);

class BoxPlotBar extends StatefulWidget {
  final SampleSet sampleSet;

  BoxPlotBar({@required this.sampleSet});

  @override
  _BoxPlotBarState createState() => _BoxPlotBarState();
}

class _BoxPlotBarState extends State<BoxPlotBar> with TickerProviderStateMixin {
  final _fillColor = Colors.blue;
  final _notifier = ValueNotifier<int>(0);

  _CustomPainter _painter;
  Ticker _ticker;
  Duration _lastElapsed;
  StreamSubscription _dataUpdateSub;

  @override
  void initState() {
    super.initState();
    _ticker ??= createTicker(_onTick);
    _ensureTicking();

    _painter = _CustomPainter(this);

    _dataUpdateSub = widget.sampleSet.onUpdate.listen((_) {
      _ensureTicking();
    });
  }

  void _ensureTicking() {
    if (!_ticker.isTicking) {
      _ticker.start();
    }
  }

  void _onTick(Duration elapsed) {
    if (elapsed == Duration.zero) {
      _lastElapsed = elapsed;
    }
    final delta = elapsed - _lastElapsed;
    _lastElapsed = elapsed;

    if (delta.inMilliseconds <= 0) {
      // `_delta` may be negative or zero if `elapsed` is zero (first tick)
      // or during a restart. Just ignore this case.
      return;
    }

    _painter.update(delta > _maxFrameDuration ? _maxFrameDuration : delta);

    if (!_painter.stable) {
      _notifier.value++;
    } else {
      _ticker.stop();
      _lastElapsed = null;
    }
  }

  @override
  Widget build(BuildContext context) => CustomPaint(painter: _painter);

  @override
  void dispose() {
    _ticker.dispose();
    _dataUpdateSub.cancel();
    super.dispose();
  }
}

class _CustomPainter extends CustomPainter {
  final _BoxPlotBarState _parent;
  bool _stable = false;
  bool _updated = false;
  int _lastPaintCount = 0;

  final _helper = BoxPlotHelper();

  static final _blackPaint = _linePaint(Colors.black);

  static Paint _linePaint(Color color) => Paint()
    ..color = color
    ..strokeWidth = 2
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.square;

  static final _grayBackgroundPaint = Paint()
    ..color = const Color.fromARGB(255, 250, 250, 250);

  static final _gridLinePaint = Paint()
    ..color = const Color.fromARGB(15, 0, 0, 0);

  SampleSet get _sampleSet => _parent.widget.sampleSet;

  void update(Duration duration) {
    _helper.data = _sampleSet.data;
    _updated = _helper.update(duration);
    if (_updated && _stable) {
      _stable = false;
    }
  }

  bool get stable => _stable;

  _CustomPainter(this._parent) : super(repaint: _parent._notifier);

  @override
  void paint(Canvas canvas, Size size) {
    final data = _helper.data;

    canvas.drawRect(
      Rect.fromLTRB(0, 0, size.width, size.height),
      _grayBackgroundPaint,
    );

    if (data == null) {
      _lastPaintCount = 0;
      final pb = ParagraphBuilder(ParagraphStyle())..addText('??');
      canvas.drawParagraph(
          pb.build()..layout(const ParagraphConstraints(width: 30)),
          Offset(size.width / 2, size.height / 2));
    } else {
      final lineValues = getLines(data.min, data.max);
      assert(lineValues.first <= lineValues.last);

      _helper.setRangeMapping(
          RangeMapping(
            sourceLow: lineValues.first,
            sourceHigh: lineValues.last,
            topScreenRow: 8,
            bottomScreenRow: size.height - 8,
          ),
          resetAnimations: _lastPaintCount == 0 && data.count > 0);

      _lastPaintCount = data.count;

      for (var thing in _helper.lines) {
        final text = thing.source.toInt().toString();
        final pb = ParagraphBuilder(ParagraphStyle(textAlign: TextAlign.right))
          ..pushStyle(TextStyle(color: Colors.black))
          ..addText(text);

        canvas
          ..drawParagraph(
              pb.build()..layout(const ParagraphConstraints(width: 30)),
              Offset(5, thing.mapped - 8))
          ..drawLine(Offset(40, thing.mapped), Offset(size.width, thing.mapped),
              _gridLinePaint);
      }

      final middleX = size.width / 2;

      final quarterLeft = middleX - 20;
      final quarterRight = middleX + 20;

      final boxRect = Rect.fromPoints(
        Offset(quarterLeft, _helper.quartile3.animated),
        Offset(quarterRight, _helper.quartile1.animated),
      );

      canvas
        // quartile box
        ..drawRect(
          boxRect,
          Paint()..color = _parent._fillColor,
        )
        ..drawRect(
          boxRect,
          _blackPaint,
        )
        ..drawLine(
          Offset(quarterLeft, _helper.median.animated),
          Offset(quarterRight, _helper.median.animated),
          _blackPaint,
        )

        // Top line
        ..drawLine(
          Offset(middleX, _helper.lowest.animated),
          Offset(quarterRight, _helper.lowest.animated),
          _blackPaint,
        )
        ..drawLine(
          Offset(quarterRight, _helper.lowest.animated),
          Offset(quarterRight, _helper.quartile1.animated),
          _blackPaint,
        )

        // Bottom line
        ..drawLine(
          Offset(middleX, _helper.highest.animated),
          Offset(quarterRight, _helper.highest.animated),
          _blackPaint,
        )
        ..drawLine(
          Offset(quarterRight, _helper.quartile3.animated),
          Offset(quarterRight, _helper.highest.animated),
          _blackPaint,
        );

      final parentFillPaint = Paint()
        ..color = _parent._fillColor.withOpacity(0.4)
        ..strokeWidth = 3;

      final outRangePaint = Paint()
        ..color = Colors.red.withOpacity(parentFillPaint.color.opacity)
        ..strokeWidth = parentFillPaint.strokeWidth;

      for (var value in _sampleSet) {
        var paint = parentFillPaint;

        if (value < data.lowest || value > data.highest) {
          paint = outRangePaint;
        }

        final paintLocation = _helper.rangeMapping.scaleAndFlip(value);

        canvas.drawLine(
          Offset(quarterRight + 10, paintLocation),
          Offset(quarterRight + 20, paintLocation),
          paint,
        );
      }
    }
    if (!_updated && !_stable) {
      _stable = true;
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    // TODO: maybe not always true?
    return true;
  }
}
