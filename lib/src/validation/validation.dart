import '../errors.dart';

/// Validates maps and model-like objects.
class Validator {
  static Map<String, String> validateMap(
    Map<String, dynamic> data,
    Map<String, ValidateRule> rules,
  ) {
    final errors = <String, String>{};
    for (final entry in rules.entries) {
      final field = entry.key;
      final rule = entry.value;
      final value = data[field];

      if (rule.required && (value == null || (value is String && value.isEmpty))) {
        errors[field] = '$field is required';
        continue;
      }
      if (value == null) continue;

      if (value is String) {
        if (rule.minLength != null && value.length < rule.minLength!) {
          errors[field] = '$field must be at least ${rule.minLength} characters';
        }
        if (rule.maxLength != null && value.length > rule.maxLength!) {
          errors[field] = '$field must be at most ${rule.maxLength} characters';
        }
        if (rule.email && !_isEmail(value)) {
          errors[field] = '$field must be a valid email';
        }
      }

      if (value is num) {
        if (rule.min != null && value < rule.min!) {
          errors[field] = '$field must be >= ${rule.min}';
        }
        if (rule.max != null && value > rule.max!) {
          errors[field] = '$field must be <= ${rule.max}';
        }
      }
    }

    return errors;
  }

  static void validateOrThrow(
    Map<String, dynamic> data,
    Map<String, ValidateRule> rules,
  ) {
    final errors = validateMap(data, rules);
    if (errors.isNotEmpty) {
      throw ValidationException(errors);
    }
  }

  static bool _isEmail(String value) {
    return RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(value);
  }
}

class ValidateRule {
  const ValidateRule({
    this.required = false,
    this.minLength,
    this.maxLength,
    this.email = false,
    this.min,
    this.max,
  });

  const ValidateRule.required()
      : required = true,
        minLength = null,
        maxLength = null,
        email = false,
        min = null,
        max = null;

  const ValidateRule.email()
      : required = true,
        minLength = null,
        maxLength = null,
        email = true,
        min = null,
        max = null;

  final bool required;
  final int? minLength;
  final int? maxLength;
  final bool email;
  final num? min;
  final num? max;
}
