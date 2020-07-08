import 'dart:typed_data';
import 'package:json_annotation/json_annotation.dart';

import 'package:eosdart/eosdart.dart';

part 'identity.g.dart';

@JsonSerializable(explicitToJson: true)
class Identity {
  @JsonKey(name: 'permission')
  IdentityPermission identityPermission;

  Identity();

  factory Identity.fromJson(Map<String, dynamic> json) =>
      _$IdentityFromJson(json);

  Map<String, dynamic> toJson() => _$IdentityToJson(this);

  @override
  String toString() => this.toJson().toString();

  Uint8List toBinary(Type type) {
    var buffer = SerialBuffer(Uint8List(0));
    type.serialize(type, buffer, this.toJson());
    return buffer.asUint8List();
  }
}

@JsonSerializable(explicitToJson: true)
class IdentityPermission {
  @JsonKey(name: 'actor')
  String actor;

  @JsonKey(name: 'permission')
  String permission;

  IdentityPermission();

  factory IdentityPermission.fromJson(Map<String, dynamic> json) =>
      _$IdentityPermissionFromJson(json);

  Map<String, dynamic> toJson() => _$IdentityPermissionToJson(this);

  @override
  String toString() => this.toJson().toString();
}
