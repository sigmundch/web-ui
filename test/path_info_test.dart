// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * Tests for [PathInfo]. All other info types are produced by the analyzer and
 * tested in analyzer test.
 */
library path_info_test;

import 'package:pathos/path.dart' as path;
import 'package:unittest/compact_vm_config.dart';
import 'package:unittest/unittest.dart';
import 'package:web_ui/src/info.dart';
import 'testing.dart';


main() {
  useCompactVMConfiguration();
  group('outdir == basedir:', () {
    group('outputPath', () {
      test('mangle automatic', () {
        var paths = _newPathInfo('a', 'a', false);
        var file = _mockFile('a/b.dart', paths);
        expect(file.dartCodePath, 'a/b.dart');
        expect(paths.outputPath(file.dartCodePath, '.dart').toString(),
            'a/_b.dart.dart');
      });

      test('within packages/', () {
        var paths = _newPathInfo('a', 'a', false);
        var file = _mockFile('a/packages/b.dart', paths);
        expect(file.dartCodePath, 'a/packages/b.dart');
        expect(paths.outputPath(file.dartCodePath, '.dart').toString(),
            'a/_from_packages/_b.dart.dart');
      });
    });

    group('relativePath', () {
      test('simple paths', () {
        var paths = _newPathInfo('a', 'a', false);
        var file1 = _mockFile('a/b.dart', paths);
        var file2 = _mockFile('a/c/d.dart', paths);
        var file3 = _mockFile('a/e/f.dart', paths);
        expect(paths.relativePath(file1, file2).toString(), 'c/_d.dart.dart');
        expect(paths.relativePath(file1, file3).toString(), 'e/_f.dart.dart');
        expect(paths.relativePath(file2, file1).toString(), '../_b.dart.dart');
        expect(paths.relativePath(file2, file3).toString(),
            '../e/_f.dart.dart');
        expect(paths.relativePath(file3, file2).toString(),
            '../c/_d.dart.dart');
        expect(paths.relativePath(file3, file1).toString(), '../_b.dart.dart');
      });

      test('include packages/', () {
        var paths = _newPathInfo('a', 'a', false);
        var file1 = _mockFile('a/b.dart', paths);
        var file2 = _mockFile('a/c/d.dart', paths);
        var file3 = _mockFile('a/packages/f.dart', paths);
        expect(paths.relativePath(file1, file2).toString(), 'c/_d.dart.dart');
        expect(paths.relativePath(file1, file3).toString(),
            '_from_packages/_f.dart.dart');
        expect(paths.relativePath(file2, file1).toString(), '../_b.dart.dart');
        expect(paths.relativePath(file2, file3).toString(),
            '../_from_packages/_f.dart.dart');
        expect(paths.relativePath(file3, file2).toString(),
            '../c/_d.dart.dart');
        expect(paths.relativePath(file3, file1).toString(), '../_b.dart.dart');
      });
    });

    test('transformUrl simple paths', () {
      var paths = _newPathInfo('a', 'a', false);
      var file1 = 'a/b.dart';
      var file2 = 'a/c/d.html';
      // when the output == input directory, no paths should be rewritten
      expect(paths.transformUrl(file1, '/a.dart'), '/a.dart');
      expect(paths.transformUrl(file1, 'c.dart'), 'c.dart');
      expect(paths.transformUrl(file1, '../c/d.dart'), '../c/d.dart');
      expect(paths.transformUrl(file1, 'packages/c.dart'), 'packages/c.dart');
      expect(paths.transformUrl(file2, 'e.css'), 'e.css');
      expect(paths.transformUrl(file2, '../c/e.css'), 'e.css');
      expect(paths.transformUrl(file2, '../q/e.css'), '../q/e.css');
      expect(paths.transformUrl(file2, 'packages/c.css'), 'packages/c.css');
      expect(paths.transformUrl(file2, '../packages/c.css'),
          '../packages/c.css');
    });

    test('transformUrl with source in packages/', () {
      var paths = _newPathInfo('a', 'a', false);
      var file = 'a/packages/e.html';
      // Even when output == base, files under packages/ are moved to
      // _from_packages, so all imports are affected:
      expect(paths.transformUrl(file, 'e.css'), '../packages/e.css');
      expect(paths.transformUrl(file, '../packages/e.css'),
          '../packages/e.css');
      expect(paths.transformUrl(file, '../q/e.css'), '../q/e.css');
      expect(paths.transformUrl(file, 'packages/c.css'),
          '../packages/packages/c.css');
    });
  });

  group('outdir != basedir:', () {
    group('outputPath', (){
      test('no force mangle', () {
        var paths = _newPathInfo('a', 'out', false);
        var file = _mockFile('a/b.dart', paths);
        expect(file.dartCodePath, 'a/b.dart');
        expect(paths.outputPath(file.dartCodePath, '.dart').toString(),
            'out/b.dart');
      });

      test('force mangling', () {
        var paths = _newPathInfo('a', 'out', true);
        var file = _mockFile('a/b.dart', paths);
        expect(file.dartCodePath, 'a/b.dart');
        expect(paths.outputPath(file.dartCodePath, '.dart').toString(),
            'out/_b.dart.dart');
      });

      test('within packages/, no mangle', () {
        var paths = _newPathInfo('a', 'out', false);
        var file = _mockFile('a/packages/b.dart', paths);
        expect(file.dartCodePath, 'a/packages/b.dart');
        expect(paths.outputPath(file.dartCodePath, '.dart').toString(),
            'out/_from_packages/b.dart');
      });

      test('within packages/, mangle', () {
        var paths = _newPathInfo('a', 'out', true);
        var file = _mockFile('a/packages/b.dart', paths);
        expect(file.dartCodePath, 'a/packages/b.dart');
        expect(paths.outputPath(file.dartCodePath, '.dart').toString(),
            'out/_from_packages/_b.dart.dart');
      });
    });

    group('relativePath', (){
      test('simple paths, no mangle', () {
        var paths = _newPathInfo('a', 'out', false);
        var file1 = _mockFile('a/b.dart', paths);
        var file2 = _mockFile('a/c/d.dart', paths);
        var file3 = _mockFile('a/e/f.dart', paths);
        expect(paths.relativePath(file1, file2).toString(), 'c/d.dart');
        expect(paths.relativePath(file1, file3).toString(), 'e/f.dart');
        expect(paths.relativePath(file2, file1).toString(), '../b.dart');
        expect(paths.relativePath(file2, file3).toString(), '../e/f.dart');
        expect(paths.relativePath(file3, file2).toString(), '../c/d.dart');
        expect(paths.relativePath(file3, file1).toString(), '../b.dart');
      });

      test('simple paths, mangle', () {
        var paths = _newPathInfo('a', 'out', true);
        var file1 = _mockFile('a/b.dart', paths);
        var file2 = _mockFile('a/c/d.dart', paths);
        var file3 = _mockFile('a/e/f.dart', paths);
        expect(paths.relativePath(file1, file2).toString(), 'c/_d.dart.dart');
        expect(paths.relativePath(file1, file3).toString(), 'e/_f.dart.dart');
        expect(paths.relativePath(file2, file1).toString(), '../_b.dart.dart');
        expect(paths.relativePath(file2, file3).toString(),
            '../e/_f.dart.dart');
        expect(paths.relativePath(file3, file2).toString(),
            '../c/_d.dart.dart');
        expect(paths.relativePath(file3, file1).toString(), '../_b.dart.dart');
      });

      test('include packages/, no mangle', () {
        var paths = _newPathInfo('a', 'out', false);
        var file1 = _mockFile('a/b.dart', paths);
        var file2 = _mockFile('a/c/d.dart', paths);
        var file3 = _mockFile('a/packages/f.dart', paths);
        expect(paths.relativePath(file1, file2).toString(), 'c/d.dart');
        expect(paths.relativePath(file1, file3).toString(),
            '_from_packages/f.dart');
        expect(paths.relativePath(file2, file1).toString(), '../b.dart');
        expect(paths.relativePath(file2, file3).toString(),
            '../_from_packages/f.dart');
        expect(paths.relativePath(file3, file2).toString(), '../c/d.dart');
        expect(paths.relativePath(file3, file1).toString(), '../b.dart');
      });

      test('include packages/, mangle', () {
        var paths = _newPathInfo('a', 'out', true);
        var file1 = _mockFile('a/b.dart', paths);
        var file2 = _mockFile('a/c/d.dart', paths);
        var file3 = _mockFile('a/packages/f.dart', paths);
        expect(paths.relativePath(file1, file2).toString(), 'c/_d.dart.dart');
        expect(paths.relativePath(file1, file3).toString(),
            '_from_packages/_f.dart.dart');
        expect(paths.relativePath(file2, file1).toString(), '../_b.dart.dart');
        expect(paths.relativePath(file2, file3).toString(),
            '../_from_packages/_f.dart.dart');
        expect(paths.relativePath(file3, file2).toString(),
            '../c/_d.dart.dart');
        expect(paths.relativePath(file3, file1).toString(), '../_b.dart.dart');
      });
    });

    group('transformUrl', () {
      test('simple source, not in packages/', () {
        var paths = _newPathInfo('a', 'out', false);
        var file1 = 'a/b.dart';
        var file2 = 'a/c/d.html';
        // when the output == input directory, no paths should be rewritten
        expect(paths.transformUrl(file1, '/a.dart'), '/a.dart');
        expect(paths.transformUrl(file1, 'c.dart'), '../a/c.dart');

        // reach out from basedir:
        expect(paths.transformUrl(file1, '../c/d.dart'), '../c/d.dart');

        // reach into packages dir:
        expect(paths.transformUrl(file1, 'packages/c.dart'),
            '../a/packages/c.dart');

        expect(paths.transformUrl(file2, 'e.css'), '../../a/c/e.css');

        _checkPath('../../a/c/../c/e.css', '../../a/c/e.css');
        expect(paths.transformUrl(file2, '../c/e.css'), '../../a/c/e.css');

        _checkPath('../../a/c/../q/e.css', '../../a/q/e.css');
        expect(paths.transformUrl(file2, '../q/e.css'), '../../a/q/e.css');

        expect(paths.transformUrl(file2, 'packages/c.css'),
            '../../a/c/packages/c.css');
        _checkPath('../../a/c/../packages/c.css', '../../a/packages/c.css');
        expect(paths.transformUrl(file2, '../packages/c.css'),
            '../../a/packages/c.css');
      });

      test('input in packages/', () {
        var paths = _newPathInfo('a', 'out', true);
        var file = 'a/packages/e.html';
        expect(paths.transformUrl(file, 'e.css'), '../../a/packages/e.css');
        expect(paths.transformUrl(file, '../packages/e.css'),
            '../../a/packages/e.css');
        expect(paths.transformUrl(file, '../q/e.css'), '../../a/q/e.css');
        expect(paths.transformUrl(file, 'packages/c.css'),
            '../../a/packages/packages/c.css');
      });
    });
  });
}

_newPathInfo(String baseDir, String outDir, bool forceMangle) =>
    new PathInfo(baseDir, outDir, 'packages', forceMangle);

_mockFile(String filePath, PathInfo paths) {
  var file = new FileInfo(filePath);
  file.outputFilename = paths.mangle(path.basename(filePath), '.dart', false);
  return file;
}

_checkPath(String filePath, String expected) {
  expect(path.normalize(filePath), expected);
}
