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

// **** TESTING Version ****

/// Universally Unique Identifiers (also GUID).
///
/// _Note_: This class should be used for testing the [Uuid] package.
/// The seed can be edited, but should be used as it creates
/// reproducible streams of [Uuid] data.
class Uuid extends UuidBase {
  /// The random [Uuid] generator.
  static final V4Generator v4Generator = V4Generator.test;

  // The 16 bytes of UUID data.
  final Uint8List data;

  /// Constructs a Version 4 [Uuid]. If [isSecure] is [false],
  /// it uses the [Random] RNG.  If [isSecure] is [true], it uses
  /// the [Random.secure] RNG. The default is isSecure is [true].
  Uuid() : this.data = v4Generator.next;

  /// Constructs [Uuid] from a [List<int>] of 16 unsigned 8-bit [int]s.
  Uuid.fromList(List<int> iList) : this.data = listToBytes(iList);

  String get type => 'Testing Uuid';

  /// Returns [true] if a secure [Random] number generator is being used.
  static bool get isSecure => v4Generator.isSecure;

  /// Returns the integer [seed] provided to the pseudo (non-secure)
  /// random number generator.
  static int get seed => v4Generator.seed;

  /// If [true] [Uuid] [String]s will be in uppercase hexadecimal.
  /// If [false] [Uuid] [String]s will be in lowercase hexadecimal.
  static bool get useUppercase => UuidBase.useUppercase;

  /// Returns [true] if [s] is a valid [Uuid].
  static bool isValidString(String s, [int type]) =>
      UuidBase.isValidString(s, type);

  /// Parses [s], which must be in UUID format, and returns
  /// a [Uint8List] 16 bytes long containing the value
  /// of the [Uuid]. Returns [null] if [s] is not valid.
  static Uint8List parseToBytes(String s,
      {Uint8List bytes, UuidBase Function(String) onError}) =>
      parseUuidToBytes(s, bytes: bytes, onError: onError);

  /// Returns a Uuid created from [s], if [s] is in valid Uuid format;
  /// otherwise, if [onError] is not [null] calls [onError]([s])
  /// and returns its value. If [onError] is [null], then a
  /// [InvalidUuidError] is thrown.
  static Uuid parse(String s,
      {Uint8List data, UuidBase Function(String) onError}) {
    Uint8List bytes = parseUuidToBytes(s, data: data, onError: onError);
    return (bytes == null) ? null : new Uuid.fromList(bytes);
  }

}
