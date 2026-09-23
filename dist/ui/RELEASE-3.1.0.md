# Serenity UI 3.1.0 — Phonk rollout

Approved by the owner after RC1 testing on September 7, 2026.

The permanent root loader and routing/access code are unchanged. The shared V3 entry selects the new UI only for Phonk's known place/universe plus the exact Phonk manifest name. Other manifests retain the original V3 entry and renderers. Protected game payloads are unchanged.

The new Phonk UI contains the approved appearance, mobile layouts, launcher, preference persistence, and owner-approved direct feedback destination. UI preferences use SerenityHub/ui-phonk-v3-1.json; original session configuration remains owned by the game and Phonk automations still start OFF. Runtime replacement uses the supplied RuntimeKey and invokes old cleanup.

Validation: Lua subset compilation, 24 actual manifest controls, callback/default behavior, reset/reload, mobile bounds/input, feedback success/failure with mocked HTTP, cleanup and exact dispatch isolation. Owner accepted RC1; protected production payload execution and live delivery cannot be reproduced in the development environment.

Rollback: restore dist/ui/serenity-v3.lua from commit 2bce578a14b53a7454e7bfd08ea1dd58ee3b326c (or the preserved serenity-v3-legacy.lua). No game/config rollback is needed for this UI-only change.

Remaining rollout: adapt and regression-test Sell Ores and other games before widening dispatch. Do not use this Phonk-specific adapter as a universal V3 replacement.
