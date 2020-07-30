import 'package:dart_esr/src/models/action.dart';
import 'package:dart_esr/src/models/identity.dart';
import 'package:dart_esr/src/models/transaction.dart';
import 'package:dart_esr/src/utils/esr_constant.dart';

class SigningRequestCreateArguments {
  SigningRequestCreateArguments(
      {this.action,
      this.actions,
      this.broadcast,
      this.callback,
      this.chainId,
      this.identity,
      this.info,
      this.transaction});
  /** Single action to create request with. */
  Action action;
  /** Multiple actions to create request with. */
  List<Action> actions;
  /**
   * Full or partial transaction to create request with.
   * If TAPoS info is omitted it will be filled in when resolving the request.
   */
  Transaction transaction;
  /** Create an identity request. */
  Identity identity;
  /** Chain to use, defaults to EOS main-net if omitted. */
  String chainId;
  /** Whether wallet should broadcast tx, defaults to true. */
  bool broadcast;
  /**
   * Optional callback URL the signer should hit after
   * broadcasting or signing. Passing a string means background = false.
   */
  CallbackType callback;
  /** Optional metadata to pass along with the request. */
  Map<String, String> info;
}

class SigningRequestCreateIdentityArguments {
  SigningRequestCreateIdentityArguments(
    this.callback, {
    this.chainId,
    this.account,
    this.permission,
    this.info,
  }) {
    if (!(this.chainId is ChainName) &&
        !(this.chainId is int) &&
        !(this.chainId is String)) {
      throw 'Invalid arguments: ChainId must be of type ESRConstants.ChainName, string or int';
    }
  }
  /**
   * Callback where the identity should be delivered.
   */
  CallbackType callback;
  /** Chain to use, defaults to EOS main-net if omitted. */
  String chainId;
  /**
   * Requested account name of identity.
   * Defaults to placeholder (any identity) if omitted.
   */
  String account;
  /**
   * Requested account permission.
   * Defaults to placeholder (any permission) if omitted.
   */
  String permission;
  /** Optional metadata to pass along with the request. */
  Map<String, String> info;
}

class CallbackType {
  String url;
  bool background;

  CallbackType(this.url, this.background);
}

class CallbackPayload {
  /** The first signature. */
  String sig;
  /** Transaction ID as HEX-encoded String. */
  String tx;
  /** Block number hint (only present if transaction was broadcast). */
  String bn;
  /** Signer authority, aka account name. */
  String sa;
  /** Signer permission, e.g. "active". */
  String sp;
  /** Reference block num used when resolving request. */
  String rbn;
  /** Reference block id used when resolving request. */
  String rid;
  /** The originating signing request packed as a uri String. */
  String req;
  /** Expiration time used when resolving request. */
  String ex;
  /** All signatures 0-indexed as `sig0`, `sig1`, etc. */
  Map<String, String> signatures;
  CallbackPayload(
      {this.bn,
      this.ex,
      this.rbn,
      this.req,
      this.rid,
      this.sa,
      this.sig,
      this.signatures,
      this.sp,
      this.tx});
}

/**
 * Context used to resolve a transaction.
 * Compatible with the JSON response from a `get_block` call.
 */
class TransactionContext {
  /** Timestamp expiration will be derived from. */
  DateTime timestamp;
  /**
   * How many seconds in the future to set expiration when deriving from timestamp.
   * Defaults to 60 seconds if unset.
   */
  int expireSeconds;
  /** Block number ref_block_num will be derived from. */
  int blockNum;
  /** Reference block number, takes precedence over block_num if both is set. */
  int refBlockNnum;
  /** Reference block prefix. */
  int refBlockPrefix;
  /** Expiration timestamp, takes precedence over timestamp and expire_seconds if set. */
  DateTime expiration;

  TransactionContext(
      {this.blockNum,
      this.expiration,
      this.expireSeconds,
      this.refBlockNnum,
      this.refBlockPrefix,
      this.timestamp});
}
