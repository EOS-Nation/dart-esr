import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

//import from eosdart
import 'package:dart_esr/eosdart/src/eosdart_base.dart';
import 'package:dart_esr/eosdart/src/serialize.dart' as ser;

import 'package:dart_esr/eosdart/src/models/abi.dart';
import 'package:dart_esr/eosdart/src/models/action.dart';
import 'package:dart_esr/eosdart/src/models/block.dart';
import 'package:dart_esr/eosdart/src/models/node_info.dart';
import 'package:dart_esr/eosdart/src/models/transaction.dart';
//

/// EOSClient calls APIs against given EOS nodes
class EOSSerializeUtils {
  EOSNode eosNode;
  int expirationInSec;

  EOSSerializeUtils(String nodeURL, String nodeVersion,
      {this.expirationInSec = 180}) {
    eosNode = EOSNode(nodeURL, nodeVersion);
  }

  Future<Transaction> fullFillTransaction(Transaction transaction,
      {int blocksBehind = 3}) async {
    var info = await eosNode.getInfo();

    var refBlock =
        await eosNode.getBlock((info.headBlockNum - blocksBehind).toString());

    var trx = await this._fullFill(transaction, refBlock);
    await this.serializeActions(trx.actions);
    return trx;
  }

  /// serialize actions in a transaction
  void serializeActions(List<Action> actions) async {
    for (Action action in actions) {
      String account = action.account;

      var contract = await this._getContract(account);

      action.data = this._serializeActionData(
        contract,
        account,
        action.name,
        action.data,
      );
    }
  }

  /// Get data needed to serialize actions in a contract */
  Future<Contract> _getContract(String accountName,
      {bool reload = false}) async {
    var abi = await eosNode.getRawAbi(accountName);
    var types = ser.getTypesFromAbi(ser.createInitialTypes(), abi.abi);
    var actions = new Map<String, Type>();
    for (var act in abi.abi.actions) {
      actions[act.name] = ser.getType(types, act.type);
    }
    var result = Contract(types, actions);
    return result;
  }

  /// Fill the transaction withe reference block data
  Future<Transaction> _fullFill(Transaction transaction, Block refBlock) async {
    transaction.expiration =
        refBlock.timestamp.add(Duration(seconds: expirationInSec));
    transaction.refBlockNum = refBlock.blockNum & 0xffff;
    transaction.refBlockPrefix = refBlock.refBlockPrefix;

    return transaction;
  }

  /// Convert action data to serialized form (hex) */
  String _serializeActionData(
      Contract contract, String account, String name, Object data) {
    var action = contract.actions[name];
    if (action == null) {
      throw "Unknown action $name in contract $account";
    }
    var buffer = new ser.SerialBuffer(Uint8List(0));
    action.serialize(action, buffer, data);
    return ser.arrayToHex(buffer.asUint8List());
  }
}

class EOSNode {
  String _nodeURL;
  get url => this._nodeURL;
  set url(String url) => this._nodeURL = url;

  String _nodeVersion;
  get version => this._nodeVersion;
  set version(String url) => this._nodeVersion = version;

  EOSNode(this._nodeURL, this._nodeVersion);

  Future<dynamic> _post(String path, Object body) async {
    var response = await http.post('${this.url}/${this.version}${path}',
        body: json.encode(body));
    if (response.statusCode >= 300) {
      throw response.body;
    } else {
      return json.decode(response.body);
    }
  }

  /// Get EOS Node Info
  Future<NodeInfo> getInfo() async {
    var nodeInfo = await this._post('/chain/get_info', {});
    return NodeInfo.fromJson(nodeInfo);
  }

  /// Get EOS Block Info
  Future<Block> getBlock(String blockNumOrId) async {
    var block =
        await this._post('/chain/get_block', {'block_num_or_id': blockNumOrId});
    return Block.fromJson(block);
  }

  /// Get EOS raw abi from account name
  Future<AbiResp> getRawAbi(String accountName) async {
    try {
      return this._post(
          '/chain/get_raw_abi', {'account_name': accountName}).then((abi) {
        return AbiResp.fromJson(abi);
      });
    } catch (e) {
      print(e.toString());
    }
    return null;
  }
}
