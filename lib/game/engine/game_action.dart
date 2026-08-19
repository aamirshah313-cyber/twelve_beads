import '../board/board_graph.dart';
import 'side.dart';

/// The four action types the engine accepts, per
/// 02-board-rules-and-engine.md. A chained-capture continuation is not a
/// distinct type: it is just another [CaptureAction] issued while
/// `GameState.mustContinueCaptureFrom` is set, constrained by
/// [legalActions] to originate from that node.
sealed class GameAction {
  const GameAction();

  Map<String, Object?> toJson();

  static GameAction fromJson(Map<String, Object?> json) {
    final type = json['type'] as String;
    switch (type) {
      case 'move':
        return MoveAction(
          from: json['from'] as NodeId,
          to: json['to'] as NodeId,
        );
      case 'capture':
        return CaptureAction(
          from: json['from'] as NodeId,
          over: json['over'] as NodeId,
          to: json['to'] as NodeId,
        );
      case 'resign':
        return ResignAction(Side.values.byName(json['side'] as String));
      case 'timeout':
        return TimeoutAction(Side.values.byName(json['side'] as String));
      default:
        throw ArgumentError('Unknown GameAction type: $type');
    }
  }
}

class MoveAction extends GameAction {
  final NodeId from;
  final NodeId to;

  const MoveAction({required this.from, required this.to});

  @override
  Map<String, Object?> toJson() => {'type': 'move', 'from': from, 'to': to};

  @override
  bool operator ==(Object other) =>
      other is MoveAction && other.from == from && other.to == to;

  @override
  int get hashCode => Object.hash('move', from, to);

  @override
  String toString() => 'MoveAction($from -> $to)';
}

class CaptureAction extends GameAction {
  final NodeId from;
  final NodeId over;
  final NodeId to;

  const CaptureAction({
    required this.from,
    required this.over,
    required this.to,
  });

  @override
  Map<String, Object?> toJson() => {
    'type': 'capture',
    'from': from,
    'over': over,
    'to': to,
  };

  @override
  bool operator ==(Object other) =>
      other is CaptureAction &&
      other.from == from &&
      other.over == over &&
      other.to == to;

  @override
  int get hashCode => Object.hash('capture', from, over, to);

  @override
  String toString() => 'CaptureAction($from -> over $over -> $to)';
}

class ResignAction extends GameAction {
  final Side side;

  const ResignAction(this.side);

  @override
  Map<String, Object?> toJson() => {'type': 'resign', 'side': side.name};

  @override
  bool operator ==(Object other) => other is ResignAction && other.side == side;

  @override
  int get hashCode => Object.hash('resign', side);

  @override
  String toString() => 'ResignAction($side)';
}

class TimeoutAction extends GameAction {
  final Side side;

  const TimeoutAction(this.side);

  @override
  Map<String, Object?> toJson() => {'type': 'timeout', 'side': side.name};

  @override
  bool operator ==(Object other) =>
      other is TimeoutAction && other.side == side;

  @override
  int get hashCode => Object.hash('timeout', side);

  @override
  String toString() => 'TimeoutAction($side)';
}
