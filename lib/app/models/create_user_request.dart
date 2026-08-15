import 'package:json_annotation/json_annotation.dart';

part 'create_user_request.g.dart';

@JsonSerializable(createToJson: false)
class CreateUserRequest {
  const CreateUserRequest({required this.email, required this.name});

  factory CreateUserRequest.fromJson(Map<String, dynamic> json) =>
      _$CreateUserRequestFromJson(json);

  final String email;
  final String name;
}
