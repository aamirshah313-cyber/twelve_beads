import 'package:flutter_test/flutter_test.dart';
import 'package:twelve_beads/game/board/board_graph.dart';

void main() {
  group('BoardGraph.standard() node set', () {
    final graph = BoardGraph.standard();

    test('has exactly 25 nodes', () {
      expect(graph.nodeIds.length, 25);
    });

    test('node ids follow the r{row}c{col} scheme for row/col 0..4', () {
      for (var row = 0; row < 5; row++) {
        for (var col = 0; col < 5; col++) {
          expect(graph.isValidNode('r${row}c$col'), isTrue);
        }
      }
    });

    test('rejects ids outside the declared grid', () {
      expect(graph.isValidNode('r5c0'), isFalse);
      expect(graph.isValidNode('r0c5'), isFalse);
      expect(graph.isValidNode('bogus'), isFalse);
    });
  });

  group('BoardGraph.standard() edges (positive/negative cases)', () {
    final graph = BoardGraph.standard();

    test('has exactly 72 undirected edges (40 orthogonal + 32 diagonal)', () {
      final undirected = <String>{};
      graph.edges.forEach((node, neighbors) {
        for (final neighbor in neighbors) {
          final pair = ([node, neighbor]..sort()).join('|');
          undirected.add(pair);
        }
      });
      expect(undirected.length, 72);
    });

    test('orthogonal neighbors are connected', () {
      expect(graph.hasEdge('r0c0', 'r0c1'), isTrue);
      expect(graph.hasEdge('r0c0', 'r1c0'), isTrue);
      expect(graph.hasEdge('r2c2', 'r2c3'), isTrue);
      expect(graph.hasEdge('r2c2', 'r3c2'), isTrue);
    });

    test('both diagonals of a unit cell are connected', () {
      // Cell with corners r0c0, r0c1, r1c0, r1c1.
      expect(graph.hasEdge('r0c0', 'r1c1'), isTrue); // "\"
      expect(graph.hasEdge('r0c1', 'r1c0'), isTrue); // "/"
    });

    test('edges are undirected (symmetric adjacency)', () {
      expect(graph.hasEdge('r0c0', 'r0c1'), graph.hasEdge('r0c1', 'r0c0'));
      expect(graph.hasEdge('r0c0', 'r1c1'), graph.hasEdge('r1c1', 'r0c0'));
    });

    test('non-adjacent nodes are not connected (negative cases)', () {
      expect(graph.hasEdge('r0c0', 'r0c2'), isFalse); // two apart, same row
      expect(graph.hasEdge('r0c0', 'r2c0'), isFalse); // two apart, same col
      expect(graph.hasEdge('r0c0', 'r2c2'), isFalse); // two apart, diagonal
      expect(graph.hasEdge('r0c0', 'r1c2'), isFalse); // knight-shaped, no line
      expect(graph.hasEdge('r0c0', 'r0c0'), isFalse); // no self-loop
    });

    test('degree distribution matches the reference image reading', () {
      const corners = ['r0c0', 'r0c4', 'r4c0', 'r4c4'];
      for (final id in corners) {
        expect(
          graph.neighborsOf(id).length,
          3,
          reason: '$id should be a degree-3 corner',
        );
      }

      const edgeNonCorner = [
        'r0c1',
        'r0c2',
        'r0c3',
        'r4c1',
        'r4c2',
        'r4c3',
        'r1c0',
        'r2c0',
        'r3c0',
        'r1c4',
        'r2c4',
        'r3c4',
      ];
      for (final id in edgeNonCorner) {
        expect(
          graph.neighborsOf(id).length,
          5,
          reason: '$id should be a degree-5 boundary node',
        );
      }

      for (var row = 1; row <= 3; row++) {
        for (var col = 1; col <= 3; col++) {
          final id = 'r${row}c$col';
          expect(
            graph.neighborsOf(id).length,
            8,
            reason: '$id should be a degree-8 interior node',
          );
        }
      }
    });
  });

  group('BoardGraph.standard() 180-degree rotational symmetry', () {
    final graph = BoardGraph.standard();

    String rotate(String id) {
      final row = int.parse(id[1]);
      final col = int.parse(id[3]);
      return BoardGraph.idFor(4 - row, 4 - col);
    }

    test('every edge has a rotated counterpart edge', () {
      graph.edges.forEach((node, neighbors) {
        for (final neighbor in neighbors) {
          expect(
            graph.hasEdge(rotate(node), rotate(neighbor)),
            isTrue,
            reason: 'edge $node-$neighbor should have a rotated counterpart',
          );
        }
      });
    });

    test('every node has the same degree as its rotated counterpart', () {
      for (final id in graph.nodeIds) {
        expect(
          graph.neighborsOf(id).length,
          graph.neighborsOf(rotate(id)).length,
        );
      }
    });
  });

  group('BoardGraph.standard() jump relations (move-generation)', () {
    final graph = BoardGraph.standard();

    test('has exactly 96 directed jump relations', () {
      expect(graph.jumps.length, 96);
    });

    test(
      'all jump relations reference three pairwise-distinct declared nodes',
      () {
        for (final jump in graph.jumps) {
          expect(graph.isValidNode(jump.source), isTrue);
          expect(graph.isValidNode(jump.over), isTrue);
          expect(graph.isValidNode(jump.landing), isTrue);
          expect(jump.source, isNot(jump.over));
          expect(jump.over, isNot(jump.landing));
          expect(jump.source, isNot(jump.landing));
        }
      },
    );

    test('all jump relations are collinear across two real graph edges', () {
      for (final jump in graph.jumps) {
        expect(graph.hasEdge(jump.source, jump.over), isTrue);
        expect(graph.hasEdge(jump.over, jump.landing), isTrue);
      }
    });

    test('positive case: horizontal jump over an adjacent node', () {
      expect(
        graph.jumpsFrom('r0c0'),
        contains(const Jump(source: 'r0c0', over: 'r0c1', landing: 'r0c2')),
      );
    });

    test('positive case: diagonal jump through the center', () {
      expect(
        graph.jumpsFrom('r1c1'),
        contains(const Jump(source: 'r1c1', over: 'r2c2', landing: 'r3c3')),
      );
    });

    test('negative case: no jump when the landing node would be off-grid', () {
      expect(
        graph.jumpsFrom('r0c0'),
        isNot(
          contains(const Jump(source: 'r0c0', over: 'r0c1', landing: 'r1c0')),
        ),
      );
      final jumpsFromCorner = graph.jumpsFrom('r0c0');
      // Corner has exactly 3 legal jump directions: right, down, and the
      // down-right diagonal (all 3 of its degree-3 edges land in bounds).
      expect(jumpsFromCorner.length, 3);
    });

    test('negative case: no jump along a direction with no declared edge', () {
      // r0c0 -> r1c2 is not collinear along any declared axis.
      expect(
        graph.jumps,
        isNot(
          contains(const Jump(source: 'r0c0', over: 'r1c1', landing: 'r1c2')),
        ),
      );
    });
  });

  group('StandardStartingLayout', () {
    test('each side has exactly 12 nodes and exactly one node is empty', () {
      expect(StandardStartingLayout.topSide.length, 12);
      expect(StandardStartingLayout.bottomSide.length, 12);
      expect(StandardStartingLayout.empty.length, 1);
    });

    test('sides and the empty node are pairwise disjoint and cover the whole board', () {
      final graph = BoardGraph.standard();
      final union = {
        ...StandardStartingLayout.topSide,
        ...StandardStartingLayout.bottomSide,
        ...StandardStartingLayout.empty,
      };
      expect(
        union.length,
        25,
        reason: 'no overlaps and no gaps across all 25 nodes',
      );
      expect(union, equals(graph.nodeIds.toSet()));
      expect(
        StandardStartingLayout.topSide.intersection(
          StandardStartingLayout.bottomSide,
        ),
        isEmpty,
      );
    });

    test('the only empty starting node is the true board center', () {
      expect(StandardStartingLayout.empty, {'r2c2'});
    });

    test('layout is 180-degree rotationally symmetric between sides', () {
      String rotate(String id) {
        final row = int.parse(id[1]);
        final col = int.parse(id[3]);
        return BoardGraph.idFor(4 - row, 4 - col);
      }

      final rotatedTop = StandardStartingLayout.topSide.map(rotate).toSet();
      expect(rotatedTop, StandardStartingLayout.bottomSide);
    });
  });
}
