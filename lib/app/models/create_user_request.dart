/// JSON request model for creating users in the demo app.
library create_user_request;

import 'package:json_annotation/json_annotation.dart';

part 'create_user_request.g.dart';

/// Payload accepted by `POST /api/users`.
@JsonSerializable(createToJson: false)
class CreateUserRequest {
  /// Creates a request with [email] and [name].
  const CreateUserRequest({required this.email, required this.name});

  /// Parses JSON into a [CreateUserRequest].
  factory CreateUserRequest.fromJson(Map<String, dynamic> json) =>
      _$CreateUserRequestFromJson(json);

  /// User email address.
  final String email;

  /// Display name.
  final String name;
}
