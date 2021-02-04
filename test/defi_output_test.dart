import 'package:defichaindart/defichaindart.dart';
import 'package:defichaindart/src/defi.dart';
import 'package:hex/hex.dart';
import 'package:test/test.dart';

void main() {
  group("test defi output script", () {
    test("createAnyAccountToAccountOutput", () {
      var defiOutput = DefiTransactionHelper.createAnyAccountToAccountOutput(
          1,
          "teg1zqnGVqGKmu1WmZH7BPTL9CthbYBAYs",
          100000000,
          "tXmZ6X4xvZdUdXVhUKJbzkcN2MNuwVSEWv",
          100000000,
          defichain_testnet);
      var hexOut = HEX.encode(defiOutput.script);

      expect(hexOut,
          "6a4c5144665478610117a9145c41c70349fd7ab79e2359bd0f0627d2d9bff8c287010100000000e1f505000000000117a9141084ef98bacfecbc9f140496b26516ae55d79bfa87010100000000e1f50500000000");
    });
    test("createAccountToAccountOutput", () {
      var defiOutput = DefiTransactionHelper.createAccountToAccountOuput(
          1,
          "teg1zqnGVqGKmu1WmZH7BPTL9CthbYBAYs",
          "tXmZ6X4xvZdUdXVhUKJbzkcN2MNuwVSEWv",
          100000000,
          defichain_testnet);
      var hexOut = HEX.encode(defiOutput.script);

      expect(hexOut,
          "6a43446654784217a9145c41c70349fd7ab79e2359bd0f0627d2d9bff8c2870117a9141084ef98bacfecbc9f140496b26516ae55d79bfa87010100000000e1f50500000000");
    });
  });
}
