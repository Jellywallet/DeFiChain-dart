import 'dart:ffi';
import 'dart:typed_data';

import 'package:defichaindart/src/utils/constants/op.dart';

import '../defichaindart.dart';

class DefiTxTypes {
  static var CreateMasternode = 'C';
  static var ResignMasternode = 'R';

  // custom tokens:
  static var CreateToken = 'T';
  static var MintToken = 'M';
  static var UpdateToken = 'N'; // previous type, only DAT flag triggers
  static var UpdateTokenAny =
      'n'; // new type of token's update with any flags/fields possible

  // dex orders - just not to overlap in future
//    CreateOrder         = 'O',
//    DestroyOrder        = 'E',
//    MatchOrders         = 'A',
  //poolpair
  static var CreatePoolPair = 'p';
  static var UpdatePoolPair = 'u';
  static var PoolSwap = 's';
  static var AddPoolLiquidity = 'l';
  static var RemovePoolLiquidity = 'r';

  // accounts
  static var UtxosToAccount = 'U';
  static var AccountToUtxos = 'b';
  static var AccountToAccount = 'B';
  static var AnyAccountsToAccounts = 'a';

  //set governance variable
  static var SetGovVariable = 'G';

  // Auto auth TX
  static var AutoAuthPrep = 'A';
}

class DefiOutput extends OutputBase {
  DefiOutput(Uint8List script) : super(script: script, value: 0);
}

class DefiTransactionHelper {
  static var DefiTxHeader = const [0x44, 0x66, 0x54, 0x78];

  static List<int> _prepare(dynamic txType) {
    var script = List<int>.empty(growable: true);

    script.addAll(DefiTxHeader);
    if (txType is String) {
      if (txType.length > 1) {
        throw ArgumentError("txType cannot be longer than 1 char");
      }
      script.add(txType[0].codeUnitAt(0));
    } else {
      throw ArgumentError("txType is invalid!");
    }
    return script;
  }

  static Uint8List _postpare(Uint8List defiScript) {
    var cscript = new List<int>.empty(growable: true);

    cscript.add(OPS["OP_RETURN"]);

    if (defiScript.length < OPS["OP_PUSHDATA1"]) {
      cscript.add(defiScript.length);
    } else if (defiScript.length <= 0xff) {
      cscript.add(OPS["OP_PUSHDATA1"]);
      cscript.add(defiScript.length);
    }

    cscript.addAll(defiScript);

    return Uint8List.fromList(cscript);
  }

  static DefiOutput createAccountToAccountOuput(
      dynamic token, dynamic from, dynamic to, int toValue,
      [NetworkType nw]) {
    var script = _prepare(DefiTxTypes.AccountToAccount);

    script.addAll(_createScript(from, nw));
    script.addAll(_createAccount(token, to, toValue, nw));

    var defiScript = Uint8List.fromList(script);

    return DefiOutput(_postpare(defiScript));
  }

  static DefiOutput createAnyAccountToAccountOutput(
      dynamic token, dynamic from, int fromValue, dynamic to, int toValue,
      [NetworkType nw]) {
    var script = _prepare(DefiTxTypes.AnyAccountsToAccounts);

    script.addAll(_createAccount(token, from, fromValue, nw));
    script.addAll(_createAccount(token, to, toValue, nw));

    var defiScript = Uint8List.fromList(script);

    return DefiOutput(_postpare(defiScript));
  }

  static Uint8List _createScript(dynamic address, NetworkType nw) {
    var script = List<int>.empty(growable: true);
    var scriptPubKey = Address.addressToOutputScript(address, nw);
    script.add(scriptPubKey.length);
    script.addAll(scriptPubKey);

    return Uint8List.fromList(script);
  }

  static Uint8List _createAccount(
      dynamic token, dynamic address, int value, NetworkType nw) {
    var script = List<int>.empty(growable: true);
    //add accounts - for now we only allow 1
    script.add(1);
    script.addAll(_createScript(address, nw));

    //add defi balance - for now we only allow 1
    script.add(1);
    // add token type
    script.addAll(_convertInt32(token));
    // add token amount
    script.addAll(_convertInt64(value));

    return Uint8List.fromList(script);
  }

  static Uint8List _convertInt32(int value) {
    var buffer = Uint8List(4);
    var byteData = buffer.buffer.asByteData();
    byteData.setUint32(0, value, Endian.little);
    return buffer;
  }

  static Uint8List _convertInt64(int value) {
    var buffer = Uint8List(8);
    var byteData = buffer.buffer.asByteData();
    byteData.setUint64(0, value, Endian.little);
    return buffer;
  }
}
