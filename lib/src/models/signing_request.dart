import 'dart:typed_data';
import 'package:dart_esr/src/models/info_pair.dart';
import 'package:json_annotation/json_annotation.dart';

import 'package:eosdart/eosdart.dart';

part 'signing_request.g.dart';

@JsonSerializable(explicitToJson: true)
class SigningRequest {
  @JsonKey(name: 'chain_id')
  List<dynamic> chainId = [];

  @JsonKey(name: 'req')
  List<dynamic> req = [];

  @JsonKey(name: 'flags')
  int flags = 1;

  @JsonKey(name: 'callback')
  String callback = '';

  @JsonKey(name: 'info')
  List<InfoPair> info = [];

  SigningRequest();

  factory SigningRequest.fromJson(Map<String, dynamic> json) =>
      _$SigningRequestFromJson(json);

  Map<String, dynamic> toJson() => _$SigningRequestToJson(this);

  @override
  String toString() => this.toJson().toString();

  Uint8List toBinary(Type type) {
    var buffer = SerialBuffer(Uint8List(0));
    type.serialize(type, buffer, this.toJson());
    return buffer.asUint8List();
  }

  factory SigningRequest.fromBinary(Type type, dynamic data) {
    SerialBuffer buffer;
    if (data is SerialBuffer) {
      buffer = data;
    } else if (data is Uint8List) {
      buffer = SerialBuffer(data);
    } else {
      throw 'Data must be either Uint8List or SerialBuffer';
    }
    var deserializedData =
        Map<String, dynamic>.from(type.deserialize(type, buffer));
    return SigningRequest.fromJson(deserializedData);
  }
}
