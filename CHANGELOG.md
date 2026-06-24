# Changelog

All notable changes for the CTMod Midnight community port.

## [12.0.0] — Midnight (WoW 12.0) port

First release targeting World of Warcraft "Midnight" (interface `120000`). Base TOCs
also keep The War Within (11.x) compatibility; Classic Era and Cataclysm Classic TOCs
are retained.

### Suite-wide (CT_Library)
- Added `CT_Library.safeValue(v, default)` — a shared sanitizer for Midnight "secret
  values". In combat, insecure addon code cannot compare, do arithmetic on, or index
  tables with restricted unit/aura/action data; this probes a value and returns it
  only when usable. Consolidated four per-module copies into this one helper.
- Added `CT_Library.safeBool(v, default)` — the boolean counterpart, for restricted
  "secret booleans" (e.g. `UnitInRange`) that throw on a boolean test.
- Added `CT_Library.getSpellName(idOrName)` — resolves spell names across
  `C_Spell.GetSpellInfo` (retail) and `GetSpellInfo` (classic); also a spell-exists
  check. Replaced scattered fallbacks across modules.
- `regEvent` now skips events that don't exist on the current client instead of
  erroring (fixes init crash from the removed `LEARNED_SPELL_IN_TAB`).
- Fixed `SetIsUnrestricted` guard and a `GameTooltip:SetText` alpha-argument bug.
- Converted two German localization files (`CT_PartyBuffs`, `CT_UnitFrames`) from
  Windows-1252 to UTF-8.

### CT_BarMod
- Migrated removed globals: `IsSpellOverlayed` → `C_SpellActivationOverlay`,
  guarded `StartChargeCooldown`, `GetSpellInfo` → shared helper, removed proc-glow
  template, and the removed main-bar page-number frame.
- `GetActionCooldown` / `GetSpellCooldown` now return `enable` as a boolean — fixed
  the `enable > 0` comparisons.
- Sanitized all in-combat action-data reads (cooldown/count/charges) so the addon is
  crash-free in combat. **Note:** live cooldown/count/proc-glow do not display during
  combat (a secret-value/taint limitation of insecure action bars).

### CT_BuffMod
- Re-keyed aura tracking from `spellId` to `auraInstanceID` (spellId is a secret value
  in combat), fixing duplicate buttons piling up during combat.
- Sanitized aura name/duration/expiration/applications and caster class lookups.

### CT_ExpenseHistory
- `GetMerchantItemInfo` (removed) → `C_MerchantFrame.GetItemInfo` adapter.

### CT_MapMod
- Reworked map-pin click / drag handling for the modern MapCanvas pin system.

### CT_UnitFrames
- Guarded health/power bar text against secret values; stopped calling Blizzard's
  secure health-bar update from insecure code (taint fix). Assist/Focus frames remain
  disabled on retail.

### CT_RaidAssist
- Guarded health/power reads against secret values; wired `SPELLS_CHANGED` in place of
  the removed `LEARNED_SPELL_IN_TAB`.

### CT_PartyBuffs
- Added a `DebuffTypeColor` fallback table (the global is nil in Midnight).

### CT_Core, CT_MailMod, CT_Timer, CT_Viewport
- TOC bumps and minor compatibility fixes; verified working on Midnight.

### CT_BottomBar
- Left **disabled on retail** (superseded by Blizzard's Edit Mode). Classic / Cata
  builds unaffected.
