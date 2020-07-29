import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dart_esr/src/models/action.dart';
import 'package:dart_esr/src/models/transaction.dart';

import 'package:eosdart/eosdart.dart' as eosDart;

import 'package:http/http.dart' as http;

class EOSSerializeUtils {
  EOSNode eosNode;
  int expirationInSec;

  EOSSerializeUtils(String nodeURL, String nodeVersion,
      {this.expirationInSec = 180}) {
    eosNode = EOSNode(nodeURL, nodeVersion);
  }

  //Fill the transaction with the reference block data
  Future<Transaction> fullFillTransaction(Transaction transaction,
      {int blocksBehind = 3}) async {
    var info = await eosNode.getInfo();

    var refBlock =
        await eosNode.getBlock((info.headBlockNum - blocksBehind).toString());

    await this._fullFill(transaction, refBlock);
    await this.serializeActions(transaction.actions);
    return transaction;
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
  Future<eosDart.Contract> _getContract(String accountName,
      {bool reload = false}) async {
    var abi = await eosNode.getRawAbi(accountName);
    var types = eosDart.getTypesFromAbi(eosDart.createInitialTypes(), abi.abi);
    var actions = new Map<String, eosDart.Type>();
    for (var act in abi.abi.actions) {
      actions[act.name] = eosDart.getType(types, act.type);
    }
    return eosDart.Contract(types, actions);
  }

  /// Fill the transaction withe reference block data
  void _fullFill(Transaction transaction, eosDart.Block refBlock) async {
    transaction.expiration =
        refBlock.timestamp.add(Duration(seconds: expirationInSec));
    transaction.refBlockNum = refBlock.blockNum & 0xffff;
    transaction.refBlockPrefix = refBlock.refBlockPrefix;
  }

  /// Convert action data to serialized form (hex) */
  String _serializeActionData(
      eosDart.Contract contract, String account, String name, Object data) {
    var action = contract.actions[name];
    if (action == null) {
      throw "Unknown action $name in contract $account";
    }
    var buffer = new eosDart.SerialBuffer(Uint8List(0));
    action.serialize(action, buffer, data);
    return eosDart.arrayToHex(buffer.asUint8List());
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
  Future<eosDart.NodeInfo> getInfo() async {
    var nodeInfo = await this._post('/chain/get_info', {});
    return eosDart.NodeInfo.fromJson(nodeInfo);
  }

  /// Get EOS Block Info
  Future<eosDart.Block> getBlock(String blockNumOrId) async {
    var block =
        await this._post('/chain/get_block', {'block_num_or_id': blockNumOrId});
    return eosDart.Block.fromJson(block);
  }

  /// Get EOS raw abi from account name
  Future<eosDart.AbiResp> getRawAbi(String accountName) async {
    return this
        ._post('/chain/get_raw_abi', {'account_name': accountName}).then((abi) {
      return eosDart.AbiResp.fromJson(abi);
    });
  }
}
