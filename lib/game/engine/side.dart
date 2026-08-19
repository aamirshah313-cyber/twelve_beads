/// The two sides of a match, matching the board-derived starting layout in
/// `board_graph.dart` (`StandardStartingLayout.topSide` / `.bottomSide`).
enum Side { top, bottom }

extension SideX on Side {
  Side get opponent => this == Side.top ? Side.bottom : Side.top;
}
