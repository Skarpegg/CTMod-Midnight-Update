------------------------------------------------
--            CT_RaidAssist (CTRA)            --
--                                            --
-- Provides features to assist raiders incl.  --
-- customizable raid frames.  CTRA was the    --
-- original raid frame in Vanilla (pre 1.11)  --
-- but has since been re-written completely   --
-- to integrate with the more modern UI.      --
--                                            --
-- Please do not modify or otherwise          --
-- redistribute this without the consent of   --
-- the CTMod Team. Thank you.                 --
--					      --
-- Original credits to Cide and TS            --
-- Improved by Dargen circa late Vanilla      --
-- Maintained by Resike from 2014 to 2017     --
-- Rebuilt by Dahk Celes (ddc) in 2019        --
------------------------------------------------

local __, module = ...;

-- Expansion Configuration Data
-- These tables should be updated every expansion or major patch to reflect new content



------------------------------------------------
-- CTRA_Configuration_Buffs

-- Which buffs could be applied out of combat by right-clicking the player frame?  Buffs listed first take precedence.
-- id:		spellId of any rank of this spell		(mandatory)
-- button: 	1 (left), or 2 (right).				(optional; mandatory if modifier has a value, or omit both for spells disabled by default)
-- modifier: 	nomod, mod, mod:shift, mod:ctrl, or mod:alt	(optional; mandatory if button has a value, or omit both for spells disabled by default)
module.CTRA_Configuration_Buffs =
{
	["DRUID"] = 
	{
		{["id"] = 1126, ["button"] = 2, ["modifier"] = "nomod"},		-- Mark of the Wild (Classic)
		{["id"] = 48470, ["button"] = 2, ["modifier"] = "mod:shift"},		-- Gift of the Wild (Classic)
	},
	["HUNTER"] =
	{
		{["id"] = 19506, ["button"] = 2, ["modifier"] = "nomod"},		-- Trueshot Aura
	},
	["MAGE"] =
	{
		{["id"] = 1459, ["button"] = 2, ["modifier"] = "nomod"},		-- Arcane Intellect
		{["id"] = 23028, ["button"] = 2, ["modifier"] = "mod:shift"},		-- Arcane Brilliance (Classic)
		{["id"] = 1008, ["button"] = 2, ["modifier"] = "mod:ctrl"},		-- Amplify Magic (Classic)
		{["id"] = 604, ["button"] = 2, ["modifier"] = "mod:alt"},		-- Dampen Magic (Classic)
	},
	["PALADIN"] = 
	{
		{["id"] = 20217, ["button"] = 2, ["modifier"] = "nomod"},		-- Blessing of Kings
		{["id"] = 19742, ["button"] = 2, ["modifier"] = "mod:shift"},		-- Blessing of Might
		{["id"] = 19740, ["button"] = 2, ["modifier"] = "mod:ctrl"},		-- Blessing of Wisdom
		{["id"] = 1038, ["button"] = 2, ["modifier"] = "mod:alt"},		-- Blessing of Salvation
	},
	["PRIEST"] =
	{
		{["id"] = 211681, ["button"] = 2, ["modifier"] = "nomod"},		-- Power Word: Fortitude (Retail)
		{["id"] = 1243, ["button"] = 2, ["modifier"] = "nomod"},		-- Power Word: Fortitude (Classic)
		{["id"] = 21562, ["button"] = 2, ["modifier"] = "mod:shift"},		-- Prayer of Fortitude (Classic)
		{["id"] = 976, ["button"] = 2, ["modifier"] = "mod:ctrl"},		-- Shadow Protection (Classic; no default keybind)
		{["id"] = 27683, ["button"] = 2, ["modifier"] = "mod:alt"},		-- Prayer of Shadow Protection (Classic, no default keybind)
	},
	["WARRIOR"] =
	{	
		{["id"] = 6673, ["button"] = 2, ["modifier"] = "nomod"},		-- Battle Shout
	},
}


------------------------------------------------
-- CTRA_Configuration_FriendlyRemoves

-- Which debuff removals could be cast in combat by right-clicking the player frame?  Buffs listed first take precedence.
-- id:		spellId of any rank of this spell		(mandatory)
-- button: 	1 (left), or 2 (right).				(optional; mandatory if modifier has a value, or omit both for spells disabled by default)
-- modifier: 	nomod, mod, mod:shift, mod:ctrl, or mod:alt	(optional; mandatory if button has a value, or omit both for spells disabled by default)
-- spec:	if set, this line only applies when GetInspectSpecialization("player") returns this SpecializationID
module.CTRA_Configuration_FriendlyRemoves =												
{			
	["DRUID"] =										
	{											
		{["id"] = 88423, ["button"] = 2, ["modifier"] = "nomod"},		-- Nature's Cure (Retail some specs)
		{["id"] = 2782, ["button"] = 2, ["modifier"] = (module:getGameVersion() <= 3 and "mod:shift" or "nomod")},	-- Remove Curse in classic, or Remove Corruption in retail
		{["id"] = 2893, ["button"] = 2, ["modifier"] = "nomod"},		-- Abolish Poison (Classic after lvl 26)
		{["id"] = 8946, ["button"] = 2, ["modifier"] = "nomod"},  		-- Cure Poison (Classic until lvl 26)
	},
	["MAGE"] =
	{
		{["id"] = 475, ["button"] = 2, ["modifier"] = "nomod"},			-- Remove Curse / Remove Lesser Curse
	},
	["MONK"] =
	{
		{["id"] = 115450, ["button"] = 2, ["modifier"] = "nomod"},		-- Detox
	},
	["PALADIN"] =
	{
		{["id"] = 4987, ["button"] = 2, ["modifier"] = "nomod"},		-- Cleanse (high-level in Classic, and some Retail specs)
		{["id"] = 213644, ["button"] = 2, ["modifier"] = "nomod"},		-- Cleanse Toxins (other Retail specs)
		{["id"] = 1152, ["button"] = 2, ["modifier"] = "nomod"},		-- Purify (low-level Classic)
	},
	["PRIEST"] = 
	{	
		{["id"] = 527, ["button"] = 2, ["modifier"] = "nomod"},			-- Purify (Retail some specs) / Dispel Magic (Classic)
		{["id"] = 213634, ["button"] = 2, ["modifier"] = "nomod"},		-- Purify Disease (Retail other specs)
		{["id"] = 528, ["button"] = 2, ["modifier"] = "mod:shift"},		-- Cure Disease (Classic)
	},
	["SHAMAN"] =
	{
		{["id"] = 77130, ["button"] = 2, ["modifier"] = "nomod"},		-- Purify Spirit (Retail some specs)
		{["id"] = 51886, ["button"] = 2, ["modifier"] = "nomod"},		-- Cleanse Spirit (Retail other specs)
		{["id"] = 526, ["button"] = 2, ["modifier"] = "mod:shift"},		-- Cure Poison (Classic)
		{["id"] = 2870, ["button"] = 2, ["modifier"] = "mod:alt"},		-- Cure Disease (Classic)
	},
}


------------------------------------------------
-- CTRA_Configuration_RezAbilities

-- Which ressurection spells could be cast by right-clicking the player frame?  Buffs listed first take precedence.
-- id:		spellId of any rank of this spell		(mandatory)
-- button: 	1 (left), or 2 (right).				(optional; mandatory if modifier has a value, or omit both for spells disabled by default)
-- modifier: 	nomod, mod, mod:shift, mod:ctrl, or mod:alt	(optional; mandatory if button has a value, or omit both for spells disabled by default)
-- combat: 	if set, this spell may be cast during combat	(optional; but either this or nocombat must be set to be useful)
-- nocombat:	if set, this spell may be cast outside combat	(optional; but either this or combat must be set to be useful)
module.CTRA_Configuration_RezAbilities =
{
	["DRUID"] =
	{
		{["id"] = 20484, ["button"] = 2, ["modifier"] = "nomod", ["combat"] = true},				-- Rebirth
		{["id"] = 50769, ["button"] = 2, ["modifier"] = "nomod", ["nocombat"] = true},				-- Revive
	},
	["DEATHKNIGHT"] =
	{
		{["id"] = 61999, ["button"] = 2, ["modifier"] = "nomod", ["combat"] = true, ["nocombat"] = true},	-- Raise Ally
	},
	["WARLOCK"] = 
		module:getGameVersion() >= 4 
			and {["id"] = 5232, ["button"] = 2, ["modifier"] = "nomod", ["combat"] = true}			-- Soulstone (Retail)
			or nil,
	["PALADIN"] =
	{
		{["id"] = 7328, ["button"] = 2, ["modifier"] = "nomod", ["nocombat"] = true},				-- Redemption
	},	
	["PRIEST"] =
	{
		{["id"] = 2006, ["button"] = 2, ["modifier"] = "nomod", ["nocombat"] = true},				-- Ressurrection
	},	
	["SHAMAN"] =
	{
		{["id"] = 2008, ["button"] = 2, ["modifier"] = "nomod", ["nocombat"] = true},				-- Ancestral Spirit
	},
}

------------------------------------------------
-- CTRA_Configuration_BossAuras

-- Which auras associated with boss encounters are important enough to emphasize in the middle of each frame?  Buffs listed first take presedence
-- key: 	spellId
-- value:	0 to always show, or a positive integer to show when the stack count is this number or greater
module.CTRA_Configuration_BossAuras =
{
	-- Debug Testing
	--[1459] = 0,		-- Arcane Intellect
	--[333049] = 2,		-- Fevered Incantation

	-- Mythic Plus Affixes
	[240443] = 2,		-- Mythic Plus: Bursting
	[209858] = 20,		-- Mythic Plus: Necrotic
	[240559] = 1,		-- Mythic Plus: Grievous
	
	-- Classic
	[19702] = 0,		-- Molten Core - Lucifron: Impending Doom
	[19703] = 0,		-- Molten Core - Lucifron: Lucifron's Curse
	[20604] = 0,		-- Molten Core - Lucifron: Dominate Mind
	[19408] = 0,		-- Molten Core - Magmadar: Panic
	[19716] = 0,		-- Molten Core - Gehennas: Gehenna's Curse
	[19658] = 0,		-- Molten Core - Baron Geddon: Ignite Mana
	[20475] = 0,		-- Molten Core - Baron Geddon: Living Bomb
	[19713] = 0,		-- Molten Core - Shazzrah: Shazzrah's Curse
	[13880] = 20,		-- Molten Core - Golemagg the Incinerator: Magma Splash
	[19776] = 0,		-- Molten Core - Sulfuron Harbinger: Shadow Word: Pain
	[20294] = 0,		-- Molten Core - Sulfuron Harbinger: Immolater
	[18431] = 0,		-- Onyxia's Lair - Onyxia: Bellowing Roar
	[23958] = 0,		-- Blackwing Lair - Razorgore the Untamed: Mind Exhaustion
	[18183] = 0,		-- Blackwing Lair - Vaelastrasz the Corrupt: Burning Adrenaline
	[24573] = 0,		-- Blackwing Lair - Broodlord Lashlayer: Mortal Strike
	[23341] = 5,		-- Blackwing Lair - Firemaw: Flame Buffet
	[23340] = 0,		-- Blackwing Lair - Ebonroc: Shadow of Ebonroc
	[23153] = 0,		-- Blackwing Lair - Chromaggus: Brood Affliction, Blue
	[23154] = 0,		-- Blackwing Lair - Chromaggus: Brood Affliction, Black
	[23155] = 0,		-- Blackwing Lair - Chromaggus: Brood Affliction, Red
	[23169] = 0,		-- Blackwing Lair - Chromaggus: Brood Affliction, Green
	[23170] = 0,		-- Blackwing Lair - Chromaggus: Brood Affliction, Bronze
	[23224] = 0,		-- Blackwing Lair - Nefarian: Veil of Shadow
	[23603] = 0,		-- Blackwing Lair - Nefarian: Wild Polymorph
	[23401] = 0,		-- Blackwing Lair - Nefarian: Corrupted Healing
	[24314] = 0,		-- Zul'Gurub - Bloodlord Mandokir: Threatening Gaze
	[24053] = 0,		-- Zul'Gurub - Jin'do the Hexxer: Hex
	[24321] = 0,		-- Zul'Gurub - Hakkar the Soulflayer: Poisonous Blood
	[24327] = 0,		-- Zul'Gurub - Hakkar the Soulflayer: Cause Insanity
	[24328] = 0,		-- Zul'Gurub - Hakkar the Soulflayer: Corrupted Blood
	[25189] = 0,		-- Ruins of Ahn'Qiraj - Ossirian the Unscarred: Enveloping Winds
	[25646] = 3,		-- Temple of Ahn'Qiraj - Battleguard Sartura: Mortal Wound
	[25812] = 2,		-- Temple of Ahn'Qiraj - The Bug Trio; Yauj, Vem and Kri: Toxic Volley
	[25991] = 2,		-- Temple of Ahn'Qiraj - Viscidus: Poison Bolt Volley
	[26050] = 5,		-- Temple of Ahn'Qiraj - Princess Huhuran: Acid Spit
	[26476] = 5,		-- Temple of Ahn'Qiraj - C'Thun: Digestive Acid
	[28796] = 0,		-- Naxxramas - Grand Widow Faerlina: Poison Bolt Volley
	[28622] = 0,		-- Naxxramas - Maexxna: Web Wrap
	[28776] = 0,		-- Naxxramas - Maexxna: Necrotic Poison
	[28213] = 0,		-- Naxxramas - Noth the Plaguebringer: Curse of the Plaguebringer
	[28832] = 5,		-- Naxxramas - The Four Horsemen: Mark of Korth'azz
	[28833] = 5,		-- Naxxramas - The Four Horsemen: Mark of Blaumeux
	[28834] = 5,		-- Naxxramas - The Four Horsemen: Mark of Mograine
	[28835] = 5,		-- Naxxramas - The Four Horsemen: Mark of Zeliek
	[28169] = 0,		-- Naxxramas - Grobbulus: Mutating Injection
	[28059] = 0,		-- Naxxramas - Thaddius: Positive Charge
	[28084] = 0,		-- Naxxramas - Thaddius: Negative Charge
	
	-- The Burning Crusade
	[29833] = 0,		-- Karazhan - Attumen the Huntsman: Intangible Presence
	

	-- Battle for Azeroth
	[255558] = 0,		-- Atal'Dazar - Priestess Alun'za: Tainted Blood
	[255371] = 0,		-- Atal'Dazar - Rezan: Terrifying Visage
	[255421] = 0,		-- Atal'Dazar - Rezan: Devour
	[265773] = 0,		-- King's Rest - The Golden Serpent: Spit Gold
	[267626] = 0,		-- King's Rest - Mchimba the Embalmer: Dessication
	[271563] = 5,		-- King's Rest - Embalming Fluid (trash)
	[260907] = 0,		-- Waycrest Manor - Heartsbane Triad: Soul Manipulation
	[260741] = 0,		-- Waycrest Manor - Heartsbane Triad: Jagged Nettles
	[268088] = 3,		-- Waycrest Manor - Heartsbane Triad: Aura of Dread
	[261439] = 0,		-- Waycrest Manor - Lord and Lady Waycrest: Virulent Pathogen
	[264560] = 0,		-- Shrine of the Storm - Aqu'sirr: Choking Brine
	[268211] = 0,		-- Shrine of the Storm - Minor Reinforcing Ward (trash)
	[268215] = 0,		-- Shrine of the Storm - Carve Flesh (trash)
	[267818] = 3,		-- Shrine of the Storm - Tidesage Council: Slicing Blast
	[269131] = 0,		-- Shrine of the Storm - Lord Stormsong: Ancient Mindbender
	[268896] = 0,		-- Shrine of the Storm - Lord Stormsong: Mind Rend
	[260685] = 0,		-- Underrot - Elder Leaxa: Taint of G'huun
	[256044] = 1,		-- Tol Dagor - Overseer Korgus: Deadeye
	[258337] = 0,		-- Freehold - Council o' Captains Blackout Barrel
	[265987] = 8,		-- Temple of Sethraliss - Galvazzt: Galvanized
	[294711] = 5,		-- The Eternal Palace - Abyssal Commander Sivara: Frost Mark
	[294715] = 5,		-- The Eternal Palace - Abyssal Commander Sivara: Toxic Brand
	[292133] = 0,		-- The Eternal Palace - Blackwater Behemoth: Bioluminescence
	[292138] = 0,		-- The Eternal Palace - Blackwater Behemoth: Radiant Biomass
	[296746] = 0,		-- The Eternal Palace - Radiance of Azshara: Arcane Bomb
	[296725] = 0,		-- The Eternal Palace - Lady Ashvane: Barnacle Bash
	[298242] = 0,		-- The Eternal Palace - Orgozoa: Incubation Fluid
	[298156] = 5,		-- The Eternal Palace - Orgozoa: Desensitizing Sting
	[301829] = 5,		-- The Eternal Palace - Queen's Court: Pashmar's Touch
	[292963] = 0,		-- The Eternal Palace - Za'qul: Dread
	[295173] = 0,		-- The Eternal Palace - Za'qul: Fear Realm
	[295249] = 0,		-- The Eternal Palace - Za'qul: Delirium Realm
	[298014] = 3,		-- The Eternal Palace - Queen Azshara: Cold Blast
	[300743] = 2,		-- The Eternal Palace - Queen Azshara: Void Touched
	[298569] = 1,		-- The Eternal Palace - Queen Azshara: Drained Soul
	[307056] = 0,		-- Ny'alotha - Wrathion: Burning Madness
	[306015] = 5,		-- Ny'alotha - Wrathion: Searing Armor
	[313250] = 50,		-- Ny'alotha - Wrathion: Creeping Madness
	[307839] = 0,		-- Ny'alotha - Maut: Devoured Abyss
	[307399] = 5,		-- Ny'alotha - Maut: Arcane Wounds
	[314337] = 1,		-- Ny'alotha - Maut: Ancient Curse
	[307937] = 0,		-- Ny'alotha - Prophet Skitra: Shred Psyche
	[307977] = 3,		-- Ny'alotha - Prophet Skitra: Shadow Shock
	[311551] = 1,		-- Ny'alotha - Dark Inquisitor Xanesh: Abyssal Strike
	[312406] = 0,		-- Ny'alotha - Dark Inquisitor Xanesh: Voidwoken
	[314298] = 2,		-- Ny'alotha - Dark Inquisitor Xanesh: Imminent Doom
	[307019] = 12,		-- Ny'alotha - Vexiona: Void Corruption
	[307317] = 0,		-- Ny'alotha - Vexiona: Encroaching Shadows
	[313460] = 0,		-- Ny'alotha - Hivemind: Nullification
	[313461] = 0,		-- Ny'alotha - Hivemind: Corrosion
	[306819] = 1,		-- Ny'alotha - Ra'den: Nullifying Strike
	[307471] = 1,		-- Ny'alotha - Shad'har: Crush
	[307472] = 1,		-- Ny'alotha - Shad'har: Dissolve
	[306692] = 0,		-- Ny'alotha - Shad'har the Insatiable: Living Miasma
	[310277] = 0,		-- Ny'alotha - Drest'agath: Volatile Seed
	[308377] = 0,		-- Ny'alotha - Drest'agath: Void Infused Ichor
	[310563] = 1,		-- Ny'alotha - Drest'agath: Mutterings of Betrayal
	[309961] = 2,		-- Ny'alotha - Il'gynoth: Eye of N'Zoth
	[315954] = 2,		-- Ny'alotha - Carapace of N'Zoth: Black Scar
	[306973] = 0,		-- Ny'alotha - Carapace of N'Zoth: Madness Bomb
	
	-- Shadowlands
	[342074] = 0,		-- Castle Nathria - Shriekwing: Echolocation
	[328897] = 1,		-- Castle Nathria - Shriekwing: Exsanguinated
	[334971] = 2,		-- Castle Nathria - Huntsman Altimor: Jagged Claws
	[334852] = 0,		-- Castle Nathria - Huntsman Altimor: Petrifying Howl
	[332295] = 5,		-- Castle Nathria - Hungering Destroyer: Growing Hunger
	[329298] = 0,		-- Castle Nathria - Hungering Destroyer: Gluttonous Miasma
	[334755] = 5,		-- Castle Nathria - Hungering Destroyer: Essence Sap
	[325361] = 0,		-- Castle Nathria - Artificer Xy'Mox: Glyph of Destruction
	[328437] = 0,		-- Castle Nathria - Artificer Xy'Mox: Dimensional Tear
	[340860] = 0,		-- Castle Nathria - Artificer Xy'Mox: Withering Touch
	[326271] = 0,		-- Castle Nathria - Artificer Xy'Mox: Statis Trap
	[326456] = 5,		-- Castle Nathria - Sun King's Salvation: Burning Remnants
	[325877] = 0,		-- Castle Nathria - Sun King's Salvation: Ember Blast
	[325442] = 2,		-- Castle Nathria - Sun King's Salvation: Vanquished
	[325382] = 2,		-- Castle Nathria - Lady Inerva Darkvein: Warped Desires
	[325908] = 0,		-- Castle Nathria - Lady Inerva Darkvein: Shared Cognition
	[324983] = 0,		-- Castle Nathria - Lady Inerva Darkvein: Shared Suffering
	[337110] = 1,		-- Castle Nathria - The Council of Blood: Dreadbolt Volley
	[327773] = 5,		-- Castle Nathria - The Council of Blood: Drain Essence
	[346681] = 2,		-- Castle Nathria - The Council of Blood: Soul Spikes
	[346690] = 1,		-- Castle Nathria - The Council of Blood: Duelist's Riposte
	[327503] = 1,		-- Castle Nathria - The Council of Blood: Evasive Lunge
	[330848] = 1,		-- Castle Nathria - The Council of Blood: Wrong Moves
	[347350] = 1,		-- Castle Nathria - The Council of Blood: Dancing Fever
	[335295] = 0,		-- Castle Nathria - Sludgefist: Shattering Chain
	[335354] = 0,		-- Castle Nathria - Sludgefist: Chain Slam
	[339690] = 0,		-- Castle Nathria - Stone Legion Generals: Crystalize
	[343881] = 2,		-- Castle Nathria - Stone Legion Generals: Serrated Tear
	[333913] = 1,		-- Castle Nathria - Stone Legion Generals: Wicked Laceration
	[334765] = 0,		-- Castle Nathria - Stone Legion Generals: Heart Rend
	[334771] = 0,		-- Castle Nathria - Stone Legion Generals: Heart Hemorrhage
	[326699] = 2,		-- Castle Nathria - Sire Denathrius: Burden of Sin
	[329875] = 3,		-- Castle Nathria - Sire Denathrius: Carnage
	[329181] = 1,		-- Castle Nathria - Sire Denathrius: Wracking Pain
	[332585] = 5,		-- Castle Nathria - Sire Denathrius: Scorn
	
	-- Dragonflight
	[371836] = 5,		-- Vault of the Incarnates - Primal Council: Primal Blizzard
	[372027] = 1,		-- Vault of the Incarnates - Primal Council: Slashing Blaze
	[372044] = 0,		-- Vault of the Incarnates - Sennarth: Wrapped in Webs
	[381615] = 0,		-- Vault of the Incarnates - Raszageth: Static Charge
}


------------------------------------------------
-- CTRA_Configuration_Consumables

-- What consumables might raid leaders be interested in tracking during ready checks?  These will appear in tooltips during ready checks only.
-- key: 	spellId
-- value:	true, or a numeric itemID to have the name of that item added in parenthesis (such as disambiguating well-fed buffs)
module.CTRA_Configuration_Consumables =
{
	-- Classic
	[11348] = 13445, -- Elixir of Superior Defense
	[11349] = 8951, -- Elixir of Greater Defense
	[24363] = 20007, -- Mageblood Potion
	[24368] = 20004, -- Major Troll's Blood Potion
	[11390] = true, -- Arcane Elixir
	[11406] = true, -- Elixir of Demonslaying
	[17538] = true, -- Elixir of the Mongoose
	[17539] = true, -- Greater Arcane Elixir
 	[11474] = true, -- Elixir of Shadow Power
 	[26276] = true, -- Elixir of Greater Firepower
	[17626] = true, -- Flask of the Titans
	[17627] = true, -- Flask of Distilled Wisdom 
	[17628] = true, -- Flask of Supreme Power 
	[17629] = true, -- Flask of Chromatic Resistance 
	[17649] = true, -- Greater Arcane Protection Potion
	[17543] = true, -- Greater Fire Protection Potion
	[17544] = true, -- Greater Frost Protection Potion
	[17546] = true, -- Greater Nature Protection Potion
	[17548] = true, -- Greater Shadow Protection Potion
	[18192] = 13928, -- Grilled Squid
	[24799] = 20452, -- Smoked Desert Dumplings
	[18194] = 13931, -- Nightfin Soup
	[22730] = 18254, -- Runn Tum Tuber Suprise
	[25661] = 21023, -- Dirge's Kickin Chimaerok Chops
	[18141] = 13813, -- Blessed Sunfruit Juice
	[18125] = 13810, -- Blessed Sunfruit

	-- Burning Crusade
	[28490] = true, -- Major Strength
	[28491] = true, -- Healing Power
	[28493] = true, -- Major Frost Power
	[28501] = true, -- Major Firepower
	[28503] = true, -- Major Shadow Power
	[33720] = true, -- Onslaught Elixir
	[33721] = true, -- Spellpower Elixir
	[33726] = true, -- Elixir of Mastery
	[38954] = true, -- Fel Strength Elixir
	[45373] = true, -- Bloodberry
	[54452] = true, -- Adept's Elixir
	[54494] = true, -- Major Agility
	[28502] = true, -- Major Armor
	[28509] = true, -- Greater Mana Regeneration
	[28514] = true, -- Empowerment
	[39625] = true, -- Elixir of Major Fortitude
	[39627] = true, -- Elixir of Draenic Wisdom
	[39628] = true, -- Elixir of Ironskin
	[39626] = true, -- Earthen Elixir
	[28518] = true, -- Flask of Fortification
	[28519] = true, -- Flask of Mighty Restoration 
	[28520] = true, -- Flask of Relentless Assault 
	[28521] = true, -- Flask of Blinding Light 
	[28540] = true, -- Flask of Pure Death
	[40567] = true, -- Unstable Flask of the Bandit
	[40568] = true, -- Unstable Flask of the Elder
	[40572] = true, -- Unstable Flask of the Beast
	[40573] = true, -- Unstable Flask of the Physician
	[40575] = true, -- Unstable Flask of the Soldier
	[40576] = true, -- Unstable Flask of the Sorcerer
	[41608] = true, -- Relentless Assault of Shattrath
	[41609] = true, -- Fortification of Shattrath
	[41610] = true, -- Mighty Restoration of Shattrath
	[41611] = true, -- Supreme Power of Shattrath
	[46837] = true, -- Pure Death of Shattrath
	[46839] = true, -- Blinding Light of Shattrath
	
	-- Wrath of the Lich King
	[53747] = true, -- Elixir of Spirit
	[60347] = true, -- Elixir of Mighty Thoughts
	[53764] = true, -- Elixir of Mighty Mageblood
	[53751] = true, -- Elixir of Mighty Fortitude
	[60343] = true, -- Elixir of Mighty Defense
	[53763] = true, -- Elixir of Protection
	[53746] = true, -- Wrath Elixir
	[53749] = true, -- Guru's Elixir
	[53748] = true, -- Elixir of Mighty Strength
	[28497] = true, -- Elixir of Mighty Agility
	[60346] = true, -- Elixir of Lightning Speed
	[60344] = true, -- Elixir of Expertise
	[60341] = true, -- Elixir of Deadly Strikes
	[60340] = true, -- Elixir of Accuracy
	[79474] = true, -- Elixir of the Naga
	[53752] = true, -- Lesser Flask of Toughness
	[53755] = true, -- Flask of the Frost Wyrm
	[53758] = true, -- Flask of Stoneblood
	[54212] = true, -- Flask of Pure Mojo
	[53760] = true, -- Flask of Endless Rage
	[62380] = true, -- Lesser Flask of Resistance
	[67019] = true, -- Flask of the North	

	-- Cataclysm
	[79480] = true, -- Elixir of Deep Earth
	[79631] = true, -- Prismatic Elixir
	[79477] = true, -- Elixir of the Cobra
	[79481] = true, -- Elixir of Impossible Accuracy
	[79632] = true, -- Elixir of Mighty Speed
	[79635] = true, -- Elixir of the Master
	[79469] = true, -- Flask of Steelskin
	[79470] = true, -- Flask of the Draconic Mind
	[79471] = true, -- Flask of the Winds
	[79472] = true, -- Flask of Titanic Strength
	[94160] = true, -- Flask of Flowing Water
	[92729] = true, -- Flask of Steelskin (guild cauldron)
	[92730] = true, -- Flask of the Draconic Mind (guild cauldron)
	[92725] = true, -- Flask of the Winds (guild cauldron)
	[92731] = true, -- Flask of Titanic Strength (guild cauldron)

	-- Mists of Pandaria
	[105681] = true, -- Mantid Elixir
	[105687] = true, -- Elixir of Mirrors
	[105682] = true, -- Mad Hozen Elixir
	[105683] = true, -- Elixir of Weaponry
	[105684] = true, -- Elixir of the Rapids
	[105685] = true, -- Elixir of Peace
	[105686] = true, -- Elixir of Perfection
	[105688] = true, -- Monk's Elixir
	[105689] = true, -- Flask of Spring Blossoms
	[105691] = true, -- Flask of the Warm Sun
	[105693] = true, -- Flask of Falling Leaves
	[105694] = true, -- Flask of the Earth
	[105696] = true, -- Flask of Winter's Bite
	[105617] = true, -- Alchemist's Flask
	[127230] = true, -- Crystal of Insanity
        
	-- Warlords of Draenor
	[156080] = true, -- Greater Draenic Strength Flask
	[156084] = true, -- Greater Draenic Stamina Flask
	[156079] = true, -- Greater Draenic Intellect Flask
	[156064] = true, -- Greater Draenic Agility Flask
	[156071] = true, -- Draenic Strength Flask
	[156077] = true, -- Draenic Stamina Flask
	[156070] = true, -- Draenic Intellect Flask
	[156073] = true, -- Draenic Agility Flask
	[176151] = true, -- Whispers of Insanity
	
	-- Legion
	[188031] = true, -- Flask of the Whispered Pact
	[188033] = true, -- Flask of the Seventh Demon
	[188034] = true, -- Flask of the Countless Armies
	[188035] = true, -- Flask of Ten Thousand Scars
	[242551] = true, -- Repurposed Fel Focuser
	[224001] = true, -- Defiled Augment Rune
	
	-- Battle for Azeroth
	[251839] = true, -- Flask of the Undertow
	[251838] = true, -- Flask of the Vast Horizon
	[251837] = true, -- Flask of the Endless Fathoms
	[251836] = true, -- Flask of the Currents
	[298841] = true, -- Greater Flask of the Undertow
	[298839] = true, -- Greater Flask of the Vast Horizon
	[298837] = true, -- Greater Flask of Endless Fathoms
	[298836] = true, -- Greater Flask of the Currents
	[270058] = true, -- Battle-Scarred Augment Rune
	[279639] = true, -- Galley Banquet
	[288076] = true, -- Seasoned Steak and Potatoes
	[257410] = 154882, -- Honey-Glazed Haunches
	[257415] = 154884, -- Swamp Fish 'n Chips
	[257420] = 154888, -- Sailor's Pie
	[257424] = 154886, -- Spiced Snapper
	[290467] = 166804, -- Boralus Blood Sausage (Agi)
	[290468] = 166804, -- Boralus Blood Sausage (Int)
	[290478] = 166804, -- Boralus Blood Sausage (Str)
	[259454] = 156526, -- Bountiful Captain's Feast or Sanguinated Feast (Agi)
	[259455] = 156526, -- Bountiful Captain's Feast or Sanguinated Feast (Int)
	[259456] = 156526, -- Bountiful Captain's Feast or Sanguinated Feast (Str)
	[297039] = 168310, -- Mech-Dowel's "Big Mech"
	[297034] = 168313, -- Baked Port Tato
	[297035] = 168311, -- Abyssal-Fried Rissole
	[297037] = 168314, -- Bil-Tong
	[297040] = 168312, -- Fragrant Kakavia
	[297116] = 168315, -- Famine Evaluator And Snack Table (Agi)
	[297117] = 168315, -- Famine Evaluator And Snack Table (Int)
	[297118] = 168315, -- Famine Evaluator And Snack Table (Str)
	
	-- Shadowlands
	--[321389] = 171286,	-- Embalmer's Oil	-- placeholder until a future CTRA version; it won't work like this because it is a weapon enchant
	--[320798] = 171295,	-- Shadowcore Oil	-- placeholder until a future CTRA version; it won't work like this because it is a weapon enchant
	[307175] = 171276,	-- Spectral Flask of Power
	[307187] = 171278,	-- Spectral Flask of Stamina
	[308525] = 172069,	-- Banana Beef Pudding (22 Sta)
	[308514] = 172051,	-- Steak a la Mode (30 Ver)
	[308488] = 172045,	-- Tenebrous Crown Roast Aspic (30 Hst)
	[308434] = 172041,	-- Spinefin Souffle and Fries (30 Cri)
	[308506] = 172049,	-- Iridescent Ravioli with Apple Sauce (30 Mas)
	[327701] = true,	-- Surprisingly Palatable Feast (18 Str)
	[327704] = true,	-- Surprisingly Palatable Feast (18 Int)
	[327705] = true,	-- Surprisingly Palatable Feast (18 Agi)
	[327706] = true,	-- Feast of Gluttonous Hedonism (20 Str)
	[327708] = true,	-- Feast of Gluttonous Hedonism (20 Int)
	[327709] = true,	-- Feast of Gluttonous Hedonism (20 Agi)
} 



------------------------------------------------
-- Filtering spells not available in the current expansion, and localizing to the current client name

local playerLoginHappened = false;
module:regEvent("PLAYER_LOGIN", function() playerLoginHappened = true; end);

local onSpellLoad
if AsyncCallbackSystemMixin then
	-- Avoiding taint in WoW 10.x (WoWUIBugs #373)
	local insecureAsyncSpellCallback = Mixin(CreateFrame("Frame"), AsyncCallbackSystemMixin)
	insecureAsyncSpellCallback:Init(AsyncCallbackAPIType.ASYNC_SPELL)
	function onSpellLoad(spellID, func)
		insecureAsyncSpellCallback:AddCallback(spellID, func)
	end
else
	-- Classic; unusable on Retail because it causes taint
	function onSpellLoad(spellID, func)
		Spell:CreateFromSpellID(spellID):ContinueOnSpellLoad(func)
	end
end
	
local function filterAndLocalize(table)
	local entries = table[select(2, UnitClass("player"))];
	if (entries) then
		-- manual while loop, because entries will be removed if they don't exist in the current edition of the game
		local i = 1;
		while (entries[i]) do
			local entry = entries[i];	-- This local reference is important! The async queries below could come back after entries[i] points to something else.
			if (C_Spell.DoesSpellExist(entry.id)) then
				onSpellLoad(entry.id, function()
					entry.name = CT_Library.getSpellName(entry.id)	-- shared helper (WoW 11.0.2 vs classic)
					if (playerLoginHappened and module.ClickCastBroker) then
						module.ClickCastBroker:Refresh();
					end
				end)
				i = i + 1;			-- moves to the next spell
			else
				tremove(entries, i);		-- shifts the remaining spells forward to the current position
			end
		end
	end
end

filterAndLocalize(module.CTRA_Configuration_Buffs);
filterAndLocalize(module.CTRA_Configuration_FriendlyRemoves);
filterAndLocalize(module.CTRA_Configuration_RezAbilities);