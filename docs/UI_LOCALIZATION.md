# Shared UI languages

The production Phonk and universal V3 adapters include ten languages: English, Filipino, Indonesian, Vietnamese, Thai, Spanish, Brazilian Portuguese, French, German and Russian.

Choose Settings > Appearance > Language. English is always the initial default, regardless of Roblox locale. Manual choices save in each game's existing UI configuration. Reset saved UI settings restores English. Re-execute the normal loader to obtain the update; its URL is unchanged.

Translations are bundled locally: no translation API or additional translation requests. Known shared UI and common feature labels translate immediately. Unlisted game-specific phrases remain English. This is not full automatic translation of arbitrary game manifests. Player names, game titles, typed feedback, callback keys and saved gameplay values remain original. Existing layout and scale defaults are retained; translated labels may wrap within their existing space.

## Maintaining translations

Edit src/ui/localization/translations.txt: each line is English|Filipino|Indonesian|Vietnamese|Thai|Spanish|Portuguese|French|German|Russian. Keep ten columns, unique English keys and no literal pipe characters within phrases. Add future game feature labels here without changing their control IDs. Runtime binding logic lives in src/ui/localization/i18n-core.lua.

Run `python scripts/build-ui-locales.py` to rebuild the marked translation sections in both dist/ui/phonk-v3-1-0.lua and dist/ui/universal-v3-2-0.lua. Commit sources and both generated bundles together. Shared V3 manifests receive the selector automatically; legacy V12 adapters are not changed.

## Release validation

Mocked Roblox tests passed for both production adapters: all ten language selections, English default despite a Spanish Roblox locale, saved language restoration, deferred selection rendering and Filipino confirmation, unchanged feedback drafts, stable canonical option values, original desktop row height, viewport resizing and connection cleanup. The universal fixture verified 51 game controls, gameplay callback isolation, saved gameplay state, reset and runtime cleanup. These checks do not replace live PC/mobile testing of every supported game.


## Offline audit and validation (September 22, 2026)

Run `python scripts/audit-ui-locales.py path/to/readable-game.lua` before publishing a game. It prints a JSON checklist of missing literal UI fields and dynamic expressions needing review. With no paths it scans dist/ui and dist/runtime/games. `--strict` fails on missing literals. This is a heuristic, not a Lua parser or a completeness guarantee: manually review option arrays, notifications, proper names, custom UI and dynamically built strings. Obfuscated Luraph files are reported as unscannable; audit their readable source before obfuscation. No scanner runs on players' devices.

The build now rejects empty columns, duplicate keys, surrounding whitespace and mismatched named or printf placeholders. Run `python scripts/test-ui-locales.py`, then `python scripts/build-ui-locales.py`. Commit locale_dictionary.py with the builder. Translations remain bundled, with no API requests.

Runtime translation now supports a dictionary-backed label followed by `: ` or ` · ` and a numeric value (digits, commas, decimal points), e.g. `Selected Pets: 3` and `Active now · 1,250`. It preserves the numeric text exactly. Unknown labels and name-valued strings remain unchanged. Arbitrary counters with units, rich text and sentences need explicit future templates; they are not automatically rewritten. Exact dictionary matches take precedence.

English default, manual language saving, scale, gameplay callbacks and option values are unchanged. New offline checks passed for dictionary validation and scanner fixtures; Lua runtime checks covered all ten languages, numeric labels and unknown/name preservation. PC/mobile rendering still needs live verification.
