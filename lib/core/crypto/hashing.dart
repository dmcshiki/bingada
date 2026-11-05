/// Hashing and a portable 32-bit PRNG, bit-identical on the Dart VM and web.
library;

import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

const int _mask32 = 0xFFFFFFFF;

/// sha256 of the utf8 bytes of [input].
List<int> sha256Bytes(String input) => sha256.convert(utf8.encode(input)).bytes;

/// Hex sha256 of the utf8 bytes of [input].
String sha256Hex(String input) => sha256.convert(utf8.encode(input)).toString();

/// First 4 bytes of [bytes] as big-endian uint32.
int uint32BE(List<int> bytes) =>
    ((bytes[0] * 0x1000000) + (bytes[1] << 16) + (bytes[2] << 8) + bytes[3]) &
    _mask32;

/// First 4 bytes of the hex string [hex] as big-endian uint32.
int uint32FromHex(String hex) => int.parse(hex.substring(0, 8), radix: 16);

/// Lowercase hex of [bytes].
String toHex(List<int> bytes) =>
    [for (final b in bytes) b.toRadixString(16).padLeft(2, '0')].join();

/// 32-bit multiply (like JS `Math.imul`, unsigned result) using 16-bit halves
/// so no intermediate exceeds 2^53.
int imul32(int a, int b) {
  final al = a & 0xFFFF;
  final ah = (a >> 16) & 0xFFFF;
  final bl = b & 0xFFFF;
  final bh = (b >> 16) & 0xFFFF;
  final lo = al * bl;
  final mid = ((ah * bl + al * bh) & 0xFFFF) * 0x10000;
  return (lo + mid) & _mask32;
}

int _shr(int x, int n) => (x & _mask32) >> n;

/// mulberry32 PRNG producing uint32 values.
final class Mulberry32 {
  Mulberry32(int seed) : _state = seed & _mask32;

  int _state;

  int next() {
    _state = (_state + 0x6D2B79F5) & _mask32;
    var t = _state;
    t = imul32(t ^ _shr(t, 15), t | 1);
    t = (t ^ ((t + imul32(t ^ _shr(t, 7), t | 61)) & _mask32)) & _mask32;
    return (t ^ _shr(t, 14)) & _mask32;
  }
}

/// Unused-bytes helper kept typed for callers that need raw bytes.
Uint8List hexToBytes(String hex) => Uint8List.fromList([
  for (var i = 0; i < hex.length; i += 2)
    int.parse(hex.substring(i, i + 2), radix: 16),
]);
