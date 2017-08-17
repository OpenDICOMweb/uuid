// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Author: Jim Philbin <jfphilbin@gmail.edu>
// See the AUTHORS file for other contributors.

import 'package:system/system.dart';
import "package:test/test.dart";

import 'package:uuid/uuid_test.dart';

void main() {

  System.log.level = Level.debug2;

  group('Version 4 Tests', () {
    test('Check if V4 is consistent using a static seed', () {
      var uuid0 = new Uuid();
      var data0 = uuid0.data;
      //  log.debug('u0: $u0');
      var data1 = [
        164, 98, 80, 42, 115, 175, 67, 65,
        191, 196, 5, 149, 123, 112, 48, 221 // No reformat
      ];
      expect(data0.length, equals(16));
      expect(data1.length, equals(16));
      expect(data0, equals(data1));
    });

    test('Test Uuid.fromBytes', () {
      const List<int> data0 = const <int>[
        0x10, 0x91, 0x56, 0xbe, 0xc4, 0xfb, 0xc1, 0xea,
        0x71, 0xb4, 0xef, 0xe1, 0x67, 0x1c, 0x58, 0x36 // No Reformat
      ];
      const String string0 = "109156be-c4fb-41ea-b1b4-efe1671c5836";

      log.debug('data0: $data0');
      Uuid uuid0 = new Uuid.fromList(data0);

      log.debug('  uuid0: $uuid0');
      log.debug('string0: $string0');
      expect(uuid0.toString(), equals(string0));
    });

    test('Make sure that really fast uuid.v4 doesn\'t produce duplicates', () {
      var list =
          new List.filled(1000, null).map((something) => new Uuid()).toList();
      var setList = list.toSet();
      log.debug('setList:$setList');
      expect(list.length, equals(setList.length));
    });
  });

  group('[Parse/Unparse Tests]', () {

    System.log.level = Level.debug2;

    test('Parsing a UUID', () {
      var id = '00112233-4455-6677-8899-aabbccddeeff';
      var uuid = Uuid.parse(id, onError: (id) => null);
      log.debug('id:   $id');
      log.debug('uuid: $uuid');
      expect(uuid.toString(), equals('00112233-4455-6677-8899-aabbccddeeff'));
    });
  });
}
