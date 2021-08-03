import 'dart:typed_data';

// Le costille for dart2js
extension Uint64Js on ByteData {
  void setUint64Js(int byteOffset, int value, [Endian endian = Endian.big]) {
    var highBits = value >> 32;
    var lowBits = value & 0xFFFFFFFF;

    if (endian == Endian.big) {
      setUint32(byteOffset, highBits, endian);
      setUint32(byteOffset + 4, lowBits, endian);
    } else {
      setUint32(byteOffset, lowBits, endian);
      setUint32(byteOffset + 4, highBits, endian);
    }
  }
}
