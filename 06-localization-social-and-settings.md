# Localization, Local Social, and Settings

## English and Urdu

Use Flutter ARB localization; no hard-coded user-facing strings. Supply `app_en.arb` and `app_ur.arb`, plural/select support, semantic translations, and localized quick-chat/badge/rule content. Urdu uses `Locale('ur')`, RTL `Directionality`, an embedded Urdu-capable font with its license, and visual QA on all screens. Numerals/time formatting must be intentional and consistent; game node identifiers are not exposed as untranslated technical labels.

Language control is a Settings dropdown plus an optional first-launch choice. Apply instantly, persist locally, and ensure dialogs, navigation icons, alignment, and chat bubbles mirror correctly. Preserve board geometry; game coordinates do not change under RTL.

## Move-feedback preferences

Sound and haptics must be independently configurable and synchronized only to accepted presentation-timeline events (selection, travel, capture and match end). Reduced motion must not remove the ability to identify an opponent move: preserve a localized source/destination, capture and turn-transition cue without relying solely on animated travel. Visual-quality selection (Auto/Low/Standard/High) applies to trails, blur and particles, not to legal-move visibility, replay data or accessibility semantics.

Machine-thinking and chained-capture announcements must be localized, including Urdu RTL review. TalkBack users receive ordered, concise descriptions of actor, source, destination, captured piece(s), chain step and next turn; stable internal node IDs are never exposed as raw technical copy.

## Settings defaults

Sound on, haptics on when supported, language follows device on first run, Standard visual quality, timer off, reduced motion follows system. Changes must preview where reasonable and persist immediately.

## Privacy

All profile data, match history and quick chat remain on device. No permissions beyond those genuinely required; no contacts, microphone, camera, location or Internet permission for the base release. Present a concise in-app privacy statement and a local-data deletion control with confirmation.
