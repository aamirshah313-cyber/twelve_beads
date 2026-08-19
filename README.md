# Twelve Beads / بارہ گوٹی — Implementation Specification

This documentation set is a sequential build brief for a Flutter/Dart Android game. Start with `00-master-claude-code-prompt.md`, then use the numbered files in order.

## Source-board gate

The supplied reference image is expected at `/mnt/data/images.jpg`. It is a **rules/reference artifact**, not a runtime texture or gameplay board. Before implementing the board, inspect it and encode its junctions and legal connections as a tested data graph. Do not infer a standard 5×5 grid or substitute a generic board without validating the image first.

## Document order

1. `00-master-claude-code-prompt.md`
2. `01-product-requirements.md`
3. `02-board-rules-and-engine.md`
4. `03-architecture-and-data.md`
5. `04-ui-ux-and-visual-system.md`
6. `05-ai-and-gameplay-systems.md`
7. `06-localization-social-and-settings.md`
8. `07-android-quality-security-and-release.md`
9. `08-testing-and-delivery-plan.md`

## Decision record

Where regional Twelve Beads rules vary, keep variants explicit, named, local-only settings. The image-derived board graph and the selected ruleset must be recorded in code, tests, and this project’s README before the first playable build.

## Opponent-move contract

Both local-human and machine opponents use the same graph-driven visual move timeline: source/destination cue, path/trail, travel, explicit capture removal, per-step chained captures, last-move marker and turn transition. Machine thinking is visible and accessible. The authoritative record is the versioned engine action log plus stable-node move events, allowing deterministic replay; animation is presentation only. Reduced-motion and Low-quality modes retain clear non-colour move cues while reducing or removing costly effects.
