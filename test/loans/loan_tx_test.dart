import 'package:defichaindart/src/defi.dart';
import 'package:test/test.dart';
import 'package:defichaindart/src/models/networks.dart' as networks;
import 'package:hex/hex.dart';

void main() {
  group('Loans', () {
    test('add collat to vaul', () {
      var out = DefiTransactionHelper.depositToVaultOutput(
          'ed59b0558f03d547819c1990bfbade53656170e2c311d9b8b418a6a74ae4c2ae', 'bcrt1q3r2jhxcammvnyfewpjd7hvxueh2xanuere5q3e', 0, 10000, networks.defichain_regtest);

      var hex = HEX.encode(out.script!);

      expect(hex, "6a454466547853aec2e44aa7a618b4b8d911c3e270616553debabf90199c8147d5038f55b059ed16001488d52b9b1dded932272e0c9bebb0dccdd46ecf99001027000000000000");
    });
  });
}
