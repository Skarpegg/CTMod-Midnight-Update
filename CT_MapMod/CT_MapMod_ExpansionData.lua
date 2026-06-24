------------------------------------------------
--                 CT_MapMod                  --
--                                            --
-- Simple addon that allows the user to add   --
-- notes and gathered nodes to the world map. --
-- Please do not modify or otherwise          --
-- redistribute this without the consent of   --
-- the CTMod Team. Thank you.                 --
--					      --
-- Original credits to Cide and TS (Vanilla)  --
-- Maintained by Resike from 2014 to 2017     --
-- Rebuilt by Dahk Celes (DDCorkum) in 2018   --
------------------------------------------------

local module = select(2, ...);

-- Expansion Configuration Data
-- These tables should be updated every expansion or major patch to reflect new content




------------------------------------------------
-- Pins


-- Non-localized name of every valid user, herb and ore pin; the latter two subcategorized by how recently they were added to the game.
-- Value	String		Non-localized name as it is saved in the .wtf files.
module.pinTypes =
{
	["User"] =
	{
		"Grey Note",
		"Blue Shield",
		"Red Dot",
		"White Circle",
		"Green Square",
		"Red Cross",
		"Diamond", -- added in 8.0
		(C_Map and C_Map.CanSetUserWaypointOnMap) and "Waypoint", -- added in 9.0
	},			
	["Herb"] =
	{
		["Classic"] = 
		{
			"Bruiseweed", "Arthas' Tears", "Black Lotus", "Blindweed", "Briarthorn",
			"Dreamfoil", "Earthroot", "Fadeleaf", "Firebloom", "Ghost Mushroom",
			"Golden Sansam", "Goldthorn", "Grave Moss", "Gromsblood", "Icecap",
			"Khadgars Whisker", "Kingsblood", "Liferoot", "Mageroyal", "Mountain Silversage",
			"Peacebloom", "Plaguebloom", "Purple Lotus", "Silverleaf", "Stranglekelp",
			"Sungrass", "Swiftthistle", "Wild Steelbloom", "Wintersbite", "Dreaming Glory",
		},
		["Early Expansions"] = 
		{
			-- BC, Wrath, Cata, MoP
			"Felweed", "Flame Cap", "Mana Thistle", "Netherbloom", "Netherdust Bush", "Nightmare Vine", "Ragveil", "Terocone",
			"Adder's Tongue", "Frost Lotus", "Goldclover", "Icethorn", "Lichbloom", "Talandra's Rose", "Tiger Lily",	"Frozen Herb",
			"Cinderbloom", "Azshara's Veil", "Stormvine", "Heartblossom", "Whiptail", "Twilight Jasmine",
			"Green Tea Leaf", "Rain Poppy", "Silkweed", "Snow Lily", "Fool's Cap", "Sha-Touched Herb", "Golden Lotus",
		},
		["Later Expansions"] =
		{
			-- WoD, Legion, BFA, SL, DF,
			"Fireweed", "Gorgrond Flytrap", "Frostweed", "Nagrand Arrowbloom", "Starflower", "Talador Orchid", "Withered Herb",
			"Aethril", "Astral Glory", "Dreamleaf", "Fel-Encrusted Herb", "Fjarnskaggl", "Foxflower", "Starlight Rose",
			"Akunda's Bite", "Anchor Weed", "Riverbud", "Sea Stalks", "Siren's Sting", "Star Moss", "Winter's Kiss", "Zin'anthid",
			"Death Blossom", "Marrowroot", "Rising Glory", "Vigil's Torch", "Widowbloom", "Nightshade",
			"Hochenblume", "Saxifrage", "Bubble Poppy", "Writhebark",
		},
		["Worldsoul Saga"] = 
		{
			-- WW, Mid, LT
			"Arathor's Spear", "Blessing Blossom", "Luredrop", "Orbinid", "Mycobloom"
			-- insert Midnight herbs here (WoW 11.x)
			-- insert Last Titan herbs here (WoW 12.x)
		}
	},
	["Ore"] =
	{ 
		["Classic"] = 
		{
			"Copper", "Gold", "Iron", "Mithril", "Silver",
			"Thorium", "Tin", "Truesilver", "Adamantite",
		},
		["Early Expansions"] = 
		{
			-- BC, Wrath, Cata, MoP
			"Fel Iron", "Khorium",
			"Cobalt", "Saronite", "Titanium",
			"Elementium", "Obsidian", "Pyrite",
			"Ghost Iron", "Kyparite", "Trillium",
		},
		["Later Expansions"] = 
		{
			-- WoD, Legion, BFA, SL, DF
			"Blackrock", "True Iron",
			"Leystone", "Felslate",
			"Monelite", "Storm Silver", "Platinum", "Osmenite",
			"Laestrite", "Oxxein", "Phaedrum", "Sinvyr", "Solenium", "Elethium",
			"Serevite", "Draconium",
		},
		["Worldsoul Saga"] = 
		{
			-- WW, Mid, LT
			"Aqirite", "Ironclaw", "Bismuth"
			-- insert Midnight ores here (WoW 11.x)
			-- insert Last Titan ores here (WoW 12.x)
		}
	},
};

-- Path to the texture used for each type of pin, or a table containing the path, dimensions and tex coords.
-- Key		String		Non-localized name as it appears in module.pinTypes
-- Value	String		Path to the in-game or custom AddOn texture using assuming default TexCoord(0, 1, 0, 1)
--		or Table	Table with .path, .width, .height, .left, .right, .top and .bottom to use with tooltips, tex coords, etc.
module.pinIcons = 
{
	-- User --
	["Grey Note"] = "Interface\\AddOns\\CT_MapMod\\Skin\\GreyNote",
	["Blue Shield"] = "Interface\\AddOns\\CT_MapMod\\Skin\\BlueShield",
	["Red Dot"] = "Interface\\AddOns\\CT_MapMod\\Skin\\RedDot",
	["White Circle"] = "Interface\\AddOns\\CT_MapMod\\Skin\\WhiteCircle",
	["Green Square"] = "Interface\\AddOns\\CT_MapMod\\Skin\\GreenSquare",
	["Red Cross"] = "Interface\\AddOns\\CT_MapMod\\Skin\\RedCross",
	["Diamond"] = "Interface\\RaidFrame\\UI-RaidFrame-Threat",
	["Waypoint"] =
	{
		path = "Interface\\Waypoint\\WaypoinMapPinUI",
		width = 30,
		height = 30,
		left = 0.320312,
		right = 0.554688,
		top = 0.515625,
		bottom = 0.984375
	},
	
	-- Herbs --
	
	-- Classic
	["Bruiseweed"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_Bruiseweed",
	["Arthas' Tears"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_ArthasTears",
	["Black Lotus"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_BlackLotus",
	["Blindweed"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_Blindweed",
	["Briarthorn"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_Briarthorn",
	["Dreamfoil"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_Dreamfoil",
	["Earthroot"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_Earthroot",
	["Fadeleaf"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_Fadeleaf",
	["Firebloom"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_Firebloom",
	["Ghost Mushroom"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_GhostMushroom",
	["Golden Sansam"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_GoldenSansam",
	["Goldthorn"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_Goldthorn",
	["Grave Moss"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_GraveMoss",
	["Gromsblood"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_Gromsblood",
	["Icecap"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_Icecap",
	["Khadgars Whisker"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_KhadgarsWhisker",
	["Kingsblood"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_Kingsblood",
	["Liferoot"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_Liferoot",
	["Mageroyal"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_Mageroyal",
	["Mountain Silversage"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_MountainSilversage",
	["Peacebloom"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_Peacebloom",
	["Plaguebloom"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_Plaguebloom",
	["Purple Lotus"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_PurpleLotus",
	["Silverleaf"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_Silverleaf",
	["Stranglekelp"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_Stranglekelp",
	["Sungrass"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_Sungrass",
	["Swiftthistle"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_Swiftthistle",
	["Wild Steelbloom"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_WildSteelbloom",
	["Wintersbite"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_Wintersbite",
	["Dreaming Glory"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_DreamingGlory",
	
	-- Burning Crusade
	["Felweed"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_Felweed",
	["Flame Cap"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_FlameCap",
	["Mana Thistle"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_ManaThistle",
	["Netherbloom"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_Netherbloom",
	["Netherdust Bush"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_NetherdustBush",
	["Nightmare Vine"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_NightmareVine",
	["Ragveil"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_Ragveil",
	["Terocone"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_Terocone",
	
	-- Wrath of the Lich King
	["Adder's Tongue"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_AddersTongue",
	["Frost Lotus"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_FrostLotus",
	["Goldclover"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_Goldclover",
	["Icethorn"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_Icethorn",
	["Lichbloom"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_Lichbloom",
	["Talandra's Rose"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_TalandrasRose",
	["Tiger Lily"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_TigerLily",
	["Frozen Herb"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_FrozenHerb",
	
	-- Cataclysm
	["Cinderbloom"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_Cinderbloom",
	["Azshara's Veil"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_AzsharasVeil",
	["Stormvine"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_Stormvine",
	["Heartblossom"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_Heartblossom",
	["Whiptail"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_Whiptail",
	["Twilight Jasmine"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_TwilightJasmine",
	
	-- Mists of Pandaria
	["Green Tea Leaf"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_GreenTeaLeaf",
	["Rain Poppy"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_RainPoppy",
	["Silkweed"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_Silkweed",
	["Snow Lily"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_SnowLily",
	["Fool's Cap"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_FoolsCap",
	["Sha-Touched Herb"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_ShaHerb",
	["Golden Lotus"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_GoldenLotus",	
	
	-- WoD
	["Fireweed"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_Fireweed",
	["Gorgrond Flytrap"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_GorgrondFlytrap",
	["Frostweed"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_Frostweed",
	["Nagrand Arrowbloom"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_NagrandArrowbloom",
	["Starflower"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_Starflower",
	["Talador Orchid"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_TaladorOrchid",
	["Withered Herb"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_FrozenHerb",
	
	-- Legion
	["Aethril"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_Bruiseweed",
	["Astral Glory"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_Bruiseweed",
	["Dreamleaf"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_Bruiseweed",
	["Fel-Encrusted Herb"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_Bruiseweed",
	["Fjarnskaggl"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_Bruiseweed",
	["Foxflower"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_Bruiseweed",
	["Starlight Rose"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_StarlightRose",
	
	-- Battle for Azeroth
	["Akunda's Bite"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_AkundasBite",
	["Anchor Weed"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_AnchorWeed",
	["Riverbud"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_Riverbud",
	["Sea Stalks"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_SeaStalk",
	["Siren's Sting"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_Bruiseweed",
	["Star Moss"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_StarMoss",
	["Winter's Kiss"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_WintersKiss",
	["Zin'anthid"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_Zinanthid",
	
	-- Shadowlands
	["Death Blossom"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_DeathBlossom",
	["Marrowroot"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_Marrowroot",
	["Rising Glory"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_RisingGlory",
	["Vigil's Torch"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_VigilsTorch",
	["Widowbloom"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_Widowbloom",	
	["Nightshade"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_Nightshade",
	
	-- Dragonflight
	["Hochenblume"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_Hochenblume",
	["Saxifrage"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_Saxifrage",
	["Bubble Poppy"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_BubblePoppy",
	["Writhebark"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_Writhebark",
	
	-- The War Within
	["Arathor's Spear"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_ArathorsSpear", 
	["Blessing Blossom"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_BlessingBlossom",
	["Luredrop"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_Luredrop",
	["Orbinid"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_Orbinid",
	["Mycobloom"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_Bruiseweed",
	
	-- Ore --
	
	-- Classic
	["Copper"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Ore_CopperVein",
	["Gold"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Ore_GoldVein",
	["Iron"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Ore_IronVein",
	["Mithril"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Ore_MithrilVein",
	["Silver"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Ore_SilverVein",
	["Thorium"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Ore_ThoriumVein",
	["Tin"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Ore_TinVein",
	["Truesilver"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Ore_TruesilverVein",
	["Adamantite"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Ore_AdamantiteVein",
	
	-- Burning Crusade
	["Fel Iron"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Ore_FelIronVein",
	["Khorium"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Ore_KhoriumVein",
	
	-- Wrath of the Lich King
	["Cobalt"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Ore_CobaltVein",
	["Saronite"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Ore_SaroniteVein",
	["Titanium"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Ore_TitaniumVein",
	
	-- Cataclysm
	["Elementium"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Ore_Elementium",
	["Obsidian"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Ore_Obsidian",
	["Pyrite"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Ore_Pyrite",
	
	-- Mists of Pandaria
	["Ghost Iron"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Ore_GhostIron",
	["Kyparite"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Ore_Kyparite" ,
	["Trillium"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Ore_Trillium",
	
	-- Warlords of Draenor
	["Blackrock"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Ore_CopperVein",
	["True Iron"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Ore_CopperVein",
	
	-- Legion
	["Leystone"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Ore_Leystone",
	["Felslate"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Ore_Felslate",
	
	-- Battle for Azeroth
	["Monelite"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Ore_CopperVein",
	["Storm Silver"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Ore_StormSilver",
	["Platinum"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Ore_Platinum",
	["Osmenite"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Ore_Elementium",
	
	-- Shadowlands
	["Laestrite"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Ore_Laestrite",
	["Oxxein"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Ore_Oxxein",
	["Phaedrum"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Ore_Phaedrum",
	["Sinvyr"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Ore_Sinvyr",
	["Solenium"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Ore_Solenium",
	["Elethium"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Ore_Elethium",
	
	-- Dragonflight
	["Serevite"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Ore_Tyrivite",
	["Draconium"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Ore_Draconium",
	
	-- The War Within
	["Aqirite"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Ore_CopperVein",
	["Ironclaw"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Ore_Elementium",
	["Bismuth"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Ore_Platinum",
	
}
setmetatable(module.pinIcons, {__index = function() return "Interface\\RaidFrame\\UI-RaidFrame-Threat" end})

-- Herbs and ore that spawn randomly in place of other nodes, so do not create any pins.
-- Key		string		Non-localized name as it appears in module.pinTypes
-- Value	boolean		True if the herbalism or mining node occurs randomly and is therefore not worth marking on the map.
--		or function	If the value is a function, it will be called and the return will be checked as a boolean
module.randomSpawns =
{
	-- Battle for Azeroth
	["Anchor Weed"] = true,
	["Platinum"] = true,
	
	-- Shadowlands
	["Nightshade"] = function() return C_Map.GetBestMapForUnit("player") ~= 1543; end,
	["Elethium"] = function() return C_Map.GetBestMapForUnit("player") ~= 1543; end,
}


------------------------------------------------
-- Flight Maps

-- Allows pins to appear at flight masters if there is a corresponding world-map that looks identical
-- 	key			Number, Required		GetTaxiMapID() when at a flight master using FlightMapFrame
--	val			Number, Required		GetMapID() when looking at a continent in the WorldMapFrame
module.flightMaps = 
{
	 [990] = 552, -- Draenor  -- never used, because WoD has the TaxiRouteFrame instead of FlightMapFrame
	[1011] = 875, -- Zandalar
	[1014] = 876, -- Kul Tiras
	[1208] =  13, -- Eastern Kingdoms
	[1209] =  12, -- Kalimdor
	[1384] = 113, -- Northrend
	[1467] = 101, -- Outland
	[1647] = 1550, -- Shadowlands 
};


-- Classic Flight Path x/y scaling and offsets
-- 	key			Number, Required		GetTaxiMapID() when at a flight master using FlightMapFrame
--	val			Table, Required			mapID is the worldmap uiMapID, xOff and yOff are added to the x/y coords, and everything is multiplied by xScale/yScale
module.classicTaxiMaps = 
{
	-- Eastern Kingdoms: Classic Era vs. Burning Crusade Classic
	[1463] = WOW_PROJECT_ID == WOW_PROJECT_CLASSIC and { mapID = 1415, xOff = -0.152, xScale = 1.52, yOff = -0.084, yScale = 1.094 }		-- Classic Eastern Kingdoms
		or { mapID = 1415, xOff = -0.16, xScale = 1.48, yOff = 0.03, yScale = 0.96 },
	
	-- Kalimdor: Classic
	[1464] = { mapID = 1414, xOff = -0.164, xScale = 1.5, yOff = -0.01, yScale = 1 },
	
	-- Outland: Burning Crusade Classic
	[987] = { mapID = 1945, xOff = -0.146, xScale = 1.48, yOff = 0.071, yScale = 0.92 },
};


-- Data points to omit from the taxi map
-- 	key			Number, Required		TaxiNodeID
module.ignoreClassicTaxiNodes = 
{
	[36] = true,	-- Generic, World Target 001
	[84] = true,	-- Plaguewood Tower, Eastern Plaguelands
	[85] = true,	-- Northpass Tower, Eastern Plaguelands
	[86] = true,	-- Eastwall Tower, Eastern Plaguelands
	[87] = true,	-- Crown Guard Tower, Eastern Plaguelands
	[95] = true,	-- As the Crow Flies quest, Zangermarsh
	[97] = true,	-- Elekk Path to Kessel quest, Bloodmyst Isle
	[103] = true,	-- Halaa PvP, Nagrand
	[104] = true,
	[105] = true,
	[106] = true,
	[107] = true,
	[108] = true,
	[109] = true,
	[110] = true,
	[111] = true,	-- Duskwither Teleport end, Eversong
	[112] = true,	-- Duskwither Teleport start, Eversong
	[113] = true,	-- Nethrandamus quest, Netherstorm
	[131] = true,	-- Horde hellfire start, Hellfire Peninsula
	[132] = true,	-- Horde hellfire end, Hellfire Peninsula
	[133] = true, 	-- Alliance bombing run start, Hellfire Peninsula
	[134] = true, 	-- Alliance bombing run end8, Hellfire Peninsula
	[135] = true,	-- Horde bombing run start, Hellfire Peninsula
	[136] = true,	-- Horde bombing run finish, Hellfire Peninsula
	[137] = true,	-- Alliance Shatter Point bombing run end, Hellfire Peninsula
	[138] = true,	-- Alliance Shatter Point bombing run end, Hellfire Peninsula
	[143] = true,	-- Caverns of Time intro flight start, Tanaris
	[144] = true,	-- Caverns of Time intro fligth end, Tanaris
	[145] = true,	-- Stealth Flight quest start, Netherstorm
	[147] = true,	-- Force Camp quest, Hellfire Peninsula
	[148] = true,	-- Shatter Point questing8, Hellfire Peninsula
	[152] = true,	-- Manaforge Ultris quest start, Netherstorm
	[153] = true,	-- Manaforge Ultris quest end, Netherstorm
	[157] = true,	-- Vision Guide quest, Blade's Edge Mountaints
	[168] = true,	-- Filming
	[169] = true,	-- Netherwing Ledge quest, Shadowmoon Valley
	[180] = true,	-- Quest - Dustwallow - Alcaz Survey Start
	[181] = true,	-- Quest - Dustwallow - Alcaz Survey End
	[209] = true,	-- Dead Scar Bombing start, Sunwell
	[211] = true,	-- Ship Bombing end, Sunwell
	[212] = true,	-- Ship Bombing end, Sunwell
	[285] = true,	-- Quest: Wintergarde -> Stars' Rest (Start)
	[287] = true,	-- Quest: Valgarde -> Westguard Keep Start
	[292] = true,	-- Flavor - Stormwind Harbor - Start
	[316] = true,	-- Ebon Hold - Acherus -> Death's Breach Start
	[318] = true,	-- Ebon Hold - Death's Breach -> Acherus Start
	[392] = true,	-- CC Prologue - GT - Quest - Vent Horizon - Start
	[393] = true,	-- CC Prologue - GT - Quest - Vent Horizon - End
	[394] = true,	-- CC Prologue - ET - Battle Flight - Start
	[404] = true,	-- Durotar - ET - CC Prologue Spy Frog Start
	[405] = true,	-- Durotar - ET - CC Prologue Spy Frog End
	[438] = true,	-- Durotar - ET - CC Prologue Troll Taxi Bat Start
	[439] = true,	-- Durotar - ET - CC Prologue Troll Recruit End
}

-- Special forms of travel which appear on the flight map.
module.specialTransportNodes = 
{
	-- Underwater, Cataclysm
	[521] = 1,
	[522] = 1,
	[523] = 1,
	[524] = 1,
	[525] = 1,
	[526] = 1,
	[607] = 1,
	[609] = 1,
	[611] = 1,
	[612] = 1,
	
	-- Teleportation, Dragon Isles
	[2834] = 2,		-- Eon's Fringe
	[2836] = 2,		-- Algeth'era
	[2837] = 2,		-- Vakthros
	[2838] = 2,		-- Cobalt Assembly
	[2839] = 2,		-- Rusza'thar
	[2840] = 2,		-- Shady Sanctuary
	[2841] = 2,		-- Skytop Observatory
	[2842] = 2,		-- Rubyscale Outpost
	
}


------------------------------------------------
-- Gathering Professions

-- Allows detecting interactions with herbalism nodes
-- 	key			Number, Required		SpellID of an herbalism ability used on an herbalism node
--	val			String, Required		Must evaluate to "Herb" or "Ore"
module.gatheringSkills =
{
	-- Herbalism
	  [2366] = "Herb",
	  [2368] = "Herb",
	  [3570] = "Herb",
	 [11993] = "Herb",
	 [28695] = "Herb",
	 [50300] = "Herb",
	 [74519] = "Herb",
	[110413] = "Herb",
	[158745] = "Herb",
	[265819] = "Herb",
	[265821] = "Herb",
	[265823] = "Herb",
	[265825] = "Herb",
	[265827] = "Herb",
	[265829] = "Herb",
	[265831] = "Herb",
	[265834] = "Herb",
	[265835] = "Herb",
	[309780] = "Herb",	-- Shadowlands
	[366252] = "Herb",	-- Dragonflight
	[441327] = "Herb",  -- The War Within

	-- Mining
	   [186] = "Ore",
	  [2575] = "Ore",	-- Classic Apprentice
	  [2576] = "Ore",	-- Classic Journeyman
	  [3564] = "Ore",	-- Classic Expert
	 [10248] = "Ore",	-- Classic Artisan
	 [29354] = "Ore",	-- Legacy Master (BC)
	 [50310] = "Ore",	-- Legacy Grand Master (WotLK)
	 [74517] = "Ore",	-- Legacy Illustrious Grand Master (Cata)
	[102161] = "Ore",	-- Legacy Zen Master Minder (Pandaria)
	[158754] = "Ore",	-- Legacy Draenor
	[195122] = "Ore",	-- Legacy Broken Isles
	[265837] = "Ore",	-- Artisan
	[265839] = "Ore",	-- Burning Crusade
	[265841] = "Ore",	-- Northrend
	[265843] = "Ore",	-- Cataclysm
	[265845] = "Ore",	-- Pandaria
	[265847] = "Ore",	-- Draenor
	[265849] = "Ore",	-- Legion
	[265851] = "Ore",	-- Kul Tiran
	[265854] = "Ore",	-- Zandalari
	[309835] = "Ore",	-- Shadowlands
	[366260] = "Ore",	-- Dragonflight
	[423341] = "Ore",  -- The War Within
}


------------------------------------------------
-- Localization

if (not GetProfessions) then
	-- Classic compatibility block with modern C_Spell / GetSpellInfo fallbacks
	local spellAPI = Spell or (C_Spell and C_Spell.CreateSpellBySpellID and C_Spell);
	local getSpellInfoFunc = CT_Library.getSpellName;	-- shared helper: returns the spell name string directly
	
	if spellAPI and getSpellInfoFunc then
		local findOre = spellAPI:CreateFromSpellID(2580);
		if findOre and findOre.ContinueOnSpellLoad then
			findOre:ContinueOnSpellLoad(
				function() 
					module.text = module.text or {};
					local info = getSpellInfoFunc(2580);
					module.text["CT_MapMod/Map/ClassicMiner"] = type(info) == "table" and info.name or info;
				end
			);
		end
		
		local findHerbs = spellAPI:CreateFromSpellID(2383);
		if findHerbs and findHerbs.ContinueOnSpellLoad then
			findHerbs:ContinueOnSpellLoad(
				function() 
					module.text = module.text or {};
					local info = getSpellInfoFunc(2383);
					module.text["CT_MapMod/Map/ClassicHerbalist"] = type(info) == "table" and info.name or info;
				end
			);
		end
	end
end