# Premium UI/UX and Visual System

## Direction

Create a sophisticated, warm tabletop experience—not a heavy 3D engine. The board is procedurally drawn with `CustomPainter` from the validated graph: layered wood/stone base, subtle grain/noise, engraved paths, directional light, soft ambient shadow, and high-contrast junctions. Beads use radial gradients, rim highlights, contact shadows, and short eased movement to suggest depth. Never let decoration obscure legal connections or reduce touch targets.

## Responsive composition

- Portrait phones: board dominates center; compact player rails above/below; bottom action sheet.
- Landscape/tablets: centered board inside safe area; player rails on sides; secondary information docked, never overlaying critical nodes.
- Use `LayoutBuilder`, safe areas, text scaling, minimum 48dp targets, and board transforms that preserve graph aspect ratio.
- Hit testing maps screen coordinates to graph nodes with a generous responsive radius, but validates with engine actions.

## Opponent move communication

For **both** a local-human opponent and the Machine, serialize visible opponent actions: source ring/glow and semantic announcement; directional path/trail; bead travel along validated graph geometry; destination pulse; persistent last-move source→destination marker; and a localized turn banner when complete. Use shape/pattern/labels in addition to colour. Input is locked only for the active presentation sequence and exposes an accessible “opponent move in progress” status.

A capture explicitly highlights the jumped bead before its removal. A multi-capture plays source → over → landing one jump at a time, with the current chain step announced and the forced continuation retained until the engine reports it complete. Do not hide a chain behind a final-state update.

Before a machine action, present a localized, screen-reader-visible thinking indicator. AI calculation stays off the UI path; any display delay is bounded, cancellable/skippable where accessibility requires, and follows the clock policy. Pause, restart, resign, and lifecycle loss cancel visual work safely and redraw the authoritative state.

## States and motion

Resting, selected, legal move, capturable, last action, forced capture, opponent source/destination/path, machine thinking, move playback lock, disabled, paused, timer warning, win/loss/draw. Motions: 120–220ms eased piece slide, restrained capture pulse, victory confetti only on capable tier. Synchronize move/capture/end sound and optional haptics with timeline events. Reduced motion replaces travel/particles with immediate state transitions while retaining source, destination, capture and turn cues long enough to comprehend.

## Quality tiers

Auto-detect conservatively, with user override:

| Tier | Treatment |
|---|---|
| Low | flat gradients, no blur/particles, static shadows; crisp source/destination and instant or very short travel |
| Standard | cached board layers, soft shadows, lightweight path/trail and motion |
| High | subtle shaders/noise and restrained particles/trails only after profiling |

Cache static painting; repaint only changed pieces/overlays. Target smooth 60fps on typical devices and preserve responsiveness on low-end hardware.

## Accessibility

Semantic labels name piece, node and available moves; logical focus order follows board graph. Support TalkBack, keyboard/D-pad where available, scalable typography, high contrast, color-blind-safe bead patterns, and alternatives for sound/haptics.
