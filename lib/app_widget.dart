// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
import 'dart:async';
import 'dart:math' as math;

import 'package:box_plot/box_plot.dart';
import 'package:box_plot/sample_set.dart';
import 'package:flutter_web/material.dart';

final _autoAdd = false;

class AppWidget extends StatefulWidget {
  final data = SampleSet<num>(source: <num>[9, 21]);

  @override
  State<StatefulWidget> createState() => _AppWidgetState();
}

enum Flavor { high, low, random }

class _AppWidgetState extends State<AppWidget> {
  SampleSet<num> get _data => widget.data;

  Timer _timer;

  @override
  void initState() {
    super.initState();

    if (_autoAdd) {
      var adding = true;

      _timer = Timer.periodic(const Duration(milliseconds: 250), (_) {
        _change(adding, Flavor.random);

        if (_data.length > 15) {
          adding = false;
        } else if (_data.isEmpty) {
          adding = true;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) => Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: Column(
            verticalDirection: VerticalDirection.down,
            textDirection: TextDirection.ltr,
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(
                  minHeight: 500,
                  minWidth: 500,
                  maxHeight: 800,
                  maxWidth: 800,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: BoxPlotBar(
                    sampleSet: _data,
                  ),
                ),
              ),
              _buttons(),
            ],
          ),
        ),
      );

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _change(bool add, Flavor flavor) {
    num newValue(Flavor flavor) {
      switch (flavor) {
        case Flavor.random:
          return _nextRandom();
        case Flavor.high:
          if (_data.isEmpty) {
            return 0;
          }
          return _data.last + 1;
        case Flavor.low:
          if (_data.isEmpty) {
            return 0;
          }
          return _data.first - 1;
      }
      throw FallThroughError();
    }

    int removeIndex(Flavor flavor) {
      switch (flavor) {
        case Flavor.random:
          return _rnd.nextInt(_data.length);
        case Flavor.high:
          return _data.length - 1;
        case Flavor.low:
          return 0;
      }
      throw FallThroughError();
    }

    setState(() {
      if (add) {
        _data.addValue(newValue(flavor));
      } else {
        final index = removeIndex(flavor);
        if (index != null) {
          _data.removeAt(index);
        }
      }
    });
  }

  Table _buttons() {
    Widget create(Flavor value, bool add) {
      final name = value.toString().split('.')[1];
      return Padding(
          padding: const EdgeInsets.all(5),
          child: FlatButton(
              onPressed:
                  (!add && _data.isEmpty) ? null : () => _change(add, value),
              child: Text('${add ? "add" : "remove"} $name'),
              color: Colors.black26,
              disabledColor: Colors.black12));
    }

    return Table(
      defaultColumnWidth: const FixedColumnWidth(150),
      children: [
        TableRow(children: Flavor.values.map((v) => create(v, true)).toList()),
        TableRow(children: Flavor.values.map((v) => create(v, false)).toList()),
      ],
    );
  }

  final _rnd = math.Random();

  num _nextRandom() =>
      100 *
      math.cos(2 * math.pi * _rnd.nextDouble()) *
      math.sqrt(-2 * math.log(_rnd.nextDouble()));
}
