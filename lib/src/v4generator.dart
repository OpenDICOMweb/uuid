// Copyright (c) 2016, 2017 Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Author: Jim Philbin <jfphilbin@gmail.edu>
// See the AUTHORS file for other contributors.

import 'dart:math';
import 'dart:typed_data';

/// A generator of Version 4 (random) UUIDs.
///
/// The generator can use either the [Random] RNG, which is
/// the default, or the [Random.secure] RNG.
// Note: This implementation is faster than http:pub.dartlang.org/uuid
//   this one: Template(RunTime): 142,266.66666666666 us.
//   pub uuid: Template(RunTime): 170,166.66666666666 us.
class V4Generator {
  final Random rng;
  final bool isSecure;
  final int seed;

  /// Creates a generator of Version 4 UUIDs.  [isSecure] (the default)
  /// determines whether the [Random] or [Random.secure] RNG is used.
  ///
  /// [seed] affects only the [Random] RNG and can be used to gen
  /// pseudo-random numbers.
  V4Generator({this.isSecure: false, this.seed})
      : rng = (isSecure) ? new Random.secure() : new Random(seed);

  V4Generator._(this.rng, {this.isSecure: false, this.seed});

  Uint8List get next {
    Uint8List bytes = new Uint8List(16);
    Uint32List int32 = bytes.buffer.asUint32List();
    for (int i = 0; i < 4; i++) int32[i] = rng.nextInt(0xFFFFFFFF);
    // Set the version and variant bits to the correct values.
      bytes[6] = bytes[6] >> 4 | 0x40;
      bytes[8] = bytes[8] >> 2 | 0x80;
    return bytes;
  }

  static final Random _rngSecure = new Random.secure();
  static final Random _rngBasic = new Random();
  static final Random _rngTest = new Random(0);

  /// Generates a series of random (secure) [Uuid]s.
  static final secure = new V4Generator._(_rngSecure, isSecure: true);

  /// Generates a series of pseudo-random [Uuid]s.
  /// _Note_: No [seed] is used. This is faster than
  /// [secure] and can be used for testing.
  static final basic = new V4Generator._(_rngBasic);

  /// Generates a reproducible series of pseudo-random [Uuid]s.
  /// The [seed] used is 1.
  static final test = new V4Generator._(_rngTest, seed: 0);
}



/* Flush prior to V0.9.0
Uint8List _getNext(Random rng) {
  Uint8List bytes = new Uint8List(16);
  Uint32List int32 = bytes.buffer.asUint32List();
  for (int i = 0; i < 4; i++) int32[i] = rng.nextInt(0xFFFFFFFF);
  _setToVersion4(bytes);
  return bytes;
}

/// Sets the version and variant bits to the correct values.
void _setToVersion4(Uint8List bytes) {
  bytes[6] = bytes[6] >> 4 | 0x40;
  bytes[8] = bytes[8] >> 2 | 0x80;
}*/
