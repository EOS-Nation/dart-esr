import 'package:dart_esr/src/encoding_options.dart';
import 'package:dart_esr/src/models/action.dart';
import 'package:dart_esr/src/models/authorization.dart';
import 'package:dart_esr/src/models/transaction.dart';
import 'package:dart_esr/src/serializeUtils.dart';
import 'package:dart_esr/src/signing_request_interface.dart';
import 'package:dart_esr/src/signing_request_manager.dart';
import 'package:dart_esr/src/utils/esr_constant.dart';

main(List<String> args) async {
  // transactionTest();
  // actionTest();
  // actionsTest();
  identityTest();
  // desezialize();
}

void desezialize() {
  var uri =
      "esr://gmN8zrVqx8w62T9P-_evaTi9u__Nm-qZ52doTXFRt9mTckSkmJmByTqjpKSg2EpfPzlJLzEvOSO_SC8nMy9b39zAzCIx2dJM18gs0VLXxNQwRTfRwtxA1zgpMdXM3MzQwtTQkpkFpFSLgYHB4aiWbzgDk1Zw_ObTlU85c7s4MpfmSx3-q3BJxkpY9A_f6Qv8f9b9b-AuTsxNjU9JLctMTmVk5C5KLSktyosvSCzJCE_LzEkFukI_Iz83Vb8gMTlf3yU_uTQ3Na-kWB-oQT-9KLUyN7G4WB_iSF2wI1MrEnMLclKL9XPy0zPz9DPzUlIr9DJKcnOUDXPTAnz9PfIA";
  var w = SigningRequestManager.from(uri,
      options: defaultSigningRequestEncodingOptions);
  print(w.toString());
}

Future<void> actionTest() async {
  var esr = EOSSerializeUtils('https://jungle2.cryptolions.io', 'v1');
  var auth = <Authorization>[ESRConstants.PlaceholderAuth];

  var data = <String, String>{'name': 'data'};

  var action = Action()
    ..account = 'eosnpingpong'
    ..name = 'ping'
    ..authorization = auth
    ..data = data;

  var args = SigningRequestCreateArguments(
      action: action,
      chainId:
          'e70aaab8997e1dfce58fbfac80cbbb8fecec7b99cf982a9444273cbc64c41473',
      info: {'key': 'sctfgkhlkjnlm'});
  SigningRequestEncodingOptions options = defaultSigningRequestEncodingOptions;

  var request = await SigningRequestManager.create(args,
      options: options, serializeUtils: esr);

  var uri = request.encode();
  print(uri);
}

Future<void> actionsTest() async {
  var esr = EOSSerializeUtils('https://jungle2.cryptolions.io', 'v1');
  var auth = <Authorization>[ESRConstants.PlaceholderAuth];

  var data = <String, String>{'name': 'data'};

  var action = Action()
    ..account = 'eosnpingpong'
    ..name = 'ping'
    ..authorization = auth
    ..data = data;

  var action2 = Action()
    ..account = 'eosnpingpong'
    ..name = 'ping'
    ..authorization = auth
    ..data = data;

  var action3 = Action()
    ..account = 'eosnpingpong'
    ..name = 'ping'
    ..authorization = auth
    ..data = data;

  var args = SigningRequestCreateArguments(
    actions: [action, action2, action3],
    chainId: 'e70aaab8997e1dfce58fbfac80cbbb8fecec7b99cf982a9444273cbc64c41473',
  );
  SigningRequestEncodingOptions options = defaultSigningRequestEncodingOptions;

  var request = await SigningRequestManager.create(args,
      options: options, serializeUtils: esr);

  var uri = request.encode();
  print(uri);
}

Future<void> identityTest() async {
  var esr = EOSSerializeUtils('https://jungle2.cryptolions.io', 'v1');

  var callback = CallbackType('asdf', true);
  var args = SigningRequestCreateIdentityArguments(callback,
      chainId:
          'e70aaab8997e1dfce58fbfac80cbbb8fecec7b99cf982a9444273cbc64c41473',
      account: ESRConstants.PlaceholderName,
      permission: ESRConstants.PlaceholderPermission);

  SigningRequestEncodingOptions options = defaultSigningRequestEncodingOptions;

  var idReq = await SigningRequestManager.identity(args,
      options: options, serializeUtils: esr);

  // encode signing request as URI string
  var uri = idReq.encode();
  print(uri);
}

Future<void> transactionTest() async {
  var esr = EOSSerializeUtils('https://jungle2.cryptolions.io', 'v1');
  var auth = <Authorization>[ESRConstants.PlaceholderAuth];

  var data = <String, String>{'name': 'data'};

  var actions = <Action>[
    Action()
      ..account = 'eosnpingpong'
      ..name = 'ping'
      ..authorization = auth
      ..data = data,
  ];

  var transaction = Transaction()..actions = actions;

  var args = SigningRequestCreateArguments(
    transaction: transaction,
    chainId: 'e70aaab8997e1dfce58fbfac80cbbb8fecec7b99cf982a9444273cbc64c41473',
  );
  SigningRequestEncodingOptions options = defaultSigningRequestEncodingOptions;

  var request = await SigningRequestManager.create(args,
      options: options, serializeUtils: esr);

  var uri = request.encode();
  print(uri);
}
