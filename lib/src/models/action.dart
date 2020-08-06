import 'dart:typed_data';

import 'package:dart_esr/src/models/authorization.dart';
import 'package:eosdart/eosdart.dart' as eosDart;
import 'package:json_annotation/json_annotation.dart';

part 'action.g.dart';

@JsonSerializable(explicitToJson: true)
class Action {
  @JsonKey(name: 'account')
  String account;

  @JsonKey(name: 'name')
  String name;

  @JsonKey(name: 'authorization')
  List<Authorization> authorization;

  @JsonKey(name: 'data')
  Object data;

//  @JsonKey(name: 'hex_data')
//  String hexData;

  Action();

  factory Action.fromJson(Map<String, dynamic> json) => _$ActionFromJson(json);

  Map<String, dynamic> toJson() => _$ActionToJson(this);

  @override
  String toString() => this.toJson().toString();

  Uint8List toBinary(eosDart.Type type) {
    var buffer = eosDart.SerialBuffer(Uint8List(0));
    type.serialize(type, buffer, this.toJson());
    return buffer.asUint8List();
  }

  factory Action.fromBinary(eosDart.Type type, dynamic data) {
    eosDart.SerialBuffer buffer;
    if (data is eosDart.SerialBuffer) {
      buffer = data;
    } else if (data is Uint8List) {
      buffer = eosDart.SerialBuffer(data);
    } else {
      throw 'Data must be either Uint8List or SerialBuffer';
    }
    var deserializedData =
        Map<String, dynamic>.from(type.deserialize(type, buffer));
    return Action.fromJson(deserializedData);
  }
}
