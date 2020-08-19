import 'dart:typed_data';

import 'package:dart_esr/src/utils/esr_constant.dart';
import 'package:dart_esr/src/encoding_options.dart';
import 'package:dart_esr/src/models/action.dart';
import 'package:dart_esr/src/models/authorization.dart';
import 'package:dart_esr/src/models/identity.dart';

import 'package:eosdart/eosdart.dart' as eosDart;

class EOSSerializeUtils {
  /// serialize actions in a transaction
  static serializeActions(eosDart.Contract contract, Action action) async {
    if (action.account.isEmpty &&
        action.name == 'identity' &&
        action.data is Identity) {
      action.data = (action.data as Identity)
          .toBinary(ESRConstants.signingRequestAbiType['identity']);
    } else {
      action.data = EOSSerializeUtils.serializeActionData(
        contract,
        action.account,
        action.name,
        action.data,
      );
    }
  }

  /** Deserialize action data. If `data` is a `string`, then it's assumed to be in hex. */
  static Object deserializeActionData(
      eosDart.Contract contract,
      String account,
      String name,
      dynamic data,
      TextEncoder textEncoder,
      TextDecoder textDecoder) {
    var action = contract.actions[name];
    if (data is String) {
      data = eosDart.hexToUint8List(data);
    }
    if (action == null) {
      throw 'Unknown action ${name} in contract ${account}';
    }

    if (account.isEmpty && name == 'identity') {
      return Identity.fromBinary(
          ESRConstants.signingRequestAbiType['identity'], data);
    }

    var buffer = eosDart.SerialBuffer(data);
    return action.deserialize(action, buffer);
  }

  /** Deserialize action. If `data` is a `string`, then it's assumed to be in hex. */
  static Action deserializeAction(
      eosDart.Contract contract,
      String account,
      String name,
      List<Authorization> authorization,
      dynamic data,
      TextEncoder textEncoder,
      TextDecoder textDecoder) {
    return Action()
      ..account = account
      ..name = name
      ..authorization = authorization
      ..data = EOSSerializeUtils.deserializeActionData(
          contract, account, name, data, textEncoder, textDecoder);
  }

  /** Convert action data to serialized form (hex) */
  static String serializeActionData(
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
