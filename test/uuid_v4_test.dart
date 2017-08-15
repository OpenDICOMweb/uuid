// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Author: Jim Philbin <jfphilbin@gmail.edu>
// See the AUTHORS file for other contributors.

import 'package:system/system.dart';
import 'package:uuid/uuid.dart';
import "package:test/test.dart";

void main() {
  final log = new Logger('uuid_v4_test');
  var generator = new V4Generator(isSecure: false, seed: 1);
  group('[Version 4 Tests]', () {
    test('Check if V4 is consistent using a static seed', () {
      var u0 = generator.next;
      //  log.debug('u0: $u0');
      var u1 = [
        164,
        98,
        80,
        42,
        115,
        175,
        67,
        65,
        191,
        196,
        5,
        149,
        123,
        112,
        48,
        221
      ];
      expect(u0, equals(u1));
      expect(u1.length, equals(16));
    });

    test('Test Uuid.fromBytes', () {
      List<int> bytes = [
        0x10,
        0x91,
        0x56,
        0xbe,
        0xc4,
        0xfb,
        0xc1,
        0xea,
        0x71,
        0xb4,
        0xef,
        0xe1,
        0x67,
        0x1c,
        0x58,
        0x36
      ];
      log.debug('bytes: $bytes');
      Uuid u0 = new Uuid.fromList(bytes);
      var u1 = "109156be-c4fb-41ea-b1b4-efe1671c5836";
      log.debug('u0: $u0');
      log.debug('u1: $u1');
      expect(u0.toString(), equals(u1));
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
    test('Parsing a UUID', () {
      var id = '00112233-4455-6677-8899-aabbccddeeff';
      var uuid = Uuid.parse(id);
      log.debug('id:   $id');
      log.debug('uuid: $uuid');
      expect(uuid.toString(), equals('00112233-4455-6677-8899-aabbccddeeff'));
    });
  });
}
