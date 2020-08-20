import 'package:dart_esr/dart_esr.dart';

main(List<String> args) => identityExample();

Future<void> identityExample() async {
  var callback = CallbackType('asdf', true);
  var args = SigningRequestCreateIdentityArguments(callback,
      chainId: ESRConstants.ChainIdLookup[ChainName.EOS_JUNGLE2],
      account: ESRConstants.PlaceholderName,
      permission: ESRConstants.PlaceholderPermission);

  SigningRequestEncodingOptions options = defaultSigningRequestEncodingOptions(
      nodeUrl: 'https://jungle.greymass.com');

  try {
    var idReq = await SigningRequestManager.identity(args, options: options);

    // encode signing request as URI string
    var uri = idReq.encode();
    print('identity\n' + uri);
  } catch (e) {
    print(e.toString());
  }
}
