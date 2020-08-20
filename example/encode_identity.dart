import 'package:dart_esr/dart_esr.dart';

main(List<String> args) => identityExample();

Future<void> identityExample() async {
  var callback = CallbackType('http://callback.com', true);
  var args = SigningRequestCreateIdentityArguments(callback,
      chainId: ESRConstants.ChainIdLookup[ChainName.EOS],
      account: ESRConstants.PlaceholderName,
      permission: ESRConstants.PlaceholderPermission);

  SigningRequestEncodingOptions options =
      defaultSigningRequestEncodingOptions(nodeUrl: 'https://eos.eosn.io');

  var idReq = await SigningRequestManager.identity(args, options: options);

  var uri = idReq.encode();
  print('identity\n' + uri);
}
