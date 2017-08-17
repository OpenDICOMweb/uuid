// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'dart:typed_data';

import 'src/uuid_base.dart';
import 'src/v4generator.dart';

export 'src/errors.dart';
export 'src/v4Generator.dart';

// **** Secure Version ****

/// Universally Unique Identifiers (also GUID).
///
/// _Note_: This class implements secure random [Uuid]s.
/// It should be used for production systems.
class Uuid extends UuidBase {
  // The random number generator
  static final V4Generator v4Generator = V4Generator.secure;

  // The 16 bytes of UUID data.
  final Uint8List data;

  /// Constructs a Version 4 [Uuid]. If [isSecure] is [false],
  /// it uses the [Random] RNG.  If [isSecure] is [true], it uses
  /// the [Random.secure] RNG. The default is isSecure is [true].
  Uuid() : this.data = v4Generator.next;

  /// Constructs [Uuid] from a [List<int>] of 16 unsigned 8-bit [int]s.
  Uuid.fromList(List<int> iList) : this.data = _listToBytes(iList);

  String get type => 'Testing Uuid';

  /// Returns [true] if a secure [Random] number generator is being used.
  static int get isSecure => v4Generator.isSecure;

  /// Returns the integer [seed] provided to the pseudo (non-secure)
  /// random number generator.
  static int get seed => v4Generator.seed;

  /// If [true] [Uuid] [String]s will be in uppercase hexadecimal.
  /// If [false] [Uuid] [String]s will be in lowercase hexadecimal.
  static bool get useUppercase => UuidBase.useUppercase;

  /// Returns [true] if [s] is a valid [Uuid].
  static bool isValidString(String s, [int type]) =>
      UuidBase.isValidString(s, type);

  static Uuid parse(String s, {Null Function(String) onError}) =>
      UuidBase.parse(s, onError: onError);
}
