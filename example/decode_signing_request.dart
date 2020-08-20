import 'package:dart_esr/dart_esr.dart';

main(List<String> args) => decodeExample();

void decodeExample() {
  var esr =
      'esr://gmNcs7jsE9uOP6rL3rrcvpMWUmN27LCdleD836_eTzFz-vCSjQEMXhmEFohe6ry3yuguIyNEiIEJSgvCBA58nnUl1dgwlAEoAAA';
  var request = SigningRequestManager.from(esr,
      options:
          defaultSigningRequestEncodingOptions(nodeUrl: 'https://eos.eosn.io'));

  print('decode\n' + request?.data?.toString());
}
