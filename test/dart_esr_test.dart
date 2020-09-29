import 'package:dart_esr/dart_esr.dart';
import 'package:test/test.dart';

void main() {
  group('EOSIO Signing Request', () {
    var chainId =
        'e70aaab8997e1dfce58fbfac80cbbb8fecec7b99cf982a9444273cbc64c41473';
    var transferUri =
     // 'esr:gmNgYmAoCOJqXqlwloGBIVzX5uxZRkYGCGCC0ooOD0M-rirWLGZg8PNKbLi5tKFFDizBEuzq6hIMZAB1AAA';
    'esr://gmN8zrVqx8w62T9P-_evaTi9u__Nm-qZ52doTXFRt9mTckSkmIFhWZMJ8yuDUAYGhnBdm7NnGRkZIIAJSiuCsL-voBGQVgLRAuoQCRZX_2AwA6gDAA';

    test('encode transfer action', () async {
      var auth = [ESRConstants.PlaceholderAuth];

      var data = {
        'from': 'account1',
        'to': 'account2',
        'quantity': '1.0000 EOS',
        'memo': ''
      };

      var action = Action()
        ..account = 'eosio.token'
        ..name = 'transfer'
        ..authorization = auth
        ..data = data;

      var args =
          SigningRequestCreateArguments(action: action, chainId: chainId);

      var options =  defaultSigningRequestEncodingOptions2();

      var request = await SigningRequestManager.create(args, options: options);

      var uri = request.encode();

      expect(uri, transferUri);
    });

    test('decode transfer action', () async {
      var request = await SigningRequestManager.from(
        transferUri,
        options: defaultSigningRequestEncodingOptions2(),
      );

      expect(request.data.chainId[1].toLowerCase(), chainId);
      expect(request.data.req[1], {
        'account': 'eosio.token',
        'name': 'transfer',
        'authorization': [
          {'actor': '............1', 'permission': '............2'}
        ],
        'data':
            '000000214F4D1132000000224F4D1132102700000000000004454F530000000000'
      });
    });
  });
}
