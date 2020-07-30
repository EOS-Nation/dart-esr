import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:dart_esr/src/models/info_pair.dart';

import 'package:dart_esr/src/serializeUtils.dart';

import 'package:dart_esr/src/utils/base64u.dart';
import 'package:dart_esr/src/utils/esr_constant.dart';

import 'package:dart_esr/src/models/action.dart';
import 'package:dart_esr/src/models/identity.dart';
import 'package:dart_esr/src/models/transaction.dart';
import 'package:dart_esr/src/models/signing_request.dart';

class EOSIOSigningrequest {
  EOSSerializeUtils _client;
  SigningRequest _signingRequest;
  Uint8List _request;

  EOSIOSigningrequest(
    String nodeUrl,
    String nodeVersion, {
    String chainId,
    ChainName chainName,
    int flags = 1,
    String callback = '',
    List<InfoPair> info,
  }) {
    this._signingRequest = SigningRequest();
    this._client = EOSSerializeUtils(nodeUrl, nodeVersion);

    this.setChainId(chainName: chainName, chainId: chainId);
    this.setOtherFields(
        flags: flags, callback: callback, info: info != null ? info : []);
  }

  void setNode(String nodeUrl, String nodeVersion) {
    _client = EOSSerializeUtils(nodeUrl, nodeVersion);
  }

  void setChainId({ChainName chainName, String chainId}) {
    if (chainName != null) {
      _signingRequest.chainId = [
        'chain_alias',
        ESRConstants.getChainAlias(chainName)
      ];
      return;
    } else if (chainId != null) {
      _signingRequest.chainId = ['chain_id', chainId];
      return;
    } else {
      throw 'Either "ChainName" or "ChainId" must be set';
    }
  }

  void setOtherFields({int flags, String callback, List<InfoPair> info}) {
    if (flags != null) this._signingRequest.flags = flags;
    if (callback != null) this._signingRequest.callback = callback;
    info.forEach((element) {
      element.toJson();
    });
    if (info != null && !info.isEmpty) this._signingRequest.info = info;
  }

  Future<String> encodeTransaction(Transaction transaction) async {
    await _client.fullFillTransaction(transaction);
    _signingRequest.req = ['transaction', transaction.toJson()];
    return this._encode();
  }

  Future<String> encodeAction(Action action) async {
    await this._client.serializeActions([action]);
    _signingRequest.req = ['action', action.toJson()];
    return this._encode();
  }

  Future<String> encodeActions(List<Action> actions) async {
    await this._client.serializeActions(actions);
    var jsonAction = [];
    for (var action in actions) {
      jsonAction.add(action.toJson());
    }
    _signingRequest.req = ['action[]', jsonAction];
    return this._encode();
  }

  Future<String> encodeIdentity(Identity identity, String callback) async {
    if (callback == null) {
      throw 'Callback is needed';
    }
    _signingRequest.req = ['identity', identity.toJson()];
    _signingRequest.callback = callback;
    _signingRequest.flags = 0;

    return this._encode();
  }

  Future<String> _encode() async {
    this._request = _signingRequest
        .toBinary(ESRConstants.signingRequestAbiType['signing_request']);

    this._compressRequest();
    this._addVersionHeaderToRequest();

    return this._requestToBase64();
  }

  SigningRequest deserialize(String encodedRequest) {
    var request = '';
    if (encodedRequest.startsWith('esr://')) {
      request = encodedRequest.substring(6);
    }

    var decoded = Base64u().decode(request);
    var list = Uint8List(decoded.length - 1);

    list = decoded.sublist(1);
    var decompressed = ZLibDecoder().decodeBytes(list, raw: true);

    return SigningRequest.fromBinary(
        ESRConstants.signingRequestAbiType['signing_request'], decompressed);
  }

  void _compressRequest() {
    var encoded = ZLibEncoder().encode(this._request, raw: true);
    this._request = Uint8List.fromList(encoded);
  }

  void _addVersionHeaderToRequest() {
    var header = ESRConstants.ProtocolVersion;

    var list = Uint8List(this._request.length + 1);
    list[0] = header |= 1 << 7;
    for (int i = 1; i < list.length; i++) {
      list[i] = this._request[i - 1];
    }
    this._request = list;
  }

  String _requestToBase64() {
    var encoded = Base64u().encode(Uint8List.fromList(this._request));
    return ESRConstants.Scheme + '//' + encoded;
  }
}
