import 'dart:convert';
import 'dart:typed_data';

import 'package:defichaindart/src/utils/constants/op.dart';
import 'package:defichaindart/src/utils/bytedata_unit64_js.dart';
import 'package:defichaindart/src/utils/varuint.dart';
import 'package:hex/hex.dart';
import 'package:convert/convert.dart';
import 'utils/varuint.dart' as varuint;
import 'utils/compactuint.dart' as compactvaruint;

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
  static var PoolSwapV2 = 'i';
  static var AddPoolLiquidity = 'l';
  static var RemovePoolLiquidity = 'r';

  // accounts
  static var UtxosToAccount = 'U';
  static var AccountToUtxos = 'b';
  static var AccountToAccount = 'B';
  static var AnyAccountsToAccounts = 'a';
  static var SmartContract = 'K';

  //set governance variable
  static var SetGovVariable = 'G';

  // Auto auth TX
  static var AutoAuthPrep = 'A';

  static var ICX_CreateOrder = '1';
  static var ICX_MakeOffer = '2';
  static var ICX_Submit_DFC_HTLC = '3';
  static var ICX_Submit_EXT_HTLC = '4';
  static var ICX_Claim_DFC_HTLC = '5';
  static var ICX_CloseOrder = '6';
  static var ICX_CloseOffer = '7';

// Loans
  static var SetLoanCollateralToken = 'c';
  static var SetLoanToken = 'g';
  static var UpdateLoanToken = 'x';
  static var LoanScheme = 'L';
  static var DefaultLoanScheme = 'd';
  static var DestroyLoanScheme = 'D';
  static var Vault = 'V';
  static var CloseVault = 'e';
  static var UpdateVault = 'v';
  static var DepositToVault = 'S';
  static var WithdrawFromVault = 'J';
  static var TakeLoan = 'X';
  static var PaybackLoan = 'H';
  static var AuctionBid = 'I';
}

class DefiOutput extends OutputBase {
  DefiOutput(Uint8List script, int value) : super(script: script, value: value);
}

class DefiTransactionHelper {
  static var DefiTxHeader = const [0x44, 0x66, 0x54, 0x78];

  static List<int> _prepare(dynamic txType) {
    var script = List<int>.empty(growable: true);

    script.addAll(DefiTxHeader);
    if (txType is String) {
      if (txType.length > 1) {
        throw ArgumentError('txType cannot be longer than 1 char');
      }
      script.add(txType[0].codeUnitAt(0));
    } else {
      throw ArgumentError('txType is invalid!');
    }
    return script;
  }

  static Uint8List _postpare(Uint8List defiScript) {
    var cscript = List<int>.empty(growable: true);

    cscript.add(OPS['OP_RETURN']!);

    if (defiScript.length < OPS['OP_PUSHDATA1']!) {
      cscript.add(defiScript.length);
    } else if (defiScript.length <= 0xff) {
      cscript.add(OPS['OP_PUSHDATA1']!);
      cscript.add(defiScript.length);
    }

    cscript.addAll(defiScript);

    return Uint8List.fromList(cscript);
  }

  static DefiOutput smartContractOutput(dynamic token, dynamic from, int value,
      [NetworkType? nw]) {
    var script = _prepare(DefiTxTypes.SmartContract);

    script.addAll([0x08, 0x44, 0x46, 0x49, 0x50, 0x32, 0x32, 0x30, 0x31]);

    script.add(1); // add 1 account
    script.addAll(_addAccount(token, from, value, nw));

    var defiScript = Uint8List.fromList(script);

    return DefiOutput(_postpare(defiScript), 0);
  }

  static DefiOutput mintTokenOutput(dynamic tokenId, dynamic tokenAmount,
      [NetworkType? nw]) {
    var script = _prepare(DefiTxTypes.MintToken);

    script.addAll(_createBalance([tokenId], [tokenAmount]));

    var defiScript = Uint8List.fromList(script);

    return DefiOutput(_postpare(defiScript), 0);
  }

  static DefiOutput createIcxMakeOffer(String orderTx, dynamic amount,
      dynamic ownerAddress, dynamic receivePubKey, dynamic expiry) {
    var script = _prepare(DefiTxTypes.ICX_MakeOffer);

    script.addAll(HEX.decode(orderTx));

    var defiScript = Uint8List.fromList(script);
    return DefiOutput(_postpare(defiScript), 0);
  }

  static DefiOutput createVaultOutput(
      dynamic ownerAddress, dynamic schemeId, int vaultFees,
      [NetworkType? nw]) {
    var script = _prepare(DefiTxTypes.Vault);

    script.addAll(_createScript(ownerAddress, nw));

    var utf8 = _convertUtf8(schemeId);
    script.add(utf8.length);
    script.addAll(utf8);

    var defiScript = Uint8List.fromList(script);

    return DefiOutput(_postpare(defiScript), vaultFees);
  }

  static DefiOutput updateVaultOutput(
      dynamic vaultId, dynamic ownerAddress, dynamic schemeId,
      [NetworkType? nw]) {
    var script = _prepare(DefiTxTypes.UpdateVault);

    var hexDe = hex.decode(vaultId).reversed;
    script.addAll(hexDe);
    script.addAll(_createScript(ownerAddress, nw));
    var utf8 = _convertUtf8(schemeId);
    script.add(utf8.length);
    script.addAll(utf8);

    var defiScript = Uint8List.fromList(script);

    return DefiOutput(_postpare(defiScript), 0);
  }

  static DefiOutput depositToVaultOutput(
      dynamic vaultId, dynamic from, dynamic tokenId, dynamic tokenAmount,
      [NetworkType? nw]) {
    var script = _prepare(DefiTxTypes.DepositToVault);

    var hexDe = hex.decode(vaultId).reversed;
    script.addAll(hexDe);
    script.addAll(_createScript(from, nw));
    script.addAll(_createTokenBalance(tokenId, tokenAmount, nw));

    var defiScript = Uint8List.fromList(script);

    return DefiOutput(_postpare(defiScript), 0);
  }

  static DefiOutput withdrawFromVaultOutput(
      dynamic vaultId, dynamic to, dynamic tokenId, dynamic tokenAmount,
      [NetworkType? nw]) {
    var script = _prepare(DefiTxTypes.WithdrawFromVault);

    var hexDe = hex.decode(vaultId).reversed;
    script.addAll(hexDe);
    script.addAll(_createScript(to, nw));
    script.addAll(_createTokenBalance(tokenId, tokenAmount, nw));

    var defiScript = Uint8List.fromList(script);

    return DefiOutput(_postpare(defiScript), 0);
  }

  static DefiOutput takeLoanVaultOutput(
      dynamic vaultId, dynamic to, dynamic tokenId, dynamic tokenAmount,
      [NetworkType? nw]) {
    var script = _prepare(DefiTxTypes.TakeLoan);

    var hexDe = hex.decode(vaultId).reversed;
    script.addAll(hexDe);
    script.addAll(_createScript(to, nw));
    script.addAll(_createBalance([tokenId], [tokenAmount]));

    var defiScript = Uint8List.fromList(script);

    return DefiOutput(_postpare(defiScript), 0);
  }

  static DefiOutput paybackLoanVaultOutput(
      dynamic vaultId, dynamic from, dynamic tokenId, dynamic tokenAmount,
      [NetworkType? nw]) {
    var script = _prepare(DefiTxTypes.PaybackLoan);

    var hexDe = hex.decode(vaultId).reversed;
    script.addAll(hexDe);
    script.addAll(_createScript(from, nw));
    script.addAll(_createBalance([tokenId], [tokenAmount]));

    var defiScript = Uint8List.fromList(script);

    return DefiOutput(_postpare(defiScript), 0);
  }

  static DefiOutput closeVaultOutput(dynamic vaultId, dynamic to,
      [NetworkType? nw]) {
    var script = _prepare(DefiTxTypes.CloseVault);

    var hexDe = hex.decode(vaultId).reversed;
    script.addAll(hexDe);
    script.addAll(_createScript(to, nw));

    var defiScript = Uint8List.fromList(script);

    return DefiOutput(_postpare(defiScript), 0);
  }

  static DefiOutput placeAuctionBidOutput(
      String vaultId, int index, String from, int tokenId, int tokenAmount,
      [NetworkType? nw]) {
    var script = _prepare(DefiTxTypes.AuctionBid);

    var hexDe = hex.decode(vaultId).reversed;
    script.addAll(hexDe);
    script.addAll(_convertInt32(index));
    script.addAll(_createScript(from, nw));
    script.addAll(_createTokenBalance(tokenId, tokenAmount, nw));

    var defiScript = Uint8List.fromList(script);

    return DefiOutput(_postpare(defiScript), 0);
  }

  static DefiOutput createAccountToAccountOuput(
      dynamic token, dynamic from, dynamic to, int toValue,
      [NetworkType? nw]) {
    var script = _prepare(DefiTxTypes.AccountToAccount);

    script.addAll(_createScript(from, nw));
    script.add(1); // add 1 account
    script.addAll(_addAccount(token, to, toValue, nw));

    var defiScript = Uint8List.fromList(script);

    return DefiOutput(_postpare(defiScript), 0);
  }

  static DefiOutput createAnyAccountToAccountOutput(
      dynamic token, dynamic from, int fromValue, dynamic to, int toValue,
      [NetworkType? nw]) {
    var script = _prepare(DefiTxTypes.AnyAccountsToAccounts);

    script.add(1); // add 1 from account
    script.addAll(_addAccount(token, from, fromValue, nw));
    script.add(1); // add 1 to account
    script.addAll(_addAccount(token, to, toValue, nw));

    var defiScript = Uint8List.fromList(script);

    return DefiOutput(_postpare(defiScript), 0);
  }

  static DefiOutput createPoolSwapOutput(
      int fromToken,
      String from,
      int fromAmount,
      int toToken,
      String to,
      int maxPrice,
      int maxPricefraction,
      [NetworkType? nw]) {
    var script = _prepare(DefiTxTypes.PoolSwap);

    script.addAll(_createScript(from, nw));
    script.addAll(_convertCompactVarInt(fromToken));
    script.addAll(_convertInt64(fromAmount));

    script.addAll(_createScript(to, nw));
    script.addAll(_convertCompactVarInt(toToken));

    script.addAll(_convertInt64(maxPrice));
    script.addAll(_convertInt64(maxPricefraction));

    var defiScript = Uint8List.fromList(script);

    return DefiOutput(_postpare(defiScript), 0);
  }

  static DefiOutput createPoolSwapV2Output(
      int fromToken,
      String from,
      int fromAmount,
      int toToken,
      String to,
      int maxPrice,
      int maxPricefraction,
      List<int> poolIds,
      [NetworkType? nw]) {
    var script = _prepare(DefiTxTypes.PoolSwapV2);

    script.addAll(_createScript(from, nw));
    script.addAll(_convertCompactVarInt(fromToken));
    script.addAll(_convertInt64(fromAmount));

    script.addAll(_createScript(to, nw));
    script.addAll(_convertCompactVarInt(toToken));

    script.addAll(_convertUint64(maxPrice));
    script.addAll(_convertUint64(maxPricefraction));

    script.add(poolIds.length);
    for (var pool in poolIds) {
      script.addAll(_convertUint(pool));
    }

    var defiScript = Uint8List.fromList(script);

    return DefiOutput(_postpare(defiScript), 0);
  }

  static DefiOutput createAuthOutput() {
    var script = _prepare(DefiTxTypes.AutoAuthPrep);
    var defiScript = Uint8List.fromList(script);

    return DefiOutput(_postpare(defiScript), 0);
  }

  static DefiOutput createAddPoolLiquidity(
      int tokenA,
      String fromA,
      int fromAmountA,
      int tokenB,
      String fromB,
      int fromAmountB,
      String shareAddress,
      [NetworkType? nw]) {
    var script = _prepare(DefiTxTypes.AddPoolLiquidity);

    script.add(2);
    script.addAll(_addAccount(tokenA, fromA, fromAmountA, nw));
    script.addAll(_addAccount(tokenB, fromB, fromAmountB, nw));

    script.addAll(_createScript(shareAddress, nw));

    var defiScript = Uint8List.fromList(script);

    return DefiOutput(_postpare(defiScript), 0);
  }

  static DefiOutput createMessageOutput(String message, [NetworkType? nw]) {
    var script = utf8.encode(message);

    var defiScript = Uint8List.fromList(script);

    return DefiOutput(_postpare(defiScript), 0);
  }

  static DefiOutput createAddPoolLiquiditySingleAddress(String from, int tokenA,
      int fromAmountA, int tokenB, int fromAmountB, String shareAddress,
      [NetworkType? nw]) {
    var script = _prepare(DefiTxTypes.AddPoolLiquidity);

    script.add(1);
    script.addAll(_createScript(from, nw));
    script.addAll(_createBalance([tokenA, tokenB], [fromAmountA, fromAmountB]));

    script.addAll(_createScript(shareAddress, nw));

    var defiScript = Uint8List.fromList(script);

    return DefiOutput(_postpare(defiScript), 0);
  }

  static DefiOutput createRemovePoolLiquidity(String from, int token, int value,
      [NetworkType? nw]) {
    var script = _prepare(DefiTxTypes.RemovePoolLiquidity);

    script.addAll(_createScript(from, nw));

    script.addAll(_convertUint(token));
    script.addAll(_convertInt64(value));

    var defiScript = Uint8List.fromList(script);

    return DefiOutput(_postpare(defiScript), 0);
  }

  static DefiOutput createAccountToUtxos(
      dynamic token, dynamic from, int value, int mintingOutputsStart,
      [NetworkType? nw]) {
    var script = _prepare(DefiTxTypes.AccountToUtxos);

    script.addAll(_createScript(from, nw));
    script.addAll(_createBalance([token], [value]));
    script.add(mintingOutputsStart);

    var defiScript = Uint8List.fromList(script);

    return DefiOutput(_postpare(defiScript), 0);
  }

  static DefiOutput createUtxosToAccount(dynamic token, dynamic from, int value,
      [NetworkType? nw]) {
    var script = _prepare(DefiTxTypes.UtxosToAccount);

    script.add(1); // add 1 from account
    script.addAll(_addAccount(token, from, value, nw));

    var defiScript = Uint8List.fromList(script);

    return DefiOutput(_postpare(defiScript), value);
  }

  static Uint8List _createScript(dynamic address, NetworkType? nw) {
    var script = List<int>.empty(growable: true);
    var scriptPubKey = Address.addressToOutputScript(address, nw)!;
    script.add(scriptPubKey.length);
    script.addAll(scriptPubKey);

    return Uint8List.fromList(script);
  }

  static Uint8List _createTokenBalance(int token, int amount, NetworkType? nw) {
    var script = List<int>.empty(growable: true);
    script.addAll(_convertVarInt(token));
    script.addAll(_convertInt64(amount));

    return Uint8List.fromList(script);
  }

  static Uint8List _addAccount(
      dynamic token, dynamic address, int value, NetworkType? nw) {
    var script = List<int>.empty(growable: true);

    script.addAll(_createScript(address, nw));

    script.addAll(_createBalance([token], [value]));
    return Uint8List.fromList(script);
  }

  static Uint8List _createBalance(List<dynamic> token, List<int> value) {
    var script = List<int>.empty(growable: true);

    if (token.length != value.length) {
      throw ArgumentError('token and value list must have equal length');
    }

    script.add(token.length);
    for (var i = 0; i < token.length; i++) {
      // add token type
      script.addAll(_convertInt32(token[i]));
      // add token amount
      script.addAll(_convertInt64(value[i]));
    }

    return Uint8List.fromList(script);
  }

  static Uint8List _convertUint64(dynamic value) {
    // var second = value % 0x100000000;
    // var first = ((value - second) / 0x100000000).round();
    var buffer = Uint8List(8);

    var byteData = buffer.buffer.asByteData();
    // byteData.setUint32(0, second, Endian.little);
    // byteData.setUint32(4, first, Endian.little);

    writeUInt64LE(byteData, 0, value);
    return buffer;
  }

  static Uint8List _convertInt32(int value) {
    var buffer = Uint8List(4);
    var byteData = buffer.buffer.asByteData();
    byteData.setUint32(0, value, Endian.little);
    return buffer;
  }

  static Uint8List _convertVarInt(int value) {
    var buffer = Uint8List(varuint.encodingLength(value));
    varuint.encode(value, buffer, 0);
    return buffer;
  }

  static Uint8List _convertCompactVarInt(int value) {
    return compactvaruint.encode(value);
  }

  static Uint8List _convertUtf8(String value) {
    var utf = utf8.encode(value);
    return Uint8List.fromList(utf);
  }

  static Uint8List _convertUint(int value) {
    return encode(value);
  }

  static Uint8List _convertInt64(int value) {
    var buffer = Uint8List(8);
    var byteData = buffer.buffer.asByteData();
    byteData.setUint64Js(0, value, Endian.little);
    return buffer;
  }
}
