# CTMod Midnight

An **unofficial community port** of the classic **CTMod** addon suite, updated for
**World of Warcraft "Midnight" (12.0, interface `120000`)**. The base `.toc` files
also retain The War Within (11.x) compatibility, and Classic Era / Cataclysm Classic
TOCs are included.

This port builds on the original CTMod by **Cide, TS, Resike and Dahk Celes**, and
follows the precedent of the
[CTMod Classic Revival](https://www.curseforge.com/wow/addons/ctmod-classic-revival)
fork. All original credits and the upstream license are preserved unchanged — see
[`CT_Library/README.txt`](CT_Library/README.txt).

## Installation

1. Download / clone this repository.
2. Copy the `CT_*` folders into your `World of Warcraft\_retail_\Interface\AddOns\` directory.
3. Restart the game (or `/reload`) and enable the modules on the character-select / AddOns screen.

`CT_Library` is required by all modules.

## Modules

| Module | Status on Midnight |
|---|---|
| **CT_Library** | Ported. Shared infrastructure — added `CT_Library.safeValue` (secret-value sanitizer) and `CT_Library.getSpellName`, plus tolerant event registration. |
| **CT_Core** | Ported. |
| **CT_MailMod** | Ported. |
| **CT_MapMod** | Ported (map-pin click/drag reworked for the modern MapCanvas). |
| **CT_BuffMod** | Ported. Combat-safe aura tracking (keyed by `auraInstanceID`). |
| **CT_ExpenseHistory** | Ported (`GetMerchantItemInfo` → `C_MerchantFrame.GetItemInfo`). |
| **CT_Timer** | Ported. |
| **CT_Viewport** | Ported. |
| **CT_PartyBuffs** | Ported. |
| **CT_UnitFrames** | Ported (secret-value guards). Assist/Focus frames remain disabled on retail. |
| **CT_RaidAssist** | Ported (secret-value guards). Raid-combat behavior degrades gracefully rather than erroring. |
| **CT_BarMod** | Ported and crash-free — see limitation below. |
| **CT_BottomBar** | **Disabled on retail** — superseded by Blizzard's built-in Edit Mode. Still available on Classic / Cata. |

## Known limitations

- **CT_BarMod** runs crash-free in combat, but does **not** display live cooldown
  swipes, stack counts, charges, or proc glow during combat. In Midnight, that action
  data is a restricted "secret value" to insecure (addon) code; showing it would
  require rebuilding the bars on Blizzard's secure action-button system.
- **CT_BottomBar** is intentionally disabled on retail. Its purpose (splitting the
  main bar into movable pieces) is now native via Edit Mode.
- **CT_RaidAssist / CT_UnitFrames** skip individual bar updates when a value is
  restricted in combat, rather than crashing.

See [`CHANGELOG.md`](CHANGELOG.md) for the full list of Midnight changes.

## License & credits

CTMod is distributed **"all rights reserved"**; the CTMod team requests that you
contact them before modifying or redistributing. This community port preserves that
notice and all original credits — full text in [`CT_Library/README.txt`](CT_Library/README.txt).

- Original CTMod: **Cide**, **TS**, **Resike**, **Dahk Celes (DDCorkum)** and the CTMod team.
- "World of Warcraft" and related marks are property of Blizzard Entertainment.

This is an unofficial fan port and is not affiliated with or endorsed by the CTMod
team or Blizzard Entertainment.
