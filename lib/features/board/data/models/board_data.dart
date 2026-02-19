/// Feature: spec/features/kanban-board-view.feature
///
/// Board data models for the Kanban board view.
/// Represents the JSON response from the 'board' fspec command.
library;

import 'package:freezed_annotation/freezed_annotation.dart';

part 'board_data.freezed.dart';
part 'board_data.g.dart';

/// Work unit type enum
enum WorkUnitType {
  @JsonValue('story')
  story,
  @JsonValue('bug')
  bug,
  @JsonValue('task')
  task,
}

/// Represents a single work unit card on the board
@freezed
abstract class WorkUnit with _$WorkUnit {
  const factory WorkUnit({
    required String id,
    required String title,
    required WorkUnitType type,
    int? estimate,
  }) = _WorkUnit;

  factory WorkUnit.fromJson(Map<String, dynamic> json) =>
      _$WorkUnitFromJson(json);
}

/// Represents the board columns data
@freezed
abstract class BoardColumns with _$BoardColumns {
  const factory BoardColumns({
    @Default([]) List<WorkUnit> backlog,
    @Default([]) List<WorkUnit> specifying,
    @Default([]) List<WorkUnit> testing,
    @Default([]) List<WorkUnit> implementing,
    @Default([]) List<WorkUnit> validating,
    @Default([]) List<WorkUnit> done,
    @Default([]) List<WorkUnit> blocked,
  }) = _BoardColumns;

  factory BoardColumns.fromJson(Map<String, dynamic> json) =>
      _$BoardColumnsFromJson(json);
}

/// Represents the full board data response
@freezed
abstract class BoardData with _$BoardData {
  const factory BoardData({
    required bool success,
    required BoardColumns columns,
    String? summary,
  }) = _BoardData;

  factory BoardData.fromJson(Map<String, dynamic> json) =>
      _$BoardDataFromJson(json);
}

/// Column metadata for display
class ColumnInfo {
  final String key;
  final String displayName;
  final List<WorkUnit> Function(BoardColumns) getWorkUnits;

  const ColumnInfo({
    required this.key,
    required this.displayName,
    required this.getWorkUnits,
  });
}

/// All columns in order
const List<ColumnInfo> boardColumnInfos = [
  ColumnInfo(
    key: 'backlog',
    displayName: 'Backlog',
    getWorkUnits: _getBacklog,
  ),
  ColumnInfo(
    key: 'specifying',
    displayName: 'Specifying',
    getWorkUnits: _getSpecifying,
  ),
  ColumnInfo(
    key: 'testing',
    displayName: 'Testing',
    getWorkUnits: _getTesting,
  ),
  ColumnInfo(
    key: 'implementing',
    displayName: 'Implementing',
    getWorkUnits: _getImplementing,
  ),
  ColumnInfo(
    key: 'validating',
    displayName: 'Validating',
    getWorkUnits: _getValidating,
  ),
  ColumnInfo(
    key: 'done',
    displayName: 'Done',
    getWorkUnits: _getDone,
  ),
  ColumnInfo(
    key: 'blocked',
    displayName: 'Blocked',
    getWorkUnits: _getBlocked,
  ),
];

List<WorkUnit> _getBacklog(BoardColumns c) => c.backlog;
List<WorkUnit> _getSpecifying(BoardColumns c) => c.specifying;
List<WorkUnit> _getTesting(BoardColumns c) => c.testing;
List<WorkUnit> _getImplementing(BoardColumns c) => c.implementing;
List<WorkUnit> _getValidating(BoardColumns c) => c.validating;
List<WorkUnit> _getDone(BoardColumns c) => c.done;
List<WorkUnit> _getBlocked(BoardColumns c) => c.blocked;
