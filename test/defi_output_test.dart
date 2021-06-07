import 'package:defichaindart/defichaindart.dart';
import 'package:defichaindart/src/defi.dart';
import 'package:hex/hex.dart';
import 'package:test/test.dart';

void main() {
  group("test defi output script", () {
    test("create AnyAccountToAccountOutput", () {
      var defiOutput = DefiTransactionHelper.createAnyAccountToAccountOutput(
          1, "teg1zqnGVqGKmu1WmZH7BPTL9CthbYBAYs", 100000000, "tXmZ6X4xvZdUdXVhUKJbzkcN2MNuwVSEWv", 100000000, defichain_testnet);
      var hexOut = HEX.encode(defiOutput.script!);

      expect(hexOut,
          "6a4c5144665478610117a9145c41c70349fd7ab79e2359bd0f0627d2d9bff8c287010100000000e1f505000000000117a9141084ef98bacfecbc9f140496b26516ae55d79bfa87010100000000e1f50500000000");
    });
    test("create AccountToAccountOutput", () {
      var defiOutput =
          DefiTransactionHelper.createAccountToAccountOuput(1, "teg1zqnGVqGKmu1WmZH7BPTL9CthbYBAYs", "tXmZ6X4xvZdUdXVhUKJbzkcN2MNuwVSEWv", 100000000, defichain_testnet);
      var hexOut = HEX.encode(defiOutput.script!);

      expect(hexOut, "6a43446654784217a9145c41c70349fd7ab79e2359bd0f0627d2d9bff8c2870117a9141084ef98bacfecbc9f140496b26516ae55d79bfa87010100000000e1f50500000000");
    });
    test("create accountToUtxos output", () {
      var defiOutput = DefiTransactionHelper.createAccountToUtxos(1, "teg1zqnGVqGKmu1WmZH7BPTL9CthbYBAYs", 1 * 1000000000, 0, defichain_testnet);
      var hexOut = HEX.encode(defiOutput.script!);

      expect(hexOut, "6a2b446654786217a9145c41c70349fd7ab79e2359bd0f0627d2d9bff8c287010100000000ca9a3b0000000000");
    });
    test("create utxosToAccount output", () {
      var defiOutput = DefiTransactionHelper.createUtxosToAccount(0, "teg1zqnGVqGKmu1WmZH7BPTL9CthbYBAYs", 1 * 100000000, defichain_testnet);
      var hexOut = HEX.encode(defiOutput.script!);

      expect(hexOut, "6a2b44665478550117a9145c41c70349fd7ab79e2359bd0f0627d2d9bff8c287010000000000e1f50500000000");
    });
    test("create addPoolLiquidity output", () {
      var defiOutput = DefiTransactionHelper.createAddPoolLiquidity(
          0, "tXmZ6X4xvZdUdXVhUKJbzkcN2MNuwVSEWv", 100000, 1, "tXmZ6X4xvZdUdXVhUKJbzkcN2MNuwVSEWv", 8160367226, "tXmZ6X4xvZdUdXVhUKJbzkcN2MNuwVSEWv", defichain_testnet);
      var hexOut = HEX.encode(defiOutput.script!);

      expect(hexOut,
          "6a4c68446654786c0217a9141084ef98bacfecbc9f140496b26516ae55d79bfa870100000000a08601000000000017a9141084ef98bacfecbc9f140496b26516ae55d79bfa8701010000007a5265e60100000017a9141084ef98bacfecbc9f140496b26516ae55d79bfa87");
    });

    test("create removePoolLiquidity output", () {
      var defiOutput = DefiTransactionHelper.createRemovePoolLiquidity("dVTLp4iqkp7P3fDf2PqtDKap21hGQaLMEa", 5, 38207852, defichain);
      var hexOut = HEX.encode(defiOutput.script!);

      expect(hexOut, "6a26446654787217a914afe582e10c94c932671ffc83e7e2280e4cd9a10687056c01470200000000");
    });
  });
}
