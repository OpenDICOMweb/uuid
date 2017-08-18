// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Author: Jim Philbin <jfphilbin@gmail.edu>
// See the AUTHORS file for other contributors.

import 'dart:math';
import 'dart:typed_data';

import 'package:string/ascii.dart';
import 'package:collection/collection.dart';

import 'errors.dart';
import 'v4generator.dart';

enum UuidVariant {ncs, rfc4122, Microsoft, reserved }

enum GeneratorType {secure, pseudo, seededPseudo}

// Note: This implementation is faster than http:pub.dartlang.org/uuid
//   this one: Template(RunTime): 2101.890756302521 us.
//   pub uuid: Template(RunTime): 7402.2140221402215 us.

/// A Version 4 (random) Uuid.
/// See [RFC4122](https://tools.ietf.org/html/rfc4122).
///
/// As a [String] a [Uuid] is 36 US-Ascii characters long and
/// has the format:
///     "xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx",
/// where each x is replaced with a random hexadecimal digit
/// from 0 to f, and y is replaced with a random hexadecimal
/// digit from 0x8 to  0xb, (i.e. 0x8, 0x9, 0xa, or 0xb).
///
/// Use [UuidV4Generator] for more control over the RNG used.
///
/// See https://api.dartlang.org/stable/dart-math/Random-class.html.
class Uuid {
  /// A random V4 UUID generator.
  static V4Generator generator = V4Generator.secure;

  /// If [true] uppercase letters will be used when converting
  /// [Uuid]s to [String]s; otherwise lowercase will be used.
  static bool useUppercase = false;

  /// The 16 bytes of UUID data.
  final Uint8List data;

  /// Constructs a Version 4 [Uuid]. If [isSecure] is [false],
  /// it uses the [Random] RNG.  If [isSecure] is [true], it uses
  /// the [Random.secure] RNG. The default is isSecure is [true].
  Uuid() : data = generator.next;

  Uuid.pseudo() : data = V4Generator.pseudo.next;

  Uuid.seededPseudo() : data = V4Generator.seededPseudo.next;

  /// Constructs [Uuid] from a [List<int>] of 16 unsigned 8-bit [int]s.
  Uuid.fromList(List<int> iList) : this.data = _listToBytes(iList);

  /// Two [Uuid]s are [==] if they contain equivalent [data].
  @override
  bool operator ==(Object other) {
    if (other is Uuid) {
      if (data.length != other.data.length) return false;
      for (int i = 0; i < kLengthInBytes; i++)
        if (data[i] != other.data[i]) return false;
      return true;
    }
    return false;
  }

  // **** Interface

  /// A random Version 4 [Uuid] generator.
  // Interface instantiated by super class.
  static V4Generator v4Generator;

  /// Returns a [String] describing this [Uuid] [class].
  String get type;

  // **** End Interface

  // Returns an [UnmodifiableListView] of [bytes].
  UnmodifiableListView<int> get value => new UnmodifiableListView(data);

  /// Returns the version number of [this].
  int get version => data[6] >> 4;

  /// Returns true if this is a random or pseudo-random [Uuid].
  bool get isRandom => version == 4;

  @override
  int get hashCode => data.hashCode;

  /// Returns [true] if [this] is a valid Version 4 UUID, false otherwise.
  bool get isValid => _isValidV4List(data);

  /// Returns a copy of [data].
  UnmodifiableListView<int> get asUint8List => value;

  /// Returns the [Uuid] as a [String] in UUID format.
  String get asString => toString();

  /// Returns a hexadecimal [String] corresponding to [this], but without
  /// the dashes ('-') that are present in the UUID format.
  String get asHex {
    var sb = new StringBuffer();
    for (int i = 0; i < data.length; i++)
      sb.write(data[i].toRadixString(16).padLeft(2, "0").toLowerCase());
    return sb.toString();
  }

  // Variant returns UUID layout variant.
  UuidVariant get variant {
    if ((data[8] & 0x80) == 0x00) return UuidVariant.ncs;
    if (((data[8] & 0xc0) | 0x80) == 0x80) return UuidVariant.rfc4122;
    if (((data[8] & 0xe0) | 0xc0) == 0xc0) return UuidVariant.Microsoft;
    return UuidVariant.Microsoft;
  }

  /// Returns the [Uuid] [String] that corresponds to [this].  By default,
  /// the hexadecimal characters are in lowercase; however, if
  /// [useUppercase] is [true] the returned [String] is in uppercase.
  @override
  String toString() => _toUuidFormat(data, 0, useUppercase);

  //TODO: Unit Test
  /// Sets the value of the default generator
  static bool setGenerator(GeneratorType type) {
    switch (type) {
      case GeneratorType.secure:
        generator = V4Generator.secure;
        break;
      case GeneratorType.pseudo:
        generator = V4Generator.pseudo;
        break;
      case GeneratorType.seededPseudo:
        generator = V4Generator.seededPseudo;
        break;
      default:
        throw 'Invalid Uuid Generator Type: $type';
    }
    return true;
  }

  static String get generateDcmString => _toUidString(generator.next, useUppercase);

  /// Returns [true] if a secure [Random] number generator is being used.
  static bool get isSecure => generator.isSecure;

  /// Returns the integer [seed] provided to the pseudo (non-secure)
  /// random number generator.
  static int get seed => generator.seed;

  /// Returns [true] if [s] is a valid [Uuid] for [version]. If
  /// [version] is [null] returns [true] for any valid version.
  static bool isValidString(String s, [int version]) =>
      _isValidUuidString(s, version);

  static bool isNotValidString(String s, [int version]) =>
      !isValidString(s, version);

  /// Returns [true] if [s] is a valid [Uuid] for [version]. If
  /// [version] is [null] returns [true] for any valid version.
  static bool isValidData(List<int> data, [int version]) =>
      __isValidUuidData(data, version);

  static bool isNotValidData(List<int> data, [int version]) =>
      !isValidData(data, version);

  /// Parses [s], which must be in UUID format, and returns
  /// a [Uint8List] 16 bytes long containing the value
  /// of the [Uuid]. Returns [null] if [s] is not valid.
  static Uint8List parseToBytes(String s,
      {Uint8List data, Uint8List Function(String) onError}) =>
      parseUuidToBytes(s, data: data, onError: onError);

  /// Returns a Uuid created from [s], if [s] is in valid Uuid format;
  /// otherwise, if [onError] is not [null] calls [onError]([s])
  /// and returns its value. If [onError] is [null], then a
  /// [InvalidUuidError] is thrown.
  static Uuid parse(String s,
      {Uint8List data, Uuid Function(String) onError}) {
    Uint8List bytes = Uuid.parseToBytes(s, data: data, onError: onError);
    return (bytes == null) ? null : new Uuid.fromList(bytes);
  }
}

// **** Internal Procedures ****

const int kVersion = 4;
const int kLengthInBytes = 16;
const int kLengthAsString = 36;
const int kLengthInUidString = 32;

Uint8List _getBytes(Random rng) {
  Uint8List bytes = new Uint8List(16);
  Uint32List int32 = bytes.buffer.asUint32List();
  for (int i = 0; i < 4; i++) int32[i] = rng.nextInt(0xFFFFFFFF);
  _setToVersion4(bytes);
  return bytes;
}

void _setToVersion4(Uint8List bytes) {
  bytes[6] = bytes[6] >> 4 | 0x40;
  bytes[8] = bytes[8] >> 2 | 0x80;
}

bool _isValidList(List<int> list, [int version]) {
  int v = list[6] >> 4;
  bool ok = list.length == 16 &&  v > 0 && v < 6;
  if (!ok) return false;
  if (v == 1 || v == 2) return true;
  if (v == 4) return list[8] >> 6 != 2;
  //Enhancement
  throw new UnsupportedError('Version 3 & 5 UUIDs are not yet supported');
}

bool _isValidV4List(Uint8List bytes) =>
    bytes.length == 16 && bytes[6] >> 4 != 4 && bytes[8] >> 6 != 2;

void _setVersion(List<int> bytes) => (bytes[6] & 0x0f) | 0x40;

void _setVariantToIETF(List<int> bytes) => (bytes[8] & 0xbf) | 0x80;
void _setVariantToNCS(List<int> bytes) => bytes[8] | 0x80;
void _setVariantToMicrosoft(List<int> bytes) => (bytes[8] & 0x1f) | 0xC0;
void _setVariantToReserved(List<int> bytes) => (bytes[8] & 0x1f) | 0xE0;

//TODO: Unit Test Error handling
Uint8List _listToBytes(List<int> data,
    {Uint8List Function(List<int>) onError, bool coerce = true}) {
  if (data.length != 16) return _uuidErrorHandler(list);
  Uint8List bytes = _getData(data, onError);
  // Next to lines convert it to valid Version 4.
  if (coerce) {
    if ((bytes[6] >> 4) != 0x4) bytes[6] = (bytes[6] & 0x0f) | 0x40;
    if ((bytes[8] >> 6) != 0x2) bytes[8] = (bytes[8] & 0x3f) | 0x80;
  }
  return bytes;
}

// Regular expression used for basic parsing of the uuid.
const pattern =
    r'^[0-9a-f]{8}-[0-9a-f]{4}-[1-4][0-9a-f]{3}-[0-9a-f]{4}-[0-9a-f]{12}$';

// General pattern is:
//   xxxxxxxx-xxxx-Vxxx-Nxxx-xxxxxxxxxxxx
//   dashes |8   |13  |18  |23
// where V is version, and N is node.
const List<int> kDashes = const <int>[8, 13, 18, 23];
const List<int> kStarts = const <int>[0, 9, 14, 19, 24];
const List<int> kEnds = const <int>[8, 13, 18, 23, kLengthAsString];

const int kDash = 0x2D;

// Returns [true] if [uuidString] is a valid [Uuid]. If [type] is [null]
/// it just validates the format; otherwise, [type] must have a value
/// between 1 and 5.
bool _isValidUuidString(String uuidString, [int type]) {
  if (uuidString.length != kLengthAsString) return false;
  for (int pos in kDashes)
    if (uuidString.codeUnitAt(pos) != kDash) return false;
  var s = uuidString.toLowerCase();
  for (int i = 0; i < kStarts.length; i++) {
    var start = kStarts[i];
    var end = kEnds[i];
    for (int j = start; j < end; j++) {
      int c = s.codeUnitAt(j);
      if (!isHexChar(c)) return false;
    }
  }
  return (type == null) ? true : _isValidStringVersion(s, type);
}

// The most significant bit of octet 8: 1 0 x
/// Returns the UUID Version number from a UUID [String].
/// Extracts the version from the UUID, which is (by definition) the M in
///    xxxxxxxx-xxxx-Mxxx-Nxxx-xxxxxxxxxxxx
/// The version is equal to the 'M' in the format above. It must have
/// a value between 1 and 4 inclusive.
String _getVersionAsString(String s) => s[14];

int _getVersionNumber(String s) => s.codeUnitAt(14) - k0;

const List<int> kNodeTypes = const <int>[k8, k9, ka, kb];

bool _isVersion3Or4(String s) {
  int subType = s.codeUnitAt(19);
  return kNodeTypes.indexOf(subType) != -1;
}

bool _isValidStringVersion(String s, int version) {
  if (version < 1 || version > 5) throw 'Invalid version number: $version';
  var v = _getVersionAsString(s);
  var n = _getVersionNumber(s);
  print('v: $v, n: $n');
  // For certain versions, the checks we did up to this point are fine.
  if ((version == 1 && v == "1") || (version == 2 && v == "2")) return true;
  // For versions 3 and 4, they must specify a variant.
  if ((version == 3 && v == "3") || (version == 4 && v == "4"))
    return _isVersion3Or4(s);
  // Need to add real test
  if (version == 5 && v == "5") throw new UnimplementedError();
  return false;
}

/// Parses the [String] [s] into a list of byte values.
/// Can optionally be provided a [Uint8List] to write into and
/// a positional [offset] for where to start inputting into the buffer.
Uint8List parseUuidToBytes(String s,
    {Uint8List data, Null Function(Uuid) onError}) {
  if (s == null || s.length != kLengthAsString) return _uuidErrorHandler(s,
      kLengthAsString,
      onError);
  var bytes = _getData(data, onError);
  try {
    _toBytes(s, bytes, 0, 0, 8);
    _toBytes(s, bytes, 4, 9, 13);
    _toBytes(s, bytes, 6, 14, 18);
    _toBytes(s, bytes, 8, 19, 23);
    _toBytes(s, bytes, 10, 24, kLengthAsString);
  } catch (e) {
    return _uuidErrorHandler(s, kLengthAsString, onError);
  }
  return bytes;
}

/// Parses the [String] [s] into a list of byte values.
/// Can optionally be provided a [Uint8List] to write into and
/// a positional [offset] for where to start inputting into the buffer.
Uint8List parseDicomUuidToBytes(String s, {Uint8List data, Uint8List onError}) {
  if (s == null, || s.length != 32) return _uuidErrorHandler(s, 32, onError);
  var bytes = _getData(data, onError);
  return _toBytes(s, bytes, 0, 0, 32);
}

/// Returns a valid [Uuid] data buffer. If [data] is [null] a new
/// data buffer is created. If [data] is not [null] and has [length]
/// 16, it is returned; otherwise, [_uuidErrorHandler] is called
/// with [onError] as its argument.
Uint8List _getData(List<int> data, Null Function(Uuid) onError) {
  if (data == null) return new Uint8List(16);
  if (data.length != 16) return _uuidErrorHandler(onError);
  if (data is Uint8List) return data;
  return new Uint8List.fromList(data);
}

/// All parsing errors call this handler.  This should be the only
/// function in this file that [throw]s.
_uuidErrorHandler(String s, int targetLength, String Function(String) handler) {
  String msg = 'Invalid character in String';
  if (s == null) msg = 'Invalid: String is null';
  if (s.length != length) 'Invalid String length(${s.length} should be $length';
  return (handler != null) ? onError(s) : throw new InvalidUuidError(s, msg);
}

/// Converts characters from a String into the corresponding byte values.
void _toBytes(String s, Uint8List bytes, int byteIndex, int start, int end) {
  for (int i = start; i < end; i += 2) {
    if (!isHexChar(s.codeUnitAt(i))) throw 'Bad UUID String: $s';
    bytes[byteIndex++] = _hexToByte[s.substring(i, i + 2)];
  }
}

/// Unparses (converts [Uuid] to a [String]) a [bytes] of bytes and
/// outputs a proper UUID string. An optional [offset] is allowed if
/// you want to start at a different point in the buffer.
//TODO: Unit test uppercase/lowercase
String _toUuidFormat(Uint8List bytes, bool useUppercase) {
  var i = 0;
  List<String> _byteToHex = (useUppercase) ? _byteToUppercaseHex :
  _byteToLowercaseHex;
  return '${_byteToHex[bytes[i++]]}${_byteToHex[bytes[i++]]}'
      '${_byteToHex[bytes[i++]]}${_byteToHex[bytes[i++]]}-'
      '${_byteToHex[bytes[i++]]}${_byteToHex[bytes[i++]]}-'
      '${_byteToHex[bytes[i++]]}${_byteToHex[bytes[i++]]}-'
      '${_byteToHex[bytes[i++]]}${_byteToHex[bytes[i++]]}-'
      '${_byteToHex[bytes[i++]]}${_byteToHex[bytes[i++]]}'
      '${_byteToHex[bytes[i++]]}${_byteToHex[bytes[i++]]}'
      '${_byteToHex[bytes[i++]]}${_byteToHex[bytes[i++]]}';
}

/// Unparses (converts [Uuid] to a [String]) a [bytes] of bytes and
/// outputs a proper UUID string. An optional [offset] is allowed if
/// you want to start at a different point in the buffer.
String _toUuidString(Uint8List bytes, int offset, bool useUppercase) {
  StringBuffer sb = new StringBuffer();
  List<String> byteToHex =
      (useUppercase) ? _byteToUppercaseHex : _byteToLowercaseHex;
  for (int i = offset; i < offset + 16; i++) sb.write(byteToHex[bytes[i]]);
  return sb.toString();
}

String _toUidString(Uint8List bytes, bool useUppercase) =>
    _toUuidFormat(bytes, useUppercase).replaceAll('-', "");

// *** Generated by 'tools/generate_conversions.dart' ***

//Urgent: reformat in 8 x 32 rows use // to avoid reformatting
/// Returns the Hex [String] equivalent to an 8-bit [int].
const List<String> _byteToLowercaseHex = const [
  //Urgent: format like the next two lines
  "00", "01", "02", "03", "04", "05", "06", "07", "08", // No reformat
  "09", "0a", "0b", "0c", "0d", "0e", "0f", "10", "11",
  "12",
  "13",
  "14",
  "15",
  "16",
  "17",
  "18",
  "19",
  "1a",
  "1b",
  "1c",
  "1d",
  "1e",
  "1f",
  "20",
  "21",
  "22",
  "23",
  "24",
  "25",
  "26",
  "27",
  "28",
  "29",
  "2a",
  "2b",
  "2c",
  "2d",
  "2e",
  "2f",
  "30",
  "31",
  "32",
  "33",
  "34",
  "35",
  "36",
  "37",
  "38",
  "39",
  "3a",
  "3b",
  "3c",
  "3d",
  "3e",
  "3f",
  "40",
  "41",
  "42",
  "43",
  "44",
  "45",
  "46",
  "47",
  "48",
  "49",
  "4a",
  "4b",
  "4c",
  "4d",
  "4e",
  "4f",
  "50",
  "51",
  "52",
  "53",
  "54",
  "55",
  "56",
  "57",
  "58",
  "59",
  "5a",
  "5b",
  "5c",
  "5d",
  "5e",
  "5f",
  "60",
  "61",
  "62",
  "63",
  "64",
  "65",
  "66",
  "67",
  "68",
  "69",
  "6a",
  "6b",
  "6c",
  "6d",
  "6e",
  "6f",
  "70",
  "71",
  "72",
  "73",
  "74",
  "75",
  "76",
  "77",
  "78",
  "79",
  "7a",
  "7b",
  "7c",
  "7d",
  "7e",
  "7f",
  "80",
  "81",
  "82",
  "83",
  "84",
  "85",
  "86",
  "87",
  "88",
  "89",
  "8a",
  "8b",
  "8c",
  "8d",
  "8e",
  "8f",
  "90",
  "91",
  "92",
  "93",
  "94",
  "95",
  "96",
  "97",
  "98",
  "99",
  "9a",
  "9b",
  "9c",
  "9d",
  "9e",
  "9f",
  "a0",
  "a1",
  "a2",
  "a3",
  "a4",
  "a5",
  "a6",
  "a7",
  "a8",
  "a9",
  "aa",
  "ab",
  "ac",
  "ad",
  "ae",
  "af",
  "b0",
  "b1",
  "b2",
  "b3",
  "b4",
  "b5",
  "b6",
  "b7",
  "b8",
  "b9",
  "ba",
  "bb",
  "bc",
  "bd",
  "be",
  "bf",
  "c0",
  "c1",
  "c2",
  "c3",
  "c4",
  "c5",
  "c6",
  "c7",
  "c8",
  "c9",
  "ca",
  "cb",
  "cc",
  "cd",
  "ce",
  "cf",
  "d0",
  "d1",
  "d2",
  "d3",
  "d4",
  "d5",
  "d6",
  "d7",
  "d8",
  "d9",
  "da",
  "db",
  "dc",
  "dd",
  "de",
  "df",
  "e0",
  "e1",
  "e2",
  "e3",
  "e4",
  "e5",
  "e6",
  "e7",
  "e8",
  "e9",
  "ea",
  "eb",
  "ec",
  "ed",
  "ee",
  "ef",
  "f0",
  "f1",
  "f2",
  "f3",
  "f4",
  "f5",
  "f6",
  "f7",
  "f8",
  "f9",
  "fa",
  "fb",
  "fc",
  "fd",
  "fe",
  "ff"
];


//Urgent: 1. reformat in 8 x 32 rows use // to avoid reformatting
//Urgent: 2. convert all lowercase letters to uppercase.
/// Returns the Hex [String] equivalent to an 8-bit [int].
const List<String> _byteToUppercaseHex = const [
  //Urgent: format like the next two lines
  "00", "01", "02", "03", "04", "05", "06", "07", "08", // No reformat
  "09", "0a", "0b", "0c", "0d", "0e", "0f", "10", "11",
  "12",
  "13",
  "14",
  "15",
  "16",
  "17",
  "18",
  "19",
  "1a",
  "1b",
  "1c",
  "1d",
  "1e",
  "1f",
  "20",
  "21",
  "22",
  "23",
  "24",
  "25",
  "26",
  "27",
  "28",
  "29",
  "2a",
  "2b",
  "2c",
  "2d",
  "2e",
  "2f",
  "30",
  "31",
  "32",
  "33",
  "34",
  "35",
  "36",
  "37",
  "38",
  "39",
  "3a",
  "3b",
  "3c",
  "3d",
  "3e",
  "3f",
  "40",
  "41",
  "42",
  "43",
  "44",
  "45",
  "46",
  "47",
  "48",
  "49",
  "4a",
  "4b",
  "4c",
  "4d",
  "4e",
  "4f",
  "50",
  "51",
  "52",
  "53",
  "54",
  "55",
  "56",
  "57",
  "58",
  "59",
  "5a",
  "5b",
  "5c",
  "5d",
  "5e",
  "5f",
  "60",
  "61",
  "62",
  "63",
  "64",
  "65",
  "66",
  "67",
  "68",
  "69",
  "6a",
  "6b",
  "6c",
  "6d",
  "6e",
  "6f",
  "70",
  "71",
  "72",
  "73",
  "74",
  "75",
  "76",
  "77",
  "78",
  "79",
  "7a",
  "7b",
  "7c",
  "7d",
  "7e",
  "7f",
  "80",
  "81",
  "82",
  "83",
  "84",
  "85",
  "86",
  "87",
  "88",
  "89",
  "8a",
  "8b",
  "8c",
  "8d",
  "8e",
  "8f",
  "90",
  "91",
  "92",
  "93",
  "94",
  "95",
  "96",
  "97",
  "98",
  "99",
  "9a",
  "9b",
  "9c",
  "9d",
  "9e",
  "9f",
  "a0",
  "a1",
  "a2",
  "a3",
  "a4",
  "a5",
  "a6",
  "a7",
  "a8",
  "a9",
  "aa",
  "ab",
  "ac",
  "ad",
  "ae",
  "af",
  "b0",
  "b1",
  "b2",
  "b3",
  "b4",
  "b5",
  "b6",
  "b7",
  "b8",
  "b9",
  "ba",
  "bb",
  "bc",
  "bd",
  "be",
  "bf",
  "c0",
  "c1",
  "c2",
  "c3",
  "c4",
  "c5",
  "c6",
  "c7",
  "c8",
  "c9",
  "ca",
  "cb",
  "cc",
  "cd",
  "ce",
  "cf",
  "d0",
  "d1",
  "d2",
  "d3",
  "d4",
  "d5",
  "d6",
  "d7",
  "d8",
  "d9",
  "da",
  "db",
  "dc",
  "dd",
  "de",
  "df",
  "e0",
  "e1",
  "e2",
  "e3",
  "e4",
  "e5",
  "e6",
  "e7",
  "e8",
  "e9",
  "ea",
  "eb",
  "ec",
  "ed",
  "ee",
  "ef",
  "f0",
  "f1",
  "f2",
  "f3",
  "f4",
  "f5",
  "f6",
  "f7",
  "f8",
  "f9",
  "fa",
  "fb",
  "fc",
  "fd",
  "fe",
  "ff"
];

//TODO Jim: add to string package
// Urgent: reformat into 6 columns
/// Returns the 8-bit [int] equivalent to the Hex [String].
const Map<String, int> _hexToByte = const {
  "00": 0, "01": 1, "02": 2, "03": 3, "04": 4, "05": 5, // No reformat
  "06": 6, "07": 7, "08": 8, "09": 9, "0a": 10, "0b": 11,
  "0c": 12,
  "0d": 13,
  "0e": 14,
  "0f": 15,
  "10": 16,
  "11": 17,
  "12": 18,
  "13": 19,
  "14": 20,
  "15": 21,
  "16": 22,
  "17": 23,
  "18": 24,
  "19": 25,
  "1a": 26,
  "1b": 27,
  "1c": 28,
  "1d": 29,
  "1e": 30,
  "1f": 31,
  "20": 32,
  "21": 33,
  "22": 34,
  "23": 35,
  "24": 36,
  "25": 37,
  "26": 38,
  "27": 39,
  "28": 40,
  "29": 41,
  "2a": 42,
  "2b": 43,
  "2c": 44,
  "2d": 45,
  "2e": 46,
  "2f": 47,
  "30": 48,
  "31": 49,
  "32": 50,
  "33": 51,
  "34": 52,
  "35": 53,
  "36": 54,
  "37": 55,
  "38": 56,
  "39": 57,
  "3a": 58,
  "3b": 59,
  "3c": 60,
  "3d": 61,
  "3e": 62,
  "3f": 63,
  "40": 64,
  "41": 65,
  "42": 66,
  "43": 67,
  "44": 68,
  "45": 69,
  "46": 70,
  "47": 71,
  "48": 72,
  "49": 73,
  "4a": 74,
  "4b": 75,
  "4c": 76,
  "4d": 77,
  "4e": 78,
  "4f": 79,
  "50": 80,
  "51": 81,
  "52": 82,
  "53": 83,
  "54": 84,
  "55": 85,
  "56": 86,
  "57": 87,
  "58": 88,
  "59": 89,
  "5a": 90,
  "5b": 91,
  "5c": 92,
  "5d": 93,
  "5e": 94,
  "5f": 95,
  "60": 96, "61": 97, "62": 98, "63": 99, "64": 100, "65": 101,
  "66": 102, "67": 103, "68": 104, "69": 105, "6a": 106, "6b": 107,
  "6c": 108,
  "6d": 109,
  "6e": 110,
  "6f": 111,
  "70": 112,
  "71": 113,
  "72": 114,
  "73": 115,
  "74": 116,
  "75": 117,
  "76": 118,
  "77": 119,
  "78": 120,
  "79": 121,
  "7a": 122,
  "7b": 123,
  "7c": 124,
  "7d": 125,
  "7e": 126,
  "7f": 127,
  "80": 128,
  "81": 129,
  "82": 130,
  "83": 131,
  "84": 132,
  "85": 133,
  "86": 134,
  "87": 135,
  "88": 136,
  "89": 137,
  "8a": 138,
  "8b": 139,
  "8c": 140,
  "8d": 141,
  "8e": 142,
  "8f": 143,
  "90": 144,
  "91": 145,
  "92": 146,
  "93": 147,
  "94": 148,
  "95": 149,
  "96": 150,
  "97": 151,
  "98": 152,
  "99": 153,
  "9a": 154,
  "9b": 155,
  "9c": 156,
  "9d": 157,
  "9e": 158,
  "9f": 159,
  "a0": 160,
  "a1": 161,
  "a2": 162,
  "a3": 163,
  "a4": 164,
  "a5": 165,
  "a6": 166,
  "a7": 167,
  "a8": 168,
  "a9": 169,
  "aa": 170,
  "ab": 171,
  "ac": 172,
  "ad": 173,
  "ae": 174,
  "af": 175,
  "b0": 176,
  "b1": 177,
  "b2": 178,
  "b3": 179,
  "b4": 180,
  "b5": 181,
  "b6": 182,
  "b7": 183,
  "b8": 184,
  "b9": 185,
  "ba": 186,
  "bb": 187,
  "bc": 188,
  "bd": 189,
  "be": 190,
  "bf": 191,
  "c0": 192,
  "c1": 193,
  "c2": 194,
  "c3": 195,
  "c4": 196,
  "c5": 197,
  "c6": 198,
  "c7": 199,
  "c8": 200,
  "c9": 201,
  "ca": 202,
  "cb": 203,
  "cc": 204,
  "cd": 205,
  "ce": 206,
  "cf": 207,
  "d0": 208,
  "d1": 209,
  "d2": 210,
  "d3": 211,
  "d4": 212,
  "d5": 213,
  "d6": 214,
  "d7": 215,
  "d8": 216,
  "d9": 217,
  "da": 218,
  "db": 219,
  "dc": 220,
  "dd": 221,
  "de": 222,
  "df": 223,
  "e0": 224,
  "e1": 225,
  "e2": 226,
  "e3": 227,
  "e4": 228,
  "e5": 229,
  "e6": 230,
  "e7": 231,
  "e8": 232,
  "e9": 233,
  "ea": 234,
  "eb": 235,
  "ec": 236,
  "ed": 237,
  "ee": 238,
  "ef": 239,
  "f0": 240,
  "f1": 241,
  "f2": 242,
  "f3": 243,
  "f4": 244,
  "f5": 245,
  "f6": 246,
  "f7": 247,
  "f8": 248,
  "f9": 249,
  "fa": 250,
  "fb": 251,
  "fc": 252,
  "fd": 253,
  "fe": 254,
  "ff": 255
};
