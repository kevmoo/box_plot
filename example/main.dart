import 'package:box_plot/app_widget.dart';
import 'package:flutter_web/material.dart';
import 'package:flutter_web_ui/ui.dart' as ui;

Future main() async {
  await ui.webOnlyInitializePlatform();
  runApp(AppWidget());
}
