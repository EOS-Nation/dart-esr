import 'package:dart_esr/dart_esr.dart';

main(List<String> args) => identityExample();

Future<void> identityExample() async {
  var callback = CallbackType('asdf', true);
  var args = SigningRequestCreateIdentityArguments(callback,
      chainId:
          'e70aaab8997e1dfce58fbfac80cbbb8fecec7b99cf982a9444273cbc64c41473',
      account: ESRConstants.PlaceholderName,
      permission: ESRConstants.PlaceholderPermission);

  SigningRequestEncodingOptions options =
      defaultSigningRequestEncodingOptions(nodeUrl: 'https://eos.eosn.io');

  try {
    var idReq = await SigningRequestManager.identity(args, options: options);

    // encode signing request as URI string
    var uri = idReq.encode();
    print('identity\n' + uri);
  } catch (e) {
    print(e.toString());
  }
}
