# Product Requirements

## Product scope

**Twelve Beads / بارہ گوٹی** is a premium local board game for Android. It must be usable without a connection after installation.

## Core journeys

| Journey | Required outcome |
|---|---|
| Quick play | Select mode and start in at most three taps. |
| Two players | Two people share one device; colors, names, turn and timer are unmistakable. |
| Vs machine | Choose profile, color/first turn, difficulty: Easy, Medium, Difficult. AI plays locally. |
| Resume | An interrupted non-terminal game offers Resume/Discard on launch. |
| Learn | Rules explain the validated board, move/capture logic, timer and variants. |
| Progress | Local profile shows matches, W/L/D, streak, captures, time and badges. |

## Features

- Home: Play, How to Play, Profile, Settings; current language is visible.
- Modes: local two-player; one player vs machine. No online matching in this release.
- Pre-game: player names, bead theme/colors with accessible contrast, first-player selector (random/P1/P2), difficulty, timer and optional rule variant.
- In-game: selected-piece state, legal destination/capture cues, turn banner, pause, restart, resign, rules, undo only when its defined policy permits it. Each opponent action has source/destination highlights, directional path/trail, piece movement, capture/chained-capture steps, last-move marker and turn-transition feedback.
- Timers: off; total time per player 1/3/5/10/15/custom min; optional per-move 15/30/45/60/custom sec; warning threshold; timeout result.
- Settings: English/اردو dropdown, audio, haptics, reduced motion, high contrast, visual quality, text scale behavior, timer defaults.
- Local quick chat: contextual phrases/emotes (for example “Good move”, “Your turn”, “Well played”) displayed transiently in the match. No keyboard, cloud, or transmission.
- Profiles: local display name/avatar selection, history, statistics and badges. One default profile is sufficient; support multiple local profiles if low-cost.

## Non-goals, version 1

- Network multiplayer, real-time text chat, accounts, payments, advertisements, social sharing, and remote leaderboards.
- A rule engine based on visual hit boxes or a static board bitmap.

## Acceptance criteria

- A player can finish every mode offline after first install.
- A legal move can never be rejected because of rendering state; an illegal move cannot be executed by UI or AI.
- Every terminal match produces exactly one history record and badge evaluation.
- Language switch updates all UI without restart and persists.
- Pausing/backgrounding cannot give either timer unearned elapsed time beyond the explicitly documented policy.
- A player can visually identify every opponent move and capture without manually reconstructing the board; this remains true with reduced motion and Low visual quality.
