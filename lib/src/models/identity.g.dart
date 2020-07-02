part of 'identity.dart';

Identity _$IdentityFromJson(Map<String, dynamic> json) {
  return Identity()..identityPermission = json['permission'];
}

Map<String, dynamic> _$IdentityToJson(Identity instance) => <String, dynamic>{
      'permission': instance.identityPermission.toJson(),
    };

IdentityPermission _$IdentityPermissionFromJson(Map<String, dynamic> json) {
  return IdentityPermission()
    ..actor = json['actor'] as String
    ..permission = json['permission'] as String;
}

Map<String, dynamic> _$IdentityPermissionToJson(IdentityPermission instance) =>
    <String, dynamic>{
      'actor': instance.actor,
      'permission': instance.permission
    };
