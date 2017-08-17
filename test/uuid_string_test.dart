// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'dart:typed_data';

import 'package:test/test.dart';
import 'package:uuid/uuid_test.dart';
//Urgent: create this same file with secure and basic

const String uuidV1 = '23d57c30-afe7-11e4-ab7d-12e3f512a338';
const String uuidV4 = '09bb1d8c-4965-4788-94f7-31b151eaba4e';

//These are the first two UUIDs generated if the seed = 0.
const String v4Random0 = '8f534d57-0195-4a3c-8796-8be3b34440bc';
const String v4Random1 = '7eeab2ad-c74e-43fe-9720-db0e09797518';

const List<int> uuidList = const <int>[
  149, 236, 195, 128, 175, 233, 17, 228, // No reformat
  155, 108, 117, 27, 102, 221, 84, 30
];

final uuidBytes = new Uint8List.fromList(uuidList);

void main() {
  group('Uuid Tests', () {
    test('Uuid Test with seed=0', () {
      print('seed: ${Uuid.seed}');
      Uuid uuid0 = new Uuid();
      print('Uuid: $uuid0');
      expect(uuid0.asString, equals(v4Random0));

      Uuid uuid1 = new Uuid();
      print('Uuid: $uuid1');
      expect(uuid1.asString, equals(v4Random1));
    });

    test('Uuid Strings', () {
      expect(Uuid.isValidString(uuidV1, 1), true);

      // accepts implicit valid uuid v1
      expect(Uuid.isValidString(uuidV1), true);

      //accepts explicit valid uuid v4
      expect(Uuid.isValidString(uuidV4, 4), true);

      //accepts implicit valid uuid v4
      expect(Uuid.isValidString(uuidV4), true);

      //denies if wrong version
      expect(Uuid.isValidString(uuidV1, 4), false);

      print(uuidList);
      print(uuidBytes);
      expect(uuidList != uuidBytes, true);

      //accepts valid List
      var uuid = new Uuid.fromList(uuidList);
      print('uuidList uuid: $uuid');
      expect(Uuid.isValidString(uuid.asString), true);

      //accepts valid Uint8List
      uuid = new Uuid.fromList(uuidBytes);
      expect(Uuid.isValidString(uuid.asString), true);
      expect(uuid.data == uuidBytes, true);

      //denies if invalid
      expect(Uuid.isValidString('foo', 4), false);

      //fixes issue #1 (character casing correct at col 19)
      expect(Uuid.isValidString('97a90793-4898-4abe-b255-e8dc6967ed40'), true);
    });
  });
}
