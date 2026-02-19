/// Feature: spec/features/work-unit-detail-view.feature
///
/// Work unit detail data models for the detail view.
/// Represents the JSON response from the 'show-work-unit' fspec command.
/// Includes Example Mapping data: user story, rules, examples, questions.
library;

import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../board/data/models/board_data.dart';

part 'work_unit_detail.freezed.dart';
part 'work_unit_detail.g.dart';

/// User story in "As a... I want to... so that..." format
@freezed
abstract class UserStory with _$UserStory {
  const factory UserStory({
    required String role,
    required String action,
    required String benefit,
  }) = _UserStory;

  factory UserStory.fromJson(Map<String, dynamic> json) =>
      _$UserStoryFromJson(json);
}

/// Business rule (blue card in Example Mapping)
@freezed
abstract class Rule with _$Rule {
  const factory Rule({
    required int index,
    required String text,
    @Default(false) bool deleted,
  }) = _Rule;

  factory Rule.fromJson(Map<String, dynamic> json) => _$RuleFromJson(json);
}

/// Concrete example (green card in Example Mapping)
@freezed
abstract class Example with _$Example {
  const factory Example({
    required int index,
    required String text,
    String? type,
    @Default(false) bool deleted,
  }) = _Example;

  factory Example.fromJson(Map<String, dynamic> json) =>
      _$ExampleFromJson(json);
}

/// Question with optional @mentions (red card in Example Mapping)
@freezed
abstract class Question with _$Question {
  const factory Question({
    required int index,
    required String text,
    String? answer,
    @Default([]) List<String> mentions,
    @Default(false) bool deleted,
  }) = _Question;

  factory Question.fromJson(Map<String, dynamic> json) =>
      _$QuestionFromJson(json);
}

/// Full work unit detail including Example Mapping data
@freezed
abstract class WorkUnitDetail with _$WorkUnitDetail {
  const factory WorkUnitDetail({
    required String id,
    required String title,
    required WorkUnitType type,
    required String status,
    String? description,
    String? epic,
    int? estimate,
    UserStory? userStory,
    @Default([]) List<Rule> rules,
    @Default([]) List<Example> examples,
    @Default([]) List<Question> questions,
    @Default([]) List<String> architectureNotes,
    @Default([]) List<String> dependsOn,
    @Default([]) List<String> linkedFeatures,
  }) = _WorkUnitDetail;

  factory WorkUnitDetail.fromJson(Map<String, dynamic> json) =>
      _$WorkUnitDetailFromJson(json);
}
