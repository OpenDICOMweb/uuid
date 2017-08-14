// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.

// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Author: Jim Philbin <jfphilbin@gmail.edu>
// See the AUTHORS file for other contributors.

import 'dart:math';
import 'dart:typed_data';

import 'package:collection/collection.dart';
import 'package:common/number.dart';

/// A generator of Version 4 (random) UUIDs.
///
/// The generator can use either the [Random] RNG, which is the default,
/// or the [Random.secure] RNG.
class UuidV4Generator {
  final Random rngBasic;
  final Random rngSecure;
  final bool isSecure;

  /// Creates a generator of Version 4 UUIDs.  [isSecure] (the default) determines
  /// whether the [Random] or [Random.secure] RNG is used.
  ///
  /// [seed] affects only the [Random] RNG and can be used to gen pseudo-random
  /// numbers.
  UuidV4Generator({this.isSecure: false, int seed})
      : rngBasic = new Random(seed),
        rngSecure = new Random.secure();

  Random get rng => (isSecure) ? rngSecure : rngBasic;

  Uint8List get bytes => _getBytes(rng);

  String get string => _toUidString(_getBytes(rng));

  /// Returns a Version 4 (random) UUID.
  /// If [isSecure] is [true] it uses the [Random.secure] RNG.
  Uint8List call({bool isSecure: false}) =>
      _getBytes((isSecure) ? rngSecure : rngBasic);
}

/// A Version 4 (random) Uuid.
/// See [RFC4122](https://tools.ietf.org/html/rfc4122).
///
/// As a [String] a [Uuid] is 36 US-Ascii characters long and has the format:
///     "xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx",
/// where each x is replaced with a random hexadecimal digit from 0 to f,
/// and y is replaced with a random hexadecimal digit from 8 to b, i.e.
///
/// Use [UuidV4Generator] for more control over the RNG used.
///
/// See https://api.dartlang.org/stable/dart-math/Random-class.html.
class Uuid {
  static const int version = 4;
  static const int lengthInBytes = 16;
  static const int lengthAsString = 36;
  static const int lengthAsUidString = 32;

  /// The default [generator] uses the default [Random] number generator.
  static final UuidV4Generator generator = new UuidV4Generator();

  /// Set to [true] for uppercase hex characters.
  static bool useUppercase = false;

  /// A [Uint8List] 16 bytes long containing the [Uuid] value.
  final Uint8List _bytes;

  /// Constructs a Version 4 [Uuid]. If [isSecure] is [false], (the default) it uses
  /// the [Random] RNG.  If [isSecure] is [true], it uses the [Random.secure] RNG.
  Uuid({bool isSecure: false}) : _bytes = generator(isSecure: isSecure);

  /// Constructs a Version 4 [Uuid] from a [List<int>].  If the [List] has length greater than 16,
  /// it constructs the [Uuid] from [list.sublist(0, 16)].
  Uuid.fromList(List<int> bytes) : _bytes = _listToBytes(bytes);

  /// Constructs a Version 4 [Uuid] from a [Uint8List].  If the [List] has length greater than 16,
  /// it constructs the [Uuid] from [list.sublist(0, 16)].
  Uuid.fromUint8List(Uint8List _bytes)
      : _bytes = (_isValidV4Uint8List(_bytes))
            ? _bytes
            : throw new ArgumentError('Invalid Uuid Uint8List: $_bytes');

  Uuid._(this._bytes);

  /// Two [Uuid]s are [==] if they contain equivalent [_bytes].
  @override
  bool operator ==(Object other) {
    if (other is Uuid) {
      if (_bytes.length != other._bytes.length) return false;
      for (int i = 0; i < lengthInBytes; i++)
        if (_bytes[i] != other._bytes[i]) return false;
      return true;
    } else {
      return false;
    }
  }

  @override
  int get hashCode => Hash.hash(_bytes);

  // Returns an [UnmodifiableListView] of [_bytes].
  UnmodifiableListView<int> get value => new UnmodifiableListView(_bytes);

  /// Returns [true] if [this] is a valid Version 4 UUID, false otherwise.
  bool get isValid => _isValidV4Uint8List(_bytes);

  /// Returns a copy of [_bytes].
  UnmodifiableListView<int> get asUint8List => value;

  /// Returns the [Uuid] as a [String] in UUID format.
  String get asString => toString();

  /// Returns a list of hexadecimal [String]s corresponding to [this].
  String get asHex {
    var sb = new StringBuffer();
    for (int i = 0; i < _bytes.length; i++)
      sb.write(_bytes[i].toRadixString(16).padLeft(2, "0").toLowerCase());
    return sb.toString();
  }

  /// Returns the [Uuid] [String] that corresponds to [this].  By default,
  /// the hexadecimal characters are in lowercase; however, if [useUppercase] is
  /// [true] the returned [String] is in uppercase.
  @override
  String toString() {
    var s = _toUuidFormat(_bytes);
    return (useUppercase) ? s.toUpperCase() : s;
  }

  /// Returns a new random Uuid using the default generator.
  static Uuid get random => new Uuid();

  //Flush
  /// The UID Root for UIDs created from random (V4) UUIDs.
  // static const String randomUidRoot = "2.25.";

  // flush
  /// Returns a [String] containing a random UID as per the
  /// OID Standard.  See TODO: add reference.
  //static String get randomUid =>
  //    randomUidRoot + _unparse(random._bytes).replaceAll('-', "");

  //TODO: Should this return [null] or [throw] an error?
  /// Parses a [String] in UUID format.  Returns the corresponding
  /// UUID if valid; otherwise, returns [null].
  static Uuid parse(String s, [Uint8List buffer, int offset = 0]) {
    var uuid = new Uuid._(_parseToBytes(s, buffer, offset));
    if (!uuid.isValid) return null;
    return uuid;
  }
}

// **** Internal Procedures ****
/* Flush at 0.9.0 if not used
Uint8List _validateV4Uint8List(Uint8List bytes) {
  if ((bytes.length != Uuid.lengthInBytes) ||
      (0x40 != bytes[6] & 0x40) || (2 != (bytes[8] >> 6) & 0x02))
    throw "Invalid Uuid Uint8List: $bytes";
  return bytes;
}
*/

Uint8List _getBytes(Random rng) {
  Uint8List bytes = new Uint8List(16);
  Uint32List int32 = bytes.buffer.asUint32List();
  for (int i = 0; i < 4; i++) int32[i] = rng.nextInt(0xFFFFFFFF);
  bytes[6] = bytes[6] >> 4 | 0x40;
  bytes[8] = bytes[8] >> 2 | 0x80;
  return bytes;
}

bool _isValidV4Uint8List(Uint8List bytes) =>
    (bytes.length == Uuid.lengthInBytes) &&
    (0x40 == bytes[6] & 0x40) &&
    (2 == (bytes[8] >> 6) & 0x02);

Uint8List _listToBytes(List<int> list) {
  if (list.length < 16)
    throw new ArgumentError('Invalid List Length: ${list.length}');

  Uint8List bytes =
      (list is Uint8List) ? list : new Uint8List.fromList(list.sublist(0, 16));
  if ((bytes[6] >> 4) != 0x4) bytes[6] = (bytes[6] & 0x0f) | 0x40;
  if ((bytes[8] >> 6) != 0x2) bytes[8] = (bytes[8] & 0x3f) | 0x80;
  return bytes;
}

// This implementation is faster than http:pub.dartlang.org/uuid
//   this one: Template(RunTime): 142,266.66666666666 us.
//   pub uuid: Template(RunTime): 170,166.66666666666 us.
//
/// Parses the provided [uuid] [String] into a list of byte values.
/// Can optionally be provided a [Uint8List] to write into and
/// a positional [offset] for where to start inputting into the buffer.
Uint8List _parseToBytes(String s, [Uint8List list, int offset = 0]) {
  Uint8List bytes =
      (list != null) ? list.buffer.asUint8List(offset, 16) : new Uint8List(16);
  void toBytes(int byteIndex, int start, int end) {
    for (int i = start; i < end; i += 2)
      //TODO: change this to use s.codeUnitAt(i)
      bytes[byteIndex++] = hexToByte[s.substring(i, i + 2)];
  }

  toBytes(0, 0, 8);
  toBytes(4, 9, 13);
  toBytes(6, 14, 18);
  toBytes(8, 19, 23);
  toBytes(10, 24, 36);
  return bytes;
}

// This implementation is faster than http:pub.dartlang.org/uuid
//   this one: Template(RunTime): 2101.890756302521 us.
//   pub uuid: Template(RunTime): 7402.2140221402215 us.
//

/// Unparses (converts [Uuid] to a [String]) a [bytes] of bytes and outputs a proper UUID string.
/// An optional [offset] is allowed if you want to start at a different point
/// in the buffer.
String _toUuidFormat(Uint8List bytes, [int offset = 0]) {
  var i = offset;
  return '${byteToHex[bytes[i++]]}${byteToHex[bytes[i++]]}'
      '${byteToHex[bytes[i++]]}${byteToHex[bytes[i++]]}-'
      '${byteToHex[bytes[i++]]}${byteToHex[bytes[i++]]}-'
      '${byteToHex[bytes[i++]]}${byteToHex[bytes[i++]]}-'
      '${byteToHex[bytes[i++]]}${byteToHex[bytes[i++]]}-'
      '${byteToHex[bytes[i++]]}${byteToHex[bytes[i++]]}'
      '${byteToHex[bytes[i++]]}${byteToHex[bytes[i++]]}'
      '${byteToHex[bytes[i++]]}${byteToHex[bytes[i++]]}';
}

String _toUidString(Uint8List bytes, [int offset = 0]) {
  StringBuffer sb = new StringBuffer();
  for (int i = offset; i < offset + 16; i++) sb.write(byteToHex[bytes[i]]);
  return sb.toString();
}

String toUid(Uint8List bytes, [int offset = 0]) =>
    _toUuidFormat(bytes).replaceAll('-', "");

// *** Generated by 'tools/generate_conversions.dart' ***

//TODO: reformat in 8 x 32 rows use // to avoid reformatting
/// Returns the Hex [String] equivalent to an 8-bit [int].
const List<String> byteToHex = const [
  // This comment prevents reformatting.
  "00", "01", "02", "03", "04", "05", "06", "07", "08",
  "09",
  "0a",
  "0b",
  "0c",
  "0d",
  "0e",
  "0f",
  "10",
  "11",
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

/// Returns the 8-bit [int] equivalent to the Hex [String].
const Map<String, int> hexToByte = const {
  "00": 0,
  "01": 1,
  "02": 2,
  "03": 3,
  "04": 4,
  "05": 5,
  "06": 6,
  "07": 7,
  "08": 8,
  "09": 9,
  "0a": 10,
  "0b": 11,
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
  "60": 96,
  "61": 97,
  "62": 98,
  "63": 99,
  "64": 100,
  "65": 101,
  "66": 102,
  "67": 103,
  "68": 104,
  "69": 105,
  "6a": 106,
  "6b": 107,
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
