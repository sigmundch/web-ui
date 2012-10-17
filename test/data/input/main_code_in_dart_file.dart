library main;

import 'dart:html';
import 'package:web_components/watcher.dart';
import '../input/common.dart';

main() {
  topLevelVar = "hello";
  dispatch();
  window.setTimeout(() => window.postMessage('done', '*'), 0);
}

