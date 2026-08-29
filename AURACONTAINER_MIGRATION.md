# CT_BuffMod → AuraContainer migration — feature mapping

Working design doc (branch `auracontainer-migration`). Not for distribution.

## The model shift

**Today (CT_BuffMod):** *read every aura → sort/group in Lua → place & style buttons ourselves.*
Impossible in combat under Midnight — reading auras from tainted code throws (secret values).

**AuraContainer:** *declare groups/slots by **filter string** + sort + layout + button styling; Blizzard's
SECURE code parses the (secret) auras and populates the frames.* We describe **what** to show and **how**
it looks; we never read the aura data. This is what makes buffs work **in combat**.

Creation (verified): `LoadAddOn("Blizzard_AuraContainer")` then
`CreateFrame("AuraContainer", name, parent, "CustomAuraContainerTemplate")`; call `:AddAuraGroup` /
`:AddAuraSlot` / `:AddItemEnchantment` + the Set*… setters on the frame instance.

## Feature mapping

Legend: ✅ survives · ◐ partial / constrained · ❓ needs verification · ❌ lost (secret-values wall)

| CT_BuffMod feature | AuraContainer mechanism | Verdict |
|---|---|---|
| Show buffs / debuffs (HELPFUL/HARMFUL) | group `filterString` | ✅ |
| Cancelable vs uncancelable grouping | `filterString`/`candidateFilters` — Blizzard's SECURE parser may honour CANCELABLE where our tainted `GetAuraDataByIndex` can't | ❓ (test — could actually come *back*) |
| "Own" (player-cast) separation | `candidateFilters` / filter tokens (PLAYER) | ◐❓ |
| Multiple sections (groupBy / groupByPriority) | one `AddAuraGroup` per section, ordered by layout | ✅ |
| Sort by name / time / expires / index | per-group `SetAuraGroupSortMethod(sortMethod, sortDirection)` — Blizzard sorts securely, so **time sorting works in combat** (ours can't) | ✅❓ (confirm the sort-method enum has our equivalents) |
| separateOwn / separateZero ordering | may not map to the built-in sort options | ◐❓ |
| Anchor point, x/y offset, wrap, growth dir, min size | per-group flow layout (`SetAuraGroupLayout`) | ✅◐ (map fields at POC time) |
| Max buttons shown | `maxFrameCount` in group options | ✅ |
| Temporary weapon enchants | `AddItemEnchantment(slot, options)` + `SetItemEnchantmentLayout/SortMethod` | ✅ (a reason to migrate) |
| Icon / stack count / cooldown swipe | CustomAuraButton built-ins + `initializeFrame`/`templateNames` | ✅◐ |
| Border colour by dispel type | `CustomAuraButtonDispelTypeTextureStyle` (Border/BorderWithIcon/Icon/…) | ✅ |
| Custom fonts / colours / sizes / custom timer text | `initializeFrame` callback styles each button — but text driven by aura **values** we can't read | ◐ (cosmetic ✅; value-derived text ❌) |
| Tooltips on hover | CustomAuraButton built-in (secure) | ✅ |
| Right-click to cancel a buff | CustomAuraButton is a secure Blizzard button → may cancel natively, **in combat too** | ✅❓ (confirm; would be a gain over the unsecure fallback) |
| Custom per-buff conditions / `visCondition` reading aura state | needs reading aura data | ❌ |
| Show/hide window by combat / vehicle state | we Show/Hide the container frame (those states aren't secret) | ✅ |
| Consolidation (`consolidateTo`) | already removed from the game | ❌ n/a |
| Per-unit windows (player/target/focus/pet) | one container per unit/window | ✅❓ (confirm how the container's unit is assigned) |

## Net picture

- **Big win:** buffs display **in combat** again — plus time-based sorting, tooltips, and possibly
  click-to-cancel come back *in combat*, which even the old secure header gave up on.
- **Standard styling/sorting/layout** largely survive via the built-in options + `initializeFrame`.
- **The losses are the same wall as the unit-frame text:** anything that needs to *read* aura values in
  our code — custom conditions, bespoke sort logic, value-derived text/abbreviation — can't be done.

## Open questions to resolve during the player-frame POC

1. Sort-method enum values — do NAME/TIME/EXPIRES/INDEX equivalents exist? (`Blizzard_AuraContainerShared`)
2. Flow-layout option field names (direction, spacing, wrap/stride, min size). (`…FlowLayout`)
3. Does the secure CANCELABLE / NOT_CANCELABLE filtering work in a group (vs. our broken tainted read)?
4. Does CustomAuraButton support right-click cancel, and in combat?
5. How is the container's **unit** set (for target/focus/pet windows)?
6. How much per-button styling `initializeFrame` actually allows.

## Approach

Additive + capability-gated (Mainline only; Classic/Cata keep SecureAuraHeaderTemplate), behind a feature
flag. Build the **player buff frame** first, resolve the open questions in-game, then expand.
