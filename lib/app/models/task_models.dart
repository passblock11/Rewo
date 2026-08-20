/// Task models used by the demo tasks module.
library task_models;

import 'package:json_annotation/json_annotation.dart';

part 'task_models.g.dart';

/// Payload accepted by `POST /api/tasks`.
@JsonSerializable()
class CreateTaskRequest {
  /// Creates a request with [title] and optional [description].
  CreateTaskRequest({required this.title, this.description = ''});

  /// Parses JSON into a [CreateTaskRequest].
  factory CreateTaskRequest.fromJson(Map<String, dynamic> json) =>
      _$CreateTaskRequestFromJson(json);

  /// Short task title.
  final String title;

  /// Optional longer description.
  final String description;

  /// Serializes this request to JSON.
  Map<String, dynamic> toJson() => _$CreateTaskRequestToJson(this);
}

/// Demo task entity stored in memory.
class Task {
  /// Creates a task with the given fields.
  Task({
    required this.id,
    required this.title,
    required this.description,
    required this.done,
    required this.createdAt,
  });

  /// Unique identifier.
  final String id;

  /// Short task title.
  final String title;

  /// Optional longer description.
  final String description;

  /// Whether the task is completed.
  final bool done;

  /// Creation timestamp.
  final DateTime createdAt;

  /// Serializes this task to JSON.
  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'done': done,
        'createdAt': createdAt.toIso8601String(),
      };

  /// Returns a copy with an updated [done] flag.
  Task copyWith({bool? done}) => Task(
        id: id,
        title: title,
        description: description,
        done: done ?? this.done,
        createdAt: createdAt,
      );
}
