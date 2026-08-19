import '../board/board_graph.dart';
import 'side.dart';

/// Versioned, immutable presentation/replay record derived from an accepted
/// engine action. Per 03-architecture-and-data.md, this is the only data the
/// `MovePresentationController` (a later phase) may read to drive opponent-
/// move visualization and replay — never animation coordinates, and never a
/// re-derivation from raw board pixels.
class MoveEvent {
  /// Schema version of this event shape, independent of [rulesetVersion].
  static const int schemaVersion = 1;

  final String matchId;

  /// Position of this event within the match's action log (0-based).
  final int actionSequence;

  final Side actor;

  /// One of: 'move', 'capture', 'resign', 'timeout'.
  final String actionType;

  final NodeId? source;
  final NodeId? destination;

  /// Nodes captured by this single action, in order. Exactly one entry for
  /// a 'capture' action, empty otherwise.
  final List<NodeId> capturedNodes;

  /// 0 for the first capture of a turn (or any non-capture action);
  /// increments for each forced chain continuation within the same turn.
  final int chainStep;

  /// True when the engine determined another capture is mandatory from
  /// [destination] before the turn can pass.
  final bool chainContinues;

  final Side resultingTurn;
  final String rulesetId;
  final int rulesetVersion;

  const MoveEvent({
    required this.matchId,
    required this.actionSequence,
    required this.actor,
    required this.actionType,
    required this.source,
    required this.destination,
    required this.capturedNodes,
    required this.chainStep,
    required this.chainContinues,
    required this.resultingTurn,
    required this.rulesetId,
    required this.rulesetVersion,
  });

  Map<String, Object?> toJson() => {
    'schemaVersion': schemaVersion,
    'matchId': matchId,
    'actionSequence': actionSequence,
    'actor': actor.name,
    'actionType': actionType,
    'source': source,
    'destination': destination,
    'capturedNodes': capturedNodes,
    'chainStep': chainStep,
    'chainContinues': chainContinues,
    'resultingTurn': resultingTurn.name,
    'rulesetId': rulesetId,
    'rulesetVersion': rulesetVersion,
  };

  factory MoveEvent.fromJson(Map<String, Object?> json) => MoveEvent(
    matchId: json['matchId'] as String,
    actionSequence: json['actionSequence'] as int,
    actor: Side.values.byName(json['actor'] as String),
    actionType: json['actionType'] as String,
    source: json['source'] as String?,
    destination: json['destination'] as String?,
    capturedNodes: (json['capturedNodes'] as List).cast<String>(),
    chainStep: json['chainStep'] as int,
    chainContinues: json['chainContinues'] as bool,
    resultingTurn: Side.values.byName(json['resultingTurn'] as String),
    rulesetId: json['rulesetId'] as String,
    rulesetVersion: json['rulesetVersion'] as int,
  );

  @override
  bool operator ==(Object other) =>
      other is MoveEvent &&
      other.matchId == matchId &&
      other.actionSequence == actionSequence &&
      other.actor == actor &&
      other.actionType == actionType &&
      other.source == source &&
      other.destination == destination &&
      _listEquals(other.capturedNodes, capturedNodes) &&
      other.chainStep == chainStep &&
      other.chainContinues == chainContinues &&
      other.resultingTurn == resultingTurn &&
      other.rulesetId == rulesetId &&
      other.rulesetVersion == rulesetVersion;

  @override
  int get hashCode => Object.hash(
    matchId,
    actionSequence,
    actor,
    actionType,
    source,
    destination,
    Object.hashAll(capturedNodes),
    chainStep,
    chainContinues,
    resultingTurn,
    rulesetId,
    rulesetVersion,
  );

  @override
  String toString() =>
      'MoveEvent(#$actionSequence $actor $actionType $source->$destination '
      'captured=$capturedNodes chainStep=$chainStep continues=$chainContinues)';
}

bool _listEquals(List<NodeId> a, List<NodeId> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
