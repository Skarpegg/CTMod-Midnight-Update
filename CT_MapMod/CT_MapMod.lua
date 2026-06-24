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
local _G = getfenv(0);

local MODULE_NAME = "CT_MapMod";
local MODULE_VERSION = strmatch(C_AddOns.GetAddOnMetadata(MODULE_NAME, "version"), "^([%d.]+)");

module.name = MODULE_NAME;
module.version = MODULE_VERSION;

CT_Library:registerModule(module);
_G[MODULE_NAME] = module.publicInterface;
local public = module.publicInterface; -- shorthand

module.text = module.text or { };
local L = module.text;

--------------------------------------------
-- Public design

-- CT_MapMod:NewDataProvider()		-- Creates a new CT_MapMod data provider, so other addons can integrate CT_MapMod into their custom map.
-- CT_MapMod:InsertHerb()		-- Inserts an herbalism pin using a localized name and position, but avoiding duplicates
-- CT_MapMod:InsertOre()		-- Inserts a mining pin using a localized name and position, but avoiding duplicates
-- CT_MapMod_PinMixin			-- Handles the appearance and behaviour of a single pin on a map.


--------------------------------------------
-- Public dependencies (localized for performance)

local WorldMapFrame = WorldMapFrame;
local C_Map = C_Map;
local WaypointLocationDataProviderMixin = WaypointLocationDataProviderMixin;


--------------------------------------------
-- Private design

local StaticNoteEditPanel;			-- Allows the manual editing of a pin's contents

--------------------------------------------
-- Initialization

function module:Initialize()				-- called via module.update("init") from CT_Library

	-- Up to two tasks for each frame:
	--	(1) installing a DataProvider that will do most of the horsepower; and
	--	(2) installing unique UI customizations applicable only to that frame.

	-- WorldMapFrame
	module.worldMapDataProvider = module:NewDataProvider()
	WorldMapFrame:AddDataProvider(module.worldMapDataProvider)
	module:configureWorldMapFrame()
	
	-- FlightMapFrame (loaded asynchrously when first visiting a flight master)
	module:hookWhenFirstLoaded("FlightMapFrame", "FlightMap_LoadUI", function()
		module.flightMapDataProvider = module:NewDataProvider()
		FlightMapFrame:AddDataProvider(module.flightMapDataProvider)
		module:configureFlightMapFrame()
	end)
	
	-- TaxiFrame (WoD alternative to FlightMapFrame)
	if (module:getGameVersion() >= 6) then
		module:configureTaxiFrame()
	else
		module:configureClassicTaxiFrame()
	end

end

--------------------------------------------
-- Saved Variable: CT_MapMod_Notes
-- Persistant storage of the actual pins, and a collection of public and private methods to manipulate the data

CT_MapMod_Notes = {}; 		-- Account-wide saved variable containing all of the information about pins

-- Inserts a new pin on a map; however, if an essentially identical pin exists then it will simple refresh the existing one to prevent duplicates
function module:InsertPin(mapID, x, y, name, set, subset, descript)
	CT_MapMod_Notes[mapID] = CT_MapMod_Notes[mapID] or {}
	for i, note in ipairs(CT_MapMod_Notes[mapID]) do
		if (abs(note.x - x) + abs(note.y - y) < 0.001 and note.set == set) then
			note.subset = subset;
			note.descript = descript;
			note.name = name;
			note.datemodified = date("%Y%m%d");
			note.version = MODULE_VERSION;
			module:refreshVisibleDataProviders();
			if (WorldMapFrame:IsShown() and set == "User") then
				StaticNoteEditPanel():RequestFocus(module.worldMapDataProvider.pins[i]);
			end
			return;
		end
	end
	tinsert(CT_MapMod_Notes[mapID], {
		["x"] = x,
		["y"] = y,
		["name"] = name,
		["set"] = set,
		["subset"] = subset,
		["descript"] = descript,
		["datemodified"] = date("%Y%m%d"),
		["version"] = MODULE_VERSION
	});
	module:refreshVisibleDataProviders();
	if (WorldMapFrame:IsShown()) then
		if (set == "User") then
			StaticNoteEditPanel():RequestFocus(module.worldMapDataProvider.pins[#CT_MapMod_Notes[mapID]]);
		end
	end
	
end

-- Deletes a pin from the i'th position on mapID, taking the very last remaining one and inserting it into the current position rather than shifting all the other notes down by one
-- (This is an alternative to using tremove in the middle of a big table, for performance reasons only)
function module:DeletePin(mapID, i)
	if (CT_MapMod_Notes[mapID] and CT_MapMod_Notes[mapID][i]) then
		if (i == #CT_MapMod_Notes[mapID]) then
			tremove(CT_MapMod_Notes[mapID], i);
		else
			local lastNoteInStack = tremove(CT_MapMod_Notes[mapID], #CT_MapMod_Notes[mapID]);
			CT_MapMod_Notes[mapID][i] = lastNoteInStack;
		end
		module:refreshVisibleDataProviders();
	end
end

-- Inserts a new herb node on the map, but subject to rules imposed by CT_MapMod to prevent duplication
-- Parameters:
--	mapID		Number, Required	Corresponding to a uiMapID upon which the pin should appear
--	x, y		Numbers, Required	Absolute coordinates on the map between 0 and 1
--	herb		String, Required	Localized or non-localized name of the herbalism node or kind of herb (silently fails if it is a string that simply isn't recognized)
--	descript	String			Optional text to include (defaults to nil)
--	name		String			Optional name for the pin (defaults to a localized version of the herb)
function public:InsertHerb(mapID, x, y, herb, descript, name)
	assert(type(mapID) == "number", "An AddOn is creating a CT_MapMod pin without identifying a valid map")
	assert(type(x) == "number" and type(y) == "number" and x >= 0 and y >= 0 and x <= 1 and y <= 1, "An AddOn is creating a CT_MapMod pin without specifying valid cordinates");
	assert(type(herb) == "string", "An AddOn is creating a CT_MapMod herbalism pin without identifying a kind of herbalism node")
	if (type(descript) ~= "string") then
		descript = nil
	end
	if (type(name) ~= "string") then
		name = nil;
	end
	
	-- convert special node names to the standard variant (localization dependent)
	if GetLocale() == "enUS" or GetLocale() == "enGB" then
	
		-- Drangonflight, The War Within
		if herb:sub(1, 8) == "Decayed " and herb:len() > 8 then
			herb = herb:sub(9)
		elseif herb:sub(1, 11) == "Self-Grown " and herb:len() > 11 then
			herb = herb:sub(12)
		elseif herb:sub(1, 10) == "Windswept " and herb:len() > 10 then
			herb = herb:sub(11)
		elseif herb:sub(1, 7) == "Frigid " and herb:len() > 7 then
			herb = herb:sub(8)
		elseif herb:sub(1, 5) == "Lush " and herb:len() > 5 then
			herb = herb:sub(6)
		elseif herb:sub(1, 14) == "Titan-Touched " and herb:len() > 14 then
			herb = herb:sub(15)
		elseif herb:sub(1, 10) == "Infurious " and herb:len() > 10 then
			herb = herb:sub(11)
		elseif herb:sub(1, 8) == "Lambent " and herb:len() > 8 then
			herb = herb:sub(9)
		elseif herb:sub(1, 10) == "Overgrown " and herb:len() > 10 then
			herb = herb:sub(11)
		elseif herb:sub(1,11) == "Irradiated " and herb:len() > 11 then
			herb = herb:sub(12)
		elseif herb:sub(1,13) == "Crystallized " and herb:len() > 13 then
			herb = herb:sub(14)
		elseif herb:sub(1,11) == "Sporefused " and herb:len() > 11 then
			herb = herb:sub(12)
		elseif herb:sub(1,8) == "Altered " and herb:len() > 8 then
			herb = herb:sub(9)
		elseif herb:sub(1,13) == "Camouflaged " and herb:len() > 13 then
			herb = herb:sub(14)
		end
	
	elseif GetLocale() == "frFR" then
	
		-- Drangonflight overloads
		if herb:sub(-10, -1) == " sanglante" and herb:len() > 10 then
			herb = herb:sub(1, -11)
		--elseif herb:sub(1, 11) == "Self-Grown " and herb:len() > 11 then
		--	herb = herb:sub(12)
		elseif herb:sub(-21, -1) == " balayée par le vent" and herb:len() > 21 then
			herb = herb:sub(1, -22)
		elseif herb:sub(-7, -1) == " algide" and herb:len() > 7 then
			herb = herb:sub(1, -8)
		elseif herb:sub(-11, -1) == " luxuriante" and herb:len() > 11 then
			herb = herb:sub(1, -12)
		elseif herb:sub(-24, -1) == " touchée par les Titans" and herb:len() > 24 then
			herb = herb:sub(1, -25)
		elseif herb:sub(-8, -1) == " ardente" and herb:len() > 8 then
			herb = herb:sub(1, -9)
		end

	elseif GetLocale() == "deDE" then

		-- Drangonflight, The War Within
		if herb:sub(1, 11) == "Verrottete " and herb:len() > 11 then
			herb = herb:sub(12)
		elseif herb:sub(1, 12) == "Verrotteter " and herb:len() > 12 then
			herb = herb:sub(13)
		elseif herb:sub(1, 12) == "Verrottetes " and herb:len() > 12 then
			herb = herb:sub(13)
		elseif herb:sub(1, 16) == "Windgepeitschte " and herb:len() > 16 then
			herb = herb:sub(17)
		elseif herb:sub(1, 17) == "Windgepeitschter " and herb:len() > 17 then
			herb = herb:sub(18)
		elseif herb:sub(1, 17) == "Windgepeitschtes " and herb:len() > 17 then
			herb = herb:sub(18)
		elseif herb:sub(1, 7) == "Eisige " and herb:len() > 7 then
			herb = herb:sub(8)
		elseif herb:sub(1, 8) == "Eisiger " and herb:len() > 8 then
			herb = herb:sub(9)
		elseif herb:sub(1, 8) == "Eisiges " and herb:len() > 8 then
			herb = herb:sub(9)
		elseif herb:sub(1, 8) == "Üppige " and herb:len() > 8 then
			herb = herb:sub(9)
		elseif herb:sub(1, 9) == "Üppiger " and herb:len() > 9 then
			herb = herb:sub(10)
		elseif herb:sub(1, 9) == "Üppiges " and herb:len() > 9 then
			herb = herb:sub(10)
		elseif herb:sub(1, 17) == "Titanenberührte " and herb:len() > 17 then
			herb = herb:sub(18)
		elseif herb:sub(1, 18) == "Titanenberührter " and herb:len() > 18 then
			herb = herb:sub(19)
		elseif herb:sub(1, 18) == "Titanenberührtes " and herb:len() > 18 then
			herb = herb:sub(19)
		elseif herb:sub(1, 14) == "Wutentbrannte " and herb:len() > 14 then
			herb = herb:sub(15)
		elseif herb:sub(1, 15) == "Wutentbrannter " and herb:len() > 15 then
			herb = herb:sub(16)
		elseif herb:sub(1, 15) == "Wutentbranntes " and herb:len() > 15 then
			herb = herb:sub(16)
		elseif herb:sub(1, 11) == "Flackernde " and herb:len() > 11 then
			herb = herb:sub(12)
		elseif herb:sub(1, 12) == "Flackernder " and herb:len() > 12 then
			herb = herb:sub(13)
		elseif herb:sub(1, 12) == "Flackerndes " and herb:len() > 12 then
			herb = herb:sub(13)
		elseif herb:sub(1, 12) == "Verwucherte " and herb:len() > 12 then
			herb = herb:sub(13)
		elseif herb:sub(1, 13) == "Verwucherter " and herb:len() > 13 then
			herb = herb:sub(14)
		elseif herb:sub(1, 13) == "Verwuchertes " and herb:len() > 13 then
			herb = herb:sub(14)
		elseif herb:sub(1,12) == "Verstrahlte " and herb:len() > 12 then
			herb = herb:sub(13)
		elseif herb:sub(1,13) == "Verstrahlter " and herb:len() > 13 then
			herb = herb:sub(14)			
		elseif herb:sub(1,13) == "Verstrahltes " and herb:len() > 13 then
			herb = herb:sub(14)
		elseif herb:sub(1,16) == "Kristallisierte " and herb:len() > 16 then
			herb = herb:sub(17)
		elseif herb:sub(1,17) == "Kristallisierter " and herb:len() > 17 then
			herb = herb:sub(18)
		elseif herb:sub(1,17) == "Kristallisiertes " and herb:len() > 17 then
			herb = herb:sub(18)
		elseif herb:sub(1,20) == "Sporenverschmolzene " and herb:len() > 20 then
			herb = herb:sub(21)
		elseif herb:sub(1,21) == "Sporenverschmolzener " and herb:len() > 21 then
			herb = herb:sub(22)
		elseif herb:sub(1,21) == "Sporenverschmolzenes " and herb:len() > 21 then
			herb = herb:sub(22)
		elseif herb:sub(1,13) == "Modifizierte " and herb:len() > 13 then
			herb = herb:sub(14)
		elseif herb:sub(1,14) == "Modifizierter " and herb:len() > 14 then
			herb = herb:sub(15)
		elseif herb:sub(1,14) == "Modifiziertes " and herb:len() > 14 then
			herb = herb:sub(15)
		elseif herb:sub(1,9) == "Getarnte " and herb:len() > 9 then
			herb = herb:sub(10)
		elseif herb:sub(1,10) == "Getarnter " and herb:len() > 10 then
			herb = herb:sub(11)
		elseif herb:sub(1,10) == "Getarntes " and herb:len() > 10 then
			herb = herb:sub(11)
		end
	end

	-- now process the standardized names
	for __, expansion in pairs(module.pinTypes["Herb"]) do
		for __, kind in ipairs(expansion) do
			if (L["CT_MapMod/Herb/" .. kind] == herb or kind == herb) then
				local isRandom = module.randomSpawns[kind];
				if (type(isRandom) == "function") then
					isRandom = isRandom();
				end
				if (isRandom and not module:getOption("CT_MapMod_IncludeRandomSpawns")) then
					-- this is an kind that appears randomly throughout the zone in place of others, such as Anchor's Weed
					return;
				end
				CT_MapMod_Notes[mapID] = CT_MapMod_Notes[mapID] or { };
				for __, note in ipairs(CT_MapMod_Notes[mapID]) do
					if ((note["name"] == kind) and (math.sqrt((note["x"]-x)^2+(note["y"]-y)^2)<.02)) then
						--two kinds of the same kind not far apart
						return;
					elseif ((note["set"] == "Herb") and (math.sqrt((note["x"]-x)^2+(note["y"]-y)^2)<.01)) then
						--two kinds of different kinds very close together
						if (module:getOption("CT_MapMod_OverwriteGathering")) then
							note["x"] = x;
							note["y"] = y;
							if (note["descript"] == "" or not note["descript"]) then
								note["descript"] = "Nearby: " .. L["CT_MapMod/Herb/" .. note["subset"]];
							elseif (note["descript"]:sub(1,8) == "Nearby: " and not note["descript"]:find(L["CT_MapMod/Herb/" .. note["subset"]],9)) then
								note["descript"] = note["descript"] .. ", " .. L["CT_MapMod/Herb/" .. note["subset"]];
							end
							note["name"] = L["CT_MapMod/Herb/" .. kind];
							note["subset"] = kind;
							note["datemodified"] = date("%Y%m%d");
							note["version"] = MODULE_VERSION
						else
							-- leave the existing note, but add details in the description
							if (note["descript"] == "" or not note["descript"]) then
								note["descript"] = "Nearby: " .. L["CT_MapMod/Herb/" .. kind];
							elseif (note["descript"]:sub(1,8) == "Nearby: " and not note["descript"]:find(L["CT_MapMod/Herb/" .. kind],9)) then
								note["descript"] = note["descript"] .. ", " .. L["CT_MapMod/Herb/" .. kind];
							end											
						end
						return;
					elseif (math.sqrt((note["x"]-x)^2+(note["y"]-y)^2)<.005) then 		--two notes of completely different kinds EXTREMELY close together
						return;
					end
				end
				if (not name) then
					name = L["CT_MapMod/Herb/" .. kind];
				end
				-- this point will not have been reached if the earlier rules were triggered, causing the function to return early
				module:InsertPin(mapID, x, y, name, "Herb", kind, descript);
				return; -- breaks the for loops
			end
		end
	end
end

-- Inserts a new ore node on the map, but subject to rules imposed by CT_MapMod to prevent duplication
-- Parameters:
--	mapID		Number, Required	Corresponding to a uiMapID upon which the pin should appear
--	x, y		Numbers, Required	Absolute coordinates on the map between 0 and 1
--	ore		String			Localized name of the mining node or kind of ore (silently fails if it is a string that simply isn't recognized)
--	descript	String			Optional text to include (defaults to nil)
--	name		String			Optional name for the pin (defaults to a localized version of the ore)
function public:InsertOre(mapID, x, y, ore, descript, name)
	assert(type(mapID) == "number", "An AddOn is creating a CT_MapMod pin without identifying a valid map")
	assert(type(x) == "number" and type(y) == "number" and x >= 0 and y >= 0 and x <= 1 and y <= 1, "An AddOn is creating a CT_MapMod pin without specifying valid cordinates");
	assert(type(ore) == "string", "An AddOn is creating a CT_MapMod mining pin without identifying a kind of mining node")
	if (type(descript) ~= "string") then
		descript = nil
	end
	if (type(name) ~= "string") then
		name = nil;
	end
	-- Convert from the name of a node to a type of ore (using rules for each localization)
	if (GetLocale() == "enUS" or GetLocale() == "enGB") then
	
		-- adjectives
		if (ore:sub(1,5) == "Rich " and ore:len() > 5) then
			ore = ore:sub(6); 				-- "Rich Thorium Vein" to "Thorium Vein"
		elseif (ore:sub(1,5) == "Small " and ore:len() > 6) then 
			ore = ore:sub(7); 				-- "Small Thorium Vein" to "Thorium Vein"
		end
		
		-- Dragonflight, The War Within
		if ore:sub(1,14) == "Titan-Touched " and ore:len() > 14 then
			ore = ore:sub(15)
		elseif ore:sub(1,7) == "Primal " and ore:len() > 7 then
			ore = ore:sub(8)
		elseif ore:sub(1,7) == "Molten " and ore:len() > 7 then
			ore = ore:sub(8)
		elseif ore:sub(1,9) == "Hardened " and ore:len() > 9 then
			ore = ore:sub(10)
		elseif ore:sub(1,10) == "Infurious " and ore:len() > 10 then
			ore = ore:sub(11)
		elseif ore:sub(1,12) == "Metamorphic " and ore:len() > 12 then
			ore = ore:sub(13)
		elseif ore:sub(1,7) == "Living " and ore:len() > 7 then
			ore = ore:sub(8)
		elseif ore:sub(1,13) == "Crystallized " and ore:len() > 13 then
			ore = ore:sub(14)
		elseif ore:sub(1,12) == "Camouflaged " and ore:len() > 12 then
			ore = ore:sub(13)
		elseif ore:sub(1,7) == "Webbed " and ore:len() > 7 then
			ore = ore:sub(8)
		elseif ore:sub(1,8) == "Weeping " and ore:len() > 8 then
			ore = ore:sub(9)
		elseif ore:sub(1,8) == "EZ-Mine-" and ore:len() > 8 then
			ore = ore:sub(9)
		end
		
		-- nouns
		if (ore:sub(-5) == " Vein" and ore:len() > 5) then 
			ore = ore:sub(1,-6);				-- "Copper Vein" to "Copper"
		elseif (ore:sub(-8) == " Deposit" and ore:len() > 8) then
			ore = ore:sub(1,-9);				-- "Iron Deposit" to "Iron"
		elseif (ore:sub(-5) == " Seam" and ore:len() > 5) then 
			ore = ore:sub(1,-6);				-- "Monelite Seam" to "Monelite"
		end
		
	elseif (GetLocale() == "frFR") then
	
		-- adjectifs
		if (ore:sub(1,6) == "Riche " and ore:len() > 7) then 
			ore = ore:sub(7,7):upper() .. ore:sub(8);	-- "Riche filon de thorium" to "Filon de Thorium"
		elseif (ore:sub(1,6) == "Petit " and ore:len() > 7) then 
			ore = ore:sub(7,7):upper() .. ore:sub(8);	-- "Petit filon de thorium" to "Filon de Thorium"
		end
		
		-- noms
		if (ore:sub(1,9) == "Filon de " and ore:len() > 10) then 
			ore = ore:sub(10,10):upper() .. ore:sub(11);	-- "Filon de cuivre" to "Cuivre"
		elseif (ore:sub(1,12) == "Gisement de " and ore:len() > 13) then 
			ore = ore:sub(13,13):upper() .. ore:sub(14);	-- "Gisement de fer" to "Fer"
		elseif (ore:sub(1,9) == "Veine de " and ore:len() > 10) then 
			ore = ore:sub(10,10):upper() .. ore:sub(11);	-- "Veine de gangreschiste" to "Gangreschiste"
		end
		
	elseif (GetLocale() == "deDE") then		-- credit: Dynaletik
	
		-- adjectives
		if (ore:sub(1,8) == "Reiches " and ore:len() > 8) then
			ore = ore:sub(9); 				-- "Reiches Thoriumvorkommen" to "Thoriumvorkommen"
		elseif (ore:sub(1,8) == "Kleines " and ore:len() > 8) then
			ore = ore:sub(9); 				-- "Kleines Thoriumvorkommen" to "Thoriumvorkommen"
		elseif (ore:sub(1,7) == "Reiche " and ore:len() > 7) then
			ore = ore:sub(8); 				-- "Reiche Adamantitablagerung" to "Adamantitablagerung"
		end
		
		-- Dragonflight, The War Within
		if ore:sub(1,18) == "Titanenberührtes " and ore:len() > 18 then
			ore = ore:sub(19)
		elseif ore:sub(1,16) == "Titanversetztes " and ore:len() > 16 then
			ore = ore:sub(17)
		elseif ore:sub(1,2) == "Ur" and ore:len() > 3 then
			ore = ore:sub(3,3):upper() .. ore:sub(4)
		elseif ore:sub(1,14) == "Geschmolzenes " and ore:len() > 14 then
			ore = ore:sub(15)
		elseif ore:sub(1,12) == "Gehärtetes " and ore:len() > 12 then
			ore = ore:sub(13)
		elseif ore:sub(1,15) == "Wutentbranntes " and ore:len() > 15 then
			ore = ore:sub(16)
		elseif ore:sub(1,12) == "Metamorphes " and ore:len() > 12 then
			ore = ore:sub(13)
		elseif ore:sub(1,9) == "Lebendes " and ore:len() > 9 then
			ore = ore:sub(10)
		elseif ore:sub(1,16) == "Kristallisierte " and ore:len() > 16 then
			ore = ore:sub(17)
		elseif ore:sub(1,17) == "Kristallisiertes " and ore:len() > 17 then
			ore = ore:sub(18)
		elseif ore:sub(1,9) == "Getarnte " and ore:len() > 9 then
			ore = ore:sub(10)
		elseif ore:sub(1,10) == "Getarntes " and ore:len() > 10 then
			ore = ore:sub(11)
		elseif ore:sub(1,11) == "Eingewebte " and ore:len() > 11 then
			ore = ore:sub(12)
		elseif ore:sub(1,12) == "Eingewebtes " and ore:len() > 12 then
			ore = ore:sub(13)
		elseif ore:sub(1,9) == "Heulende " and ore:len() > 9 then
			ore = ore:sub(10)
		elseif ore:sub(1,10) == "Heulendes " and ore:len() > 10 then
			ore = ore:sub(11)
		elseif ore:sub(1,13) == "Schnellabbau-" and ore:len() > 13 then
			ore = ore:sub(14)
		elseif ore:sub(1,13) == "Reichhaltige " and ore:len() > 13 then
			ore = ore:sub(14)
		elseif ore:sub(1,14) == "Reichhaltiges " and ore:len() > 14 then
			ore = ore:sub(15)
		end
		
		-- nouns
		if (ore:sub(-9) == "vorkommen" and ore:len() > 9) then
			ore = ore:sub(1, -10); 				-- "Kupfervorkommen" to "Kupfer"
		elseif (ore:sub(-5) == "flöz" and ore:len() > 5) then
			ore = ore:sub(1, -6); 				-- "Monelitflöz" to Monelit"	NOTE: the ö counts as TWO bytes
		elseif (ore:sub(-4) == "ader" and ore:len() > 4) then
			ore = ore:sub(1, -5); 				-- "Zinnader" to "Zinn"
		elseif (ore:sub(-10) == "ablagerung" and ore:len() > 10) then
			ore = ore:sub(1, -11); 				-- "Mithrilablagerung" to "Mithril"
		end
		
	elseif (GetLocale() == "esES" or GetLocale() == "esMX") then
	
		-- following adjective
		if (ore:sub(-9) == " enriquecido" and ore:len() > 12) then
			ore = ore:sub(1, -13); 				-- "Filón de torio enriquecido" to "Filón de torio"
		end
		
		-- preceeding nouns and adjectives
		if (ore:sub(1,10) == "Filón de " and ore:len() > 11) then
			ore = ore:sub(11,11):upper() .. ore:sub(12);	-- "Filón de cobre" to "Cobre"	NOTE: the ó counts as TWO bytes
		elseif (ore:sub(1,19) == "Filón pequeño de " and ore:len() > 20) then 
			ore = ore:sub(20,20):upper() .. ore:sub(21);	-- "Filón pequeño de torio" to "Torio"
		elseif (ore:sub(1,13) == "Depósito de " and ore:len() > 14) then
			ore = ore:sub(14,14):upper() .. ore:sub(15);	-- "Depósito de hierro" to "Hierro"
		elseif (ore:sub(1,18) == "Depósito rico en " and ore:len() > 19) then
			ore = ore:sub(19,19):upper() .. ore:sub(20);	-- "Depósito rico en verahierro" to "Verahierro"
		elseif (ore:sub(1,8) == "Veta de " and ore:len() > 9) then
			ore = ore:sub(9,9):upper() .. ore:sub(10);	-- "Veta de monalita" to "Monalita"
		end
		
	elseif (GetLocale() == "ptBR") then
	
		-- following adjectives
		if (ore:sub(-10) == " Abundante" and ore:len() > 10) then
			ore = ore:sub(1,-11);				-- changes "Veio de Tório Abundante" to "Veio de Tório"
		elseif (ore:sub(-8) == " Escasso" and ore:len() > 8) then
			ore = ore:sub(1,-9);				-- changes "Veio de Tório Escasso" to "Veio de Tório"
		end
		
		-- preceeding nouns
		if (ore:sub(1,8) == "Veio de " and ore:len() > 8) then
			ore = ore:sub(9);				-- changes "Veio de Cobre" to "Cobre"
		elseif (ore:sub(1,13) == "Depósito de " and ore:len() > 13) then
			ore = ore:sub(14);				-- changes "Depósito de Ferro" to "Ferro"
		elseif (ore:sub(1,10) == "Jazida de " and ore:len() > 10) then
			ore = ore:sub(11);				-- changes "Jazida de Monelita" to "Monelita"
		end
		
	elseif (GetLocale() == "ruRU") then
	
		-- preceeding
		if (ore:sub(1,15) == "Богатая " and ore:len() > 16) then
			ore = ore:sub(16,16):upper() .. ore:sub(17);	-- changes "Богатая ториевая жила" to "Ториевая жила"
		end
		if (ore:sub(1,11) == "Малая " and ore:len() > 12) then
			ore = ore:sub(12,12):upper() .. ore:sub(13);	-- changes "Малая ториевая жила" to "Ториевая жила"
		end
		if (ore:sub(1,13) == "Залежи " and ore:len() > 14) then
			ore = ore:sub(14,14):upper() .. ore:sub(15);	-- changes "Залежи истинного серебра" to "Истинного серебра"
		end
		
		-- following
		if (ore:sub(-9) == " жила" and ore:len() > 9) then
			ore = ore:sub(1,-10);				-- changes "Медная жила" to "Медная"
		end
	elseif (GetLocale() == "zhCH") then
	
		-- exceptions first, then normal rules for everything else
		if (ore == "活性魔石") then
			ore = "魔石矿石"					-- Living Leystone
		elseif (ore == "黑曜石碎块" or ore == "巨型黑曜石石板") then
			ore = "黑曜石矿"					-- Obsidium
		else
			-- normal rules: prefix characters
			if (ore:sub(1,3) == "富" and ore:len() > 3) then
				ore = ore:sub(4)			-- changes 富瑟银矿 (Rich Thorium Vein) to 瑟银矿, and later rule adds 石 to make 瑟银矿石 (Thorium Ore)
			elseif (ore:sub(1,9) == "纯净的" and ore:len() > 9) then
				ore = ore:sub(10)			-- changes 纯净的萨隆邪铁矿脉 (Pure Saronite Deposit) to 萨隆邪铁矿脉, and a later rule replaces 脉 with 石 to make 萨隆邪铁矿石 (Saronite Ore)
			elseif (ore:sub(1,15) == "软泥覆盖的" and ore:len() > 15) then
				ore = ore:sub(16)			-- changes 软泥覆盖的秘银矿脉 (Ooze Covered Mithril Deposit) to 秘银矿脉, and a later rule replaces 脉 with 石 to make 秘银矿石 (Mithril Ore)
			end
			-- normal rules: suffix characters
			if (ore:sub(-3) == "脉" and ore:len() > 3) then
				ore = ore:sub(1,-4) .. "石"		-- changes 魔铁矿脉 (Fel Iron Deposit) to 魔铁矿石 (Fel Iron Ore)
			elseif (ore:sub(-3) == "层" and ore:len() > 3) then
				ore = ore:sub(1,-4) .. "石"		-- changes 魔石矿层 (Leystone Seam) to 魔石矿石 (Leystone Ore)
			elseif (ore:sub(-3) ~= "石") then
				ore = ore .. "石"			-- changes 铜矿 (Copper Vein) to 铜矿石 (Copper Ore)
			end
		end
	end

	-- Now process the mining node
	for __, expansion in pairs(module.pinTypes["Ore"]) do
		for __, kind in ipairs(expansion) do
			if (L["CT_MapMod/Ore/" .. kind] == ore or kind == ore) then
				local isRandom = module.randomSpawns[kind];
				if (type(isRandom) == "function") then
					isRandom = isRandom();
				end
				if (isRandom and not module:getOption("CT_MapMod_IncludeRandomSpawns")) then
					-- this is an ore that appears randomly throughout the zone in place of others, such as Platinum
					return;
				end
				CT_MapMod_Notes[mapID] = CT_MapMod_Notes[mapID] or { };
				for __, note in ipairs(CT_MapMod_Notes[mapID]) do
					if ((note["name"] == kind) and (math.sqrt((note["x"]-x)^2+(note["y"]-y)^2)<.02)) then 
						--two veins of the same kind not far apart
						return;
					elseif ((note["set"] == "Ore") and (math.sqrt((note["x"]-x)^2+(note["y"]-y)^2)<.01)) then
						--two veins of different kinds very close together
						if (module:getOption("CT_MapMod_OverwriteGathering")) then
							-- overwrite the existing note
							note["x"] = x;
							note["y"] = y;
							if (note["descript"] == "" or not note["descript"]) then
								note["descript"] = "Nearby: " .. L["CT_MapMod/Ore/" .. note["subset"]];
							elseif (note["descript"]:sub(1,8) == "Nearby: " and not note["descript"]:find(L["CT_MapMod/Ore/" .. note["subset"]],9)) then
								note["descript"] = note["descript"] .. ", " .. L["CT_MapMod/Ore/" .. note["subset"]];
							end
							note["name"] = L["CT_MapMod/Ore/" .. kind];
							note["subset"] = kind;
						else
							-- leave the existing note, but add details in the description
							if (note["descript"] == "" or not note["descript"]) then
								note["descript"] = "Nearby: " .. (L["CT_MapMod/Ore/" .. kind]);
							elseif (note["descript"]:sub(1,8) == "Also nearby: " and not note["descript"]:find(L["CT_MapMod/Ore/" .. kind],9)) then
								note["descript"] = note["descript"] .. ", " .. L["CT_MapMod/Ore/" .. kind];
							end
						end
						note["datemodified"] = date("%Y%m%d");
						note["version"] = MODULE_VERSION
						return;
					elseif (math.sqrt((note["x"]-x)^2+(note["y"]-y)^2)<.005) then
						--two notes of completely different kinds EXTREMELY close together
						return;
					end
				end
				if (not name) then
					name = L["CT_MapMod/Ore/" .. kind];
				end
				-- this point will not have been reached if the earlier rules were triggered, causing the function to return early
				module:InsertPin(mapID, x, y, name, "Ore", kind, descript);
				return; -- breaks the for loops
			end
		end
	end
end

--------------------------------------------
-- DataProvider
-- Manages the adding, updating, and removing of data like icons, blobs or text to the map canvas

local CT_MapMod_DataProviderMixin = CreateFromMixins(MapCanvasDataProviderMixin);

do
	local dataProviders = { };

	function public:NewDataProvider()
		local newProvider = CreateFromMixins(CT_MapMod_DataProviderMixin);
		tinsert(dataProviders, newProvider);
		return newProvider;
	end

	function module:refreshVisibleDataProviders()
		for __, dataProvider in ipairs(dataProviders) do
			local map = dataProvider:GetMap();
			if (map and map:IsShown()) then
				dataProvider:RefreshAllData();
			end
		end
	end
end

function CT_MapMod_DataProviderMixin:RemoveAllData()
	if (self.pins) then
		self:GetMap():RemoveAllPinsByTemplate("CT_MapMod_PinTemplate");
		StaticNoteEditPanel():Hide();
		module.PinHasFocus = nil;
		wipe(self.pins);
	end
end
 
function CT_MapMod_DataProviderMixin:RefreshAllData(fromOnShow)
	-- Initialization
	self.pins = self.pins or { };

	-- Clear the map
	self:RemoveAllData();
	
	-- determine if the player is an herbalist or miner, for automatic showing of those kinds of notes
	if (GetProfessions) then
		-- Retail
		local prof1, prof2 = GetProfessions();
		if (prof1) then 
			local tradeSkill = select(7, GetProfessionInfo(prof1))
			if (tradeSkill == 182) then 
				module.isHerbalist = true;
			elseif (tradeSkill == 186) then 
				module.isMiner = true; 
			end
		end
		if (prof2) then 
			local tradeSkill = select(7, GetProfessionInfo(prof2))
			if (tradeSkill == 182) then 
				module.isHerbalist = true;
			elseif (tradeSkill == 186) then 
				module.isMiner = true;
			end
		end
	else	
-- Classic / Retail fallback via the shared CT_Library spell helper
		if (CT_Library.getSpellName(L["CT_MapMod/Map/ClassicHerbalist"])) then
			module.isHerbalist = true;
		end
		if (CT_Library.getSpellName(L["CT_MapMod/Map/ClassicMiner"])) then
			module.isMiner = true;
		end
	end
	
	-- Fetch and push the pins to be used for this map
	local mapID = self:GetMap():GetMapID();
	if (mapID) then	
		mapID = module:getOption("CT_MapMod_ShowOnFlightMaps") ~= false and module.flightMaps[mapID] or mapID;		
		if (CT_MapMod_Notes[mapID]) then
			local showUser, showHerb, showOre = 
				module:getOption("CT_MapMod_UserNoteDisplay") or 1,
				module:getOption("CT_MapMod_HerbNoteDisplay") or 1,
				module:getOption("CT_MapMod_OreNoteDisplay") or 1;
			for i, info in ipairs(CT_MapMod_Notes[mapID]) do
				if (
					info["set"] == "User" and showUser == 1
					or info["set"] == "Herb" and (showHerb == 1 and module.isHerbalist or showHerb == 2)
					or info["set"] == "Ore" and (showOre == 1 and module.isMiner or showOre == 2)
				) then
					self.pins[i] = self:GetMap():AcquirePin("CT_MapMod_PinTemplate", mapID, i, info["x"], info["y"], info["name"], info["descript"], info["set"], info["subset"], info["datemodified"], info["version"]);
				end
			end
		end
	end
end
 
--------------------------------------------
-- PinMixin
-- Pins that may be added to the map canvas, like icons, blobs or text

CT_MapMod_PinMixin = CreateFromMixins(MapCanvasPinMixin);

-- By default the modern MapCanvas lets pins pass the right (and middle) mouse button through to the
-- canvas underneath, so the map's right-click "navigate up a level" fires through our pins. We need
-- the right button for editing/dragging notes, so neutralise pass-through by stubbing the setter the
-- framework would otherwise call to enable it. (Stubbing also avoids a combat taint error from the
-- real call; same approach HandyNotes uses.)
CT_MapMod_PinMixin.SetPassThroughButtons = function() end

function CT_MapMod_PinMixin:OnLoad()
	-- Override in your mixin, called when this pin is created
	
	-- Create the basic properties of the pin itself
	self:SetWidth(15);
	self:SetHeight(15);
	self.texture = self:CreateTexture(nil,"ARTWORK");
	self.texture:SetAllPoints();
	
	-- Right-button click vs drag is handled manually in OnMouseDown/OnMouseUp below.
	-- (Modern MapCanvas wires pin scripts by mixin-method name, which clobbers a HookScript'd
	--  OnDragStart, and RegisterForDrag on a button stops its clicks reaching OnMouseUp.)
	self.isBeingDragged = nil;
end
 
function CT_MapMod_PinMixin:OnAcquired(...) -- the arguments here are anything that are passed into AcquirePin after the pinTemplate
	-- Override in your mixin, called when this pin is being acquired by a data provider but before its added to the map
	self.mapID, self.i, self.x, self.y, self.name, self.descript, self.set, self.subset, self.datemodified, self.version = ...;
	
	-- Set basic properties for the pin itself
	self:SetPosition(self.x, self.y);
	local icon = module.pinIcons[self.subset];
	if (type(icon) == "table") then
		self.texture:SetTexture(icon.path);
		self.texture:SetTexCoord(icon.left, icon.right, icon.top, icon.bottom);
	else
		self.texture:SetTexture(icon);
		self.texture:SetTexCoord(0, 1, 0, 1);
	end
	local size = module:getOption("CT_MapMod_" .. self.set .. "NoteSize") or self.set == "User" and 24 or 14;
	self:SetSize(size, size);
	self:Show();
end
 
function CT_MapMod_PinMixin:OnReleased()
	-- Override in your mixin, called when this pin is being released by a data provider and is no longer on the map
	if (self.isShowingTip) then
		GameTooltip:Hide();
		self.isShowingTip = nil;
	end
	self:Hide();
end

-- Two variants of function CT_MapMod_PinMixin:OnClick(button), for retail vs Classic
if (C_Map and C_Map.CanSetUserWaypointOnMap) then -- Made safe for Retail
	local uiMapPoint =
	{
		uiMapID = 0,
		position = CreateVector2D(0,0),
	}
	local waypointLinkPattern = "|cffffff00|Hworldmap:%d:%d:%d|h[%s]|h|r";		-- uiMapID, x, y, MAP_PIN_HYPERLINK
	function CT_MapMod_PinMixin:handleClick(button)
		if (IsModifiedClick("CHATLINK") and C_Map.CanSetUserWaypointOnMap(self.mapID)) then
			-- Share the pin in chat as a waypoint (using features introduced in Shadowlands)
			ChatEdit_InsertLink(waypointLinkPattern:format(self.mapID, self.x*10000, self.y*10000, MAP_PIN_HYPERLINK));
		elseif (IsControlKeyDown() and C_Map.CanSetUserWaypointOnMap(self.mapID)) then
			-- Set a waypoint centred on the pin (using features introduced in Shadowlands)
			uiMapPoint.uiMapID = self.mapID;
			uiMapPoint.position:SetXY(self.x, self.y);
			C_Map.SetUserWaypoint(uiMapPoint);
		elseif (button == "RightButton") then
			-- Edit the pin on a plain right-click (right-click-and-drag moves it instead).
			-- No modifier is used because Alt is commonly intercepted by the OS window manager.
			local panel = StaticNoteEditPanel();
			panel:RequestFocus(self);
		end
	end
else
	function CT_MapMod_PinMixin:handleClick(button)
		if (button == "RightButton") then
			-- Edit the pin on a plain right-click (right-click-and-drag moves it instead).
			local panel = StaticNoteEditPanel();
			panel:RequestFocus(self);
		end
	end
end

-- Right-button handling: distinguish a click (Alt-Right to edit) from a drag (hold + move to reposition).
-- Handled manually because the modern MapCanvas does not honour RegisterForDrag/OnDragStart for these pins.
function CT_MapMod_PinMixin:stopDragging()
	self.dragPending = false;
	if (not self.isBeingDragged) then return false; end
	self.isBeingDragged = false;
	local x, y = self:GetMap():GetNormalizedCursorPosition();
	if (x and y) then
		x, y = Clamp(x, 0.005, 0.995), Clamp(y, 0.005, 0.995); -- clamping to the map
		CT_MapMod_Notes[self.mapID][self.i]["x"] = x;
		CT_MapMod_Notes[self.mapID][self.i]["y"] = y;
		self.x = x;
		self.y = y;
		self:SetPosition(x, y);
		if (self.onXYChanged) then self.onXYChanged(x, y); end
	end
	return true; -- it was a drag
end

function CT_MapMod_PinMixin:OnMouseDown(button)
	if (button ~= "RightButton" or module.PinHasFocus) then return; end
	local map = self:GetMap();
	self.dragStartX, self.dragStartY = map:GetNormalizedCursorPosition();
	self.dragPending = true;
	self.isBeingDragged = false;
	local function whileDragging()
		if (not self.dragPending) then return; end
		if (not IsMouseButtonDown("RightButton")) then self:stopDragging(); return; end
		local x, y = map:GetNormalizedCursorPosition();
		if (x and y) then
			if (not self.isBeingDragged and self.dragStartX
				and (math.abs(x - self.dragStartX) > 0.003 or math.abs(y - self.dragStartY) > 0.003)) then
				self.isBeingDragged = true;
			end
			if (self.isBeingDragged) then
				x, y = Clamp(x, 0.005, 0.995), Clamp(y, 0.005, 0.995); -- clamping to the map
				self:SetPosition(x, y);
				if (self.onXYChanged) then self.onXYChanged(x, y); end
			end
		end
		C_Timer.After(0.02, whileDragging);
	end
	whileDragging();
end

function CT_MapMod_PinMixin:OnMouseUp(button)
	if (button == "RightButton" and self:stopDragging()) then
		return; -- it was a drag, not a click
	end
	self:handleClick(button);
end

local patterns = { noIcon = "  %s", basicIcon = "|T%s:20|t %s", texCoordIcon = "|T%s:20:20:0:0:%f:%f:%f:%f:%f:%f|t %s" }
function CT_MapMod_PinMixin:OnMouseEnter()
	if (self.isBeingDragged) then
		return;
	end
	local icon = module.pinIcons[self.subset];
	if ( self.x > 0.5 ) then
		GameTooltip:SetOwner(self, "ANCHOR_LEFT");
	else
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
	end
	GameTooltip:ClearLines();
	if (type(icon) == "table") then
		GameTooltip:AddDoubleLine(patterns.texCoordIcon:format(icon.path, icon.width, icon.height, icon.left * icon.width, icon.right * icon.width, icon.top * icon.height, icon.bottom * icon.height, self.name), self.set, 0, 1, 0, 0.6, 0.6, 0.6);
	elseif (icon) then
		GameTooltip:AddDoubleLine(patterns.basicIcon:format(icon, self.name), self.set, 0, 1, 0, 0.6, 0.6, 0.6);
	else
		GameTooltip:AddDoubleLine(patterns.noIcon:format(self.name), self.set, 0, 1, 0, 0.6, 0.6, 0.6);
	end
	if ( self.descript ) then
		GameTooltip:AddLine(self.descript, nil, nil, nil, 1);
	end
	if (C_Map and C_Map.CanSetUserWaypointOnMap and C_Map.CanSetUserWaypointOnMap(self.mapID)) then -- Made safe for Retail
		GameTooltip:AddLine(" ");
		GameTooltip_AddNormalLine(GameTooltip, MAP_PIN_SHARING_TOOLTIP);
		GameTooltip:AddLine(" ");
	end
	if (not module.PinHasFocus) then  -- clicking on pins won't do anything while the edit box is open for this or another pin
		local editLabel = L["CT_MapMod/Pin/Right-Click to Edit"] or "Right-Click to Edit";
		if (self.datemodified and self.version) then
			GameTooltip:AddDoubleLine(editLabel, self.datemodified .. " (" .. self.version .. ")", 0.2, 1.0, 0.2, 0.3, 0.3, 0.3);
		else
			GameTooltip:AddLine(editLabel, 0.2, 1.0, 0.2);
		end
		GameTooltip:AddDoubleLine(L["CT_MapMod/Pin/Right-Click to Drag"] or "Right-Click and Drag to Move", "uiMapId " .. self.mapID, 0.2, 1.0, 0.2, 0.3, 0.3, 0.3 );
		
	else
		if (self.datemodified and self.version) then
			GameTooltip:AddDoubleLine(" ", self.datemodified .. " (" .. self.version .. ")", 0.2, 1.0, 0.2, 0.3, 0.3, 0.3);
		end
	end
	GameTooltip:Show();
end
 
function CT_MapMod_PinMixin:OnMouseLeave()
	-- Override in your mixin, called when the mouse leaves this pin
	GameTooltip:Hide();
end	
 
function CT_MapMod_PinMixin:ApplyFrameLevel()
	if (self.set == "User") then
		self:SetFrameLevel(2099)
	else
		self:SetFrameLevel(2012);  -- herbalism and mining nodes don't cover over the flypoints
	end
end

function CT_MapMod_PinMixin:ApplyCurrentScale()
	local scale;
	local startScale = 0.80;
	local endScale = 1.60;
	local scaleFactor = 1;
	if (WorldMapFrame.IsMaximized == nil or (WorldMapFrame:IsMaximized())) then
		-- This is WoW Classic, or this is WoW Retail and the window is maximized
		scale = 1.5 / self:GetMap():GetCanvasScale() * Lerp(startScale, endScale, Saturate(scaleFactor * self:GetMap():GetCanvasZoomPercent()))
	else
		scale = 1.0 / self:GetMap():GetCanvasScale() * Lerp(startScale, endScale, Saturate(scaleFactor * self:GetMap():GetCanvasZoomPercent()))
	end
	if scale then
		if not self:IsIgnoringGlobalPinScale() then
			scale = scale * self:GetMap():GetGlobalPinScale();
		end
		self:SetScale(scale);
		self:ApplyCurrentPosition();
	end
end

function CT_MapMod_PinMixin:ApplyCurrentAlpha()
	self:SetAlpha(Lerp( 1.0*((module:getOption("CT_MapMod_AlphaZoomedOut")) or 0.85), module:getOption("CT_MapMod_AlphaZoomedIn") or 1.00, Saturate(1.00 * self:GetMap():GetCanvasZoomPercent())));
end

--------------------------------------------
-- Note Edit Panel
-- Manages the adding, updating, and removing of data like icons, blobs or text to the map canvas

-- This function is called the first time the pin is clicked on, and also every subsequent time the pin is acquired

do
	local noteEditPanel;
	
	function StaticNoteEditPanel()
	
		-- STATIC PUBLIC INTERFACE
		if (noteEditPanel) then
			return noteEditPanel;
		end
		local obj = { };
		noteEditPanel = obj;
		
		-- PRIVATE PROPERTIES
		local frame;				-- The actual note panel itself as an in-game object
		local pin;				-- The pin currently being used by the note panel
		local map;				-- The map containing the pin currently being used
		
		local nameEditBox, descriptEditBox, xEditBox, yEditBox;
		local setDropDown, subsetDropDown;
		
		-- PRIVATE METHODS
		
		-- Updates the x,y text fields to map coordinates normalized between 0.0 and 100.0 (always one decimal)
		-- Arguments:
		--	x,y		Numbers, Required		Map coordinates normalized between 0 and 1
		local function updateXY(x,y)
			xEditBox:SetText(format("%.1f", x*100));
			yEditBox:SetText(format("%.1f", y*100));			
		end

		-- Updates the text fields and dropdowns to display information about the current pin
		local function updateFields()
			-- STEP 1: Update text fields to match the current pin
			-- STEP 2: Update and display the correct dropdowns based in type of current pin
			-- STEP 3: Register to be updated of any changes to this pin's position (and de-register from previous pins)
			
			-- STEP 1:
			nameEditBox:SetText(pin.name or "");
			descriptEditBox:SetText(pin.descript or "");
			updateXY(pin.x, pin.y);
			
			-- STEP 2:
			if UIDropDownMenu_SetText and setDropDown and subsetDropDown then
				UIDropDownMenu_SetText(setDropDown,L["CT_MapMod/Pin/" .. pin.set]);
				UIDropDownMenu_SetText(subsetDropDown,L["CT_MapMod/" .. pin.set .. "/" .. pin.subset]);
				setDropDown.unapprovedValue = pin.set;
				subsetDropDown.unapprovedValue = pin.subset;
			end
			
			-- STEP 3:

			pin.onXYChanged = updateXY;
		end
		
		-- Closes the frame and saves the new properties of pin to CT_MapMod_Notes
		local function okayPressed()
			-- Fall back to the pin's existing set/subset when the dropdowns are unavailable
			-- (e.g. if UIDropDownMenu is unavailable, the frames were never created)
			local setValue = (setDropDown and setDropDown.unapprovedValue) or pin.set;
			local subsetValue = (subsetDropDown and subsetDropDown.unapprovedValue) or pin.subset;
			CT_MapMod_Notes[pin.mapID][pin.i] = {
				["x"] = pin.x,
				["y"] = pin.y,
				["name"] = nameEditBox:GetText() or pin.name,
				["set"] = setValue,
				["subset"] = subsetValue,
				["descript"] = descriptEditBox:GetText() or pin.descript,
				["datemodified"] = date("%Y%m%d"),
				["version"] = MODULE_VERSION,
			}
			frame:Hide();
			-- calling onAcquired will update tooltips and anything else that wasn't already changed
			pin:OnAcquired(pin.mapID, pin.i, pin.x, pin.y, nameEditBox:GetText() or pin.name, descriptEditBox:GetText() or pin.descript, setValue, subsetValue, date("%Y%m%d"), MODULE_VERSION );
		end

		-- Closes the frame and restores pin to its original state
		local function cancelPressed()
			frame:Hide();
			-- calling OnAcquired will reset everything user-visible to their original conditions
			pin:OnAcquired(pin.mapID, pin.i, pin.x, pin.y, pin.name, pin.descript, pin.set, pin.subset, pin.datemodified, pin.version);		
		end
		
		-- Closes the frame and removes pin from both the map and CT_MapMod_Notes
		local function deletePressed()
			module:DeletePin(pin.mapID, pin.i);
			frame:Hide();	
		end
		
		-- Creates the frame and its contents (called by the constructor)
		local function createNotePanel()
			if (frame) then
				return;
			end
			
			-- STEP 1: Create the frame, and establish its basic properties
			-- STEP 2: Create the frame's children
			
			-- STEP 1:
			frame = CreateFrame("FRAME", nil, nil, BackdropTemplateMixin and "BackdropTemplate");
			frame:SetSize(330, 180);
			frame:SetBackdrop({
				bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
				edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
				tile = true,
				tileEdge = true,
				tileSize = 16,
				edgeSize = 24,
				insets = { left = 8, right = 8, top = 8, bottom = 8 },
			});
			frame:SetBackdropColor(0.4, 0.4, 0.4, 0.8);
			if (module:getGameVersion() >= 8) then
				frame:SetScale(1.2);
			end
			
			-- STEP 2:
			local textColor0 = "#1.0:1.0:1.0";
			local textColor1 = "#0.9:0.9:0.9";
			local textColor2 = "#0.7:0.7:0.7";
			local textColor3 = "#0.9:0.72:0.0";
			module:getFrame (
				{	["button#s:80:25#br:b:-42:10#v:GameMenuButtonTemplate#" .. L["CT_MapMod/Pin/Okay"]] = {
						["onclick"] = okayPressed,
					},
					["button#s:80:25#b:b:0:10#v:GameMenuButtonTemplate#" .. L["CT_MapMod/Pin/Cancel"]] = {
						["onclick"] = cancelPressed,
					},
					["button#s:80:25#bl:b:42:10#v:GameMenuButtonTemplate#" .. L["CT_MapMod/Pin/Delete"]] = {
						["onclick"] = deletePressed,
					},
					["font#l:tr:-100:-25#x" .. textColor2 .. ":l"] = { },
					["editbox#l:tr:-85:-25#s:30:18"] = { 
						["onload"] = function(self)
							xEditBox = self;
							-- change this to allow typing in x coord manually
							self:SetAutoFocus(false);
							self:SetFontObject(ChatFontSmall);
							self:HookScript("OnEditFocusGained", function(self)
								self:ClearFocus();
							end);
						end,
					},
					["font#l:tr:-55:-25#y" .. textColor2 .. ":l"] = { },
					["editbox#l:tr:-40:-25#s:30:18"] = { 
						["onload"] = function(self)
							yEditBox = self;
							-- change this to allow typing in y coord manually
							self:SetAutoFocus(false);
							self:SetFontObject(ChatFontSmall);
							self:HookScript("OnEditFocusGained", function(self)
								self:ClearFocus();
							end);
						end,
					},
					["font#l:tl:15:-25#" .. L["CT_MapMod/Pin/Name"] .. textColor2 .. ":l"] = { },
					["editbox#l:tl:55:-25#s:150:18"] = { 
						["onload"] = function(self)
							nameEditBox = self;
							self:SetAutoFocus(false);
							Mixin(self, BackdropTemplateMixin or { });
							self:SetBackdrop({
								bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
								tile = true,
								tileSize = 1,
							});
							self:SetBackdropColor(1,1,1,1);
							self:SetFontObject(ChatFontSmall);
							self:SetMaxLetters(32);
							self:HookScript("OnEscapePressed", function(self)
								self:ClearFocus();
							end);
							self:HookScript("OnEnterPressed", function(self)
								self:ClearFocus();
							end);
						end,
					},	
					["font#l:tl:15:-50#" .. L["CT_MapMod/Pin/Type"] .. textColor2 .. ":l"] = { },
					["font#l:t:5:-50#" .. L["CT_MapMod/Pin/Icon"] .. textColor2 .. ":l"] = { },
					["font#l:tl:15:-75#" .. L["CT_MapMod/Pin/Description"] .. textColor2 .. ":l"] = { },
					["editbox#tl:tl:15:-84#br:tl:315:-144#ChatFontSmall"] = {
						["onload"] = function(self)
							descriptEditBox = self;
							Mixin(self, BackdropTemplateMixin or { });
							self:SetBackdrop({
								bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
								tile = true,
								tileSize = 1,
							});
							self:SetAutoFocus(false);
							self:SetMultiLine(true);
							self:SetMaxLetters(255);
							self:HookScript("OnEscapePressed", function()
								self:ClearFocus();
							end);
							self:HookScript("OnEnterPressed", function()
								self:ClearFocus();
							end);
						end,
					},
				},
				frame
			);
			
			-- Safeguard in case UIDropDownMenu and its templates are removed in a future patch (still present as of Midnight 12.0)
			if UIDropDownMenu_Initialize then
				setDropDown = CreateFrame("Frame", nil, frame, "UIDropDownMenuTemplate");
				setDropDown:SetPoint("LEFT",frame,"TOPLEFT",35,-52);
				UIDropDownMenu_SetWidth(setDropDown, 90);
				UIDropDownMenu_JustifyText(setDropDown, "LEFT");
				
				subsetDropDown = CreateFrame("Frame", nil, frame, "UIDropDownMenuTemplate");
				subsetDropDown:SetPoint("LEFT",frame,"TOP",30,-52);
				UIDropDownMenu_SetWidth(subsetDropDown, 90);
				UIDropDownMenu_JustifyText(subsetDropDown, "LEFT");

				UIDropDownMenu_Initialize(setDropDown, function()
					local dropdownEntry = { };

					dropdownEntry.func = function(self)
						setDropDown.unapprovedValue = self.value;
						UIDropDownMenu_SetText(setDropDown, L["CT_MapMod/Pin/" .. self.value]);
						pin:SetHeight(module:getOption("CT_MapMod_" .. self.value .. "NoteSize") or 24);
						pin:SetWidth(module:getOption("CT_MapMod_" .. self.value .. "NoteSize") or 24);
						if (pin.set == self.value) then
							-- return to the pin's original icon
							subsetDropDown.unapprovedValue = pin.subset;
							UIDropDownMenu_SetText(subsetDropDown, L["CT_MapMod/" .. self.value .. "/" .. pin.subset]);
							local icon = module.pinIcons[pin.subset];
							if (type(icon) == "table") then
								pin.texture:SetTexture(icon.path);
								pin.SetTexCoord(icon.left, icon.right, icon.top, icon.bottom);
							else
								pin.texture:SetTexture(icon);
								pin.texture:SetTexCoord(0, 1, 0, 1);
							end
						else
							-- use the first icon on the list
							local name = self.value ~= "User" and module.pinTypes[self.value]["Classic"][1] or module.pinTypes[self.value][1];
							subsetDropDown.unapprovedValue = name;
							UIDropDownMenu_SetText(subsetDropDown, L["CT_MapMod/" .. self.value .. "/" .. name]);
							local icon = module.pinIcons[name];
							if (type(icon) == "table") then
								pin.texture:SetTexture(icon.path);
								pin.SetTexCoord(icon.left, icon.right, icon.top, icon.bottom);
							else
								pin.texture:SetTexture(icon);
								pin.texture:SetTexCoord(0, 1, 0, 1);
							end
						end
					end

					-- user
					dropdownEntry.value = "User";
					dropdownEntry.text = L["CT_MapMod/Pin/User"];
					dropdownEntry.checked = nil;
					if ((setDropDown.unapprovedValue or pin.set) == "User") then dropdownEntry.checked = true; end
					UIDropDownMenu_AddButton(dropdownEntry);

					-- herb
					dropdownEntry.value = "Herb";
					dropdownEntry.text = L["CT_MapMod/Pin/Herb"];
					dropdownEntry.checked = nil;
					if ((setDropDown.unapprovedValue or pin.set) == "Herb") then dropdownEntry.checked = true; end
					UIDropDownMenu_AddButton(dropdownEntry);

					-- ore
					dropdownEntry.value = "Ore";
					dropdownEntry.text = L["CT_MapMod/Pin/Ore"];
					dropdownEntry.checked = nil;
					if ((setDropDown.unapprovedValue or pin.set) == "Ore") then dropdownEntry.checked = true; end
					UIDropDownMenu_AddButton(dropdownEntry);
				end);
				UIDropDownMenu_JustifyText(setDropDown, "LEFT");

				UIDropDownMenu_Initialize(subsetDropDown, function(frame, level, menuList)
					local set = setDropDown.unapprovedValue or pin.set;

					-- on-click handler for dropdown menu items
					local function onClick(entry, arg1, arg2, checked)
						subsetDropDown.unapprovedValue = entry.value;
						UIDropDownMenu_SetText(subsetDropDown,L["CT_MapMod/" .. set .. "/" .. entry.value]);
						local icon = module.pinIcons[entry.value];
						if (type(icon) == "table") then
							pin.texture:SetTexture(icon.path);
							pin.SetTexCoord(icon.left, icon.right, icon.top, icon.bottom);
						else
							pin.texture:SetTexture(icon);
							pin.texture:SetTexCoord(0, 1, 0, 1);
						end
					end

					-- Dropdown builder
					local function addEntries(tbl)
						local dropdownEntry = module:getTable();
						dropdownEntry.func = onClick;
						for i, name in ipairs(tbl) do
							dropdownEntry.text = L["CT_MapMod/" .. set .. "/" .. name] or name;
							dropdownEntry.value = name;
							local icon = module.pinIcons[name];
							if (type(icon) == "table") then
								dropdownEntry.icon = icon.path;
								dropdownEntry.tCoordLeft = icon.left;
								dropdownEntry.tCoordRight = icon.right;
								dropdownEntry.tCoordTop = icon.top;
								dropdownEntry.tCoordBottom = icon.bottom;
							else
								dropdownEntry.icon = icon;
								dropdownEntry.tCoordLeft = nil;
								dropdownEntry.tCoordRight = nil;
								dropdownEntry.tCoordTop = nil;
								dropdownEntry.tCoordBottom = nil;
							end
							if (dropdownEntry.value == (subsetDropDown.unapprovedValue or pin.subset)) then
								dropdownEntry.checked = true;
							elseif (not subsetDropDown.unapprovedValue and i == 1) then
								dropdownEntry.checked = true;
							else
								dropdownEntry.checked = false;
							end
							UIDropDownMenu_AddButton(dropdownEntry, level);
						end
						module:freeTable(dropdownEntry);
					end
					
					if (set == "User") then
						addEntries(module.pinTypes.User);
					elseif (module:getGameVersion() >= 8) then
						-- herbs and ore, with expansions
						if (level == 1) then
							local dropdownEntry = module:getTable();
							for key, __ in pairs(module.pinTypes[set]) do
								dropdownEntry.text = key;
								dropdownEntry.hasArrow = true;
								dropdownEntry.value = key;
								dropdownEntry.icon = nil;
								dropdownEntry.menuList = key;
								UIDropDownMenu_AddButton(dropdownEntry);
							end
							module:freeTable(dropdownEntry);
						elseif (menuList) then
							addEntries(module.pinTypes[set][menuList]);
						end
					else
						-- Herbs and ore, Classic only
						addEntries(module.pinTypes[set]["Classic"]);
					end
				end);		
			end
        end			
		
		-- PUBLIC METHODS

		function obj:RequestFocus(newPin)
			if (not newPin) then return; end
			if (pin) then
				pin.onXYChanged = nil;	-- eliminates any previous callback function that was created by updateFields();
			end
			pin = newPin;
			map = pin:GetMap();
			if (not frame) then
				createNotePanel();
			end
			frame:SetParent(map);
			frame:ClearAllPoints();
			frame:SetPoint("TOP", map, "BOTTOM", 0, -10);
			frame:SetClampedToScreen(true);
			frame:SetClampRectInsets(-20, 20, 20, -20);
			frame:Show();
			updateFields();
		end
		
		function obj:Hide()
			if (frame) then
				frame:Hide();
			end
		end
		
		-- PUBLIC CONSTRUCTOR
		
		do
			return obj;
		end
	end
end

--------------------------------------------
-- UI elements added to the world map title bar

function module.configureWorldMapFrame()
	local newpinmousestart;
	module:getFrame ({
		["button#n:CT_MapMod_WhereAmIButton#s:100:20#v:UIPanelButtonTemplate#" .. L["CT_MapMod/Map/Where am I?"]] = {
			["onload"] = function (self)
				module.mapResetButton = self;
				local function updatePosition(value)
					self:ClearAllPoints();
					if (value == 1) then
						self:SetPoint("BOTTOM",WorldMapFrame.ScrollContainer,"BOTTOM",0,3);
					elseif (value == 2) then
						self:SetPoint("TOP",WorldMapFrame.ScrollContainer,"TOP",0,-1);
					else
						self:SetPoint("TOPLEFT",WorldMapFrame.ScrollContainer,"TOPLEFT",3,-40);
					end
				end
				updatePosition(module:getOption("CT_MapMod_MapResetButtonPlacement") or 1);
				self.updatePosition = updatePosition;
				
				local doAutoShow, autoShowTicker;
				local function updateVisibility(value)
					if (value == 1) then
						doAutoShow = true;
					elseif (value == 2) then
						doAutoShow = false;
						self:Show();
					else
						doAutoShow = false;
						self:Hide();
					end
				end
				updateVisibility(module:getOption("CT_MapMod_ShowMapResetButton") or 1);
				self.updateVisibility = updateVisibility;
							
				local function autoShow()
					if (doAutoShow) then
						if (WorldMapFrame:GetMapID() ~= C_Map.GetBestMapForUnit("player")) then
							self:Show();
						else
							self:Hide();
						end
					end
				end
				
				WorldMapFrame.ScrollContainer:HookScript("OnShow", function()
					autoShow();
					autoShowTicker = autoShowTicker or C_Timer.NewTicker(1, autoShow);
				end);
				
				WorldMapFrame.ScrollContainer:HookScript("OnHide", function()
					if (autoShowTicker) then
						autoShowTicker:Cancel();
						autoShowTicker = nil;
					end
				end);
				
				self:HookScript("OnClick", function()
					WorldMapFrame:SetMapID(C_Map.GetBestMapForUnit("player"));
					autoShow();
				end);
			end,
			["onenter"] = function(self)
				GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT", 30, 15);
				GameTooltip:SetText("CT: " .. L["CT_MapMod/Map/Reset the map"]);
				GameTooltip:Show();
			end,
			["onleave"] = function(self)
				GameTooltip:Hide();
			end
		},
		["button#n:CT_MapMod_Button#s:32:32"] = {
			"texture#all#i:enabled#Interface\\Addons\\CT_Library\\Images\\minimapIcon",  

			["onclick"] = function (self, button)
				if (not self.dropdown) then
					self.dropdown = CreateFrame("Frame", nil, self, "UIDropDownMenuTemplate");
					UIDropDownMenu_Initialize(
						self.dropdown,
						function(frame, level, menuList)
							local info = module:getTable();
							info.notCheckable = true;
							if (level == 1) then

								-- CT_MapMod
								info.text = MODULE_NAME;
								info.isTitle = true;	
								UIDropDownMenu_AddButton(info, 1);

								-- Create a note
								info.text = L["CT_MapMod/Map/DropDown/NewNote"];
								info.isTitle = false;
								info.hasArrow = true;
								info.disabled = false;
								info.menuList = "NewNote";
								UIDropDownMenu_AddButton(info, 1);

								-- Settings
								info.text = L["CT_MapMod/Map/DropDown/Options"];
								info.hasArrow = false;
								info.func = function()
									module:showModuleOptions();
									if (WorldMapFrame:GetFrameStrata() == "FULLSCREEN") then
										-- so the options are visible on classic
										CTCONTROLPANEL:SetFrameStrata("FULLSCREEN_DIALOG");
									end
								end
								UIDropDownMenu_AddButton(info, 1);

							elseif (menuList == "NewNote") then
								
								-- New note at cursor
								info.text = L["CT_MapMod/Map/DropDown/AtCursor"];
								info.disabled = nil;
								info.icon = module.pinIcons["Grey Note"];
								info.func = function()
									module.isCreatingNote = true;
								end
								UIDropDownMenu_AddButton(info, level);

								-- New note at player
								local mapID = WorldMapFrame:GetMapID();
								local playerPosition = C_Map.GetPlayerMapPosition(mapID, "player");
								if (playerPosition) then
									local x, y = playerPosition:GetXY();
									info.text = string.format("%s (%d,%d)", L["CT_MapMod/Map/DropDown/AtPlayer"], x*100, y*100);
									info.func = function()
										module:InsertPin(mapID, x, y, "New Note", "User", "Diamond", "New note under player");
									end
									info.icon = module.pinIcons.Diamond;
									UIDropDownMenu_AddButton(info, level);
								end
						
								-- New note at waypoint
								if (C_Map and C_Map.CanSetUserWaypointOnMap) then
									local position = C_Map.HasUserWaypoint() and C_Map.GetUserWaypointPositionForMap(mapID);
									local x, y = position and position.x, position and position.y;
									if (x and x <= 1 and y and y <= 1 and x >= 0 and y >= 0 and (x > 0 or y > 0)) then
										info.text = string.format("%s (%d,%d)", L["CT_MapMod/Map/DropDown/AtWaypoint"], x*100, y*100);
										info.func = function()
											module:InsertPin(mapID, x, y, "Waypoint", "User", "Waypoint", "New note under waypoint");
										end
									info.icon = module.pinIcons.Waypoint.path;
									info.tCoordLeft = module.pinIcons.Waypoint.left;
									info.tCoordRight = module.pinIcons.Waypoint.right;
									info.tCoordBottom = module.pinIcons.Waypoint.bottom;
									info.tCoordTop = module.pinIcons.Waypoint.top;
									UIDropDownMenu_AddButton(info, level);
									end
								end
								
							end
							module:freeTable(info);
						end,
						"MENU"	-- causes it to be like a context menu
					);
				end
				ToggleDropDownMenu(1, nil, self.dropdown, self, -50, 0);
			end,
			["ondragstart"] = function(self)
				self.updateClamps();
				self:StartMoving();
			end,
			["ondragstop"] = function(self)
				self:StopMovingOrSizing();
				self.setPosition();
			end,
			["onload"] = function(self)
				local anchorFrom = WorldMapFrame.ScrollContainer;
				local leftMinOffset = 140;
				local hasWaypoints = C_Map and C_Map.CanSetUserWaypointOnMap;
				local rightMaxOffset = MapLegendScrollFrame and -116 or hasWaypoints and -84 or WorldMapFrame.BorderFrame.MaximizeMinimizeFrame and -52 or -20; -- Made safe for Retail
				local yOff = -18.5;
				self.updateClamps = function()
					local scale = WorldFrame:GetEffectiveScale() / self:GetEffectiveScale();
					self:SetClampRectInsets(
						- anchorFrom:GetLeft() - leftMinOffset,
						- anchorFrom:GetRight() + WorldFrame:GetRight()*scale,
						- anchorFrom:GetTop() - 15 + WorldFrame:GetTop()*scale,
						- anchorFrom:GetTop() + 45
					);
				end
				self.updatePoint = function(anchor, xOff)
					self:ClearAllPoints()
					local maxWidth = anchorFrom:GetWidth() / 4;
					xOff = Clamp(xOff, -maxWidth, maxWidth);
					self:SetPoint("CENTER", anchorFrom, anchor, xOff, yOff);
				end
				self.setPosition = function()
					local btnCenterX, mapLeftX, mapRightX, mapCenterX = self:GetCenter(), anchorFrom:GetLeft(), anchorFrom:GetRight(), anchorFrom:GetCenter();
					btnCenterX = Clamp(btnCenterX, mapLeftX + leftMinOffset, mapRightX + rightMaxOffset);
					local anchor, xOff;
					if (abs(btnCenterX - mapRightX) < abs(btnCenterX - mapCenterX)) then
						anchor, xOff = "TOPRIGHT", btnCenterX - mapRightX;
					elseif (abs(btnCenterX - mapLeftX) < abs(btnCenterX - mapCenterX)) then
						anchor, xOff = "TOPLEFT", btnCenterX - mapLeftX;
					else
						anchor, xOff = "TOP", btnCenterX - mapCenterX;
					end
					module:setOption("CT_MapMod_MapButton_Anchor", anchor);
					module:setOption("CT_MapMod_MapButton_OffX", xOff);
					self.updatePoint(anchor, xOff);
				end
				local function updatePosition()
					self.updateClamps();
					self.updatePoint(module:getOption("CT_MapMod_MapButton_Anchor") or "TOPRIGHT", module:getOption("CT_MapMod_MapButton_OffX") or rightMaxOffset);
				end
				if (WorldMapFrame.BorderFrame.MaximizeMinimizeFrame) then
					hooksecurefunc(WorldMapFrame.BorderFrame.MaximizeMinimizeFrame, "Maximize", updatePosition);
					hooksecurefunc(WorldMapFrame.BorderFrame.MaximizeMinimizeFrame, "Minimize", updatePosition);
				else
					-- Classic changes the map's position/scale to simulate older screens, so wait until the next frame
					WorldMapFrame.ScrollContainer:HookScript("OnShow", function() C_Timer.After(0, updatePosition) end);
				end
				self:RegisterForClicks("LeftButtonUp", "RightButtonUp");
				self:RegisterForDrag("LeftButton","RightButton");
				self:SetClampedToScreen(true);
				self:SetMovable(true);
			end,
		},
		["frame#n:CT_MapMod_pxy#s:80:16#b:b:-100:0"] = { 
			["onload"] = function(self)
				module.pxy = self
				local text = self:CreateFontString(nil,"ARTWORK","ChatFontNormal");
				text:SetAllPoints();
				local function updateText()
					local mapID = WorldMapFrame:GetMapID();
					if (mapID) then
						local playerposition = C_Map.GetPlayerMapPosition(mapID,"player");
						if (playerposition) then
							local px, py = playerposition:GetXY();
							text:SetText(format("P: %.1f, %.1f", px*100, py*100));
						else
							text:SetText("-");
						end
						if (mapID == C_Map.GetBestMapForUnit("player")) then
							text:SetTextColor(1,1,1,1);		
						else
							text:SetTextColor(1,1,1,.3);			
						end
					end
				end
				self.updateText = updateText;
			end,
			["onenter"] = function(self)
				GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT", 30, 15);
				local playerposition = C_Map.GetPlayerMapPosition(WorldMapFrame:GetMapID(),"player");
				if (playerposition) then
					GameTooltip:SetText("CT: Player Coords");
				else
					GameTooltip:SetText("Player coords not available here");
				end
				GameTooltip:Show();
			end,
			["onleave"] = function(self)
				GameTooltip:Hide();
			end,
			["onshow"] = function(self)
				self.textTicker = self.textTicker or C_Timer.NewTicker(0.5, self.updateText);
			end,
			["onhide"] = function(self)
				if (self.textTicker) then
					self.textTicker:Cancel();
					self.textTicker = nil;
				end
			end,
		},
		["frame#n:CT_MapMod_cxy#s:80:16#b:b:100:0"] =  { 
			["onload"] = function(self)
				module.cxy = self
				local text = self:CreateFontString(nil,"ARTWORK","ChatFontNormal");
				text:SetAllPoints();
				local function updateText()
					if (WorldMapFrame.ScrollContainer.Child:GetLeft()) then
						local cx, cy = WorldMapFrame:GetNormalizedCursorPosition();
						if (cx and cy) then
							if (cx > 0 and cx < 1 and cy > 0 and cy < 1) then
								text:SetTextColor(1,1,1,1);
								text:SetText(format("C: %.1f, %.1f", cx*100, cy*100));
							else
								text:SetTextColor(1,1,1,.3);
								cx = math.max(math.min(cx,1),0);
								cy = math.max(math.min(cy,1),0);				
								text:SetText(format("C: %d, %d", cx*100, cy*100));
							end

						end
					end
				end
				self.updateText = updateText;
			end,
			["onenter"] = function(self)
				GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT", 30, 15);
				GameTooltip:SetText("CT: Cursor Coords");
				GameTooltip:Show();
			end,
			["onleave"] = function(self)
				GameTooltip:Hide();
			end,
			["onshow"] = function(self)
				self.textTicker = self.textTicker or C_Timer.NewTicker(0.1, self.updateText);
			end,
			["onhide"] = function(self)
				if (self.textTicker) then
					self.textTicker:Cancel();
					self.textTicker = nil;
				end
			end,
		},
	}, WorldMapFrame.ScrollContainer);
	
	-- Adding notes to the map by clicking on it
	WorldMapFrame:AddCanvasClickHandler(function(canvas, button)
		if (not module.isCreatingNote) then return; end
		module.isCreatingNote = nil;
		GameTooltip:Hide();
		if (InCombatLockdown()) then return; end
		local mapID = WorldMapFrame:GetMapID();
		local x,y = WorldMapFrame:GetNormalizedCursorPosition();
		if (mapID and x and y and x>=0 and y>=0 and x<=1 and y<=1 and (x~=0 or y~=0)) then
			module:InsertPin(mapID, x, y, "New Note", "User", "Grey Note", "New note at cursor");
			C_Timer.After(0.01,function() if (WorldMapFrame:GetMapID() ~= mapID) then WorldMapFrame:SetMapID(mapID) end end); --to add pins on the parts of a map in other zones
		end
	end);
	
	-- integrate extra features into the Shadowlands 9.0 waypoint pin
	if (WaypointLocationPinMixin) then
		hooksecurefunc(WaypointLocationPinMixin, "OnMouseClickAction", function(self)
			local mapID = self:GetMap():GetMapID();
			local x, y = self:GetPosition();
			if (x and y and module.isCreatingNote) then
				module:InsertPin(mapID, x, y, "Waypoint", "User", "Waypoint", "New note under waypoint");
				module.isCreatingNote = nil;
			end
		end);	
	end
end


--------------------------------------------
-- FlightMapFrame (flight paths except WoD)

function module.configureFlightMapFrame()

	local showUnreachable = module:getOption("CT_MapMod_ShowUnreachableFlightPaths") ~= false

	local hookedPins = {}				-- used to hook things only once, and also to undo hooks when an optin is turned off

	function module.updateFlightMapFrame(option, value)	-- until this exists, module.update() is smart enough not to try calling it
		if (option == "CT_MapMod_ShowUnreachableFlightPaths" and value ~= showUnreachable) then
			showUnreachable = value
			for pin in pairs(hookedPins) do
				pin.SetShown, pin.ctSetShown = pin.ctSetShown, pin.SetShown
				pin.OnClick, pin.ctOnClick = pin.ctOnClick, pin.OnClick
			end
			if (FlightMapFrame:IsShown()) then
				FlightMapFrame:RefreshAllDataProviders()
			end
		end
	end

	local currentNodeID = 0;
	
	local function CT_MapMod_FlightPointPinTemplate_SetShown(pin, value)
		return pin.ctSetShown(pin, value or module.specialTransportNodes[currentNodeID] == module.specialTransportNodes[pin.taxiNodeData.nodeID])
	end
	
	local function CT_MapMod_FlightPointPinTemplate_OnClick(pin, button)
		if (pin.taxiNodeData.state == Enum.FlightPathState.Reachable) then
			return pin.ctOnClick(pin, button)
		end
	end
	
	local function CT_MapMod_FlightMapFrame_OnShow(frame)
		local needReload = false
		for pin in FlightMapFrame:EnumeratePinsByTemplate("FlightMap_FlightPointPinTemplate") do
			if (pin.taxiNodeData.state == 0 and pin.taxiNodeData.nodeID ~= currentNodeID) then
				currentNodeID = pin.taxiNodeData.nodeID
				needReload = true
			end
			if (hookedPins[pin] == nil) then
				hookedPins[pin] = true
				if (showUnreachable) then
					pin.SetShown, pin.ctSetShown = CT_MapMod_FlightPointPinTemplate_SetShown, pin.SetShown
					pin.OnClick, pin.ctOnClick = CT_MapMod_FlightPointPinTemplate_OnClick, pin.OnClick
					pin:SetShown(pin.taxiNodeData.state ~= Enum.FlightPathState.Unreachable)
				else
					pin.ctSetShown = CT_MapMod_FlightPointPinTemplate_SetShown
					pin.ctOnClick = CT_MapMod_FlightPointPinTemplate_OnClick
				end
				needReload = true
			end
		end
		if (needReload) then
			FlightMapFrame:RefreshAllDataProviders()
		end
	end
	
	FlightMapFrame:HookScript("OnShow", CT_MapMod_FlightMapFrame_OnShow)
end

--------------------------------------------
-- TaxiFrame (flight paths in WoD)

function module.configureTaxiFrame()

	local showUnreachable = module:getOption("CT_MapMod_ShowUnreachableFlightPaths") ~= false

	local hookedButtons = {}
	
	function module.updateTaxiFrame(option, value)	-- until this exists, module.update() is smart enough not to try calling it
		if (option == "CT_MapMod_ShowUnreachableFlightPaths" and value ~= showUnreachable) then
			showUnreachable = value
			for __, button in ipairs(hookedButtons) do
				button.Hide, button.ctHide = button.ctHide, button.Hide
			end
			if (TaxiFrame:IsShown()) then
				-- reset the appearance
				TaxiFrame_OnShow(TaxiFrame)
			end
		end
	end
	
	local function CT_MapMod_TaxiFrame_OnHide(button)
		button:SetShown(button:GetID() <= NumTaxiNodes())
	end
	
	local function CT_MapMod_TaxiFrame_OnShow()
		local needReload
		for i = #hookedButtons + 1, NUM_TAXI_BUTTONS do
			local button = _G["TaxiButton" .. i]
			hookedButtons[i] = button
			if(showUnreachable) then
				button.Hide, button.ctHide = button.Show, button.Hide
				needReload = true
			else
				button.ctHide = button.Show
			end
		end
		if (needReload) then
			TaxiFrame_OnShow(TaxiFrame)
		end
	end
	
	TaxiFrame:HookScript("OnShow", CT_MapMod_TaxiFrame_OnShow)
	
end

--------------------------------------------
-- TaxiFrame (classic alternative)

function module.configureClassicTaxiFrame()

	local showUnreachable = module:getOption("CT_MapMod_ShowUnreachableFlightPaths") ~= false
		
	local function creationFunc(self)
		local frame = CreateFrame("Frame", nil, TaxiFrame)
		frame:SetSize(8, 8)
		frame.tex = frame:CreateTexture(nil, "BACKGROUND", nil, -8)
		frame.tex:SetTexture("Interface\\TaxiFrame\\UI-Taxi-Icon-Nub")
		frame.tex:SetAllPoints()
		frame:SetScript("OnEnter", function()
			module:displayTooltip(frame, {frame.text or "", "|cffff3333" .. TAXI_PATH_UNREACHABLE}, "ANCHOR_RIGHT")
		end)
		return frame
	end
	local function resetFunc(self, obj)
		obj:Hide()
	end
	
	local flightMarkers = CreateObjectPool(creationFunc, resetFunc)
	
	local function CT_MapMod_TaxiFrameClassic_OnShow()
		if (showUnreachable) then
			local knownDestinations = {}
			for i=1, NumTaxiNodes() do
				if TaxiNodeGetType(i) == "REACHABLE" or TaxiNodeGetType(i) == "CURRENT" then
					knownDestinations[TaxiNodeName(i)] = true
				end
			end
			local taxiMap = GetTaxiMapID()
			if (taxiMap) then
				local data = module.classicTaxiMaps[taxiMap]
				if (data) then
					local nodes = C_TaxiMap.GetTaxiNodesForMap(data.mapID)
					local wrongFaction = UnitFactionGroup("player") == "Horde" and Enum.FlightPathFaction.Alliance or Enum.FlightPathFaction.Horde
					for __, node in pairs(nodes) do
						if (node.faction ~= wrongFaction and not module.ignoreClassicTaxiNodes[node.nodeID] and not knownDestinations[node.name]) then
							local pin = flightMarkers:Acquire()
							local x, y = node.position:GetXY()
							pin:SetPoint("CENTER", TaxiRouteMap, "TOPLEFT", (x + data.xOff) * TaxiRouteMap:GetWidth() * (data.xScale), - (y + (data.yOff)) * TaxiRouteMap:GetHeight() * (data.yScale))
							pin:Show()
							pin.text = node.name
						end
					end
				end
			end
		end
	end
	
	local function CT_MapMod_TaxiFrameClassic_OnHide()
		flightMarkers:ReleaseAll()
	end
	
	function module.updateTaxiFrame(option, value)	-- until this exists, module.update() is smart enough not to try calling it
		if (option == "CT_MapMod_ShowUnreachableFlightPaths" and value ~= showUnreachable) then
			showUnreachable = value
			if (TaxiFrame:IsShown()) then
				-- reset the appearance
				CT_MapMod_TaxiFrameClassic_OnHide()
				CT_MapMod_TaxiFrameClassic_OnShow()
			end
		end
	end
	
	TaxiFrame:HookScript("OnShow", CT_MapMod_TaxiFrameClassic_OnShow)
	TaxiFrame:HookScript("OnHide", CT_MapMod_TaxiFrameClassic_OnHide)
	
end

--------------------------------------------
-- Auto-Gathering

do	
	-- Outside combat, monitor the player's actions to detect herbalism and mining
	local frame = CreateFrame("Frame")
	frame:RegisterEvent("UNIT_SPELLCAST_SENT");
	frame:RegisterEvent("PLAYER_REGEN_DISABLED");
	frame:RegisterEvent("PLAYER_REGEN_ENABLED");
	frame:SetScript("OnEvent", function(self, event, arg1, arg2, arg3, arg4)
		if (event == "UNIT_SPELLCAST_SENT" and arg1 == "player") then
			if (module.gatheringSkills[arg4]) then
				local mapID = C_Map.GetBestMapForUnit("player");
				if (mapID) then
					local position = C_Map.GetPlayerMapPosition(mapID,"player");	-- TODO: measure if checking for the type of skill first would be faster than doing these API calls
					if (position) then
						local x, y = position:GetXY();
						if (x and y and (x ~= 0 or y ~= 0)) then			-- could be nil or 0 in dungeons and raids to prevent cheating
							-- Herbalism and Mining
							if (module.gatheringSkills[arg4] == "Herb" and (module:getOption("CT_MapMod_AutoGatherHerbs") or 1) == 1) then
								module:InsertHerb(mapID, x, y, arg2);
							elseif (module.gatheringSkills[arg4] == "Ore" and (module:getOption("CT_MapMod_AutoGatherOre") or 1) == 1) then
								module:InsertOre(mapID, x, y, arg2);
							end
						end
					end
				end
			end
			
		elseif (event == "PLAYER_REGEN_DISABLED") then
			-- Improve performance by not even looking for herbs/mining during combat
			frame:UnregisterEvent("UNIT_SPELLCAST_SENT");
		elseif (event == "PLAYER_REGEN_ENABLED") then
			-- Restore searching for herbs/mining out of combat
			frame:RegisterEvent("UNIT_SPELLCAST_SENT");
		end
	end);
end


--------------------------------------------
-- Options handling

function module:init()
	-- initialize the overall UI
	module:Initialize();

	-- convert an older note name for compatibility
	for __, zone in pairs(CT_MapMod_Notes) do
		for __, pin in pairs(zone) do
			if pin.subset == "Stormvein" then
				pin.subset = "Stormvine"
			end
		end
	end
	
	-- handle options
	module.pxy:ClearAllPoints();
	module.cxy:ClearAllPoints();
	local position = module:getOption("CT_MapMod_ShowPlayerCoordsOnMap") or 2;
	if (position == 1) then
		module.pxy:Show();
		module.pxy:SetPoint("TOP",WorldMapFrame.BorderFrame,"TOP",-105,-3);
	elseif (position == 2) then
		module.pxy:Show();
		module.pxy:SetPoint("BOTTOM",WorldMapFrame.ScrollContainer,"BOTTOM",-100,3);
	else
		module.pxy:Hide();
	end
	position = module:getOption("CT_MapMod_ShowCursorCoordsOnMap") or 2;
	if (position == 1) then
		module.cxy:Show();
		module.cxy:SetPoint("TOP",WorldMapFrame.BorderFrame,"TOP",95,-3);
	elseif (position == 2) then
		module.cxy:Show();
		module.cxy:SetPoint("BOTTOM",WorldMapFrame.ScrollContainer,"BOTTOM",100,3);
	else
		module.cxy:Hide();
	end
end

function module:update(optName, value)
	if (optName == "CT_MapMod_ShowPlayerCoordsOnMap") then
		if (not module.pxy) then return; end
		module.pxy:ClearAllPoints();
		if (value == 1) then
			module.pxy:Show();
			module.pxy:SetPoint("TOP",WorldMapFrame.BorderFrame,"TOP",-105,-3);
		elseif (value == 2) then
			module.pxy:Show();
			module.pxy:SetPoint("BOTTOM",WorldMapFrame.ScrollContainer,"BOTTOM",-100,3);	
		else
			module.pxy:Hide();
		end
	elseif (optName == "CT_MapMod_ShowCursorCoordsOnMap") then
		if (not module.cxy) then return; end
		module.cxy:ClearAllPoints();
		if (value == 1) then
			module.cxy:Show();
			module.cxy:SetPoint("TOP",WorldMapFrame.BorderFrame,"TOP",95,-3);
		elseif (value == 2) then
			module.cxy:Show();
			module.cxy:SetPoint("BOTTOM",WorldMapFrame.ScrollContainer,"BOTTOM",100,3);		
		else
			module.cxy:Hide();
		end
	elseif (optName == "CT_MapMod_ShowMapResetButton") then
		if (module.mapResetButton) then
			module.mapResetButton.updateVisibility(value);
		end
	elseif (optName == "CT_MapMod_MapResetButtonPlacement") then
		if (module.mapResetButton) then
			module.mapResetButton.updatePosition(value);
		end
	elseif (optName == "CT_MapMod_UserNoteSize"
		or optName == "CT_MapMod_HerbNoteSize"
		or optName == "CT_MapMod_OreNoteSize"
		or optName == "CT_MapMod_UserNoteDisplay"
		or optName == "CT_MapMod_HerbNoteDisplay"
		or optName == "CT_MapMod_OreNoteDisplay"
		or optName == "CT_MapMod_AlphaZoomedOut"
		or optName == "CT_MapMod_AlphaZoomedIn"
		or optName == "CT_MapMod_ShowOnFlightMaps"
	) then
		module:refreshVisibleDataProviders();
	elseif (optName == "CT_MapMod_ShowUnreachableFlightPaths") then
		if (module.updateFlightMapFrame) then
			module.updateFlightMapFrame(optName, value);
		end
		if (module.updateTaxiFrame) then
			module.updateTaxiFrame(optName, value);
		end
	end
end

--------------------------------------------
-- /ctmap options frame

-- Slash command
local function slashCommand(msg)
	module:showModuleOptions();
end

module:setSlashCmd(slashCommand, "/ctmapmod", "/ctmap", "/mapmod", "/ctcarte", "/ctkarte");
-- Original: /ctmapmod, /ctmap, /mapmod
-- frFR: /ctcarte
-- deDE: /ctkarte

-- Options frame
module.frame = function()
	local optionsFrameList = module:framesInit()
	
	-- helper funcs
	local function optionsAddFrame (offset, size, details, data) module:framesAddFrame(optionsFrameList, offset, size, details, data) end
	local function optionsAddObject (offset, size, details) module:framesAddObject(optionsFrameList, offset, size, details) end
	local function optionsAddScript (name, func) module:framesAddScript(optionsFrameList, name, func) end
	local function optionsAddTooltip (text) module:framesAddScript(optionsFrameList, "onenter", function(obj) module:displayTooltip(obj, text, "CT_ABOVEBELOW", 0, 0, CTCONTROLPANEL) end) end
	local function optionsBeginFrame (offset, size, details, data) module:framesBeginFrame(optionsFrameList, offset, size, details, data) end
	local function optionsEndFrame () module:framesEndFrame(optionsFrameList) end
	local function optionsAddFromTemplate (offset, size, details, template) module:framesAddFromTemplate(optionsFrameList, offset, size, details, template) end

	local textColor0 = "#1.0:1.0:1.0";
	local textColor1 = "#0.9:0.9:0.9";
	local textColor2 = "#0.7:0.7:0.7";
	local textColor3 = "#0.9:0.72:0.0";
	local xoffset, yoffset;

	optionsBeginFrame(-5, 0, "frame#tl:0:%y#r");
		-- Tips
		optionsAddObject(  0,   17, "font#tl:5:%y#v:GameFontNormalLarge#" .. L["CT_MapMod/Options/Tips/Heading"]); -- Tips
		optionsAddObject( -2, 3*14, "font#t:0:%y#s:0:%s#l:13:0#r#" .. L["CT_MapMod/Options/Tips/Line 1"] .. textColor2 .. ":l"); --You can use /ctmap, /ctmapmod, or /mapmod to open this options window directly.
		optionsAddObject( -5, 3*14, "font#t:0:%y#s:0:%s#l:13:0#r#" .. L["CT_MapMod/Options/Tips/Line 2"] .. textColor2 .. ":l"); --Add pins to the world map using the 'new note' button at the top corner of the map!
		
		
		--Add Features to World Map
		optionsAddObject(-20,   17, "font#tl:5:%y#v:GameFontNormalLarge#" .. L["CT_MapMod/Options/Add Features/Heading"]); -- Add Features to World Map
		
		optionsAddObject(-15,   14, "font#t:0:%y#s:0:%s#l:13:0#r#" .. L["CT_MapMod/Options/Add Features/Coordinates/ShowPlayerCoordsOnMapLabel"] .. textColor1 .. ":l"); -- Show player coordinates
		optionsBeginFrame(-10,   24, "dropdown#tl:5:%y#s:100:20#o:CT_MapMod_ShowPlayerCoordsOnMap:2#n:CT_MapMod_ShowPlayerCoordsOnMap#" .. L["CT_MapMod/Options/At Top"] .. "#" .. L["CT_MapMod/Options/At Bottom"] .. "#" .. L["CT_MapMod/Options/Disabled"]);
			optionsAddTooltip({L["CT_MapMod/Options/Add Features/Coordinates/ShowPlayerCoordsOnMapLabel"],L["CT_MapMod/Options/Add Features/Coordinates/Line 1"] .. textColor2});
		optionsEndFrame();
		optionsAddObject(-15,   14, "font#t:0:%y#s:0:%s#l:13:0#r#" .. L["CT_MapMod/Options/Add Features/Coordinates/ShowCursorCoordsOnMapLabel"] .. textColor1 .. ":l"); -- Show cursor coordinates
		optionsBeginFrame(-10,   24, "dropdown#tl:5:%y#s:100:20#o:CT_MapMod_ShowCursorCoordsOnMap:2#n:CT_MapMod_ShowCursorCoordsOnMap#" .. L["CT_MapMod/Options/At Top"] .. "#" .. L["CT_MapMod/Options/At Bottom"] .. "#" .. L["CT_MapMod/Options/Disabled"]);
			optionsAddTooltip({L["CT_MapMod/Options/Add Features/Coordinates/ShowCursorCoordsOnMapLabel"],L["CT_MapMod/Options/Add Features/Coordinates/Line 1"] .. textColor2});
		optionsEndFrame();
		
		optionsAddObject(-15,   14, "font#t:0:%y#s:0:%s#l:13:0#r#" .. L["CT_MapMod/Options/Add Features/WhereAmI/ShowMapResetButtonLabel"] .. textColor1 .. ":l"); -- Show 'Where am I' button
		optionsBeginFrame(-10,   24, "dropdown#tl:5:%y#s:100:20#o:CT_MapMod_ShowMapResetButton#n:CT_MapMod_ShowMapResetButton#" .. L["CT_MapMod/Options/Auto"] .. "#" .. L["CT_MapMod/Options/Always"] .. "#" .. L["CT_MapMod/Options/Disabled"]);
			optionsAddTooltip({L["CT_MapMod/Options/Add Features/WhereAmI/ShowMapResetButtonLabel"],L["CT_MapMod/Options/Add Features/WhereAmI/Line 1"] .. textColor2, L["CT_MapMod/Options/Auto"] .. " - " .. SPELL_FAILED_INCORRECT_AREA .. textColor2});
		optionsEndFrame();
		optionsBeginFrame(24,   24, "dropdown#tl:140:%y#s:100:20#o:CT_MapMod_MapResetButtonPlacement#n:CT_MapMod_MapResetButtonPlacement#" .. L["CT_MapMod/Options/At Bottom"] .. "#" .. L["CT_MapMod/Options/At Top"] .. "#" .. L["CT_MapMod/Options/At Top Left"]);
			optionsAddScript("onupdate",	
				function(self)
					if (module:getOption("CT_MapMod_ShowMapResetButton") == 3) then
						UIDropDownMenu_DisableDropDown(CT_MapMod_MapResetButtonPlacement);
					else
						UIDropDownMenu_EnableDropDown(CT_MapMod_MapResetButtonPlacement);
					end
				end
			);
			optionsAddTooltip({L["CT_MapMod/Options/Add Features/WhereAmI/ShowMapResetButtonLabel"],L["CT_MapMod/Options/Add Features/WhereAmI/Line 1"] .. textColor2});
		optionsEndFrame();
		
		--Create and Display Pins
		optionsAddObject(-20,  17, "font#tl:5:%y#v:GameFontNormalLarge#" .. L["CT_MapMod/Options/Pins/Heading"]); -- Create and Display Pins
		
		optionsAddObject(-15,  14, "font#t:0:%y#s:0:%s#l:13:0#r#" .. L["CT_MapMod/Options/Pins/User/UserNoteDisplayLabel"] .. textColor1 .. ":l"); -- Show custom user notes
		optionsBeginFrame(-10,  24, "dropdown#tl:5:%y#s:100:20#o:CT_MapMod_UserNoteDisplay#n:CT_MapMod_UserNoteDisplay#" .. L["CT_MapMod/Options/Always"] .. "#" .. L["CT_MapMod/Options/Disabled"]);
			optionsAddTooltip({L["CT_MapMod/Options/Pins/User/UserNoteDisplayLabel"],L["CT_MapMod/Options/Pins/User/Line 1"] .. textColor2});
		optionsEndFrame()
		optionsAddFrame(  24,  28, "slider#tl:160:%y#s:120:15#o:CT_MapMod_UserNoteSize:24#" .. L["CT_MapMod/Options/Pins/Icon Size"] .. " - <value>:" .. SMALL .. ":" .. LARGE .. "#10:26:0.5");
		
		optionsAddObject(-15,  14, "font#t:0:%y#s:0:%s#l:13:0#r#" .. L["CT_MapMod/Options/Pins/Gathering/HerbNoteDisplayLabel"] .. textColor1 .. ":l"); -- Show herb nodes
		optionsBeginFrame(-10,   24, "dropdown#tl:5:%y#s:100:20#o:CT_MapMod_HerbNoteDisplay#n:CT_MapMod_HerbNoteDisplay#" .. L["CT_MapMod/Options/Auto"] .. "#" .. L["CT_MapMod/Options/Always"] .. "#" .. L["CT_MapMod/Options/Disabled"]);
			optionsAddTooltip({L["CT_MapMod/Options/Pins/Gathering/HerbNoteDisplayLabel"],L["CT_MapMod/Options/Pins/Gathering/Line 1"] .. textColor2, L["CT_MapMod/Options/Auto"] .. " - " .. UNIT_SKINNABLE_HERB .. textColor2});
		optionsEndFrame()
		optionsAddFrame( 24,   28, "slider#tl:160:%y#s:120:15#o:CT_MapMod_HerbNoteSize:14#" .. L["CT_MapMod/Options/Pins/Icon Size"] .. " - <value>:" .. SMALL .. ":" .. LARGE .. "#10:26:0.5");
		
		optionsAddObject(-15,   14, "font#t:0:%y#s:0:%s#l:13:0#r#" .. L["CT_MapMod/Options/Pins/Gathering/OreNoteDisplayLabel"] .. textColor1 .. ":l"); -- Show mining nodes
		optionsBeginFrame(-5,   24, "dropdown#tl:5:%y#s:100:20#o:CT_MapMod_OreNoteDisplay#n:CT_MapMod_OreNoteDisplay#" .. L["CT_MapMod/Options/Auto"] .. "#" .. L["CT_MapMod/Options/Always"] .. "#" .. L["CT_MapMod/Options/Disabled"]);
			optionsAddTooltip({L["CT_MapMod/Options/Pins/Gathering/OreNoteDisplayLabel"],L["CT_MapMod/Options/Pins/Gathering/Line 1"] .. textColor2, L["CT_MapMod/Options/Auto"] .. " - " .. UNIT_SKINNABLE_ROCK .. textColor2});
		optionsEndFrame()
		optionsAddObject( 24,   28, "slider#tl:160:%y#s:120:15#o:CT_MapMod_OreNoteSize:14#" .. L["CT_MapMod/Options/Pins/Icon Size"] .. " - <value>:" .. SMALL .. ":" .. LARGE .. "#10:26:0.5");
		
		optionsBeginFrame(-15,  26, "checkbutton#tl:10:%y#o:CT_MapMod_IncludeRandomSpawns#" .. L["CT_MapMod/Options/Pins/IncludeRandomSpawnsCheckButton"]); -- Include randomly-spawning rare nodes
			optionsAddTooltip({L["CT_MapMod/Options/Pins/IncludeRandomSpawnsCheckButton"], L["CT_MapMod/Options/Pins/IncludeRandomSpawnsTip"] .. textColor2});
		optionsEndFrame();
		optionsBeginFrame(-5,  26, "checkbutton#tl:10:%y#o:CT_MapMod_OverwriteGathering#" .. L["CT_MapMod/Options/Pins/OverwriteGatheringCheckButton"]); -- Include randomly-spawning rare nodes
			optionsAddTooltip({L["CT_MapMod/Options/Pins/OverwriteGatheringCheckButton"], L["CT_MapMod/Options/Pins/OverwriteGatheringTip"] .. textColor2});
		optionsEndFrame();
		
		optionsAddObject(-15,   14, "font#t:0:%y#s:0:%s#l:13:0#r#" .. OBJECT_ALPHA .. textColor3 .. ":l");
		optionsBeginFrame(-20,   28, "slider#tl:24:%y#s:120:15#o:CT_MapMod_AlphaZoomedOut:0.85#Zoomed out - <value>:50%:100%#0.50:1.00:0.05");
			optionsAddTooltip({"Alpha while zoomed out fully", "Reduce pin alpha to see other map features." .. textColor2, "(Less alpha = less opaque)" .. textColor2});
		optionsEndFrame();
		optionsBeginFrame(28,   28, "slider#tl:160:%y#s:120:15#o:CT_MapMod_AlphaZoomedIn:1.00#Zoomed in - <value>:50%:100%#0.50:1.00:0.05");
			optionsAddTooltip({"Alpha while zoomed in fully", "Reduce pin alpha to see other map features." .. textColor2, "(Less alpha = less opaque)" .. textColor2});
		optionsEndFrame();
		
		-- Flight Masters
		if (FlightMap_LoadUI or TaxiFrame) then
			optionsAddObject(-20,  17, "font#tl:5:%y#v:GameFontNormalLarge#" .. FLIGHT_MAP);
			optionsBeginFrame( -15,  26, "checkbutton#tl:10:%y#o:CT_MapMod_ShowOnFlightMaps:true#" .. L["CT_MapMod/Options/FlightMaps/ShowOnFlightMapsCheckButton"] .. "#l:268");
				optionsAddTooltip({L["CT_MapMod/Options/FlightMaps/ShowOnFlightMapsCheckButton"], L["CT_MapMod/Options/FlightMaps/ShowOnFlightMapsTip"]});
			optionsEndFrame()
			optionsBeginFrame( -5,  26, "checkbutton#tl:10:%y#o:CT_MapMod_ShowUnreachableFlightPaths:true#" .. L["CT_MapMod/Options/FlightMaps/ShowUnreachableFlightPathsCheckButton"] .. "#l:268");
				optionsAddTooltip({L["CT_MapMod/Options/FlightMaps/ShowUnreachableFlightPathsCheckButton"], L["CT_MapMod/Options/FlightMaps/ShowUnreachableFlightPathsTip"]});
			optionsEndFrame()
		end
		
		-- Reset Options
		optionsAddFromTemplate(-20, 0, "frame#tl:0:%y#br:tr:0:%b#i:ResetFrame", "ResetTemplate")
		
	optionsEndFrame();

	return "frame#all", module:framesGetData(optionsFrameList);
end
