import 'dart:typed_data';

extension Uint64Js on ByteData {
  void setUint64Js(int byteOffset, int value, [Endian endian = Endian.big]) {
    final tmp = BigInt.from(value);
    final b = Uint8List(8);
    for (var i = 0; i < b.length; i++) {
      b[i] = (tmp >> (i * 8)).toUnsigned(8).toInt();
    }

    if (endian == Endian.little) {
      for (var i = 0; i < b.length; i++) {
        setInt8(byteOffset, b[i]);
        byteOffset++;
      }
    } else {
      for (var i = b.length - 1; i >= 0; i--) {
        setInt8(byteOffset, b[i]);
        byteOffset++;
      }
    }
  }
}
