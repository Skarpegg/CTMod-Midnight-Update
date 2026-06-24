------------------------------
-- CTMod Midnight (community port)

This is an unofficial community port of CTMod updated for World of Warcraft
"Midnight" (12.0, interface 120000). It builds on the original CTMod by Cide,
TS, Resike and Dahk Celes, and follows the precedent set by the "CTMod Classic
Revival" fork. All original credits and the license below are preserved
unchanged; the port adds only the changes needed for the modern client.

Summary of the Midnight work:
- Migrated removed/renamed APIs (C_Spell, C_MerchantFrame, C_SpellActivationOverlay,
  C_UnitAuras, etc.) and guarded removed globals.
- Handled Midnight "secret values": in combat, insecure addon code cannot
  compare/index restricted unit/aura/action data. Added a shared sanitizer
  (CT_Library.safeValue) plus a shared CT_Library.getSpellName helper.
- Known limitations: CT_BarMod is crash-free in combat but does not show live
  cooldown/count/proc-glow there (a taint/secret-value limit); CT_BottomBar is
  left disabled on retail (superseded by Blizzard's Edit Mode).

This port is offered in the same "all rights reserved" spirit as upstream: the
CTMod team retains all rights, and you should contact them before further
modifying or redistributing. Original authors and Blizzard trademarks remain
their respective owners' property.



------------------------------
-- Overall CTMod license

CTMod remains "all rights reserved"; specifically,
it is requested to contact the team before modifying or redistributing.

The CTMod team has included the following individuals over time:
- Cide (original author)
- TS (original author)
- Resike (since 2014)
- Dahk Celes / DDCorkum (since 2017)

CTMod is currently distributed through GitHub, CurseForge, WoWInterface and Wago.



------------------------------
-- CT_Library

CT_Library embeds the following addon libraries:
- LibStub by Kaelten et al. (public domain)
- LibDeflate by Haoqian He (zlib license)
- AceSerializer-3.0 by Nevcairiel et al. (see Libs\Ace3\Ace3-License.txt)
- TaintLess by foxlit (unmodified distribution of xml authorized)

To limit download sizes, CT_Library excludes extra files from each library
such as tutorials/instructions or .xml and .toc files that simply point 
to the main code in the .lua.   Please contact the CTMod team if you need 
any help to find these original files from the library authors.
(Hint: they are all on CurseForge, WoWI, or TLY.)



------------------------------
-- CT_RaidAssist

CTRA installs common libraries to allow users more freedom to choose any compatible addon, 
avoiding any pressure to install a particular one (CT or otherwise) to participate in a raiding guild.

CT_RaidAssist currently embeds the following addon library:
- LibDurability by funkehdude (CC BY-NC-SA 3.0)

CT_RaidAssit formerly embeded the following addon library:
- LibHealComm by Shadowed, Azilroka and xbeebs (license unknown), including CallbackHandler by nevcairiel (BSD license) and ChatThrottleLib by Mikk (license unknown)


------------------------------
-- Acknowledgements

The team also acknowledges the following contributions:
- Dargen (the former "Main Tank" module in CTRA)
- Dynaletik (much of the German localization)
- 萌丶汉丶纸 (much of the Chinese localization)



Dahk Celes (D.D. Corkum)
on behalf of the CTMod Team
25 Oct 2020 (updated 11 Sep 2021)