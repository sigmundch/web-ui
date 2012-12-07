library main;

import 'dart:html';
import 'package:web_ui/watcher.dart';
import 'common.dart';

main() {
  topLevelVar = "hello";
  dispatch();
  window.setTimeout(() => window.postMessage('done', '*'), 0);
}

