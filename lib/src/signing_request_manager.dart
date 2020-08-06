import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:dart_esr/src/encoding_options.dart';
import 'package:dart_esr/src/models/action.dart';
import 'package:dart_esr/src/models/authorization.dart';
import 'package:dart_esr/src/models/identity.dart';
import 'package:dart_esr/src/models/info_pair.dart';
import 'package:dart_esr/src/models/request_signature.dart';
import 'package:dart_esr/src/models/signing_request.dart';
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
  SigningRequest data;
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
        : defaultSigningRequestEncodingOptions.textEncoder;
    TextDecoder textDecoder = options.textDecoder != null
        ? options.textDecoder
        : defaultSigningRequestEncodingOptions.textDecoder;

    var data = SigningRequest();
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
        Uint8List encodedValue;
        if (value is Uint8List) {
          encodedValue = value;
        } else if (value is String) {
          encodedValue = textEncoder.encode(value);
        } else {
          throw 'info value must be either a string or a Uint8List';
        }
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
  static SigningRequestManager fromTransaction(
      dynamic chainId, dynamic serializedTransaction,
      {SigningRequestEncodingOptions options}) {
    if (chainId is String) {
      chainId = eosDart.arrayToHex(chainId);
    }
    if (serializedTransaction is String) {
      serializedTransaction = eosDart.hexToUint8List(serializedTransaction);
    }

    var buf = new eosDart.SerialBuffer(Uint8List(0));

    buf.push([2]);
    var id = SigningRequestUtils.variantId(chainId);
    if (id[0] == 'chain_alias') {
      buf.push([0]);
      buf.push(id[1]);
    } else {
      buf.push([1]);
      buf.pushArray(eosDart.hexToUint8List(id[1]));
    }
    buf.push([2]); // transaction variant
    buf.pushArray(serializedTransaction);
    buf.push([ESRConstants.RequestFlagsBroadcast]); // flags
    buf.push([0]); // callback
    buf.push([0]); // info

    return SigningRequestManager.fromData(buf.asUint8List(), options: options);
  }

  /** Creates a signing request from encoded `esr:` uri string. */
  static SigningRequestManager from(String uri,
      {SigningRequestEncodingOptions options}) {
    if (!(uri is String)) {
      throw 'Invalid request uri';
    }
    var splitUri = uri.split(':');
    var scheme = splitUri[0];
    var path = splitUri[1];
    if (scheme != 'esr' && scheme != 'web+esr') {
      throw 'Invalid scheme';
    }
    var data =
        Base64u().decode(path.startsWith('//') ? path.substring(2) : path);
    return SigningRequestManager.fromData(data, options: options);
  }

  static SigningRequestManager fromData(Uint8List data,
      {SigningRequestEncodingOptions options}) {
    var header = data.first;
    var version = header & ~(1 << 7);
    if (version != ESRConstants.ProtocolVersion) {
      throw 'Unsupported protocol version';
    }
    var array = data.sublist(1);
    if ((header & (1 << 7)) != 0) {
      if (options.zlib == null) {
        throw 'Compressed URI needs zlib';
      }
      array = options.zlib.inflateRaw(array);
    }

    var textEncoder =
        options.textEncoder ?? defaultSigningRequestEncodingOptions.textEncoder;
    var textDecoder =
        options.textDecoder ?? defaultSigningRequestEncodingOptions.textDecoder;

    var buf = eosDart.SerialBuffer(array);

    var signingRequest = SigningRequest.fromBinary(type, buf);

    RequestSignature signature;
    if (buf.haveReadData()) {
      signature = RequestSignature.fromBinary(
          ESRConstants.signingRequestAbiType['request_signature'], buf);
    }

    return SigningRequestManager(
        version, signingRequest, textEncoder, textDecoder,
        zlib: options.zlib,
        abiProvider: options.abiProvider,
        signature: signature);
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
    this.signature = RequestSignature()
      ..signer = signer
      ..signature = signature;
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
    return this.data.toBinary(SigningRequestManager.type);
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
    rawActions
        .removeWhere((Action action) => SigningRequestUtils.isIdentity(action));
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
    if (provider == null) {
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
    //TODO: check deserialization
    return this.getRawActions().map((rawAction) {
      eosDart.Abi contractAbi;
      if (SigningRequestUtils.isIdentity(rawAction)) {
        contractAbi = eosDart.Abi.fromJson(ESRConstants.signingRequestAbiType);
      } else {
        contractAbi = abis[rawAction.account];
      }
      if (contractAbi == null) {
        throw 'Missing ABI definition for ${rawAction.account}';
      }
      var contract = SigningRequestUtils.getContract(contractAbi);

      if (signer != null) {
        // hook into eosjs name decoder and return the signing account if we encounter the placeholder
        // this is fine because getContract re-creates the initial types each time
        contract.types['name']?.deserialize = (eosDart.SerialBuffer buffer) {
          var name = buffer.getName();
          if (name == ESRConstants.PlaceholderName) {
            return signer.actor;
          } else if (name == ESRConstants.PlaceholderPermission) {
            return signer.permission;
          } else {
            return name;
          }
        };
      }

      //TODO: use deserializeAction from eosDart
      var action = serializeUtils.deserializeAction(
          contract,
          rawAction.account,
          rawAction.name,
          rawAction.authorization,
          rawAction.data,
          textEncoder,
          textDecoder);

      if (signer != null) {
        action.authorization.forEach((auth) {
          if (auth.actor == ESRConstants.PlaceholderName) {
            auth.actor = signer.actor;
          }
          if (auth.permission == ESRConstants.PlaceholderPermission) {
            auth.permission = signer.permission;
          }
          // backwards compatibility, actor placeholder will also resolve to permission when used in auth
          if (auth.permission == ESRConstants.PlaceholderName) {
            auth.permission = signer.permission;
          }
          return [auth];
        });
      }
      return action;
    }).toList();
  }

  Transaction resolveTransaction(
      Map<String, dynamic> abis, Authorization signer, TransactionContext ctx) {
    var tx = this.getRawTransaction();
    if (!this.isIdentity() && !SigningRequestUtils.hasTapos(tx)) {
      if (ctx.expiration != null &&
          ctx.refBlockNnum != null &&
          ctx.refBlockPrefix != null) {
        tx.expiration = ctx.expiration;
        tx.ref_block_num = ctx.refBlockNnum;
        tx.ref_block_prefix = ctx.refBlockPrefix;
      } else if (ctx.blockNum != null &&
          ctx.refBlockPrefix != null &&
          ctx.timestamp != null) {
        tx.expiration = ctx.timestamp.add(Duration(
            seconds: ctx.expireSeconds != null ? ctx.expireSeconds : 60));
        tx.refBlockNum = ctx.blockNum & 0xffff;
        tx.refBlockPrefix = ctx.refBlockPrefix;
      } else {
        throw 'Invalid transaction context, need either a reference block or explicit TAPoS values';
      }
    }
    tx.actions = this.resolveActions(abis, signer);

    return tx;
  }

  ResolvedSigningRequest resolve(
      Map<String, dynamic> abis, Authorization signer, TransactionContext ctx) {
    var transaction = this.resolveTransaction(abis, signer, ctx);
    var buf = eosDart.SerialBuffer(Uint8List(0));

    serializeUtils.serializeActions(transaction.actions);
    SigningRequestManager.transactionType.serialize(buf, transaction);
    var serializedTransaction = buf.asUint8List();

    return ResolvedSigningRequest(
        this, signer, transaction, serializedTransaction);
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
        var req1 = req[1];
        if (req1['permission'] != null) {
          var auth = Authorization()
            ..actor =
                req1['permission']['actor'] ?? ESRConstants.PlaceholderName
            ..permission = req1['permission']['permission'] ??
                ESRConstants.PlaceholderPermission;

          var identity = Identity()..authorization = auth;

          data = eosDart
              .arrayToHex(identity.toBinary(SigningRequestManager.idType));
          authorization = [auth];
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

    return SigningRequestManager(this.version, SigningRequest.fromJson(data),
        this.textEncoder, this.textDecoder,
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
  SigningRequestManager request;
  Authorization signer;
  Transaction transaction;
  Uint8List serializedTransaction;

  /** Recreate a resolved request from a callback payload. */
  static Future<ResolvedSigningRequest> fromPayload(
      CallbackPayload payload, SigningRequestEncodingOptions options) async {
    var request = SigningRequestManager.from(payload.req, options: options);
    var abis = await request.fetchAbis(abiProvider: options.abiProvider);

    int refBlockNnum;
    int refBlockPrefix;
    try {
      refBlockNnum = int.parse(payload.rbn);
      refBlockPrefix = int.parse(payload.rid);
    } catch (e) {}

    return request.resolve(
        abis,
        Authorization()
          ..actor = payload.sa
          ..permission = payload.sp,
        TransactionContext(
            refBlockNnum: refBlockNnum ?? 0,
            refBlockPrefix: refBlockPrefix ?? 0,
            expiration: DateTime.parse(payload.ex)));
  }

  ResolvedSigningRequest(
      this.request, this.signer, this.transaction, this.serializedTransaction);

  String getTransactionId() {
    return eosDart.arrayToHex(sha256.convert(this.serializedTransaction).bytes);
  }

  ResolvedCallback getCallback(List<String> signatures, {int blockNum}) {
    //TODO: SigningRequestUtils.serializeAction 'not implemented yet' use serialize Utils
    throw 'not implemented yet';
  }
}

class SigningRequestUtils {
  static eosDart.Contract getContract(eosDart.Abi contractAbi) {
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
