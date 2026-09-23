# Shared V3 rollout — 3.2.0

Owner confirmed PC/mobile Phonk production behavior and authorized rollout. The permanent public loader, access settings and protected game payloads remain unchanged.

All manifests using the shared V3 Build entry now receive the new UI. Phonk keeps the exact 3.1.0 adapter accepted on devices. Other V3 games use the universal adapter preserving original config paths, schema migrations, saved values, IDs, callbacks and core runtime ownership. Shared UI preferences have a separate per-universe file. About/Feedback/Settings are injected without removing game pages. Confirmed actions require confirmation.

Tests: Phonk's 24 controls and device/input lifecycle mock suite; actual Sell Ores manifest's 51 controls, no startup callbacks, saved-value restoration, default reset, live updates and cleanup; direct routing checks. Requests are mocked. Only Phonk has owner-confirmed live PC/mobile results; other games still need live observation.

Scripts importing legacy Create/Window renderers directly do not call V3 Build and remain on their existing UI. This release does not claim those interfaces are migrated. Their readable integration source or equivalent contract testing is required before replacing those interfaces.

Rollback: restore dist/ui/serenity-v3.lua from 67cc95033ad1105da3d65144169431a55e900f52 to return to Phonk-only rollout. Protected payloads are not modified.
