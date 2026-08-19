import '../../../core/l10n/gen/app_localizations.dart';
import '../../../game/board/board_graph.dart';

/// Plain-language description of a node for screen readers — stable node
/// IDs like `r1c2` are never exposed as raw technical copy. Shared by the
/// move-presentation announcements (match_screen.dart) and every board
/// node's own semantic label (board_widget.dart), so a TalkBack user can
/// always tell which junction a piece or cue refers to, not just its owner.
String describeNode(AppLocalizations l10n, NodeId nodeId) {
  final row = int.parse(nodeId.substring(1, 2));
  final col = int.parse(nodeId.substring(3, 4));
  return l10n.nodePosition(row + 1, col + 1);
}
