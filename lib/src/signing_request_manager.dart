import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:dart_esr/src/encoding_options.dart';
import 'package:dart_esr/src/models/action.dart';
import 'package:dart_esr/src/models/authorization.dart';
import 'package:dart_esr/src/models/identity.dart';
import 'package:dart_esr/src/models/info_pair.dart';
import 'package:dart_esr/src/models/signing_request.dart' as abi;
import 'package:dart_esr/src/models/transaction.dart';

import 'package:dart_esr/src/serializeUtils.dart';
import 'package:dart_esr/src/utils/base64u.dart';
import 'package:dart_esr/src/utils/esr_constant.dart';

import 'package:eosdart/eosdart.dart' as eosDart;

import 'signing_request_interface.dart';

class SigningRequestManager {
  static eosDart.Type type =
      ESRConstants.signingRequestAbiType['signing_request'];
  static eosDart.Type idType = ESRConstants.signingRequestAbiType['identity'];
  static eosDart.Type transactionType =
      ESRConstants.signingRequestAbiType['transaction'];

  EOSSerializeUtils serializeUtils;

  int version;
  abi.SigningRequest data;
  TextEncoder textEncoder;
  TextDecoder textDecoder;
  ZlibProvider zlib;
  AbiProvider abiProvider;
  RequestSignature signature;

  /**
    * Create a new signing request.
    * Normally not used directly, see the `create` and `from` class methods.
    */
  SigningRequestManager(
      this.version, this.data, this.textEncoder, this.textDecoder,
      {this.zlib, this.abiProvider, this.signature}) {
    if (this.data.flags & ESRConstants.RequestFlagsBroadcast != 0 &&
        data.req.first is Identity) {
      throw 'Invalid request (identity request cannot be broadcast)';
    }
    if (this.data.flags & ESRConstants.RequestFlagsBroadcast == 0 &&
        data.callback.isEmpty) {
      throw 'Invalid request (nothing to do, no broadcast or callback set)';
    }
  }

  /** Create a new signing request. */
  static Future<SigningRequestManager> create(
    SigningRequestCreateArguments args, {
    SigningRequestEncodingOptions options,
    EOSSerializeUtils serializeUtils,
  }) async {
    if (options == null) {
      options = defaultSigningRequestEncodingOptions;
    }
    TextEncoder textEncoder = options.textEncoder != null
        ? options.textEncoder
        : defaultSigningRequestEncodingOptions.textDecoder;
    TextDecoder textDecoder = options.textDecoder != null
        ? options.textDecoder
        : defaultSigningRequestEncodingOptions.textDecoder;

    var data = abi.SigningRequest();
    // set the request data
    if (args.identity != null) {
      data.req = ['identity', args.identity.toJson()];
    } else if (args.action != null &&
        args.actions == null &&
        args.transaction == null) {
      await serializeUtils.serializeActions([args.action]);

      data.req = ['action', args.action.toJson()];
    } else if (args.actions != null &&
        args.action == null &&
        args.transaction == null) {
      await serializeUtils.serializeActions(args.actions);

      var jsonAction = [];
      for (var action in args.actions) {
        jsonAction.add(action.toJson());
      }
      if (args.actions.length == 1) {
        data.req = ['action', jsonAction.first];
      } else {
        data.req = ['action[]', jsonAction];
      }
    } else if (args.transaction != null &&
        args.action == null &&
        args.actions == null) {
      var tx = args.transaction;

      // set default values if missing
      if (tx.expiration == null) {
        tx.expiration = DateTime.parse('1970-01-01T00:00:00.000');
      }
      if (tx.refBlockNum == null) {
        tx.refBlockNum = 0;
      }
      if (tx.refBlockPrefix == null) {
        tx.refBlockPrefix = 0;
      }
      if (tx.contextFreeActions == null) {
        tx.contextFreeActions = [];
      }
      if (tx.transactionExtensions == null) {
        tx.transactionExtensions = [];
      }
      if (tx.delaySec == null) {
        tx.delaySec = 0;
      }
      if (tx.maxCpuUsageMs == null) {
        tx.maxCpuUsageMs = 0;
      }
      if (tx.maxNetUsageWords == null) {
        tx.maxNetUsageWords = 0;
      }

      // encode actions if needed
      await serializeUtils.serializeActions(tx.actions);
      data.req = ['transaction', tx.toJson()];
    } else {
      throw 'Invalid arguments: Must have exactly one of action, actions or transaction';
    }

    // set the chain id
    data.chainId = SigningRequestUtils.variantId(args.chainId);

    data.flags = ESRConstants.RequestFlagsNone;
    var broadcast = args.broadcast != null ? args.broadcast : true;
    if (broadcast) {
      data.flags |= ESRConstants.RequestFlagsBroadcast;
    }
    if (args.callback is CallbackType) {
      data.callback = args.callback.url;
      if (args.callback.background) {
        data.flags |= ESRConstants.RequestFlagsBackground;
      }
    } else {
      data.callback = '';
    }

    data.info = [];
    if (args.info != null) {
      args.info.forEach((key, value) {
        var encodedValue = textEncoder.encode(value);
        data.info.add(InfoPair()
          ..key = key
          ..value = eosDart.arrayToHex(encodedValue));
      });
    }

    var req = SigningRequestManager(
        ESRConstants.ProtocolVersion, data, textEncoder, textDecoder,
        zlib: options.zlib, abiProvider: options.abiProvider);

    if (options.signatureProvider != null) {
      req.sign(options.signatureProvider);
    }
    return req;
  }

  /** Creates an identity request. */
  static Future<SigningRequestManager> identity(
      SigningRequestCreateIdentityArguments args,
      {SigningRequestEncodingOptions options,
      EOSSerializeUtils serializeUtils}) async {
    var permission = Authorization();
    permission.actor = args.account != null || args.account.isEmpty
        ? args.account
        : ESRConstants.PlaceholderName;
    permission.permission = args.permission != null || args.permission.isEmpty
        ? args.permission
        : ESRConstants.PlaceholderName;

    if (permission.actor == ESRConstants.PlaceholderName &&
        permission.permission == ESRConstants.PlaceholderPermission) {
      permission = null;
    }
    var createArgs = SigningRequestCreateArguments(
        chainId: args.chainId,
        identity: Identity()..authorization = permission,
        broadcast: false,
        callback: args.callback,
        info: args.info);

    return await SigningRequestManager.create(createArgs, options: options);
  }

  /**
   * Create a request from a chain id and serialized transaction.
   * @param chainId The chain id where the transaction is valid.
   * @param serializedTransaction The serialized transaction.
   * @param options Creation options.
   */
  static Future<SigningRequestManager> fromTransaction(
      dynamic chainName, dynamic serializedTransaction,
      {SigningRequestEncodingOptions options}) async {
    //TODO: SigningRequestManager.fromTransaction 'not implemented yet'
    throw 'not implemented yet';
  }

  /** Creates a signing request from encoded `esr:` uri string. */
  static Future<SigningRequestManager> from(String uri,
      {SigningRequestEncodingOptions options}) async {
    //TODO: SigningRequestManager.from 'not implemented yet'
    throw 'not implemented yet';
  }

  static Future<SigningRequestManager> fromdata(Uint8List data,
      {SigningRequestEncodingOptions options}) async {
    //TODO: SigningRequestManager.fromdata 'not implemented yet'
    throw 'not implemented yet';
  }

  /**
   * Sign the request, mutating.
   * @param signatureProvider The signature provider that provides a signature for the signer.
   */
  void sign(SignatureProvider signatureProvider) {
    var message = this.getSignatureDigest();
    this.signature = signatureProvider.sign(eosDart.arrayToHex(message));
  }

  /**
   * Get the signature digest for this request.
   */
  Uint8List getSignatureDigest() {
    var buffer = eosDart.SerialBuffer(Uint8List(0));

    // protocol version + utf8 "request"
    buffer.pushArray([this.version, 0x72, 0x65, 0x71, 0x75, 0x65, 0x73, 0x74]);
    buffer.pushArray(this.getData());
    return sha256.convert(buffer.asUint8List()).bytes;
  }

  /**
   * Set the signature data for this request, mutating.
   * @param signer Account name of signer.
   * @param signature The signature string.
   */
  void setSignature(String signer, String signature) {
    this.signature = RequestSignature(signer, signature);
  }

  /**
   * Set the request callback, mutating.
   * @param url Where the callback should be sent.
   * @param background Whether the callback should be sent in the background.
   */
  void setCallback(String url, bool background) {
    this.data.callback = url;
    if (background) {
      this.data.flags |= ESRConstants.RequestFlagsBackground;
    } else {
      this.data.flags &= ~ESRConstants.RequestFlagsBackground;
    }
  }

  /**
   * Set broadcast flag.
   * @param broadcast Whether the transaction should be broadcast by receiver.
   */
  void setBroadcast(bool broadcast) {
    if (broadcast) {
      this.data.flags |= ESRConstants.RequestFlagsBroadcast;
    } else {
      this.data.flags &= ~ESRConstants.RequestFlagsBroadcast;
    }
  }

  /**
   * Encode this request into an `esr:` uri.
   * @argument compress Whether to compress the request data using zlib,
   *                    defaults to true if omitted and zlib is present;
   *                    otherwise false.
   * @argument slashes Whether add slashes after the protocol scheme, i.e. `esr://`.
   *                   Defaults to true.
   * @returns An esr uri string.
   */
  String encode({bool compress, bool slashes = true}) {
    var shouldCompress = compress != null ? compress : this.zlib != null;
    if (shouldCompress && this.zlib == null) {
      throw 'Need zlib to compress';
    }
    var header = this.version;
    var data = this.getData();
    var sigData = this.getSignatureData();
    var temp = <int>[];
    temp.addAll(data);
    temp.addAll(sigData);
    var array = Uint8List.fromList(temp);
    if (shouldCompress) {
      var deflated = this.zlib?.deflateRaw(array);
      header |= 1 << 7;
      array = deflated;
    }
    var out = <int>[];
    out.add(header);
    out.addAll(array);
    var scheme = ESRConstants.Scheme;
    if (slashes) {
      scheme += '//';
    }
    return scheme + Base64u().encode(Uint8List.fromList(out));
  }

  /** Get the request data without header or signature. */
  Uint8List getData() {
    // var buffer = eosDart.SerialBuffer(Uint8List(0));
    // SigningRequest.type.serialize(buffer, this.data);
    return this.data.toBinary(SigningRequestManager.type);
    // return buffer.asUint8List();
  }

  /** Get signature data, returns an empty array if request is not signed. */
  Uint8List getSignatureData() {
    if (this.signature == null) {
      return Uint8List(0);
    }
    var buffer = eosDart.SerialBuffer(Uint8List(0));
    var type = ESRConstants.signingRequestAbiType['request_signature'];
    type.serialize(buffer, this.signature);
    return buffer.asUint8List();
  }

  /** ABI definitions required to resolve request. */
  List<String> getRequiredAbis() {
    var rawActions = this.getRawActions();
    rawActions.removeWhere(
        (Action action) => !SigningRequestUtils.isIdentity(action));
    return rawActions.map((action) => action.account).toSet().toList();
  }

  /** Whether TaPoS values are required to resolve request. */
  bool requiresTapos() {
    var tx = this.getRawTransaction();
    return !this.isIdentity() && !SigningRequestUtils.hasTapos(tx);
  }

  /** Resolve required ABI definitions. */
  Future<Map<String, dynamic>> fetchAbis({AbiProvider abiProvider}) async {
    var provider = abiProvider ?? this.abiProvider;
    if (provider = null) {
      throw 'Missing ABI provider';
    }
    const abis = <String, dynamic>{};

    await Future.forEach(this.getRequiredAbis(), (account) async {
      abis[account] = await provider.getAbi(account);
    });
    return abis;
  }

  /**
   * Decode raw actions actions to object representations.
   * @param abis ABI defenitions required to decode all actions.
   * @param signer Placeholders in actions will be resolved to signer if set.
   */
  List<Action> resolveActions(Map<String, dynamic> abis, Authorization signer) {
    //TODO: SigningRequestManager.resolveActions 'not implemented yet'
    throw 'not implemented yet';
  }

  Transaction resolveTransaction(
      Map<String, dynamic> abis, Authorization signer, TransactionContext ctx) {
    //TODO: SigningRequestManager.resolveTransaction 'not implemented yet'
    throw 'not implemented yet';
  }

  ResolvedSigningRequest resolve(
      Map<String, dynamic> abis, Authorization signer, TransactionContext ctx) {
    //TODO: SigningRequestManager.resolve 'not implemented yet'
    throw 'not implemented yet';
  }

  /**
   * Get the id of the chain where this request is valid.
   * @returns The 32-byte chain id as hex encoded string.
   */
  String getChainId() {
    var id = this.data.chainId;
    switch (id[0]) {
      case 'chain_id':
        return id[1];
      case 'chain_alias':
        if (ESRConstants.ChainIdLookup.containsKey(id[1])) {
          return ESRConstants.ChainIdLookup[id[1]];
        } else {
          throw 'Unknown chain id alias';
        }
        break;
      default:
        throw 'Invalid signing request data';
    }
  }

  /** Return the actions in this request with action data encoded. */
  List<Action> getRawActions() {
    var req = this.data.req;
    switch (req[0]) {
      case 'action':
        return [req[1]];
      case 'action[]':
        return req[1];
      case 'identity':
        var data =
            '0101000000000000000200000000000000'; // placeholder permission
        var authorization = [ESRConstants.PlaceholderAuth];
        Identity req1 = req[1];
        if (req1?.authorization != null) {
          var buf = eosDart.SerialBuffer(Uint8List(0));
          SigningRequestManager.idType.serialize(buf, req[1]);
          data = eosDart.arrayToHex(buf.asUint8List());
          authorization = [req1?.authorization];
        }
        return [
          Action()
            ..account = ''
            ..name = 'identity'
            ..authorization = authorization
            ..data = data
        ];
      case 'transaction':
        return req[1].actions;
      default:
        throw 'Invalid signing request data';
    }
  }

  /** Unresolved transaction. */
  getRawTransaction() {
    var req = this.data.req;
    switch (req[0]) {
      case 'transaction':
        return req[1];
      case 'action':
      case 'action[]':
      case 'identity':
        return Transaction()
          ..actions = this.getRawActions()
          ..contextFreeActions = []
          ..transactionExtensions = []
          ..expiration = DateTime.parse('1970-01-01T00:00:00.000')
          ..refBlockNum = 0
          ..refBlockPrefix = 0
          ..maxCpuUsageMs = 0
          ..maxNetUsageWords = 0
          ..delaySec = 0;

      default:
        throw 'Invalid signing request data';
    }
  }

  /** Whether the request is an identity request. */
  isIdentity() {
    return this.data.req[0] == 'identity';
  }

  /** Whether the request should be broadcast by signer. */
  bool shouldBroadcast() {
    if (this.isIdentity()) {
      return false;
    }
    return (this.data.flags & ESRConstants.RequestFlagsBroadcast) != 0;
  }

  /**
   * Present if the request is an identity request and requests a specific account.
   * @note This returns `nil` unless a specific identity has been requested,
   *       use `isIdentity` to check id requests.
   */
  String getIdentity() {
    if (this.data.req[0] == 'identity') {
      try {
        var req1 = (this.data.req[1] as Identity);
        if (req1.authorization != null) {
          var actor = req1.authorization.actor;
          return actor == ESRConstants.PlaceholderName ? null : actor;
        }
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  /**
   * Present if the request is an identity request and requests a specific permission.
   * @note This returns `nil` unless a specific permission has been requested,
   *       use `isIdentity` to check id requests.
   */
  String getIdentityPermission() {
    if (this.data.req[0] == 'identity') {
      try {
        var req1 = (this.data.req[1] as Identity);
        if (req1.authorization != null) {
          var permission = req1.authorization.permission;
          return permission == ESRConstants.PlaceholderName ? null : permission;
        }
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  /** Get raw info dict */
  Map<String, Uint8List> getRawInfo() {
    var rv = <String, Uint8List>{};
    this.data.info.forEach((InfoPair element) {
      rv[element.key] = eosDart.hexToUint8List(element.value);
    });
    return rv;
  }

  /** Get metadata values as strings. */
  Map<String, String> getInfo() {
    var rv = <String, String>{};
    var raw = this.getRawInfo();
    raw.forEach((key, value) {
      rv[key] = this.textDecoder.decode(value);
    });
    return rv;
  }

  /** Set a metadata key. 
   * value : string | boolean
  */
  void setInfoKey(String key, dynamic value) {
    Uint8List encodedValue;
    switch (value.runtimeType) {
      case String:
        encodedValue = this.textEncoder.encode(value);
        break;
      case bool:
        encodedValue = Uint8List(1);
        encodedValue[0] = value ? 1 : 0;
        break;
      default:
        throw 'Invalid value type, expected string or boolean.';
    }
    var infoPair = InfoPair()
      ..key = key
      ..value = eosDart.arrayToHex(encodedValue);

    var index = this.data.info.indexWhere((element) => element.key == key);
    if (index >= 0) {
      this.data.info[index] = infoPair;
    } else {
      this.data.info.add(infoPair);
    }
  }

  /** Return a deep copy of this request. */
  SigningRequestManager clone() {
    RequestSignature signature;
    if (this.signature != null) {
      signature = RequestSignature.clone(
          this.signature.signer, this.signature.signature);
    }
    var data = this.data.toJson();

    return SigningRequestManager(this.version,
        abi.SigningRequest.fromJson(data), this.textEncoder, this.textDecoder,
        zlib: this.zlib, abiProvider: this.abiProvider, signature: signature);
  }

  // Convenience methods.

  String toString() {
    return this.encode();
  }

  String toJSON() {
    return this.encode();
  }
}

class ResolvedSigningRequest {
  ResolvedSigningRequest() {
    //TODO: class ResolvedSigningRequest 'not implemented yet'
    throw 'not implemented yet';
  }
}

class SigningRequestUtils {
  eosDart.Contract getContract(eosDart.Abi contractAbi) {
    var types =
        eosDart.getTypesFromAbi(eosDart.createInitialTypes(), contractAbi);
    const actions = <String, eosDart.Type>{};

    contractAbi.actions.forEach((action) {
      actions[action.name] = eosDart.getType(types, action.type);
    });

    return eosDart.Contract(types, actions);
  }

  Future<void> serializeAction() async {
    //TODO: SigningRequestUtils.serializeAction 'not implemented yet' use serialize Utils
    throw 'not implemented yet';
  }

  /**
   * chainId : int | String | ChainName
   */
  static List<dynamic> variantId(dynamic chainId) {
    if (chainId == null) {
      chainId = ChainName.EOS;
    }
    switch (chainId.runtimeType) {
      case int:
        return ['chain_alias', chainId];
      case String:
        return ['chain_id', chainId];
      case ChainName:
        chainId = ESRConstants.ChainIdLookup[chainId];
        return ['chain_id', chainId];
        break;
      default:
        throw 'Invalid arguments: chainId must be of type int | String | ChainName';
    }
  }

  static bool isIdentity(Action action) {
    return action.account == '' && action.name == 'identity';
  }

  static bool hasTapos(Transaction tx) {
    return !(tx.expiration == '1970-01-01T00:00:00.000' &&
        tx.refBlockNum == 0 &&
        tx.refBlockPrefix == 0);
  }

/** Resolve a chain id to a chain name alias, returns UNKNOWN (0x00) if the chain id has no alias. */
  ChainName idToName(String chainId) {
    chainId = chainId?.toLowerCase();
    ESRConstants.ChainIdLookup.containsValue(chainId);
    return ESRConstants.ChainIdLookup.keys
        .firstWhere((key) => ESRConstants.ChainIdLookup[key] == chainId);
  }

  /** Resolve a chain name alias to a chain id. */
  static String nameToId(ChainName chainName) {
    if (ESRConstants.ChainIdLookup.containsKey(chainName)) {
      return ESRConstants.ChainIdLookup[chainName];
    }
    return ESRConstants.ChainIdLookup[ChainName.UNKNOWN];
  }
}
