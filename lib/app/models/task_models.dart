import 'package:json_annotation/json_annotation.dart';

part 'task_models.g.dart';

@JsonSerializable()
class CreateTaskRequest {
  CreateTaskRequest({required this.title, this.description = ''});

  factory CreateTaskRequest.fromJson(Map<String, dynamic> json) =>
      _$CreateTaskRequestFromJson(json);

  final String title;
  final String description;

  Map<String, dynamic> toJson() => _$CreateTaskRequestToJson(this);
}

class Task {
  Task({
    required this.id,
    required this.title,
    required this.description,
    required this.done,
    required this.createdAt,
  });

  final String id;
  final String title;
  final String description;
  final bool done;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'done': done,
        'createdAt': createdAt.toIso8601String(),
      };

  Task copyWith({bool? done}) => Task(
        id: id,
        title: title,
        description: description,
        done: done ?? this.done,
        createdAt: createdAt,
      );
}
