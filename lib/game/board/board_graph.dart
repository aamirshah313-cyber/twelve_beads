/// Stable node identifier. Nodes are named `r{row}c{col}`, row/col in 0..4,
/// row 0 = top, col 0 = left — matching the reference image's top-to-bottom,
/// left-to-right reading order. IDs are never derived from pixel position.
typedef NodeId = String;

/// A single-cell grid coordinate used only for procedural rendering layout.
/// This is not a pixel position: the presentation layer maps it onto the
/// screen while preserving the graph's aspect ratio (see
/// 04-ui-ux-and-visual-system.md).
class GridPosition {
  final int row;
  final int col;

  const GridPosition(this.row, this.col);

  @override
  bool operator ==(Object other) =>
      other is GridPosition && other.row == row && other.col == col;

  @override
  int get hashCode => Object.hash(row, col);

  @override
  String toString() => 'GridPosition($row, $col)';
}

/// A capture relation: a piece at [source] jumps over an opponent piece at
/// [over] and lands on [landing]. [source], [over] and [landing] are
/// pairwise distinct declared board nodes; the source->over and over->landing
/// steps are both declared graph edges, collinear in the same direction.
///
/// Jump relations are precomputed once from the declared edge set (see
/// [BoardGraph.standard]) and covered by tests — never guessed from a
/// geometric midpoint or pixel coordinates at runtime.
class Jump {
  final NodeId source;
  final NodeId over;
  final NodeId landing;

  const Jump({required this.source, required this.over, required this.landing});

  @override
  bool operator ==(Object other) =>
      other is Jump &&
      other.source == source &&
      other.over == over &&
      other.landing == landing;

  @override
  int get hashCode => Object.hash(source, over, landing);

  @override
  String toString() => 'Jump($source -> over $over -> $landing)';
}

/// Immutable, explicit adjacency graph for the Twelve Beads board.
///
/// Derived from inspecting the supplied reference board image: a 5x5 grid of
/// 25 junctions with every orthogonal neighbor connected by a drawn line, and
/// both diagonals drawn in each of the 16 unit cells (full Alquerque-style
/// connectivity — the interior 3x3 block of nodes has 8-way connectivity,
/// edge-non-corner nodes have 5-way, corners have 3-way). See
/// `docs/spec/board-graph.md` for the annotated diagram and
/// `docs/spec/DECISIONS.md` for open rule questions this graph does not
/// resolve on its own.
///
/// This is domain data only: no Flutter imports, no rendering, no rules.
class BoardGraph {
  static const int gridSize = 5;

  final Map<NodeId, GridPosition> positions;
  final Map<NodeId, Set<NodeId>> edges;
  final List<Jump> jumps;

  const BoardGraph({
    required this.positions,
    required this.edges,
    required this.jumps,
  });

  static NodeId idFor(int row, int col) => 'r${row}c$col';

  static bool _inBounds(int row, int col) =>
      row >= 0 && row < gridSize && col >= 0 && col < gridSize;

  List<NodeId> get nodeIds => positions.keys.toList(growable: false);

  bool isValidNode(NodeId node) => positions.containsKey(node);

  Set<NodeId> neighborsOf(NodeId node) => edges[node] ?? const <NodeId>{};

  bool hasEdge(NodeId a, NodeId b) => edges[a]?.contains(b) ?? false;

  List<Jump> jumpsFrom(NodeId node) =>
      jumps.where((jump) => jump.source == node).toList(growable: false);

  /// Builds and validates the standard Twelve Beads board graph.
  factory BoardGraph.standard() {
    final positions = <NodeId, GridPosition>{
      for (var row = 0; row < gridSize; row++)
        for (var col = 0; col < gridSize; col++)
          idFor(row, col): GridPosition(row, col),
    };

    final edges = <NodeId, Set<NodeId>>{
      for (final id in positions.keys) id: <NodeId>{},
    };

    void addEdge(int r1, int c1, int r2, int c2) {
      final a = idFor(r1, c1);
      final b = idFor(r2, c2);
      edges[a]!.add(b);
      edges[b]!.add(a);
    }

    // Orthogonal edges: every horizontal and vertical neighbor pair.
    for (var row = 0; row < gridSize; row++) {
      for (var col = 0; col < gridSize; col++) {
        if (_inBounds(row, col + 1)) addEdge(row, col, row, col + 1);
        if (_inBounds(row + 1, col)) addEdge(row, col, row + 1, col);
      }
    }

    // Diagonal edges: both diagonals of every unit cell, per the reference
    // image (a dense X pattern fills all 16 cells, not just alternating
    // ones or the board's two long diagonals).
    for (var row = 0; row < gridSize - 1; row++) {
      for (var col = 0; col < gridSize - 1; col++) {
        addEdge(row, col, row + 1, col + 1); // "\" diagonal
        addEdge(row, col + 1, row + 1, col); // "/" diagonal
      }
    }

    // Directed axes used to derive Jump(source, over, landing) relations. A
    // jump is only emitted when both the source->over and over->landing
    // steps are declared graph edges collinear in the same direction.
    const directions = <List<int>>[
      [0, 1], [0, -1], // horizontal
      [1, 0], [-1, 0], // vertical
      [1, 1], [-1, -1], // "\" diagonal
      [1, -1], [-1, 1], // "/" diagonal
    ];

    final jumps = <Jump>[];
    for (var row = 0; row < gridSize; row++) {
      for (var col = 0; col < gridSize; col++) {
        for (final direction in directions) {
          final overRow = row + direction[0];
          final overCol = col + direction[1];
          final landingRow = row + direction[0] * 2;
          final landingCol = col + direction[1] * 2;
          if (!_inBounds(overRow, overCol) ||
              !_inBounds(landingRow, landingCol)) {
            continue;
          }
          final source = idFor(row, col);
          final over = idFor(overRow, overCol);
          final landing = idFor(landingRow, landingCol);
          if (edges[source]!.contains(over) && edges[over]!.contains(landing)) {
            jumps.add(Jump(source: source, over: over, landing: landing));
          }
        }
      }
    }

    return BoardGraph(
      positions: Map.unmodifiable(positions),
      edges: {
        for (final entry in edges.entries)
          entry.key: Set.unmodifiable(entry.value),
      },
      jumps: List.unmodifiable(jumps),
    );
  }
}

/// Standard Twelve Beads starting layout (confirmed by the product owner:
/// the reference image's board geometry is authoritative, but its piece
/// placement is illustrative only — the real game seeds 12 beads per side,
/// matching the classic 12-a-side Alquerque arrangement). Each side holds
/// its two home rows (10 nodes) plus the two middle-row nodes nearest its
/// home side; the board's true center node is the only empty starting
/// point. The layout is 180°-rotationally symmetric about the center.
/// Recorded as resolved in `docs/spec/DECISIONS.md`.
class StandardStartingLayout {
  static final Set<NodeId> topSide = <NodeId>{
    for (var col = 0; col < BoardGraph.gridSize; col++) ...[
      BoardGraph.idFor(0, col),
      BoardGraph.idFor(1, col),
    ],
    BoardGraph.idFor(2, 0),
    BoardGraph.idFor(2, 1),
  };

  static final Set<NodeId> bottomSide = <NodeId>{
    for (var col = 0; col < BoardGraph.gridSize; col++) ...[
      BoardGraph.idFor(3, col),
      BoardGraph.idFor(4, col),
    ],
    BoardGraph.idFor(2, 3),
    BoardGraph.idFor(2, 4),
  };

  static final Set<NodeId> empty = <NodeId>{BoardGraph.idFor(2, 2)};
}
