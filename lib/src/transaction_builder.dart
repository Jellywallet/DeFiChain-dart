import 'dart:typed_data';
import 'package:defichaindart/src/defi.dart';
import 'package:defichaindart/src/saiive.dart';
import 'package:meta/meta.dart';
import 'package:hex/hex.dart';
import 'defi.dart';
import 'utils/script.dart' as bscript;
import 'ecpair.dart';
import 'models/networks.dart';
import 'transaction.dart';
import 'address.dart';
import 'payments/index.dart' show PaymentData;
import 'payments/p2pkh.dart';
import 'payments/p2wpkh.dart';
import 'payments/p2sh.dart';
import 'classify.dart';

class TransactionBuilder {
  NetworkType? network;
  int? maximumFeeRate;
  List<Input>? _inputs;
  Transaction? _tx;
  final Map _prevTxSet = {};

  TransactionBuilder({NetworkType? network, int? maximumFeeRate}) {
    this.network = network ?? bitcoin;
    this.maximumFeeRate = maximumFeeRate ?? 2500;
    _inputs = [];
    _tx = Transaction();
    _tx!.version = 2;
  }

  List<Input>? get inputs => _inputs;

  factory TransactionBuilder.fromTransaction(Transaction transaction, [NetworkType? network]) {
    final txb = TransactionBuilder(network: network);
    // Copy transaction fields
    txb.setVersion(transaction.version!);
    txb.setLockTime(transaction.locktime!);

    // Copy outputs (done first to avoid signature invalidation)
    transaction.outs.forEach((txOut) {
      txb.addOutput(txOut.script, txOut.value);
    });

    transaction.ins.forEach((txIn) {
      txb._addInputUnsafe(txIn.hash!, txIn.index, Input(sequence: txIn.sequence, script: txIn.script, witness: txIn.witness));
    });

    // fix some things not possible through the public API
    // print(txb.toString());
    // txb.__INPUTS.forEach((input, i) => {
    //   fixMultisigOrder(input, transaction, i);
    // });

    return txb;
  }

  void setVersion(int version) {
    if (version < 0 || version > 0xFFFFFFFF) {
      throw ArgumentError('Expected Uint32');
    }
    _tx!.version = version;
  }

  bool setLockTime(int locktime) {
    if (locktime < 0 || locktime > 0xFFFFFFFF) {
      throw ArgumentError('Expected Uint32');
    }
    // if any signatures exist, throw
    if (_inputs!.map((input) {
      if (input.signatures == null) return false;
      return input.signatures!.map((s) {
        return s != null;
      }).contains(true);
    }).contains(true)) {
      throw ArgumentError('No, this would invalidate signatures');
    }
    _tx!.locktime = locktime;
    return true;
  }

  int addOutput(dynamic data, int? value) {
    var scriptPubKey;
    if (data is String) {
      scriptPubKey = Address.addressToOutputScript(data, network);
    } else if (data is Uint8List) {
      scriptPubKey = data;
    } else {
      throw ArgumentError('Address invalid');
    }
    if (!_canModifyOutputs()) {
      throw ArgumentError('No, this would invalidate signatures');
    }
    return _tx!.addOutput(scriptPubKey, value);
  }

  int addOutputAt(dynamic data, int value, int at) {
    var scriptPubKey;
    if (data is String) {
      scriptPubKey = Address.addressToOutputScript(data, network);
    } else if (data is Uint8List) {
      scriptPubKey = data;
    } else {
      throw ArgumentError('Address invalid');
    }
    if (!_canModifyOutputs()) {
      throw ArgumentError('No, this would invalidate signatures');
    }
    return _tx!.addOutputAt(scriptPubKey, value, at);
  }

  int addAnyAccountToAccountOutput(dynamic token, dynamic from, int fromValue, dynamic to, int toValue) {
    return _tx!.addBaseOutput(DefiTransactionHelper.createAnyAccountToAccountOutput(token, from, fromValue, to, toValue, network));
  }

  int addAuthOutput({int outputIndex = -1}) {
    if (outputIndex < 0) {
      return _tx!.addBaseOutput(DefiTransactionHelper.createAuthOutput());
    }
    return _tx!.addBaseOutputAt(DefiTransactionHelper.createAuthOutput(), outputIndex);
  }

  int addAddLiquidityOutput(int tokenA, String fromA, int fromAmountA, int tokenB, String fromB, int fromAmountB, String shareAddress) {
    return _tx!.addBaseOutputAt(DefiTransactionHelper.createAddPoolLiquidity(tokenA, fromA, fromAmountA, tokenB, fromB, fromAmountB, shareAddress, network), 0);
  }

  int addAddLiquidityOutputSingleAddress(String from, int tokenA, int fromAmountA, int tokenB, int fromAmountB, String shareAddress) {
    return _tx!.addBaseOutputAt(DefiTransactionHelper.createAddPoolLiquiditySingleAddress(from, tokenA, fromAmountA, tokenB, fromAmountB, shareAddress, network), 0);
  }

  int addRemoveLiquidityOutput(int token, int amount, String shareAddress) {
    return _tx!.addBaseOutputAt(DefiTransactionHelper.createRemovePoolLiquidity(shareAddress, token, amount, network), 0);
  }

  int addAccountToAccountOutput(dynamic token, dynamic from, dynamic to, int toValue) {
    return _tx!.addBaseOutput(DefiTransactionHelper.createAccountToAccountOuput(token, from, to, toValue, network));
  }

  int addAccountToAccountOutputAt(dynamic token, dynamic from, dynamic to, int toValue, int at) {
    return _tx!.addBaseOutputAt(DefiTransactionHelper.createAccountToAccountOuput(token, from, to, toValue, network), at);
  }

  int addAccountToUtxoOutput(dynamic token, dynamic from, int value, int mintStartintAt) {
    _tx!.addBaseOutputAt(DefiTransactionHelper.createAccountToUtxos(token, from, value, mintStartintAt, network), 0);
    return 0;
  }

  int addUtxosToAccountOutput(dynamic token, dynamic from, int value, [NetworkType? nw]) {
    _tx!.addBaseOutputAt(DefiTransactionHelper.createUtxosToAccount(token, from, value, nw), 0);
    return 0;
  }

  int addSwapOutput(dynamic fromToken, dynamic from, int fromAmount, dynamic toToken, dynamic to, int maxPrice, int maxPricefraction) {
    _tx!.addBaseOutputAt(DefiTransactionHelper.createPoolSwapOutput(fromToken, from, fromAmount, toToken, to, maxPrice, maxPricefraction, network), 0);
    return 0;
  }

  int addSwapV2Output(dynamic fromToken, dynamic from, int fromAmount, dynamic toToken, dynamic to, int maxPrice, int maxPricefraction, List<int> poolIds) {
    _tx!.addBaseOutputAt(DefiTransactionHelper.createPoolSwapV2Output(fromToken, from, fromAmount, toToken, to, maxPrice, maxPricefraction, poolIds, network), 0);
    return 0;
  }

  int addCloseVault(dynamic vaultId, dynamic to) {
    _tx!.addBaseOutputAt(DefiTransactionHelper.closeVaultOutput(vaultId, to, network), 0);
    return 0;
  }

  int addCreateVault(dynamic ownerAddress, dynamic schemeId, int vaultFees) {
    _tx!.addBaseOutputAt(DefiTransactionHelper.createVaultOutput(ownerAddress, schemeId, vaultFees, network), 0);
    return 0;
  }

  int addUpdateVault(dynamic vaultId, dynamic ownerAddress, dynamic schemeId) {
    _tx!.addBaseOutputAt(DefiTransactionHelper.updateVaultOutput(vaultId, ownerAddress, schemeId, network), 0);
    return 0;
  }

  int addDepositToVault(dynamic vaultId, dynamic from, dynamic tokenId, dynamic tokenAmount) {
    _tx!.addBaseOutputAt(DefiTransactionHelper.depositToVaultOutput(vaultId, from, tokenId, tokenAmount, network), 0);
    return 0;
  }

  int addWithdrawToVault(dynamic vaultId, dynamic to, dynamic tokenId, dynamic tokenAmount) {
    _tx!.addBaseOutputAt(DefiTransactionHelper.withdrawFromVaultOutput(vaultId, to, tokenId, tokenAmount, network), 0);
    return 0;
  }

  int addTakeLoan(dynamic vaultId, dynamic to, dynamic tokenId, dynamic tokenAmount) {
    _tx!.addBaseOutputAt(DefiTransactionHelper.takeLoanVaultOutput(vaultId, to, tokenId, tokenAmount, network), 0);
    return 0;
  }

  int addPaybackLoan(dynamic vaultId, dynamic from, dynamic tokenId, dynamic tokenAmount) {
    _tx!.addBaseOutputAt(DefiTransactionHelper.paybackLoanVaultOutput(vaultId, from, tokenId, tokenAmount, network), 0);
    return 0;
  }

  int addPlaceAuctionBid(String vaultId, int index, String from, int tokenId, int tokenAmount) {
    _tx!.addBaseOutputAt(DefiTransactionHelper.placeAuctionBidOutput(vaultId, index, from, tokenId, tokenAmount, network), 0);
    return 0;
  }

  int addMintToken(dynamic tokenId, dynamic tokenAmount) {
    _tx!.addBaseOutputAt(DefiTransactionHelper.mintTokenOutput(tokenId, tokenAmount, network), 0);
    return 0;
  }

  int addSmartContractOutput(int token, dynamic from, int value) {
    return _tx!.addBaseOutputAt(DefiTransactionHelper.smartContractOutput(token, from, value, network), 0);
  }

  int addSaiiveExportOutput() {
    _tx!.addBaseOutputAt(SaiiveTransactionHelper.createExportOutput(), 0);
    return 0;
  }

  int addMessageOutput(String message) {
    return _tx!.addBaseOutput(DefiTransactionHelper.createMessageOutput(message));
  }

  int addInput(dynamic txHash, int? vout, [int? sequence, Uint8List? prevOutScript]) {
    if (!_canModifyInputs()) {
      throw ArgumentError('No, this would invalidate signatures');
    }
    Uint8List hash;
    var value;
    if (txHash is String) {
      hash = Uint8List.fromList(HEX.decode(txHash).reversed.toList());
    } else if (txHash is Uint8List) {
      hash = txHash;
    } else if (txHash is Transaction) {
      final txOut = txHash.outs[vout!];
      prevOutScript = txOut.script;
      value = txOut.value;
      hash = txHash.getHash();
    } else {
      throw ArgumentError('txHash invalid');
    }
    return _addInputUnsafe(hash, vout, Input(sequence: sequence, prevOutScript: prevOutScript, value: value));
  }

  dynamic sign({required int vin, required ECPair keyPair, String? prevOutScriptType, Uint8List? redeemScript, int? witnessValue, Uint8List? witnessScript, int? hashType}) {
    // TODO checkSignArgs
    if (keyPair.network != null && keyPair.network.toString().compareTo(network.toString()) != 0) {
      throw ArgumentError('Inconsistent network');
    }
    if (vin >= _inputs!.length) throw ArgumentError('No input at index: $vin');
    hashType = hashType ?? SIGHASH_ALL;
    if (_needsOutputs(hashType)) {
      throw ArgumentError('Transaction needs outputs');
    }
    final input = _inputs![vin];
    final ourPubKey = keyPair.publicKey;

    var signatureHash = prepareSign(
        pubKey: ourPubKey!,
        vin: vin,
        hashType: hashType,
        prevOutScriptType: prevOutScriptType,
        redeemScript: redeemScript,
        witnessScript: witnessScript,
        witnessValue: witnessValue);

    // enforce in order signing of public keys
    var signed = false;
    for (var i = 0; i < input.pubkeys!.length; i++) {
      if (HEX.encode(ourPubKey!).compareTo(HEX.encode(input.pubkeys![i]!)) != 0) {
        continue;
      }
      if (input.signatures![i] != null) {
        throw ArgumentError('Signature already exists');
      }
      final signature = keyPair.sign(signatureHash);
      input.signatures![i] = bscript.encodeSignature(signature, hashType);
      signed = true;
    }
    if (!signed) throw ArgumentError('Key pair cannot sign for this input');
  }

  Uint8List prepareSign(
      {required int vin, required Uint8List pubKey, String? prevOutScriptType, Uint8List? redeemScript, int? witnessValue, Uint8List? witnessScript, int? hashType}) {
    if (vin >= _inputs!.length) throw ArgumentError('No input at index: $vin');
    hashType = hashType ?? SIGHASH_ALL;
    if (_needsOutputs(hashType)) {
      throw ArgumentError('Transaction needs outputs');
    }
    final input = _inputs![vin];
    final ourPubKey = pubKey;

    // if redeemScript was previously provided, enforce consistency
    if (input.redeemScript != null && redeemScript != null && input.redeemScript.toString() != redeemScript.toString()) {
      throw ArgumentError('Inconsistent redeemScript');
    }

    if (!_canSign(input)) {
      if (witnessValue != null) {
        if (input.value != null && input.value != witnessValue) {
          throw ArgumentError('Input did not match witnessValue');
        }
        input.value = witnessValue;
      }
      if (redeemScript != null && witnessScript != null) {
        // TODO p2wsh
      }
      if (redeemScript != null) {
        final p2sh = P2SH(data: PaymentData(redeem: PaymentData(output: redeemScript)), network: network);
        if (input.prevOutScript != null) {
          // TODO check
        }
        final expanded = OutputBase.expandOutput(p2sh.data!.redeem!.output, ourPubKey);

        if (expanded.pubkeys == null) {
          throw ArgumentError(
            '${expanded.type} not supported as redeemScript (${bscript.toASM(redeemScript)})',
          );
        }

        if (input.signatures != null && input.signatures!.any((x) => x != null)) {
          expanded.signatures = input.signatures;
        }

        Uint8List? signScript = redeemScript;
        if (expanded.type == SCRIPT_TYPES['P2WPKH']) {
          signScript = P2PKH(data: PaymentData(pubkey: expanded.pubkeys![0]), network: network).data!.output;
        }
        input.redeemScript = redeemScript;
        input.redeemScriptType = expanded.type;
        input.prevOutType = SCRIPT_TYPES['P2SH'];
        input.prevOutScript = p2sh.data!.output;
        input.hasWitness = (expanded.type == SCRIPT_TYPES['P2WPKH']);
        input.signScript = signScript;
        input.signType = expanded.type;
        input.pubkeys = expanded.pubkeys;
        input.signatures = expanded.signatures;
        input.maxSignatures = expanded.maxSignatures;
      }
      if (witnessScript != null) {
        // TODO
      }
      if (input.prevOutScript != null && input.prevOutType != null) {
        var type = classifyOutput(input.prevOutScript!);
        if (type == SCRIPT_TYPES['P2WPKH']) {
          input.prevOutType = SCRIPT_TYPES['P2WPKH'];
          input.hasWitness = true;
          input.signatures = [null];
          input.pubkeys = [ourPubKey];
          input.signScript = P2PKH(data: PaymentData(pubkey: ourPubKey), network: network).data!.output;
        } else if (type == SCRIPT_TYPES['P2PKH']) {
          var prevOutScript = pubkeyToOutputScript(ourPubKey);
          input.prevOutType = SCRIPT_TYPES['P2PKH'];
          input.signatures = [null];
          input.pubkeys = [ourPubKey];
          input.signScript = prevOutScript;
        } else {
          // TODO other type
        }
      } else {
        var prevOutScript = pubkeyToOutputScript(ourPubKey);
        input.prevOutType = SCRIPT_TYPES['P2PKH'];
        input.signatures = [null];
        input.pubkeys = [ourPubKey];
        input.signScript = prevOutScript;
      }
    }
    var signatureHash;
    if (input.hasWitness!) {
      signatureHash = _tx!.hashForWitnessV0(vin, input.signScript!, input.value!, hashType);
    } else {
      signatureHash = _tx!.hashForSignature(vin, input.signScript, hashType);
    }
    return signatureHash;
  }

  dynamic setSignature(
      {required int vin,
      required Uint8List signature,
      required Uint8List pubKey,
      String? prevOutScriptType,
      Uint8List? redeemScript,
      int? witnessValue,
      Uint8List? witnessScript,
      int? hashType}) {
    prepareSign(
        pubKey: pubKey, vin: vin, hashType: hashType, prevOutScriptType: prevOutScriptType, redeemScript: redeemScript, witnessScript: witnessScript, witnessValue: witnessValue);
    final input = _inputs![vin];
    var signed = false;
    hashType = hashType ?? SIGHASH_ALL;

    for (var i = 0; i < input.pubkeys!.length; i++) {
      if (HEX.encode(pubKey!).compareTo(HEX.encode(input.pubkeys![i]!)) != 0) {
        continue;
      }
      if (input.signatures![i] != null) {
        throw ArgumentError('Signature already exists');
      }
      input.signatures![i] = bscript.encodeSignature(signature, hashType);
      signed = true;
    }
    if (!signed) throw ArgumentError('Key pair cannot sign for this input');
  }

  Transaction _build(bool allowIncomplete) {
    if (!allowIncomplete) {
      if (_tx!.ins.isEmpty) throw ArgumentError('Transaction has no inputs');
      if (_tx!.outs.isEmpty) {
        throw ArgumentError('Transaction has no outputs');
      }
    }

    final tx = Transaction.clone(_tx!);

    for (var i = 0; i < _inputs!.length; i++) {
      final input = _inputs![i];
      if (input.pubkeys != null && input.signatures != null && input.pubkeys!.isNotEmpty && input.signatures!.isNotEmpty) {
        final result = buildByType(input.prevOutType, input, allowIncomplete, network);
        if (result == null) {
          if (!allowIncomplete && input.prevOutType == SCRIPT_TYPES['NONSTANDARD']) {
            throw ArgumentError('Unknown input type');
          }
          if (!allowIncomplete) {
            throw ArgumentError('Not enough information');
          }
          continue;
        }

        tx.setInputScript(i, result.input);
        tx.setWitness(i, result.witness);
      } else if (!allowIncomplete) {
        throw ArgumentError('Transaction is not complete');
      }
    }

    if (!allowIncomplete) {
      // do not rely on this, its merely a last resort
      if (_overMaximumFees(tx.virtualSize())!) {
        throw ArgumentError('Transaction has absurd fees');
      }
    }

    return tx;
  }

  Transaction build() {
    return _build(false);
  }

  Transaction buildIncomplete() {
    return _build(true);
  }

  bool? _overMaximumFees(int bytes) {
    var incoming = _inputs!.fold(0, (dynamic cur, acc) => cur + (acc.value ?? 0));
    var outgoing = _tx!.outs.fold(0, (dynamic cur, acc) => cur + (acc.value ?? 0));
    var fee = incoming - outgoing;
    var feeRate = fee ~/ bytes;
    return feeRate > maximumFeeRate;
  }

  bool _canModifyInputs() {
    return _inputs!.every((input) {
      if (input.signatures == null) return true;
      return input.signatures!.every((signature) {
        if (signature == null) return true;
        return _signatureHashType(signature) & SIGHASH_ANYONECANPAY != 0;
      });
    });
  }

  bool _canModifyOutputs() {
    final nInputs = _tx!.ins.length;
    final nOutputs = _tx!.outs.length;
    return _inputs!.every((input) {
      if (input.signatures == null) return true;
      return input.signatures!.every((signature) {
        if (signature == null) return true;
        final hashType = _signatureHashType(signature);
        final hashTypeMod = hashType & 0x1f;
        if (hashTypeMod == SIGHASH_NONE) return true;
        if (hashTypeMod == SIGHASH_SINGLE) {
          // if SIGHASH_SINGLE is set, and nInputs > nOutputs
          // some signatures would be invalidated by the addition
          // of more outputs
          return nInputs <= nOutputs;
        }
        return false;
      });
    });
  }

  bool _needsOutputs(int signingHashType) {
    if (signingHashType == SIGHASH_ALL) {
      return _tx!.outs.isEmpty;
    }
    // if inputs are being signed with SIGHASH_NONE, we don't strictly need outputs
    // .build() will fail, but .buildIncomplete() is OK
    return (_tx!.outs.isEmpty) &&
        _inputs!.map((input) {
          if (input.signatures == null || input.signatures!.isEmpty) {
            return false;
          }
          return input.signatures!.map((signature) {
            if (signature == null) return false; // no signature, no issue
            final hashType = _signatureHashType(signature);
            if (hashType & SIGHASH_NONE != 0) {
              return false;
            } // SIGHASH_NONE doesn't care about outputs
            return true; // SIGHASH_* does care
          }).contains(true);
        }).contains(true);
  }

  bool _canSign(Input input) {
    return input.signScript != null &&
        // input.signType != null &&
        input.pubkeys != null &&
        input.signatures != null &&
        input.signatures!.length == input.pubkeys!.length &&
        input.pubkeys!.isNotEmpty &&
        (input.hasWitness == false || input.value != null);
  }

  int _addInputUnsafe(Uint8List hash, int? vout, Input options) {
    var txHash = HEX.encode(hash);
    Input input;
    if (isCoinbaseHash(hash)) {
      throw ArgumentError('coinbase inputs not supported');
    }
    final prevTxOut = '$txHash:$vout';
    if (_prevTxSet[prevTxOut] != null) {
      throw ArgumentError('Duplicate TxOut: ' + prevTxOut);
    }

    // if an input value was given, retain it
    if (options.script != null) {
      input = Input.expandInput(options.script!, options.witness ?? EMPTY_WITNESS);
    } else {
      input = Input();
    }

    // derive what we can from the previous transactions output script
    if (options.value != null) input.value = options.value;
    if (input.prevOutScript == null && options.prevOutScript != null) {
      if (input.pubkeys == null && input.signatures == null) {
        var expanded = OutputBase.expandOutput(options.prevOutScript);
        if (expanded.pubkeys != null && expanded.pubkeys!.isNotEmpty) {
          input.pubkeys = expanded.pubkeys;
          input.signatures = expanded.signatures;
        }
      }
      input.prevOutScript = options.prevOutScript;
      input.prevOutType = classifyOutput(options.prevOutScript!);
    }
    var vin = _tx!.addInput(hash, vout, options.sequence, options.script);
    _inputs!.add(input);
    _prevTxSet[prevTxOut] = true;
    return vin;
  }

  int _signatureHashType(Uint8List buffer) {
    return buffer.buffer.asByteData().getUint8(buffer.length - 1);
  }

  Transaction? get tx => _tx;

  Map get prevTxSet => _prevTxSet;
}

PaymentData? buildByType(String? type, Input input, bool allowIncomplete, NetworkType? network) {
  if (type == SCRIPT_TYPES['P2PKH']) {
    return P2PKH(data: PaymentData(pubkey: input.pubkeys![0], signature: input.signatures![0]), network: network).data;
  } else if (type == SCRIPT_TYPES['P2WPKH']) {
    return P2WPKH(data: PaymentData(pubkey: input.pubkeys![0], signature: input.signatures![0]), network: network).data;
  } else if (type == SCRIPT_TYPES['P2SH']) {
    final redeem = buildByType(input.redeemScriptType, input, allowIncomplete, network);

    if (redeem == null) {
      return null;
    }
    return P2SH(
            data: PaymentData(
                redeem: PaymentData(
              output: redeem.output ?? input.redeemScript,
              input: redeem.input,
              witness: redeem.witness,
            )),
            network: network)
        .data;
  }
  return null;
}

Uint8List? pubkeyToOutputScript(Uint8List? pubkey, [NetworkType? nw]) {
  var network = nw ?? bitcoin;
  var p2pkh = P2PKH(data: PaymentData(pubkey: pubkey), network: network);
  return p2pkh.data!.output;
}
