------------------------------------------------
--                CT_BuffMod                  --
--                                            --
-- Mod that allows you to heavily customize   --
-- the display of buffs to your liking.       --
-- Please do not modify or otherwise          --
-- redistribute this without the consent of   --
-- the CTMod Team. Thank you.                 --
--                                            --
-- Original credits to Cide and TS, c. 2005   --
-- Maintained by Resike, 2014-2017            --
-- Maintained by Dahk (DDCorkum), 2018-       --
------------------------------------------------


-- IMPORTANT NOTE:  Consolidation appears no longer to be part of the game,
--                  but the code has been left in the game just in case it returns.
--                  
--                  The options are commented-out and can be restored quickly in module:frame


---------------------------------------------
-- Initialization

local module = { };
local _G = getfenv(0);

local MODULE_NAME = "CT_BuffMod";
local MODULE_VERSION = strmatch(C_AddOns.GetAddOnMetadata(MODULE_NAME, "version"), "^([%d.]+)");

module.name = MODULE_NAME;
module.version = MODULE_VERSION;

_G[MODULE_NAME] = module;
CT_Library:registerModule(module);

module.text = module.text or { };		-- see localization.lua
local L = module.text;

-- In WoW Midnight, aura fields can be restricted in combat: numbers as "secret numbers" and some
-- strings (e.g. the aura name) as tainted/restricted values, which throw when compared or used by
-- insecure code. ctSafe returns the value when it is safe to use (comparable), else the default, so
-- aura sort/layout/comparisons degrade gracefully instead of erroring. Defined at chunk scope so every
-- function in the file can reach it. NOTE: tonumber() does NOT neutralize a secret number.
local ctSafe = CT_Library.safeValue;	-- shared secret-value sanitizer (see CT_Library.lua)
local DebuffTypeColor = CT_Library.DebuffTypeColor;	-- shared fallback (global is nil in Midnight)

--------------------------------------------
-- Variables & Constants

local constants = {};
module.constants = constants;

constants.AURATYPE_BUFF = 1;
constants.AURATYPE_DEBUFF = 2;
constants.AURATYPE_AURA = 3;
constants.AURATYPE_ENCHANT = 4;
constants.AURATYPE_CONSOLIDATED = 5;

local defaultBackgroundColors = {
	[constants.AURATYPE_BUFF] = { 0.1, 0.4, 0.85, 0.5 },
	[constants.AURATYPE_DEBUFF] = { 1, 0, 0, 0.85 },
	[constants.AURATYPE_AURA] = { 0.35, 0.8, 0.15, 0.5 },
	[constants.AURATYPE_ENCHANT] = { 0.75, 0.25, 1, 0.75 },
	[constants.AURATYPE_CONSOLIDATED] = { 0.97, 0.97, 0.95, 0.66 },
};

local backgroundColors = {};
for auraType, colorTable in pairs(defaultBackgroundColors) do
	backgroundColors[auraType] = colorTable;
end

local defaultClassColors = { r = 0.82, g = 1, b = 0 };

local defaultWindowColor = { 0, 0, 0, 0.25};
local defaultConsolidatedColor = { 0, 0, 0, 0.8};

constants.BUTTONMODE_SPELL = 1;
constants.BUTTONMODE_ENCHANT = 2;
constants.BUTTONMODE_CONSOLIDATED = 3;

constants.ENCHANT_SLOTS = {
	(INVSLOT_MAINHAND or 16),
	(INVSLOT_OFFHAND or 17),
-- rng	(INVSLOT_RANGED or 18),
};

constants.UNIT_TYPE_PLAYER = 1;
constants.UNIT_TYPE_VEHICLE = 2;
constants.UNIT_TYPE_PET = 3;
constants.UNIT_TYPE_TARGET = 4;
constants.UNIT_TYPE_FOCUS = 5;

constants.FILTER_TYPE_NONE = 1;
constants.FILTER_TYPE_DEBUFF = 2;  -- Debuffs
constants.FILTER_TYPE_BUFF_CANCELABLE = 3; -- Buffs
constants.FILTER_TYPE_BUFF_UNCANCELABLE = 4;  -- Auras
constants.FILTER_TYPE_BUFF_ALL = 5;  -- All buffs (cancelable and uncancelable, excluding weapons)
constants.FILTER_TYPE_WEAPON = 6;  -- Temporary weapon enchants
constants.FILTER_TYPE_CONSOLIDATED = 7; -- Consolidated buffs

constants.FILTER_TEXT_DEBUFF = "HARMFUL";
constants.FILTER_TEXT_BUFF_CANCELABLE = "HELPFUL|CANCELABLE";
constants.FILTER_TEXT_BUFF_UNCANCELABLE = "HELPFUL|NOT_CANCELABLE";
constants.FILTER_TEXT_BUFF_ALL = "HELPFUL";

constants.VISIBILITY_SHOW = 1
constants.VISIBILITY_BASIC = 2
constants.VISIBILITY_ADVANCED = 3

constants.GROUP_BY_FILTER_OWN_ZERO = 1; -- Group by the 1st to 5th aura types, then by separateOwn, then by separateZero.   This is closest to the default UI.
constants.GROUP_BY_FILTER_ZERO_OWN = 2;
constants.GROUP_BY_OWN_FILTER_ZERO = 3;
constants.GROUP_BY_OWN_ZERO_FILTER = 4;
constants.GROUP_BY_ZERO_FILTER_OWN = 5;
constants.GROUP_BY_ZERO_OWN_FILTER = 6;

constants.SEPARATE_ZERO_BEFORE = 1;
constants.SEPARATE_ZERO_AFTER = 2;
constants.SEPARATE_ZERO_WITH = 3;
constants.SEPARATE_ZERO_HIDDEN = 4;
constants.SEPARATE_ZERO_SHOWN_ONLY = 5;

constants.SEPARATE_ZERO = {1, -1, 0, 0, 0}
constants.FILTER_ZERO = {0, 0, 0, 1, -1}

constants.SEPARATE_OWN_BEFORE = 1;
constants.SEPARATE_OWN_AFTER = 2;
constants.SEPARATE_OWN_WITH = 3;

constants.SORT_METHOD_NAME = 1;
constants.SORT_METHOD_TIME = 2;
constants.SORT_METHOD_INDEX = 3;

constants.RIGHT_ALIGN_DEFAULT = 1;
constants.RIGHT_ALIGN_NO = 2;
constants.RIGHT_ALIGN_YES = 3;

constants.JUSTIFY_DEFAULT = 1;
constants.JUSTIFY_LEFT = 2;
constants.JUSTIFY_RIGHT = 3;
constants.JUSTIFY_CENTER = 4;

constants.DATA_SIDE_LEFT = 1;
constants.DATA_SIDE_RIGHT = 2;
constants.DATA_SIDE_TOP = 3;
constants.DATA_SIDE_BOTTOM = 4;
constants.DATA_SIDE_CENTER = 5;

constants.DURATION_LOCATION_DEFAULT = 1;
constants.DURATION_LOCATION_LEFT = 2;
constants.DURATION_LOCATION_RIGHT = 3;
constants.DURATION_LOCATION_ABOVE = 4;
constants.DURATION_LOCATION_BELOW = 5;

constants.LAYOUT_GROW_DOWN_WRAP_RIGHT = 1;
constants.LAYOUT_GROW_DOWN_WRAP_LEFT = 2;
constants.LAYOUT_GROW_UP_WRAP_RIGHT = 3;
constants.LAYOUT_GROW_UP_WRAP_LEFT = 4;
constants.LAYOUT_GROW_RIGHT_WRAP_DOWN = 5;
constants.LAYOUT_GROW_RIGHT_WRAP_UP = 6;
constants.LAYOUT_GROW_LEFT_WRAP_DOWN = 7;
constants.LAYOUT_GROW_LEFT_WRAP_UP = 8;

constants.BUFF_SIZE_MINIMUM = 15;
constants.BUFF_SIZE_MAXIMUM = 45;
constants.BUFF_SIZE_DEFAULT = 20;

constants.DEFAULT_LAYOUT = constants.LAYOUT_GROW_RIGHT_WRAP_DOWN;
constants.DEFAULT_MAX_WRAPS = 0;
constants.DEFAULT_WRAP_AFTER = 1;
constants.DEFAULT_FLASH_TIME = 15;
constants.DEFAULT_DETAIL_WIDTH = 245;
constants.DEFAULT_CONSOLIDATE_HIDE_TIMER = 0.50;

local inVehicle = false;
local needEnchantRescan;
local normalEnchantRescan = 2;
local sortSeqChanged;

local globalFrame;
local globalObject;
--local frame_Show; -- it doesn't appear this is ever used
local frame_Hide;

--------------------------------------------
-- Start of unsecure aura header routines.
--
-- This is a modified version of the code found
-- in Blizzard's SecureGroupHeaders.lua file.
--------------------------------------------
-- BeginMod
-- EndMod
-- Bugfix
-- EndBugfix

do

local function getFrameHandle(frame)
	return frame;
end

local function setAttributesWithoutResponse(self, ...)
	local oldIgnore = self:GetAttribute("_ignore");
	self:SetAttribute("_ignore", "attributeChanges");
	for i = 1, select('#', ...), 2 do
		self:SetAttribute(select(i, ...));
	end
	self:SetAttribute("_ignore", oldIgnore);
end

-- Working tables
local tokenTable = {};
local sortingTable = {};
local groupingTable = {};
local tempTable = {};

function CT_BuffMod_UnsecureButton_GetUnit(self)
	return self:GetAttribute("unit");
end

local function SetupAuraButtonConfiguration( header, newChild, defaultConfigFunction )
--[[
	local configCode = newChild:GetAttribute("initialConfigFunction") or header:GetAttribute("initialConfigFunction") or defaultConfigFunction;

	if ( type(configCode) == "string" ) then
		local selfHandle = GetFrameHandle(newChild);
		if ( selfHandle ) then
			CallRestrictedClosure("self", GetManagedEnvironment(header, true),
			                      selfHandle, configCode, selfHandle);
		end
	end
--]]
end

function CT_BuffMod_UnsecureAuraHeader_OnLoad(self)
	self:RegisterEvent("UNIT_AURA");
end

function CT_BuffMod_UnsecureAuraHeader_OnUpdate(self)
	local hasMainHandEnchant, hasOffHandEnchant;
	if GetWeaponEnchantInfo then
		hasMainHandEnchant, _, _, _, hasOffHandEnchant = GetWeaponEnchantInfo();
	else
		hasMainHandEnchant, hasOffHandEnchant = false, false;
	end
	if ( hasMainHandEnchant ~= self:GetAttribute("_mainEnchanted") ) then
		self:SetAttribute("_mainEnchanted", hasMainHandEnchant);
	end
	if ( hasOffHandEnchant ~= self:GetAttribute("_secondaryEnchanted") ) then
		self:SetAttribute("_secondaryEnchanted", hasOffHandEnchant);
	end
-- rng	-- Bugfix
-- rng	if ( hasRangedEnchant ~= self:GetAttribute("_rangedEnchanted") ) then
-- rng		self:SetAttribute("_rangedEnchanted", hasRangedEnchant);
-- rng	end
-- rng	-- EndBugfix
end

function CT_BuffMod_UnsecureAuraHeader_OnEvent(self, event, ...)
	if ( self:IsVisible() ) then
		local unit = CT_BuffMod_UnsecureButton_GetUnit(self);
		if ( event == "UNIT_AURA" and ... == unit ) then
			CT_BuffMod_UnsecureAuraHeader_Update(self);
		end
	end
end

function CT_BuffMod_UnsecureAuraHeader_OnAttributeChanged(self, name, value)
	if ( name == "_ignore" or self:GetAttribute("_ignore") ) then
		return;
	end
	if ( self:IsVisible() ) then
		CT_BuffMod_UnsecureAuraHeader_Update(self);
	end
end

local buttons = {};

local function extractTemplateInfo(template, defaultWidget)
	local widgetType;

	if ( template ) then
		template, widgetType = strsplit(",", (tostring(template):trim():gsub("%s*,%s*", ",")) );
		if ( template ~= "" ) then
			if ( not widgetType or widgetType == "" ) then
				widgetType = defaultWidget;
			end
			return template, widgetType;
		end
	end
	return nil;
end

local function constructChild(kind, name, parent, template)
	local new = CreateFrame(kind, name, parent, template);
	if new.SetIsUnrestricted then new:SetIsUnrestricted(true) end	
	SetupAuraButtonConfiguration(parent, new);
	return new;
end

local enchantableSlots = {
	[1] = "MainHandSlot",
	[2] = "SecondaryHandSlot",
-- rng	[3] = "RangedSlot",
}

local function configureAuras(self, auraTable, consolidateTable, weaponPosition)
	local point = self:GetAttribute("point") or "TOPRIGHT";
	local xOffset = tonumber(self:GetAttribute("xOffset")) or 0;
	local yOffset = tonumber(self:GetAttribute("yOffset")) or 0;
	local wrapXOffset = tonumber(self:GetAttribute("wrapXOffset")) or 0;
	local wrapYOffset = tonumber(self:GetAttribute("wrapYOffset")) or 0;
	local wrapAfter = tonumber(self:GetAttribute("wrapAfter"));
	if ( wrapAfter == 0 ) then wrapAfter = nil; end
	local maxWraps = self:GetAttribute("maxWraps");
	if ( maxWraps == 0 ) then maxWraps = nil; end
	local minWidth = tonumber(self:GetAttribute("minWidth")) or 0;
	local minHeight = tonumber(self:GetAttribute("minHeight")) or 0;

	-- Begin Mod
	local filterZero = tonumber(self:GetAttribute("filterZero")) or 0;
	-- End Mod

	if ( consolidateTable and #consolidateTable == 0 ) then
		consolidateTable = nil;
	end
	local name = self:GetName();

	wipe(buttons);
	local buffTemplate, buffWidget = extractTemplateInfo(self:GetAttribute("template"), "Button");
	-- Begin Mod
	local count = 0;
	-- End Mod
	if ( buffTemplate ) then
		for i=1, #auraTable do
			-- Begin Mod
			if (
				filterZero == 0 
				or filterZero == 1 and auraTable[i].duration > 0 
				or filterZero == -1 and auraTable[i].duration == 0
			) then
				count = count + 1
				local childAttr = "child"..count;
				local button = self:GetAttribute(childAttr);
				if ( button ) then
					button:ClearAllPoints();
				else
					button = constructChild(buffWidget, name and name.."AuraButton"..i, self, buffTemplate);
					setAttributesWithoutResponse(self, childAttr, button, "frameref-"..childAttr, GetFrameHandle(button));
				end
				local buffInfo = auraTable[i];
				button:SetID(buffInfo.index);
				button:SetAttribute("index", buffInfo.index);
				button:SetAttribute("filter", buffInfo.filter);
				buttons[count] = button;
			end
			-- End Mod
		end
	end
	-- Bugfix
	local deadIndex = #buttons + 1;
	local button = self:GetAttribute("child"..deadIndex);
	while ( button ) do
		button:Hide();
		deadIndex = deadIndex + 1;
		button = self:GetAttribute("child"..deadIndex)
	end
	-- EndBugfix

	local consolidateProxy = self:GetAttribute("consolidateProxy");
	if ( consolidateTable ) then
		if ( type(consolidateProxy) == 'string' ) then
			local template, widgetType = extractTemplateInfo(consolidateProxy, "Button");
			if ( template ) then
				consolidateProxy = constructChild(widgetType, name and name.."ProxyButton", self, template);
				setAttributesWithoutResponse(self, "consolidateProxy", consolidateProxy, "frameref-proxy", GetFrameHandle(consolidateProxy));
			else
				consolidateProxy = nil;
			end
		end
		if ( consolidateProxy ) then
			if ( consolidateTable.position ) then
				tinsert(buttons, consolidateTable.position, consolidateProxy);
			else
				tinsert(buttons, consolidateProxy);
			end
			consolidateProxy:ClearAllPoints();
		end
	else
		if ( consolidateProxy and type(consolidateProxy.Hide) == 'function' ) then
			consolidateProxy:Hide();
		end
	end
	if ( weaponPosition ) then
		local hasMainHandEnchant, hasOffHandEnchant, _;
-- rng		local hasMainHandEnchant, hasOffHandEnchant, hasRangedEnchant, _;
		hasMainHandEnchant, _, _, _, hasOffHandEnchant = GetWeaponEnchantInfo();
-- rng		hasMainHandEnchant, _, _, hasOffHandEnchant, _, _, hasRangedEnchant, _, _ = GetWeaponEnchantInfo();

		for weapon=2,1,-1 do
-- rng		for weapon=3,1,-1 do
			local weaponAttr = "tempEnchant"..weapon
			local tempEnchant = self:GetAttribute(weaponAttr)
			if ( (select(weapon, hasMainHandEnchant, hasOffHandEnchant)) ) then
-- rng			if ( (select(weapon, hasMainHandEnchant, hasOffHandEnchant, hasRangedEnchant)) ) then
				if ( not tempEnchant ) then
					local template, widgetType = extractTemplateInfo(self:GetAttribute("weaponTemplate"), "Button");
					if ( template ) then
						tempEnchant = constructChild(widgetType, name and name.."TempEnchant"..weapon, self, template);
						setAttributesWithoutResponse(self, weaponAttr, tempEnchant);
					end
				end
				if ( tempEnchant ) then
					tempEnchant:ClearAllPoints();
					local slot = GetInventorySlotInfo(enchantableSlots[weapon]);
					tempEnchant:SetAttribute("target-slot", slot);
					tempEnchant:SetID(slot);
					if ( weaponPosition == 0 ) then
						tinsert(buttons, tempEnchant);
					else
						tinsert(buttons, weaponPosition, tempEnchant);
					end
				end
			else
				if ( tempEnchant and type(tempEnchant.Hide) == 'function' ) then
					tempEnchant:Hide();
				end
			end
		end
	end

	local display = #buttons
	if ( wrapAfter and maxWraps ) then
		display = min(display, wrapAfter * maxWraps);
	end

	local left, right, top, bottom = math.huge, -math.huge, -math.huge, math.huge;
	for index = 1,display do
		local button = buttons[index];
		local wrapAfter = wrapAfter or index
		local tick, cycle = floor((index - 1) % wrapAfter), floor((index - 1) / wrapAfter);
		button:SetPoint(point, self, cycle * wrapXOffset + tick * xOffset, cycle * wrapYOffset + tick * yOffset);
		button:Show();
		left = min(left, button:GetLeft() or math.huge);
		right = max(right, button:GetRight() or -math.huge);
		top = max(top, button:GetTop() or -math.huge);
		bottom = min(bottom, button:GetBottom() or math.huge);
	end
	-- Bugfix
	for hideIndex = display + 1, #buttons do
		buttons[hideIndex]:Hide();
	end
--[[
	local deadIndex = display + 1;
	local button = self:GetAttribute("child"..deadIndex);
	while ( button ) do
		button:Hide();
		deadIndex = deadIndex + 1;
		button = self:GetAttribute("child"..deadIndex)
	end
--]]
	-- EndBugfix

	if ( display >= 1 ) then
		self:SetWidth(max(right - left, minWidth));
		self:SetHeight(max(top - bottom, minHeight));
	else
		self:SetWidth(minWidth);
		self:SetHeight(minHeight);
	end
	if ( consolidateTable ) then
		local header = self:GetAttribute("consolidateHeader");
		if ( type(header) == 'string' ) then
			local template, widgetType = extractTemplateInfo(header, "Frame");
			if ( template ) then
				header = constructChild(widgetType, name and name.."ProxyHeader", consolidateProxy, template);
				setAttributesWithoutResponse(self, "consolidateHeader", header);
				consolidateProxy:SetAttribute("header", header);
				consolidateProxy:SetAttribute("frameref-header", GetFrameHandle(header))
			end
		end
		if ( header ) then
			configureAuras(header, consolidateTable);
		end
	end

end

local tremove = table.remove;

local function stripRAID(filter)
	return filter and tostring(filter):upper():gsub("RAID", ""):gsub("|+", "|"):match("^|?(.+[^|])|?$");
end

local sorterBuilders =
{
	["filter"] = function()
		return function(a, b)
			if (groupingTable[a.filter] ~= groupingTable[b.filter]) then
				return groupingTable[a.filter] < groupingTable[b.filter]
			end
		end
	end,
	["separateOwn"] = function(separateOwn)
		if (separateOwn > 0) then
			return function(a, b)
				local ownA, ownB = a.caster == "player", b.caster == "player";
				if (ownA ~= ownB) then
					return ownA;
				end
			end
		elseif (separateOwn < 0) then
			return function(a, b)
				local ownA, ownB = a.caster == "player", b.caster == "player";
				if (ownA ~= ownB) then
					return not ownA;
				end
			end
		else
			return function()
				return nil;
			end
		end
	end,
	["separateZero"] = function(separateZero)
		if (separateZero > 0) then
			return function(a, b)
				local zeroA, zeroB = a.duration == 0, b.duration == 0;
				if (zeroA ~= zeroB) then
					return zeroA;
				end
			end
		elseif (separateZero < 0) then
			return function(a, b)
				local zeroA, zeroB = a.duration == 0, b.duration == 0;
				if (zeroA ~= zeroB) then
					return not zeroA;
				end
			end
		else
			return function()
				return nil;
			end
		end
	end,
	["index"] = function(reverse)
		if (reverse) then
			return function(a, b)
				if (a.index ~= b.index) then
					return a.index > b.index;
				end
			end
		else
			return function(a, b)
				if (a.index ~= b.index) then
					return a.index < b.index;
				end
			end
		end
	end,
	["name"] = function(reverse)
		if (reverse) then
			return function(a, b)
				if (a.name ~= b.name) then
					return a.name > b.name;
				end
			end
		else
			return function(a, b)
				if (a.name ~= b.name) then
					return a.name < b.name;
				end
			end
		end
	end,
	["expires"] = function(reverse)
		if (reverse) then
			return function(a, b)
				if (a.expires ~= b.expires) then
					return a.expires > b.expires;
				end
			end
		else
			return function(a, b)
				if (a.expires ~= b.expires) then
					return a.expires < b.expires;
				end
			end
		end
	end,
}

-- groupByPriority
-- 1. Filter > Own > Zero
-- 2. Filter > Zero > Own
-- 3. Own > Filter > Zero
-- 4. Own > Zero > Filter
-- 5. Zero > Groups > Own
-- 6. Zero > Own > Filter

-- BeginMod
--local function sortFactory(key, separateOwn, reverse)
local function sortFactory(key, separateOwn, reverse, separateZero, priority)
	local fragments =
	{
		-- GROUPING
		[1] = priority < 3 and sorterBuilders["filter"]() or priority < 5 and sorterBuilders["separateOwn"](separateOwn) or sorterBuilders["separateZero"](separateZero),
		[2] = priority % 5 == 1 and sorterBuilders["separateOwn"](separateOwn) or priority % 2 == 0 and sorterBuilders["separateZero"](separateZero) or sorterBuilders["filter"](),
		[3] = priority % 3 == 2 and sorterBuilders["separateOwn"](separateOwn) or priority % 2 == 1 and sorterBuilders["separateZero"](separateZero) or sorterBuilders["filter"](),
		
		-- SORTING
		[4] = sorterBuilders[key](reverse),
		[5] = key ~= "name" and sorterBuilders["name"](reverse) or sorterBuilders["expires"](reverse),	-- first fallback
		[6] = key ~= "index" and sorterBuilders["index"](reverse) or sorterBuilders["expires"](reverse),	-- second fallback
	}
	return function(a, b)
		if (a and b) then
			for i=1, 6 do
				local val = fragments[i](a, b);
				if (val ~= nil) then
					return val;
				end
			end
		end
		return true;
	end;
end
-- EndMod

local sorters = {};
for __, key in ipairs{"index", "name", "expires"} do
	local label = key:upper();
	sorters[label] = {};
	for bool in pairs{[true] = true, [false] = false} do
		sorters[label][bool] = {};
		for sep = -1, 1 do
			-- BeginMod
			--sorters[label][bool][sep] = sortFactory(key, sep, bool);
			sorters[label][bool][sep] = {};
			for zero = -1, 1 do
				sorters[label][bool][sep][zero] = {};
				for priority = 1, 6 do
					sorters[label][bool][sep][zero][priority] = sortFactory(key, sep, bool, zero, priority); -- the flip between sep and bool are intentional to mirror Blizzard
				end
			end
			-- EndMod
		end
	end
end
sorters.TIME = sorters.EXPIRES;

-- (ctSafe is defined near the top of the file, at chunk scope, so it is reachable here and elsewhere.)

function CT_BuffMod_UnsecureAuraHeader_Update(self)
	local filter = self:GetAttribute("filter");
	local groupBy = self:GetAttribute("groupBy");
	local unit = CT_BuffMod_UnsecureButton_GetUnit(self) or "player";
	local includeWeapons = tonumber(self:GetAttribute("includeWeapons"));
	if ( includeWeapons == 0 ) then
		includeWeapons = nil
	end
	local consolidateTo = tonumber(self:GetAttribute("consolidateTo"));
	local consolidateDuration, consolidateThreshold, consolidateFraction;
	if ( consolidateTo ) then
		consolidateDuration = tonumber(self:GetAttribute("consolidateDuration")) or 30;
		consolidateThreshold = tonumber(self:GetAttribute("consolidateThreshold")) or 10;
		consolidateFraction = tonumber(self:GetAttribute("consolidateFraction")) or 0.1;
	end
	local sortDirection = self:GetAttribute("sortDirection");
	local separateOwn = tonumber(self:GetAttribute("separateOwn")) or 0;
	if ( separateOwn > 0 ) then
		separateOwn = 1;
	elseif (separateOwn < 0 ) then
		separateOwn = -1;
	end
	-- BeginMod
	local separateZero = tonumber(self:GetAttribute("separateZero")) or 0;
	if ( separateZero > 0 ) then
		separateZero = 1;
	elseif (separateZero < 0 ) then
		separateZero = -1;
	end
	local groupByPriority = tonumber(self:GetAttribute("groupByPriority")) or constants.GROUP_BY_FILTER_OWN_ZERO;
	-- EndMod

 	local sortMethod = (sorters[tostring(self:GetAttribute("sortMethod")):upper()] or sorters["INDEX"])[sortDirection == "-"][separateOwn][separateZero][groupByPriority];

	local time = GetTime();

	local consolidateTable;
	if ( consolidateTo and consolidateTo ~= 0 ) then
		consolidateTable = wipe(tokenTable);
	end

	wipe(sortingTable);
	wipe(groupingTable);

	if ( groupBy ) then
		local i = 1;
		for subFilter in groupBy:gmatch("[^,]+") do
			if ( filter ) then
				subFilter = stripRAID(filter.."|"..subFilter);
			else
				subFilter = stripRAID(subFilter);
			end
			groupingTable[subFilter], groupingTable[i] = i, subFilter;
			i = i + 1;
		end
	else
		filter = stripRAID(filter);
		groupingTable[filter], groupingTable[1] = 1, filter;
	end
	if ( consolidateTable and consolidateTo < 0 ) then
		consolidateTo = #groupingTable + consolidateTo + 1;
	end
	if ( includeWeapons and includeWeapons < 0 ) then
		includeWeapons = #groupingTable + includeWeapons + 1;
	end
	local weaponPosition;
	for filterIndex, fullFilter in ipairs(groupingTable) do
		if ( consolidateTable and not consolidateTable.position and filterIndex >= consolidateTo ) then
			consolidateTable.position = #sortingTable + 1;
		end
		if ( includeWeapons and not weaponPosition and filterIndex >= includeWeapons ) then
			weaponPosition = #sortingTable + 1;
		end

		local i = 1;
		local aura = C_UnitAuras.GetAuraDataByIndex(unit, i, fullFilter)
		while aura do
			aura.filter = fullFilter;
			aura.index = i;
			-- Sanitize fields the sort/layout compares; in combat these can be restricted (secret/tainted).
			aura.name = ctSafe(aura.name, "");
			aura.duration = ctSafe(aura.duration, 0);
			aura.expirationTime = ctSafe(aura.expirationTime, 0);
			local targetList = sortingTable;
			tinsert(targetList, aura);
			i = i + 1;
			aura = C_UnitAuras.GetAuraDataByIndex(unit, i, fullFilter)
		end
	end
	if ( includeWeapons and not weaponPosition ) then
		weaponPosition = 0;
	end
	table.sort(sortingTable, sortMethod);
	if ( consolidateTable ) then
		table.sort(consolidateTable, sortMethod);
	end

	configureAuras(self, sortingTable, consolidateTable, weaponPosition);
end

end
--------------------------------------------
-- End of unsecure aura header routines
--------------------------------------------


--------------------------------------------
-- Miscellaneous

local function ctprint(...)
	print(...);
end

local function isControlPanelShown()
	-- Returns true if the CTMod control panel is showing.
	return module:IsControlPanelShown()
end

local function isOptionsFrameShown()
	-- Returns true if the CT_BuffMod options window is showing.
	return module:isModuleOptionTabSelected()
end

local function buildCondition(text)
	-- Convert the user specified text from the multiline editbox
	-- into a single line condition.

	-- Replace line terminators with semicolons.
	-- User should only press enter after typing actions.
	local cond = gsub(text, "\n", ";");

	-- Replace pairs of semicolons with single semicolons.
	-- User might have typed a semicolon after an action, and then pressed enter.
	while (strfind(cond, ";;")) do
		cond = gsub(cond, ";;", ";");
	end

	-- If the final character is a semicolon, then eliminate it.
	if (strsub(cond, #cond, #cond) == ";") then
		cond = strsub(cond, 1, #cond - 1);
	end

	-- Replace the old bonusbar:5 (WoW 4) with the new possessbar (WoW 5).
	-- This doesn't handle the large bonus bars that bonusbar:5 also used to detect.
	cond = gsub(cond, "%[bonusbar:5%]", "[possessbar]");

	return cond;
end

local function getAuraUpdateInterval(duration)
	-- Sanitize the value immediately into a plain Lua number to clear "secret number" blocks
	local cleanDuration = tonumber(duration) or 0;
	local updateInterval = 1;

	-- Run the logic in a pcall to ensure no "secret values" errors can crash the UI
	pcall(function()
		if ( cleanDuration <= 0) then
			updateInterval = 1;
		elseif (cleanDuration <= 60) then
			updateInterval = 0.05;
		elseif (cleanDuration <= 240) then
			updateInterval = 0.10;
		elseif (cleanDuration <= 540) then
			updateInterval = 0.50;
		else
			updateInterval = 1;
		end
	end);

	return updateInterval;
end

local function justifyH(fs, justify, default)
	if (justify == constants.JUSTIFY_CENTER) then
		fs:SetJustifyH("CENTER");
		return true;
	else
		if (justify == constants.JUSTIFY_DEFAULT) then
			fs:SetJustifyH(default);
		elseif (justify == constants.JUSTIFY_LEFT) then
			fs:SetJustifyH("LEFT");
		else
			fs:SetJustifyH("RIGHT");
		end
	end
	return false;
end

-- Time format 1 (unabbreviated):	 4 days / 1 hour / 35 minutes / 59 seconds		-- default; plural and singular localizations
-- Time format 2 (shortenned):		 4 day  / 1 hour / 35 min     / 59 sec			-- no attempt to pluralize
-- Time format 3 (abbreviated): 	 4d     / 1h     / 35m        / 59s			-- only one or two characters
-- Time format 4 (abbrevated two vals):  4d 16h / 1h 35m / 35m 30s    / 59s			-- may be grouped into days
-- Time format 5 (two vals, separator): 112:15h / 1:35h  / 1:35       / 0:35			-- days can be shown with a comma

local function timeFormat1(timeValue, showDays)
	-- Time format 1 (unabbreviated):	 4 days / 1 hour / 35 minutes / 59 seconds		-- default; plural and singular localizations
	timeValue = ceil(timeValue);
	if ( timeValue > 86340 and showDays) then
		-- Days
		local days = ceil(timeValue / 86400);
		if ( days ~= 1 ) then
			return format(L["CT_BuffMod/TimeFormat/Days Plural"], days);
		else
			return L["CT_BuffMod/TimeFormat/Day Singular"];
		end
	elseif ( timeValue > 3540 ) then
		-- Hours
		local hours = ceil(timeValue / 3600);
		if ( hours ~= 1 ) then
			return format(L["CT_BuffMod/TimeFormat/Hours Plural"], hours);
		else
			return L["CT_BuffMod/TimeFormat/Hour Singular"];
		end
	elseif ( timeValue > 60 ) then
		-- Minutes
		local minutes = ceil(timeValue / 60);
		if ( minutes ~= 1 ) then
			return format(L["CT_BuffMod/TimeFormat/Minutes Plural"], minutes);
		else
			return L["CT_BuffMod/TimeFormat/Minute Singular"];
		end
	else
		-- Seconds
		if ( timeValue ~= 1 ) then
			return format(L["CT_BuffMod/TimeFormat/Seconds Plural"], timeValue);
		else
			return L["CT_BuffMod/TimeFormat/Second Singular"];
		end
	end
end

local function timeFormat2(timeValue, showDays)
	-- Time format 2 (shortenned):		 4 day  / 1 hour / 35 min     / 59 sec			-- no attempt to pluralize
	timeValue = ceil(timeValue);
	if ( timeValue > 86340 and showDays) then
		-- Days
		return format(L["CT_BuffMod/TimeFormat/Days Smaller"], ceil(timeValue / 86400));
	elseif ( timeValue > 3540 ) then
		-- Hours
		return format(L["CT_BuffMod/TimeFormat/Hours Smaller"], ceil(timeValue / 3600));
	elseif ( timeValue > 60 ) then
		-- Minutes
		return format(L["CT_BuffMod/TimeFormat/Minutes Smaller"], ceil(timeValue / 60));
	else
		-- Seconds
		return format(L["CT_BuffMod/TimeFormat/Seconds Smaller"], timeValue);
	end
end

local function timeFormat3(timeValue, showDays)
	-- Time format 3 (abbreviated): 	 4d     / 1h     / 35m        / 59s			-- only one or two characters
	timeValue = ceil(timeValue);
	if ( timeValue > 86340 and showDays) then
		-- Days
		return format(L["CT_BuffMod/TimeFormat/Days Abbreviated"], ceil(timeValue / 86400));
	elseif ( timeValue > 3540 ) then
		-- Hours
		return format(L["CT_BuffMod/TimeFormat/Hours Abbreviated"], ceil(timeValue / 3600));
	elseif ( timeValue > 60 ) then
		-- Minutes
		return format(L["CT_BuffMod/TimeFormat/Minutes Abbreviated"], ceil(timeValue / 60));
	else
		-- Seconds
		return format(L["CT_BuffMod/TimeFormat/Seconds Abbreviated"], timeValue);
	end
end

local function timeFormat4(timeValue, showDays)
	-- Time format 4 (abbrevated two vals):  4d 16h / 1h 35m / 35m 30s    / 59s			-- may be grouped into days
	timeValue = ceil(timeValue);
	if ( timeValue > 86400 and showDays) then
		-- Days & Hours
		local days = floor(timeValue / 86400);
		return format(L["CT_BuffMod/TimeFormat/Days Abbreviated"] .. " " ..  L["CT_BuffMod/TimeFormat/Hours Abbreviated"], days, floor((timeValue - days * 86400) / 3600 ));
	elseif ( timeValue >= 3600 ) then
		-- Hours & Minutes
		local hours = floor(timeValue / 3600);
		return format(L["CT_BuffMod/TimeFormat/Hours Abbreviated"] .. " " ..  L["CT_BuffMod/TimeFormat/Minutes Two Digits"], hours, floor((timeValue - hours * 3600) / 60));
	elseif ( timeValue > 60 ) then
		-- Minutes & Seconds
		return format(L["CT_BuffMod/TimeFormat/Minutes Abbreviated"] .. " " ..  L["CT_BuffMod/TimeFormat/Seconds Two Digits"], floor(timeValue / 60), timeValue % 60);
	else
		-- Seconds
		return format(L["CT_BuffMod/TimeFormat/Seconds Abbreviated"], timeValue);
	end
end

local function timeFormat5(timeValue, showDays)
	-- Time format 5 (two vals, separator): 112:15h / 1:35h  / 1:35       / 0:35			-- days can be shown with a comma
	timeValue = ceil(timeValue);
	if ( timeValue > 86400 and showDays) then
		-- Days & Hours
		local days = floor(timeValue / 86400);
		return format(L["CT_BuffMod/TimeFormat/Days Digital"], days, floor((timeValue % 86400) / 3600 ), floor((timeValue % 3600) / 60 ));
	elseif ( timeValue >= 3600 ) then
		-- Hours & Minutes
		local hours = floor(timeValue / 3600);
		return format(L["CT_BuffMod/TimeFormat/Hours Digital"], hours, floor((timeValue - hours * 3600) / 60));
	else
		-- Minutes & Seconds
		return format(L["CT_BuffMod/TimeFormat/Minutes Digital"], floor(timeValue / 60), timeValue % 60);
	end
end

local function humanizeTime(...)
	-- Used when displaying expiration warning time slider values in options window
	return timeFormat4(...);
end

-- Buff background colors
local function updateBackgroundColor(auraType, colorTable)
	if (colorTable) then
		backgroundColors[auraType] = colorTable;
	end
end

local function getDefaultBackgroundColor(auraType)
	return defaultBackgroundColors[auraType];
end

local function getBackgroundColor(auraType)
	return backgroundColors[auraType];
end

--------------------------------------------
-- Recasting buffs

local buffQueue;
local buffButton;

buffButton = CreateFrame("Button", "CT_BUFFMOD_RECASTBUFFFRAME", nil, "SecureActionButtonTemplate");
buffButton:SetAttribute("unit", "player");
buffButton:SetAttribute("type", "spell");

buffButton:SetScript("PreClick", function(self)
	if ( buffQueue and not self:GetAttribute("spell") ) then
		if (not InCombatLockdown()) then
			self:SetAttribute("spell", buffQueue[#buffQueue]);
		end
	end
end);

buffButton:SetScript("PostClick", function(self)
	local spell = self:GetAttribute("spell");
	if (not InCombatLockdown()) then
		self:SetAttribute("spell", nil);
		if ( buffQueue and spell ) then
			for i = #buffQueue, 1, -1 do
				if ( buffQueue[i] == spell ) then
					tremove(buffQueue, i);
					return;
				end
			end
		end
	end
end);

local function setRecastSpell(spellName)
	if (not InCombatLockdown()) then
		buffButton:SetAttribute("spell", spellName);
		return true;
	end
	return false;
end

local function queueBuffRecast(buffName)
	if ( not buffQueue ) then
		buffQueue = { };
	end

	-- Make sure it's not in here already
	for __, value in ipairs(buffQueue) do
		if ( value == buffName ) then
			return;
		end
	end

	tinsert(buffQueue, buffName);
	return true;
end

local function removeBuffRecast(buffName)
	if ( buffQueue ) then
		for key, value in ipairs(buffQueue) do
			if ( value == buffName ) then
				tremove(buffQueue, key);
				return;
			end
		end
	end
end

local function updateKeyBind()
	if (InCombatLockdown()) then
		return;
	end
	if ( globalFrame ) then
		local bindKey = GetBindingKey("CT_BUFFMOD_RECASTBUFFS");
		if ( bindKey ) then
			SetOverrideBindingClick(globalFrame, false, bindKey, "CT_BUFFMOD_RECASTBUFFFRAME");
		else
			ClearOverrideBindings(globalFrame);
		end
	end
end

module:regEvent("UPDATE_BINDINGS", updateKeyBind);
module:regEvent("PLAYER_ENTERING_WORLD", updateKeyBind);

--------------------------------------------
-- Routines to autohide an unsecure frame
-- that was shown by moving over a button.

local autoHideData = {};
local autoHideUpdateFrame;

local function autoHide_finish(frame)
	-- Hide the frame and clear the autohide.
	local data = autoHideData[frame];
	data.frame:Hide();
	autoHideData[frame] = nil;
	-- When we're out of frames to deal with...
	if (not next(autoHideData)) then
		-- Hide the update frame.
		autoHideUpdateFrame:Hide();
	end
end

local function autoHide_OnUpdate(self, elapsed)
	for frame, data in pairs(autoHideData) do
		-- If the button or frame gets hidden...
		if (not data.button:IsShown() or not data.frame:IsShown()) then
			-- Hide the frame and clear the autohide.
			autoHide_finish(frame);

		-- If the mouse is over the button or the frame...
		elseif (data.button:IsMouseOver() or data.frame:IsMouseOver()) then
			-- Clear the timer.
			data.timer = nil;

		else
			-- Mouse is not over the button or the frame.
			if (not data.timer) then
				-- Start the timer.
				data.timer = data.delay;
			else
				-- Continue counting down
				data.timer = data.timer - elapsed;

				-- When we reach the end...
				if (data.timer < 0) then
					-- Hide the frame and clear the autohide.
					autoHide_finish(frame);
				end
			end
		end
	end
end

autoHideUpdateFrame = CreateFrame("Frame");
autoHideUpdateFrame:SetScript("OnUpdate", autoHide_OnUpdate);
autoHideUpdateFrame:Hide();

local function autoHide_set(frame, button, seconds)
	autoHideData[frame] = { frame = frame, button = button, delay = seconds };
	autoHideUpdateFrame:Show();
end

--------------------------------------------
-- Aura class
--
-- Inherits fron:
--
-- 	None
--
-- Class object overview:
--
--	(auraClassObject)
--		.meta
--
-- Object overview:
--
--	(auraObject)
--		.classObject
--		+other properties
--
-- Properties:
--
--	.classObject
--	.meta
--	.super
--
--	.auraType
--	.casterName
--	.casterUnit
--	.count
--	.debuffType
--	.duration
--	.expirationTime
--	.isFlashing
--	.canStealOrPurge
--	.name
--	.rank
--	.shouldConsolidate
--	.showedWarning
--	.spellId
--	.texture
--	.updated
--	.updateInterval
--
-- Methods and functions:
--
--	:new(spellId, auraType)
--
--	:setCasterUnit(casterUnit)
--	:checkExpiration()

-- Create the class object.
local auraClass = {};

auraClass.meta = { __index = auraClass };
auraClass.super = auraClass.classObject;

function auraClass:new(spellId, auraType)
	-- Create an object of the class.
	local object = {};
	object.classObject = self;
	setmetatable(object, self.meta);

	object.spellId = spellId;
	object.auraType = auraType;

	return object;
end

function auraClass:setCasterUnit(casterUnit)
	-- Assign unit of the buff's caster and generate a
	-- string containing the caster's name (and possibly
	-- the caster's master's name) for use in the buff tooltip.
	local x;
	local casterName, casterClass, ccolors;
	local masterName, masterClass, mcolors;
	local masterUnit;

	self.casterUnit = casterUnit;

	-- Determine caster's name, class, and class colors.
	if (not casterUnit) then
		self.casterName = nil;
		return;
	end

	-- Safeguard the UnitName retrieval with pcall against secret values
	local nameSuccess, nameResult = pcall(UnitName, casterUnit);
	casterName = nameSuccess and nameResult or UNKNOWN;

	-- Safeguard UnitClass with pcall to fully eliminate the "secret values not allowed" crash
	local classSuccess, classResult = pcall(UnitClass, casterUnit);
	if classSuccess and classResult then
		casterClass = classResult;
	else
		casterClass = nil;
	end

	-- casterClass can be a restricted "secret" string in raid combat; ctSafe -> nil so it is never used
	-- as a table key ("attempted to index a table that cannot be indexed with secret keys").
	casterClass = ctSafe(casterClass);
	if (casterClass and RAID_CLASS_COLORS) then
		ccolors = RAID_CLASS_COLORS[casterClass];
	end
	if (not ccolors) then
		ccolors = defaultClassColors;
	end

	-- Safeguard UnitIsPlayer with pcall against secret values in combat
	local isPlayer = true;
	local playerSuccess, playerResult = pcall(UnitIsPlayer, casterUnit);
	if playerSuccess then
		isPlayer = playerResult;
	end

	if (not isPlayer) then
		-- Determine the master's name, class, and class colors.
		if (casterUnit == "pet" or casterUnit == "vehicle") then
			masterUnit = "player";
		else
			local id;
			id = string.match(casterUnit, "^partypet(%d)$");
			if (id) then
				masterUnit = "party" .. id;
			else
				id = string.match(casterUnit, "^raidpet(%d%d?)$");
				if (id) then
					masterUnit = "raid" .. id;
				end
			end
		end
		if (masterUnit) then
			masterName = (UnitName(masterUnit)) or UNKNOWN;
			x, masterClass = UnitClass(masterUnit);
			masterClass = ctSafe(masterClass);	-- secret string in raid combat -> nil; never used as a key
			if (masterClass and RAID_CLASS_COLORS) then
				mcolors = RAID_CLASS_COLORS[masterClass];
			end
			if (not mcolors) then
				mcolors = defaultClassColors;
			end
		end
	end

	-- Generate caster name to be used in the buff tooltip.
	if (casterName and masterName) then
		self.casterName = string.format("|cff%02x%02x%02x%s|r |cff%02x%02x%02x<%s>|r", ccolors.r * 255, ccolors.g * 255, ccolors.b * 255, casterName, mcolors.r * 255, mcolors.g * 255, mcolors.b * 255, masterName);
	elseif (casterName) then
		self.casterName = string.format("|cff%02x%02x%02x%s|r", ccolors.r * 255, ccolors.g * 255, ccolors.b * 255, casterName);
	else
		self.casterName = nil;
	end
end

function auraClass:checkExpiration()
	-- Check to see if it is time to display an expiration warning for this aura object.
	local displayWarning;

	local duration = floor(self.duration);  -- Game sometimes reports a non integer duration (eg. 1800.002).
	local timeRemaining = self.expirationTime - GetTime();
	if (timeRemaining <= 0) then
		return;
	end

	-- If we haven't displayed an expiration warning for this object yet...
	if (not self.showedWarning) then

		-- The duration must be at least 2 minutes, warnings must be enabled, and this must not be a debuff...
		if (duration > 119 and globalObject.enableExpiration and self.auraType ~= constants.AURATYPE_DEBUFF) then
			if (duration > 1800.5) then
				-- 30 min 1 second or greater
				if (timeRemaining <= globalObject.expirationWarningTime3) then
					displayWarning = true;
				end
			elseif (duration > 600.5) then
				-- 10 min 1 second to 30 min
				if (timeRemaining <= globalObject.expirationWarningTime2) then
					displayWarning = true;
				end
			else
				-- 2 min 0 sec to 10 min
				if (timeRemaining <= globalObject.expirationWarningTime1) then
					displayWarning = true;
				end
			end
		end

		if (displayWarning) then
		     	-- Check options
		     	local canRecastKeyBind;
			local name = self.name;

			if (name) then
				-- If you don't know how to cast this buff...
			     	local isUsable, insufficientPower = (IsUsableSpell or C_Spell.IsSpellUsable)(name)	-- classic vs WoW 11.0.2
			     	if not isUsable and not insufficientPower then
					-- If ignoring buffs you cannot cast...
			     		if (globalObject.expirationCastOnly) then
			     			return;
			     		end
			     	else
			     		-- Add the buff to the recast queue
					local queued = queueBuffRecast(name);
			     		canRecastKeyBind = queued and GetBindingKey("CT_BUFFMOD_RECASTBUFFS");
			     	end

				-- Display the expiration message
				if (canRecastKeyBind) then
					module:printformat(L["CT_BuffMod/PRE_EXPIRATION_WARNING_KEYBINDING"],
						name, timeFormat1(timeRemaining), canRecastKeyBind);
				else
					module:printformat(L["CT_BuffMod/PRE_EXPIRATION_WARNING"],
						name, timeFormat1(timeRemaining));
				end

				-- Play a sound
				if (globalObject.expirationSound) then
					if (module:getGameVersion() >= 3) then
						PlaySoundFile(569634); -- "Sound\\Spells\\misdirection_impact_head.wav"
					else
						PlaySound(3081); -- "TellMessage"
					end
				end
			end

			-- Remember that we've displayed a warning for this object.
			self.showedWarning = true;
		end
	end
end

--------------------------------------------
-- Unit class
--
-- Inherits fron:
-- 	None
--
-- Class object overview:
--
--	(unitClassObject)
--		.meta
--
-- Object overview:
--
--	(unitObject)
--		.classObject
--		.consolidateAura
--			(auraObject)
--		.enchantAuras[ constants.ENCHANT_SLOTS table key value ]
--			(auraObject)
--		.spellAuras[ AURA_TYPE_* value ]
--			(auraObject)
--		.unitId
--
-- Properties:
--
--	.classObject
--	.meta
--	.super
--
--	.enchantAuras
--	.consolidateAura
--	.spellAuras
--	.unitId
--
-- Methods and functions:
--
--	:new(unitId)
--
--	:addSpell(spellId, auraType)
--	:removeSpell(spellId)
--	:moveSpell(spellId, auraTypeFrom, auraTypeTo)
--	:findSpell(spellId)
--
--	:updateSpellsForFilter(filter, buffFlag)
--	:updateSpells()
--
--	:addEnchant(index, slot)
--	:removeEnchant(index)
--	:findEnchant(index)
--	:updateEnchants()
--
--	:getConsolidateAura()
--	:setConsolidateAura()
--
--	:checkExpiration()

-- Create the class object.
local unitClass = {};

unitClass.meta = { __index = unitClass };
unitClass.super = unitClass.classObject;

function unitClass:new(unitId)
	-- Create an object of the class.
	local object = {};
	object.classObject = self;
	setmetatable(object, self.meta);

	object.unitId = unitId;
	object.spellAuras = {};  -- Aura objects for spells. Index 1: aura type, Index 2: spell id.
	object.enchantAuras = {};  -- Aura objects for temporary weapon enchants. Index: 1==Main hand, 2==Off hand, 3==Ranged -- rng
	object.consolidateAura = nil;  -- Aura object for the consolidated button

	return object;
end

function unitClass:addSpell(spellId, auraType)
	-- Add an aura object using the specified spellId.
	-- Returns nil or the aura object.
	if (spellId) then
		if type(self.spellAuras) ~= "table" then self.spellAuras = {}; end
		
		local auraObjects = self.spellAuras[auraType];
		if (not auraObjects) then
			auraObjects = {};
			self.spellAuras[auraType] = auraObjects;
		end
		
		-- Safeguard for Retail: protect the indexing against "secret keys" crashes in combat
		local success, hasKey = pcall(function() return auraObjects and auraObjects[spellId] end);
		local exists = false;
		
		if success and hasKey then
			exists = true;
		end
		
		if (not exists) then
			-- Create, add, and return a new aura object.
			local auraObject = auraClass:new(spellId, auraType);
			
			-- Also safeguard the insertion into the table via pcall
			pcall(function() auraObjects[spellId] = auraObject end);
			return auraObject;
		else
			-- If it already exists, return the protected object safely
			local fetchSuccess, existingObject = pcall(function() return auraObjects[spellId] end);
			if fetchSuccess then
				return existingObject;
			end
		end
	end
	return nil;
end

function unitClass:removeSpell(spellId)
	-- Remove an aura object using the specified spellId.
	-- Returns nil or the aura object.
	if (spellId) then
		local auraObject;
		for __, auraObjects in pairs(self.spellAuras) do
			auraObject = auraObjects[spellId];
			if (auraObject) then
				-- Remove and return the aura object.
				auraObjects[spellId] = nil;
				return auraObject;
			end
		end
	end
	return nil;
end

function unitClass:moveSpell(spellId, auraTypeFrom, auraTypeTo)
	-- Move a spell object from one aura type to another.
	if (spellId) then
		local auraObjectFrom;
		local auraObjectsFrom;
		local auraObjectsTo;
		local move;

		-- Get the "from" aura object.
		auraObjectsFrom = self.spellAuras[auraTypeFrom];
		if (auraObjectsFrom) then
			auraObjectFrom = auraObjectsFrom[spellId];
		end

		-- Move the "from" aura object only if there is not already
		-- an aura object with the same spellId in the "to" table.
		auraObjectsTo = self.spellAuras[auraTypeTo];
		if (not auraObjectsTo) then
			auraObjectsTo = {};
			self.spellAuras[auraTypeTo] = auraObjectsTo;
			move = true;
		else
			if (not auraObjectsTo[spellId]) then
				move = true;
			end
		end

		if (move) then
			auraObjectsFrom[spellId] = nil;
			auraObjectsTo[spellId] = auraObjectFrom;
			return true;
		end
	end
	return false;
end

function unitClass:findSpell(spellId)
	-- Find the aura object associated with the specified spellId.
	-- Returns nil or the aura object.
	if (spellId) then
		if type(self.spellAuras) ~= "table" then return nil; end

		-- Safe raw loop for Retail that does not crash on hidden tables (secret keys)
		local auraType, auraObjects = next(self.spellAuras);
		while auraType do
			if type(auraObjects) == "table" then
				-- Protect the indexing with pcall in case the table keys are encrypted
				local success, auraObject = pcall(function() return auraObjects[spellId] end);
				if success and auraObject then
					return auraObject;
				end
			end
			auraType, auraObjects = next(self.spellAuras, auraType);
		end
	end
	return nil;
end

function unitClass:updateSpellsForFilter(filter, buffFlag)
	local unit, index, auraObject, auraType;
	unit = self.unitId;
	index = 1;
	
	-- Safeguard for Retail: pcall around Blizzard's UnitAura API in combat
	local success, aura = pcall(function() return C_UnitAuras.GetAuraDataByIndex(unit, index, filter) end)
	if not success or not aura then return; end

	while aura do
		-- SANITIZATION FOR RETAIL: in combat these can be restricted "secret numbers". tonumber() does
		-- NOT neutralize them (the value stays secret and crashes later comparisons), so use ctSafe,
		-- which probes with a comparison and returns the default (0) when the value is secret/unusable.
		local auraDuration = ctSafe(aura.duration, 0);
		local auraExpiration = ctSafe(aura.expirationTime, 0);
		local auraApplications = ctSafe(aura.applications, 0);

		-- Track auras by auraInstanceID: spellId is a restricted "secret" value in combat and can't be
		-- used as a table key, which broke dedup (duplicate buttons piling up in combat).
		auraObject = self:findSpell(aura.auraInstanceID);
		if (not auraObject) then
			-- New aura
			if (buffFlag) then
				-- Bulletproof Retail safeguard: compare the value inside a pcall to bypass "secret number" blocks
				local isZeroDuration = false;
				local compareSuccess, compareResult = pcall(function() return (auraDuration == 0 or auraDuration == nil) end);
				if compareSuccess then
					isZeroDuration = compareResult;
				end

				if (isZeroDuration) then
					auraType = constants.AURATYPE_AURA;
				else
					auraType = constants.AURATYPE_BUFF;
				end
			else
				auraType = constants.AURATYPE_DEBUFF;
			end

			auraObject = self:addSpell(aura.auraInstanceID, auraType);
			if (auraObject) then
				auraObject.name = aura.name;
				auraObject.texture = aura.icon;
				auraObject.debuffType = aura.dispelName;
				auraObject.duration = auraDuration;
				auraObject.expirationTime = auraExpiration;
				auraObject.casterUnit = aura.sourceUnit;
				auraObject.canStealOrPurge = aura.isStealable;
				auraObject:setCasterUnit(aura.sourceUnit);

				auraObject.updateInterval = getAuraUpdateInterval(auraDuration);

				auraObject.isFlashing = false;
				auraObject.showedWarning = false;

				-- Remove this from buff recasting
				removeBuffRecast(aura.name);
			end
		else
			-- Existing aura
			-- Sanitized comparison (only plain Lua numbers are compared here now)
			if (auraObject.duration == 0 and auraDuration ~= 0) then
				auraObject.duration = auraDuration;
				auraObject.expirationTime = auraExpiration;
				auraObject.updateInterval = getAuraUpdateInterval(auraDuration);
				auraObject.isFlashing = false;
				auraObject.showedWarning = false;

				if (buffFlag) then
					if (auraDuration == 0) then
						auraType = constants.AURATYPE_AURA;
					else
						auraType = constants.AURATYPE_BUFF;
					end
				else
					auraType = constants.AURATYPE_DEBUFF;
				end
				if (auraObject.auraType ~= auraType) then
					if (self:moveSpell(aura.auraInstanceID, auraObject.auraType, auraType)) then
						auraObject.auraType = auraType;
					end
				end

			elseif (auraObject.duration ~= 0 and auraDuration == 0) then
				auraObject.duration = auraDuration;
				auraObject.expirationTime = auraExpiration;
				auraObject.updateInterval = getAuraUpdateInterval(auraDuration);
				auraObject.isFlashing = false;
				auraObject.showedWarning = false;

			elseif (auraObject.expirationTime ~= auraExpiration) then
				auraObject.duration = auraDuration;
				auraObject.expirationTime = auraExpiration;
				auraObject.updateInterval = getAuraUpdateInterval(auraDuration);

				local renew = false;
				if (auraExpiration ~= 0) then
					if (auraDuration > 0) then
						local remain = auraExpiration - GetTime();
						if (remain > auraDuration - 60) then
							renew = true;
						end
					else
						renew = true;
					end
				end

				if (renew) then
					auraObject.isFlashing = false;
					auraObject.showedWarning = false;
					removeBuffRecast(aura.name);
				end
			end
		end
		
		if (auraObject) then
			auraObject.updated = true;
			auraObject.count = auraApplications;
			-- Auras are keyed by auraInstanceID, so keep the real spellId here for the tooltip.
			-- Only store it when readable (ctSafe): spellId is secret in combat, and storing a secret
			-- would crash the tooltip's "Spell ID" concatenation. Out of combat it captures the real id.
			auraObject.spellId = ctSafe(aura.spellId, auraObject.spellId);
		end

		index = index + 1;
		-- Fetch the next aura in a safe way
		success, aura = pcall(function() return C_UnitAuras.GetAuraDataByIndex(unit, index, filter) end)
		if not success then break; end
	end
end

function unitClass:updateSpells()
	-- Update spell auras for this unit.
	if type(self.spellAuras) ~= "table" then return; end

	-- Safe reset of the .updated flag
	local auraType, auraObjects = next(self.spellAuras);
	while auraType do
		if type(auraObjects) == "table" then
			local spellId, auraObject = next(auraObjects);
			while spellId do
				if type(auraObject) == "table" then
					auraObject.updated = false;
				end
				spellId, auraObject = next(auraObjects, spellId);
			end
		end
		auraType, auraObjects = next(self.spellAuras, auraType);
	end

	-- Update spell aura information.
	self:updateSpellsForFilter("helpful", true);
	self:updateSpellsForFilter("harmful", false);

	-- Safe cleanup of lost auras
	local auraType, auraObjects = next(self.spellAuras);
	while auraType do
		if type(auraObjects) == "table" then
			local spellId, auraObject = next(auraObjects);
			while spellId do
				if type(auraObject) == "table" and not auraObject.updated then
					-- Run via pcall so it does not crash in the middle of the cleanup
					pcall(function() self:removeSpell(spellId) end);
				end
				spellId, auraObject = next(auraObjects, spellId);
			end
		end
		auraType, auraObjects = next(self.spellAuras, auraType);
	end
end

function unitClass:addEnchant(index, slot)
	-- Add an enchant object using the specified index.
	-- Returns nil or the aura object.
	if (index) then
		local enchantAuras = self.enchantAuras;
		if (not enchantAuras[index]) then
			-- Create, add, and return a new enchant object.
			local auraObject = auraClass:new(slot, constants.AURATYPE_ENCHANT);
			enchantAuras[index] = auraObject;
			return auraObject;
		end
	end
	return nil;
end

function unitClass:removeEnchant(index)
	-- Remove an enchant object using the specified index.
	-- Returns nil or the aura object.
	if (index) then
		local auraObject = self.enchantAuras[index];
		if (auraObject) then
			-- Remove and return the aura object.
			self.enchantAuras[index] = nil;
			return auraObject;
		end
	end
	return nil;
end

function unitClass:findEnchant(index)
	-- Find an enchant object using the specified index.
	if (index) then
		return self.enchantAuras[index];
	end
	return nil;
end

local TOOLTIP = CreateFrame("GameTooltip", "CT_BuffModTooltip", nil, "GameTooltipTemplate");
--local TOOLTIP_TITLE = _G.CT_BuffModTooltipTextLeft1;	-- it doesn't appear this is ever used
TOOLTIP:SetOwner(WorldFrame, "ANCHOR_NONE");

local function getTemporaryEnchantInfo(index, slot, unit)
	-- index == enchant index (1 or 2)
	-- slot == inventory slot number (16 == main hand, 17 = off hand, 18 = ranged) -- rng
	-- unit == unit ID (should be "player")

	local numValues = 4;  -- Number of return values from GetWeaponEnchantInfo() per weapon
	local hasEnchant, timeRemaining, count;
	if GetWeaponEnchantInfo then
		  hasEnchant, timeRemaining, count = select(numValues * (index - 1) + 1, GetWeaponEnchantInfo());
	else
		  hasEnchant = false;
	end
	if (not hasEnchant) then
		return false;
	end

	local expirationTime, texture, name;

	timeRemaining = floor((timeRemaining or 0) / 1000); -- Convert from milliseconds to seconds.
	expirationTime = GetTime() + timeRemaining;

	-- Extract the enchant name and time remaining from the weapon's tooltip.
	local text, numLines;
	TOOLTIP:ClearLines();
	TOOLTIP:SetInventoryItem(unit, slot);
	numLines = TOOLTIP:NumLines();
	for i = 1, numLines do
		text = _G["CT_BuffModTooltipTextLeft" .. i]:GetText();
		name = strmatch(text, "^(.+) %(%d+%s+.+%)$");
		if (name) then
			break;
		end
	end

	texture = GetInventoryItemTexture(unit, slot);

	return hasEnchant, name, texture, count or 0, timeRemaining, expirationTime;
end


local oldNumEnchants;
function unitClass:updateEnchants()
	-- Update enchant objects for this unit.
	-- Returns the number of enchants.

	local slot, enchanted, timeRemaining, count, name, texture, expirationTime;
	local auraObject;
	local numEnchants = 0;

	if (self.unitId ~= "player") then
		return 0;
	end

	for index = 1, #(constants.ENCHANT_SLOTS) do
		auraObject = self:findEnchant(index);

		slot = constants.ENCHANT_SLOTS[index];
		enchanted, name, texture, count, timeRemaining, expirationTime = getTemporaryEnchantInfo(index, slot, "player"); -- unit);

		if (enchanted) then
			numEnchants = numEnchants + 1;

			local addEnchant;

			if (not name) then
				-- Weapon is enchanted, but we couldn't figure out what the enchant name is.
				if (timeRemaining < 1) then
					-- When the timeRemaining reaches zero, the game will drop the name from
					-- the tooltip. However, GetWeaponEnchantInfo() continues to indicate
					-- (for a few more seconds) that the weapon is enchanted.
					if (auraObject) then
						-- Continue using the name we had for it.
						name = auraObject.name;
						texture = auraObject.texture;
					else
						name = UNKNOWN;
					end
				else
					name = UNKNOWN;
				end
			end
			
			
			--function used when rescanning
			self.rescanEnchantsFunc = self.rescanEnchantsFunc or function()
				local newNumEnchants = self:updateEnchants();
				if (newNumEnchants ~= oldNumEnchants or newNumEnchants > 0) then
					oldNumEnchants = newNumEnchants;
					globalObject.windowListObject:refreshWeaponButtons();
				end
			end
				
			--scheduling the rescanning, every second for unknown buffs or every two seconds for known buffs
			if (name == UNKNOWN and self.enchantTickerTime ~= 1) then
				if (self.enchantTicker) then
					self.enchantTicker:Cancel();
				end
				self.enchantTickerTime = 1;
				self.enchantTicker = C_Timer.NewTicker(1, self.rescanEnchantsFunc);
			elseif (name ~= UNKNOWN and self.enchantTickerTime ~=2) then
				if (self.enchantTicker) then
					self.enchantTicker:Cancel();
				end
				self.enchantTickerTime = 2;
				self.enchantTicker = C_Timer.NewTicker(2, self.rescanEnchantsFunc);
			end
			
			-- If we previously recorded an enchant for this slot...
			if (auraObject) then

				-- If this looks to be the same enchant as before...
				if (name == auraObject.name and texture == auraObject.texture) then

					local oldTimeRemaining, oldCount;

					oldTimeRemaining = auraObject.expirationTime - GetTime();
					oldCount = auraObject.count;

					auraObject.spellId = slot;
					auraObject.expirationTime = expirationTime;

					if (timeRemaining > auraObject.duration) then
						auraObject.duration = timeRemaining;
					end

					-- Renew or update the enchant object.
					if (timeRemaining > oldTimeRemaining + 0.5) then
						-- The enchant object was renewed.
						auraObject.isFlashing = false;
						auraObject.showedWarning = false;
					end

					-- If the number of charges changed...
					if (count ~= oldCount) then
						auraObject.count = count;
					end
				else
					-- This appears to be a different enchant than before.

					-- Remove the old buff object.
					self:removeEnchant(index);

					-- Add a new enchant object.
					addEnchant = true;
				end
			else
				-- We don't have a previous enchant recorded for this hand.

				-- Add a new enchant object.
				addEnchant = true;
			end

			if (addEnchant) then
				auraObject = self:addEnchant(index, slot);

				auraObject.name = name;
				auraObject.rank = nil;
				auraObject.texture = texture;
				auraObject.debuffType = nil;
				auraObject.duration = timeRemaining;
				auraObject.casterUnit = unit;
				auraObject.canStealOrPurge = nil;
				auraObject.shouldConsolidate = nil;
				auraObject:setCasterUnit(unit);

				auraObject.updateInterval = getAuraUpdateInterval(timeRemaining);

				auraObject.isFlashing = false;
				auraObject.showedWarning = false;

				auraObject.expirationTime = expirationTime;
				auraObject.count = count;
			end
		else
			-- This item is not enchanted.
			if (auraObject) then
				-- Remove the enchant object.
				self:removeEnchant(index);
			end
		end
	end

	return numEnchants;
end

function unitClass:getConsolidateAura()
	-- Get the consolidated aura object.
	return self.consolidateAura;
end

function unitClass:setConsolidateAura()
	-- Set the information for the consolidated buff object.
	local auraObject = auraClass:new(1, constants.AURATYPE_CONSOLIDATED);

	auraObject.name = "Consolidated"
	auraObject.rank = "";
	auraObject.texture = "Interface\\Buttons\\BuffConsolidation";
	auraObject.debuffType = nil;
	auraObject.duration = 0;
	auraObject.casterUnit = self.unitId;
	auraObject.canStealOrPurge = nil;
	auraObject.shouldConsolidate = nil;
	auraObject:setCasterUnit(auraObject.casterUnit);

	auraObject.updateInterval = getAuraUpdateInterval(auraObject.duration);

	auraObject.isFlashing = false;
	auraObject.showedWarning = true;

	auraObject.updated = true;
	auraObject.count = 0;
	auraObject.expirationTime = 0;

	self.consolidateAura = auraObject;
end

function unitClass:checkExpiration()
	-- Check to see if it is time to display an expiration warning for any buff or enchant objects assigned to this unit.
	local auraObjects;

	-- Check auras
	auraObjects = self.spellAuras[constants.AURATYPE_BUFF];
	if (auraObjects) then
		for spellId, auraObject in pairs(auraObjects) do
			auraObject:checkExpiration();
		end
	end

	-- Check enchants
	auraObjects = self.enchantAuras;
	for __, auraObject in pairs(auraObjects) do
		auraObject:checkExpiration();
	end
end

--------------------------------------------
-- Unit list class
--
-- Inherits from:
--
-- 	None
--
-- Class object overview:
--
--	(unitListClassObject)
--		.meta
--
-- Object overview:
--
--	(unitListObject)
--		.classObject
--		.unitObjects[ unitId ]
--			(unitObject)
--
-- Properties:
--
--	.classObject
--	.meta
--	.super
--
--	.unitObjects
--
-- Methods and functions:
--
--	:new()
--
--	:addUnit(unitId)
--	:deleteUnit(unitId)
--	:findUnit(unitId)
--
--	:updateSpells(unitId)
--	:updateEnchants(unitId)
--	:updateSpellsAndEnchants(unitId)
--	:setConsolidateAura()
--
--	:checkExpiration()

-- Create the class object.
local unitListClass = {};

unitListClass.meta = { __index = unitListClass };
unitListClass.super = unitListClass.classObject;

function unitListClass:new()
	-- Create an object of this class.
	local object = {};
	object.classObject = self;
	setmetatable(object, self.meta);

	object.unitObjects = {};

	return object;
end

function unitListClass:addUnit(unitId)
	-- Add a unit object using the specified unitId.
	-- Returns nil or the unit object that was added.
	if (unitId) then
		local unitObjects = self.unitObjects;
		if (not unitObjects[unitId]) then
			-- Create, add, and return a new unit object.
			local unitObject = unitClass:new(unitId);
			unitObject:setConsolidateAura();
			unitObjects[unitId] = unitObject;
			return unitObject;
		end
	end
	return nil;
end

function unitListClass:deleteUnit(unitId)
	-- Delete a unit object using the specified unitId.
	-- Note: Avoid deleting the unit object if it is being used by a window.
	if (unitId) then
		-- Don't delete the unit if it is the player, since we need to keep
		-- their buffs for the expiration messages.
		if (unitId == "player") then
			return nil;
		end

		local unitObjects = self.unitObjects;
		if (unitObjects[unitId]) then
			-- Delete the unit object.
			unitObjects[unitId] = nil;
		end
	end
	return nil;
end

function unitListClass:findUnit(unitId)
	-- Find a unit object using the specified unitId.
	-- Returns nil or the unit object.
	if (unitId) then
		-- Return the aura object or nil.
		local unitObjects = self.unitObjects;
		return unitObjects[unitId];
	end
	return nil;
end

function unitListClass:updateSpells(unitId)
	-- Update spell auras for all units in the list, or just the specified unit.
	if (not unitId) then
		for __, unitObject in pairs(self.unitObjects) do
			unitObject:updateSpells();
		end
	else
		local unitObject = self:findUnit(unitId);
		if (unitObject) then
			unitObject:updateSpells();
		end
	end
end

function unitListClass:updateEnchants(unitId)
	-- Update enchants for all units in the list, or just the specified unit.
	local numEnchants = 0;
	if (not unitId) then
		for __, unitObject in pairs(self.unitObjects) do
			numEnchants = numEnchants + unitObject:updateEnchants();
		end
	else
		local unitObject = self:findUnit(unitId);
		if (unitObject) then
			numEnchants = unitObject:updateEnchants();
		end
	end
	return numEnchants;
end

function unitListClass:updateSpellsAndEnchants(unitId)
	-- Update auras and enchants for all units in the list, or just the specified unit.
	local numEnchants = 0;
	if (not unitId) then
		for __, unitObject in pairs(self.unitObjects) do
			unitObject:updateSpells();
			numEnchants = numEnchants + unitObject:updateEnchants();
		end
	else
		local unitObject = self:findUnit(unitId);
		if (unitObject) then
			unitObject:updateSpells();
			numEnchants = unitObject:updateEnchants();
		end
	end
	return numEnchants;
end

function unitListClass:setConsolidateAura()
	for __, unitObject in pairs(self.unitObjects) do
		unitObject:setConsolidateAura();
	end
end

function unitListClass:checkExpiration()
	-- Check if it is time to display expiration warning messages.

	-- We are only going to display messages for the "player" unit.
	local unitObject = self:findUnit("player");
	if (unitObject) then
		unitObject:checkExpiration();
	end
end

--------------------------------------------
-- Aura frame buttons
--
-- Properties:
--
--	.auraObject
--	.ctinit
--	.filter
--	.frameDetails
--	.fsCount
--	.fsName
--	.fsTimeleft
--	.index
--	.mode
--	.frameObject
--	.timeleftFlag
--	.txBackground
--	.txIcon
--	.txSpark
--	.txTimerBG
--	.unitObject
--	.fontSize
--	.font

local mindetailWidth1 = 1;  -- Minimum width of detail frame before hiding font strings.

local function auraButton_updateFlashing(button)
	local frameObject = button.frameObject;
	local auraObject = button.auraObject;
	if (not auraObject) then
		return;
	end

	local timeRemaining = auraObject.expirationTime - GetTime();

	if (timeRemaining <= globalObject.flashTime and auraObject.duration > 0) then
		auraObject.isFlashing = true;

		-- If you target someone and then run a distance away, you will still know they have buffs,
		-- but the time remaining appears to be zero, which causes the icons to flash.
		-- To avoid the flashing, we'll check if they are in range when the time is zero, and if not
		-- then we'll stop the flashing.
		if (timeRemaining <= 0) then
			-- Bulletproof Retail safeguard:
			-- We run the entire range check and logic inside a pcall.
			-- If UnitInRange returns a "secret boolean value", the game's own engine is allowed
			-- to evaluate it in a protected environment and turn off the flash for us
			-- without the addon's taint crashing the UI.
			pcall(function()
				if UnitInRange then
					local inRange = UnitInRange(frameObject:getUnitId());
					-- The comparison now happens in a protected, isolated thread
					if (not inRange) then
						auraObject.isFlashing = false;
					end
				else
					-- Fallback om UnitInRange saknas helt
					auraObject.isFlashing = false;
				end
			end);
		end
	else
		auraObject.isFlashing = false;
	end
	if (auraObject.isFlashing) then
		button.txIcon:SetAlpha(module.auraAlpha or 1);
	else
		button.txIcon:SetAlpha(1);
	end
end

local function auraButton_updateTimerBar(button)
	-- Update the timer bar.
	local frameObject = button.frameObject;

	if (frameObject.buttonStyle ~= 1) then
		return;
	end

	local auraObject = button.auraObject;
	if (not auraObject) then
		return;
	end

	local txTimerBG = button.txTimerBG;
	local txBackground = button.txBackground;
	if (not txBackground) then
		return;
	end

	local timeRemaining = auraObject.expirationTime - GetTime();
	if (timeRemaining < 0) then
		timeRemaining = 0;
	end

	local txSpark = button.txSpark;

	if (frameObject.detailWidth1 < mindetailWidth1) then
		if (txSpark) then
			txSpark:Hide();
		end
		txBackground:Hide();
		if (txTimerBG) then
			txTimerBG:SetWidth(1);
		end
	elseif (not frameObject.showBuffTimer1 or auraObject.duration == 0) then
		-- User doesn't want to see the aura timer bar, or this is a buff aura.
		-- Hide the spark graphic, and show the background at full width.
		if (txSpark) then
			txSpark:Hide();
		end
		txBackground:SetWidth(frameObject.detailWidth1);
		if (txTimerBG) then
			txTimerBG:SetWidth(1);
		end
	else
		-- Show the spark graphic, and set the button's background to a width
		-- based on the amount of time remaining on the aura, and the aura's duration.
		if (txSpark) then
			txSpark:Show();
		end
		local width = max((frameObject.detailWidth1) * min(timeRemaining / auraObject.duration, 1), 0.01);
		txBackground:SetWidth(width);
		if (txTimerBG) then
			txTimerBG:SetWidth(frameObject.detailWidth1 - width);
		end
	end
end

local function auraButton_updateTimeNameSpecial(button)
	-- Show time beside the name (buttonStyle 1)

	-- This function is needed because the time left font string
	-- may vary in width as the remaining time changes.
	-- Note: Only call this if button.timeleftFlag == true

	local frameObject = button.frameObject;
	local frameDetails = button.frameDetails;
	local fsName = button.fsName;
	local fsTimeleft = button.fsTimeleft;
	local spacingOnLeft1 = frameObject.spacingOnLeft1;
	local spacingOnRight1 = frameObject.spacingOnRight1;

	fsTimeleft:SetWidth(0);
	local timeWidth = fsTimeleft:GetStringWidth();

	if (frameObject.detailWidth1 <= timeWidth + spacingOnLeft1 + spacingOnRight1) then
		-- Show time.
		if (frameObject.rightAlignIcon1) then
			fsTimeleft:SetJustifyH("RIGHT");
		else
			fsTimeleft:SetJustifyH("LEFT");
		end
		fsTimeleft:SetPoint("LEFT", frameDetails, "LEFT", spacingOnLeft1, 0);
		fsTimeleft:SetPoint("RIGHT", frameDetails, "RIGHT", -spacingOnRight1, 0);

		fsName:Hide();
		fsTimeleft:Show();
	else
		local location;
		if (frameObject.durationLocation1 == constants.DURATION_LOCATION_DEFAULT) then
			if (frameObject.rightAlignIcon1) then
				location = constants.DURATION_LOCATION_LEFT;
			else
				location = constants.DURATION_LOCATION_RIGHT;
			end
		else
			location = frameObject.durationLocation1;
		end
		if (location == constants.DURATION_LOCATION_LEFT) then
			-- Show time (on left), name (on right).
			fsTimeleft:SetJustifyH("LEFT");
			fsTimeleft:SetWidth(timeWidth);
			fsTimeleft:SetPoint("LEFT", frameDetails, "LEFT", spacingOnLeft1, 0);

			if (justifyH(fsName, frameObject.nameJustifyWithTime1, "RIGHT")) then
				spacingOnRight1 = 0;
			end
			fsName:SetPoint("RIGHT", frameDetails, "RIGHT", -spacingOnRight1, 0);
			fsName:SetPoint("LEFT", fsTimeleft, "RIGHT", 0, 0);

			fsName:Show();
			fsTimeleft:Show();

		else -- if (location == constants.DURATION_LOCATION_RIGHT) then
			-- Show name (on left), time (on right).
			fsTimeleft:SetJustifyH("RIGHT");
			fsTimeleft:SetWidth(timeWidth);
			fsTimeleft:SetPoint("RIGHT", frameDetails, "RIGHT", -spacingOnRight1, 0);

			if (justifyH(fsName, frameObject.nameJustifyWithTime1, "LEFT")) then
				spacingOnLeft1 = 0;
			end
			fsName:SetPoint("LEFT", frameDetails, "LEFT", spacingOnLeft1, 0);
			fsName:SetPoint("RIGHT", fsTimeleft, "LEFT", 0, 0);

			fsName:Show();
			fsTimeleft:Show();
		end
	end
end

local function auraButton_updateTimeDisplay(button)
	-- Update the time remaining
	local frameObject = button.frameObject;
	local auraObject = button.auraObject;
	if (not auraObject) then
		return;
	end

	local fsTimeleft = button.fsTimeleft;
	if (not fsTimeleft) then
		return;
	end

	local timeRemaining = auraObject.expirationTime - GetTime();
	if (timeRemaining < 0) then
		timeRemaining = 0;
	end

	if (frameObject.buttonStyle == 2) then
		if (
			(not frameObject.showTimers2) or
			(auraObject.duration <= 0)
		) then
			fsTimeleft:SetText("");
		else
			fsTimeleft:SetText(frameObject.durationFunc2(timeRemaining,frameObject.showDays2));
		end
	else
		if (
			(not frameObject.showTimers1) or
			(frameObject.detailWidth1 < mindetailWidth1) or
			(auraObject.duration <= 0)
		) then
			fsTimeleft:SetText("");
		else
			fsTimeleft:SetText(frameObject.durationFunc1(timeRemaining,frameObject.showDays1));
			if (button.timeleftFlag) then
				auraButton_updateTimeNameSpecial(button);
			end
		end
	end
end

local function auraButton_Update(self)
	local auraObject = self.auraObject;
	if (not auraObject) then
		if (self.ticker) then
			self.ticker:Cancel();
			self.ticker = nil;
		end
		return;
	end
	auraButton_updateTimerBar(self);
	auraButton_updateTimeDisplay(self);
	auraButton_updateFlashing(self);
	local interval = (auraObject.isFlashing and 0.05) or auraObject.updateInterval or 1;
	self.onUpdate = self.onUpdate or function() auraButton_Update(self) end;
	if (self.ticker == nil) then
		self.ticker = C_Timer.NewTicker(interval, self.onUpdate);
		self.tickerTime = interval;
	elseif (self.tickerTime ~= interval) then
		self.ticker:Cancel();
		self.ticker = C_Timer.NewTicker(interval, self.onUpdate);
		self.tickerTime = interval;
	end
end

local function auraButton_updateDimensions(button)
	-- Update the size of the icon, and spark.
	local frameObject = button.frameObject;
	local buttonStyle = frameObject.buttonStyle;

	if (buttonStyle == 1) then
		local frameDetails = button.frameDetails;
		local txSpark = button.txSpark;
		local txTimerBG = button.txTimerBG;
		local txBackground = button.txBackground;

		if ( txSpark ) then
			txSpark:SetWidth(min(frameObject.detailHeight1 * 2/3, 25));
			txSpark:SetHeight(frameObject.detailHeight1 * 1.9);
		end

		frameDetails:SetHeight(frameObject.detailHeight1);
		frameDetails:SetWidth(frameObject.detailWidth1);

		if (txBackground) then
			txBackground:SetHeight(frameObject.detailHeight1);
		end

		if (txTimerBG) then
			txTimerBG:SetHeight(frameObject.detailHeight1);
		end
	end
	
	auraButton_updateTimerBar(button);
end

local function auraButton_updateAppearance(button)
	-- ----------
	-- Update the button's appearance.
	-- This is the first auraButton_ routine to get called for each button
	-- after Blizzard configures the buttons.
	-- ---------
	local frameObject = button.frameObject;

	button.timeleftFlag = nil;

	local unitObject = globalObject.unitListObject:findUnit(frameObject:getUnitId());
	if (not unitObject) then
		return;
	end
	button.unitObject = unitObject;

	local index = button.index;
	local filter = button.filter;
	local auraObject;

	if (button.mode == constants.BUTTONMODE_SPELL) then
		-- Spell (buff, debuff)
		if (not index or not filter) then
			return;
		end
		local aura = C_UnitAuras.GetAuraDataByIndex(frameObject:getUnitId(), index, filter)
		auraObject = aura and unitObject:findSpell(aura.auraInstanceID);

	elseif (button.mode == constants.BUTTONMODE_ENCHANT) then
		-- Temporary weapon enchant
		-- index == enchant index (1 or 2 or 3)
		-- filter == inventory slot number (16 == main hand, 17 = off hand, 18 == ranged) -- rng
		if (not index or not filter) then
			return;
		end
		auraObject = unitObject:findEnchant(index);

	elseif (button.mode == constants.BUTTONMODE_CONSOLIDATED) then
		-- Consolidated buffs button
		auraObject = unitObject:getConsolidateAura();

		-- Count the number of consolidated buffs and adjust the aura object
		-- so that the number can be shown on the button.
		local auraFrame = frameObject.consolidatedObject.auraFrame;
		local count = 1;
		local button = auraFrame:GetAttribute("child1");
		while (button and button:IsShown()) do
			count = count + 1;
			button = auraFrame:GetAttribute("child" .. count);
		end
		auraObject.count = count - 1;

	else
		return;
	end

	if (not auraObject) then
		return;
	end
	button.auraObject = auraObject;

	local durationBelow;
	local spacingOnLeft1 = frameObject.spacingOnLeft1;
	local spacingOnRight1 = frameObject.spacingOnRight1;

	-- Set up the button
	local frameDetails = button.frameDetails;
	local fsName = button.fsName;
	local fsTimeleft = button.fsTimeleft;
	local txBackground = button.txBackground;
	local txTimerBG = button.txTimerBG;
	local txIcon = button.txIcon;
	local txSpark = button.txSpark;
	local txBorder = button.border;

	if (not txIcon) then
		txIcon = button:CreateTexture(nil, "ARTWORK");
		txIcon:SetTexCoord(0.1, 0.9, 0.1, 0.9);
		txIcon:SetAllPoints();
		button.txIcon = txIcon;
	end

	if (not frameDetails) then
		frameDetails = CreateFrame("Frame", nil, button);
		button.frameDetails = frameDetails;
	end

	if (
		(frameObject.buttonStyle == 1 and frameObject.showTimers1) or
		(frameObject.buttonStyle == 2 and frameObject.showTimers2)
	) then
		if ( not fsTimeleft ) then
			fsTimeleft = frameDetails:CreateFontString(nil, "ARTWORK", "ChatFontNormal");
			fsTimeleft:SetWordWrap(false)
			button.fsTimeleft = fsTimeleft;
		end
	elseif ( fsTimeleft ) then
		fsTimeleft:Hide();
		fsTimeleft = nil;
	end

	if (fsTimeleft and frameObject.fontSize) then
		if (frameObject.fontSize == 1 and fsTimeleft.font ~= "ChatFontNormal") then
			fsTimeleft:SetFontObject("ChatFontNormal");
			fsTimeleft.font = "ChatFontNormal";
		elseif (frameObject.fontSize == 2 and fsTimeleft.font ~= "ChatFontSmall") then
			fsTimeleft:SetFontObject("ChatFontSmall");
			fsTimeleft.font = "ChatFontSmall";
		elseif (frameObject.fontSize == 3 and fsTimeleft.font ~= "CT_BuffMod_ChatFontLarge") then
			if (not CT_BuffMod_ChatFontLarge) then
				CreateFont("CT_BuffMod_ChatFontLarge");
				local fname, fsize, fargs = ChatFontNormal:GetFont();
				CT_BuffMod_ChatFontLarge:SetFont(fname, fsize + 2, fargs);
			end
			fsTimeleft:SetFontObject("CT_BuffMod_ChatFontLarge");
			fsTimeleft.font = "CT_BuffMod_ChatFontLarge";
		end
	end

	if (frameObject.buttonStyle == 2) then
		frameDetails:SetHeight(0);
		frameDetails:SetWidth(0);
		frameDetails:Show();

		if (fsName) then
			fsName:Hide();
			fsName = nil;
		end
		if (txBackground) then
			txBackground:Hide();
			txBackground = nil;
		end
		if (txSpark) then
			txSpark:Hide();
			txSpark = nil;
		end
		if (txTimerBG) then
			txTimerBG:Hide();
			txTimerBG = nil;
		end
	else
		frameDetails:SetHeight(frameObject.detailHeight1);
		frameDetails:SetWidth(frameObject.detailWidth1);
		frameDetails:Show();

		if ( frameObject.colorBuffs1 ) then
			if ( not txBackground ) then
				txBackground = frameDetails:CreateTexture(nil, "BACKGROUND");
				txBackground:SetTexture("Interface\\AddOns\\CT_BuffMod\\Images\\barSmooth");
				txBackground:SetHeight(frameObject.detailHeight1);
				button.txBackground = txBackground;
			end
			if ( frameObject.showBuffTimer1 ) then
				if ( not txSpark ) then
					txSpark = frameDetails:CreateTexture(nil, "BORDER");
					txSpark:SetTexture("Interface\\CastingBar\\UI-CastingBar-Spark");
					txSpark:SetBlendMode("ADD");
					button.txSpark = txSpark;
				end
				if ( frameObject.showTimerBackground1 ) then
					if ( not txTimerBG ) then
						txTimerBG = frameDetails:CreateTexture(nil, "BACKGROUND");
						txTimerBG:SetTexture("Interface\\AddOns\\CT_BuffMod\\Images\\barSmooth");
						txTimerBG:SetHeight(frameObject.detailHeight1);
						button.txTimerBG = txTimerBG;
					end
				elseif ( txTimerBG ) then
					txTimerBG:Hide();
					txTimerBG = nil;
				end
			elseif ( txSpark ) then
				txSpark:Hide();
				txSpark = nil;
			end
		elseif ( txBackground ) then
			if (txSpark) then
				txSpark:Hide();
				txSpark = nil;
			end
			txBackground:Hide();
			txBackground = nil;
			if ( txTimerBG ) then
				txTimerBG:Hide();
				txTimerBG = nil;
			end
		end
		if ( frameObject.showNames1 ) then
			if ( not fsName ) then
				fsName = frameDetails:CreateFontString(nil, "ARTWORK", "GameFontNormal");
				fsName:SetWordWrap(false)
				button.fsName = fsName;
			end
			if (frameObject.fontSize) then
				if (frameObject.fontSize == 1 and fsName.font ~= "GameFontNormal") then
					fsName:SetFontObject("GameFontNormal");
					fsName.font = "GameFontNormal";
				elseif (frameObject.fontSize == 2 and fsName.font ~= "GameFontNormalSmall") then
					fsName:SetFontObject("GameFontNormalSmall");
					fsName.font = "GameFontNormalSmall";
				elseif (frameObject.fontSize == 3 and fsName.font ~= "CT_BuffMod_GameFontNormalMed2") then
					if (not CT_BuffMod_GameFontNormalMed2) then
						CreateFont("CT_BuffMod_GameFontNormalMed2");
						local fname, fsize, fargs = GameFontNormal:GetFont();
						CT_BuffMod_GameFontNormalMed2:SetFont(fname, fsize + 2, fargs);		-- GameFontLarge is just a bit too big
					end
					fsName:SetFontObject("CT_BuffMod_GameFontNormalMed2");
					fsName.font = "CT_BuffMod_GameFontNormalMed2";
				end
			end
		elseif ( fsName ) then
			fsName:Hide();
			fsName = nil;
		end

		if ( fsName and fsTimeleft and auraObject ) then
			if (not (auraObject.auraType == constants.AURATYPE_AURA or auraObject.auraType == constants.AURATYPE_CONSOLIDATED) ) then
--				if ( frameObject.detailHeight1 >= button.fsTimeleftHeight * 2 ) then
					if ( frameObject.durationLocation1 == constants.DURATION_LOCATION_BELOW ) then
						durationBelow = true;
					elseif ( frameObject.durationLocation1 == constants.DURATION_LOCATION_ABOVE ) then
						durationBelow = false;
					end
--				end
			end
		end
	end

	if (not auraObject) then
		if (txSpark) then
			txSpark:Hide();
		end
		if (txIcon) then
			txIcon:Hide();
		end
		if (txTimerBG) then
			txTimerBG:Hide();
		end
		if (txBackground) then
			txBackground:Hide();
		end
		if (fsTimeleft) then
			fsTimeleft:Hide();
		end
		if (fsName) then
			fsName:Hide();
		end
		if (frameDetails) then
			frameDetails:Hide();
		end
		if (button.fsCount) then
			button.fsCount:Hide();
		end
		return;
	end

	-- Set icon texture
	txIcon:SetTexture(auraObject.texture);
	if (auraObject.auraType == constants.AURATYPE_CONSOLIDATED) then
--		txIcon:SetTexCoord(0, 0.5, 0, 1);  -- original
--		txIcon:SetTexCoord(0.1, 0.4, 0.2, 0.8);  -- with border
		txIcon:SetTexCoord(0.155, 0.345, 0.310, 0.690);  -- no border
	elseif ((frameObject.buttonStyle == 1 and frameObject.normalIconBorder1) or (frameObject.buttonStyle == 2 and frameObject.normalIconBorder2)) then
		txIcon:SetTexCoord(0, 1, 0, 1);
	else
		txIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92);
	end

	-- Set icon border
	-- Consolidated button doesn't have a border.
	if (txBorder) then
		if (
			auraObject.auraType == constants.AURATYPE_DEBUFF
			and ((frameObject.buttonStyle == 1 and frameObject.colorCodeIcons1) or (frameObject.buttonStyle == 2 and frameObject.colorCodeIcons2))
		) then
			-- Show a color-coded border and symbol to emphasize the type of debuff
			local color;
			local debuffType = auraObject.debuffType;
			if ( debuffType ) then
				color = DebuffTypeColor[debuffType];
				if (not color) then
					color = DebuffTypeColor["none"];
				end
				if ( ENABLE_COLORBLIND_MODE == "1" ) then
					button.symbol:Show();
					button.symbol:SetText(DebuffTypeSymbol[debuffType] or "");
				else
					button.symbol:Hide();
				end
			else
				-- txBorder:SetVertexColor(1, 0.82, 0, 1);
				color = DebuffTypeColor["none"];
				button.symbol:Hide();
			end
			txBorder:SetVertexColor(color.r, color.g, color.b, 1);
		else
			-- Hide the border and symbol
			txBorder:SetVertexColor(0, 0, 0, 0);
			button.symbol:Hide();
		end
	end

	-- Update dimensions
	auraButton_updateDimensions(button);

	-- Position the elements
	if (frameObject.buttonStyle == 2) then
		-- Show icon and time remaining only.
		frameDetails:ClearAllPoints();
		frameDetails:SetPoint("TOPLEFT", button);
		if (fsTimeleft) then
			fsTimeleft:SetWidth(0);
			-- Update to the current time string
			auraButton_updateTimeDisplay(button);
			fsTimeleft:ClearAllPoints();
			fsTimeleft:Show();

			fsTimeleft:SetJustifyH("CENTER");

			local side = frameObject.dataSide2;
			local offset = frameObject.spacingFromIcon2;
			if (side == constants.DATA_SIDE_TOP) then
				fsTimeleft:SetPoint("BOTTOM", button, "TOP", 0, offset);  -- above icon
			elseif (side == constants.DATA_SIDE_RIGHT) then
				fsTimeleft:SetPoint("LEFT", button, "RIGHT", offset, 0);  -- right of icon
			elseif (side == constants.DATA_SIDE_BOTTOM) then
				fsTimeleft:SetPoint("TOP", button, "BOTTOM", 0, -offset);  -- below icon
			elseif (side == constants.DATA_SIDE_CENTER) then
				fsTimeleft:SetPoint("CENTER", button, "CENTER", 0, 0); -- middle of icon, without any offset
			else -- if (side == constants.DATA_SIDE_LEFT) then
				fsTimeleft:SetPoint("RIGHT", button, "LEFT", -offset, 0);  -- left of icon
			end
		end
	else
		-- Position elements within the detail frame and relative to the icon button.
		if ( fsName ) then
			fsName:SetText(auraObject.name);
		end
		if ( fsTimeleft and (auraObject.auraType == constants.AURATYPE_AURA or auraObject.auraType == constants.AURATYPE_CONSOLIDATED) ) then
			-- Don't show time remaining for auras.
			fsTimeleft:Hide();
			fsTimeleft = nil;
		end
		if (frameObject.detailWidth1 < mindetailWidth1) then
			if (fsName) then
				fsName:Hide();
				fsName = nil;
			end
			if (fsTimeleft) then
				fsTimeleft:Hide();
				fsTimeleft = nil;
			end
		end
		if (fsName) then
			fsName:ClearAllPoints();
		end

		if (fsTimeleft) then
			fsTimeleft:SetWidth(0);
			-- Update to the current time string
			auraButton_updateTimeDisplay(button);
			fsTimeleft:ClearAllPoints();
		end

		local point1, point2;
		if (frameObject.rightAlignIcon1) then
			-- Show the icon on the right side
			point1 = "RIGHT";
			point2 = "LEFT";
		else
			-- Show the icon on the left side
			point1 = "LEFT";
			point2 = "RIGHT";
		end

		frameDetails:ClearAllPoints();
		frameDetails:SetPoint(point1, button, point2);

		if (fsName and fsTimeleft) then
			-- Show name and time remaining
			if (durationBelow == true) then
				-- Show time below the name
				if (justifyH(fsName, frameObject.nameJustifyNoTime1, point1)) then
					fsName:SetPoint("BOTTOMLEFT", frameDetails, "LEFT");
					fsName:SetPoint("RIGHT", frameDetails, "RIGHT");
				else
					fsName:SetPoint("BOTTOMLEFT", frameDetails, "LEFT", spacingOnLeft1, 0);
					fsName:SetPoint("RIGHT", frameDetails, "RIGHT", -spacingOnRight1, 0);
				end

				if (justifyH(fsTimeleft, frameObject.timeJustifyNoName1, point1)) then
					fsTimeleft:SetPoint("TOPLEFT", frameDetails, "LEFT");
					fsTimeleft:SetPoint("RIGHT", frameDetails, "RIGHT");
				else
					fsTimeleft:SetPoint("TOPLEFT", frameDetails, "LEFT", spacingOnLeft1, 0);
					fsTimeleft:SetPoint("RIGHT", frameDetails, "RIGHT", -spacingOnRight1, 0);
				end

				fsName:Show();
				fsTimeleft:Show();

			elseif (durationBelow == false) then
				-- Show time above the name
				if (justifyH(fsTimeleft, frameObject.timeJustifyNoName1, point1)) then
					fsTimeleft:SetPoint("BOTTOMLEFT", frameDetails, "LEFT");
					fsTimeleft:SetPoint("RIGHT", frameDetails, "RIGHT");
				else
					fsTimeleft:SetPoint("BOTTOMLEFT", frameDetails, "LEFT", spacingOnLeft1, 0);
					fsTimeleft:SetPoint("RIGHT", frameDetails, "RIGHT", -spacingOnRight1, 0);
				end

				if (justifyH(fsName, frameObject.nameJustifyNoTime1, point1)) then
					fsName:SetPoint("TOPLEFT", frameDetails, "LEFT");
					fsName:SetPoint("RIGHT", frameDetails, "RIGHT");
				else
					fsName:SetPoint("TOPLEFT", frameDetails, "LEFT", spacingOnLeft1, 0);
					fsName:SetPoint("RIGHT", frameDetails, "RIGHT", -spacingOnRight1, 0);
				end

				fsName:Show();
				fsTimeleft:Show();

			else
				-- Show time beside the name
				button.timeleftFlag = true;
				auraButton_updateTimeNameSpecial(button);
			end

		elseif (fsName) then
			-- Show name only
			if (justifyH(fsName, frameObject.nameJustifyNoTime1, point1)) then
				fsName:SetPoint("LEFT", frameDetails, "LEFT");
				fsName:SetPoint("RIGHT", frameDetails, "RIGHT");
			else
				fsName:SetPoint("LEFT", frameDetails, "LEFT", spacingOnLeft1, 0);
				fsName:SetPoint("RIGHT", frameDetails, "RIGHT", -spacingOnRight1, 0);
			end
			fsName:Show();

		elseif (fsTimeleft) then
			-- Show time remaining only
			if (justifyH(fsTimeleft, frameObject.timeJustifyNoName1, point1)) then
				fsTimeleft:SetPoint("LEFT", frameDetails, "LEFT");
				fsTimeleft:SetPoint("RIGHT", frameDetails, "RIGHT");
			else
				fsTimeleft:SetPoint("LEFT", frameDetails, "LEFT", spacingOnLeft1, 0);
				fsTimeleft:SetPoint("RIGHT", frameDetails, "RIGHT", -spacingOnRight1, 0);
			end
			fsTimeleft:Show();
		end

		if ( txBackground ) then
			txBackground:ClearAllPoints();
			txBackground:SetPoint(point1, frameDetails, point1);
			if ( txSpark ) then
				txSpark:ClearAllPoints();
				txSpark:SetPoint("CENTER", txBackground, point2);
			end
			if ( txTimerBG ) then
				txTimerBG:ClearAllPoints();
				txTimerBG:SetPoint(point2, frameDetails, point2);
				txTimerBG:Show();
			end
		end
	end

	-- Set background, color, spark, timer
	if ( txBackground ) then
		txBackground:Show();

		-- Set our color
		if ( fsName ) then
			fsName:SetTextColor(1, 0.82, 0);
		end

		if (auraObject.auraType == constants.AURATYPE_DEBUFF) then
			if (
				(frameObject.buttonStyle == 1 and not frameObject.colorCodeBackground1)
			) then
				local color = backgroundColors[auraObject.auraType];
				txBackground:SetVertexColor(unpack(color));
			else
				local color;
				local debuffType = auraObject.debuffType;
				if ( debuffType ) then
					color = DebuffTypeColor[debuffType];
					if (not color) then
						color = DebuffTypeColor["none"];
					end
				else
					color = DebuffTypeColor["none"];
				end
				txBackground:SetVertexColor(color.r, color.g, color.b);
			end
		else
			local color = backgroundColors[auraObject.auraType];
			txBackground:SetVertexColor(unpack(color));
		end

		-- Set background & spark
		if ( frameObject.detailWidth1 < mindetailWidth1 ) then
			txBackground:Hide();
			if (txTimerBG) then
				txTimerBG:Hide();
			end
			if ( txSpark ) then
				txSpark:Hide();
			end
		elseif (
			auraObject.auraType == constants.AURATYPE_AURA or
			auraObject.auraType == constants.AURATYPE_CONSOLIDATED or
			not frameObject.showBuffTimer1
		) then
			txBackground:SetWidth(frameObject.detailWidth1);
			if (txTimerBG) then
				txTimerBG:Hide();
			end
			if ( txSpark ) then
				txSpark:Hide();
			end
		else
			if ( txTimerBG ) then
				local r, g, b, a = txBackground:GetVertexColor();
				txTimerBG:SetVertexColor(r/1.35, g/1.35, b/1.35, a/2);
				txTimerBG:Show();
			end
			auraButton_updateTimerBar(button);
		end
	end

	-- Set color of the name.
	if (fsName) then
		if (auraObject.auraType == constants.AURATYPE_DEBUFF) then
			if ( frameObject.colorCodeDebuffs1 ) then
				local debuffType = auraObject.debuffType;
				if ( debuffType ) then
					local color = DebuffTypeColor[debuffType];
					if (color) then
						fsName:SetTextColor(color.r, color.g, color.b);
					else
						fsName:SetTextColor(1, 0.82, 0);
					end
				else
					fsName:SetTextColor(1, 0.82, 0);
				end
			elseif ( txBackground ) then
				fsName:SetTextColor(1, 0.82, 0);
			else
				fsName:SetTextColor(1, 0, 0);
			end
		else
			fsName:SetTextColor(1, 0.8, 0, 1);
		end
	end

	-- Update count
	local fsCount;
	fsCount = button.fsCount;
	if (auraObject.count and auraObject.count > 1) then
		if (not fsCount) then
			fsCount = button:CreateFontString(nil, "OVERLAY", "NumberFontNormalSmall");
			fsCount:SetWordWrap(false)
			fsCount:SetPoint("BOTTOMRIGHT", button, module:getGameVersion() >= 10 and 2 or 5, 0);
			--fsCount:SetFont("ARIALN.TTF", 12, ""); -- "MONOCHROME");
		end
		fsCount:SetText(auraObject.count);
		button.fsCount = fsCount;
	elseif (fsCount) then
		fsCount:SetText("");
	end

	-- Force an update of the frequently changing properties.
	auraButton_Update(button);
end

-- The following CT_BuffMod_AuraButton_* functions need to be global since they are called from the .xml templates.

function CT_BuffMod_AuraButton_OnShow(self)
	if (not self.ctinit) then
		self.ctinit = true;
		self:RegisterForClicks("RightButtonDown", "LeftButtonDown", "RightButtonUp");
			-- alt-LeftButtonDown will always insecurely select a window
			-- either RightButtonDown or RightButtonUp may trigger based on ActionButtonUseKeyDown (from WoW 10.0 onwards)
		auraButton_Update(self);
	end
end

function CT_BuffMod_AuraButton_OnHide(self)
	if (self.ticker) then
		self.ticker:Cancel();
		self.ticker = nil;
	end
end

-- bottom-left corner of the icon tooltip, showing the user how to configure CT_BuffMod
local tooltipFooterRight = GameTooltip:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall");
tooltipFooterRight:SetScale(0.9);
tooltipFooterRight:SetTextColor(0.5, 0.5, 0.5);
tooltipFooterRight:SetText("/ctbuff to configure");
tooltipFooterRight:SetPoint("BOTTOMRIGHT", -6, 6);
tooltipFooterRight:Hide();

-- bottom-left corner of the icon tooltip, showing the spellID
local tooltipFooterLeft = GameTooltip:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall");
tooltipFooterLeft:SetScale(0.9);
tooltipFooterLeft:SetTextColor(0.5, 0.5, 0.5);
tooltipFooterLeft:SetText("");
tooltipFooterLeft:SetPoint("BOTTOMLEFT", 12, 6);
tooltipFooterLeft:Hide();

function CT_BuffMod_AuraButton_OnEnter(self)
	-- Show tooltip for the aura/enchant.
	local frameObject = self.frameObject;
	local auraObject = self.auraObject;
	if (not auraObject) then
		return;
	end

	local index = self.index;
	local filter = self.filter;

	if ( auraObject.auraType == constants.AURATYPE_CONSOLIDATED ) then
		return;
	end
	
	if (frameObject.disableTooltips) then
		if ( (isOptionsFrameShown() or isControlPanelShown()) and frameObject:getWindowId() ) then
			-- See also the auraFrame OnEnter script.
			GameTooltip:SetOwner(self, "ANCHOR_CURSOR");
			GameTooltip:SetText(format(L["CT_BuffMod/WindowTitle"],frameObject:getWindowId()));
			GameTooltip:AddLine(L["CT_BuffMod/Options/WindowControls/AltClickHint"]);
			GameTooltip:Show();
		end
		return;
	end

	local cursorX = GetCursorPosition();
	local centerX = UIParent:GetCenter();
	centerX = centerX * UIParent:GetScale();
	if (cursorX < centerX) then
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
	else
		GameTooltip:SetOwner(self, "ANCHOR_LEFT");
	end
	if ( auraObject.auraType == constants.AURATYPE_ENCHANT ) then
		GameTooltip:SetInventoryItem("player", filter);
	else
		if GameTooltip.SetUnitAura then
			GameTooltip:SetUnitAura(frameObject:getUnitId(), index, filter);
		elseif C_TooltipInfo and C_TooltipInfo.GetUnitAura then
			-- Modern method for Dragonflight and onward
			GameTooltip:SetResult(C_TooltipInfo.GetUnitAura(frameObject:getUnitId(), index, filter));
		end
		do
			-- casterName can be a restricted "secret string" in combat; ctSafe -> nil if unusable so we
			-- don't crash comparing/displaying it (caster line is simply omitted while it's restricted).
			local casterName = ctSafe(auraObject.casterName);
			if (casterName == UNKNOWN) then
				auraObject:setCasterUnit(auraObject.casterUnit);
				casterName = ctSafe(auraObject.casterName);
			end
			if (casterName) then
				GameTooltip:AddLine(casterName)
			end
		end
	end
	if (isOptionsFrameShown() or isControlPanelShown()) then
		GameTooltip:AddLine(format(L["CT_BuffMod/WindowTitle"],frameObject:getWindowId()) .. " (" .. L["CT_BuffMod/Options/WindowControls/AltClickHint"] .. ")");
		GameTooltip:Show();
	else
		GameTooltip:Show();
		tooltipFooterRight:Show();
		if (auraObject.spellId and auraObject.auraType ~= constants.AURATYPE_ENCHANT) then
			tooltipFooterLeft:Show();
			tooltipFooterLeft:SetText("Spell ID: " .. auraObject.spellId);
		end
		GameTooltip:SetSize(max(GameTooltip:GetWidth(),180),GameTooltip:GetHeight()+5);
	end
	
	C_Timer.After(0.5, function()
		if (GameTooltip:IsOwned(self)) then
			CT_BuffMod_AuraButton_OnEnter(self);
		end
	end);
end

function CT_BuffMod_AuraButton_OnLeave(self)
	-- Hide aura/enchant tooltip.
	GameTooltip:Hide();
	tooltipFooterRight:Hide();
	tooltipFooterLeft:Hide();
end

function CT_BuffMod_AuraButton_OnMouseDown(self, button)
	local frameObject = self.frameObject;
	if (frameObject) then
		if (button == "LeftButton") then
			if (IsAltKeyDown()) then
				-- Open the options window and select the correct window.
				module:options_editWindow(frameObject:getWindowId());
			else
				-- The :startMoving method tests for combat, locked window, etc.
				frameObject:startMoving();
			end
		elseif (button == "RightButton" and frameObject.useUnsecure and InCombatLockdown() == false and C_CVar.GetCVar("ActionButtonUseKeyDown") == "1") then
			local auraObject = self.auraObject;
			if (not auraObject) then
				return;
			end
			local auraType = auraObject.auraType;
			if auraType == constants.AURATYPE_BUFF or auraType == constants.AURATYPE_AURA then
				CancelUnitBuff(frameObject:getUnitId(), self.index, self.filter);
			end
		end
	end
end

function CT_BuffMod_AuraButton_OnMouseUp(self, button)
	local frameObject = self.frameObject;
	if (frameObject) then
		if (button == "LeftButton") then
			frameObject:stopMoving();
		elseif (button == "RightButton") then
			if (frameObject.useUnsecure) then
				local auraObject = self.auraObject;
				if (not auraObject) then
					return;
				end
				local auraType = auraObject.auraType;
				if self:IsMouseOver() and C_CVar.GetCVar("ActionButtonUseKeyDown") ~= "1" and (auraType == constants.AURATYPE_BUFF or auraType == constants.AURATYPE_AURA) then
					-- CancelUnitBuff() can now be called from unsecure code when not in combat.
					if (not InCombatLockdown()) then
						CancelUnitBuff(frameObject:getUnitId(), self.index, self.filter);
					end
				elseif ( auraType == constants.AURATYPE_ENCHANT ) then
					-- CancelItemTempEnchantment() can still only be called from secure code.
					--CancelItemTempEnchantment(self.index);
				end
			end
		end
	end
end


--------------------------------------------
-- Frame class (virtual)
--
--	This implements routines used by the primary and consolidated
--	classes, which are used to display a frame containing buff
--	buttons.
--
-- Inherits fron:
-- 	None
--
-- Inherited by:
--
--	primaryClass
--	consolidatedClass
--
-- Class object overview:
--
--	(frameClassObject)
--		.meta
--
-- Object overview:
--
--	(frameObject)
--		.classObject
--		+other properties
--
-- Properties:
--
--	.classObject
--	.isConsolidated -- Is this object a consolidated object (true == yes, false or nil == no)
--	.parent -- Parent object
--
-- Frame specific properties (P==Protected option):
--
-- P	.buffSpacing -- Spacing between adjacent buttons (number, default is 0)
-- P	.buttonStyle -- (1==Icon and bar, 2==Icon and time)
--  	.clampWindow -- Window cannot be moved off screen (1==yes, false==no, default == yes)
-- P	.layoutType -- Layout type (number, 1 to 8, default is constants.DEFAULT_LAYOUT) (see LAYOUT_*)
-- P	.lockWindow -- Lock window to prevent dragging (1==yes, false==no, default == no)
-- P	.maxWraps -- Maximum number of wraps (number, 0 == variable, default is constants.DEFAULT_MAX_WRAPS)
--  	.showBackground -- Show window background (1==yes, false==no, default == yes)
--  	.showBorder -- Show window border (1==yes, false == no, default == no)
--  	.useCustomBackgroundColor -- Use window specific background color instead of the global one (1==yes, false==no, default==no)
--  	.userEdgeLeft - Left border size (between border texture and .auraEdgeLeft area) (number, default == 0)
--  	.userEdgeRight - Right border size (between border texture and .auraEdgeRight area) (number, default == 0)
--  	.userEdgeTop - Top border size (between border texture and .auraEdgeTop area) (number, default == 0)
--  	.userEdgeBottom - Bottom border size (between border texture and .auraEdgeBottom area) (number, default == 0)
--  	.windowBackgroundColor -- Color of the window's background (table: 1=Red value, 2=Green value, 3==Blue value, 4==Alpha value)
-- P	.wrapAfter -- Number of icons to show before wrapping occurs (number, default == constants.DEFAULT_WRAP_AFTER)
-- P	.wrapSpacing -- Spacing between adjacent rows/columns (number, default == 0)
--
-- Button style 1 properties (P==Protected option):
--
-- P	.buffSize1 -- Height and width of the icon. Also height of the button (default is constants.BUFF_SIZE_DEFAULT).
--  	.colorBuffs1 -- Color the button backgrounds (1==yes, false==no, default == yes)
--  	.colorCodeBackground1 -- Color code bar background of debuffs (1 == yes, false == no, default == no)
--  	.colorCodeDebuffs1 -- Color code debuffs (1 == yes, false == no, default == no)
--  	.colorCodeIcons1 -- Color code border of debuff icons (1 == yes, false == no, default == no)
-- P	.detailHeight1 -- (calculated) Height of the detail frame where buff name and time is shown
-- P	.detailWidth1 -- Width of the detail frame where buff name and time is shown (default is 255).
--  	.durationFormat1 -- Format used to display time remaining text (style 1) (1=="1 hour/35 minutes", 2=="1 hour/35 min", 3=="1h/35m", 4=="1h 35m/35m 15s", 5=="1:35h/35:15", default == "1 hour/35 minutes")
--  	.durationFunc1 -- (calculated) Function used to get a formatted time for the time remaining (style 1)
--  	.durationLocation1 -- Where to display the time remaining text (1==Default, 1==Left of name, 2==Right of name, 3==Above name, 4==Below name, default == default)
--  	.nameJustifyNoTime1 -- Justification of name when time is not shown beside it (1==Default, 2==Left, 3==Right, 4==Center, default==Default) (see constants.JUSTIFY_*)
--  	.nameJustifyWithTime1 -- Justification of name when time is shown beside it (1==Default, 2==Left, 3==Right, 4==Center, default==Default) (see constants.JUSTIFY_*)
--  	.normalIconBorder1 -- Show a border around the icon all the time (1 == yes, false == no, default == no)
-- P	.rightAlign1 -- Which side of detail frame to show the icon (1==Default, 2==Left, 3==Right, default == 1) (see constants.RIGHT_ALIGN_*)
-- P	.rightAlignDef1 -- (calculated) Default side the icon is on for the current layout (false == left, true == right)
-- P	.rightAlignIcon1 -- (calculated) Current side the icon is to be shown on (false == left, true == right)
--  	.showBuffTimer1 -- Show graphic timer bar (1 == yes, false == no, default == yes)
--  	.showNames1 -- Show aura name (1 == yes, false == no, default == yes)
--  	.showTimerBackground1 -- Show timer background (1 == yes, false == no, default == yes)
--  	.showTimers1 -- Show time remaining as text (style 1) (1 == yes, false == no, default == yes)
--  	.spacingOnRight1 -- Distance between right side of detail frame and text (number, default == 0)
--  	.spacingOnLeft1 -- Distance between left side of detail frame and text (number, default == 0)
--  	.timeJustifyNoName1 -- Justification of time when name is not shown beside it (1==Default, 2==Left, 3==Right, 4==Center, default==Default) (see constants.JUSTIFY_*)
--
-- Buton style 2 properties (P==Protected option):
--
-- P	.buffSize2 -- Height and width of the icon. Also height of the button (default is constants.BUFF_SIZE_DEFAULT).
--  	.colorCodeIcons2 -- Color code border of debuff icons (1 == yes, false == no, default == no)
--  	.dataSide2 -- Side of button to display time remaining text (1==Top, 2==Right, 3==Bottom, 4==Left) (see constants.DATA_SIDE_*)
--  	.durationFormat2 -- Format used to display time remaining text (style 2) (1=="1 hour/35 minutes", 2=="1 hour/35 min", 3=="1h/35m", 4=="1h 35m/35m 15s", 5=="1:35h/35:15", default == "1 hour/35 minutes")
--  	.durationFunc2 -- (calculated) Function used to get a formatted time for the time remaining (style 2)
--  	.normalIconBorder2 -- Show a border around the icon all the time (1 == yes, false == no, default == no)
--  	.showTimers2 -- Show time remaining as text (style 2) (1 == yes, false == no, default == yes)
--  	.spacingFromIcon2 -- Distance between icon and text (Style 2) (number, default == 0)
--
-- Other values (often determined by other options, etc) (list may not be complete):
--
-- 	.anchorToEdgeLeft -- Distance from aura frame anchor point to left edge of alt frame.
-- 	.anchorToEdgeRight -- Distance from aura frame anchor point to right edge of alt frame.
-- 	.anchorToEdgeTop -- Distance from aura frame anchor point to top edge of alt frame.
-- 	.anchorToEdgeBottom -- Distance from aura frame anchor point to bottom edge of alt frame.
--	.auraFrame -- Current frame being used to display the aura buttons in (if nil then frame has not been created yet)
--	.auraButtonTemplate -- Name of XML template to use for aura buttons.
--	.auraEdgeLeft - Size of area to the left of the aura frame, and right of the .userEdgeLeft area.
--	.auraEdgeRight - Size of area to the right of the aura frame, and left of the .userEdgeRight area.
--	.auraEdgeTop - Size of area above the aura frame, and below the .userEdgeTop area.
--	.auraEdgeBottom - Size of he area below the aura frame, and above the .userEdgeBottom area.
--	.auraFrameTemplate -- Name of XML template to use for aura frame.
--	.borderSize -- Size of the border texture
--	.buttonHeight -- Height of the "button" used for each buff (this is the same as .buffSize)
--	.buttonWidth -- Width of the "button" used for each buff (for style 1 this includes the .detailWidth1 value)
--	.fontSize -- Toggles the button's fonts (both types) between normal (1), small (2) and large (3) font sizes
--   	.needUpdate -- Flag checked in aura frame's OnUpdate script to force visual update of frame contents (true == yes, nil or false == no)
--	.useUnsecure -- Use unsescure frame and buttons (1==yes, false==no)
--
-- Methods and functions:
--	:new()
--
--	:getParent()
--	:setParent(parentObject)
--
--	:getWindowId()
--	:getUnitId()
--	:setUnitId(unitId)
--
--	:calculateAnchorToEdge();
--	:applyOtherOptions(initFlag)
--	:applyUnprotectedOptions(initFlag)
--	:applyProtectedOptions()
--
--	:setDefaultOptions()
--	:setAttributes()
--	:getAuraButtonTemplate()
--
--	:setBorder()
--	:setBackground()
--	:setClamped()
--
--	:savePosition()
--	:restorePosition(ignoreHW)
--	:resetPosition()
--	:setAnchorPoint(keepOnScreen)
--
--	:resizeSpellButtons()
--	:hideSpellButtons()
--	:updateSpellButtons(func)
--	:refreshAuraButtons()
--
--	:startMoving(frame, button)
--	:stopMoving(frame, button)
--
--	:enableMouse()
--	:altFrameEnableMouse(enable)
--	:getOldAuraFrameTable()
--	:createAuraFrame()
--	:setAltFrameScripts()
--	:createAltFrame()
--	:setAuraFrameScripts()
--	:createConsolidatedButton()
--	:createWeaponButtons()
--	:shrinkAndCenterAuraFrame()
--
--	:registerAuraFrameEvents()
--	:unregisterAuraFrameEvents()
--	:registerStateDrivers()
--	:unregisterStateDrivers()
--	:createStateFrame()
--	:createBuffFrame()
--	:deleteBuffFrame()
--
--	:updateSpells(unitId)
--	:updateEnchants(unitId)
--	:updateSpellsAndEnchants(unitId)

-- Local data used by this object

-- Tables containing previously used aura frames and current .serial values.
local oldSecurePrimaryFrames = {};
local oldSecureConsolidatedFrames= {};
local oldUnsecurePrimaryFrames = {};
local oldUnsecureConsolidatedFrames = {};

local tooltipBackdrop = {
	bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
	edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
	tile = true,
	tileSize = 16,
	edgeSize = 16,
	insets = { left = 0, right = 0, top = 0, bottom = 0 }
};
local tooltipBackdrop2 = {
	bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
	edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
	tile = true,
	tileSize = 16,
	edgeSize = 16,
	insets = { left = 4, right = 4, top = 4, bottom = 4 }
};


-- Create the class object.
local frameClass = {};

frameClass.meta = { __index = frameClass };
frameClass.super = frameClass.classObject;

function frameClass:new()
	-- Create an object of this class.
	local object = {};
	object.classObject = self;
	setmetatable(object, self.meta);

	return object;
end

function frameClass:getParent()
	return self.parent;
end

function frameClass:setParent(parentObject)
	self.parent = parentObject;
end

function frameClass:getWindowId()
	-- The window id is in the window object (the primary object's parent object)
	return self.parent:getWindowId();
end

function frameClass:getUnitId()
	-- The unit id is in the primary object (the consolidated object's parent object)
	return self.parent:getUnitId();
end

function frameClass:setUnitId(unitId)
	return self.parent:setUnitId(unitId);
end

function frameClass:calculateAnchorToEdge()
	self.anchorToEdgeLeft = (self.auraEdgeLeft or 0) + self.userEdgeLeft + self.borderSize;
	self.anchorToEdgeRight = (self.auraEdgeRight or 0) + self.userEdgeRight + self.borderSize;
	self.anchorToEdgeTop = (self.auraEdgeTop or 0) + self.userEdgeTop + self.borderSize;
	self.anchorToEdgeBottom = (self.auraEdgeBottom or 0) + self.userEdgeBottom + self.borderSize;
end

function frameClass:applyOtherOptions(initFlag)
	-- Apply other options that don't require us to be out of combat.
	-- initFlag -- true if we should only initialize the object's properties (no display updates, etc).

	local frameOptions = self:getOptions();

	self.showBorder = not not frameOptions.showBorder;
	if (not initFlag) then
		self:setBorder();
	end

	self.showBackground = frameOptions.showBackground ~= false;
	self.useCustomBackgroundColor = not not frameOptions.useCustomBackgroundColor;

	local color = frameOptions.windowBackgroundColor;
	if (type(color) ~= "table") then
		color = defaultWindowColor;
	end
	if (type(self.windowBackgroundColor) ~= "table") then
		self.windowBackgroundColor = {};
	end
	for i = 1, 4 do
		self.windowBackgroundColor[i] = color[i];
	end
	if (not initFlag) then
		self:setBackground();
	end

	self.clampWindow = frameOptions.clampWindow ~= false;
	if (not initFlag) then
		self:setClamped();
	end

	if (not initFlag) then
		self.needUpdate = true;
	end
end

function frameClass:applyUnprotectedOptions(initFlag)
	-- Apply button options that don't require us to be out of combat.
	-- initFlag -- true if we should only initialize the object's properties (no display updates, etc).

	local frameOptions = self:getOptions();

	self.borderSize = 4;

	self.userEdgeLeft = frameOptions.userEdgeLeft or 0;
	self.userEdgeRight = frameOptions.userEdgeRight or 0;
	self.userEdgeTop = frameOptions.userEdgeTop or 0;
	self.userEdgeBottom = frameOptions.userEdgeBottom or 0;

	self:calculateAnchorToEdge();

	self.colorBuffs1 = frameOptions.colorBuffs1 ~= false;
	self.colorCodeDebuffs1 = not not frameOptions.colorCodeDebuffs1;
	self.colorCodeIcons1 = not not frameOptions.colorCodeIcons1;
	self.colorCodeIcons2 = not not frameOptions.colorCodeIcons2;
	self.colorCodeBackground1 = not not frameOptions.colorCodeBackground1;
	self.normalIconBorder1 = not not frameOptions.normalIconBorder1;
	self.normalIconBorder2 = not not frameOptions.normalIconBorder2;

	local func, value;

	self.durationFormat1 = frameOptions.durationFormat1 or 1;
	value = self.durationFormat1;
	if (value == 1) then
		func = timeFormat1;
	elseif (value == 2) then
		func = timeFormat2;
	elseif (value == 3) then
		func = timeFormat3;
	elseif (value == 4) then
		func = timeFormat4;
	elseif (value == 5) then
		func = timeFormat5;
	else
		func = timeFormat1;
	end
	self.durationFunc1 = func;

	self.durationFormat2 = frameOptions.durationFormat2 or 1;
	value = self.durationFormat2;
	if (value == 1) then
		func = timeFormat1;
	elseif (value == 2) then
		func = timeFormat2;
	elseif (value == 3) then
		func = timeFormat3;
	elseif (value == 4) then
		func = timeFormat4;
	elseif (value == 5) then
		func = timeFormat5;
	else
		func = timeFormat1;
	end
	self.durationFunc2 = func;

	self.dataSide2 = frameOptions.dataSide2 or constants.DATA_SIDE_BOTTOM;
	self.durationLocation1 = frameOptions.durationLocation1 or constants.DURATION_LOCATION_DEFAULT;
	self.showBuffTimer1 = frameOptions.showBuffTimer1 ~= false;
	self.showNames1 = frameOptions.showNames1 ~= false;
	self.showTimers1 = frameOptions.showTimers1 ~= false;
	self.showTimers2 = frameOptions.showTimers2 ~= false;
	self.showTimerBackground1 = frameOptions.showTimerBackground1 ~= false;
	self.spacingFromIcon2 = frameOptions.spacingFromIcon2 or 0;
	self.spacingOnRight1 = frameOptions.spacingOnRight1 or 0;
	self.spacingOnLeft1 = frameOptions.spacingOnLeft1 or 0;
	self.nameJustifyWithTime1 = frameOptions.nameJustifyWithTime1 or constants.JUSTIFY_DEFAULT;
	self.nameJustifyNoTime1 = frameOptions.nameJustifyNoTime1 or constants.JUSTIFY_DEFAULT;
	self.timeJustifyNoName1 = frameOptions.timeJustifyNoName1 or constants.JUSTIFY_DEFAULT;
	self.showDays1 = frameOptions.showDays1 ~= false;
	self.showDays2 = frameOptions.showDays2 ~= false;
	self.fontSize = frameOptions.fontSize;

	if (not initFlag) then
		self.needUpdate = true;
	end
end

function frameClass:applyProtectedOptions(initFlag)
	-- initFlag -- true if we should only initialize the object's properties (no display updates, etc).

	local frameOptions = self:getOptions();

	local auraFrame = self.auraFrame;

	self.buffSpacing = frameOptions.buffSpacing or 0;
	self.wrapSpacing = frameOptions.wrapSpacing or 0;

	-- Get some info before assigning button style.
	local oldSize;

	if (self.buttonStyle == 2) then
		oldSize = self.buffSize2;
	else
		oldSize = self.buffSize1;
	end

	-- Change the button style
	self.buttonStyle = frameOptions.buttonStyle or 1;

	-- Buff size
	local newSize;

	newSize = frameOptions.buffSize1 or constants.BUFF_SIZE_DEFAULT;
	if (newSize < constants.BUFF_SIZE_MINIMUM) then
		newSize = constants.BUFF_SIZE_MINIMUM;
	elseif (newSize > constants.BUFF_SIZE_MAXIMUM) then
		newSize = constants.BUFF_SIZE_MAXIMUM;
	end
	self.buffSize1 = newSize;

	newSize = frameOptions.buffSize2 or constants.BUFF_SIZE_DEFAULT;
	if (newSize < constants.BUFF_SIZE_MINIMUM) then
		newSize = constants.BUFF_SIZE_MINIMUM;
	elseif (newSize > constants.BUFF_SIZE_MAXIMUM) then
		newSize = constants.BUFF_SIZE_MAXIMUM;
	end
	self.buffSize2 = newSize;

	-- Get new info after assigning button style
	if (self.buttonStyle == 2) then
		newSize = self.buffSize2;
	else
		newSize = self.buffSize1;
	end

	if (auraFrame and oldSize ~= newSize) then
		-- Resize existing buttons to match the new size.
		self:resizeButtons();
	end

	if (self.buttonStyle == 2) then
		self.buttonHeight = self.buffSize2;
		self.buttonWidth = self.buffSize2;
	else
		self.detailWidth1 = frameOptions.detailWidth1;
		if (not self.detailWidth1) then
			self.detailWidth1 = constants.DEFAULT_DETAIL_WIDTH;
		end

		self.detailHeight1 = self.buffSize1;

		-- Detail frame is on right or left.
		if (self.detailHeight1 > self.buffSize1) then
			self.buttonHeight = self.detailHeight1;
		else
			self.buttonHeight = self.buffSize1;
		end

		self.buttonWidth = self.buffSize1 + self.detailWidth1;
	end

	self.auraEdgeLeft = frameOptions.auraEdgeLeft or 0;
	self.auraEdgeRight = frameOptions.auraEdgeRight or 0;
	self.auraEdgeTop = frameOptions.auraEdgeTop or 0;
	self.auraEdgeBottom = frameOptions.auraEdgeBottom or 0;

	self.layoutType = frameOptions.layoutType or constants.DEFAULT_LAYOUT;

	self.rightAlign1 = tonumber(frameOptions.rightAlign1) or constants.RIGHT_ALIGN_DEFAULT;

	-- Determine the self.rightAlignDef1 value such that it corresponds with the way the buttons grow and wrap.
	if (self.layoutType == constants.LAYOUT_GROW_LEFT_WRAP_UP or self.layoutType == constants.LAYOUT_GROW_LEFT_WRAP_DOWN) then
		-- Grow left, so default icon to the right side
		self.rightAlignDef1 = true;

	elseif (self.layoutType == constants.LAYOUT_GROW_RIGHT_WRAP_UP or self.layoutType == constants.LAYOUT_GROW_RIGHT_WRAP_DOWN) then
		-- Grow right, so default icon to the left side
		self.rightAlignDef1 = false;
	else
		-- Grow up or down
		if (self.layoutType == constants.LAYOUT_GROW_UP_WRAP_LEFT or self.layoutType == constants.LAYOUT_GROW_DOWN_WRAP_LEFT) then
			-- Wrap left, so default icon to the right side
			self.rightAlignDef1 = true;
		else
			-- Wrap right, so default icon to the left side
			self.rightAlignDef1 = false;
		end
	end

	-- Determine if the icon should be on the right side or not.
	if (self.rightAlign1 == constants.RIGHT_ALIGN_NO) then
		self.rightAlignIcon1 = false;
	elseif (self.rightAlign1 == constants.RIGHT_ALIGN_YES) then
		self.rightAlignIcon1 = true;
	else
		self.rightAlignIcon1 = self.rightAlignDef1;
	end

	-- Bug: Blizzard's code causes divide by nil error if you try to use nil or 0 for wrapAfter.
	--
	-- 	Note: As of WoW 4.3 they have fixed this bug.
	--
	self.wrapAfter = frameOptions.wrapAfter or constants.DEFAULT_WRAP_AFTER;

	self.maxWraps = frameOptions.maxWraps or constants.DEFAULT_MAX_WRAPS;

	self.lockWindow = not not frameOptions.lockWindow;
	if (not initFlag) then
		if (auraFrame) then
			-- Possibly enable the mouse in the alt frame.
			self:enableMouse();
		end
	end

	-- Calculate some values (needed by :SetAttributes(), etc).
	local point;
	local minWidth, minHeight;
	local growUpDown;

	local layoutType = self.layoutType;
	local xOffset = self.buttonWidth + self.buffSpacing;
	local yOffset = self.buttonHeight + self.buffSpacing;
	local wrapXOffset = self.buttonWidth + self.wrapSpacing;
	local wrapYOffset = self.buttonHeight + self.wrapSpacing;

	if (layoutType == constants.LAYOUT_GROW_RIGHT_WRAP_DOWN) then
		point = "TOPLEFT";
		wrapYOffset = -wrapYOffset;

	elseif (layoutType == constants.LAYOUT_GROW_RIGHT_WRAP_UP) then
		point = "BOTTOMLEFT";

	elseif (layoutType == constants.LAYOUT_GROW_LEFT_WRAP_DOWN) then
		point = "TOPRIGHT";
		xOffset = -xOffset;
		wrapYOffset = -wrapYOffset;

	elseif (layoutType == constants.LAYOUT_GROW_LEFT_WRAP_UP) then
		point = "BOTTOMRIGHT";
		xOffset = -xOffset;

	elseif (layoutType == constants.LAYOUT_GROW_UP_WRAP_LEFT) then
		point = "BOTTOMRIGHT";
		wrapXOffset = -wrapXOffset;
		growUpDown = true;

	elseif (layoutType == constants.LAYOUT_GROW_UP_WRAP_RIGHT) then
		point = "BOTTOMLEFT";
		growUpDown = true;

	elseif (layoutType == constants.LAYOUT_GROW_DOWN_WRAP_LEFT) then
		point = "TOPRIGHT";
		yOffset = -yOffset;
		wrapXOffset = -wrapXOffset;
		growUpDown = true;

	else -- if (layoutType == constants.LAYOUT_GROW_DOWN_WRAP_RIGHT) then
		point = "TOPLEFT";
		yOffset = -yOffset;
		growUpDown = true;

	end

	local reverse;
	if (self.buttonStyle == 1) then
		-- If (icon on right by default and user wants icon on left  side) or
		--    (icon on left  by default and user wants icon on right side) ...
		if (
			(self.rightAlignDef1 and not self.rightAlignIcon1) or
			(not self.rightAlignDef1 and self.rightAlignIcon1)
		) then
			-- Reverse of normal
			reverse = true;
		end
	end

	self.auraEdgeLeft = 0;
	self.auraEdgeRight = 0;

	if (growUpDown) then
		xOffset = 0;
		wrapYOffset = 0;

		-- Fixed number of buffs per wrap.
		minHeight = (self.buttonHeight + self.buffSpacing) * (self.wrapAfter - 1) + self.buttonHeight;

		if (self.maxWraps == 0) then
			-- Variable number of wraps.
			-- Minimum width == width of a single button.
			minWidth = self.buttonWidth;
			if (self.buttonStyle == 1) then
				-- Button style 1 only.
				-- To do this, the aura frame width will be reduced by the width of the detail frame.
				-- We'll widen the altFrame by the width of the detail frame to compensate.
				minWidth = minWidth - self.detailWidth1;
				if (reverse) then
					if (self.rightAlignDef1) then
						self.auraEdgeRight = self.detailWidth1;
					else
						self.auraEdgeLeft = self.detailWidth1;
					end
				else
					if (self.rightAlignDef1) then
						self.auraEdgeLeft = self.detailWidth1;
					else
						self.auraEdgeRight = self.detailWidth1;
					end
				end
			end
		else
			-- Fixed number of wraps.
			minWidth = (self.buttonWidth + self.wrapSpacing) * (self.maxWraps - 1) + self.buttonWidth;
			if (self.buttonStyle == 1) then
				-- We only need to make an adjustment if the icon is not on the normal side.
				if (reverse) then
					-- Button style 1 only.
					-- Reverse the side that the icon is normally on.
					-- To do this, the aura frame width will be reduced by the width of the detail frame.
					-- We'll widen the altFrame by the width of the detail frame to compensate.
					minWidth = minWidth - self.detailWidth1;
					if (self.rightAlignDef1) then
						self.auraEdgeRight = self.detailWidth1;
					else
						self.auraEdgeLeft = self.detailWidth1;
					end
				end
			end
		end
	else
		yOffset = 0;
		wrapXOffset = 0;

		-- Fixed number of buffs per wrap.
		minWidth = (self.buttonWidth + self.buffSpacing) * (self.wrapAfter - 1) + self.buttonWidth;

		if (self.buttonStyle == 1) then
			-- We only need to make an adjustment if the icon is not on the normal side.
			if (reverse) then
				-- Button style 1 only.
				-- Reverse the side that the icon is normally on.
				-- To do this, the aura frame width will be reduced by the width of the detail frame.
				-- We'll widen the altFrame by the width of the detail frame to compensate.
				minWidth = minWidth - self.detailWidth1;
				if (self.rightAlignDef1) then
					self.auraEdgeRight = self.detailWidth1;
				else
					self.auraEdgeLeft = self.detailWidth1;
				end
			end
		end

		if (self.maxWraps == 0) then
			-- Variable number of wraps.
			-- Minimum height == height of a single button.
			minHeight = self.buttonHeight;
		else
			-- Fixed number of wraps.
			minHeight = (self.buttonHeight + self.wrapSpacing) * (self.maxWraps - 1) + self.buttonHeight;
		end
	end

	-- Remember these calculated values
	self.point = point;
	self.minWidth = minWidth;
	self.minHeight = minHeight;
	self.xOffset = xOffset;
	self.yOffset = yOffset;
	self.wrapXOffset = wrapXOffset;
	self.wrapYOffset = wrapYOffset;

	self:calculateAnchorToEdge();

	if (not initFlag) then
		self.needUpdate = true;

		-- Set the aura frame's attributes.
		self:setAttributes();
	end
end

function frameClass:setDefaultOptions()
	-- Set default options for this object.
	-- local frameOptions = self:getOptions();
end

function frameClass:setAttributes()
	-- Set the aura frame's attributes.

	-- Attributes (this addon):
	--
	--	anchorToEdgeLeft
	--	anchorToEdgeRight
	--	anchorToEdgeTop
	--	anchorToEdgeBottom
	--	rightAlignIcon1
	--	buttonStyle
	--
	-- Attributes (secure aura header):
	--
	--	_ignore -- Prevents reconfiguration of the header while setting attributes by setting it to a non-nil value.
	--	consolidateHeader -- Frame to use for the consolidated frame. Can be a) name of an XML template, or b) an already created frame object.
	--	consolidateProxy -- Button to use for the consolidated button. Can be a) name of an XML template, or b) an already created button object.
	--	includeWeapons -- Include buttons for weapon enchants at this position (nil == don't include weapon buttons)
	--	maxWraps -- Maximum number of wraps (number, 0==Nothing will be displayed, nil == no maximum)
	--	minHeight -- The minimum height of the aura frame.
	--	minWidth -- The minimum width of the aura frame.
	--	point -- Anchor point used to anchor each button to the aura frame.
	--	tempEnchant1 -- Used by the header routines to store the button that gets created.
	--	tempEnchant2 -- Used by the header routines to store the button that gets created.
	--	tempEnchant3 -- Used by the header routines to store the button that gets created.
	--	template -- Name of an XML template to use when creating new aura buttons.
	--	unit -- Unit id to be used with the frame
	--	weaponTemplate -- Name of an XML template to use when creating new weapon enchantment buttons.
	--	wrapAfter -- Number of icons to show before wrapping occurs (number, nil or 0 == no wrapping but causes divide by nil error atm)
	--	wrapXOffset -- X offset value used to position buttons in the next row/column.
	--	wrapYOffset -- Y offset value used to position buttons in the next row/column.
	--	xOffset -- X offset value used to position buttons in the current row/column.
	--	yOffset -- Y offset value used to position buttons in the current row/column.

	local auraFrame = self.auraFrame;
	if (not auraFrame) then
		return;
	end

	-- If the aura frame is secure...
	if (auraFrame:IsProtected()) then
		if (InCombatLockdown()) then
			-- We can't update secure frame attributes while in combat.
			return;
		end
	end

	-- Suspend updates via OnAttributeChanged until we've configured everything.
	auraFrame:SetAttribute("_ignore", 1);

	-- These are addon specific options intended for use with secure code snippets.
	auraFrame:SetAttribute("anchorToEdgeLeft", self.anchorToEdgeLeft);
	auraFrame:SetAttribute("anchorToEdgeRight", self.anchorToEdgeRight);
	auraFrame:SetAttribute("anchorToEdgeTop", self.anchorToEdgeTop);
	auraFrame:SetAttribute("anchorToEdgeBottom", self.anchorToEdgeBottom);
	auraFrame:SetAttribute("rightAlignIcon1", self.rightAlignIcon1);
	auraFrame:SetAttribute("buttonStyle", self.buttonStyle);

	-- Minimum width and height of the frame
	auraFrame:SetAttribute("minWidth", self.minWidth);
	auraFrame:SetAttribute("minHeight", self.minHeight);

	-- For positioning each button relative to the frame.
	auraFrame:SetAttribute("point", self.point);

	-- For positioning relative to previous button.
	auraFrame:SetAttribute("xOffset", self.xOffset);
	auraFrame:SetAttribute("yOffset", self.yOffset);

	-- For positioning relative to previous set of buttons.
	auraFrame:SetAttribute("wrapXOffset", self.wrapXOffset);
	auraFrame:SetAttribute("wrapYOffset", self.wrapYOffset);

	-- Maximum number of wraps
	if (self.maxWraps == 0) then
		-- Trying to use 0 maxWraps will cause all buttons to be hidden.
		-- Use nil instead. This will allow an unlimited number of wraps.
		auraFrame:SetAttribute("maxWraps", nil);
	else
		auraFrame:SetAttribute("maxWraps", self.maxWraps);
	end

	-- Start a new row/column after showing this number of buffs.
	auraFrame:SetAttribute("wrapAfter", self.wrapAfter);

	-- Resume updates via OnAttributeChanged
	auraFrame:SetAttribute("_ignore", nil);
end

function frameClass:getAuraButtonTemplate()
	local buffSize;
	if (self.buttonStyle == 2) then
		buffSize = self.buffSize2;
	else
		buffSize = self.buffSize1;
	end
	if (self.useUnsecure) then
		return "CT_BuffMod_UnsecureAuraButton" .. buffSize .. "Template";
	else
		return "CT_BuffMod_SecureAuraButton" .. buffSize .. "Template";
	end
end

function frameClass:setBorder()
	-- Set the border texture and sizes.
	local auraFrame = self.auraFrame;
	if (not auraFrame) then
		return;
	end

	local altFrame = auraFrame.altFrame;

	local alpha = 0;
	if (self.showBorder) then
		alpha = 1;
	end

	altFrame:SetBackdropBorderColor(1, 1, 1, alpha);  -- r,g,b,a

	local left = self.anchorToEdgeLeft;
	local right = self.anchorToEdgeRight;
	local top = self.anchorToEdgeTop;
	local bottom = self.anchorToEdgeBottom;

	altFrame:SetPoint("TOPLEFT", auraFrame, "TOPLEFT", -left, top);
	altFrame:SetPoint("BOTTOMRIGHT", auraFrame, "BOTTOMRIGHT", right, -bottom);
end

function frameClass:setBackground()
	-- Set the color of the background.
	local auraFrame = self.auraFrame;
	if (not auraFrame) then
		return;
	end

	local altFrame = auraFrame.altFrame;

	if (self.showBackground) then
		-- Show the background.
		local color;
		if (self.useCustomBackgroundColor) then
			-- Use the custom backgound color for this window.
			color = self.windowBackgroundColor;
		else
			-- Use the default background color as chosen by the user.
			if (self.isConsolidated) then
				color = globalObject.consolidatedColor;
			else
				color = globalObject.backgroundColor;
			end
		end
		altFrame:SetBackdropColor(color[1], color[2], color[3], color[4]);
	else
		-- Hide the background by setting the alpha to 0.
		altFrame:SetBackdropColor(0, 0, 0, 0); -- r, g, b, a
	end
end

function frameClass:setClamped()
	-- Set the clamped state of the frame.
	local auraFrame = self.auraFrame;
	if (not auraFrame) then
		return;
	end

	-- Calculate the size of each border edge.
	local adjust = -self.borderSize;
	if (self.showBorder) then
		adjust = adjust + 2;
	end

	local left = self.anchorToEdgeLeft + adjust;
	local right = self.anchorToEdgeRight + adjust;
	local top = self.anchorToEdgeTop + adjust;
	local bottom = self.anchorToEdgeBottom + adjust;

	-- Extend the clamping rectangle of the aura frame so that it takes into account
	-- the size of the border areas.
	auraFrame:SetClampRectInsets(-left, right, top, -bottom);

	-- Clamp or unclamp the aura frame.
	if (self.clampWindow) then
		auraFrame:SetClampedToScreen(true);
	else
		auraFrame:SetClampedToScreen(false);
	end
end

function frameClass:savePosition()
	-- Save the position of the aura frame.
	local auraFrame = self.auraFrame;
	if (not auraFrame) then
		return;
	end

	local frameOptions = self:getOptions();

	-- Save the anchor point values.
	local anchorPoint, anchorTo, relativePoint, xoffset, yoffset = auraFrame:GetPoint(1);
	if (anchorTo) then
		anchorTo = anchorTo:GetName();
	end

	local width = auraFrame:GetWidth();
	local height = auraFrame:GetHeight();

	frameOptions.position = { anchorPoint, anchorTo, relativePoint, xoffset, yoffset, width, height };
end

function frameClass:restorePosition(ignoreHW)
	-- Restore the position of the aura frame.
	-- If there is no saved position, then center the frame.
	-- Parameters:
	-- 	ignoreHW -- if true then the height and width will not be restored.

	local auraFrame = self.auraFrame;
	if (not auraFrame) then
		return;
	end

	-- Get the frame's position
	local frameOptions = self:getOptions();
	local pos = frameOptions.position;

	auraFrame:ClearAllPoints();
	if (pos) then
		-- Restore to the saved position.
		auraFrame:SetPoint(pos[1], pos[2], pos[3], pos[4], pos[5]);
		if (not ignoreHW) then
			auraFrame:SetWidth(pos[6] or 1);
			auraFrame:SetHeight(pos[7] or 1);
		end
	else
		-- Center the frame on screen.
		auraFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0);
		if (not ignoreHW) then
			auraFrame:SetWidth(1);
			auraFrame:SetHeight(1);
		end
	end

	-- Reanchor the frame so we have the desired anchor point.
	self:setAnchorPoint(false);

	-- Save the frame's position
	self:savePosition();
end

function frameClass:resetPosition()
	-- Reset position of the aura frame to the center of the screen.
	local auraFrame = self.auraFrame;
	if (not auraFrame) then
		return;
	end
	if (auraFrame:IsProtected()) then
		if (InCombatLockdown()) then
			return;
		end
	end

	-- Center the frame on screen.
	auraFrame:ClearAllPoints();
	auraFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0);

	self:setAnchorPoint(false);

	-- Save the frame's position
	self:savePosition();
end

function frameClass:setAnchorPoint(keepOnScreen)
	-- Set the anchor point of the aura frame.
	local auraFrame = self.auraFrame;
	if (not auraFrame) then
		return;
	end

	local oldScale = auraFrame:GetScale() or 1;
	if (oldScale == 0) then
		oldScale = 1;
	end
	local xOffset, yOffset;
	local anchorX, anchorY, anchorP;
	local relativeP;
	local centerX, centerY = UIParent:GetCenter();
	centerX = centerX or 0;
	centerY = centerY or 0;

	anchorP = auraFrame:GetAttribute("point") or "TOPLEFT";

	-- Determine what the X and Y values of the anchor are.
	if (anchorP == "CENTER") then
		-- CENTER
		anchorX, anchorY = auraFrame:GetCenter();
		anchorY = anchorY or (centerY / oldScale);
		anchorX = anchorX or (centerX / oldScale);

	elseif (anchorP == "LEFT") then
		-- LEFT
		anchorX, anchorY = auraFrame:GetCenter();
		anchorY = anchorY or (centerY / oldScale);
		anchorX = auraFrame:GetLeft() or 0;

	elseif (anchorP == "BOTTOMLEFT") then
		-- BOTTOMLEFT
		anchorY = auraFrame:GetBottom() or 0;
		anchorX = auraFrame:GetLeft() or 0;

	elseif (anchorP == "BOTTOM") then
		-- BOTTOM
		anchorX, anchorY = auraFrame:GetCenter();
		anchorY = auraFrame:GetBottom() or 0;
		anchorX = anchorX or (centerX / oldScale);

	elseif (anchorP == "BOTTOMRIGHT") then
		-- BOTTOMRIGHT
		anchorY = auraFrame:GetBottom() or 0;
		anchorX = auraFrame:GetRight() or 0;

	elseif (anchorP == "RIGHT") then
		-- RIGHT
		anchorX, anchorY = auraFrame:GetCenter();
		anchorY = anchorY or (centerY / oldScale);
		anchorX = auraFrame:GetRight() or 0;

	elseif (anchorP == "TOPRIGHT") then
		-- TOPRIGHT
		anchorY = auraFrame:GetTop() or 0;
		anchorX = auraFrame:GetRight() or 0;

	elseif (anchorP == "TOP") then
		-- TOP
		anchorX, anchorY = auraFrame:GetCenter();
		anchorY = auraFrame:GetTop() or 0;
		anchorX = anchorX or (centerX / oldScale);

	else
		-- TOPLEFT
		anchorP = "TOPLEFT";
		anchorY = auraFrame:GetTop() or 0;
		anchorX = auraFrame:GetLeft() or 0;
	end

	-- If the Y anchor is in the botton half of the screen...
	if (anchorY <= centerY / oldScale) then
		-- Anchor the frame relative to the bottom left corner of the screen.
		relativeP = "BOTTOMLEFT";
		yOffset = anchorY;
	else
		-- The Y anchor is in the top half of the screen.
		-- Anchor the frame relative to the top left corner of the screen.
		relativeP = "TOPLEFT";
		yOffset = anchorY - ((UIParent:GetTop() or 0) / oldScale);
	end

	-- If the X anchor is in the left half of the screen...
	if (anchorX <= centerX / oldScale) then
		-- Use the relative point we've already decided upon.
		xOffset = anchorX;
	else
		-- The X anchor is in the right half of the screen.
		xOffset = anchorX - ((UIParent:GetRight() or 0) / oldScale);

		if (relativeP == "TOPLEFT") then
			-- The Y anchor is in the top half of the screen.
			relativeP = "TOPRIGHT";
		else
			-- The Y anchor is in the bottom half of the screen.
			relativeP = "BOTTOMRIGHT";
		end
	end

	if (keepOnScreen) then
		-- Keep the anchor point on screen.
		if (relativeP == "TOPRIGHT") then
			if (yOffset > 0) then
				yOffset = 0;
			end
			if (xOffset > 0) then
				xOffset = 0;
			end
		elseif (relativeP == "BOTTOMRIGHT") then
			if (yOffset < 0) then
				yOffset = 0;
			end
			if (xOffset > 0) then
				xOffset = 0;
			end
		elseif (relativeP == "BOTTOMLEFT") then
			if (yOffset < 0) then
				yOffset = 0;
			end
			if (xOffset < 0) then
				xOffset = 0;
			end
		else -- if (relativeP == "TOPLEFT") then
			if (yOffset > 0) then
				yOffset = 0;
			end
			if (xOffset < 0) then
				xOffset = 0;
			end
		end
	end

	-- Position the frame.
	auraFrame:ClearAllPoints();
	auraFrame:SetPoint(anchorP, "UIParent", relativeP, xOffset, yOffset);
end

function frameClass:resizeSpellButtons()
	local auraFrame = self.auraFrame;
	if (not auraFrame) then
		return;
	end

	local buffSize;
	if (self.buttonStyle == 2) then
		buffSize = self.buffSize2;
	else
		buffSize = self.buffSize1;
	end

	-- Aura buttons
	local num = 1;
	local button = auraFrame:GetAttribute("child1");
	while (button) do
		button:SetHeight(buffSize);
		button:SetWidth(buffSize);
		num = num + 1;
		button = auraFrame:GetAttribute("child" .. num);
	end
end

function frameClass:hideSpellButtons()
	-- Hide the spell buttons.
	local auraFrame = self.auraFrame;
	if (not auraFrame) then
		return;
	end

	local num = 1;
	local button = auraFrame:GetAttribute("child1");
	while (button) do
		button:Hide();
		num = num + 1;
		button = auraFrame:GetAttribute("child" .. num);
	end
end

function frameClass:updateSpellButtons(func)
	-- Update spell buttons
	local auraFrame = self.auraFrame;
	if (not auraFrame) then
		return;
	end

	local num = 1;
	local button = auraFrame:GetAttribute("child1");
	while (button) do
		if (button:IsVisible()) then
			button.frameObject = self;
			button.unitObject = nil;
			button.auraObject = nil;
			button.mode = constants.BUTTONMODE_SPELL;
			button.index = button:GetAttribute("index");
			button.filter = button:GetAttribute("filter");
			func(button);
		else
			break;
		end
		num = num + 1;
		button = auraFrame:GetAttribute("child" .. num);
	end
end

function frameClass:startMoving(frame, button)
	-- Attempt to start moving the aura frame.

	if (not self.lockWindow) then
		local auraFrame = self.auraFrame;
		local canDrag = true;

		if (auraFrame:IsProtected() and InCombatLockdown()) then
			local canDragInCombat = false;

			if (self.maxWraps ~= 0) then
				-- Allow dragging the frame in combat only if the frame is a fixed size.
				-- When a frame is dragged, Blizzard changes the anchor point of the frame.
				-- This can cause a variable size frame to expand in an undesired direction.
				-- We need to reanchor the frame when it stops moving in order to resolve
				-- the anchor point issue, but we can't do so until we're out of combat.
				canDragInCombat = true;

				-- Set flag so that protected options will be applied when combat ends.
				-- This will ensure the frame gets re-anchored.
				self.needApplyProtected = true;
			end

			canDrag = canDragInCombat;
		end

		if (canDrag) then
			auraFrame:StartMoving();
			auraFrame.isMoving = true;
			return true;
		end
	end
	return false;
end

function frameClass:stopMoving(frame, button)
	-- Attempt to stop moving the aura frame.
	local auraFrame = self.auraFrame;

	if (auraFrame.isMoving) then
		auraFrame:StopMovingOrSizing();

		local reanchor = true;
		if (auraFrame:IsProtected() and InCombatLockdown()) then
			reanchor = false;
		end
		if (reanchor) then
			self:setAnchorPoint(false);
		end

		self:savePosition();
		auraFrame.isMoving = false;

		return true;
	end
	return false;
end

function frameClass:refreshAuraButtons()
	self:updateAuraButtons(auraButton_updateAppearance);
end

function frameClass:enableMouse()
	-- Enable/disable the mouse.
	local auraFrame = self.auraFrame;
	if (not auraFrame) then
		return;
	end

	-- Enable the mouse if the options window is open.
	local altFrame = auraFrame.altFrame;

	if (isOptionsFrameShown()) then
		altFrame:EnableMouse(true);
	else
		-- Options window is closed, so set mouse based on whether the
		-- aura frame is locked or not.
		if (self.lockWindow) then
			altFrame:EnableMouse(false);
		else
			altFrame:EnableMouse(true);
		end
	end
end

function frameClass:altFrameEnableMouse(enable)
	-- Enable/disable the mouse.
	-- This is called when the options window is shown or hidden.
	local auraFrame = self.auraFrame;
	if (not auraFrame) then
		return;
	end

	local altFrame = auraFrame.altFrame;
	if (enable) then
		-- Force mouse to be enabled.
		altFrame:EnableMouse(true);
	else
		-- Disable mouse unless the aura frame is unlocked.
		if (self.lockWindow) then
			altFrame:EnableMouse(false);
		else
			altFrame:EnableMouse(true);
		end
	end
end

function frameClass:getOldAuraFrameTable()
	-- Get the table to use for recycling old aura frames.
	if (self.useUnsecure) then
		if (self.isConsolidated) then
			return oldUnsecureConsolidatedFrames;
		else
			return oldUnsecurePrimaryFrames;
		end
	else
		if (self.isConsolidated) then
			return oldSecureConsolidatedFrames;
		else
			return oldSecurePrimaryFrames;
		end
	end
end

function frameClass:createAuraFrame()
	-- Create an aura frame
	local auraFrame = self.auraFrame;

	-- Return if we have already created the frame.
	if (auraFrame) then
		return;
	end

	-- Determine if we can recycle an old frame, or if we need
	-- to create a new frame and what it's name will be.
	local frameName;
	local oldAuraFrameTable = self:getOldAuraFrameTable();

	if (#oldAuraFrameTable > 0) then
		auraFrame = tremove(oldAuraFrameTable);
	else
		-- Use a different name for unsecure and secure frames.
		if (self.useUnsecure) then
			frameName = "CT_BuffMod_AuraFrameU";
		else
			frameName = "CT_BuffMod_AuraFrameS";
		end
		-- Use a different name for consolidated and primary frames.
		if (self.isConsolidated) then
			frameName = frameName .. "C";
		else
			frameName = frameName .. "P";
		end
	end

	if (auraFrame) then
		-- Recycle an old frame.
		self.auraFrame = auraFrame;

		-- Resize the buttons to match the size we're currently using.
		self:resizeButtons();
	else
		-- Create a new frame.
		local template = self:getAuraFrameTemplate();

		if (not oldAuraFrameTable.serial) then
			oldAuraFrameTable.serial = 0;
		end
		oldAuraFrameTable.serial = oldAuraFrameTable.serial + 1;

		auraFrame = CreateFrame("Frame", frameName .. oldAuraFrameTable.serial, UIParent, template);
		
		local level = auraFrame:GetFrameLevel() + 1;  -- +1 to get it above the alt frame
		if (self.isConsolidated) then
			level = level + 10;  -- +10 to make consolidated frame higher than primary
		end
		auraFrame:SetFrameLevel(level);

		self.auraFrame = auraFrame;
	end

	auraFrame.frameObject = self;
end

function frameClass:setAltFrameScripts()
end

function frameClass:createAltFrame()
	-- Create alt frame.
	local auraFrame = self.auraFrame;

	-- Return if the alt frame has already been created.
	if (auraFrame.altFrame) then
		auraFrame.altFrame.fsWindowTitle:SetText(format(L["CT_BuffMod/WindowTitle"],self:getWindowId()));
		return;
	end

	-- Create unsecure alternate frame.
	-- We're using this frame to provide a border for the aura frame,
	-- and to allow us to display a tooltip while the options window
	-- is open (the aura and alt frames should not have the mouse enabled at
	-- the same time, and we may not be able to enable the mouse for aura
	-- frame tooltips during combat).
	local altFrame = CreateFrame("Frame", nil, UIParent, BackdropTemplateMixin and "BackdropTemplate");
	if altFrame.SetIsUnrestricted then altFrame:SetIsUnrestricted(true) end -- <--- ADD THIS LINE HERE!
	auraFrame.altFrame = altFrame;
	altFrame.auraFrame = auraFrame;

	altFrame:SetBackdrop(tooltipBackdrop2);
	altFrame:SetBackdropColor(0, 0, 0, 0);
	altFrame:SetBackdropBorderColor(1, 1, 1, 0);  -- r,g,b,a

	altFrame:SetPoint("TOPLEFT", auraFrame, "TOPLEFT", 0, 0);
	altFrame:SetPoint("BOTTOMRIGHT", auraFrame, "BOTTOMRIGHT", 0, 0);

	altFrame:SetFrameLevel(auraFrame:GetFrameLevel()-1);

	-- Ensure mouse is disabled initially.
	altFrame:EnableMouse(false);

	altFrame:Hide();

	-- Create window title
	altFrame.fsWindowTitle = altFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal");
	altFrame.fsWindowTitle:SetWordWrap(false)
	altFrame.fsWindowTitle:SetText(format(L["CT_BuffMod/WindowTitle"],self:getWindowId()));
	altFrame.fsWindowTitle:SetPoint("BOTTOM", altFrame, "TOP");
	altFrame.fsWindowTitle:Hide();
end

function frameClass:setAuraFrameScripts()
end

function frameClass:createConsolidatedButton()
end

function frameClass:createWeaponButtons()
end

function frameClass:shrinkAndCenterAuraFrame()
	-- Reduce the size of the aura frame to 1 x 1, clear all points, and then center it.
	local auraFrame = self.auraFrame;
	if (not auraFrame) then
		return;
	end
	auraFrame:SetWidth(1);
	auraFrame:SetHeight(1);
	auraFrame:ClearAllPoints();
	auraFrame:SetPoint("RIGHT", UIParent, "RIGHT", 0, 0);
end

function frameClass:registerAuraFrameEvents()
end

function frameClass:unregisterAuraFrameEvents()
end

function frameClass:registerStateDrivers()
end

function frameClass:unregisterStateDrivers()
end

function frameClass:createStateFrame()
end

function frameClass:createBuffFrame()
	-- Create a buff frame.
	--
	-- This can be used as to create a primary or consolidated frame.
	-- This should be called from the primary/consolidated class.
	-- The .isConsolidated flag is used to control whether certain
	-- components of the window are used.

	local auraFrame;

	-- Create the aura frame.
	self:createAuraFrame();

	auraFrame = self.auraFrame;

	-- Create the alt frame
	self:createAltFrame();

	-- Create the consolidate button.
	-- We'll create this now rather than let the secure aura routines do it.
	-- If they created the button during combat then we'd be unable to set up
	-- the button the way we want to.
	self:createConsolidatedButton();

	-- Create the weapon buttons.
	-- Do it now rather than wait for secure aura routine to do it.
	-- This way we'll have references to the buttons which we can use
	-- in secure code.
	self:createWeaponButtons();

	if (not self.isConsolidated) then
		-- If this is a secure primary frame, then we need to create a state frame
		-- that will be used to monitor state changes and allow us to change
		-- the unit assigned to the secure aura frame.
		if (auraFrame:IsProtected()) then
			self:createStateFrame();
		end
		self:registerStateDrivers();
	end

	-- Register some aura frame events
	self:registerAuraFrameEvents();

	-- Set some aura frame scripts
	self:setAuraFrameScripts();

	-- Set some alt frame scripts
	self:setAltFrameScripts();

	-- Start out with a minimal frame size.
	auraFrame:SetHeight(1);
	auraFrame:SetWidth(1);

	-- Make sure the mouse is initially disabled.
	auraFrame:EnableMouse(false);

	-- Assign a backdrop and set the color of the alt frame.
	self:setBackground();

	-- Show/hide the border of the alt frame.
	self:setBorder();

	-- Set clamping of the aura frame.
	self:setClamped();

	-- Enable/Disable mouse in the alt frame.
	self:enableMouse();

	-- Set the movable state (only the primary frame needs to be movable).
	auraFrame:SetMovable(not self.isConsolidated);

	-- Set the aura frame's attributes.
	self:setAttributes();

	-- Position this frame on the screen (will be centered if
	-- there is no saved position).
	self:restorePosition();
end

function frameClass:deleteBuffFrame()
	-- Delete a buff frame.
	--
	-- This can be used to delete a primary or consolidated frame.
	-- This should be called from the primary/consolidated class.
	local auraFrame = self.auraFrame;

	-- Hide the auraFrame.
	auraFrame:Hide();  -- also hides the altFrame

	-- Hide all the buttons
	self:hideAllButtons();

	-- Clear reference to the frameObject value.
	auraFrame.frameObject = nil;

	-- Don't clear the auraFrame.statFrame value. (primary object)
	-- Don't clear the auraFrame.altFrame value. (primary and consolidated objects)
	-- Don't clear the auraFrame.consolidatedButton value. (primary object)

	-- Unregister state drivers
	self:unregisterStateDrivers();

	-- Unregister events
	self:unregisterAuraFrameEvents();

	-- Ensure mouse is disabled in the aura and alt frames.
	auraFrame:EnableMouse(false);
	if (self.altFrame) then
		self.altFrame:EnableMouse(false);
	end

	-- Add the auraFrame to the appropriate old aura frames table.
	local oldAuraFrameTable = self:getOldAuraFrameTable();
	tinsert(oldAuraFrameTable, auraFrame);

	-- Clear some other values.
	self.auraFrame = nil;
	self.needUpdate = nil;
end

function frameClass:updateSpells(unitId)
	-- unitId == unit id to update for (optional). Defaults to the window's unit id.
	globalObject.unitListObject:updateSpells( unitId or self:getUnitId() );
end

function frameClass:updateEnchants(unitId)
	-- unitId == unit id to update for (optional). Defaults to the window's unit id.
	return globalObject.unitListObject:updateEnchants( unitId or self:getUnitId() );
end

function frameClass:updateSpellsAndEnchants(unitId)
	-- unitId == unit id to update for (optional). Defaults to the window's unit id.
	return globalObject.unitListObject:updateSpellsAndEnchants( unitId or self:getUnitId() );
end

--------------------------------------------
-- Consolidated class
--
-- Inherits fron:
-- 	frameClass
--
-- Class object overview:
--
--	(consolidatedClassObject)
--		.classObject
--		.meta
--		.super
--
-- Object overview:
--
--	(consolidatedObject)
--		.classObject
--		+other inherited properties
--
-- Properties:
--	.classObject
--
-- Other values (often determined by other options, etc) (list may not be complete):
--
--	.needSetSpecial -- Flag used to indicate that speciall attributes need to be set
--
-- Methods and functions:
--
--	:new()
--	:setParent(primaryObject)
--
--	:getOptions(shouldCreate)
--	:setOptions(consolidatedOptions)
--	:copyOptions(consolidatedObject)
--	:deleteOptions()
--
--	:setDefaultOptions()
--	:setSpecialAttributes()
--	:setAttributes()
--	:getAuraFrameTemplate()
--
--	:resizeButtons()
--	:hideAllButtons()
--	:updateAuraButtons(func)
--
--	consolidatedAuraFrame_OnUpdate(auraFrame, elapsed)
--	consolidatedAuraFrame_OnShow(auraFrame)
--	consolidatedAuraFrame_OnHide(auraFrame)
--	:setAuraFrameScripts()
--
--	:createBuffFrame()
--	:deleteBuffFrame()

-- Create the class object.
local consolidatedClass = frameClass:new();

consolidatedClass.meta = { __index = consolidatedClass };
consolidatedClass.super = consolidatedClass.classObject;

function consolidatedClass:new()
	-- Create an object of this class.
	local object = {};
	object.classObject = self;
	setmetatable(object, self.meta);

	object.isConsolidated = true;

	return object;
end

function consolidatedClass:setParent(primaryObject)
	self.parent = primaryObject;
end

function consolidatedClass:getOptions(shouldCreate)
	-- Get the table containing the options.
	-- shouldCreate -- true, nil == Create table if it does not exist.
	--                 false == Do not create missing table.
	return self.parent:getConsolidatedOptions(shouldCreate);
end

function consolidatedClass:setOptions(consolidatedOptions)
	-- Set the table containing the options.
	self.parent:setConsolidatedOptions(consolidatedOptions);
end

function consolidatedClass:copyOptions(consolidatedObject)
	-- Copy all of the options to the specified object.

	-- Copy the consolidated options.
	local newOptions;
	local consolidatedOptions = self:getOptions(false);
	if (consolidatedOptions) then
		newOptions = {};
		module:copyTable(consolidatedOptions, newOptions);
	end
	self:setOptions(newOptions);
end

function consolidatedClass:deleteOptions()
	-- Delete all of the options.

	-- Delete the options for the consolidated object
	local consolidatedOptions = self:getOptions(false);
	if (consolidatedOptions) then
		self:setOptions(nil);
	end
end

function consolidatedClass:setDefaultOptions()
	-- Set default options for this object.

	local frameOptions = self:getOptions();

	frameOptions.lockWindow = 1;
	frameOptions.clampWindow = 1;

	frameOptions.showBorder = 1;
	frameOptions.showBackground = 1;
	frameOptions.useCustomBackgroundColor = nil;

	local color = defaultConsolidatedColor;
	frameOptions.windowBackgroundColor = {};
	for i = 1, 4 do
		frameOptions.windowBackgroundColor[i] = color[i];
	end

	frameOptions.userEdgeLeft = 10;
	frameOptions.userEdgeRight = 10;
	frameOptions.userEdgeTop = 10;
	frameOptions.userEdgeBottom = 20;

	frameOptions.layoutType = constants.LAYOUT_GROW_LEFT_WRAP_DOWN;

	frameOptions.wrapAfter = 6;
	frameOptions.maxWraps = 0;

	frameOptions.buffSpacing = 8;
	frameOptions.wrapSpacing = 18;

	frameOptions.buttonStyle = 2;

	frameOptions.buffSize1 = nil;
	frameOptions.rightAlign1 = nil;
	frameOptions.detailWidth1 = nil;

	frameOptions.colorBuffs1 = nil;

	frameOptions.showNames1 = nil;
	frameOptions.colorCodeDebuffs1 = nil;
	frameOptions.colorCodeIcons1 = nil;
	frameOptions.colorCodeBackground1 = nil;
	frameOptions.normalIconBorder1 = nil;
	frameOptions.nameJustifyWithTime1 = nil;
	frameOptions.nameJustifyNoTime1 = nil;

	frameOptions.showTimers1 = nil;
	frameOptions.durationFormat1 = nil;
	frameOptions.durationLocation1 = nil;
	frameOptions.timeJustifyNoName1 = nil;

	frameOptions.showBuffTimer1 = nil;
	frameOptions.showTimerBackground1 = nil;

	frameOptions.spacingOnRight1 = nil;
	frameOptions.spacingOnLeft1 = nil;

	frameOptions.buffSize2 = 20;
	frameOptions.colorCodeIcons2 = nil;
	frameOptions.normalIconBorder2 = nil;
	frameOptions.showTimers2 = 1;
	frameOptions.durationFormat2 = 3;
	frameOptions.dataSide2 = constants.DATA_SIDE_BOTTOM;
	frameOptions.spacingFromIcon2 = 1;
end

function consolidatedClass:setSpecialAttributes()
	-- Set some attributes that can be changed without requiring a full reconfigure of
	-- the aura frame. These attributes may also be set during :setAttributes().
	-- If we're currently in combat and the aura frame is protected, then the update
	-- will not occur until we're out of combat.

	self.needSetSpecial = false;

	local auraFrame = self.auraFrame;
	if (auraFrame) then
		local update = true;
		if (auraFrame:IsProtected() and InCombatLockdown()) then
			update = false;
		end
		if (update) then
			auraFrame:SetAttribute("_ignore", 1);

			-- Consolidated window auto hide timer (this addon's attribute).
			auraFrame:SetAttribute("consolidatedHideTimer", globalObject.consolidatedHideTimer);

			auraFrame:SetAttribute("_ignore", nil);
		else
			-- Set special attributes once combat ends.
			self.needSetSpecial = true;
		end
	end
end

function consolidatedClass:setAttributes()
	-- Set the consolidated aura frame's attributes.
	--
	-- Attributes (this addon):
	--
	--	consolidatedHideTimer

	local auraFrame = self.auraFrame;
	if (not auraFrame) then
		return;
	end

	-- If the aura frame is secure...
	if (auraFrame:IsProtected()) then
		if (InCombatLockdown()) then
			-- We can't update secure frame attributes while in combat.
			return;
		end
	end

	-- Set most of the frame attributes
	self.super.setAttributes(self);

	-- Set special attributes
	self:setSpecialAttributes();

	-- Suspend updates via OnAttributeChanged until we've configured everything.
	auraFrame:SetAttribute("_ignore", 1);

	-- Template to use for the aura buttons.
	auraFrame:SetAttribute("template", self:getAuraButtonTemplate());

	-- Position of the weapon buttons.
	auraFrame:SetAttribute("includeWeapons", nil);

	-- Template to use for the weapon buttons.
	auraFrame:SetAttribute("weaponTemplate", nil);

	-- The template or button to use as the consolidated button.
	auraFrame:SetAttribute("consolidateProxy", nil);

	-- The template or frame to use as the consolidated frame.
	auraFrame:SetAttribute("consolidateHeader", nil);

	-- Resume updates via OnAttributeChanged
	auraFrame:SetAttribute("_ignore", nil);
end

function consolidatedClass:getAuraFrameTemplate()
	if (self.useUnsecure) then
		return "CT_BuffMod_UnsecureConsolidatedFrameTemplate";
	else
		return "CT_BuffMod_SecureConsolidatedFrameTemplate";
	end
end

function consolidatedClass:savePosition()
	-- Save the position of the aura frame.
	local auraFrame = self.auraFrame;
	if (not auraFrame) then
		return;
	end

	-- Save the anchor point values.
	local anchorPoint, anchorTo, relativePoint, xoffset, yoffset = auraFrame:GetPoint(1);

	local width = auraFrame:GetWidth();
	local height = auraFrame:GetHeight();

	-- Don't save in the options. Just save in the object.
	self.position = { anchorPoint, anchorTo, relativePoint, xoffset, yoffset, width, height };
end

function consolidatedClass:restorePosition(ignoreHW)
	-- Restore the position of the aura frame.
	-- If there is no saved position, then center the frame.
	-- Parameters:
	-- 	ignoreHW -- if true then the height and width will not be restored.

	local auraFrame = self.auraFrame;
	if (not auraFrame) then
		return;
	end

	-- Get the frame's position
	local pos = self.position;

	auraFrame:ClearAllPoints();
	if (pos) then
		-- Restore to the saved position.
		auraFrame:SetPoint(pos[1], pos[2], pos[3], pos[4], pos[5]);
		if (not ignoreHW) then
			auraFrame:SetWidth(pos[6] or 1);
			auraFrame:SetHeight(pos[7] or 1);
		end
	else
		-- Center the frame on screen.
		auraFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0);
		if (not ignoreHW) then
			auraFrame:SetWidth(1);
			auraFrame:SetHeight(1);
		end
	end

	-- Reanchor the frame so we have the desired anchor point.
	self:setAnchorPoint(false);

	-- Save the frame's position
	self:savePosition();
end

-- function consolidatedClass:resetPosition()
	-- Can use the frameClass version of this function.
-- end

function consolidatedClass:setAnchorPoint(keepOnScreen)
	-- Don't need to do this for consolidated frame.
	-- It will get re-anchored to the consolidated button when that gets
	-- moused over.
end

function consolidatedClass:resizeButtons()
	-- Resize all of the buttons associated with the auraFrame.
	self:resizeSpellButtons();
end

function consolidatedClass:hideAllButtons()
	-- Hide all the buttons in the aura frame.
	self:hideSpellButtons();
end

function consolidatedClass:updateAuraButtons(func)
	-- Update buttons for the consolidated frame.

	local auraFrame = self.auraFrame;
	if (not auraFrame) then
		return;
	end
	if (not auraFrame:IsShown()) then
		return;
	end

	-- Common buttons (spells)
	self:updateSpellButtons(func);
end

local function consolidatedAuraFrame_OnEvent(auraFrame, event, arg1)
	local frameObject = auraFrame.frameObject;

	if (not frameObject) then
		return;
	end

	if (event == "UNIT_AURA") then
		if (not auraFrame:IsVisible()) then
			return;
		end
		-- If the unit associated with the aura event is assigned to this frame...
		if (frameObject:getUnitId() == arg1) then
			-- We don't need to reconfigure the buttons, since the
			-- Secure Aura routines already do that for this event.
			-- We just need to perform a visual update of the buttons.
			frameObject:refreshAuraButtons();
		end
	elseif (event == "PLAYER_REGEN_ENABLED") then
		-- Leaving combat.
		if (frameObject.needSetSpecial) then
			frameObject:setSpecialAttributes();
		end
	end
end

local function consolidatedAuraFrame_OnShow(auraFrame)
	local frameObject = auraFrame.frameObject;
	if (not frameObject) then
		return;
	end

	frameObject:refreshAuraButtons();

	if (auraFrame.altFrame) then
		auraFrame.altFrame:Show();
	end
end

local function consolidatedAuraFrame_OnHide(auraFrame)
	local frameObject = auraFrame.frameObject;
	if (not frameObject) then
		return;
	end
	if (auraFrame.altFrame) then
		auraFrame.altFrame:Hide();
	end
end

function consolidatedClass:setAuraFrameScripts()
	-- Set aura frame scripts.
	local auraFrame = self.auraFrame;
	if (not auraFrame) then
		return;
	end

	-- Return if we've already hooked them.
	if (auraFrame.scriptsHooked) then
		return;
	end

	auraFrame:HookScript("OnEvent", consolidatedAuraFrame_OnEvent);
	auraFrame:HookScript("OnShow", consolidatedAuraFrame_OnShow);
	auraFrame:HookScript("OnHide", consolidatedAuraFrame_OnHide);

	auraFrame.scriptsHooked = true;
end

function consolidatedClass:registerAuraFrameEvents()
	-- Register some aura frame events.
	local auraFrame = self.auraFrame;
	if (not auraFrame) then
		return;
	end

	auraFrame:RegisterEvent("PLAYER_REGEN_ENABLED");
	auraFrame:RegisterEvent("UNIT_AURA");
end

function consolidatedClass:unregisterAuraFrameEvents()
	-- Unregister some aura frame events.
	local auraFrame = self.auraFrame;
	if (not auraFrame) then
		return;
	end

	auraFrame:UnregisterEvent("PLAYER_REGEN_ENABLED");
	auraFrame:UnregisterEvent("UNIT_AURA");
end

function consolidatedClass:createBuffFrame()
	-- Create a consolidated buff frame
	local auraFrame = self.auraFrame;

	-- If we already have an aura frame then return.
	if (auraFrame) then
		return;
	end

	-- Create the consolidated aura frame.
	self.super.createBuffFrame(self);
end

function consolidatedClass:deleteBuffFrame()
	local auraFrame = self.auraFrame;

	if (not auraFrame) then
		return true;
	end
	if (auraFrame:IsProtected()) then
		if (InCombatLockdown()) then
			return false;
		end
	end

	-- Delete the consolidated frame.
	self.super.deleteBuffFrame(self);

	return true;
end

--------------------------------------------
-- Primary frame class
--
-- Inherits fron:
-- 	frameClass
--
-- Class object overview:
--
--	(primaryClassObject)
--		.classObject
--		.meta
--		.super
--
-- Object overview:
--
--	(primaryObject)
--		.classObject
--		.consolidatedObject
--		.primaryId
--		.unitId
--		+other properties
--		+other inherited properties
--
-- Properties:
--
--	.classObject
--	.consolidatedObject -- Consolidated object used to show consolidated buffs.
--	.primaryId -- Id number for this primary object (currently only one object, so value is 1).
--	.unitId -- The current unit id associated with this primary object (eg. "player").
--
-- Frame specific properties (P==Protected option):
--
-- P	.consolidateDurationMinutes -- Total buff duration minutes (default is 0)
-- P	.consolidateDurationSeconds -- Total buff duration seconds (default is 30)
-- P	.consolidateFractionPercent -- Total buff duration percentage (default is 10)
-- P	.consolidateThresholdMinutes -- Time remaining threshold minutes (default is 0)
-- P	.consolidateThresholdSeconds -- Time remaining threshold seconds (default is 10)
-- P	.disableWindow -- Disable the aura frame without deleting the frame object (1==Yes, false==no, default is no)
-- P	.disableTooltips -- Prevent tooltips from appearing (1==Yes, false==no, default is no)
-- P	.playerUnsecure -- Use unsecure frame and buttons for player and vehicle units (1==yes, false==no, default == no)
-- P	.separateOwn -- Sort auras cast by player from others (1==Sort before others, 2==Sort after others, 3==Sort with others, default==Sort before others) (see constants.SEPARATE_OWN_*)
-- P	.separateZero  -- Sort non-expiring buffs before, with, or after other buffs; or hide them entirely (1=before, 2=after, 3=with; 4=hide)
-- P	.groupByPriority -- Sequence for applying buff-type filters/groupings, separateOwn, and separateZero (ranges from 1 to 6, default (1) is Filter > Own > Zero)
-- P	.sortDirection -- Sort direction (false == ascending, 1 == descending, default == ascending)
-- P	.sortMethod -- Sort by (1==Name, 2==Time, 3==Order, default == Name) (see constants.SORT_METHOD_*)
-- P	.sortSeq1 -- First type of buff to sort (1==None, 2==Debuff, 3==Cancelable buff, 4==Uncancelable Buff, 5==All buffs, 6==Weapon, 7=Consolidated, default==Debuff) (see constants.FILTER_TYPE_*)
-- P	.sortSeq2 -- Second type of buff to sort (1==None, 2==Debuff, 3==Cancelable buff, 4==Uncancelable Buff, 5==All buffs, 6==Weapon, 7=Consolidated, default==Weapon) (see constants.FILTER_TYPE_*)
-- P	.sortSeq3 -- Third type of buff to sort (1==None, 2==Debuff, 3==Cancelable buff, 4==Uncancelable Buff, 5==All buffs, 6==Weapon, 7=Consolidated, default==Cancelable buff) (see constants.FILTER_TYPE_*)
-- P	.sortSeq4 -- Fourth type of buff to sort (1==None, 2==Debuff, 3==Cancelable buff, 4==Uncancelable Buff, 5==All buffs, 6==Weapon, 7=Consolidated, default==Uncancelable buff) (see constants.FILTER_TYPE_*)
-- P	.sortSeq5 -- Fifth type of buff to sort (1==None, 2==Debuff, 3==Cancelable buff, 4==Uncancelable Buff, 5==All buffs, 6==Weapon, 7=Consolidated, default==None) (see constants.FILTER_TYPE_*)
-- P	.unitType -- Unit type (number, 1==Player, 2=Vehicle, 3==Pet, 4==Target, 5==Focus, default == Player)
-- P	.vehicleBuffs -- Show vehicle buffs when in a vehicle (only applies if normal unit is "player") (1==yes, false==no, default == yes)
-- P	.visCondition -- Advanced visibility condition string (default = "");
-- P	.visHideInCombat -- Hide window when in combat (1==yes, false==no, default == no)
-- P	.visHideNotCombat -- Hide window when not in combat (1==yes, false==no, default == no)
-- P	.visHideInVehicle -- Hide window when in a vehicle (1==yes, false==no, default == no)
-- P	.visHideNotVehicle -- Hide window when not in a vehicle (1==yes, false==no, default == no)
-- P	.visWindow -- Window visibility mode (1=Show always, 2=Basic, 3=Advanced, default == Show always) (see constants.VISIBILITY_*)
--
-- Other values (often determined by other options, etc) (list may not be complete):
--
--	.needApplyProtected -- Flag check after combat ends to see if :applyProtectedOptions() needs to be called.
--	.needReconfigure -- Flag checked in aura frame's OnUpdate script to force call to primaryClass:reconfigureButtons(). (true == yes, nil or false == no)
--	.needRescanTicker -- C_Timer.NewTicker that checks for buffs which are known to be late updating in the game when switch from a vehicle or pet
--	.needSetSpecial -- Flag used to indicate that speciall attributes need to be set
--	.unitNormal -- The normal unit id for this window (string, determined using .unitType) (one of: "player", "vehicle", "pet", "target", "focus")
--
-- Methods and functions:
--
--	:new(unitId)
--	:setParent(windowObject)
--	:getUnitId() -- override frameClass method
--	:setUnitId(unitId) -- override frameClass method
--
--	:getOptions(shouldCreate)
--	:setOptions(primaryOptions)
--	:getConsolidatedOptions(shouldCreate)
--	:setConsolidatedOptions(consolidatedOptions)
--	:copyOptions(primaryObject)
--	:deleteOptions()
--
--	:applyOptions(initFlag)
--	:applyUnprotectedOptions(initFlag)
--	:applyOtherOptions(initFlag)
--	:validateProtectedOptions();
--	:applyProtectedOptions(initFlag)
--
--	:setSpecialAttributes()
--	:setAttributes()
--	:getAuraFrameTemplate()
--	:getWeaponButtonTemplate()
--	:getConsolidatedButtonTemplate()
--
--	:resizeButtons()
--	:hideConsolidatedButton()
--	:hideWeaponButtons()
--	:hideAllButtons()
--	:reconfigureButtons()
--	:fixWeaponSlotNumbers()
--	:refreshWeaponButtons()
--	:updateWeaponButtons(func)
--	:updateAuraButtons(func)
--
--	primaryAuraFrame_OnEvent(auraFrame, event, arg1)
--	primaryAuraFrame_OnAttributeChanged(auraFrame, name, value)
--	primaryAuraFrame_OnShow(auraFrame)
--	primaryAuraFrame_OnHide(auraFrame)
--	:setAuraFrameScripts()
--
--	primaryAltFrame_OnMouseDown(altFrame, button)
--	primaryAltFrame_OnMouseUp(altFrame, button)
--	primaryAltFrame_OnEnter(altFrame)
--	primaryAltFrame_OnLeave(altFrame)
--	:setAltFrameScripts()
--
--	consolidatedButton_OnMouseDown(self, button)
--	consolidatedButton_OnMouseUp(self, button)
--	consolidatedButton_OnEnter(self, motion)
--	consolidatedButton_OnHide(self, motion)
--	:createConsolidatedButton()
--	:createWeaponButtons()
--
--	:registerAuraFrameEvents()
--	:unregisterAuraFrameEvents()
--	:registerStateDrivers()
--	:unregisterStateDrivers()
--	:createStateFrame()
--	:createBuffFrame()
--	:buildBasicCondition()
--	:setVisibility()
--	:deleteBuffFrame()

-- Create the class object.
local primaryClass = frameClass:new();

primaryClass.meta = { __index = primaryClass };
primaryClass.super = primaryClass.classObject;

function primaryClass:new(unitId)
	-- Create an object of this class.
	local object = {};
	object.classObject = self;
	setmetatable(object, self.meta);

	-- Assign an invalid primary id of 0 for now.
	-- A vald primary id will be assigned in windowClass:new().
	object.primaryId = 0;

	-- Set the unit id to be used by this primary object.
	object:setUnitId(unitId);

	-- Create the consolidated object.
	object.consolidatedObject = consolidatedClass:new();
	object.consolidatedObject:setParent(object);

	return object;
end

function primaryClass:setParent(windowObject)
	self.parent = windowObject;
end

function primaryClass:getUnitId() -- override frameClass method
	return self.unitId;
end

function primaryClass:setUnitId(unitId) -- override frameClass method
	local unitListObject = globalObject.unitListObject;
	local windowListObject = globalObject.windowListObject;

	local unitIdOld = self.unitId;
	self.unitId = unitId or "player";

	-- Create the unit object if needed.
	local unitObject = unitListObject:findUnit(self.unitId);
	if (not unitObject) then
		unitListObject:addUnit(self.unitId);
	end

	-- If the unit id is different than before...
	if (self.unitId ~= unitIdOld) then
		-- Delete the old unit if it is no longer needed by any windows.
		if ( not windowListObject:isUnitIdAssigned( unitIdOld ) ) then
			unitListObject:deleteUnit( unitIdOld );
		end
		-- Update the auras for the new unit
		unitListObject:updateSpellsAndEnchants( self.unitId );
		self.needUpdate = true;
	end
end

function primaryClass:getOptions(shouldCreate)
	-- Get the table containing the options.
	-- shouldCreate -- true, nil == Create table if it does not exist.
	--                 false == Do not create missing table.
	return self.parent:getPrimaryOptions(self.primaryId, shouldCreate);
end

function primaryClass:setOptions(primaryOptions)
	-- Set the table containing the options.
	self.parent:setPrimaryOptions(self.primaryId, primaryOptions);
end

function primaryClass:getConsolidatedOptions(shouldCreate)
	-- Get the table containing the options for the consolidated object.
	-- shouldCreate -- true, nil == Create table if it does not exist.
	--                 false == Do not create missing table.

	-- We currently don't want to have the game save the consolidated options,
	-- so we are keeping them in a table in the consolidated object's parent
	-- (ie. in this primary object).

	local consolidatedOptions = self.consolidatedOptions;
	if (not consolidatedOptions) then
		if (shouldCreate == false) then
			return nil;
		end
		consolidatedOptions = {};
		self:setConsolidatedOptions(consolidatedOptions);
	end
	return consolidatedOptions;
end

function primaryClass:setConsolidatedOptions(consolidatedOptions)
	-- Set the table containing the options for the consolidated object.
	self.consolidatedOptions = consolidatedOptions;
end

function primaryClass:copyOptions(primaryObject)
	-- Copy all of the options to the specified object.

	-- Copy the options for the consolidated object.
	self.consolidatedObject:copyOptions(primaryObject.consolidatedObject);

	-- Copy the options for the primary object.
	local newOptions;
	local primaryOptions = self:getOptions(false);
	if (primaryOptions) then
		newOptions = {};
		module:copyTable(primaryOptions, newOptions);
	end
	primaryObject:setOptions(newOptions);
end

function primaryClass:deleteOptions()
	-- Delete all of the options.

	-- Delete the options for the consolidated object
	self.consolidatedObject:deleteOptions();

	-- Delete the options for the primary object
	local primaryOptions = self:getOptions(false);
	if (primaryOptions) then
		self:setOptions(nil);
	end
end

function primaryClass:applyOptions(initFlag)
	-- Apply all options.
	-- initFlag -- true if we should only initialize the object's properties (no display updates, etc).

	self:applyUnprotectedOptions(initFlag);

	self:applyProtectedOptions(initFlag);

	-- Run after applyProtectedOptions
	self:applyOtherOptions(initFlag);
end

function primaryClass:applyUnprotectedOptions(initFlag)
	-- initFlag -- true if we should only initialize the object's properties (no display updates, etc).
	local consolidatedObject = self.consolidatedObject;

	-- The super (frameClass) handles all of the unprotected options for primary and consolidated frames.
	self.super.applyUnprotectedOptions(self, initFlag);
	consolidatedObject.super.applyUnprotectedOptions(consolidatedObject, initFlag);
end

function primaryClass:applyOtherOptions(initFlag)
	-- initFlag -- true if we should only initialize the object's properties (no display updates, etc).
	local consolidatedObject = self.consolidatedObject;

	-- The super (frameClass) handles all of the other options for primary and consolidated frames.
	self.super.applyOtherOptions(self, initFlag);
	consolidatedObject.super.applyOtherOptions(consolidatedObject, initFlag);
end

function primaryClass:validateProtectedOptions()
	-- Call at start of primary applyProtectedOptions prior to
	-- testing if protected options cannot be applied due to combat restrictions.

	local frameOptions = self:getOptions();

	-- Don't allow duplicate sortSeq values unless they are constants.FILTER_TYPE_NONE.
	-- If duplicates are found, change the option value to none.

	local temp = {}
	temp.sortSeq1 = frameOptions.sortSeq1 or constants.FILTER_TYPE_DEBUFF;
	temp.sortSeq2 = frameOptions.sortSeq2 or constants.FILTER_TYPE_WEAPON;
	temp.sortSeq3 = frameOptions.sortSeq3 or constants.FILTER_TYPE_BUFF_CANCELABLE;
	temp.sortSeq4 = frameOptions.sortSeq4 or constants.FILTER_TYPE_BUFF_UNCANCELABLE;
	temp.sortSeq5 = frameOptions.sortSeq5 or constants.FILTER_TYPE_NONE;
	for i = 1, 5 do
		local sortSeqA = temp["sortSeq" .. i];
		for j = i + 1, 5 do
			local sortSeqB = temp["sortSeq" .. j];
			if (sortSeqB == sortSeqA and j ~= i and sortSeqB ~= constants.FILTER_TYPE_NONE) then
				-- Convert option to a "none" filter.
				-- We're using sortSeqChanged to avoid clearing
				-- the option that the user just changed.
				-- The var is temporarily set in the options routines.
				local k;
				if (sortSeqChanged == j) then
					k = i;
				else
					k = j;
				end
				temp["sortSeq" .. k] = constants.FILTER_TYPE_NONE;
				frameOptions["sortSeq" .. k] = constants.FILTER_TYPE_NONE;
			end
		end
	end
end

function primaryClass:applyProtectedOptions(initFlag)
	-- Apply button options that require us to be out of combat when dealing with secure frames.
	-- initFlag -- true if we should only initialize the object's properties (no display updates, etc).

	local frameOptions = self:getOptions();

	if (not initFlag) then
		-- Set the flag that gets checked when leaving combat.
		self.needApplyProtected = true;
	end

	-- Validate some options first before we test if combat will prevent us from applying them.
	self:validateProtectedOptions();

	-- Start out by determining some values, but don't change the self.xxxx values
	-- until we are sure we aren't going to return because of combat restrictions, etc.

	-- Determine which unit will be used for the aura frame.
	local unitType = frameOptions.unitType or constants.UNIT_TYPE_PLAYER;

	local unitNormal;
	if (unitType == constants.UNIT_TYPE_TARGET) then
		unitNormal = "target";
	elseif (unitType == constants.UNIT_TYPE_FOCUS) then
		unitNormal = "focus";
	elseif (unitType == constants.UNIT_TYPE_VEHICLE) then
		unitNormal = "vehicle";
	elseif (unitType == constants.UNIT_TYPE_PET) then
		unitNormal = "pet";
	else
		unitNormal = "player";
	end

	-- Determine which type of aura frame will be used (secure or unsecure).
	local playerUnsecure = not not frameOptions.playerUnsecure;

	local useUnsecure;
	if (unitType == constants.UNIT_TYPE_PLAYER or unitType == constants.UNIT_TYPE_VEHICLE) then
		-- Use a secure frame for player or vehicle units unless
		-- the user chose to use an unsecure one.
		useUnsecure = playerUnsecure;
	else
		-- For target, focus, or pet units use an unsecure frame.
		-- We don't need to be able to cancel these buffs, and I
		-- don't know of any way to securely detect if the target or
		-- focus changes and force a reconfiguration during combat.
		-- I can detect target/focus existance changes, but not
		-- target/focus unit changes (the target does not cease to
		-- exist if you switch from one to another without clearing
		-- the target).
		useUnsecure = true;
	end

	local deleteFrame;
	local createFrame;

	local disableWindow = not not frameOptions.disableWindow;

	if (not initFlag) then
		-- Determine if we need to delete and/or create an aura frame,
		-- and check if combat restrictions prevent us from doing so.

		if (disableWindow) then
			-- We need to disable the aura frame
			if (self.auraFrame) then
				if (self.auraFrame:IsProtected() and InCombatLockdown()) then
					-- Can't delete a secure auraFrame while in combat.
					return;
				end
				deleteFrame = true;
			end
		else
			-- We need to enable the aura frame
			if (not self.auraFrame) then
				if (not useUnsecure and InCombatLockdown()) then
					-- Can't create a secure auraFrame while in combat.
					return;
				end
				createFrame = true;
			end
		end

		-- If we have an aura frame...
		if (self.auraFrame) then
			-- Check if we need to switch to a different security mode.
			-- If the desired mode is different than the current mode...
			if (useUnsecure ~= self.useUnsecure) then
				-- We need to change modes.

				-- If the current mode is secure...
				if (self.auraFrame:IsProtected() and InCombatLockdown()) then
					-- Can't delete a secure auraFrame while in combat.
					return;
				end

				-- If the desired mode is secure...
				if (not useUnsecure and InCombatLockdown()) then
					-- Can't change to secure mode while in combat.
					return;
				end

				deleteFrame = true;
				createFrame = true;
			else
				-- We don't need to change modes.

				-- If the aura frame is secure...
				if (self.auraFrame:IsProtected() and InCombatLockdown()) then
					-- We can't apply these options while in combat.
					return;
				end
			end
		end
	end

	-- Clear the flag that gets checked when leaving combat.
	self.needApplyProtected = false;

	-- Code below this point assumes that combat restrictions won't
	-- prevent it from executing.

	local consolidatedObject = self.consolidatedObject;

	if (not initFlag) then
		-- Delete the aura frame if we need to...
		if (deleteFrame and self.auraFrame) then
			-- Delete the buff frame.
			if (not self:deleteBuffFrame()) then
				-- Should never get here, but just to be safe...
				return;
			end
		end
	end

	-- Deal with the unit id and the vehicle buffs flag.

	self.unitNormal = unitNormal;
	self.vehicleBuffs = frameOptions.vehicleBuffs ~= false;

	-- Change the unit id assigned to the window.
	-- If the unit id is different, then it will rescan spells and enchants.
	-- If the old unit id is no longer assigned to any windows, then it will be deleted.

	if (inVehicle and self.vehicleBuffs and self.unitNormal == "player") then
		self:setUnitId("vehicle");
	else
		self:setUnitId(self.unitNormal);
	end

	-- The disable window flag
	self.disableWindow = disableWindow;
	
	-- The disable tooltips flag
	self.disableTooltips = not not frameOptions.disableTooltips;

	-- The security modes
	self.useUnsecure = useUnsecure;
	self.playerUnsecure = playerUnsecure;

	-- Use the same security mode for the consolidated frame.
	consolidatedObject.useUnsecure = useUnsecure;

	if (not initFlag) then
		-- Create an aura frame if we need to...
		if (createFrame) then
			self:createBuffFrame();
		end
	end

	-- Apply some additional protected options for the primary object.
	self.sortSeq1 = frameOptions.sortSeq1 or constants.FILTER_TYPE_DEBUFF;
	self.sortSeq2 = frameOptions.sortSeq2 or constants.FILTER_TYPE_WEAPON;
	self.sortSeq3 = frameOptions.sortSeq3 or constants.FILTER_TYPE_BUFF_CANCELABLE;
	self.sortSeq4 = frameOptions.sortSeq4 or constants.FILTER_TYPE_BUFF_UNCANCELABLE;
	self.sortSeq5 = frameOptions.sortSeq5 or constants.FILTER_TYPE_NONE;

	-- Bug: Originally due to a bug in Blizzard's code, the SEPARATE_OWN_WITH value
	--      acted like the SEPARATE_OWN_BEFORE value.
	--
	--      Note: As of WoW 4.3 they have fixed the bug.
	--            I am now using SEPARATE_OWN_WITH as the default instead of SEPARATE_OWN_BEFORE.
	--
	self.separateOwn = frameOptions.separateOwn or constants.SEPARATE_OWN_WITH;
	self.sortMethod = frameOptions.sortMethod or constants.SORT_METHOD_NAME;
	self.sortDirection = not not frameOptions.sortDirection;
	self.separateZero = frameOptions.separateZero or constants.SEPARATE_ZERO_WITH;
	self.groupByPriority = frameOptions.groupByPriority or constants.GROUP_BY_FILTER_OWN_ZERO;
	
	self.consolidateDuration = (frameOptions.consolidateDurationMinutes or 0) * 60 + (frameOptions.consolidateDurationSeconds or 30);
	self.consolidateThreshold = (frameOptions.consolidateThresholdMinutes or 0) * 60 + (frameOptions.consolidateThresholdSeconds or 10);
	self.consolidateFraction = (frameOptions.consolidateFractionPercent or 10) / 100;

	if (not initFlag) then
		-- Do we need a consolidated frame?
		local needConsolidated;
		for i = 1, 5 do
			local sortSeq = self["sortSeq" .. i];
			if (sortSeq == constants.FILTER_TYPE_CONSOLIDATED) then
				needConsolidated = true;
				break;
			end
		end
		-- If we need one, and primary frame is not disabled, and we don't have one yet...
		if (needConsolidated and not self.disableWindow and not consolidatedObject.auraFrame) then
			-- Create the consolidated aura frame.
			consolidatedObject:createBuffFrame();
		end
	end

	-- Set visibility
	self.visWindow = frameOptions.visWindow or constants.VISIBILITY_SHOW;
	self.visCondition = frameOptions.visCondition or "";
	self.visHideInCombat = not not frameOptions.visHideInCombat;
	self.visHideNotCombat = not not frameOptions.visHideNotCombat;
	self.visHideInVehicle = not not frameOptions.visHideInVehicle;
	self.visHideNotVehicle = not not frameOptions.visHideNotVehicle;
	self:setVisibility();

	-- Apply general frame related protected options for the primary object.
	self.super.applyProtectedOptions(self, initFlag);

	-- Apply general frame related protected options for the consolidated object.
	consolidatedObject.super.applyProtectedOptions(consolidatedObject, initFlag);

	if (not initFlag) then
		-- Force the buttons to be reconfigured.
		self:reconfigureButtons();
	end
end

function primaryClass:setSpecialAttributes()
	self.needSetSpecial = false;
end

function primaryClass:setAttributes()
	-- Set the aura frame's attributes.
	--
	-- Attributes (used only by this addon):
	--
	--	consolidatedFrame -- Name of the consolidated aura frame that we've created
	--	includeWeaponsNormal -- The normal value of the "includeWeapons" attribute. Used by our secure code when entering/leaving a vehicle.
	--	primaryFrame -- Name of the primary aura frame that we've created
	--	separateZero -- Sort zero duration buffs before, after, or with other buffs (1=before, -1=after, 0=with)
	--	groupByPriority -- Sequence for applying buff-type filters/groupings, separateOwn, and separateZero (ranges from 1 to 6, default (1) is Filter > Own > Zero)
	--	unitNormal -- Normal unit id (string) used for the frame (may not equal .unitId if in a vehicle).
	--	vehicleBuffs -- Show vehicle buffs when in a vehicle (only applies if normal unit is "player") (1==yes, false==no, default == yes)
	--
	-- Attributes (secure aura header):
	--
	--	_ignore -- Prevents reconfiguration of the header while setting attributes by setting it to a non-nil value.
	--	consolidateTo -- Consolidate some buffs to a single button (nil or 0 == don't consolidate, negative/positive == position of button)
	--	consolidateDuration -- The minimum total duration an aura should have to be considered for consolidation (Default: 30)
	--	consolidateFraction -- Buffs with less remaining duration than this many seconds should not be consolidated (Default: 10)
	--	consolidateThreshold -- The fraction of remaining duration a buff should still have to be eligible for consolidation (Default: .10)
	--	filter -- Filter for UnitAura()
	--	groupBy -- Comma separated list of filters used to sort the auras into sections within the frame (must have at least one value) (don't use an empty string, use nil instead)
	--	separateOwn -- Sort auras cast by player from others (1 == Sort player before others, -1 == Sort player after others, 0 == Sort player with others)
	--	sortMethod -- Sort by ("NAME", "TIME" or "EXPIRES", "INDEX")
	--	sortDir -- Sort direction ("+" == ascending, "-" == descending)
	--	sortDirection -- Sort direction ("+" == ascending, "-" == descending)
	--	unit -- unit id associated with this aura frame.

	local auraFrame = self.auraFrame;
	if (not auraFrame) then
		return;
	end

	-- If the aura frame is secure...
	if (auraFrame:IsProtected()) then
		if (InCombatLockdown()) then
			-- We can't update secure frame attributes while in combat.
			return;
		end
	end

	-- Set most of the frame attributes
	self.super.setAttributes(self);

	-- Set special attributes
	self:setSpecialAttributes();

	-- Suspend updates via OnAttributeChanged until we've configured everything.
	auraFrame:SetAttribute("_ignore", 1);

	-- Blizard's SecureAuraHeader does not handle units other than "player" well.
	-- For example, if you set the unit to "target", it does not update the
	-- button configuration if you clear your target, or if the target changes.
	--
	auraFrame:SetAttribute("unit", self:getUnitId());

	-- These two attributes are not part of the Secure Aura Header routines.
	-- They are only used by this addon.
	--
	auraFrame:SetAttribute("unitNormal", self.unitNormal);
	auraFrame:SetAttribute("vehicleBuffs", self.vehicleBuffs);

	-- Main aura filter.
	-- We're not using the main filter in this addon. Instead we're using
	-- the groupBy attribute to allow for multiple filters in the same frame.
	self.filter = nil;
	auraFrame:SetAttribute("filter", self.filter);

	-- The aura filters that the user wants to see for each group of buffs.
	-- We need to create a comma separate list of filters.
	self.groupBy = "";
	for i = 1, 5 do
		local sortSeq = self["sortSeq" .. i];
		if (sortSeq == constants.FILTER_TYPE_DEBUFF) then
			self.groupBy = self.groupBy .. "," .. constants.FILTER_TEXT_DEBUFF;
		elseif (sortSeq == constants.FILTER_TYPE_BUFF_CANCELABLE) then
			self.groupBy = self.groupBy .. "," .. constants.FILTER_TEXT_BUFF_CANCELABLE;
		elseif (sortSeq == constants.FILTER_TYPE_BUFF_UNCANCELABLE) then
			self.groupBy = self.groupBy .. "," .. constants.FILTER_TEXT_BUFF_UNCANCELABLE;
		elseif (sortSeq == constants.FILTER_TYPE_BUFF_ALL) then
			self.groupBy = self.groupBy .. "," .. constants.FILTER_TEXT_BUFF_ALL;
		end
	end
	self.groupBy = strsub(self.groupBy, 2);  -- Remove leading comma if present
	auraFrame:SetAttribute("groupBy", self.groupBy);

	-- The sorting method to use.
	local sortMethod = self.sortMethod;
	if (sortMethod == constants.SORT_METHOD_INDEX) then
		sortMethod = "INDEX";
	elseif (sortMethod == constants.SORT_METHOD_TIME) then
		sortMethod = "TIME";
	else -- if (sortMethod == constants.SORT_METHOD_NAME) then
		sortMethod = "NAME";
	end
	auraFrame:SetAttribute("sortMethod", sortMethod);

	-- The direction of the sort.
	--
	-- Bug: Blizzard's code specifies "sortDir" in their comments
	--      but uses "sortDirection" in their code. We'll set both in case
	--      they decide to switch it at some point.
	--
	--      Note: As of WoW 4.3 they've changed the comments to indicate that
	--            "sortDirection" is the correct attribute to use.
	--	      I've commented the code that sets the alternate attribute name.
	--
	if ( not not self.sortDirection ) then
		-- Reverse direction of sort (descending sort)
		auraFrame:SetAttribute("sortDirection", "-");
		--auraFrame:SetAttribute("sortDir", "-");
	else
		-- Ascending sort
		auraFrame:SetAttribute("sortDirection", "+");
		--auraFrame:SetAttribute("sortDir", "+");
	end

	-- Sort buffs player cast before, after, or with those cast by others.
	--
	-- Bug: There is a bug in Blizzard's code that does not properly
	--      handle the "separateOwn" attribute value of 0 (sort player cast
	--      buffs with others). It currently treats 0 as if it were -1 (sort
	--      player cast buffs after others).
	--
	--      Note: As of WoW 4.3 they have fixed this bug.
	--
	local value = self.separateOwn;
	if (value == constants.SEPARATE_OWN_BEFORE) then
		-- Sort buffs player cast before others
		value = 1;
	elseif (value == constants.SEPARATE_OWN_AFTER) then
		-- Sort buffs player cast after others
		value = -1;
	else -- if (value == constants.SEPARATE_OWN_WITH) then
		-- Sort buffs player cast with others
		value = 0;
	end
	auraFrame:SetAttribute("separateOwn", value);

	-- Sort zero duration buffs before, after, or with other buffs; or hide them entirely
	auraFrame:SetAttribute("separateZero", constants.SEPARATE_ZERO[self.separateZero]);
	auraFrame:SetAttribute("filterZero", constants.FILTER_ZERO[self.separateZero]);
	
	-- In what priority should grouping by filters, separateOwn, and separateZero be applied?
	auraFrame:SetAttribute("groupByPriority", self.groupByPriority);

	-- Values used to determine if auras get consolidated.
	auraFrame:SetAttribute("consolidateDuration", self.consolidateDuration);
	auraFrame:SetAttribute("consolidateThreshold", self.consolidateThreshold);
	auraFrame:SetAttribute("consolidateFraction", self.consolidateFraction);

	-- Determine the positions of the weapon and consolidated buttons.
	local weaponPos;
	local consolidatePos;
	local count = 1;
	for i = 1, 5 do
		local sortSeq = self["sortSeq" .. i];
		if (sortSeq == constants.FILTER_TYPE_WEAPON) then
			if (not weaponPos) then
				weaponPos = count;
			end
		elseif (sortSeq == constants.FILTER_TYPE_CONSOLIDATED) then
			if (not consolidatePos) then
				consolidatePos = count;
			end
		elseif (sortSeq ~= constants.FILTER_TYPE_NONE) then
			count = count + 1;
		end
	end

	-- If the unit id is not "player", then turn off weapon buttons.
	if (self:getUnitId() ~= "player") then
		weaponPos = nil;
	end
	-- We'll allow it to show a consolidated button if the user has chosen to do so.

	-- The weaponPos var is now either nil, or a value >= 1
	-- The consolidatePos var is now either nil, or a value >= 1
	--
	-- In both cases, a numeric value indicates that the user wants to
	-- see the corresponding button if those types of buffs are available.
	--
	-- A nil value indicates to this addon that the button should not be shown even if
	-- those types of buffs are available.
	--
	-- In the secure aura header routines, if the weapons and consolidated button
	-- appear at the same position in the sorted list of buffs, then the
	-- weapon buttons (main, offhand, ranged) will appear first, followed by the
	-- consolidated button. There is no way to influence this sequence.

	-- Template to use for the aura buttons
	auraFrame:SetAttribute("template", self:getAuraButtonTemplate());

	-- Weapon enchantment buttons
	if (weaponPos) then
		-- The user wants to see the weapon buttons.

		-- Position of the weapon buttons.
		--
		-- Bug: Blizzard's comments state that if the "includeWeapons" attribute
		--      is 0 or nil then weapon enchants will be ignored. The comment about 0 appears
		--      to be incorrect, but nil will work.
		--
		--      Note: As of WoW 4.3 they fixed this issue. If you set the attribute to 0 then
		--            the updated code will use nil instead.
		--
		auraFrame:SetAttribute("includeWeapons", weaponPos);
		auraFrame:SetAttribute("includeWeaponsNormal", weaponPos); -- This addon's attribute

		-- Template to use for the weapon buttons.
		-- We're creating the weapon buttons ahead of time so this isn't really needed.
		auraFrame:SetAttribute("weaponTemplate", self:getWeaponButtonTemplate());
	else
		-- The user does not want to see the weapon buttons.
		do
			-- Bug: Blizzard does not hide the weapon enchant buttons if you set the
			--      "includeWeapons" attribute to nil. To work around this, hide
			--      the weapon enchant buttons before setting the attribute to nil.
			--
			if (not self.isConsolidated) then
				self:hideWeaponButtons();
			end
		end
		auraFrame:SetAttribute("includeWeapons", nil);
		auraFrame:SetAttribute("includeWeaponsNormal", nil); -- This addon's attribute
		auraFrame:SetAttribute("weaponTemplate", nil);
	end

	-- These attributes are used by the aura header code to keep track of the
	-- previously created weapon enchant buttons, so don't overwrite them.
	--
	-- Reminder: We are creating the weapon buttons ahead of time and using these
	-- attributes to store the buttons.
	--
	--auraFrame:SetAttribute("tempEnchant1", nil);
	--auraFrame:SetAttribute("tempEnchant2", nil);
	--auraFrame:SetAttribute("tempEnchant3", nil);

	-- Consolidated buffs button
	if (consolidatePos) then
		-- The user wants to see a consolidated button.

		-- Position of the consolidated buton (with respect to the groupBy list).
		auraFrame:SetAttribute("consolidateTo", consolidatePos);

		-- The template or button to use as the consolidated button.
		--
		-- The consolidateProxy attribute can be:
		-- 1) nil
		-- 2) the name of an XML template
		-- 3) a button
		--
		-- NOTE: If you assign the name of an XML template to the attribute, once the code
		-- has created the button, it will store the button in this attribute.
		--
		-- In this addon we are creating the consolidated button ourself while out of combat
		-- rather than letting the Secure Aura Header routine to do it.
		auraFrame:SetAttribute("consolidateProxy", auraFrame.consolidatedButton);

		-- The template or frame to use as the consolidated frame.
		--
		-- The consolidateHeader attribute can be:
		-- 1) nil
		-- 2) the name of an XML template
		-- 3) a frame
		--
		-- NOTE: If you assign the name of an XML template to the attribute, once the code
		-- has created the frame, it will store the frame in this attribute.
		--
		-- In this addon we are creating the consolidated frame ourself while out of combat
		-- rather than letting the Secure Aura Header routine to do it.

		local consolidatedFrame = self.consolidatedObject.auraFrame;

		-- Assign some attributes to the consolidated button for this addon's use.
		auraFrame.consolidatedButton:SetAttribute("primaryFrame", auraFrame:GetName());
		auraFrame.consolidatedButton:SetAttribute("consolidatedFrame", consolidatedFrame:GetName());

		-- For a secure frame, assign frame references for the consolidated and aura frames, to the
		-- consolidated button.
		if (auraFrame:IsProtected()) then
			auraFrame.consolidatedButton:SetFrameRef(consolidatedFrame:GetName(), consolidatedFrame);
			auraFrame.consolidatedButton:SetFrameRef(auraFrame:GetName(), auraFrame);
		end

		-- Now set the attribute that is used by the Secure Aura Header routines.
		-- In our case we are setting it to the actual frame we have already created.
		auraFrame:SetAttribute("consolidateHeader", consolidatedFrame);
	else
		-- The user does not want to see a consolidated button.
		do
			-- Bug: Blizzard does not hide the consolidated button if you set the
			--      "consolidateTo" attribute to nil. To work around this, hide
			--      the consolidated button before setting the attribute to nil.
			--
			if (not self.isConsolidated) then
				self:hideConsolidatedButton();
			end
		end
		auraFrame:SetAttribute("consolidateTo", nil);
		auraFrame:SetAttribute("consolidateProxy", nil);
		auraFrame:SetAttribute("consolidateHeader", nil);
	end

	-- Resume updates via OnAttributeChanged
	auraFrame:SetAttribute("_ignore", nil);
end

function primaryClass:getAuraFrameTemplate()
	if (self.useUnsecure) then
		return "CT_BuffMod_UnsecureAuraHeaderTemplate";
	else
		return "CT_BuffMod_SecureAuraHeaderTemplate";
	end
end

function primaryClass:getWeaponButtonTemplate()
	return self:getAuraButtonTemplate();
end

function primaryClass:getConsolidatedButtonTemplate()
	if (self.useUnsecure) then
		return "CT_BuffMod_UnsecureConsolidatedButtonTemplate";
	else
		return "CT_BuffMod_SecureConsolidatedButtonTemplate";
	end
end

function primaryClass:resizeButtons()
	-- Resize all of the buttons associated with the auraFrame.
	local auraFrame = self.auraFrame;
	if (not auraFrame) then
		return;
	end

	local buffSize;
	if (self.buttonStyle == 2) then
		buffSize = self.buffSize2;
	else
		buffSize = self.buffSize1;
	end

	-- Resize spell buttons
	self:resizeSpellButtons();

	-- Resize temporary weapon enchant buttons
	local button;
	for index, slot in pairs(constants.ENCHANT_SLOTS) do
		button = auraFrame:GetAttribute("tempEnchant" .. index);
		if (button) then
			button:SetHeight(buffSize);
			button:SetWidth(buffSize);
		end
	end

	-- Resize the consolidate button
	local button = auraFrame:GetAttribute("consolidateProxy");
	if (button and type(button.Hide) == "function") then
		button:SetHeight(buffSize);
		button:SetWidth(buffSize);
	end
end

function primaryClass:hideConsolidatedButton()
	-- Hide the consolidated button in the aura frame.
	local auraFrame = self.auraFrame;
	if (not auraFrame) then
		return;
	end

	local button = auraFrame:GetAttribute("consolidateProxy");
	if (button and type(button.Hide) == "function") then
		button:Hide();
	end
end

function primaryClass:hideWeaponButtons()
	-- Hide all the weapon buttons in the aura frame.
	local auraFrame = self.auraFrame;
	if (not auraFrame) then
		return;
	end

	-- Hide the temporary weapon enchant buttons.
	local button;
	for index, slot in pairs(constants.ENCHANT_SLOTS) do
		button = auraFrame:GetAttribute("tempEnchant" .. index);
		if (button) then
			button:Hide();
		end
	end
end

function primaryClass:hideAllButtons()
	-- Hide all the buttons in the aura frame.
	local auraFrame = self.auraFrame;
	if (not auraFrame) then
		return;
	end

	-- Hide the spell buttons
	self:hideSpellButtons();

	-- Hide the temporary weapon enchant buttons.
	self:hideWeaponButtons();

	-- Hide the consolidate button
	self:hideConsolidatedButton();
end

function primaryClass:reconfigureButtons()
	-- Force the buttons to be reconfigured.
	-- Returns true if buttons were reconfigured (or there was no auraFrame).

	local auraFrame = self.auraFrame;
	if (not auraFrame) then
		return true;
	end
	if (auraFrame:IsProtected()) then
		if (InCombatLockdown()) then
			return false;
		end
	end

	local consolidatedObject = self.consolidatedObject;

	-- Establish an anchor point such that the frame will
	-- expand in the appropriate direction (but not move)
	-- if the wrapAfter or maxWraps attributes have changed.
	self:setAnchorPoint(true);
	consolidatedObject:setAnchorPoint(true);

	-- Save the newly established anchor point so that we
	-- can restore it after the reconfiguration.
	self:savePosition();
	consolidatedObject:savePosition();

--[[
	do
		-- Bugfix
		--
		-- Bug: Blizzard's code currently has trouble determining the
		--      correct width for the aura frame when the first button's
		--      :GetRight() or :GetTop() value is negative.
		--
		--      To avoid this issue we will temporarily shrink the frame
		--      to 1 x 1 and reposition it on the screen such that the
		--      :GetRight() and :GetTop() values of the button will not
		--      be negative.
		--
		--      Note: As of WoW 4.3 they have fixed this bug.
		--
		self:shrinkAndCenterAuraFrame();
		consolidatedObject:shrinkAndCenterAuraFrame();
	end
--]]

	do
		-- Bugfix
		--
		-- Bug: Once Blizzard has shown an aura button it will continue to be displayed even
		--      if you reduce the maxWraps or wrapAfter attributes. It will only get hidden
		--      if the buff wears off or is cancelled.
		--      They are not hiding buttons that are still displayed beyond the number of
		--      buffs that you want to see (maxWraps * wrapAfter).
		--      To compensate for this bug, we will hide the buttons before we force the
		--      reconfiguration.
		--
		--      Note: As of build 14980 on the 4.3 PTR the fix for this bug has a problem.
		--
		self:hideAllButtons();
		consolidatedObject:hideAllButtons();
	end

	-- Force reconfiguration of the primary frame buttons by setting a dummy attribute.
	-- As part of the reconfiguration, Blizzard will adjust the width and height of
	-- the aura frames (primary and consolidated frames).
	auraFrame:SetAttribute("dummy", nil);

	-- Set the border and clamping. This will take into account
	-- any changes made to the .auraEdgeLeft and .auraEdgeRight
	-- values in the :SetAttributes() call.
	self:setBorder();
	self:setClamped();
	consolidatedObject:setBorder();
	consolidatedObject:setClamped();

	-- Restore the frame's position, but not the saved height or width.
	-- We want to use the height and width established by Blizzard during
	-- the reconfiguration.
	self:restorePosition(true);
	consolidatedObject:restorePosition(true);

	return true;
end

--[[
function primaryClass:fixWeaponSlotNumbers()
	-- BugFix
	--
	-- Fix the slot numbers assigned to the temporary weapon enchant aura buttons.
	--
	-- Bug: Blizzard currently is putting the wrong slot number on the off hand button.
	--      This will correct the slot number as long as the player is not in combat
	--      when this function is called.
	--
	--      Note: As of WoW 4.3 they have fixed this bug.
	--

	local auraFrame = self.auraFrame;
	if (not auraFrame) then
		return;
	end
	if (not auraFrame:IsShown()) then
		return;
	end
	local button;
	for index, slot in pairs(constants.ENCHANT_SLOTS) do
		button = auraFrame:GetAttribute("tempEnchant" .. index);
		if (button) then
			if (button:IsVisible()) then
				-- Bugfix
				-- If we're not in combat, then correct Blizzard's incorrect slot number
				-- for the offhand weapon.
				if (not InCombatLockdown() and slot ~= button:GetAttribute("target-slot")) then
					button:SetAttribute("target-slot", slot);
					button:SetID(slot);
				end
			end
		end
	end
end
--]]

function primaryClass:refreshWeaponButtons()
	self:updateWeaponButtons(auraButton_updateAppearance);
end

function primaryClass:updateWeaponButtons(func)
	-- Update buttons for the primary frame.

	local auraFrame = self.auraFrame;
	if (not auraFrame) then
		return;
	end
	if (not auraFrame:IsShown()) then
		return;
	end

	-- Update temporary weapon enchants
	local button;
	for index, slot in pairs(constants.ENCHANT_SLOTS) do
		button = auraFrame:GetAttribute("tempEnchant" .. index);
		if (button) then
			if (button:IsVisible()) then
				button.frameObject = self;
				button.unitObject = nil;
				button.auraObject = nil;
				button.mode = constants.BUTTONMODE_ENCHANT;
				button.index = index;
				button.filter = button:GetAttribute("target-slot");

				-- Bugfix
				--
				-- Bug: Blizzard currently provides the wrong slot for the off hand enchant.
				--      Use the value in our constants.ENCHANT_SLOTS table for now.
				--      Note: This won't allow cancelling of the correct buff, but we can
				--      at least show the correct one.
				--
				--      Note: As of WoW 4.3 they have fixed this bug.
				--
				--button.filter = slot;

				-- Bugfix
				--
				-- Bug: If we're not in combat, then correct Blizzard's incorrect slot number
				--      for the offhand weapon.
				--
				--      Note: As of WoW 4.3 they have fixed this bug.
				--
				--if (not InCombatLockdown() and slot ~= button:GetAttribute("target-slot")) then
				--	button:SetAttribute("target-slot", slot);
				--	button:SetID(slot);
				--end

				func(button);
			end
		end
	end
end

function primaryClass:updateAuraButtons(func)
	-- Update buttons for the primary frame.

	local auraFrame = self.auraFrame;
	if (not auraFrame) then
		return;
	end
	if (not auraFrame:IsShown()) then
		return;
	end

	-- Update spell buttons.
	self:updateSpellButtons(func);

	-- Update temporary weapon enchants
	self:updateWeaponButtons(func);

	-- Update consolidate button
	local button = auraFrame:GetAttribute("consolidateProxy");
	if (button and type(button.Hide) == "function" and button:IsVisible()) then
		button.frameObject = self;
		button.unitObject = nil;
		button.auraObject = nil;
		button.mode = constants.BUTTONMODE_CONSOLIDATED;
		button.index = nil;
		button.filter = nil;
		func(button);
	end
end

local function primaryAuraFrame_OnEvent(auraFrame, event, arg1)
	local frameObject = auraFrame.frameObject;

	if (not frameObject) then
		return;
	end
	if (frameObject.disableWindow) then
		return;
	end

	if (event == "UNIT_AURA") then
		-- If the unit associated with the aura event is assigned to this frame...
		if (frameObject:getUnitId() == arg1) then
			-- We don't need to reconfigure the buttons, since the
			-- Secure Aura routines already do that for this event.
			-- The global frame does the buff rescan.
			-- Set the flag to indicate we need a visual update.
			C_Timer.After(0.0005, auraFrame.refreshTickerFunc);
		end

	elseif (event == "UNIT_PET") then
		if (arg1 == "player" and frameObject:getUnitId() == "pet") then
			if (frameObject:reconfigureButtons()) then
				C_Timer.After(0.0005, auraFrame.refreshTickerFunc);
			else
				frameObject.needReconfigure = true;
			end
		end

	elseif (event == "PLAYER_REGEN_DISABLED") then
		-- Entering combat.

		-- If aura frame is being moved then allow it to continue being moved.
		-- Any restrictions on moving the frame were checked for before we
		-- allowed the frame to start moving.

		-- For a protected frame...
		if (auraFrame:IsProtected()) then
			-- Update anything that might need to be done before it gets locked down
			if (frameObject:reconfigureButtons()) then
				C_Timer.After(0.0005, auraFrame.refreshTickerFunc);
			end
		end

	elseif (event == "PLAYER_REGEN_ENABLED") then
		-- Leaving combat.

		-- BugFix
		--
		-- Bug: Correct any incorrect weapon slot numbers assigned to weapon enchant aura buttons by Blizzard.
		--
		--      Note: As of WoW 4.3 they have fixed this bug.
		--
		--frameObject:fixWeaponSlotNumbers();

		if (frameObject.needApplyProtected) then
			-- Apply options that we could not alter during combat,
			-- and re-anchor the aura frame.
			frameObject:applyProtectedOptions(false);
		end
		if (frameObject.needSetSpecial) then
			frameObject:setSpecialAttributes();
		end
		
		if (frameObject.needReconfigure and frameObject:reconfigureButtons()) then
			C_Timer.After(0.0005, auraFrame.refreshTickerFunc);
			frameObject.needReconfigure = nil;
		end
			

	elseif (event == "PLAYER_TARGET_CHANGED") then
		if (frameObject:getUnitId() == "target") then
			-- The global frame does the buff rescan.
			-- Set the flag to indicate we need a reconfiguration.
			if (frameObject:reconfigureButtons()) then
				C_Timer.After(0.0005, auraFrame.refreshTickerFunc);
			else
				frameObject.needReconfigure = true;
			end
		end

	elseif (event == "PLAYER_FOCUS_CHANGED") then
		if (frameObject:getUnitId() == "focus") then
			-- The global frame does the buff rescan.
			-- Set the flag to indicate we need a reconfiguration.
			if (frameObject:reconfigureButtons()) then
				C_Timer.After(0.0005, auraFrame.refreshTickerFunc);
			else
				frameObject.needReconfigure = true;
			end
		end

	elseif (event == "UNIT_ENTERED_VEHICLE") then
		if (arg1 == "player") then

			inVehicle = true;

			if (not auraFrame:IsProtected()) then
				local unitNormal = auraFrame:GetAttribute("unitNormal") or "player";

				-- Only change units if the normal one is "player".
				if (unitNormal == "player") then

					if (auraFrame:GetAttribute("vehicleBuffs")) then

						-- Hide the weapon buttons (the aura header
						-- routines won't hide them for us).
						auraFrame:SetAttribute("_ignore", 1);
						auraFrame:SetAttribute("includeWeapons", nil);
						auraFrame:SetAttribute("_ignore", nil);
						frameObject:hideWeaponButtons();

						-- Switch to the vehicle unit.
						-- Changing the unit attribute will cause the frameObject's
						-- unitId to be changed in the OnAttributeChanged script,
						-- and that will lead to an update of the buttons.
						auraFrame:SetAttribute("unit", "vehicle");
					end
				end
			end
		end

	elseif (event == "UNIT_EXITED_VEHICLE") then
		if (arg1 == "player") then

			inVehicle = false;

			if (not auraFrame:IsProtected()) then
				local unit = auraFrame:GetAttribute("unit") or "player";
				local unitNormal = auraFrame:GetAttribute("unitNormal") or "player";

				-- Only change the unit if the normal one for this frame is "player".
				--
				-- Since this section of code deals with an unprotected frame,
				-- if the user changed the unit while in the vehicle, then
				-- the frame is already configured for the normal unit.
				--
				-- Also keep in mind that all primary aura frames will get this
				-- event even if they weren't showing vehicle buffs.

				if (unitNormal == "player") then
					-- Only switch if the normal unit was "player" and
					-- the frame was showing a vehicle.
					if (unit == "vehicle") then
						-- Restore the weapon buttons status.
						auraFrame:SetAttribute("_ignore", 1);
						auraFrame:SetAttribute("includeWeapons", auraFrame:GetAttribute("includeWeaponsNormal"));
						auraFrame:SetAttribute("_ignore", nil);

						-- Switch back to the normal unit for this frame.
						-- Changing the unit attribute will cause the frameObject's
						-- unitId to be changed in the OnAttributeChanged script,
						-- and that will lead to an update of the buttons.
						auraFrame:SetAttribute("unit", "player");
					end

				elseif (unitNormal == "vehicle" or unitNormal == "pet") then
					-- If the frame's normal unit is "vehicle" or "pet"...
					--
					-- When you exit a vehicle you will no longer receive UNIT_AURA
					-- events for the vehicle. Any buffs still showing in the frame
					-- will stay there and continue counting down until they reach 0
					-- and get stuck. There is no UNIT_AURA event to make us rescan
					-- for the normal unit after you exit.
					--
					-- The same thing happens if the normal unit is "pet". While in
					-- the vehicle the pet frame shows vehicle buffs. If you get out
					-- and you don't have a pet, the aura frame won't get a UNIT_AURA
					-- event for a pet, and the vehicle buffs will remain visible.
					--
					-- To avoid this we need to rescan buffs on the unit.
					-- At the time of this event, the game may still tell us that
					-- there are buffs assigned to the vehicle, so we have to do the
					-- scans via a timer.
					frameObject.rescanTickerFunc = frameObject.rescanTickerFunc or function()
						if (frameObject:getUnitId() ~= unitNormal or frameObject.rescanTicks == 10) then
							frameObject.rescanTicker:Cancel()
							frameObject.rescanTicker = nil;
						else
							-- Try to update spells and enchantments for the unit
							globalObject.unitListObject:updateSpellsAndEnchants(frameObject.needRescanUnit);
							
							-- Try to force a full button reconfiguration.
							if (frameObject:reconfigureButtons()) then
								C_Timer.After(0.0005, auraFrame.refreshTickerFunc);
							else
								frameObject.needReconfigure = true;
							end
							frameObject.rescanTicks = frameObject.rescanTicks  + 1;
						end
					end
					frameObject.rescanTicks = 0;
					frameObject.rescanTicker = frameObject.rescanTicker or C_Timer.NewTicker(2, frameObject.rescanTickerFunc);
				end
			end
		end
	end
end

local function primaryAuraFrame_OnAttributeChanged(auraFrame, name, value)
	local frameObject = auraFrame.frameObject;

	if (not frameObject) then
		return;
	end
	if (frameObject.disableWindow) then
		return;
	end

	-- Attribute names arrive in lower case.
	if ( name == "_ignore" or auraFrame:GetAttribute("_ignore") ) then
		return;
	end

	if (name == "unit") then
		-- The unit attribute changed.
		-- The Secure Aura Header has reconfigured the buttons.
		-- If the new unit id is different then :setUnitId() will
		-- rescan the buffs and request a visual update
		frameObject:setUnitId(value);
	elseif (
		   name == "_mainenchanted"
		or name == "_secondaryenchanted"
-- rng		or name == "_rangedenchanted"   -- Bug: Not sure which name Blizzard will use if they add support for ranged weapon enchant.
-- rng		or name == "_rangeenchanted"    -- Bug: Not sure which name Blizzard will use if they add support for ranged weapon enchant.
	) then
		-- The Secure Aura Header routine has detected a change in the
		-- weapon enchants and set one of these attributes to notify us
		-- of the change (similar to a UNIT_AURA event for a spell buff).
		-- The Secure Aura Header has reconfigured the buttons.
		-- Rescan the enchants and then request a visual update.
		-- Bug: Blizzard does not detect if a weapon buff is applied onto an already buffed weapon.
		frameObject:updateEnchants();
		C_Timer.After(0.0005, auraFrame.refreshTickerFunc);
	else
		-- An attribute was changed on the primary aura frame.
		-- The Secure Aura Header has reconfigured the buttons.
		-- We need to perform a visual update.
		C_Timer.After(0.0005, auraFrame.refreshTickerFunc);
	end
end

local function primaryAuraFrame_OnShow(auraFrame)
	local frameObject = auraFrame.frameObject;

	if (not frameObject) then
		return;
	end

	-- The Secure Aura Header does a button reconfiguration
	-- when the aura frame gets shown.

	-- Update spells and enchants, then request a visual update.
	frameObject:updateSpellsAndEnchants();
	C_Timer.After(0.0005, auraFrame.refreshTickerFunc);

	if (auraFrame.altFrame) then
		auraFrame.altFrame:Show();
	end
end

local function primaryAuraFrame_OnHide(auraFrame)
	local frameObject = auraFrame.frameObject;

	if (not frameObject) then
		return;
	end

	if (auraFrame.altFrame) then
		auraFrame.altFrame:Hide();
	end
end

function primaryClass:setAuraFrameScripts()
	-- Set aura frame scripts.
	local auraFrame = self.auraFrame;
	if (not auraFrame) then
		return;
	end

	-- Return if we've already hooked them.
	if (auraFrame.scriptsHooked) then
		return;
	end

	-- Some of these scripts are already in use by the secure aura
	-- routines so we can't just use :SetScript().
	auraFrame.refreshTickerFunc = function() local frame = auraFrame.frameObject; if frame then frame:refreshAuraButtons() end end;
	auraFrame:HookScript("OnEvent", primaryAuraFrame_OnEvent);
	auraFrame:HookScript("OnAttributeChanged", primaryAuraFrame_OnAttributeChanged);
	auraFrame:HookScript("OnShow", primaryAuraFrame_OnShow);
	auraFrame:HookScript("OnHide", primaryAuraFrame_OnHide);

	auraFrame.scriptsHooked = true;
end

local function primaryAltFrame_OnMouseDown(altFrame, button)
	local auraFrame = altFrame.auraFrame;
	if (auraFrame) then
		local frameObject = auraFrame.frameObject;
		if (frameObject) then
			if (button == "LeftButton") then
				if (IsAltKeyDown()) then
					-- Open the options window and select the correct window.
					module:options_editWindow(frameObject:getWindowId());
				else
					frameObject:startMoving();
				end
			end
		end
	end
end

local function primaryAltFrame_OnMouseUp(altFrame, button)
	local auraFrame = altFrame.auraFrame;
	if (auraFrame) then
		local frameObject = auraFrame.frameObject;
		if (frameObject) then
			if (button == "LeftButton") then
				frameObject:stopMoving();
			end
		end
	end
end

local function primaryAltFrame_OnEnter(altFrame)
	local auraFrame = altFrame.auraFrame;
	if (not auraFrame) then
		return;
	end
	local frameObject = auraFrame.frameObject;
	if (not frameObject) then
		return;
	end

	local windowId = frameObject:getWindowId();
	if ( (isOptionsFrameShown() or isControlPanelShown()) and windowId ) then
		-- See also the auraFrame OnEnter script.
		GameTooltip:SetOwner(altFrame, "ANCHOR_CURSOR");
		GameTooltip:SetText(format(L["CT_BuffMod/WindowTitle"],windowId));
		GameTooltip:AddLine(L["CT_BuffMod/Options/WindowControls/AltClickHint"]);
		GameTooltip:Show();
	end
end

local function primaryAltFrame_OnLeave(altFrame)
	local auraFrame = altFrame.auraFrame;
	if (not auraFrame) then
		return;
	end
	local frameObject = auraFrame.frameObject;
	if (not frameObject) then
		return;
	end

	GameTooltip:Hide();
end

function primaryClass:setAltFrameScripts()
	local auraFrame = self.auraFrame;
	if (not auraFrame) then
		return;
	end

	local altFrame = auraFrame.altFrame;

	-- Return if we've already hooked them.
	if (altFrame.scriptsHooked) then
		return;
	end

	altFrame:HookScript("OnMouseUp", primaryAltFrame_OnMouseUp);
	altFrame:HookScript("OnMouseDown", primaryAltFrame_OnMouseDown);
	altFrame:HookScript("OnEnter", primaryAltFrame_OnEnter);
	altFrame:HookScript("OnLeave", primaryAltFrame_OnLeave);

	altFrame.scriptsHooked = true;
end

local function consolidatedButton_OnMouseDown(self, button)
	local frameObject = self.frameObject;
	if (frameObject) then
		if (button == "LeftButton") then
			if (IsAltKeyDown()) then
				-- Open the options window and select the correct window.
				module:options_editWindow(frameObject:getWindowId());
			else
				frameObject:startMoving();
			end
		end
	end
end

local function consolidatedButton_OnMouseUp(self, button)
	local frameObject = self.frameObject;
	if (frameObject) then
		if (button == "LeftButton") then
			frameObject:stopMoving();
		end
	end
end

local function consolidatedButton_OnEnter(self)
	-- Unsecure consolidated button OnEnter
	local consolidatedFrame = self.auraFrame:GetAttribute("consolidateHeader");
	local primaryFrame = self.auraFrame;

	consolidatedFrame:Show();

	local __, __, frameWidth = consolidatedFrame:GetRect();

	local buttonLeft, __, buttonWidth = self:GetRect();
	local buttonRight = buttonLeft + buttonWidth;

	local anchorToEdgeLeft = consolidatedFrame:GetAttribute("anchorToEdgeLeft");
	local anchorToEdgeRight = consolidatedFrame:GetAttribute("anchorToEdgeRight");
	--local anchorToEdgeTop = consolidatedFrame:GetAttribute("anchorToEdgeTop");	--not used
	--local anchorToEdgeBottom = consolidatedFrame:GetAttribute("anchorToEdgeBottom");	--not used
	local rightAlignIcon1 = primaryFrame:GetAttribute("rightAlignIcon1");
	local buttonStyle = primaryFrame:GetAttribute("buttonStyle");

	local isDetailRight;
	if (buttonStyle == 1) then
		isDetailRight = not rightAlignIcon1; -- true == detail frame on right, false == on left
	else
		isDetailRight = nil;  -- nil == no detail frame
	end

	frameWidth = frameWidth + anchorToEdgeLeft + anchorToEdgeRight;

	local uiparent = primaryFrame:GetParent();

	local parentWidth = uiparent:GetWidth();
	--local parentHeight = uiparent:GetHeight();	--not used

	local showRight;
	if (isDetailRight == true) then
		-- Don't show consolidated on right since the detail frame is there.
		showRight = false;
	elseif (isDetailRight == false) then
		-- Don't show consolidated on left since the detail frame is there.
		showRight = true;
	else
		-- There is no detail frame, so pick a side
		if (frameWidth < buttonLeft) then
			showRight = false;
		else
			showRight = true;
		end
	end

	local anchorP, relativeP, xoffset, yoffset;

	if (showRight) then
		if (frameWidth > max(parentWidth - buttonRight, 0)) then
			-- Show on left
			showRight = false;
		end
	else
		if (frameWidth > buttonLeft) then
			showRight = true;
		end
	end

	if (showRight) then
		-- Show on right of button
		anchorP = "TOPLEFT";
		relativeP = "TOPRIGHT";
		xoffset = anchorToEdgeLeft;
		yoffset = 0;
	else
		-- Show on left of button
		anchorP = "TOPRIGHT";
		relativeP = "TOPLEFT"
		xoffset = -anchorToEdgeRight;
		yoffset = 0;
	end

	consolidatedFrame:ClearAllPoints();
	consolidatedFrame:SetPoint(anchorP, self, relativeP, xoffset, yoffset);

	local seconds = consolidatedFrame:GetAttribute("consolidatedHideTimer");
	autoHide_set(consolidatedFrame, self, seconds);
end

local function consolidatedButton_OnHide(self)
	local consolidatedFrame = self.auraFrame:GetAttribute("consolidateHeader");
	consolidatedFrame:Hide();
end

local consolidatedButton_snippet_onenter = [=[
	-- The mouse has entered the consolidated button.

	-- Get some frame references.
	local primaryFrameName = self:GetAttribute("primaryFrame");
	local primaryFrame = self:GetFrameRef(primaryFrameName);
	local consolidatedFrameName = self:GetAttribute("consolidatedFrame");
	local consolidatedFrame = self:GetFrameRef(consolidatedFrameName);

	-- Show the frame
	consolidatedFrame:Show();

	-- Figure out which side of the button we want to show the consolidated frame.
	local frameLeft, frameBottom, frameWidth, frameHeight = consolidatedFrame:GetRect();

	local buttonLeft, buttonBottom, buttonWidth, buttonHeight = self:GetRect();
	local buttonRight = buttonLeft + buttonWidth;

	local anchorToEdgeLeft = consolidatedFrame:GetAttribute("anchorToEdgeLeft");
	local anchorToEdgeRight = consolidatedFrame:GetAttribute("anchorToEdgeRight");
	local anchorToEdgeTop = consolidatedFrame:GetAttribute("anchorToEdgeTop");
	local anchorToEdgeBottom = consolidatedFrame:GetAttribute("anchorToEdgeBottom");
	local rightAlignIcon1 = primaryFrame:GetAttribute("rightAlignIcon1");
	local buttonStyle = primaryFrame:GetAttribute("buttonStyle");

	local isDetailRight;
	if (buttonStyle == 1) then
		isDetailRight = not rightAlignIcon1; -- true == detail frame on right, false == on left
	else
		isDetailRight = nil;  -- nil == no detail frame
	end

	frameWidth = frameWidth + anchorToEdgeLeft + anchorToEdgeRight;  -- altFrame width

	local uiparent = primaryFrame:GetParent();

	local parentWidth = uiparent:GetWidth();
	local parentHeight = uiparent:GetHeight();

	local showRight;
	if (isDetailRight == true) then
		-- Don't show consolidated on right since the detail frame is there.
		showRight = false;
	elseif (isDetailRight == false) then
		-- Don't show consolidated on left since the detail frame is there.
		showRight = true;
	else
		-- There is no detail frame, so pick a side
		if (frameWidth < buttonLeft) then
			showRight = false;
		else
			showRight = true;
		end
	end

	local anchorP, relativeP, xoffset, yoffset;

	if (showRight) then
		if (frameWidth > max(parentWidth - buttonRight, 0)) then
			-- Show on left
			showRight = false;
		end
	else
		if (frameWidth > buttonLeft) then
			showRight = true;
		end
	end

	if (showRight) then
		-- Show on right of button
		anchorP = "TOPLEFT";
		relativeP = "TOPRIGHT";
		xoffset = anchorToEdgeLeft;
		yoffset = 0;
	else
		-- Show on left of button
		anchorP = "TOPRIGHT";
		relativeP = "TOPLEFT"
		xoffset = -anchorToEdgeRight;
		yoffset = 0;
	end

	-- Anchor the consolidated frame to the consolidated button.
	consolidatedFrame:ClearAllPoints();
	consolidatedFrame:SetPoint(anchorP, self, relativeP, xoffset, yoffset);

	-- Do this after repositioning the frame otherwise the repositioning cancels the autohide.
	-- This will autohide the consolidated frame after n seconds if the mouse is not over
	-- the consolidated frame or the consolidated button.
	local seconds = consolidatedFrame:GetAttribute("consolidatedHideTimer");
	consolidatedFrame:RegisterAutoHide(seconds);  -- watch the frame
	consolidatedFrame:AddToAutoHide(self);  -- watch the button
]=];

--[[

local consolidatedButton_snippet_onleave = [=[
	-- Hide the consolidated frame when the mouse leaves the consolidated button.
	local consolidatedFrameName = self:GetAttribute("consolidatedFrame");
	local consolidatedFrame = self:GetFrameRef(consolidatedFrameName);
	consolidatedFrame:Hide();
]=];

--]]

local consolidatedButton_snippet_onhide = [=[
	-- Hide the consolidated frame when the consolidated button gets hidden.
	local consolidatedFrameName = self:GetAttribute("consolidatedFrame");
	local consolidatedFrame = self:GetFrameRef(consolidatedFrameName);
	consolidatedFrame:Hide();
]=];

function primaryClass:createConsolidatedButton()
	-- Create the consolidated button
	local auraFrame = self.auraFrame;
	if (not auraFrame) then
		return;
	end

	-- Return if we've already created this button.
	if (auraFrame.consolidatedButton) then
		return;
	end

	-- Create the consolidated button as a frame.
	local template = self:getConsolidatedButtonTemplate();
	local consolidatedButton = CreateFrame("Frame", nil, auraFrame, template);

	auraFrame.consolidatedButton = consolidatedButton;
	consolidatedButton.auraFrame = auraFrame;

	-- Set up a mechanism to show/hide the consolidated frame when the
	-- mouse enter/leaves the consolidated button.

	if (auraFrame:IsProtected()) then
		-- Secure frame handling.
		consolidatedButton:SetAttribute("_onenter", consolidatedButton_snippet_onenter);
--		consolidatedButton:SetAttribute("_onleave", consolidatedButton_snippet_onleave);
		consolidatedButton:SetAttribute("_onhide", consolidatedButton_snippet_onhide);
	else
		-- Scripts to use for an unsecure frame.
		consolidatedButton:SetScript("OnEnter", consolidatedButton_OnEnter);
--		consolidatedButton:SetScript("OnLeave", consolidatedButton_OnLeave);
		consolidatedButton:SetScript("OnHide", consolidatedButton_OnHide);
	end
	consolidatedButton:SetScript("OnMouseDown", consolidatedButton_OnMouseDown);
	consolidatedButton:SetScript("OnMouseUp", consolidatedButton_OnMouseUp);

	-- Set the initial size of the button.
	local buffSize;
	if (self.buttonStyle == 2) then
		buffSize = self.buffSize2;
	else
		buffSize = self.buffSize1;
	end
	consolidatedButton:SetHeight(buffSize);
	consolidatedButton:SetWidth(buffSize);

	-- Start out with it hidden.
	consolidatedButton:Hide();
end

function primaryClass:createWeaponButtons()
	-- Create the weapon buttons
	local auraFrame = self.auraFrame;
	if (not auraFrame) then
		return;
	end

	-- Return if we've already created these buttons.
	if (auraFrame.weaponButtons) then
		return;
	end

	auraFrame.weaponButtons = {};

	-- Create the weapon buttons.
	local template = self:getWeaponButtonTemplate();
	for i = 1, 3 do
		local weaponButton = CreateFrame("Button", nil, auraFrame, template);

		auraFrame.weaponButtons[i] = weaponButton;

		-- Set the initial size of the button.
		local buffSize;
		if (self.buttonStyle == 2) then
			buffSize = self.buffSize2;
		else
			buffSize = self.buffSize1;
		end
		weaponButton:SetHeight(buffSize);
		weaponButton:SetWidth(buffSize);

		-- Start out with it hidden.
		weaponButton:Hide();
	end

	-- Configure some attributes now rather than wait for :setAttributes().
	-- These will never need to be changed now that the buttons have been created.

	-- Suspend updates via OnAttributeChanged until we've configured everything.
	auraFrame:SetAttribute("_ignore", 1);

	-- For a secure frame, set up a frame reference to the weapon buttons we've created.
	if (auraFrame:IsProtected()) then
		for i = 1, 3 do
			SecureHandlerSetFrameRef(auraFrame, auraFrame:GetName() .. "Weapon" .. i, auraFrame.weaponButtons[i]);
		end
	end

	-- Set the attributes that are used by the Secure Aura Header routines.
	-- In our case we are setting them to the actual buttons we have already created.
	for i = 1, 3 do
		auraFrame:SetAttribute("tempEnchant" .. i, auraFrame.weaponButtons[i]);
	end

	-- Resume updates via OnAttributeChanged
	auraFrame:SetAttribute("_ignore", nil);
end

function primaryClass:registerAuraFrameEvents()
	-- Register some aura frame events.
	local auraFrame = self.auraFrame;
	if (not auraFrame) then
		return;
	end

	auraFrame:RegisterEvent("PLAYER_REGEN_DISABLED");
	auraFrame:RegisterEvent("PLAYER_REGEN_ENABLED");
	auraFrame:RegisterEvent("PLAYER_TARGET_CHANGED");
	auraFrame:RegisterEvent("UNIT_PET");
	auraFrame:RegisterEvent("UNIT_AURA");				-- Reminder: The secure aura routines also register UNIT_AURA
	if (VehicleMenuBar) then
		-- Introduced in WotLK
		auraFrame:RegisterEvent("UNIT_ENTERED_VEHICLE");
		auraFrame:RegisterEvent("UNIT_EXITED_VEHICLE");
	end
	if (FocusFrame) then
		-- Introduced in BC
		auraFrame:RegisterEvent("PLAYER_FOCUS_CHANGED");
	end

end

function primaryClass:unregisterAuraFrameEvents()
	-- Unregister some aura frame events.
	local auraFrame = self.auraFrame;
	if (not auraFrame) then
		return;
	end

	auraFrame:UnregisterEvent("PLAYER_REGEN_DISABLED");
	auraFrame:UnregisterEvent("PLAYER_REGEN_ENABLED");
	auraFrame:UnregisterEvent("PLAYER_TARGET_CHANGED");
	auraFrame:UnregisterEvent("UNIT_PET");
	auraFrame:UnregisterEvent("UNIT_AURA");
	if (VehicleMenuBar) then
		-- Introduced in WotLK
		auraFrame:UnregisterEvent("UNIT_ENTERED_VEHICLE");
		auraFrame:UnregisterEvent("UNIT_EXITED_VEHICLE");
	end
	if (FocusFrame) then
		-- Introduced in BC
		auraFrame:UnregisterEvent("PLAYER_FOCUS_CHANGED");
	end
end

function primaryClass:registerStateDrivers()
	local auraFrame = self.auraFrame;
	if (not auraFrame) then
		return;
	end

	if (auraFrame:IsProtected()) then
		local stateFrame = auraFrame.stateFrame;
		RegisterStateDriver(stateFrame, "vehicleState", "[vehicleui] in; out");
	end
end

function primaryClass:unregisterStateDrivers()
	local auraFrame = self.auraFrame;
	if (not auraFrame) then
		return;
	end

	if (auraFrame:IsProtected()) then
		local stateFrame = auraFrame.stateFrame;
		UnregisterStateDriver(stateFrame, "vehicleState");
	end

	UnregisterStateDriver(auraFrame, "visibility");
end

function primaryClass:createStateFrame()
	-- Create a state frame for use with a protected aura frame.
	--
	-- We're using this to detect state changes such as entering
	-- and leaving a vehicle so that we can change the unit assigned
	-- to a protected aura frame if we're in combat.

	local auraFrame = self.auraFrame;
	if (not auraFrame) then
		return;
	end

	-- Return if we've already created the frame.
	if (auraFrame.stateFrame) then
		return;
	end

	-- Create the state frame.
	local stateFrame = CreateFrame("Frame", nil, auraFrame, "SecureHandlerStateTemplate");

	auraFrame.stateFrame = stateFrame;
	stateFrame:SetAttribute("primaryFrameName", auraFrame:GetName());
	stateFrame:SetFrameRef(auraFrame:GetName(), auraFrame);

	--[[
	Secure frames and entering/exiting vehicles:

	When you get into a vehicle:
	1. The "vehicleState" attribute of the stateFrame is set to "in"
	2. The code snippet for "_onstate-vehicleState" is run.
	3. The snippet changes the "unit" attribute of the auraFrame only if the normal unit of the
	   frame is "player", and then only if the "vehicleBuffs" attribute is true.
	4. If the "unit" attribute was changed, then the auraFrame's OnAttributeChanged script updates
	   the primaryObject's unitId, and sets the "frame needs an update" flag.

	When you get out of a vehicle:
	1. The "vehicleState" attribute of the stateFrame is set to "out"
	2. The code snippet for "_onstate-vehicleState" is run.
	3. The snippet changes the "unit" attribute of the auraFrame back to the normal unit only if the
	   normal unit of the frame is "player".
	4. If the "unit" attribute was changed, then the auraFrame's OnAttributeChanged script updates
	   the primaryObject's unitId, and sets the "frame needs an update" flag.

	The auraFrame's OnEvent script watches for UNIT_ENTERED_VEHICLE, and when found sets the
	variable inVehicle to true.

	The auraFrame's OnEvent script watches for UNIT_EXITED_VEHICLE, and when found sets the
	variable inVehicle to false.

	The inVehicle variable is used in the primaryObject:applyProtectedOptions function
	to determine whether to set the primaryObject's unitId value to "vehicle" or the value in
	the "unitNormal" attribute.
	--]]

	local snippet =	[=[
		local frameName = self:GetAttribute("primaryFrameName");
		local auraFrame = self:GetFrameRef(frameName);

		local unitNormal = auraFrame:GetAttribute("unitNormal") or "player";
		if (unitNormal == "player") then
			-- Only change the unit if the normal unit of this frame is "player".
			if (newstate == "in") then
				-- When getting "in", only change unit if player wants to see vehicle buffs.

				if (auraFrame:GetAttribute("vehicleBuffs")) then
					-- First, turn off weapon buffs.
					auraFrame:SetAttribute("includeWeapons", nil);

					-- Hide the weapon buttons in case they were already shown.
					for i = 1, 3 do
						local weaponButton = auraFrame:GetFrameRef(auraFrame:GetName() .. "Weapon" .. i);
						weaponButton:Hide();
					end

					-- Finally, change the unit so it displays vehicle buffs.
					-- This will force a reconfiguration of the buttons in the secure aura routines.
					auraFrame:SetAttribute("unit", "vehicle");
				end
			else
				-- When getting "out", always change the unit back.

				-- First, restore weapon buffs state.
				auraFrame:SetAttribute("includeWeapons", auraFrame:GetAttribute("includeWeaponsNormal"));

				-- Finally, restore the normal unit id of the frame.
				-- This will force a reconfiguration of the buttons in the secure aura routines.
				auraFrame:SetAttribute("unit", unitNormal);
			end

		elseif (unitNormal == "vehicle") then
			if (newstate == "out") then
				-- Hide all of the buttons while we're in secure code.
				-- If we don't do this then we may end up with left over
				-- vehicle buffs stuck in the window.
				local count = 0;
				local button = auraFrame:GetFrameRef("child1");
				while (button) do
					button:Hide();
					count = count + 1;
					button = auraFrame:GetFrameRef("child" .. count);
				end
			end
		end
	]=];
	stateFrame:SetAttribute("_onstate-vehicleState", snippet);
end

function primaryClass:createBuffFrame()
	-- Create a buff frame (primary and consolidated frames).
	local auraFrame = self.auraFrame;

	-- If we already have an aura frame then return.
	if (auraFrame) then
		return;
	end

	-- If we want to create a secure aura frame...
	if (not self.useUnsecure) then
		-- Check if we're in combat.
		if (InCombatLockdown()) then
			-- Cannot create secure frame while in combat.
			return;
		end
	end

	-- Don't create aura frame if user wants the window to be disabled.
	if (self.disableWindow) then
		return;
	end

	local consolidatedObject = self.consolidatedObject;

	-- Do we need a consolidated frame at this time?
	local needConsolidated;
	for i = 1, 5 do
		local sortSeq = self["sortSeq" .. i];
		if (sortSeq == constants.FILTER_TYPE_CONSOLIDATED) then
			needConsolidated = true;
			break;
		end
	end
	if (needConsolidated) then
		-- Create the consolidated aura frame before the primary frame
		-- since the primary needs to assign the frame to one of its
		-- attributes.
		consolidatedObject:createBuffFrame();
	end

	-- Create the primary aura frame
	self.super.createBuffFrame(self);
	auraFrame = self.auraFrame;

	-- Do not make the primary frame the consolidated frame's parent.

	self.auraFrame:Show();

	-- Reconfigure the primary frame
	-- This will result in the consolidated frame being reconfigured
	-- as well if there are buffs in the consolidated frame.
	self:reconfigureButtons();

	-- Refresh the appearance of the primary frame buttons.
	self:refreshAuraButtons();

	if (consolidatedObject.auraFrame) then
		-- Refresh the appearance of the consolidated frame buttons.
		consolidatedObject:refreshAuraButtons();
		consolidatedObject.auraFrame:Hide();
	end

	self:setVisibility();
end

function primaryClass:buildBasicCondition()
	-- Basic conditions
	local cond = "";
	if (self.visHideInVehicle) then
		cond = cond .. "[vehicleui]hide; ";
	end
	if (self.visHideNotVehicle) then
		cond = cond .. "[novehicleui]hide; ";
	end
	if (self.visHideInCombat) then
		cond = cond .. "[combat]hide; ";
	end
	if (self.visHideNotCombat) then
		cond = cond .. "[nocombat]hide; ";
	end
	cond = cond .. "show";

	return cond;
end

function primaryClass:setVisibility()
	local auraFrame = self.auraFrame;
	if (not auraFrame) then
		return;
	end
	local visWindow = self.visWindow;
	if (visWindow == constants.VISIBILITY_BASIC) then
		-- Basic conditions
		local cond = self:buildBasicCondition();
		RegisterStateDriver(auraFrame, "visibility", cond);

	elseif (visWindow == constants.VISIBILITY_ADVANCED) then
		-- Advanced conditions
		local cond = buildCondition(self.visCondition);
		RegisterStateDriver(auraFrame, "visibility", cond);

	else -- if (visWindow == constants.VISIBILITY_SHOW) then
		UnregisterStateDriver(auraFrame, "visibility");
		auraFrame:Show();

	end
end

function primaryClass:deleteBuffFrame()
	local auraFrame = self.auraFrame;

	if (not auraFrame) then
		return true;
	end
	if (auraFrame:IsProtected()) then
		if (InCombatLockdown()) then
			return false;
		end
	end

	-- Delete the consolidated frame.
	local consolidatedObject = self.consolidatedObject;
	if (consolidatedObject) then
		if (not consolidatedObject:deleteBuffFrame()) then
			return false;
		end
	end

	-- Delete the primary frame.
	self.super.deleteBuffFrame(self);

	-- Clear some other values.
	self.needReconfigure = nil;
	if (self.rescanTicker) then
		self.rescanTicker:Cancel();
		self.rescanTicker = nil;
	end

	return true;
end


--------------------------------------------
-- Window class
--
-- Inherits fron:
-- 	None
--
-- Class object overview:
--
--	(windowClassObject)
--		.meta
--
-- Object overview:
--
--	(windowObject)
--		.classObject
--		.primaryObject
--		.windowId
--
-- Properties:
--	.classObject
--	.primaryObject -- Object representing the primary buff frame.
--	.windowId -- Window id number (minimum is 1)
--
-- Methods and functions:
--
--	:new(unitId)
--
--	:getWindowId()
--
--	:getParent()
--	:setParent(windowListObject)
--
--	:getUnitId()
--
--	:getOptions(shouldCreate)
--	:setOptions(windowOptions)
--
--	:getPrimaryOptionsList(shouldCreate)
--	:setPrimaryOptionsList(primaryOptionsList)
--
--	:getPrimaryOptions(primaryId, shouldCreate)
--	:setPrimaryOptions(primaryId, primaryOptions)
--
--	:copyOptions(windowObject)
--	:deleteOptions()
--	:setDefaultOptions()
--	:applyOptions(initFlag)
--
--	:updateTimeDisplay()
--	:refreshAuraButtons()
--	:refreshWeaponButtons()
--	:setBackground()
--	:altFrameEnableMouse(enable)
--	:resetPosition()
--
--	:createBuffFrame()
--	:createWindow(windowObjectToClone)
--	:deleteWindow()
--
--	:updateSpells(unitId)
--	:updateEnchants(unitId)
--	:updateSpellsAndEnchants(unitId)
--
--	:setSpecialAttributes()
--	:setCurrentWindow(isCurrent, showTitle)

-- Create the class object.
local windowClass = {};

windowClass.meta = { __index = windowClass };
windowClass.super = windowClass.classObject;

function windowClass:new(unitId)
	-- Create an object of this class.
	local object = {};
	object.classObject = self;
	setmetatable(object, self.meta);

	object.windowId = nil;  -- Will assign value during windowListClass:addWindow()

	-- Create the primary object.
	local primaryObject;
	primaryObject = primaryClass:new(unitId);
	primaryObject.primaryId = 1;  -- There is only one primary object per window, so use id 1.
	primaryObject:setParent(object);

	object.primaryObject = primaryObject;

	return object;
end

function windowClass:getWindowId()
	return self.windowId;
end

function windowClass:getParent()
	return self.parent;
end

function windowClass:setParent(windowListObject)
	self.parent = windowListObject;
end

function windowClass:getUnitId()
	return self.primaryObject:getUnitId();
end

function windowClass:getOptions(shouldCreate)
	-- Get the table containing the options.
	-- shouldCreate -- true, nil == Create table if it does not exist.
	--                 false == Do not create missing table.
	return self.parent:getWindowOptions(self.windowId, shouldCreate);
end

function windowClass:setOptions(windowOptions)
	-- Set the table containing the options.
	self.parent:setWindowOptions(self.windowId, windowOptions);
end

function windowClass:getPrimaryOptionsList(shouldCreate)
	-- Get the list of tables containing options for the primary objects.
	-- shouldCreate -- true, nil == Create list if it does not exist.
	--                 false == Do not create missing list.

	-- Although this allows for multiple primary objects, we are not
	-- currently using more than one.

	local windowOptions = self:getOptions(shouldCreate);
	if (not windowOptions) then
		return nil;
	end
	local primaryOptionsList = windowOptions.primaryOptionsList;
	if (not primaryOptionsList) then
		if (shouldCreate == false) then
			return nil;
		end
		primaryOptionsList = {};
		self:setPrimaryOptionsList(primaryOptionsList);
	end
	return primaryOptionsList;
end

function windowClass:setPrimaryOptionsList(primaryOptionsList)
	-- Set the list of tables containing options for the primary objects.
	local windowOptions = self:getOptions(true);
	windowOptions.primaryOptionsList = primaryOptionsList;
end

function windowClass:getPrimaryOptions(primaryId, shouldCreate)
	-- Get the table containing the options for the specified primary object id.
	-- shouldCreate -- true, nil == Create table if it does not exist.
	--                 false == Do not create missing table.
	local primaryOptionsList = self:getPrimaryOptionsList(shouldCreate);
	if (not primaryOptionsList) then
		return nil;
	end
	local primaryOptions = primaryOptionsList[primaryId];
	if (not primaryOptions) then
		if (shouldCreate == false) then
			return nil;
		end
		primaryOptions = {};
		self:setPrimaryOptions(primaryId, primaryOptions);
	end
	return primaryOptions;
end

function windowClass:setPrimaryOptions(primaryId, primaryOptions)
	-- Set the table containing the options for the specified primary object id.
	local primaryOptionsList = self:getPrimaryOptionsList(true);
	primaryOptionsList[primaryId] = primaryOptions;
end

function windowClass:copyOptions(windowObject)
	-- Copy all of the options to the specified object.

	-- Copy the options for the primary object (which will also copy consolidated object options)
	self.primaryObject:copyOptions(windowObject.primaryObject);

	-- Copy the options for the window object.
	local newOptions;
	local windowOptions = self:getOptions(false);
	if (windowOptions) then
		newOptions = {};
		module:copyTable(windowOptions, newOptions);
	end
	windowObject:setOptions(newOptions);
end

function windowClass:deleteOptions()
	-- Delete all of the options.

	-- Delete the options for the primary object
	self.primaryObject:deleteOptions();

	-- Delete the options for the window object
	local windowOptions = self:getOptions(false);
	if (windowOptions) then
		self:setOptions(nil);
	end
end

function windowClass:setDefaultOptions()
	-- Set default options for a newly created primary/consolidated object.
	self.primaryObject:setDefaultOptions();

	local consolidatedObject = self.primaryObject.consolidatedObject;
	consolidatedObject:setDefaultOptions();
end

function windowClass:applyOptions(initFlag)
	-- Apply options.
	-- initFlag -- true if we should only initialize the object's properties (no display updates, etc).

	-- The primaryObject will apply options for the consolidated object.
	self.primaryObject:applyOptions(initFlag);
end

function windowClass:updateTimeDisplay()
	-- Update the time remaining in the frames.
	self.primaryObject:updateTimeDisplay();
	self.primaryObject.consolidatedObject:updateTimeDisplay();
end

function windowClass:refreshAuraButtons()
	-- Refresh the aura buttons in the frames.
	self.primaryObject:refreshAuraButtons();
	self.primaryObject.consolidatedObject:refreshAuraButtons();
end

function windowClass:refreshWeaponButtons()
	-- Refresh the weapon buttons in the frames.
	self.primaryObject:refreshWeaponButtons();
end

function windowClass:setBackground()
	-- Set the background of the frames.
	self.primaryObject:setBackground();
	self.primaryObject.consolidatedObject:setBackground();
end

function windowClass:altFrameEnableMouse(enable)
	-- Enable/disable the mouse in the alt frames.
	self.primaryObject:altFrameEnableMouse(enable);
	self.primaryObject.consolidatedObject:altFrameEnableMouse(enable);
end

function windowClass:resetPosition()
	-- Reset the position of the frames.
	self.primaryObject:resetPosition();

	local consolidatedObject = self.primaryObject.consolidatedObject;
	consolidatedObject:resetPosition();
end

function windowClass:createBuffFrame()
	-- Create the buff frames.

	-- The primary object will create the buff frame for the consolidated object.
	self.primaryObject:createBuffFrame();
end

function windowClass:createWindow(windowObjectToClone)
	-- Create a window for the window object.
	-- windowObjectToClone == windowObject to copy settings from (optional)

	self:setDefaultOptions();

	if (windowObjectToClone) then
		-- Copy the source window's options to the destination.
		windowObjectToClone:copyOptions(self);
	end

	self:applyOptions(true);
	self:createBuffFrame();
end

function windowClass:deleteWindow()
	-- Delete the window (primary frame, consolidated frame, options, etc).
	-- Note: This does not remove it from the windowListObject. The deleteWindow
	-- method of the windowListClass should be called instead of this one. It will
	-- call this one.
	local primaryObject = self.primaryObject;

	primaryObject.consolidatedObject:deleteBuffFrame()
	primaryObject:deleteBuffFrame()

	-- Delete the options
	self:deleteOptions();
end

function windowClass:updateSpells(unitId)
	-- unitId == unit id to update for (optional). Defaults to the primary object's unit id.
	globalObject.unitListObject:updateSpells( unitId or self.primaryObject:getUnitId() );
end

function windowClass:updateEnchants(unitId)
	-- unitId == unit id to update for (optional). Defaults to the primary object's unit id.
	return globalObject.unitListObject:updateEnchants( unitId or self.primaryObject:getUnitId() );
end

function windowClass:updateSpellsAndEnchants(unitId)
	-- unitId == unit id to update for (optional). Defaults to the primary object's unit id.
	return globalObject.unitListObject:updateSpellsAndEnchants( unitId or self.primaryObject:getUnitId() );
end

function windowClass:setSpecialAttributes()
	local primaryObject = self.primaryObject;
	local consolidatedObject = primaryObject.consolidatedObject;

	primaryObject:setSpecialAttributes();
	consolidatedObject:setSpecialAttributes();
end

function windowClass:setCurrentWindow(isCurrent, showTitle)
	-- Show/hide and set the color of the window title.
	local auraFrame = self.primaryObject.auraFrame;
	if (auraFrame) then
		local fsWindowTitle = auraFrame.altFrame.fsWindowTitle;
		if (isCurrent) then
			fsWindowTitle:SetTextColor(1, 1, 1);
		else
			fsWindowTitle:SetTextColor(1, 0.82, 0);
		end
		if (showTitle) then
			fsWindowTitle:Show();
		else
			fsWindowTitle:Hide();
		end
	end
end


--------------------------------------------
-- Window list class
--
-- Inherits fron:
-- 	None
--
-- Class object overview:
--
--	(windowListClassObject)
--		.meta
--
-- Object overview:
--
--	(windowListObject)
--		.classObject
--		.windowIds[ sequential number ]
--			(windowId)
--		.windowObjects[ window id ]
--			(windowObject)
--
-- Properties:
--	.classObject
--	.windowIds -- Table of window ID numbers indexed by a sequential number.
--	.windowObjects -- Table of windowClass objects indexed by their window ID number.
--
-- Methods and functions:
--
--	:new()
--
--	:getWindowCount()
--	:getMaxWindowCount()
--	:windowNumToId(windowNum)
--	:windowIdToNum(windowId)
--
--	:getWindowOptionsList(shouldCreate)
--	:setWindowOptionsList(windowOptionsList)
--	:getWindowOptions(windowId, shouldCreate)
--	:setWindowOptions(windowId, windowOptions)
--
--	:applyOptions(initFlag)
--
--	:addWindow(unitId, windowId)
--	:deleteWindow(windowId)
--	:findWindow(windowId)
--
--	:isUnitIdAssigned(unitId)
--
--	:updateTimeDisplay()
--	:refreshAuraButtons()
--	:refreshWeaponButtons()
--
--	:setBackground()
--	:altFrameEnableMouse(enable)
--	:createBuffFrame()
--
--	:updateSpells(unitId)
--	:updateEnchants(unitId)
--	:updateSpellsAndEnchants(unitId)
--
--	:setSpecialAttributes()
--	:setCurrentWindow(windowId, showTitle)


-- Create the class object.
local windowListClass = {};

windowListClass.meta = { __index = windowListClass };
windowListClass.super = windowListClass.classObject;

function windowListClass:new()
	-- Create an object of this class.
	local object = {};
	object.classObject = self;
	setmetatable(object, self.meta);

	object.windowIds = {};  -- indexed by sequential number
	object.windowObjects = {};  -- indexed by windowId

	return object;
end

function windowListClass:getWindowCount()
	return #self.windowIds;
end

function windowListClass:getMaxWindowCount()
	-- Maximum number of windows that can be created.
	-- This is an arbitrary limit.
	-- If it is too large then the list of windows won't fit
	-- in a dropdown menu. Also an excessive number might
	-- slow things down a bit.
	return 10;
end

function windowListClass:windowNumToId(windowNum)
	-- Used to translate a window number into a window id.
	-- Window numbers are sequential starting at 1.
	-- Window ids may not be sequential.
	return self.windowIds[windowNum];
end

function windowListClass:windowIdToNum(windowId)
	-- Used to translate window id into a window number.
	-- Window numbers are sequential starting at 1.
	-- Window ids may not be sequential.
	local windowIds = self.windowIds;
	for num, id in ipairs(windowIds) do
		if (id == windowId) then
			return num;
		end
	end
	return nil;
end

function windowListClass:getWindowOptionsList(shouldCreate)
	-- Get the list of tables containing options for the window objects.
	-- shouldCreate -- true, nil == Create list if it does not exist.
	--                 false == Do not create missing list.
	local windowOptionsList = module:getOption("windowOptionsList");
	if (not windowOptionsList) then
		if (shouldCreate == false) then
			return nil;
		end
		windowOptionsList = {};
		self:setWindowOptionsList(windowOptionsList)
	end
	return windowOptionsList;
end

function windowListClass:setWindowOptionsList(windowOptionsList)
	module:setOption("windowOptionsList", windowOptionsList);
end

function windowListClass:getWindowOptions(windowId, shouldCreate)
	-- Get the table containing the options for the specified window object id.
	-- shouldCreate -- true, nil == Create table if it does not exist.
	--                 false == Do not create missing table.
	local windowOptionsList = self:getWindowOptionsList(shouldCreate);
	if (not windowOptionsList) then
		return nil;
	end
	local windowOptions = windowOptionsList[windowId];
	if (not windowOptions) then
		if (shouldCreate == false) then
			return nil;
		end
		windowOptions = {};
		self:setWindowOptions(windowId, windowOptions);
	end
	return windowOptions;
end

function windowListClass:setWindowOptions(windowId, windowOptions)
	-- Set the table containing the options for the specified window object id.
	local windowOptionsList = self:getWindowOptionsList(true);
	windowOptionsList[windowId] = windowOptions;
end

function windowListClass:applyOptions(initFlag)
	-- initFlag -- true if we should only initialize the object's properties (no display updates, etc).
	for windowId, windowObject in pairs(self.windowObjects) do
		windowObject.primaryObject:applyOptions(initFlag);
	end
end

function windowListClass:addWindow(unitId, windowId, windowObjectToClone)
	-- Add a window to the list.
	-- Returns the window object.
	-- unitId == unit id associated with this window (required)
	-- windowId == windowId associated with this window (optional)
	-- windowObjectToClone == windowObject of window to clone settings from (optional)

	local windowObjects = self.windowObjects;
	local windowIds = self.windowIds;

	-- Create a new window object
	local windowObject = windowClass:new(unitId);

	-- Set this object as the window's parent
	windowObject:setParent(self);

	if (windowId) then
		-- If the specified window id is already in use, then clear it
		-- so that we will scan for an unused one instead.
		if (windowObjects[windowId]) then
			windowId = nil;
		end
	end

	if (not windowId) then
		-- Scan for an unused window id number
		windowId = 1;
		while (windowObjects[windowId]) do
			windowId = windowId + 1;
		end
	end

	-- Assign the window id to the window.
	-- This function should be the only thing assigning a window id to a window object.
	windowObject.windowId = windowId;

	-- Assign the window object to the list.
	windowObjects[windowId] = windowObject;

	-- Insert the window id into the appropriate spot in the windowIds list.
	-- We want the window ids in the list to be in numerical order.
	local pos = 0;
	for num, winId in ipairs(windowIds) do
		if (windowId < winId) then
			-- We'll insert the window id at this position in the list.
			pos = num;
			break;
		elseif (windowId == winId) then
			-- Window id is already in the list, so don't add it again.
			pos = nil;
			break;
		end
	end
	if (pos) then
		if (pos == 0) then
			-- Add it to the end of the list.
			tinsert(windowIds, windowId);
		else
			-- Insert it at the located position.
			tinsert(windowIds, pos, windowId);
		end
	end

	-- Create the window (the actual buff frames, apply options, etc.)
	windowObject:createWindow(windowObjectToClone);

	return windowObject;
end

function windowListClass:deleteWindow(windowId)
	-- Delete the window associated with the window id.
	if (windowId) then
		local windowObjects = self.windowObjects;
		local windowObject = windowObjects[windowId];

		if (windowObject) then
			local unitId = windowObject:getUnitId();

			-- Delete the window.
			windowObject:deleteWindow();

			-- Delete the window object from the list.
			local num = self:windowIdToNum(windowId);
			windowObjects[windowId] = nil;
			tremove(self.windowIds, num);

			-- If the unit id is no longer assigned to any window, then delete it.
			if (not self:isUnitIdAssigned(unitId)) then
				globalObject.unitListObject:deleteUnit(unitId);
			end
		end
	end
	return nil;
end

function windowListClass:findWindow(windowId)
	-- Find a window object using the specified windowId.
	return self.windowObjects[windowId];
end

function windowListClass:isUnitIdAssigned(unitId)
	-- Find out if any window is using the specified unit id.
	for windowId, windowObject in pairs(self.windowObjects) do
		if (windowObject:getUnitId() == unitId) then
			return true;
		end
	end
	return false;
end


function windowListClass:updateTimeDisplay()
	for windowId, windowObject in pairs(self.windowObjects) do
		windowObject:updateTimeDisplay();
	end
end

function windowListClass:refreshAuraButtons()
	for windowId, windowObject in pairs(self.windowObjects) do
		windowObject:refreshAuraButtons();
	end
end

function windowListClass:refreshWeaponButtons()
	for windowId, windowObject in pairs(self.windowObjects) do
		windowObject:refreshWeaponButtons();
	end
end

function windowListClass:setBackground()
	for windowId, windowObject in pairs(self.windowObjects) do
		windowObject:setBackground();
	end
end

function windowListClass:altFrameEnableMouse(enable)
	for windowId, windowObject in pairs(self.windowObjects) do
		windowObject:altFrameEnableMouse(enable);
	end
end

function windowListClass:createBuffFrame()
	for windowId, windowObject in pairs(self.windowObjects) do
		windowObject:createBuffFrame();
	end
end

function windowListClass:updateSpells(unitId)
	-- unitId == unit id to update for (optional)
	globalObject.unitListObject:updateSpells(unitId);
end

function windowListClass:updateEnchants(unitId)
	-- unitId == unit id to update for (optional)
	return globalObject.unitListObject:updateEnchants(unitId);
end

function windowListClass:updateSpellsAndEnchants(unitId)
	-- unitId == unit id to update for (optional)
	return globalObject.unitListObject:updateSpellsAndEnchants(unitId);
end

function windowListClass:setSpecialAttributes()
	for windowId, windowObject in pairs(self.windowObjects) do
		windowObject:setSpecialAttributes();
	end
end

function windowListClass:setCurrentWindow(windowId, showTitle)
	for winId, windowObject in pairs(self.windowObjects) do
		windowObject:setCurrentWindow(winId == windowId, showTitle);
	end
end

--------------------------------------------
-- Global object
--
-- Inherits fron:
--
-- 	None
--
-- Class object overview:
--
--	(globalClassObject)
--		.meta
--
-- Object overview:
--
--	(globalObject)
--		.classObject
--		+other properties
--
-- Properties:
--	.classObject
--	.unitListObject
--	.windowListObject
--
--	.backgroundColor -- Background color to use for all primary windows unless the window option overrides it. (table: 1=Red value, 2=Green value, 3==Blue value, 4==Alpha value)
--	.bgColorAURA -- Aura background color (table: 1=Red value, 2=Green value, 3==Blue value, 4==Alpha value)
--	.bgColorBUFF -- Buff background color (table: 1=Red value, 2=Green value, 3==Blue value, 4==Alpha value)
--	.bgColorDEBUFF -- Debuff background color (table: 1=Red value, 2=Green value, 3==Blue value, 4==Alpha value)
--	.bgColorITEM -- Weapon enchant background color (table: 1=Red value, 2=Green value, 3==Blue value, 4==Alpha value)
--	.bgColorCONSOLIDATED -- Consolidated buff background color (table: 1=Red value, 2=Green value, 3==Blue value, 4==Alpha value)
--	.consolidatedColor -- Background color to use for all consolidated windows unless the window option overrides it. (table: 1=Red value, 2=Green value, 3==Blue value, 4==Alpha value)
--	.consolidatedHideTimer -- Number of seconds before the consolidated window automatically hides when the mouse is not over the consolidated aura frame or the consolidated button).
--	.enableExpiration -- Enable expiration warning (1==yes, false==no, default == yes)
--	.expirationCastOnly -- Ignore buffs you cannot cast (1==yes, false=no, default == no)
--	.expirationSound -- Play sound when expiration warning is shown (1==yes, false==no, default == yes)
--	.expirationWarningTime1 -- Expiration warning time for buffs with a 2:00 to 10:00 minute duration (number, default == 15)
--	.expirationWarningTime2 -- Expiration warning time for buffs with a 10:01 to 30:00 minute duration (number, default == 60)
--	.expirationWarningTime3 -- Expiration warning time for buffs with a 30:01 or greater minute duration (number, default == 180)
--	.flashTime -- Time to flash icons before expiring (number, default == constants.DEFAULT_FLASH_TIME seconds, zero means no flashing at all)
--	.hideBlizzardBuffs -- Hide Blizzard's buff frame (1==yes, false==no, default == yes)
--	.hideBlizzardEnchants -- Hide Blizzards temporary weapon enchants window (1==yes, false==no, default == yes)
--
-- Methods and functions:
--
--	:new(unitId)
--
--	:applyGlobalOptions(initFlag)
--
--	:hideBlizzardEnchantsFrame(value)
--	:hideBlizzardBuffsFrame(value)
--	:hideBlizzardConsolidatedFrame(value)

-- Create the class object.
local globalClass = {};

globalClass.meta = { __index = globalClass };
globalClass.super = globalClass.classObject;

function globalClass:new(unitId)
	-- Create an object of this class.
	local object = {};
	object.classObject = self;
	setmetatable(object, self.meta);

	self.unitListObject = unitListClass:new();
	self.windowListObject = windowListClass:new();

	return object;
end

function globalClass:applyGlobalOptions(initFlag)
	-- initFlag -- true if we should only initialize the object's properties (no display updates, etc).
	local value;

	-- Hide Blizzard's buffs, consolidated buffs, enchants
	self.hideBlizzardBuffs = module:getOption("hideBlizzardBuffs") ~= false;
	--self.hideBlizzardConsolidated = module:getOption("hideBlizzardConsolidated") ~= false;
	self.hideBlizzardEnchants = module:getOption("hideBlizzardEnchants") ~= false;

	globalObject:hideBlizzardEnchantsFrame(self.hideBlizzardEnchants);
	globalObject:hideBlizzardBuffsFrame(self.hideBlizzardBuffs);
	--globalObject:hideBlizzardConsolidatedFrame(self.hideBlizzardConsolidated);

	-- Background color for primary window
	local color = module:getOption("backgroundColor");
	if (type(color) ~= "table") then
		color = defaultWindowColor;
	end
	if (#color ~= 4) then
		for i = 1, 4 do
			color[i] = defaultWindowColor[i];
		end
	end
	self.backgroundColor = color;

	-- Background color for consolidated window
	local color = module:getOption("consolidatedColor");
	if (type(color) ~= "table") then
		color = defaultConsolidatedColor;
	end
	if (#color ~= 4) then
		for i = 1, 4 do
			color[i] = defaultConsolidatedColor[i];
		end
	end
	self.consolidatedColor = color;

	-- Background colors for auras, buffs, debuffs, enchants.
	value = module:getOption("bgColorAURA");
	if (type(value) ~= "table") then
		value = getDefaultBackgroundColor(constants.AURATYPE_AURA);
	end
	self.bgColorAURA = value;
	updateBackgroundColor(constants.AURATYPE_AURA, value);

	value = module:getOption("bgColorBUFF");
	if (type(value) ~= "table") then
		value = getDefaultBackgroundColor(constants.AURATYPE_BUFF);
	end
	self.bgColorBUFF = value;
	updateBackgroundColor(constants.AURATYPE_BUFF, value);

	value = module:getOption("bgColorDEBUFF");
	if (type(value) ~= "table") then
		value = getDefaultBackgroundColor(constants.AURATYPE_DEBUFF);
	end
	self.bgColorDEBUFF = value;
	updateBackgroundColor(constants.AURATYPE_DEBUFF, value);

	value = module:getOption("bgColorITEM");
	if (type(value) ~= "table") then
		value = getDefaultBackgroundColor(constants.AURATYPE_ENCHANT);
	end
	self.bgColorENCHANT = value;
	updateBackgroundColor(constants.AURATYPE_ENCHANT, value);

	value = module:getOption("bgColorCONSOLIDATED");
	if (type(value) ~= "table") then
		value = getDefaultBackgroundColor(constants.AURATYPE_CONSOLIDATED);
	end
	self.bgColorCONSOLIDATED = value;
	updateBackgroundColor(constants.AURATYPE_CONSOLIDATED, value);

	-- Consolidated window auto hide timer.
	self.consolidatedHideTimer = module:getOption("consolidatedHideTimer") or constants.DEFAULT_CONSOLIDATE_HIDE_TIMER;

	-- Expiration warnings
	self.enableExpiration = module:getOption("enableExpiration") ~= false;
	self.expirationCastOnly = not not module:getOption("expirationCastOnly");
	self.expirationSound = module:getOption("expirationSound") ~= false;
	self.expirationWarningTime1 = module:getOption("expirationTime1") or 15;
	self.expirationWarningTime2 = module:getOption("expirationTime2") or 60;
	self.expirationWarningTime3 = module:getOption("expirationTime3") or 180;

	-- Flash icons when about to fade
	self.flashTime = module:getOption("flashTime") or constants.DEFAULT_FLASH_TIME;
end

-- Blizzard shows the TemporaryEnchants frame once and then never shows/hides it again.
local hidEnchants;
local enchantsOption;

function globalClass:hideBlizzardEnchantsFrame(value)
	-- Configure the option.
	local frame = TemporaryEnchantFrame;
	if frame then
		enchantsOption = value;  -- save option's value for use in the OnShow hook.
		if (value) then
			frame_Hide(frame);
			hidEnchants = true;
		else
			-- Only show the frame if we have previously hidden it,
			-- that way we don't affect anything if the user leaves the option disabled.
			if (hidEnchants) then
				frame:Show();
			hidEnchants = nil;
			end
		end
	end
end

if TemporaryEnchantFrame then
	TemporaryEnchantFrame:HookScript("OnShow", function(self)
		-- If player has chosen to hide the frame.
		if (enchantsOption) then
			-- Override Show() by hiding the frame.
				frame_Hide(self)
		end
	end)
end

-- Blizzard shows the BuffFrame frame once and then never shows/hides it again.
local hidBuffs;
local buffsOption;

function globalClass:hideBlizzardBuffsFrame(value)
	-- Configure the option.
	local frame1, frame2 = BuffFrame, DebuffFrame;
	buffsOption = value  -- save option's value for use in the OnShow hook.
	if value then
		frame_Hide(frame1)
		if frame2 then
			frame_Hide(frame2)
		end
		hidBuffs = true
	else
		-- Only show the frame if we have previously hidden it,
		-- that way we don't affect anything if the user leaves the option disabled.
		if hidBuffs then
			frame1:Show()
			if frame2 then
				frame2:Show()
			end
			hidBuffs = nil
		end
	end
end

BuffFrame:HookScript("OnShow",
	function(self)
		-- If player has chosen to hide the frame.
		if buffsOption then
			-- Override Show() by hiding the frame.
			frame_Hide(self)
		end
	end
)

if DebuffFrame then
	DebuffFrame:HookScript("OnShow",
		function(self)
			-- If player has chosen to hide the frame.
			if buffsOption then
				-- Override Show() by hiding the frame.
				frame_Hide(self)
			end
		end
	)
end

-- Blizzard shows/hides the ConsolidatedBuffs frame as needed.
--[[local hidConsolidated;
local consolidatedOption;

function globalClass:hideBlizzardConsolidatedFrame(value)
	-- Configure the option.
	local frame = ConsolidatedBuffs;
	consolidatedOption = value;  -- save option's value for use in the OnShow hook.
	if (value) then
		frame_Hide(frame);
		hidConsolidated = true;
	else
		-- Only show the frame if we have previously hidden it,
		-- that way we don't affect anything if the user leaves the option disabled.
		if (hidConsolidated) then
			-- Only show it if we should.
			-- The ShouldShowConsolidatedBuffFrame() function is defined
			-- in BuffFrame.lua.
			if ( ShouldShowConsolidatedBuffFrame() ) then
				frame:Show();
			end
			hidConsolidated = nil;
		end
	end
end

ConsolidatedBuffs:HookScript("OnShow",
	function(self)
		-- If player has chosen to hide the frame.
		if (consolidatedOption) then
			-- Override Blizzard's Show() by hiding the frame.
			frame_Hide(self);
		end
	end
);]]



--------------------------------------------
-- Window options

local currentWindowId = 1;
local windowOptionsFrame;
local doNotUpdateFlag;

local function options_updateWindowWidgets_Visibility(windowId)
	local frame = windowOptionsFrame;

	if (not frame) then
		return;
	end
	if (not windowId) then
		windowId = currentWindowId;
	end

	local windowObject = globalObject.windowListObject:findWindow(windowId);
	local primaryObject = windowObject.primaryObject;
	local frameOptions = primaryObject:getOptions();

	local show, basic, advanced;
	local value = frameOptions.visWindow or constants.VISIBILITY_SHOW;

	if (value == constants.VISIBILITY_ADVANCED) then
		-- Advanced conditions
		advanced = true;
	elseif (value == constants.VISIBILITY_BASIC) then
		-- Basic conditions
		basic = true;
	else
		-- Show always
		show = true;
	end

	if (show) then
		-- Enable show always options
		windowOptionsFrame.visShow:SetChecked(1);
	else
		-- Disable show always options
		windowOptionsFrame.visShow:SetChecked(nil);
	end

	if (basic) then
		-- Enable basic options
		windowOptionsFrame.visBasic:SetChecked(1);
	else
		-- Disable basic options
		windowOptionsFrame.visBasic:SetChecked(nil);
	end

	if (advanced) then
		-- Enable advanced options
		windowOptionsFrame.visAdvanced:SetChecked(1);
	else
		-- Disable advanced options
		windowOptionsFrame.visAdvanced:SetChecked(nil);
	end

	windowOptionsFrame.conditionEB:ClearFocus();
	windowOptionsFrame.conditionEB:HighlightText(0, 0);
end

local function options_updateWindowWidgets(windowId)
	-- Update widgets associated with the specified window id.
	local frame = windowOptionsFrame;

	if (not frame) then
		return;
	end
	if (not windowId) then
		windowId = currentWindowId;
	end

	-- To stop some widgets from achieving anything when they call module:setOption() we will
	-- set the "doNotUpdateFlag" variable. It gets tested for in the module.optionUpdate()
	-- function and if it is found to be set then the function will return without doing anything.
	-- We just want to visually update the widges, not change any options.
	doNotUpdateFlag = true;

	local windowObject = globalObject.windowListObject:findWindow(windowId);
	local primaryObject = windowObject.primaryObject;
	local frameOptions = primaryObject:getOptions();
	local value;
	local dropdown, slider;

	-- Select Window menu
	dropdown = CT_BuffModDropdown_editWindow;
	if (not dropdown.isInitialized) then
		dropdown.isInitialized = true;
		-- Only need to do this one time.
		if UIDropDownMenu_Initialize then
			UIDropDownMenu_Initialize(dropdown,
				function()
					local i = 1;
					local dropdownEntry = {};
					local windowListObject = globalObject.windowListObject;
					local count = windowListObject:getWindowCount();
					for windowNum = 1, count do
						dropdownEntry.text = format(L["CT_BuffMod/WindowTitle"],windowListObject:windowNumToId(i));
						dropdownEntry.value = i;
						dropdownEntry.checked = nil;
						dropdownEntry.func = dropdown.ctDropdownClick;
						UIDropDownMenu_AddButton(dropdownEntry);
						i = i + 1;
					end
				end
			);
		end
	else
		if UIDropDownMenu_Initialize then
			UIDropDownMenu_Initialize( dropdown, dropdown.initialize );
		end
	end
	if UIDropDownMenu_Initialize then
		UIDropDownMenu_SetSelectedValue( dropdown, globalObject.windowListObject:windowIdToNum(windowId) );
		UIDropDownMenu_JustifyText(dropdown, "LEFT");
	end

	----------
	-- Window
	----------
	-- Disable window
	frame.disableWindow:SetChecked( not not frameOptions.disableWindow );
	
	-- Disable tooltips
	frame.disableTooltips:SetChecked( not not frameOptions.disableTooltips );

	-- Unlock window
	frame.lockWindow:SetChecked( not not frameOptions.lockWindow );

	-- Window cannot be moved off screen
	frame.clampWindow:SetChecked( frameOptions.clampWindow ~= false );

	----------
	-- Unit
	----------
	local unitType = frameOptions.unitType or constants.UNIT_TYPE_PLAYER;
	local playerUnsecure = not not frameOptions.playerUnsecure;

	dropdown = CT_BuffModDropdown_unitType;
	if UIDropDownMenu_Initialize then
		UIDropDownMenu_Initialize( dropdown, dropdown.initialize );
		UIDropDownMenu_SetSelectedValue( dropdown, unitType );
	end

	-- Use unsecure buttons
	frame.playerUnsecure:SetChecked( playerUnsecure );
	if (unitType == constants.UNIT_TYPE_PLAYER or unitType == constants.UNIT_TYPE_VEHICLE) then
		frame.playerUnsecure:Show();
	else
		frame.playerUnsecure:Hide();
		playerUnsecure = true;
	end

	-- Show vehicle buffs when in a vehicle
	frame.vehicleBuffs:SetChecked( frameOptions.vehicleBuffs ~= false );
	if (unitType == constants.UNIT_TYPE_PLAYER) then
		frame.vehicleBuffs:Show();
	else
		frame.vehicleBuffs:Hide();
	end

	----------
	-- Sorting
	----------
	local sortMethod = frameOptions.sortMethod or constants.SORT_METHOD_NAME;

	dropdown = CT_BuffModDropdown_sortMethod;
	if UIDropDownMenu_Initialize then
		UIDropDownMenu_Initialize( dropdown, dropdown.initialize );
		UIDropDownMenu_SetSelectedValue( dropdown, sortMethod );
	end

	dropdown = frame.separateZero.dropdown;
	if UIDropDownMenu_Initialize then
		UIDropDownMenu_Initialize( dropdown, dropdown.initialize );
		UIDropDownMenu_SetSelectedValue( dropdown, frameOptions.separateZero or constants.SEPARATE_ZERO_WITH );
		if (playerUnsecure) then
			frame.separateZero.label:SetAlpha(1);
			UIDropDownMenu_EnableDropDown(dropdown);
		else
			frame.separateZero.label:SetAlpha(0.5);
			UIDropDownMenu_DisableDropDown(dropdown);
		end
	end
	
	dropdown = frame.groupByPriority.dropdown;
	if UIDropDownMenu_Initialize then
		UIDropDownMenu_Initialize( dropdown, dropdown.initialize );
		UIDropDownMenu_SetSelectedValue( dropdown, frameOptions.groupByPriority or constants.GROUP_BY_FILTER_OWN_ZERO );
		if (playerUnsecure) then
			frame.groupByPriority.label:SetAlpha(1);
			UIDropDownMenu_EnableDropDown(dropdown);
		else
			frame.groupByPriority.label:SetAlpha(0.5);
			UIDropDownMenu_DisableDropDown(dropdown);
		end
	end

	frame.sortDirection:SetChecked( not not frameOptions.sortDirection );

	dropdown = CT_BuffModDropdown_separateOwn;
	if UIDropDownMenu_Initialize then
		UIDropDownMenu_Initialize( dropdown, dropdown.initialize );
		-- Bug: Originally due to a bug in Blizzard's code, the SEPARATE_OWN_WITH value
		--      acted like the SEPARATE_OWN_BEFORE value.
		--
		--      Note: As of WoW 4.3 they hvae fixed the bug.
		--            I am now using SEPARATE_OWN_WITH as the default instead of SEPARATE_OWN_BEFORE.
		--
		UIDropDownMenu_SetSelectedValue( dropdown, frameOptions.separateOwn or constants.SEPARATE_OWN_WITH );
	end

	if UIDropDownMenu_Initialize then	
		dropdown = CT_BuffModDropdown_sortSeq1;
		UIDropDownMenu_Initialize( dropdown, dropdown.initialize );
		UIDropDownMenu_SetSelectedValue( dropdown, frameOptions.sortSeq1 or constants.FILTER_TYPE_DEBUFF );

		dropdown = CT_BuffModDropdown_sortSeq2;
		UIDropDownMenu_Initialize( dropdown, dropdown.initialize );
		UIDropDownMenu_SetSelectedValue( dropdown, frameOptions.sortSeq2 or constants.FILTER_TYPE_WEAPON );

		dropdown = CT_BuffModDropdown_sortSeq3;
		UIDropDownMenu_Initialize( dropdown, dropdown.initialize );
		UIDropDownMenu_SetSelectedValue( dropdown, frameOptions.sortSeq3 or constants.FILTER_TYPE_BUFF_CANCELABLE );

		dropdown = CT_BuffModDropdown_sortSeq4;
		UIDropDownMenu_Initialize( dropdown, dropdown.initialize );
		UIDropDownMenu_SetSelectedValue( dropdown, frameOptions.sortSeq4 or constants.FILTER_TYPE_BUFF_UNCANCELABLE );

		dropdown = CT_BuffModDropdown_sortSeq5;
		UIDropDownMenu_Initialize( dropdown, dropdown.initialize );
		UIDropDownMenu_SetSelectedValue( dropdown, frameOptions.sortSeq5 or constants.FILTER_TYPE_NONE );
	end
	----------
	-- Visibility
	----------

	-- Visibility radio buttons
	options_updateWindowWidgets_Visibility(windowId);

	-- Basic conditions
	frame.visHideInCombat:SetChecked( not not frameOptions.visHideInCombat );
	frame.visHideNotCombat:SetChecked( not not frameOptions.visHideNotCombat );
	frame.visHideInVehicle:SetChecked( not not frameOptions.visHideInVehicle );
	frame.visHideNotVehicle:SetChecked( not not frameOptions.visHideNotVehicle );

	-- Advanced conditions
	windowOptionsFrame.conditionEB:SetText( frameOptions.visCondition or "" );
	windowOptionsFrame.visSave:Disable();

	windowOptionsFrame.conditionEB.ctUndo = frameOptions.visCondition or "";
	windowOptionsFrame.visUndo:Disable();

	----------
	-- Consolidation
	----------
--[[ CONSOLIDATION REMOVED FROM GAME
	-- Minimum total duration
	frame.consolidateDurationMinutes:SetValue( frameOptions.consolidateDurationMinutes or 0 );
	frame.consolidateDurationSeconds:SetValue( frameOptions.consolidateDurationSeconds or 30 );

	-- Time remaining threshold
	frame.consolidateThresholdMinutes:SetValue( frameOptions.consolidateThresholdMinutes or 0 );
	frame.consolidateThresholdSeconds:SetValue( frameOptions.consolidateThresholdSeconds or 10 );

	-- Total duration percentage
	frame.consolidateFractionPercent:SetValue( frameOptions.consolidateFractionPercent or 10 );
--]]
	----------
	-- Background
	----------
	-- Show background
	frame.showBackground:SetChecked( frameOptions.showBackground ~= false );

	-- Use different background color
	frame.useCustomBackgroundColor:SetChecked( not not frameOptions.useCustomBackgroundColor );

	-- Background color
	local color = frameOptions.windowBackgroundColor;
	if (type(color) ~= "table") then
		color = defaultWindowColor;
	end
	if (#color ~= 4) then
		for i = 1, 4 do
			color[i] = defaultWindowColor[i];
		end
	end
	-- Note: Due to the way the colorswatch object works in CT_Library, we have to maintain
	-- a general (non window specific) option of the same name we're using for the window.
	-- Also, in addition to setting the vertex color of the color button, we need to change
	-- the .r, .g, .b, and .opacity values of the colorswatch object to be the values of
	-- the window currently being edited.
	frame.windowBackgroundColor.r = color[1];
	frame.windowBackgroundColor.g = color[2];
	frame.windowBackgroundColor.b = color[3];
	frame.windowBackgroundColor.opacity = color[4];
	frame.windowBackgroundColor.normalTexture:SetVertexColor(color[1], color[2], color[3]);
	-- We need to set the general option so that the colorswatch object works correctly
	-- for the window currently being edited. The code in CT_Library makes calls to :getOption()
	-- to retrieve the current value, so we need to maintain a general (non frame specific) option
	-- with the color values for the window currently being edited.
	-- Temporarily disable the do not update flag so we can set the option.
	value = doNotUpdateFlag;
	doNotUpdateFlag = nil;
	module:setOption("windowBackgroundColor", { color[1], color[2], color[3], color[4] });
	doNotUpdateFlag = value;

	----------
	-- Border
	----------
	-- Show border
	frame.showBorder:SetChecked( not not frameOptions.showBorder );

	-- Border sizes
	frame.userEdgeLeft:SetValue( frameOptions.userEdgeLeft or 0 );
	frame.userEdgeRight:SetValue( frameOptions.userEdgeRight or 0 );
	frame.userEdgeTop:SetValue( frameOptions.userEdgeTop or 0 );
	frame.userEdgeBottom:SetValue( frameOptions.userEdgeBottom or 0 );

	----------
	-- Layout
	----------
	local layoutType = frameOptions.layoutType or constants.DEFAULT_LAYOUT;

	-- Layout
	if UIDropDownMenu_Initialize then
		dropdown = CT_BuffModDropdown_layoutType;
		UIDropDownMenu_Initialize( dropdown, dropdown.initialize );
		UIDropDownMenu_SetSelectedValue( dropdown, layoutType );
	end

	if (
		layoutType == constants.LAYOUT_GROW_DOWN_WRAP_RIGHT or
		layoutType == constants.LAYOUT_GROW_DOWN_WRAP_LEFT or
		layoutType == constants.LAYOUT_GROW_UP_WRAP_RIGHT or
		layoutType == constants.LAYOUT_GROW_UP_WRAP_LEFT
	) then

		frame.layoutTypeText:SetText(L["CT_BuffMod/Options/Window/Layout/VerticalLayoutTip"]);
		frame.wrapAfter.titleText = L["CT_BuffMod/Options/Window/Layout/VerticalWrapAfterSlider"];
		frame.maxWraps.titleText = L["CT_BuffMod/Options/Window/Layout/VerticalMaxWrapsSlider"];
		frame.wrapSpacing.titleText = L["CT_BuffMod/Options/Window/Layout/VerticalWrapSpacingSlider"];
	else
		frame.layoutTypeText:SetText(L["CT_BuffMod/Options/Window/Layout/HorizontalLayoutTip"]);
		frame.wrapAfter.titleText = L["CT_BuffMod/Options/Window/Layout/HorizontalWrapAfterSlider"];
		frame.maxWraps.titleText = L["CT_BuffMod/Options/Window/Layout/HorizontalMaxWrapsSlider"];
		frame.wrapSpacing.titleText = L["CT_BuffMod/Options/Window/Layout/HorizontalWrapSpacingSlider"];
	end

	value = frameOptions.wrapAfter or constants.DEFAULT_WRAP_AFTER;
	slider = frame.wrapAfter;
	slider:SetValue( value );
	slider.title:SetText(gsub(slider.titleText, "<value>", floor( ( value or slider:GetValue() )*100+0.5)/100));

	value = frameOptions.maxWraps or constants.DEFAULT_MAX_WRAPS;
	slider = frame.maxWraps;
	slider:SetValue( value );
	slider.title:SetText(gsub(slider.titleText, "<value>", floor( ( value or slider:GetValue() )*100+0.5)/100));

	frame.buffSpacing:SetValue( frameOptions.buffSpacing or 0 );

	value = frameOptions.wrapSpacing or 0;
	slider = frame.wrapSpacing;
	slider:SetValue( value );
	slider.title:SetText(gsub(slider.titleText, "<value>", floor( ( value or slider:GetValue() )*100+0.5)/100));

	if UIDropDownMenu_Initialize then
		----------
		-- Font Size
		----------

		dropdown = CT_BuffModDropdown_fontSize;
		UIDropDownMenu_Initialize( dropdown, dropdown.initialize );
		UIDropDownMenu_SetSelectedValue( dropdown, frameOptions.fontSize or 1 );

		----------
		-- Appearance
		----------
		dropdown = CT_BuffModDropdown_buttonStyle;
		UIDropDownMenu_Initialize( dropdown, dropdown.initialize );
		UIDropDownMenu_SetSelectedValue( dropdown, frameOptions.buttonStyle or 1 );
	end
	
	----------
	-- Style 1
	----------
	frame.style1Collapsible.buffSize1:SetValue( frameOptions.buffSize1 or constants.BUFF_SIZE_DEFAULT );
	frame.style1Collapsible.colorCodeIcons1:SetChecked( not not frameOptions.colorCodeIcons1 );
	frame.style1Collapsible.normalIconBorder1:SetChecked( not not frameOptions.normalIconBorder1 );
	frame.style1Collapsible.detailWidth1:SetValue( frameOptions.detailWidth1 or constants.DEFAULT_DETAIL_WIDTH );

	if UIDropDownMenu_Initialize then
		dropdown = CT_BuffModDropdown_rightAlign1;
		UIDropDownMenu_Initialize( dropdown, dropdown.initialize );
		UIDropDownMenu_SetSelectedValue( dropdown, tonumber(frameOptions.rightAlign1) or constants.RIGHT_ALIGN_DEFAULT );
	end

	frame.style1Collapsible.colorBuffs1:SetChecked( frameOptions.colorBuffs1 ~= false );
	frame.style1Collapsible.colorCodeBackground1:SetChecked( not not frameOptions.colorCodeBackground1 );

	frame.style1Collapsible.showNames1:SetChecked( frameOptions.showNames1 ~= false );

	frame.style1Collapsible.colorCodeDebuffs1:SetChecked( not not frameOptions.colorCodeDebuffs1 );

	if UIDropDownMenu_Initialize then
		dropdown = CT_BuffModDropdown_nameJustifyWithTime1;
		UIDropDownMenu_Initialize( dropdown, dropdown.initialize );
		UIDropDownMenu_SetSelectedValue( dropdown, frameOptions.nameJustifyWithTime1 or constants.JUSTIFY_DEFAULT );

		dropdown = CT_BuffModDropdown_nameJustifyNoTime1;
		UIDropDownMenu_Initialize( dropdown, dropdown.initialize );
		UIDropDownMenu_SetSelectedValue( dropdown, frameOptions.nameJustifyNoTime1 or constants.JUSTIFY_DEFAULT );
	end
	frame.style1Collapsible.showTimers1:SetChecked( frameOptions.showTimers1 ~= false );

	if UIDropDownMenu_Initialize then
		dropdown = CT_BuffModDropdown_durationFormat1;
		UIDropDownMenu_Initialize( dropdown, dropdown.initialize );
		UIDropDownMenu_SetSelectedValue( dropdown, frameOptions.durationFormat1 or 1 );

		dropdown = CT_BuffModDropdown_durationLocation1;
		UIDropDownMenu_Initialize( dropdown, dropdown.initialize );
		UIDropDownMenu_SetSelectedValue( dropdown, frameOptions.durationLocation1 or constants.DURATION_LOCATION_DEFAULT );

		dropdown = CT_BuffModDropdown_timeJustifyNoName1;
		UIDropDownMenu_Initialize( dropdown, dropdown.initialize );
		UIDropDownMenu_SetSelectedValue( dropdown, frameOptions.timeJustifyNoName1 or constants.JUSTIFY_DEFAULT );
	end
	
	frame.style1Collapsible.showBuffTimer1:SetChecked( frameOptions.showBuffTimer1 ~= false );
	frame.style1Collapsible.showTimerBackground1:SetChecked( frameOptions.showTimerBackground1 ~= false );

	frame.style1Collapsible.spacingOnLeft1:SetValue( frameOptions.spacingOnLeft1 or 0 );
	frame.style1Collapsible.spacingOnRight1:SetValue( frameOptions.spacingOnRight1 or 0 );

	----------
	-- Style 2
	----------
	frame.style2Collapsible.buffSize2:SetValue( frameOptions.buffSize2 or constants.BUFF_SIZE_DEFAULT );
	frame.style2Collapsible.colorCodeIcons2:SetChecked( not not frameOptions.colorCodeIcons2 );
	frame.style2Collapsible.normalIconBorder2:SetChecked( not not frameOptions.normalIconBorder2 );

	frame.style2Collapsible.showTimers2:SetChecked( frameOptions.showTimers2 ~= false );

	if UIDropDownMenu_Initialize then
		dropdown = CT_BuffModDropdown_durationFormat2;
		UIDropDownMenu_Initialize( dropdown, dropdown.initialize );
		UIDropDownMenu_SetSelectedValue( dropdown, frameOptions.durationFormat2 or 1 );

		dropdown = CT_BuffModDropdown_dataSide2;
		UIDropDownMenu_Initialize( dropdown, dropdown.initialize );
		UIDropDownMenu_SetSelectedValue( dropdown, frameOptions.dataSide2 or constants.DATA_SIDE_BOTTOM );
	end
	
	frame.style2Collapsible.spacingFromIcon2:SetValue( frameOptions.spacingFromIcon2 or 0 );

	doNotUpdateFlag = nil;
end

local function options_setCurrentWindow(windowId, showTitle)
	currentWindowId = windowId;
	globalObject.windowListObject:setCurrentWindow(currentWindowId, showTitle);
	options_updateWindowWidgets(currentWindowId);
end

local function options_updateValue(optName, value, windowId)
	-- Update an option value.

	-- Note: Due to the way the colorswatch object works in CT_Library, we don't want to clear
	-- the "windowBackgroundColor" option. It should always be set to the value of the window
	-- currently being edited since the CT_Library code uses :getOption() to get the current value.
	if (optName ~= "windowBackgroundColor") then
		-- Clear the general option.
		module:setOption(optName, nil);
	end

	-- Assign the value to the frame's option table.
	local windowObject = globalObject.windowListObject:findWindow(windowId);
	local primaryObject = windowObject.primaryObject;
	local frameOptions = primaryObject:getOptions();
	local apply;

	-- Check to see if the value has changed.
	if (type(value) == "table") then
		local option = frameOptions[optName];
		if (type(option) ~= "table") then
			option = {};
		end
		for k, v in pairs(value) do
			if (option[k] ~= v) then
				apply = true;
				break;
			end
		end
	else
		if (frameOptions[optName] ~= value) then
			apply = true;
		end
	end

	-- Value has changed, so it needs to be applied.
	if (apply) then
		if (type(value) == "table") then
			local option = frameOptions[optName];
			if (type(option) ~= "table") then
				option = {};
			end
			for k, v in pairs(value) do
				option[k] = v;
			end
			frameOptions[optName] = option;
		else
			frameOptions[optName] = value;
		end
		primaryObject:setOptions(frameOptions);

		-- Return the primaryObject of the window being edited.
		return primaryObject;
	end

	return nil;
end

local function options_updateOther(optName, value, windowId)
	-- Update an "other" option.
	local primaryObject = options_updateValue(optName, value, windowId);

	if (primaryObject) then
		-- The option changed. Apply the options.
		primaryObject:applyOtherOptions(false);
	end
end

local function options_updateUnprotected(optName, value, windowId)
	-- Update an "unprotected" option.
	local primaryObject = options_updateValue(optName, value, windowId);
	
	if (primaryObject) then
		
		-- The option changed. Apply the options.
		primaryObject:applyUnprotectedOptions(false);

		if (
			optName == "userEdgeLeft" or
			optName == "userEdgeRight" or
			optName == "userEdgeTop" or
			optName == "userEdgeBottom"
		) then
			primaryObject.consolidatedObject:setBorder();
			primaryObject.consolidatedObject:setClamped();

			primaryObject:setBorder();
			primaryObject:setClamped();
		end
		
		if (
			optName == "fontSize"
		) then
			primaryObject:updateAuraButtons(auraButton_updateAppearance);
		end
	end
end

local function options_updateProtected(optName, value, windowId)
	-- Update a "protected" option.
	local primaryObject = options_updateValue(optName, value, windowId);

	if (primaryObject) then
		-- The option changed. Apply the options.
		primaryObject:applyProtectedOptions(false);

		if (
			optName == "layoutType" or
			optName == "playerUnsecure" or
			optName == "separateZero" or
			optName == "groupByPriority" or
			optName == "sortSeq1" or
			optName == "sortSeq2" or
			optName == "sortSeq3" or
			optName == "sortSeq4" or
			optName == "sortSeq5" or
			optName == "unitType"
		) then
			options_updateWindowWidgets(windowId);

		elseif ( optName == "visWindow" ) then
			options_updateWindowWidgets_Visibility(windowId);
		end
	end
end

local function options_updateGlobal(optName, value)
	-- Update a "global" option.
	globalObject:applyGlobalOptions(false);

	if (
		optName == "bgColorAURA" or
		optName == "bgColorBUFF" or
		optName == "bgColorDEBUFF" or
		optName == "bgColorITEM" or
		optName == "bgColorCONSOLIDATED"
	) then
		globalObject.windowListObject:refreshAuraButtons();

	elseif (optName == "backgroundColor") then
		globalObject.windowListObject:setBackground();

	elseif (optName == "consolidatedColor") then
		globalObject.windowListObject:setBackground();

	elseif (optName == "consolidatedHideTimer") then
		globalObject.windowListObject:setSpecialAttributes();

	end
end

local function options_editWindow(windowNum)
	-- Select window to edit.
	local windowListObject = globalObject.windowListObject;

	-- Clear the temp option.
	module:setOption("editWindow", nil);

	-- Switch to the window.
	options_setCurrentWindow( windowListObject:windowNumToId(windowNum), true );
end

function module:options_editWindow(windowId)
	if (not isOptionsFrameShown()) then
		module:showModuleOptions();
	end

	ctprint(format(L["CT_BuffMod/Options/WindowControls/WindowSelectedMessage"],windowId));

	local windowListObject = globalObject.windowListObject;
	local windowNum = windowListObject:windowIdToNum(windowId);
	options_editWindow(windowNum);
end

local function options_nextWindow()
	-- Select next window to edit.
	local windowListObject = globalObject.windowListObject;
	local windowNum = windowListObject:windowIdToNum(currentWindowId);

	windowNum = windowNum + 1;
	if (windowNum > windowListObject:getWindowCount()) then
		windowNum = 1
	end

	-- Switch to the window.
	options_setCurrentWindow( windowListObject:windowNumToId(windowNum), true );
end

local function options_prvsWindow()
	-- Select previous window to edit.
	local windowListObject = globalObject.windowListObject;
	local windowNum = windowListObject:windowIdToNum(currentWindowId);

	windowNum = windowNum - 1;
	if (windowNum < 1) then
		windowNum = windowListObject:getWindowCount();
	end

	-- Switch to the window.
	options_setCurrentWindow( windowListObject:windowNumToId(windowNum), true );
end

local function options_addWindow()
	-- Add a new window.
	local windowListObject = globalObject.windowListObject;

	if (InCombatLockdown()) then
		ctprint("You cannot add a window when in combat.");
		return;
	end

	-- Can't add more than the maximum number of allowed windows.
	local maxNum = windowListObject:getMaxWindowCount();
	local count = windowListObject:getWindowCount();
	if (count >= maxNum) then
		ctprint("You cannot create more than " .. maxNum .. " windows.");
		return;
	end

	-- Create a new window
	local windowObject = windowListObject:addWindow("player", nil, nil);

	windowObject:updateSpellsAndEnchants();
	windowObject:refreshAuraButtons();
	windowObject:resetPosition();

	local windowId = windowObject:getWindowId();
	ctprint(format(L["CT_BuffMod/Options/WindowControls/WindowAddedMessage"], windowId));

	-- Switch to the window.
	options_setCurrentWindow( windowId, true );
end

local function options_deleteWindow()
	-- Delete a window
	local windowListObject = globalObject.windowListObject;

	-- Can't delete a window while in combat.
	if (InCombatLockdown()) then
		ctprint("You cannot delete a window when in combat.");
		return;
	end

	-- Remember the current window number.
	local windowNum = windowListObject:windowIdToNum(currentWindowId);

	-- Delete the current window from the list.
	windowListObject:deleteWindow(currentWindowId);
	ctprint(format(L["CT_BuffMod/Options/WindowControls/WindowDeletedMessage"], windowNum));

	-- If there are no windows left then create a new one so we have at least 1 window.
	if (windowListObject:getWindowCount() == 0) then
		local windowObject = windowListObject:addWindow("player", nil, nil);

		windowObject:updateSpellsAndEnchants();
		windowObject:refreshAuraButtons();
		windowObject:resetPosition();

		ctprint("No windows remain. Window " .. windowObject:getWindowId() .. " added.");
	end

	-- Determine which window to show options for.
	local count = windowListObject:getWindowCount();
	if (windowNum > count) then
		windowNum = count;
	end

	-- Switch to the window.
	options_setCurrentWindow( windowListObject:windowNumToId(windowNum), true );
end

local function options_cloneWindow()
	-- Create a new window using a copy of an existing window's options.
	local windowListObject = globalObject.windowListObject;

	if (InCombatLockdown()) then
		ctprint("You cannot copy a window when in combat.");
		return;
	end

	-- Can't add more than the maximum number of allowed windows.
	local maxNum = windowListObject:getMaxWindowCount();
	local count = windowListObject:getWindowCount();
	if (count >= maxNum) then
		ctprint("You cannot create more than " .. maxNum .. " windows.");
		return;
	end

	-- Get the source window object.
	local windowObject1 = windowListObject:findWindow(currentWindowId);
	local unitId = windowObject1.primaryObject:getUnitId();

	-- Add a destination window object using the source object for its options.
	local windowObject2 = windowListObject:addWindow( unitId, nil, windowObject1 );

	windowObject2:updateSpellsAndEnchants();
	windowObject2:refreshAuraButtons();
	windowObject2:resetPosition();
	-- Cloning a disabled window will leave the new window at the same screen
	-- location as the original. The :resetPosition() does nothing since the
	-- disabled window does not have an auraFrame that can be repositioned.

	ctprint(format(L["CT_BuffMod/Options/WindowControls/WindowClonedMessage"], windowObject2:getWindowId(), windowObject1:getWindowId()));

	-- Switch to the window.
	options_setCurrentWindow( windowObject2:getWindowId(), true );
end

module.optionUpdate = function(self, optName, value)
	-- Update an option.

	if (doNotUpdateFlag) then
		return;
	end

	-- Window id of the window currently being edited.
	local windowId = currentWindowId;

	if (optName ~= "init" and value == nil) then
		-- Prevent ininfite loop when clearing an option
		-- from within this function.
		return;
	end

	-- Translate option name, value, etc. if necessary before processing the option.
	if ( optName == "visShow" ) then
		self:setOption(optName, nil);
		optName = "visWindow";
		value = constants.VISIBILITY_SHOW;
	elseif ( optName == "visBasic" ) then
		self:setOption(optName, nil);
		optName = "visWindow";
		value = constants.VISIBILITY_BASIC;
	elseif ( optName == "visAdvanced" ) then
		self:setOption(optName, nil);
		optName = "visWindow";
		value = constants.VISIBILITY_ADVANCED;
	end

	if (optName == "editWindow") then
		options_editWindow(value);

	-- Other options
	elseif (
		optName == "clampWindow" or
		optName == "showBackground" or
		optName == "showBorder" or
		optName == "useCustomBackgroundColor" or
		optName == "windowBackgroundColor"
	) then
		options_updateOther(optName, value, windowId);

	-- Unprotected options
	elseif (
		optName == "colorBuffs1" or
		optName == "colorCodeBackground1" or
		optName == "colorCodeDebuffs1" or
		optName == "colorCodeIcons1" or
		optName == "colorCodeIcons2" or
		optName == "dataSide2" or
		optName == "durationFormat1" or
		optName == "durationFormat2" or
		optName == "showDays1" or
		optName == "showDays2" or
		optName == "durationLocation1" or
		optName == "nameJustifyWithTime1" or
		optName == "nameJustifyNoTime1" or
		optName == "normalIconBorder1" or
		optName == "normalIconBorder2" or
		optName == "showBuffTimer1" or
		optName == "showNames1" or
		optName == "showTimerBackground1" or
		optName == "showTimers1" or
		optName == "showTimers2" or
		optName == "spacingFromIcon2" or
		optName == "spacingOnLeft1" or
		optName == "spacingOnRight1" or
		optName == "timeJustifyNoName1" or
		optName == "userEdgeLeft" or
		optName == "userEdgeRight" or
		optName == "userEdgeTop" or
		optName == "userEdgeBottom" or
		optName == "fontSize"
	) then
		options_updateUnprotected(optName, value, windowId);

	-- Protected options specific to the primary object (ie. don't apply to secondary objects)
	elseif (
		optName == "disableWindow" or
		optName == "disableTooltips" or
		optName == "playerUnsecure" or
		optName == "unitType" or
		optName == "vehicleBuffs"
	) then
		options_updateProtected(optName, value, windowId);

		if ( optName == "playerUnsecure" ) then
			globalObject.windowListObject:setCurrentWindow( currentWindowId, true );
		end

	-- Protected options
	elseif (
		optName == "buffSize1" or
		optName == "buffSize2" or
		optName == "buffSpacing" or
		optName == "buttonStyle" or
		optName == "consolidateDurationMinutes" or
		optName == "consolidateDurationSeconds" or
		optName == "consolidateFractionPercent" or
		optName == "consolidateThresholdMinutes" or
		optName == "consolidateThresholdSeconds" or
		optName == "detailWidth1" or
		optName == "layoutType" or
		optName == "lockWindow" or
		optName == "maxWraps" or
		optName == "rightAlign1" or
		optName == "separateOwn" or
		optName == "separateZero" or
		optName == "groupByPriority" or
		optName == "sortDirection" or
		optName == "sortMethod" or
		optName == "sortSeq1" or
		optName == "sortSeq2" or
		optName == "sortSeq3" or
		optName == "sortSeq4" or
		optName == "sortSeq5" or
		optName == "visCondition" or
		optName == "visHideInVehicle" or
		optName == "visHideNotVehicle" or
		optName == "visHideInCombat" or
		optName == "visHideNotCombat" or
		optName == "visWindow" or
		optName == "wrapAfter" or
		optName == "wrapSpacing"
	) then
		if (
			optName == "sortSeq1" or
			optName == "sortSeq2" or
			optName == "sortSeq3" or
			optName == "sortSeq4" or
			optName == "sortSeq5"
		) then
			-- Set flag to the sequence number that was changed
			-- so that we can detect this during the
			-- :validateProtectedOptions method. We want to keep
			-- the value the user just changed, and in the case
			-- of duplicates get rid of the other ones.
			-- Normally it keeps the first one when it finds a
			-- duplicate.
			sortSeqChanged = tonumber(strsub(optName, 8, 8));
		else
			sortSeqChanged = nil;
		end
		options_updateProtected(optName, value, windowId);
		sortSeqChanged = nil;

		if ( optName == "visWindow" ) then
			options_updateWindowWidgets_Visibility(windowId);
		end

	-- Global options
	elseif (
		optName == "backgroundColor" or
		optName == "bgColorAURA" or
		optName == "bgColorBUFF" or
		optName == "bgColorDEBUFF" or
		optName == "bgColorITEM" or
		optName == "bgColorCONSOLIDATED" or
		optName == "consolidatedColor" or
		optName == "consolidatedHideTimer" or
		optName == "enableExpiration" or
		optName == "expirationCastOnly" or
		optName == "expirationSound" or
		optName == "expirationTime1" or
		optName == "expirationTime2" or
		optName == "expirationTime3" or
		optName == "flashTime" or
		optName == "hideBlizzardBuffs" or
		optName == "hideBlizzardConsolidated" or
		optName == "hideBlizzardEnchants"
	) then
		options_updateGlobal(optName, value);
	end

	-- Clear edit box focus and highlight.
	-- Calling it here will ensure the focus is removed regardless of
	-- which option the user changes.
	if (windowOptionsFrame) then
		windowOptionsFrame.conditionEB:ClearFocus();
		windowOptionsFrame.conditionEB:HighlightText(0, 0);
	end
end

--------------------------------------------
-- The options frame.

local optionsFrameList;
local function optionsInit()
	optionsFrameList = module:framesInit();
end
local function optionsGetData() return module:framesGetData(optionsFrameList); end
local function optionsAddFrame(offset, size, details, data)	module:framesAddFrame(optionsFrameList, offset, size, details, data); end
local function optionsAddObject(offset, size, details) 	module:framesAddObject(optionsFrameList, offset, size, details); end
local function optionsAddScript(name, func) 	module:framesAddScript(optionsFrameList, name, func); end
local optionsAddTooltip = function(text) 	module:framesAddScript(optionsFrameList, "onenter", function(obj) module:displayTooltip(obj, text, "CT_ABOVEBELOW", 0, 0, CTCONTROLPANEL); end); end
local function optionsBeginFrame(offset, size, details, data) 	module:framesBeginFrame(optionsFrameList, offset, size, details, data); end
local function optionsEndFrame() 	module:framesEndFrame(optionsFrameList); end
local function optionsAddFromTemplate (offset, size, details, template) module:framesAddFromTemplate(optionsFrameList, offset, size, details, template) end

module.frame = function()
	local updateFunc = function(self, value)
		value = floor((value or self:GetValue())/self:GetValueStep())*self:GetValueStep();
		local timeLeft = floor( value * 10 + 0.5 ) / 10;
		if ( timeLeft == 0 ) then
			self.title:SetText(L["CT_BuffMod/TimeFormat/Off"]);
		else
			self.title:SetText(humanizeTime(timeLeft));
		end
		local option = self.option;
		if ( option ) then
			module:setOption(option, value);
		end
	end;

	local textColor1 = "0.9:0.9:0.9";
	local textColor2 = "0.7:0.7:0.7";
	local textColor3 = "0.9:0.72:0.0";
	local offset;
	local temp;

	optionsInit();

	-- Tips
	optionsBeginFrame(-5, 0, "frame#tl:0:%y#r");
		optionsAddObject(  0,   17, "font#tl:5:%y#v:GameFontNormalLarge#" .. L["CT_BuffMod/Options/Tips/Heading"]);
		optionsAddObject( -5, 2*14, "font#t:0:%y#s:0:%s#l:13:0#r#" .. L["CT_BuffMod/Options/Tips/Line 1"] .. "#" .. textColor2 .. ":l");  -- You can use /ctbuff or /ctbuffmod to open this options window directly.
		optionsAddObject( -5, 3*14, "font#t:0:%y#s:0:%s#l:13:0#r#" .. L["CT_BuffMod/Options/Tips/Line 2"] .. "#" .. textColor2 .. ":l");  -- You can use Alt Left-click on a CT_BuffMod window to select it and open this options window.
		optionsAddObject( -5, 2*14, "font#t:0:%y#s:0:%s#l:13:0#r#" .. L["CT_BuffMod/Options/Tips/Line 3"] .. "#" .. textColor2 .. ":l");  -- NOTE: Most options have no effect until you are out of combat.
	optionsEndFrame();

	-- Blizzard's frames
	optionsBeginFrame(-20, 0, "frame#tl:0:%y#r#i:blizzardFrames");
		optionsAddObject(  0,   17, "font#tl:5:%y#v:GameFontNormalLarge#" .. L["CT_BuffMod/Options/Blizzard Frames/Heading"]);

		-- Hide the buffs frame
		-- Hide the consolidated buffs frame
		-- Hide the weapon buffs frame
		optionsAddObject( -5,   26, "checkbutton#tl:10:%y#o:hideBlizzardBuffs:true#" .. L["CT_BuffMod/Options/Blizzard Frames/Hide Buffs"]);
		optionsAddObject(  6,   26, "checkbutton#tl:10:%y#o:hideBlizzardEnchants:true#" .. L["CT_BuffMod/Options/Blizzard Frames/Hide Enchants"]);
--[[ CONSOLIDATION REMOVED FROM GAME
		optionsAddObject(  6,   26, "checkbutton#tl:10:%y#o:hideBlizzardConsolidated:true#" .. L["CT_BuffMod/Options/Blizzard Frames/Hide Consolidated"]);
CONSOLIDATION REMOVED FROM GAME --]]
	optionsEndFrame();

	-- General Options
	optionsBeginFrame(-20, 0, "frame#tl:0:%y#br:tr:0:%b");
		optionsAddObject(  0,   17, "font#tl:5:%y#v:GameFontNormalLarge#" .. L["CT_BuffMod/Options/General/Heading"]);

		optionsAddObject(-15, 1*13, "font#tl:15:%y#" .. L["CT_BuffMod/Options/General/Colors/Heading"]);

		-- Window background color
		optionsAddObject(-10,   16, "colorswatch#tl:35:%y#s:16:16#o:backgroundColor:" .. defaultWindowColor[1] .. "," .. defaultWindowColor[2] .. "," .. defaultWindowColor[3] .. "," .. defaultWindowColor[4] .. "#true");
		optionsAddObject( 14,   15, "font#tl:60:%y#v:ChatFontNormal#" .. L["CT_BuffMod/Options/General/Colors/Background"]);

		-- Aura color
		-- Buff color
		-- Debuff color
		-- Weapon buff color
		optionsAddObject(-15,   16, "colorswatch#tl:35:%y#s:16:16#i:bgColorAURA#o:bgColorAURA:0.35,0.8,0.15,0.5#true");
		optionsAddObject( 14,   15, "font#tl:60:%y#v:ChatFontNormal#" .. L["CT_BuffMod/Options/General/Colors/Aura"]);

		optionsAddObject( 15,   16, "colorswatch#tl:175:%y#s:16:16#i:bgColorBUFF#o:bgColorBUFF:0.1,0.4,0.85,0.5#true");
		optionsAddObject( 14,   15, "font#tl:200:%y#v:ChatFontNormal#" .. L["CT_BuffMod/Options/General/Colors/Buff"]);

		optionsAddObject( -2,   16, "colorswatch#tl:35:%y#s:16:16#i:bgColorDEBUFF#o:bgColorDEBUFF:1,0,0,0.85#true");
		optionsAddObject( 14,   15, "font#tl:60:%y#v:ChatFontNormal#" .. L["CT_BuffMod/Options/General/Colors/Debuff"]);

		optionsAddObject( 15,   16, "colorswatch#tl:175:%y#s:16:16#i:bgColorITEM#o:bgColorITEM:0.75,0.25,1,0.75#true");
		optionsAddObject( 14,   15, "font#tl:200:%y#v:ChatFontNormal#" .. L["CT_BuffMod/Options/General/Colors/Weapon"]);

--[[ CONSOLIDATION REMOVED FROM GAME
		optionsAddObject( -15,   16, "colorswatch#tl:35:%y#s:16:16#o:consolidatedColor:" .. defaultConsolidatedColor[1] .. "," .. defaultConsolidatedColor[2] .. "," .. defaultConsolidatedColor[3] .. "," .. defaultConsolidatedColor[4] .. "#true");
		optionsAddObject( 14,   15, "font#tl:60:%y#v:ChatFontNormal#Consolidated window background color");
		optionsAddObject( -2,   16, "colorswatch#tl:35:%y#s:16:16#i:bgColorCONSOLIDATED#o:bgColorCONSOLIDATED:0.97,0.97,0.95,0.66#true");
		optionsAddObject( 14,   15, "font#tl:60:%y#v:ChatFontNormal#Consolidated bar color");

		-- Consolidated window
		optionsAddObject(-15, 1*13, "font#tl:15:%y#Consolidated window");

		optionsBeginFrame(  17,   20, "button#tl:250:%y#s:40:%s#i:consWindowHelp#v:UIPanelButtonTemplate#?");
			optionsAddScript("onenter",
				function(self)
					GameTooltip:SetOwner(self, "ANCHOR_RIGHT", 35, 0);
					GameTooltip:SetText("Consolidated window");
					GameTooltip:AddLine("If you choose Consolidated as one of the group items in the Sorting section, then some buffs will be placed in a separate window instead of in the main window.", 1, 1, 1, true);
					GameTooltip:AddLine("\nA Consolidated button will then appear in the main window. When you move the mouse over the button, the Consolidated window will appear. You can move the mouse into the Consolidated window to view buff tooltips or cancel buffs.", 1, 1, 1, true);
					GameTooltip:AddLine("\nThe Consolidated window will be automatically hidden when the mouse is not over it, or the consolidated button, for more than the amount of time configured for the 'Auto hide timer' option.", 1, 1, 1, true);
					GameTooltip:Show();
				end
			);
			optionsAddScript("onleave",
				function(self)
					GameTooltip:Hide();
				end
			);
		optionsEndFrame();

		optionsAddObject(-20,   14, "font#tl:30:%y#v:ChatFontNormal#Auto hide timer:");
		optionsAddObject( 15,   17, "slider#tl:150:%y#s:140:%s#i:consolidatedHideTimer#o:consolidatedHideTimer:" .. constants.DEFAULT_CONSOLIDATE_HIDE_TIMER .. "#<value> seconds#0.05:2:0.05");
CONSOLIDATION REMOVED FROM GAME --]]

	optionsEndFrame();

	-- Expiration options

	optionsAddObject( -15,   13, "font#tl:15:%y#v:GameFontNormal#" .. L["CT_BuffMod/Options/General/Expiration/Heading"]);

	optionsAddObject(-22,   7, "font#l:tl:30:%y#v:ChatFontNormal#" .. L["CT_BuffMod/Options/General/Expiration/FlashSliderLabel"]);
	optionsBeginFrame(15,   17, "slider#tl:175:%y#tr:-5:%y#i:flashTime#o:flashTime:" .. constants.DEFAULT_FLASH_TIME .. "#<value> seconds:" .. L["CT_BuffMod/TimeFormat/Off"] .. ":" .. format(L["CT_BuffMod/TimeFormat/Minutes Smaller"],1) .. "#0:60:1");
		optionsAddScript("onvaluechanged", updateFunc);
		optionsAddScript("onload", updateFunc);
	optionsEndFrame();

	optionsAddObject(-18,   26, "checkbutton#tl:30:%y#o:enableExpiration:true#" .. L["CT_BuffMod/Options/General/Expiration/ChatMessageCheckbox"])
	optionsBeginFrame( 0,    0, "collapsible#tl:0:%y#br:tr:0:%b#i:expirationCollapsible#o:enableExpiration:true")
		optionsAddObject(  5,   26, "checkbutton#tl:48:%y#o:expirationCastOnly#" .. L["CT_BuffMod/Options/General/Expiration/PlayerBuffsOnlyCheckbox"]);
		optionsAddObject(  5,   26, "checkbutton#tl:48:%y#o:expirationSound:true#" .. L["CT_BuffMod/Options/General/Expiration/PlaySoundCheckbox"]);

		optionsAddObject(-10,   15, "font#tl:55:%y#n:expirationDurationHeading#" .. L["CT_BuffMod/Options/General/Expiration/DurationHeading"]);
		optionsAddObject( 15,   15, "font#tl:175:%y#n:expirationWarningTimeHeading#" .. L["CT_BuffMod/Options/General/Expiration/WarningTimeHeading"]);

		optionsAddObject(-23,   15, "font#tl:55:%y#n:expirationTime1Label#v:ChatFontNormal#  2:00  -  10:00");
		optionsBeginFrame(  18,   17, "slider#tl:175:%y#tr:-5:%y#n:CT_BuffMod_ExpirationTime1Slider#o:expirationTime1:15#:" .. L["CT_BuffMod/TimeFormat/Off"] .. ":" .. format(L["CT_BuffMod/TimeFormat/Minutes Smaller"],1) .. "#0:60:5");
			optionsAddScript("onvaluechanged", updateFunc);
			optionsAddScript("onload", updateFunc);
		optionsEndFrame();

		optionsAddObject(-27,   15, "font#tl:55:%y#n:expirationTime2Label#v:ChatFontNormal#10:01  -  30:00");
		optionsBeginFrame(  18,   17, "slider#tl:175:%y#tr:-5:%y#n:CT_BuffMod_ExpirationTime2Slider#o:expirationTime2:60#:" .. L["CT_BuffMod/TimeFormat/Off"] .. ":" .. format(L["CT_BuffMod/TimeFormat/Minutes Smaller"],3) .. "#0:180:5");
			optionsAddScript("onvaluechanged", updateFunc);
			optionsAddScript("onload", updateFunc);
		optionsEndFrame();

		optionsAddObject(-27,   15, "font#tl:55:%y#n:expirationTime3Label#v:ChatFontNormal#30:01  +");
		optionsBeginFrame(  18,   17, "slider#tl:175:%y#tr:-5:%y#n:CT_BuffMod_ExpirationTime3Slider#o:expirationTime3:180#:" .. L["CT_BuffMod/TimeFormat/Off"] .. ":" .. format(L["CT_BuffMod/TimeFormat/Minutes Smaller"],5) .. "#0:300:5");
			optionsAddScript("onvaluechanged", updateFunc);
			optionsAddScript("onload", updateFunc);
			optionsAddScript("onshow", enableExpirationChildren);
		optionsEndFrame();
	optionsEndFrame()
	

	-- Adding and Removing Windows
	optionsBeginFrame(-20, 0, "frame#tl:0:%y#br:tr:0:%b#i:frameOptions#n:foo");
		optionsAddScript("onload", function(self)
			self.collapsibleChildrenMayShrink = true
		end)
		optionsAddObject(-10,   17, "font#tl:5:%y#v:GameFontNormalLarge#" .. L["CT_BuffMod/Options/WindowControls/Heading"]);

		optionsBeginFrame( -10,   30, "button#tl:15:%y#s:80:%s#v:UIPanelButtonTemplate#" .. L["CT_BuffMod/Options/WindowControls/AddButton"]);
			optionsAddScript("onclick", function(self)
				options_addWindow();
			end);
			optionsAddScript("onenter", function(self)
				GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT");
				GameTooltip:SetText(L["CT_BuffMod/Options/WindowControls/AddTooltip"], 1, 0.82, 0, 1, true);
				GameTooltip:Show();
			end);
			optionsAddScript("onleave", function(self)
				GameTooltip:Hide();
			end);
		optionsEndFrame();
		optionsBeginFrame(  30,   30, "button#tl:110:%y#s:80:%s#v:UIPanelButtonTemplate#" .. L["CT_BuffMod/Options/WindowControls/CloneButton"]);
			optionsAddScript("onclick", function(self)
				options_cloneWindow();
			end);
			optionsAddScript("onenter", function(self)
				GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT");
				GameTooltip:SetText(L["CT_BuffMod/Options/WindowControls/CloneTooltip"], 1, 0.82, 0, 1, true);
				GameTooltip:Show();
			end);
			optionsAddScript("onleave", function(self)
				GameTooltip:Hide();
			end);
		optionsEndFrame();
		optionsBeginFrame(  30,   30, "button#tl:205:%y#s:80:%s#v:UIPanelButtonTemplate#" .. L["CT_BuffMod/Options/WindowControls/DeleteButton"]);
			optionsAddScript("onclick", function(self)
				if (IsShiftKeyDown()) then
					options_deleteWindow();
				else
					ctprint(L["CT_BuffMod/Options/WindowControls/DeleteTooltip"]);
				end
			end);
			optionsAddScript("onenter", function(self)
				GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT");
				GameTooltip:SetText(L["CT_BuffMod/Options/WindowControls/DeleteTooltip"], 1, 0.82, 0, 1, true);
				GameTooltip:Show();
			end);
			optionsAddScript("onleave", function(self)
				GameTooltip:Hide();
			end);
		optionsEndFrame();

		optionsAddObject(-20,   14, "font#tl:15:%y#v:ChatFontNormal#" .. L["CT_BuffMod/Options/WindowControls/SelectionLabel"]);

		optionsBeginFrame( 19,   24, "button#tl:105:%y#s:24:%s");
			optionsAddScript("onclick",
				function(self)
					options_prvsWindow();
				end
			);
			optionsAddScript("onload",
				function(self)
					self:SetNormalTexture("Interface\\Buttons\\UI-SpellbookIcon-PrevPage-Up");
					self:SetPushedTexture("Interface\\Buttons\\UI-SpellbookIcon-PrevPage-Down");
					self:SetDisabledTexture("Interface\\Buttons\\UI-SpellbookIcon-PrevPage-Disabled");
					self:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight");
				end
			);
		optionsEndFrame();

		optionsBeginFrame( 24,   24, "button#tl:125:%y#s:24:%s");
			optionsAddScript("onclick",
				function(self)
					options_nextWindow();
				end
			);
			optionsAddScript("onload",
				function(self)
					self:SetNormalTexture("Interface\\Buttons\\UI-SpellbookIcon-NextPage-Up");
					self:SetPushedTexture("Interface\\Buttons\\UI-SpellbookIcon-NextPage-Down");
					self:SetDisabledTexture("Interface\\Buttons\\UI-SpellbookIcon-NextPage-Disabled");
					self:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight");
				end
			);
		optionsEndFrame();

		optionsAddObject( 20,   20, "dropdown#tl:140:%y#n:CT_BuffModDropdown_editWindow#o:editWindow#Window 1");

		optionsAddObject( -5, 2*14, "font#tl:15:%y#s:0:%s#l:13:0#r#" .. L["CT_BuffMod/Options/WindowControls/Tip"] .. "#" .. textColor2 .. ":l");

		----------
		-- Window
		----------

		optionsAddObject(-15, 1*13, "font#tl:15:%y#" .. L["CT_BuffMod/Options/Window/General/Heading"]);

		-- Unlock window
		-- Window cannot be moved off screen
		optionsAddObject( -5,   26, "checkbutton#tl:30:%y#i:disableWindow#o:disableWindow#" .. L["CT_BuffMod/Options/Window/General/DisableWindowCheckbox"]);
		optionsAddObject(  6,   26, "checkbutton#tl:30:%y#i:disableTooltips#o:disableTooltips#" .. L["CT_BuffMod/Options/Window/General/DisableTooltipsCheckbox"]);
		optionsAddObject(  6,   26, "checkbutton#tl:30:%y#i:lockWindow#o:lockWindow#" .. L["CT_BuffMod/Options/Window/General/PositionLockedCheckbox"]);
		optionsAddObject(  6,   26, "checkbutton#tl:30:%y#i:clampWindow#o:clampWindow:true#" .. L["CT_BuffMod/Options/Window/General/PositionClampedCheckbox"]);

		optionsBeginFrame( -5,   30, "button#t:0:%y#s:180:%s#n:CT_BuffMod_ResetPosition_Button#v:GameMenuButtonTemplate#" .. L["CT_BuffMod/Options/Window/General/PositionResetButton"]);
			optionsAddScript("onclick",
				function(self)
					local windowObject = globalObject.windowListObject:findWindow(currentWindowId);
					local primaryObject = windowObject.primaryObject;
					if (primaryObject) then
						if (not primaryObject.useUnsecure and InCombatLockdown()) then
							-- Do not restore position
						else
							primaryObject.consolidatedObject:resetPosition();
							primaryObject:resetPosition();
						end
					end
				end
			);
		optionsEndFrame();
		optionsAddObject( -5, 2*13, "font#t:0:%y#s:0:%s#l#r#".. L["CT_BuffMod/Options/Window/General/PositionResetTip"] .. "#" .. textColor2);

		----------
		-- Unit
		----------

		optionsAddObject(-20, 1*13, "font#tl:15:%y#" .. L["CT_BuffMod/Options/Window/Unit/Heading"]);
		do
			-- Show buffs for Player|Vehicle|Pet|Target|Focus
			-- Use unsecure buttons (refer to tooltip)
			-- Show vehicle buffs when in a vehicle
			optionsAddObject(-10,   14, "font#tl:34:%y#v:ChatFontNormal#" .. L["CT_BuffMod/Options/Window/Unit/UnitDropdownLabel"]);
			optionsAddObject( 15,   20, "dropdown#tl:140:%y#s:100:%s#n:CT_BuffModDropdown_unitType#i:unitType#o:unitType:" .. constants.UNIT_TYPE_PLAYER .. L["CT_BuffMod/Options/Window/Unit/UnitDropdownOptions"]);
			optionsBeginFrame(  0,   26, "checkbutton#tl:30:%y#i:playerUnsecure#o:playerUnsecure#" .. L["CT_BuffMod/Options/Window/Unit/NonSecureCheckbox"]);
				optionsAddScript("onenter",
					function(button)
						GameTooltip:SetOwner(button, "ANCHOR_RIGHT", 275, 0);
						GameTooltip:SetText(L["CT_BuffMod/Options/Window/Unit/SecureTooltip/Heading"]);
						GameTooltip:AddLine(L["CT_BuffMod/Options/Window/Unit/SecureTooltip/Content"]);
						GameTooltip:Show();
					end
				);
				optionsAddScript("onleave",
					function()
						GameTooltip:Hide();
					end
				);
			optionsEndFrame();
			optionsAddObject(  0,   26, "checkbutton#tl:30:%y#i:vehicleBuffs#o:vehicleBuffs:true#" .. L["CT_BuffMod/Options/Window/Unit/VehicleCheckbox"]);
		end

		----------
		-- Grouping (takes precedence over sorting)
		----------

		optionsAddObject(-20, 1*13, "font#tl:15:%y#" .. L["CT_BuffMod/Options/Window/Grouping/Heading"]);
		
		-- What sequence to apply grouping in
		optionsBeginFrame( 0,    0, "frame#tl:0:%y#br:tr:0:%b#i:groupByPriority");
		
			local groupByStrings =
			{
				[1] = "#" .. L["CT_BuffMod/Options/Window/Grouping/GroupByPriorityFragment1"] .. " > " .. L["CT_BuffMod/Options/Window/Grouping/GroupByPriorityFragment2"] .. " > " .. L["CT_BuffMod/Options/Window/Grouping/GroupByPriorityFragment3"],
				[2] = "#" .. L["CT_BuffMod/Options/Window/Grouping/GroupByPriorityFragment1"] .. " > " .. L["CT_BuffMod/Options/Window/Grouping/GroupByPriorityFragment3"] .. " > " .. L["CT_BuffMod/Options/Window/Grouping/GroupByPriorityFragment2"],
				[3] = "#" .. L["CT_BuffMod/Options/Window/Grouping/GroupByPriorityFragment2"] .. " > " .. L["CT_BuffMod/Options/Window/Grouping/GroupByPriorityFragment1"] .. " > " .. L["CT_BuffMod/Options/Window/Grouping/GroupByPriorityFragment3"],
				[4] = "#" .. L["CT_BuffMod/Options/Window/Grouping/GroupByPriorityFragment2"] .. " > " .. L["CT_BuffMod/Options/Window/Grouping/GroupByPriorityFragment3"] .. " > " .. L["CT_BuffMod/Options/Window/Grouping/GroupByPriorityFragment1"],
				[5] = "#" .. L["CT_BuffMod/Options/Window/Grouping/GroupByPriorityFragment3"] .. " > " .. L["CT_BuffMod/Options/Window/Grouping/GroupByPriorityFragment1"] .. " > " .. L["CT_BuffMod/Options/Window/Grouping/GroupByPriorityFragment2"],
				[6] = "#" .. L["CT_BuffMod/Options/Window/Grouping/GroupByPriorityFragment3"] .. " > " .. L["CT_BuffMod/Options/Window/Grouping/GroupByPriorityFragment2"] .. " > " .. L["CT_BuffMod/Options/Window/Grouping/GroupByPriorityFragment1"],
			}
			optionsAddObject(-10,   14, "font#tl:35:%y#v:ChatFontNormal#i:label#" .. L["CT_BuffMod/Options/Window/Grouping/GroupByPriorityLabel"]);
			optionsAddObject( 15,   20, "dropdown#tl:140:%y#s:130:%s#n:CT_BuffModDropdown_groupByPriority#i:dropdown#o:groupByPriority:" .. constants.GROUP_BY_FILTER_OWN_ZERO .. groupByStrings[1] .. groupByStrings[2] .. groupByStrings[3] .. groupByStrings[4] .. groupByStrings[5] .. groupByStrings[6]);
			optionsAddScript("onleave", function(frame)
				frame:GetParent().playerUnsecure.text:SetTextColor(1,1,1);
			end);
			optionsAddScript("onenter", function(frame)
				if (frame.label:GetAlpha() < 1) then
					module:displayTooltip(frame, {L["CT_BuffMod/Options/Window/Grouping/GroupByPriorityLabel"], L["CT_BuffMod/Options/Window/Grouping/MethodUnavailableTip"] .. "#" .. textColor2}, "CT_ABOVEBELOW", 0, 0, CTCONTROLPANEL);
					frame:GetParent().playerUnsecure.text:SetTextColor(1, 1, 0);
				else
					module:displayTooltip(frame, {L["CT_BuffMod/Options/Window/Grouping/GroupByPriorityLabel"], L["CT_BuffMod/Options/Window/Grouping/GroupByPriorityTip"] .. "#" .. textColor2}, "CT_ABOVEBELOW", 0, 0, CTCONTROLPANEL);
				end
			end);
		optionsEndFrame();
		
		-- Buffs you cast
		optionsAddObject(-10,   14, "font#tl:35:%y#v:ChatFontNormal#" .. L["CT_BuffMod/Options/Window/Grouping/PlayerBuffsLabel"]);
		-- Bug: Omit 3rd menu item while waiting for Blizzard to fix the "Sort with others" bug
		--
		--      Note: As of WoW 4.3 they have fixed the bug related to this attribute.
		--	      I've added the third option and made SEPARATE_OWN_WITH the default instead of SEPARATE_OWN_BEFORE.
		--
		optionsAddObject( 15,   20, "dropdown#tl:140:%y#s:130:%s#n:CT_BuffModDropdown_separateOwn#i:separateOwn#o:separateOwn:" .. constants.SEPARATE_OWN_WITH .. L["CT_BuffMod/Options/Window/Grouping/PlayerBuffsDropdown"]);

		-- Sort zero duration buffs
		optionsBeginFrame( 0,    0, "frame#tl:0:%y#br:tr:0:%b#i:separateZero");
			optionsAddObject(-10,   14, "font#tl:35:%y#v:ChatFontNormal#i:label#" .. L["CT_BuffMod/Options/Window/Grouping/NonExpiringBuffsLabel"]);
			optionsAddObject( 15,   20, "dropdown#tl:140:%y#s:130:%s#n:CT_BuffModDropdown_separateZero#i:dropdown#o:separateZero:" .. constants.SEPARATE_ZERO_WITH .. L["CT_BuffMod/Options/Window/Grouping/NonExpiringBuffsDropdown"]);
			optionsAddScript("onleave", function(frame)
				frame:GetParent().playerUnsecure.text:SetTextColor(1,1,1);
			end);
			optionsAddScript("onenter", function(frame)
				if (frame.label:GetAlpha() < 1) then
					module:displayTooltip(frame, {L["CT_BuffMod/Options/Window/Grouping/NonExpiringBuffsLabel"], L["CT_BuffMod/Options/Window/Grouping/MethodUnavailableTip"] .. "#" .. textColor2}, "CT_ABOVEBELOW", 0, 0, CTCONTROLPANEL);
					frame:GetParent().playerUnsecure.text:SetTextColor(1, 1, 0);
				end
			end);
		optionsEndFrame();

		-- Group by
		do
			local menu = L["CT_BuffMod/Options/Window/Grouping/OrderDropdown"]; -- "#None#Debuffs#Cancelable buffs#Uncancelable buffs#All buffs#Weapons" -- the 7th option was previously #Consolidated, but that does nothing any more

			optionsAddObject(-10,   14, "font#tl:35:%y#v:ChatFontNormal#" .. L["CT_BuffMod/Options/Window/Grouping/OrderLabel"]);

			optionsAddObject(-10,   14, "font#tl:66:%y#v:ChatFontNormal#" .. L["CT_BuffMod/Options/Window/Grouping/Order1Label"]);
			optionsAddObject( 15,   20, "dropdown#tl:110:%y#s:140:%s#n:CT_BuffModDropdown_sortSeq1#i:sortSeq1#o:sortSeq1:" .. constants.FILTER_TYPE_DEBUFF .. menu);

			optionsAddObject(-10,   14, "font#tl:66:%y#v:ChatFontNormal#" .. L["CT_BuffMod/Options/Window/Grouping/Order2Label"]);
			optionsAddObject( 15,   20, "dropdown#tl:110:%y#s:140:%s#n:CT_BuffModDropdown_sortSeq2#i:sortSeq2#o:sortSeq2:" .. constants.FILTER_TYPE_WEAPON .. menu);

			optionsAddObject(-10,   14, "font#tl:66:%y#v:ChatFontNormal#" .. L["CT_BuffMod/Options/Window/Grouping/Order3Label"]);
			optionsAddObject( 15,   20, "dropdown#tl:110:%y#s:140:%s#n:CT_BuffModDropdown_sortSeq3#i:sortSeq3#o:sortSeq3:" .. constants.FILTER_TYPE_BUFF_CANCELABLE .. menu);

			optionsAddObject(-10,   14, "font#tl:66:%y#v:ChatFontNormal#" .. L["CT_BuffMod/Options/Window/Grouping/Order4Label"]);
			optionsAddObject( 15,   20, "dropdown#tl:110:%y#s:140:%s#n:CT_BuffModDropdown_sortSeq4#i:sortSeq4#o:sortSeq4:" .. constants.FILTER_TYPE_BUFF_UNCANCELABLE .. menu);

			optionsAddObject(-10,   14, "font#tl:66:%y#v:ChatFontNormal#" .. L["CT_BuffMod/Options/Window/Grouping/Order5Label"]);
			optionsAddObject( 15,   20, "dropdown#tl:110:%y#s:140:%s#n:CT_BuffModDropdown_sortSeq5#i:sortSeq5#o:sortSeq5:" .. constants.FILTER_TYPE_NONE .. menu);
		end
		
		----------
		-- Sorting (subordinate to grouping)
		----------

		optionsAddObject(-20, 1*13, "font#tl:15:%y#" .. L["CT_BuffMod/Options/Window/Sorting/Heading"]);

		-- Sort method
		optionsAddObject(-10,   14, "font#tl:35:%y#v:ChatFontNormal#" .. L["CT_BuffMod/Options/Window/Sorting/SortMethodLabel"]);
		optionsAddObject( 15,   20, "dropdown#tl:140:%y#s:100:%s#n:CT_BuffModDropdown_sortMethod#i:sortMethod#o:sortMethod:" .. constants.SORT_METHOD_NAME .. L["CT_BuffMod/Options/Window/Sorting/SortMethodDropdown"]);

		-- Sort direction
		optionsAddObject(  0,   26, "checkbutton#tl:33:%y#i:sortDirection#o:sortDirection#" .. L["CT_BuffMod/Options/Window/Sorting/ReverseCheckbox"]);
		
		----------
		-- Visibility
		----------
		optionsAddObject(-20, 1*13, "font#tl:15:%y#" .. L["CT_BuffMod/Options/Window/Visibility/Heading"]);

		-- Always show window
		optionsAddObject( -5,   20, "checkbutton#tl:25:%y#s:%s:%s#i:visShow#o:visShow#" .. L["CT_BuffMod/Options/Window/Visibility/AlwaysRadio"]);

		-- Basic conditions
		optionsAddObject( -2,   20, "checkbutton#tl:25:%y#s:%s:%s#i:visBasic#o:visBasic#" .. L["CT_BuffMod/Options/Window/Visibility/BasicRadio"]);
		
		local function toggleBasicConditions(checkbutton)
			checkbutton:HookScript("OnClick",
				function()
					if (
						visHideInVehicle:GetChecked() 
						or visHideNotVehicle:GetChecked()
						or visHideInCombat:GetChecked() 
						or visHideNotCombat:GetChecked()
					) then
						visBasic:Click();
					else
						visShow:Click();
					end
				end
			);
		end
		
		optionsBeginFrame( -2,   26, "checkbutton#tl:44:%y#i:visHideInVehicle#o:visHideInVehicle#" .. L["CT_BuffMod/Options/Window/Visibility/HideVehicleCheckbox"]);
			optionsAddScript("onload", toggleBasicConditions);
		optionsEndFrame();
		optionsBeginFrame(  6,   26, "checkbutton#tl:44:%y#i:visHideNotVehicle#o:visHideNotVehicle#" .. L["CT_BuffMod/Options/Window/Visibility/HideNotVehicleCheckbox"]);
			optionsAddScript("onload", toggleBasicConditions);
		optionsEndFrame();
		optionsBeginFrame(  6,   26, "checkbutton#tl:44:%y#i:visHideInCombat#o:visHideInCombat#" .. L["CT_BuffMod/Options/Window/Visibility/HideCombatCheckbox"]);
			optionsAddScript("onload", toggleBasicConditions);
		optionsEndFrame();
		optionsBeginFrame(  6,   26, "checkbutton#tl:44:%y#i:visHideNotCombat#o:visHideNotCombat#" .. L["CT_BuffMod/Options/Window/Visibility/HideNotCombatCheckbox"]);
			optionsAddScript("onload", toggleBasicConditions);
		optionsEndFrame();
		
		-- Advanced conditions
		optionsAddObject( -2,   20, "checkbutton#tl:25:%y#s:%s:%s#i:visAdvanced#o:visAdvanced#" .. L["CT_BuffMod/Options/Window/Visibility/AdvancedRadio"]);

		optionsBeginFrame(  20,   20, "button#tl:222:%y#s:20:%s#i:visHelp0#v:UIPanelButtonTemplate#?");
			optionsAddScript("onenter",
				function(self)
					local windowObject = globalObject.windowListObject:findWindow(currentWindowId);
					local primaryObject = windowObject.primaryObject;

					GameTooltip:SetOwner(self, "ANCHOR_RIGHT", 35);
					GameTooltip:SetText("Visibility conditions");
					GameTooltip:AddLine("Standard macro conditions are used to control the visibility of the selected window.", 1, 1, 1, true);
					GameTooltip:AddLine("\nThe valid actions that you can use with visibility conditions are:", 1, 1, 1, true);
					GameTooltip:AddLine("hide, show", 0.45, 0.75, 0.95, true);
					GameTooltip:AddLine("\nThe 'hide' action will hide the window, and the 'show' action will show the window.", 1, 1, 1, true);
					GameTooltip:AddLine("\nHere's an example that hides the window when you are in a vehicle or combat, otherwise it shows the window:", 1, 1, 1, true);
					GameTooltip:AddLine("[vehicleui]hide\n[combat]hide\nshow", 0.45, 0.75, 0.95, true);
					if (primaryObject) then
						GameTooltip:AddLine("\nThese are the current basic visibility conditions for this window:", 1, 0.82, 0, true);
						GameTooltip:AddLine(primaryObject:buildBasicCondition(), 0.45, 0.75, 0.95, true);
						GameTooltip:AddLine("\nShift click this ? button to paste the current basic visibility conditions into the edit window.", 1, 0.82, 0, true);
					end
					GameTooltip:Show();
				end
			);
			optionsAddScript("onleave",
				function(self)
					GameTooltip:Hide();
				end
			);
			optionsAddScript("onclick",
				function(self)
					if (IsShiftKeyDown()) then
						local windowObject = globalObject.windowListObject:findWindow(currentWindowId);
						local primaryObject = windowObject.primaryObject;
						if (primaryObject) then
							local editBox = self:GetParent().conditionEB;
							editBox:HighlightText(0, 0);
							editBox:ClearFocus();
							editBox:SetText( primaryObject:buildBasicCondition() );
						end
					end
				end
			);
		optionsEndFrame();

		optionsBeginFrame(  20,   20, "button#tl:250:%y#s:20:%s#i:visHelp1#v:UIPanelButtonTemplate#?");
			optionsAddScript("onenter",
				function(self)
					GameTooltip:SetOwner(self, "ANCHOR_RIGHT", 35);
					GameTooltip:SetText("Condition format");
					GameTooltip:AddLine("Each line should contain zero or more macro conditions followed by an action. If you don't specify a condition it defaults to true.", 1, 1, 1, true);
					GameTooltip:AddLine("\nAll conditions must be enclosed in [square brackets]. Within the brackets you can separate multiple conditions using commas (each comma acts like an 'and').", 1, 1, 1, true);
					GameTooltip:AddLine("\nMultiple [conditions] can be placed next to each other. This acts like an 'or' between each pair of brackets.", 1, 1, 1, true);
					GameTooltip:AddLine("\nA semicolon ';' must be used to separate an action from a following [condition] on the same line. You can omit the semicolon if you press enter after the action instead.", 1, 1, 1, true);
					GameTooltip:AddLine("\nIt is ok for a long line to automatically wrap onto the next line. Don't press enter unless you do so after an action.", 1, 1, 1, true);
					GameTooltip:AddLine("\nThe game will perform the action that is associated with the first set of true conditions.", 1, 1, 1, true);
					GameTooltip:AddLine("\nFor information on macro conditions, refer to sections 12 through 14 at: www.wowpedia.org/Making_a_macro", 1, 1, 1, true);
					GameTooltip:Show();
				end
			);
			optionsAddScript("onleave",
				function(self)
					GameTooltip:Hide();
				end
			);
		optionsEndFrame();

		optionsBeginFrame(  21,   20, "button#tl:278:%y#s:20:%s#i:visHelp2#v:UIPanelButtonTemplate#?");
			optionsAddScript("onenter",
				function(self)
					GameTooltip:SetOwner(self, "ANCHOR_RIGHT", 7);
					GameTooltip:SetText("Macro conditions");
					GameTooltip:AddLine("A '/' is used with specific conditions to separate multiple values to test for. The '/' acts like an 'or'.", 1, 1, 1, true);
					GameTooltip:AddLine("\nThe letters 'no' can be placed at the start of most condition names to alter the meaning of the condition.", 1, 1, 1, true);
					GameTooltip:AddLine("\n@<unit or name>\nactionbar:1/.../6\nbar:1/.../6\nbonusbar:1/.../4\nchanneling:<spell name>\ncombat\ndead\nequipped:<slot or type or subtype>\nexists\nextrabar\nflyable\nflying\ngroup:party/raid\nform:0/.../n\nharm\nhelp\nindoors\nmod:shift/ctrl/alt\nmodifier:shift/ctrl/alt\nmounted\noverridebar\noutdoors\nparty\npet\npet:<name or type>\npetbattle\npossessbar\nraid\nspec:1/2\nstance:0/1/2/.../n\nstealth\nswimming\ntarget=<unit or name>\nunithasvehicleui\nvehicleui\nworn:<slot or type or subtype>", 1, 1, 1, false);
					GameTooltip:Show();
				end
			);
			optionsAddScript("onleave",
				function(self)
					GameTooltip:Hide();
				end
			);
		optionsEndFrame();

		optionsBeginFrame(   0,  120, "frame#tl:40:%y#br:tr:0:%b");
			optionsAddScript("onload",
				function(self)
					local width = 260;
					local height = 120;
					local frame = module:createMultiLineEditBox("CT_BuffMod_AdvancedEdit", width, height, self, 1);
					frame:Show();
					do
						local function update(self)
							self:HighlightText(0, 0);
							self:ClearFocus();
						end
						frame.editBox:SetScript("OnEscapePressed", update);
						frame.editBox:SetScript("OnTabPressed", update);
						frame.editBox:SetScript("OnEditFocusLost", update);
					end
					frame.editBox:HookScript("OnTextChanged",
						function(self)
							local windowObject = globalObject.windowListObject:findWindow(currentWindowId);
							local primaryObject = windowObject.primaryObject;
							if (primaryObject) then
								local frameOptions = primaryObject:getOptions();
								if ( self:GetText() ~= (frameOptions.visCondition or "") ) then
									windowOptionsFrame.visSave:Enable();
									windowOptionsFrame.visUndo:Enable();
								end
							end
						end
					);
					self:GetParent().conditionEB = frame.editBox;
				end
			);
		optionsEndFrame();

		optionsBeginFrame(  -2,   22, "button#tl:60:%y#s:60:%s#i:visTest#v:UIPanelButtonTemplate#" .. L["CT_BuffMod/Options/Window/Visibility/TestButton"]);
			optionsAddScript("onclick",
				function(self)
					local editBox = windowOptionsFrame.conditionEB;
					local cond = buildCondition( editBox:GetText() );
					local action, target = SecureCmdOptionParse(cond);
					print("Tested: ", cond);
					if (target) then
						print("Target used: ", target);
					end
					if (action == "show") then
						print("Valid Result: |cFF66FF66show");
					elseif (action == "hide") then
						print("Valid Result: |cFFFFFF00hide");
					elseif (action == "" or not action) then
						print("Invalid Result: |cFFFF3333[nil!]");
					else
						print("Invalid Result: |cFFFF3333" .. action);
					end
				end
			);
			optionsAddScript("onenter",
				function(self)
					GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
					GameTooltip:SetText("Test conditions");
					GameTooltip:AddLine("This tests the conditions in the edit box in order to display the current action that will be performed when the conditions are saved.\n\nThis button does not have any effect on the window.", 1, 1, 1, true);
					GameTooltip:Show();
				end
			);
			optionsAddScript("onleave",
				function(self)
					GameTooltip:Hide();
				end
			);
		optionsEndFrame();

		optionsBeginFrame(  23,   22, "button#tl:140:%y#s:60:%s#i:visSave#v:UIPanelButtonTemplate#" .. L["CT_BuffMod/Options/Window/Visibility/SaveButton"]);
			optionsAddScript("onload",
				function(self)
					self:Disable();
				end
			);
			optionsAddScript("onclick",
				function(self)
					local editBox = windowOptionsFrame.conditionEB;
					editBox:HighlightText(0, 0);
					editBox:ClearFocus();
					local cond = editBox:GetText();
					module:setOption("visCondition", cond);
					self:Disable();
					editBox.ctUndo = cond;
					windowOptionsFrame.visUndo:Disable();
					if (IsShiftKeyDown()) then
						print(buildCondition(cond));
					end
					if editBox:GetText() ~= "" then
						visAdvanced:Click();
					else
						visShow:Click();
					end
				end
			);
			optionsAddScript("onenter",
				function(self)
					GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
					GameTooltip:SetText("Save changes");
					GameTooltip:AddLine("This saves the changes you've made to the conditions. The window will not be affected by the modified conditions until you save the changes.", 1, 1, 1, true);
					GameTooltip:Show();
				end
			);
			optionsAddScript("onleave",
				function(self)
					GameTooltip:Hide();
				end
			);
		optionsEndFrame();

		optionsBeginFrame(  23,   22, "button#tl:220:%y#s:60:%s#i:visUndo#v:UIPanelButtonTemplate#" .. L["CT_BuffMod/Options/Window/Visibility/UndoButton"]);
			optionsAddScript("onload",
				function(self)
					self:Disable();
				end
			);
			optionsAddScript("onclick",
				function(self)
					local editBox = windowOptionsFrame.conditionEB;
					editBox:HighlightText(0, 0);
					editBox:ClearFocus();
					if (editBox.ctUndo) then
						editBox:SetText(editBox.ctUndo);
						self:Disable();
						windowOptionsFrame.visSave:Disable();
					end
				end
			);
			optionsAddScript("onenter",
				function(self)
					GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
					GameTooltip:SetText("Undo changes");
					GameTooltip:AddLine("This will undo the changes you've made to the conditions.", 1, 1, 1, true);
					GameTooltip:Show();
				end
			);
			optionsAddScript("onleave",
				function(self)
					GameTooltip:Hide();
				end
			);
		optionsEndFrame();


		----------
		-- Consolidation
		----------
--[[ CONSOLIDATION REMOVED FROM GAME
		optionsAddObject(-20, 1*13, "font#tl:15:%y#Consolidation");

		optionsBeginFrame(  15,   20, "button#tl:250:%y#s:40:%s#i:consHelp#v:UIPanelButtonTemplate#?");
			optionsAddScript("onenter",
				function(self)
					GameTooltip:SetOwner(self, "ANCHOR_RIGHT", 35, 0);
					GameTooltip:SetText("Consolidation");
					GameTooltip:AddLine("Blizzard determines which buffs are placed in the Consolidated window, but you can use the following options to influence the decision. Note that some buffs are never eligible to be consolidated.", 1, 1, 1, true);
					GameTooltip:AddLine("\nThe game will place an eligible buff in the consolidated window if:", 1, 1, 1, true);
					GameTooltip:AddLine("\n(1) its total duration is greater than the minimum total duration,", 1, 1, 1, true);
					GameTooltip:AddLine("\nOR", 1, 1, 1, true);
					GameTooltip:AddLine("\n(2) the time remaining is greater than the larger of the following two values: (a) the time remaining threshold, (b) a percentage of the total duration.", 1, 1, 1, true);
					GameTooltip:Show();
				end
			);
			optionsAddScript("onleave",
				function(self)
					GameTooltip:Hide();
				end
			);
		optionsEndFrame();

		optionsAddObject(-10,   14, "font#tl:30:%y#v:ChatFontNormal#Minimum total duration (default 30):");
		optionsAddObject(-20,   17, "slider#tl:50:%y#s:110:%s#i:consolidateDurationMinutes#o:consolidateDurationMinutes:0#Minutes = <value>#0:60:1");
		optionsAddObject( 17,   17, "slider#tl:180:%y#s:110:%s#i:consolidateDurationSeconds#o:consolidateDurationSeconds:30#Seconds = <value>#0:59:1");

		optionsAddObject(-25,   14, "font#tl:30:%y#v:ChatFontNormal#Time remaining threshold (default 10):");
		optionsAddObject(-20,   17, "slider#tl:50:%y#s:110:%s#i:consolidateThresholdMinutes#o:consolidateThresholdMinutes:0#Minutes = <value>#0:60:1");
		optionsAddObject( 17,   17, "slider#tl:180:%y#s:110:%s#i:consolidateThresholdSeconds#o:consolidateThresholdSeconds:10#Seconds = <value>#0:59:1");

		optionsAddObject(-25,   14, "font#tl:30:%y#v:ChatFontNormal#Total duration percentage (default 10):");
		optionsAddObject(-20,   17, "slider#tl:50:%y#s:240:%s#i:consolidateFractionPercent#o:consolidateFractionPercent:10#<value> %#0:100:0.1");
CONSOLIDATION REMOVED FROM GAME--]]

		----------
		-- Background
		----------
		optionsAddObject(-25, 1*13, "font#tl:15:%y#" .. L["CT_BuffMod/Options/Window/Background/Heading"]);

		-- Backdrop
		optionsAddObject(-10,   26, "checkbutton#tl:30:%y#i:showBackground#o:showBackground:true#" .. L["CT_BuffMod/Options/Window/Background/ShowBackgroundCheckbox"]);
		optionsAddObject(  6,   26, "checkbutton#tl:30:%y#i:useCustomBackgroundColor#o:useCustomBackgroundColor#" .. L["CT_BuffMod/Options/Window/Background/CustomColorCheckbox"]);
		optionsAddObject( -2,   16, "colorswatch#tl:65:%y#s:16:16#i:windowBackgroundColor#o:windowBackgroundColor:" .. defaultWindowColor[1] .. "," .. defaultWindowColor[2] .. "," .. defaultWindowColor[3] .. "," .. defaultWindowColor[4] .. "#true");
		optionsAddObject( 14,   15, "font#tl:90:%y#v:ChatFontNormal#" .. L["CT_BuffMod/Options/Window/Background/CustomColorLabel"]);

		----------
		-- Border
		----------
		optionsAddObject(-15, 1*13, "font#tl:15:%y#" .. L["CT_BuffMod/Options/Window/Border/Heading"]);

		optionsAddObject(-10,   26, "checkbutton#tl:35:%y#i:showBorder#o:showBorder#" .. L["CT_BuffMod/Options/Window/Border/ShowBorderCheckbox"]);
		optionsAddObject(-15,   17, "slider#tl:40:%y#s:250:%s#i:userEdgeLeft#o:userEdgeLeft:0#" .. L["CT_BuffMod/Options/Window/Border/LeftSliderValue"] .. "#0:100:1");
		optionsAddObject(-20,   17, "slider#tl:40:%y#s:250:%s#i:userEdgeRight#o:userEdgeRight:0#" .. L["CT_BuffMod/Options/Window/Border/RightSliderValue"] .. "#0:100:1");
		optionsAddObject(-20,   17, "slider#tl:40:%y#s:250:%s#i:userEdgeTop#o:userEdgeTop:0#" .. L["CT_BuffMod/Options/Window/Border/TopSliderValue"] .. "#0:100:1");
		optionsAddObject(-20,   17, "slider#tl:40:%y#s:250:%s#i:userEdgeBottom#o:userEdgeBottom:0#" .. L["CT_BuffMod/Options/Window/Border/BottomSliderValue"] .. "#0:100:1");

		----------
		-- Layout
		----------

		optionsAddObject(-25, 1*13, "font#tl:15:%y#" .. L["CT_BuffMod/Options/Window/Layout/Heading"]);

		optionsBeginFrame(  15,   20, "button#tl:250:%y#s:40:%s#i:layoutHelp1#v:UIPanelButtonTemplate#?");
			optionsAddScript("onenter",
				function(self)
					GameTooltip:SetOwner(self, "ANCHOR_RIGHT", 35, 0);
					GameTooltip:SetText(L["CT_BuffMod/Options/Window/Layout/Heading"]);
					GameTooltip:AddLine(L["CT_BuffMod/Options/Window/Layout/Tooltip"]);
					GameTooltip:Show();
				end
			);
			optionsAddScript("onleave",
				function(self)
					GameTooltip:Hide();
				end
			);
		optionsEndFrame();

		-- Layout type
		do
			optionsAddObject(-20,   14, "font#tl:35:%y#v:ChatFontNormal#" .. L["CT_BuffMod/Options/Window/Layout/LayoutDropdownLabel"]);
			optionsAddObject( 15,   20, "dropdown#tl:80:%y#s:180:%s#n:CT_BuffModDropdown_layoutType#i:layoutType#o:layoutType:" .. constants.DEFAULT_LAYOUT .. L["CT_BuffMod/Options/Window/Layout/LayoutDropdown"]);
		end

		optionsAddObject( -5, 4*14, "font#tl:35:%y#s:0:%s#i:layoutTypeText#l:13:0#r#place holder text#" .. textColor2 .. ":l");

		-- Buffs per wrap
		optionsAddObject(-25,   17, "slider#tl:40:%y#s:250:%s#i:wrapAfter#o:wrapAfter:" .. constants.DEFAULT_WRAP_AFTER .. "#<value>#1:50:1");

		-- Number of wraps
		optionsAddObject(-25,   17, "slider#tl:40:%y#s:250:%s#i:maxWraps#o:maxWraps:" .. constants.DEFAULT_MAX_WRAPS .. "#<value>:" .. L["CT_BuffMod/Options/Window/Layout/MaxWrapsSliderAuto"] .. ":50#0:50:1");

		-- Buff spacing
		optionsAddObject(-25,   17, "slider#tl:40:%y#s:250:%s#i:buffSpacing#o:buffSpacing:0#".. L["CT_BuffMod/Options/Window/Layout/BuffSpacingSlider"] .. "#0:200:1");

		-- Wrap spacing
		optionsAddObject(-25,   17, "slider#tl:40:%y#s:250:%s#i:wrapSpacing#o:wrapSpacing:0#<value>#0:200:1");

		----------
		-- Font size
		----------
		
		optionsAddObject(-25, 1*13, "font#tl:15:%y#" .. L["CT_BuffMod/Options/Window/Fonts/Heading"]);
		optionsAddObject(-20,   14, "font#tl:28:%y#v:ChatFontNormal#" .. L["CT_BuffMod/Options/Window/Fonts/FontSizeLabel"]);
		optionsAddObject( 15,   20, "dropdown#tl:80:%y#s:170:%s#n:CT_BuffModDropdown_fontSize#i:fontSize#o:fontSize:1" .. L["CT_BuffMod/Options/Window/Fonts/FontSizeDropDown"]);

		----------
		-- Button appearance
		----------
		optionsAddObject(-25, 1*13, "font#tl:15:%y#Button appearance");

		local Style1Objects = { }

		-- Button style
		optionsAddObject(-20,   14, "font#tl:28:%y#v:ChatFontNormal#Use style:");
		optionsBeginFrame( 15,   20, "dropdown#tl:80:%y#s:170:%s#n:CT_BuffModDropdown_buttonStyle#i:buttonStyle#o:buttonStyle:1#" .. L["CT_BuffMod/Options/Window/Button/Style1/Heading"] .. "#" .. L["CT_BuffMod/Options/Window/Button/Style2/Heading"]);
			optionsAddScript("onshow", function(self)
				self.ticker = self.ticker or C_Timer.NewTicker(0.5, function()
					if (UIDropDownMenu_GetSelectedID(self) == 1) then
						self.parent.style1Collapsible:Expand()
						self.parent.style2Collapsible:Collapse()
					else
						self.parent.style1Collapsible:Collapse()
						self.parent.style2Collapsible:Expand()
					end
				end)
			end)
			optionsAddScript("onhide", function(self)
				if (self.ticker) then
					self.ticker:Cancel()
					self.ticker = nil
				end
			end)
		optionsEndFrame()
		
		-- Style 1
		optionsBeginFrame( 0,    0, "collapsible#tl:0:%y#br:tr:0:%b#i:style1Collapsible")

			optionsAddObject(-20, 1*13, "font#tl:22:%y#n:CT_BuffMod_Style1Label#" .. L["CT_BuffMod/Options/Window/Button/Style1/Heading"]);


			-- Size of the icon
			optionsAddObject(-20,   14, "font#tl:35:%y#v:ChatFontNormal#n:CT_BuffMod_Style1SizeLabel#" .. L["CT_BuffMod/Options/Window/Button/General/IconSizeSliderLabel"]);
			optionsAddObject( 15,   17, "slider#tl:165:%y#s:120:%s#i:buffSize1#o:buffSize1:" .. constants.BUFF_SIZE_DEFAULT .. "#<value>#" .. constants.BUFF_SIZE_MINIMUM ..":" .. constants.BUFF_SIZE_MAXIMUM .. ":1");

			-- Icon position
			optionsAddObject(-20,   15, "font#tl:35:%y#n:CT_BuffMod_Style1PositionLabel#v:ChatFontNormal#" .. L["CT_BuffMod/Options/Window/Button/Style1/IconPositionLabel"]);
			optionsAddObject( 15,   20, "dropdown#tl:140:%y#s:120:%s#n:CT_BuffModDropdown_rightAlign1#i:rightAlign1#o:rightAlign1:" .. constants.RIGHT_ALIGN_DEFAULT .. L["CT_BuffMod/Options/Window/Button/Style1/IconPositionDropdown"]);

			-- Icon Borders, including debuff colour codes
			optionsBeginFrame( -5,   26, "checkbutton#tl:30:%y#i:colorCodeIcons1#o:colorCodeIcons1#" .. L["CT_BuffMod/Options/Window/Button/General/DebuffBorderColorCheckbox"]);
				optionsAddScript("onenter",
					function(button)
						module:displayTooltip(button, {L["CT_BuffMod/Options/Window/Button/General/DebuffBorderColorCheckbox"],L["CT_BuffMod/Options/Window/Button/General/DebuffColorTooltip"]}, "ANCHOR_TOPLEFT");
					end
				);
			optionsEndFrame();
			optionsBeginFrame( -5,   26, "checkbutton#tl:30:%y#i:normalIconBorder1#o:normalIconBorder1#" .. L["CT_BuffMod/Options/Window/Button/General/NormalIconBorderCheckbox"]);
				optionsAddScript("onenter",
					function(button)
						module:displayTooltip(button, {L["CT_BuffMod/Options/Window/Button/General/NormalIconBorderCheckbox"],L["CT_BuffMod/Options/Window/Button/General/NormalIconBorderTip"]}, "ANCHOR_TOPLEFT");
					end
				);
			optionsEndFrame();

			-- Detail frame width
			optionsAddObject(-20,   17, "slider#tl:40:%y#s:250:%s#i:detailWidth1#o:detailWidth1:" .. constants.DEFAULT_DETAIL_WIDTH .. "#Bar width = <value>#0:400:1");

			-- Color the background of the bar
			-- 	Color code debuff backgrounds
			optionsAddObject(-15,   26, "checkbutton#tl:30:%y#i:colorBuffs1#o:colorBuffs1:true#" .. L["CT_BuffMod/Options/Window/Button/Style1/BarBackgroundCheckbox"]);
			optionsBeginFrame(  6,   26, "checkbutton#tl:44:%y#i:colorCodeBackground1#o:colorCodeBackground1#" .. L["CT_BuffMod/Options/Window/Button/Style1/DebuffBarBackgroundCheckbox"]);
				optionsAddScript("onenter",
					function(button)
						module:displayTooltip(button, {L["CT_BuffMod/Options/Window/Button/Style1/DebuffBarBackgroundCheckbox"],L["CT_BuffMod/Options/Window/Button/General/DebuffColorTooltip"]}, "ANCHOR_TOPLEFT");
					end
				);
			optionsEndFrame();


			-- Show name
			--	Color code debuff names
			--	Justify (beside time)
			-- 	Justify (when alone)
			optionsAddObject( -5,   26, "checkbutton#tl:30:%y#i:showNames1#o:showNames1:true#" .. L["CT_BuffMod/Options/Window/Button/Style1/ShowNameCheckbox"]);
			optionsBeginFrame(  6,   26, "checkbutton#tl:44:%y#i:colorCodeDebuffs1#o:colorCodeDebuffs1#" .. L["CT_BuffMod/Options/Window/Button/Style1/DebuffNameCheckbox"]);
				optionsAddScript("onenter",
					function(button)
						module:displayTooltip(button, {L["CT_BuffMod/Options/Window/Button/Style1/DebuffNameCheckbox"],L["CT_BuffMod/Options/Window/Button/General/DebuffColorTooltip"]}, "ANCHOR_TOPLEFT");
					end
				);
			optionsEndFrame();
			optionsAddObject( -3,   15, "font#tl:48:%y#v:ChatFontNormal#n:CT_BuffMod_Style1JustifyLabel1#" .. L["CT_BuffMod/Options/Window/Button/Style1/JustifyNotAloneLabel"]);
			optionsAddObject( 15,   20, "dropdown#tl:180:%y#s:80:%s#n:CT_BuffModDropdown_nameJustifyWithTime1#i:nameJustifyWithTime1#o:nameJustifyWithTime1:" .. constants.JUSTIFY_DEFAULT .. L["CT_BuffMod/Options/Window/Button/Style1/JustifyDropdown"]);

			optionsAddObject( -5,   15, "font#tl:48:%y#v:ChatFontNormal#n:CT_BuffMod_Style1JustifyLabel2#" .. L["CT_BuffMod/Options/Window/Button/Style1/JustifyAloneLabel"]);
			optionsAddObject( 15,   20, "dropdown#tl:180:%y#s:80:%s#n:CT_BuffModDropdown_nameJustifyNoTime1#i:nameJustifyNoTime1#o:nameJustifyNoTime1:" .. constants.JUSTIFY_DEFAULT .. L["CT_BuffMod/Options/Window/Button/Style1/JustifyDropdown"]);

			-- Show time remaining text
			--	Format
			--	Location
			--	Justify (when alone)
			optionsAddObject( -5,   26, "checkbutton#tl:30:%y#i:showTimers1#o:showTimers1:true#" .. L["CT_BuffMod/Options/Window/Button/General/TimeRemainingCheckbox"]);

			optionsAddObject( -3,   15, "font#tl:48:%y#v:ChatFontNormal#n:CT_BuffMod_Style1FormatLabel#Format:");
			optionsAddObject( 15,   20, "dropdown#tl:115:%y#s:145:%s#n:CT_BuffModDropdown_durationFormat1#i:durationFormat1#o:durationFormat1:1#" .. L["CT_BuffMod/Options/Window/Time Remaining/Duration Format Dropdown"]);

			optionsAddObject(  6,   26, "checkbutton#tl:44:%y#n:CT_BuffMod_showDaysFormat1#o:showDays1:true#" .. L["CT_BuffMod/Options/Window/Button/General/ShowDaysCheckbox"]);

			optionsAddObject( -5,   15, "font#tl:48:%y#v:ChatFontNormal#n:CT_BuffMod_Style1LocationLabel#" .. L["CT_BuffMod/Options/Window/Button/General/TimeLocationLabel"]);
			optionsAddObject( 15,   20, "dropdown#tl:115:%y#s:145:%s#n:CT_BuffModDropdown_durationLocation1#i:durationLocation1#o:durationLocation1:" .. constants.DURATION_LOCATION_DEFAULT .. "#Default#Left of the name#Right of the name#Above the name#Below the name");

			optionsAddObject( -5,   15, "font#tl:48:%y#v:ChatFontNormal#n:CT_BuffMod_Style1JustifyLabel3#" .. L["CT_BuffMod/Options/Window/Button/Style1/JustifyAloneLabel"]);
			optionsAddObject( 15,   20, "dropdown#tl:180:%y#s:80:%s#n:CT_BuffModDropdown_timeJustifyNoName1#i:timeJustifyNoName1#o:timeJustifyNoName1:" .. constants.JUSTIFY_DEFAULT .. L["CT_BuffMod/Options/Window/Button/Style1/JustifyDropdown"]);

			-- Show time remaining bar
			-- 	Show the bar's background
			optionsAddObject( -5,   26, "checkbutton#tl:30:%y#i:showBuffTimer1#o:showBuffTimer1:true#" .. L["CT_BuffMod/Options/Window/Button/Style1/TimeRemainingBarCheckbox"]);
			optionsAddObject(  6,   26, "checkbutton#tl:44:%y#i:showTimerBackground1#o:showTimerBackground1:true#" .. L["CT_BuffMod/Options/Window/Button/Style1/TimeRemainingBarBackgroundCheckbox"]);

			-- Spacing between left side of detail frame and text
			optionsAddObject(-15,   14, "font#tl:48:%y#v:ChatFontNormal#n:CT_BuffMod_Style1OffsetLabel1#" .. L["CT_BuffMod/Options/Window/Button/Style1/LeftOffsetLabel"]);
			optionsAddObject( 15,   17, "slider#tl:190:%y#s:100:%s#i:spacingOnLeft1#o:spacingOnLeft1:0#<value>#0:50:1");

			-- Spacing between right side of detail frame and text
			optionsAddObject(-20,   14, "font#tl:48:%y#v:ChatFontNormal#n:CT_BuffMod_Style1OffsetLabel2#" .. L["CT_BuffMod/Options/Window/Button/Style1/RightOffsetLabel"]);
			optionsAddObject( 15,   17, "slider#tl:190:%y#s:100:%s#i:spacingOnRight1#o:spacingOnRight1:0#<value>#0:50:1");
		
			optionsAddScript("onload", function(self)
				self.collapsiblePassthrough = true;
			end)
		optionsEndFrame()

		-- Style 2
		
		optionsBeginFrame( -10,    0, "collapsible#tl:0:%y#br:tr:0:%b#i:style2Collapsible")
		
			optionsAddObject(-20, 1*13, "font#tl:22:%y#n:CT_BuffMod_Style2Label#" .. L["CT_BuffMod/Options/Window/Button/Style2/Heading"]);

			-- Icon size
			optionsAddObject(-20,   14, "font#tl:35:%y#n:CT_BuffMod_Style2SizeLabel#v:ChatFontNormal#" .. L["CT_BuffMod/Options/Window/Button/General/IconSizeSliderLabel"]);
			optionsAddObject( 15,   17, "slider#tl:165:%y#s:120:%s#i:buffSize2#o:buffSize2:" .. constants.BUFF_SIZE_DEFAULT .. "#<value>#" .. constants.BUFF_SIZE_MINIMUM ..":" .. constants.BUFF_SIZE_MAXIMUM .. ":1");

			-- Icon Borders, including debuff colour codes
			optionsBeginFrame(-15,   26, "checkbutton#tl:30:%y#i:colorCodeIcons2#o:colorCodeIcons2#" .. L["CT_BuffMod/Options/Window/Button/General/DebuffBorderColorCheckbox"]);
				optionsAddScript("onenter",
					function(button)
						module:displayTooltip(button, {L["CT_BuffMod/Options/Window/Button/General/DebuffBorderColorCheckbox"],L["CT_BuffMod/Options/Window/Button/General/DebuffColorTooltip"]}, "ANCHOR_TOPLEFT");
					end
				);
			optionsEndFrame();
			optionsBeginFrame( -6,   26, "checkbutton#tl:30:%y#i:normalIconBorder2#o:normalIconBorder2#" .. L["CT_BuffMod/Options/Window/Button/General/NormalIconBorderCheckbox"]);
				optionsAddScript("onenter",
					function(button)
						module:displayTooltip(button, {L["CT_BuffMod/Options/Window/Button/General/NormalIconBorderCheckbox"],L["CT_BuffMod/Options/Window/Button/General/NormalIconBorderTip"]}, "ANCHOR_TOPLEFT");
					end
				);
			optionsEndFrame();

			-- Show time remaining text
			--	Format
			--	Location
			optionsAddObject( -6,   26, "checkbutton#tl:30:%y#i:showTimers2#o:showTimers2:true#" .. L["CT_BuffMod/Options/Window/Button/General/TimeRemainingCheckbox"]);

			optionsAddObject( -2,   15, "font#tl:70:%y#n:CT_BuffMod_Style2FormatLabel#v:ChatFontNormal#" .. L["CT_BuffMod/Options/Window/Button/General/TimeFormatLabel"]);
			optionsAddObject( 12,   20, "dropdown#tl:115:%y#s:145:%s#n:CT_BuffModDropdown_durationFormat2#i:durationFormat2#o:durationFormat2:1#" .. L["CT_BuffMod/Options/Window/Time Remaining/Duration Format Dropdown"]);

			optionsAddObject(  6,   26, "checkbutton#tl:44:%y#n:CT_BuffMod_showDaysFormat2#o:showDays2:true#" .. L["CT_BuffMod/Options/Window/Button/General/ShowDaysCheckbox"]);

			optionsAddObject( -6,   15, "font#tl:48:%y#n:CT_BuffMod_Style2LocationLabel#v:ChatFontNormal#" .. L["CT_BuffMod/Options/Window/Button/General/TimeLocationLabel"]);
			optionsAddObject( 12,   20, "dropdown#tl:115:%y#s:145:%s#n:CT_BuffModDropdown_dataSide2#i:dataSide2#o:dataSide2:" .. constants.DATA_SIDE_BOTTOM .. L["CT_BuffMod/Options/Window/Button/Style2/TimeLocationDropdown"]);

			-- Spacing between icon and text
			optionsAddObject(-17,   14, "font#tl:48:%y#n:CT_BuffMod_Style2OffsetLabel#v:ChatFontNormal#" .. L["CT_BuffMod/Options/Window/Button/Style2/OffsetLabel"]);
			optionsBeginFrame(15,   17, "slider#tl:190:%y#s:100:%s#i:spacingFromIcon2#o:spacingFromIcon2:0#<value>#0:50:1");
				optionsAddScript("onupdate",
					function(self)
						if (UIDropDownMenu_GetSelectedID(CT_BuffModDropdown_dataSide2) == constants.DATA_SIDE_CENTER) then
							self:Disable();
							self.Low:SetTextColor(.5,.5,.5)
							self.Text:SetTextColor(.5,.5,.5)
							self.High:SetTextColor(.5,.5,.5)
						else
							self:Enable();
							self.Low:SetTextColor(1,1,1);
							self.Text:SetTextColor(1,1,1)
							self.High:SetTextColor(1,1,1)
						end
					end
				);
			optionsEndFrame();
		
		optionsEndFrame()
		
		----------
		-- Scripts
		----------
		optionsAddScript("onload",
			function(self)
				windowOptionsFrame = self;
				module:setRadioButtonTextures(self.visShow);
				module:setRadioButtonTextures(self.visBasic);
				module:setRadioButtonTextures(self.visAdvanced);
				self.collapsiblePassthrough = true;
			end
		);
		optionsAddScript("onshow",
			function(self)
				-- If the current edit frame id is invalid, then select the first one.
				local windowId = currentWindowId;
				local windowObject = globalObject.windowListObject:findWindow(windowId);
				if (not windowObject) then
					windowId = globalObject.windowListObject:windowNumToId(1);
				end
				options_setCurrentWindow( windowId, true );
			end
		);
	optionsEndFrame();

	
	-- Reset Options
	optionsAddFromTemplate(-20, 0, "frame#tl:0:%y#br:tr:0:%b#i:ResetFrame", "ResetTemplate")

	optionsAddScript("onshow",
		function(self)
			globalObject.windowListObject:altFrameEnableMouse(true);
			globalObject.windowListObject:setCurrentWindow( currentWindowId, true );
		end
	);
	optionsAddScript("onhide",
		function(self)
			globalObject.windowListObject:altFrameEnableMouse(false);
			globalObject.windowListObject:setCurrentWindow( currentWindowId, false );
		end
	);

	return "frame#all", optionsGetData();
end

-- Function to update an option.
module.update = function(self, optName, value)
	module.optionUpdate(self, optName, value);
end

--------------------------------------------
-- Global frame

local function globalFrame_Init(self)
	-- Perform initialization

	-- Create global object.
	globalObject = globalClass:new();
	module.globalObject = globalObject;

	-- Apply global options
	globalObject:applyGlobalOptions(true);

	-- Register events
	self:RegisterEvent("UNIT_AURA");
	self:RegisterEvent("PLAYER_TARGET_CHANGED");
	if (FocusFrame) then
		-- BC onwards
		self:RegisterEvent("PLAYER_FOCUS_CHANGED");
	end

	-- Create the initial frame objects.
	local windowListObject = globalObject.windowListObject;

	local windowOptionsList = windowListObject:getWindowOptionsList();
	local windowObject;
	local primaryObject;
	local consolidatedObject;

	-- Determine the largest window id number that is present in
	-- the saved window options.
	local maxWindowId = 0;
	for windowId, windowOptions in pairs(windowOptionsList) do
		if (windowId > maxWindowId) then
			maxWindowId = windowId;
		end
	end
	if (maxWindowId > 0) then
		-- Create windows for those that had saved frame options.
		-- Create the window objects in numerical window id sequence.
		for windowId = 1, maxWindowId do
			-- We need to access the windowOptionsList directly since we don't
			-- have any windows created yet. If we don't find any options for
			-- a window then we don't need to create the window.
			local windowOptions = windowOptionsList[windowId];
			if (windowOptions) then
				windowObject = windowListObject:addWindow(windowOptions.unitId, windowId, nil);
			end
		end
	end
	if (windowListObject:getWindowCount() == 0) then
		-- No windows defined yet, so create one for the player.
		windowObject = windowListObject:addWindow("player", nil, nil);
		windowObject:updateSpellsAndEnchants();
		windowObject:refreshAuraButtons();
		windowObject:resetPosition();
	else
		-- Finish up with the windows that did have options.
		windowListObject:updateSpellsAndEnchants();
		windowListObject:refreshAuraButtons();
	end
	
	-- Start a ticker to synchronize flashing across all windows
	local flashDirection;
	local function synchronizeFlashing()
		-- Adjust alpha value to use for flashing auras.
		if (flashDirection) then
			module.auraAlpha = module.auraAlpha - 0.05;
			if (module.auraAlpha <= 0) then
				flashDirection = false;
				module.auraAlpha = 0
			end
		else
			module.auraAlpha = module.auraAlpha + 0.05;
			if (module.auraAlpha >= 1) then
				flashDirection = true;
				module.auraAlpha = 1
			end
		end
		C_Timer.After(0.05, synchronizeFlashing);
	end
	module.auraAlpha = 0;
	synchronizeFlashing();

	-- Start a ticker to monitor for expiring buffs every second
	local function checkExpiration()
		globalObject.unitListObject:checkExpiration();
		C_Timer.After(1, checkExpiration);
	end
	checkExpiration();
	
end

local function globalFrame_OnEvent(self, event, arg1)
	if (event == "PLAYER_LOGIN") then
		globalFrame_Init(self);

	elseif (event == "UNIT_AURA") then
		-- Update auras for the specified unit.
		globalObject.unitListObject:updateSpells(arg1);
		-- UNIT_AURA event detection in the frames will trigger visual updates.

	elseif (event == "PLAYER_TARGET_CHANGED") then
		-- Update auras and enchants for the target.
		globalObject.unitListObject:updateSpellsAndEnchants("target");

	elseif (event == "PLAYER_FOCUS_CHANGED") then
		-- Update auras and enchants for the target.
		globalObject.unitListObject:updateSpellsAndEnchants("focus");

	end
end

globalFrame = CreateFrame("Frame", nil, UIParent);
globalFrame:SetScript("OnEvent", globalFrame_OnEvent);
globalFrame:RegisterEvent("PLAYER_LOGIN");
globalFrame:Show();

--frame_Show = globalFrame.Show; -- it doesn't appear this is ever used
frame_Hide = globalFrame.Hide;

--------------------------------------------
-- Slash command.

local function slashCommand()
	module:showModuleOptions();
end

module:setSlashCmd(slashCommand, "/ctbuff", "/ctbuffmod", "/ctaura");
-- enUS: /ctbuff, /ctbuffmod
-- frFR: /ctaura