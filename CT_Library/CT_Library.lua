------------------------------------------------
--                 CT_Library                 --
--                                            --
-- A shared library for all CTMod addons to   --
-- simplify simple, yet time consuming tasks  --
-- Please do not modify or otherwise          --
-- redistribute this without the consent of   --
-- the CTMod Team. Thank you.                 --
--                                            --
-- Original credits to Cide and TS (Vanilla)  --
-- Maintained by Resike from 2014 to 2017     --
-- Maintained by Dahk Celes since 2018        --
--                                            --
-- This file contains the overall CTMod       --
-- structure used by all modules, and several --
-- helper functions to simplify coding        --
------------------------------------------------

-----------------------------------------------
-- Initialization
local LIBRARY_NAME, lib = ...;
local LIBRARY_VERSION = strmatch(C_AddOns.GetAddOnMetadata(LIBRARY_NAME, "version"), "^([%d.]+)");

-- Create tables for all the PROTECTED contents and PUBLIC interface of CTMod


local libPublic = {}		-- Public attributes and methods that any AddOn, including CT modules, may access at time by calling _G["CT_Library"] or via the special table module.publicInterface that is created by CT_Library(RegisterModule.module)
				-- By contrast, "lib" contains any Protected attributes and methods that any CT module may access by calling CT_Library:RegisterModule(module) with its own table as a parameter

-- Associate lib and libPublic, so that code written for the protected lib can also access the public libPublic without being aware of the difference
setmetatable(lib, { __index = libPublic });

-- Publicly expose the public interface
_G[LIBRARY_NAME] = libPublic;

-- Private attributes
local modules = {};		-- Contains two references to each installed module: by number and by name.  See lib:iterateModules() and lib:getModule(name)
local movables, frame, eventTable;
local timerRepeatingFuncs, timerFuncs = {}, {};
local numSlashCmds, localizations, tableList;
local defaultDisplayValues = {}
local frameCache;

-- Set the variables used
lib.name = LIBRARY_NAME;
lib.version = LIBRARY_VERSION;

------------------------------------------------
-- Shared helpers (WoW Midnight / cross-module)
-- Exposed on the public interface so any module can use them via CT_Library.xxx

-- safeValue: neutralizes Midnight "secret values".
-- In combat, insecure addon code may read restricted ("secret") values from unit/aura/action APIs.
-- Comparing, doing arithmetic on, or using such a value as a table key throws a Lua error. This probes
-- the value with a comparison inside pcall and returns it only when usable, otherwise the supplied
-- default (or nil). Works for numbers and strings. NOTE: tonumber() does NOT neutralize a secret number.
function libPublic.safeValue(v, default)
	if (pcall(function() return v < v; end)) then
		return v;
	end
	return default;
end

-- safeBool: the boolean counterpart of safeValue. Some APIs (e.g. UnitInRange) return a restricted
-- "secret boolean" to tainted addon code; a boolean test (`if v`, `not v`) on it throws. safeValue's
-- `<` probe can't be used on booleans, so this probes with a protected boolean test instead. Returns the
-- value when it is a normal boolean/nil, else the default. (A legitimately nil/false result passes
-- through; only a truly restricted value yields the default.)
function libPublic.safeBool(v, default)
	if (pcall(function() return not v; end)) then
		return v;
	end
	return default;
end

-- getSpellName: returns a spell's name (string) or nil, across retail (C_Spell) and classic (GetSpellInfo).
-- Accepts a spellID or a spell name; also doubles as an "does this spell exist" check via truthiness.
function libPublic.getSpellName(spellIdentifier)
	if (not spellIdentifier) then
		return nil;
	end
	if (GetSpellInfo) then
		return (GetSpellInfo(spellIdentifier));		-- classic / older retail: first return value is the name
	elseif (C_Spell and C_Spell.GetSpellInfo) then
		local info = C_Spell.GetSpellInfo(spellIdentifier);
		return info and info.name;
	elseif (C_Spell and C_Spell.GetSpellName) then
		return C_Spell.GetSpellName(spellIdentifier);
	end
	return nil;
end

-- DebuffTypeColor: standard Blizzard debuff-type colors. The global was removed in Midnight; this uses
-- it when present (older clients) and otherwise falls back to the standard values. Index by dispel type
-- ("Magic"/"Curse"/"Disease"/"Poison"/"none"); [""] aliases "none". Modules that used the bare global
-- should add:  local DebuffTypeColor = CT_Library.DebuffTypeColor
libPublic.DebuffTypeColor = _G.DebuffTypeColor or {
	["none"]    = { r = 0.80, g = 0.00, b = 0.00 },
	["Magic"]   = { r = 0.20, g = 0.60, b = 1.00 },
	["Curse"]   = { r = 0.60, g = 0.00, b = 1.00 },
	["Disease"] = { r = 0.60, g = 0.40, b = 0.00 },
	["Poison"]  = { r = 0.00, g = 0.60, b = 0.00 },
};
if (not libPublic.DebuffTypeColor[""]) then
	libPublic.DebuffTypeColor[""] = libPublic.DebuffTypeColor["none"];
end

-- getMerchantItemInfo: GetMerchantItemInfo was removed in Midnight -> C_MerchantFrame.GetItemInfo(index)
-- returns a table. This adapter preserves the old positional return values.
function libPublic.getMerchantItemInfo(index)
	if (GetMerchantItemInfo) then
		return GetMerchantItemInfo(index);
	elseif (C_MerchantFrame and C_MerchantFrame.GetItemInfo) then
		local info = C_MerchantFrame.GetItemInfo(index);
		if (info) then
			return info.name, info.texture, info.price, info.stackCount, info.numAvailable, info.isPurchasable, info.isUsable, info.hasExtendedCost;
		end
	end
end

-- isSpellOverlayed: the global was removed in modern clients (moved to C_SpellActivationOverlay).
-- Returns false when no overlay API is available.
function libPublic.isSpellOverlayed(spellID)
	if (IsSpellOverlayed) then
		return IsSpellOverlayed(spellID);
	elseif (C_SpellActivationOverlay and C_SpellActivationOverlay.IsSpellOverlayed) then
		return C_SpellActivationOverlay.IsSpellOverlayed(spellID);
	end
	return false;
end

-- see localization.lua
local L;
do
	lib.text = lib.text or { };
	L = lib.text
	local metatable = getmetatable(L) or {}
	metatable.__index = function(table, missingKey)
		return "[Not Found: " .. gsub(missingKey, "CT_Library/", "") .. "]";
	end
	setmetatable(L, metatable);
end

-- End Initialization
-----------------------------------------------


-----------------------------------------------
-- Local Copies

local ChatFrame1 = ChatFrame1;

local bit = bit;
local floor = floor;
local format = format;
local gsub = gsub;
local ipairs = ipairs;
local match = string.match;
local math = math;
local maxn = table.maxn;
local min = min;
local pairs = pairs;
local print = print;
local select = select;
local setmetatable = setmetatable;
local sort = sort;
local string = string;
local strlen = strlen;
local strlower = strlower;
local strmatch = strmatch;
local strsub = strsub;
local strupper = strupper;
local tinsert = tinsert;
local tonumber = tonumber;
local tostring = tostring;
local tremove = tremove;
local type = type;
local unpack = unpack;

-- MODERNISERAT FOR WOW RETAIL (C_SpellBook)
local getNumSpellTabs = C_SpellBook and C_SpellBook.GetNumSpellBookTabs;
local getSpellTabInfo = C_SpellBook and C_SpellBook.GetSpellBookTabInfo;
local getSpellName = C_SpellBook and C_SpellBook.GetSpellBookItemName;

-- End Local Copies
-----------------------------------------------

-----------------------------------------------
-- Protected; these should be overloaded

function lib:init()
	-- fires after ADDON_LOADED; defaults to the older CTMod behaviour of self:update("init", nil)
	return self:update("init")
end

function lib:update(option, value)
	-- fires after self:setOption() unless supressed using the third arg of setOption()
	-- if self:init() is undefined, then self:update("init", nil) fires after ADDON_LOADED
end

function lib.frame()
	-- constructs them module's panel; defaults to an empty window
	-- once called, replaced with a reference to the actual frame itself
	local optionsFrameList = self:framesInit()
	return "frame#all", self:framesGetData(optionsFrameList)
end

-----------------------------------------------
-- Generic Functions

-- Return's the library's version, as a number with the main version before the decimal and subversions as fractions (usually tenths and thousandths, but not guaranteed)
function libPublic:getLibVersion()
	return LIBRARY_VERSION;
end

local function printText(frame, r, g, b, text)
	frame:AddMessage(text, r, g, b);
end

-- Local function to print text with a given color
local function getPrintText(...)
	local str = "";
	local num = select("#", ...);
	for i = 1, num, 1 do
		str = str .. tostring(select(i, ...)) .. ( (i < num and "  " ) or "" );
	end
	return str;
end

function lib:iterateModules()
	return ipairs(modules);
end

function lib:getModule(name)
	return modules[name]
end

-- Clears a table
local emptyMeta = { };
function lib:clearTable(tbl, clearMeta)
	for key, value in pairs(tbl) do
		tbl[key] = nil;
	end

	if ( clearMeta ) then
		setmetatable(tbl, emptyMeta);
	end
end

-- Returns the game version as a number suitable for binary comparison operators, such as (module:getGameVersion() <= 10) or (module:getGameVersionAndPatch() == 2.01)
do
	local version, major, minor = strsplit(".", GetBuildInfo())
	version = tonumber(version) or 0
	major = version + (tonumber(major) or 0)/10
	minor = major + (tonumber(minor) or 0)/100
	
	function libPublic:getGameVersion()
		return version
	end
	
	function libPublic:getGameVersionAndPatch()
		return minor
	end
end

-- Print a formatted message in yellow to ChatFrame1
function lib:printformat(...)
	printText(ChatFrame1, 1, 1, 0, format(...));
end

-- Print a formatted error message in red to ChatFrame1
function lib:errorformat(...)
	printText(ChatFrame1, 1, 0, 0, format(...));
end

-- Print a message in yellow to ChatFrame1
function lib:print(...)
	printText(ChatFrame1, 1, 1, 0, getPrintText(...));
end

-- Print an error message in red to ChatFrame1
function lib:error(...)
	printText(ChatFrame1, 1, 0, 0, getPrintText(...));
end

-- Print a message in a color of your choice to ChatFrame1
function lib:printcolor(r, g, b, ...)
	printText(ChatFrame1, r, g, b, getPrintText(...));
end

-- Print a formatted message in a color of your choice to ChatFrame1
function lib:printcolorformat(r, g, b, ...)
	printText(ChatFrame1, r, g, b, format(...));
end

-- Displays a tooltip, then hides it when the mouse cursor leaves the object
do
	local lineHeight = { };
	local left, right = { }, { };
	local tooltip = GameTooltip;
	local validLinkTypes =
	{
		["item"] = true,
		["spell"] = true,
	}
	
	function lib:displayTooltip(obj, text, anchor, offx, offy, owner)
		if not obj or not tooltip then return; end

		if not (obj.ct_displayTooltip_Hooked) then
			obj:HookScript("OnLeave", function()
				tooltip:Hide();
			for i, height in pairs(lineHeight) do
				left[i]:SetScale(1);
				if (right[i]) then right[i]:SetScale(1); end
			end
			wipe(lineHeight);
			end);
			obj.ct_displayTooltip_Hooked = true
		end

		owner = (type(owner) == "string" and _G[owner]) or owner or obj;
		if ( not anchor ) then
			GameTooltip_SetDefaultAnchor(tooltip, owner);
		elseif (anchor == "CT_ABOVEBELOW") then
			if (owner:GetBottom() * owner:GetEffectiveScale() <= (UIParent:GetTop() * UIParent:GetEffectiveScale()) - (owner:GetTop() * owner:GetEffectiveScale())) then
				tooltip:SetOwner(owner, "ANCHOR_TOP", offx or 0, offy or 0);
			else
				tooltip:SetOwner(owner, "ANCHOR_BOTTOM", offx or 0, -(offy or 0));
			end
		elseif (anchor == "CT_BESIDE") then
			if (owner:GetLeft() <= UIParent:GetRight() - owner:GetRight()) then
				tooltip:SetOwner(owner, "ANCHOR_BOTTOMRIGHT", offx or 0, (offy or 0) + owner:GetHeight());
			else
				tooltip:SetOwner(owner, "ANCHOR_BOTTOMLEFT", -(offx or 0), (offy or 0) + owner:GetHeight());
			end
		else
			tooltip:SetOwner(owner, anchor, offx or 0, offy or 0);
		end

		if (type(text) == "string") then
			local p1, p2 = strsplit(":", text)
			if (p1 and p2 and validLinkTypes[p1] and tonumber(p2)) then
				tooltip:SetHyperlink(text)
			else
				tooltip:SetText(text)
			end
		elseif (type(text) == "table") then
			for i, row in ipairs(text) do
				local splitrow = {strsplit("#", row)}
				local leftR,leftG,leftB,rightR,rightG,rightB
				local alpha,wrap,leftText,rightText
				for j=1, #splitrow do
					local pieces = {strsplit(":", splitrow[j])}
					local isAllNums = true
					for k, piece in ipairs(pieces) do
						if (not tonumber(piece) or tonumber(piece) < 0 or tonumber(piece) > 1) then
							isAllNums = false
						end
					end						
					if (not leftR and #pieces >= 3 and isAllNums) then
						leftR = pieces[1]
						leftG = pieces[2]
						leftB = pieces[3]
						if (pieces[6]) then
							rightR = pieces[4]
							rightG = pieces[5]
							rightB = pieces[6]
						elseif (pieces[4]) then
							alpha = pieces[4]
						end
					elseif (not wrap and #pieces == 1 and pieces[1] == "w") then
						wrap = true
					elseif (not size and #pieces == 2 and pieces[1] == "s") then
						lineHeight[i] = tonumber(pieces[2])
					elseif (not leftText) then
						leftText = splitrow[j]
					elseif (not rightText) then
						rightText = splitrow[j]
					end
				end
				if (rightText) then
					GameTooltip:AddDoubleLine(leftText, rightText, leftR or 0.9, leftG or 0.9, leftB or 0.9, rightR or 0.9, rightG or 0.9, rightB or 0.9)
				elseif (leftText) then
					GameTooltip:AddLine(leftText, leftR or 0.9, leftG or 0.9, leftB or 0.9, alpha, wrap)
				end
			end
		end

		tooltip:Show();
		
		for i, height in pairs(lineHeight) do
			left[i] = left[i] or _G["GameTooltipTextLeft" .. i]
			right[i] = right[i] or _G["GameTooltipTextRight" .. i]
			tooltip:SetHeight(tooltip:GetHeight() + (height - 1) * left[i]:GetHeight());
			left[i]:SetScale(height);
			if (right[i] and right[i]:IsVisible()) then
				right[i]:SetScale(height);
				right[i]:SetPoint("RIGHT", left[i], "LEFT", select(4, right[i]:GetPoint(1))/height, 0)
			end
		end
	end
end

function lib:displayPredefinedTooltip(obj, text, ...)
	self:displayTooltip(obj, L["CT_Library/Tooltip/" .. text], ...);
end

function lib:blockOverflowText(fontString, maxwidth)
	local fontName, fontHeight, fontFlags = fontString:GetFont();
	fontString.ctOverflowFunc = function(__, text)
		fontString.ctIsResizing = true;
		fontString:SetFont(fontName, fontHeight, fontFlags);
		local width = fontString:GetStringWidth();
		local newHeight = fontHeight;
		while (width >= maxwidth and newHeight * 1.5 > fontHeight) do
			newHeight = newHeight - 0.5;
			fontString:SetFont(fontName, newHeight, fontFlags);
			width = fontString:GetStringWidth();
		end
		fontString.ctIsResizing = false;
	end	
	if (not fontString.ctOverflowFuncHooked) then
		fontString.ctOverflowFuncHooked = true;
		hooksecurefunc(fontString, "SetText", fontString.ctOverflowFunc);
		hooksecurefunc(fontString, "SetFont", function()
			if (not fontString.ctIsResizing) then
				fontName, fontHeight, fontFlags = fontString:GetFont();
				fontString.ctOverflowFunc(fontString, fontString:GetText());
			end
		end);
		fontString.ctOverflowFunc(fontString, fontString:GetText());
	end
end

function lib:unblockOverflowText(fontString)
	if (fontString.ctOverflowFuncHooked) then
		fontString.ctOverflowFunc = function() return; end
	end
end

if (not numSlashCmds) then
	numSlashCmds = 0;
	local cmd = true;
	while (cmd) do
		local count = numSlashCmds + 1;
		cmd = _G["SLASH_CT_SLASHCMD" .. count .. "1"];
		if (not cmd) then
			break;
		end
		numSlashCmds = count;
	end
end

function lib:setSlashCmd(func, ...)
	numSlashCmds = numSlashCmds + 1;
	local id = "CT_SLASHCMD" .. numSlashCmds;
	SlashCmdList[id] = func;
	for i = 1, select('#', ...), 1 do
		_G["SLASH_" .. id .. i] = select(i, ...);
	end
end

function lib:updateSlashCmd(func, ...)
	local found;
	local count = 1;
	local id = "CT_SLASHCMD" .. count;
	local oldFunc = SlashCmdList[id];
	while (oldFunc) do
		local i = 1;
		local cmd = _G["SLASH_" .. id .. i];
		while (cmd) do
			for k = 1, select('#', ...), 1 do
				if (cmd == select(i, ...)) then
					found = true;
					break;
				end
			end
			if (found) then
				break;
			end
			i = i + 1;
			cmd = _G["SLASH_" .. id .. i];
		end
		if (found) then
			local i = 1;
			local cmd = _G["SLASH_" .. id .. i];
			while (cmd) do
				_G["SLASH_" .. id .. i] = nil;
				i = i + 1;
				cmd = _G["SLASH_" .. id .. i];
			end
			local save = numSlashCmds;
			numSlashCmds = count - 1;
			self:setSlashCmd(func, ...);
			numSlashCmds = save;
			break;
		end
		count = count + 1;
		id = "CT_SLASHCMD" .. count;
		oldFunc = SlashCmdList[id];
	end
	if (not found) then
		self:setSlashCmd(func, ...);
	end
end

local num_locales = 3;
function lib:setText(key, ...)
	local count = select('#', ...);
	if ( count == 0 ) then
		return;
	end

	if ( not localizations ) then
		localizations = { };
	end

	local retVal = maxn(localizations)+1;
	for i = 1, min(count, num_locales), 1 do
		tinsert(localizations, (select(i, ...)));
	end
	self[key] = retVal;
end

function lib:getText(key)
	local localeOffset;
	if ( localizations ) then

		key = self[key];
		if ( not key ) then
			return;
		end

		if ( not localeOffset ) then
			local locale = strsub(GetLocale(), 1, 2);
			if ( locale == "en" ) then
				localeOffset = 0;
			elseif ( locale == "de" ) then
				localeOffset = 1;
			elseif ( locale == "fr" ) then
				localeOffset = 2;
			else
				localeOffset = 0;
			end
		end

		local value = localizations[key+localeOffset];
		if ( not value and localeOffset > 0 ) then
			value = localizations[key];
		end
		if ( not value ) then
			value = "";
		end
		return value;
	end
end

if (not tableList) then
	tableList = { };
end
setmetatable(tableList, { __mode = 'v' });

function lib:getTable()
	return tremove(tableList) or { };
end

function lib:freeTable(tbl)
	if ( tbl ) then
		self:clearTable(tbl, true);
		tinsert(tableList, tbl);
	end
end

function lib:copyTable(source, dest)
	if (type(dest) ~= "table") then
		dest = {};
	end
	if (type(source) == "table") then
		for k, v in pairs(source) do
			if (type(v) == "table") then
				v = self:copyTable(v, dest[k]);
			end
			dest[k] = v;
		end
	end
	return dest;
end

do
	local separatorPattern4 = "%s%d" .. LARGE_NUMBER_SEPERATOR .. "%03d";
	local separatorPattern7 = "%s%d" .. LARGE_NUMBER_SEPERATOR .. "%03d" .. LARGE_NUMBER_SEPERATOR .. "%03d";
	local capPattern4 = separatorPattern4;
	local capPattern6 = "%s%d" .. FIRST_NUMBER_CAP;
	local capPattern7 = separatorPattern4 .. FIRST_NUMBER_CAP;
	local capPattern9 = "%s%d" .. SECOND_NUMBER_CAP;
	local capPattern10 = separatorPattern4 .. SECOND_NUMBER_CAP;

	function lib:abbreviateLargeNumbers(value, breakup)
		local negative = "";
		if (value < 0) then
			negative = "-";
			value = -value;
		end
		if (value < 1000) then
			return negative .. value
		elseif (value < 100000 and breakup ~= false) then
			return capPattern4:format(negative, value/1000, value%1000);
		elseif (value < 1000000) then
			return capPattern6:format(negative, value/1000);
		elseif (value < 100000000 and breakup ~= false) then
			return capPattern7:format(negative, value/1000000, value%1000000/1000);
		elseif (value < 1000000000 or breakup == false) then
			return capPattern9:format(negative, value/1000000);
		else
			return capPattern10:format(negative, value/1000000000, value/1000000);
		end
	end

	function lib:breakUpLargeNumbers(value, breakup)
		local negative = "";
		if (value < 0) then
			negative = "-";
			value = -value;
		end

		if ( value < 1000 ) then
			if ( value%1 == 0) then
				return negative .. value;
			else
				return negative .. format("%.2f", value);
			end
		elseif (breakup ~= false) then
			if ( value >= 1000000 ) then
				return separatorPattern7:format(negative, value/1000000, value/1000%1000, value%1000);
			else
				return separatorPattern4:format(negative, value/1000, value%1000);
			end
		else
			return negative .. math.floor(value);
		end
	end
end

-----------------------------------------------
-- Actions requiring frames

if ( not frame ) then
	frame = CreateFrame("Frame");
end

function lib:regEvent(event, func)
	event = strupper(event);
	-- Skip events that don't exist in this client version (e.g. renamed/removed in WoW Midnight),
	-- so one unknown event can't abort a module's init with "attempting to register unknown event".
	if (C_EventUtils and C_EventUtils.IsEventValid and not C_EventUtils.IsEventValid(event)) then
		return;
	end
	if (not pcall(frame.RegisterEvent, frame, event)) then
		return;
	end

	if ( not eventTable ) then
		eventTable = { };
	end

	local oldFunc = eventTable[event];
	if ( not oldFunc ) then
		eventTable[event] = func;
	elseif ( type(oldFunc) == "table" ) then
		tinsert(oldFunc, func);
	else
		eventTable[event] = { oldFunc, func };
	end
end

function lib:unregEvent(event, func)
	if ( not eventTable ) then
		return;
	end

	event = strupper(event);
	local eventFuncs = eventTable[event];
	if ( not eventFuncs ) then
		return;
	end

	if ( type(eventFuncs) == "table" ) then
		for key, value in ipairs(eventFuncs) do
			if ( value == func ) then
				tremove(eventFuncs, key);
				break;
			end
		end
		if ( #eventFuncs == 0 ) then
			frame:UnregisterEvent(event);
		end
	else
		eventTable[event] = nil;
		frame:UnregisterEvent(event);
	end
end

local function eventHandler(self, event, ...)
	local eventFuncs = eventTable[event];
	if ( type(eventFuncs) == "table" ) then
		for key, value in ipairs(eventFuncs) do
			value(event, ...);
		end
	elseif ( eventFuncs ) then
		eventFuncs(event, ...);
	end
end

frame:SetScript("OnEvent", eventHandler);

function lib:schedule(time, func, repeatFunc)
	if ( not time or not func or ( type(func) ~= "function" and not repeatFunc ) ) then
		return;
	end

	if ( repeatFunc ) then
		if (timerRepeatingFuncs[repeatFunc]) then
			timerRepeatingFuncs[repeatFunc]:Cancel();
		end
		timerRepeatingFuncs[repeatFunc] = C_Timer.NewTicker(time, repeatFunc);
	else
		if (timerFuncs[func]) then
			timerFuncs[func]:Cancel();
		end
		timerFuncs[func] = C_Timer.NewTimer(time, func);
	end
end

function lib:unschedule(func, isRepeat)
	if ( not func ) then
		return;
	end

	if ( isRepeat ) then
		if ( timerRepeatingFuncs[func] ) then
			timerRepeatingFuncs[func]:Cancel();
			timerRepeatingFuncs[func] = nil;
		end
	else
		if ( timerFuncs[func] ) then
			timerFuncs[func]:Cancel();
			timerFuncs[func] = nil;
		end
	end
end

do
	local inEncounter = nil
	lib:regEvent("ENCOUNTER_START", function(__, id)
		inEncounter = id
	end);
	lib:regEvent("ENCOUNTER_END", function()
		inEncounter = nil
	end);
	
	function lib:isInEncounter()
		return inEncounter
	end
end

local queueDuringCombat = {}
local errorFreeAfterCombat = true

function lib:afterCombat(func, ...)
	if InCombatLockdown() then
		tinsert(queueDuringCombat, {func, ...})
	else
		func(...)
	end
end

lib:regEvent("PLAYER_REGEN_ENABLED", function()
	for __, funcAndArgs in ipairs(queueDuringCombat) do
		local retOK, msg = pcall(unpack(funcAndArgs))
		if not retOK and msg and errorFreeAfterCombat then
			print("CTMod caught an error when combat ended.")
			print(msg)
			errorFreeAfterCombat = false
		end
	end
end)

-----------------------------------------------
-- Module Handling

local module_meta =
{
	__index = function(module, key)
		return module.publicInterface[key] or lib[key];
	end
}
local module_metaPublic = { __index = libPublic };

local function registerMeta(module)
	module.publicInterface = module.publicInterface or {};
	setmetatable(module.publicInterface, module_metaPublic);
	setmetatable(module, module_meta);
end

local function registerLocalizationMeta(module)
	module.text = module.text or {};
	local meta = getmetatable(module.text) or {};
	meta.__index = function(table, missingKey)
		missingKey = gsub(missingKey, (module.name or "CT_Library") .. "/", "");
		missingKey = gsub(missingKey, "Options/", "O/");
		return "[Error: " .. missingKey .. "]";
	end
	setmetatable(module.text, meta);
end

local function registerModule(module, position)
	if modules[module.name] then
		return;
	end
	modules[module.name] = module;
	if ( position ) then
		module.ctposition = position;
		tinsert(modules, position, module);
	else
		tinsert(modules, module);
	end
	registerMeta(module);
	registerLocalizationMeta(module);
	sort(modules, function(a, b)
		if (a.ctposition and not b.ctposition) then
			return true;
		elseif (not a.ctposition and b.ctposition) then
			return false;
		elseif (a.ctposition and b.ctposition) then
			if (a.ctposition == b.ctposition) then
				return a.name < b.name;
			else
				return a.ctposition < b.ctposition;
			end
		else
			return a.name < b.name;
		end
	end);
	defaultDisplayValues[module] = {}
end

function libPublic:registerModule(module)
	assert(type(module) == "table", "An AddOn attempted to register itself with CTMod without passing its table");
	assert(type(module.name) == "string", "An unnamed addon attempted to register with CTMod.");
	registerModule(module);
end

local function registerPseudoModule(module, position)
	local charKey = lib.getCharKey()
	registerModule(module, position)
	module.options = {}
	module.options[charKey] = {}
	module.charOptions = module.options[charKey]
end

-----------------------------------------------
-- Option Handling

do
	local charKey = "CHAR-"..(UnitName("player") or "Unknown").."-"..(GetRealmName() or "Unknown")
	local function getCharKey()
		return charKey
	end
	lib.getCharKey = getCharKey

	local function loadAddon(event, addon)
		local module = modules[addon]
		if (module) then
			local optionsKey = addon.."Options"
			_G[optionsKey] = _G[optionsKey] or {}
			module.options = _G[optionsKey]
			module.options[charKey] = module.options[charKey] or {}
			module.charOptions = module.options[charKey]
			module:init()
		end
	end

	lib:regEvent("ADDON_LOADED", loadAddon);

	CT_SKIP_UPDATE_FUNC = false

	function lib:setOption(option, value, callUpdate)
		if type(option) == "function" then
			option = option()
		end
		if option and self.options then
			self.charOptions[option] = value;
			if (callUpdate ~= false) then
				self:update(option, value)
				if (self.setOptionCallbacks and self.setOptionCallbacks[option]) then
					for __, func in ipairs(self.setOptionCallbacks[option]) do
						func(value)
					end
				end
			end
		end
	end

	function lib:getOption(option)
		if type(option) == "function" then
			option = option()
		end
		if option and self.options then
			return self.charOptions[option]
		end
	end

	function lib:getDisplayValue(option)
		local value = self:getOption(option)
		return value == nil and defaultDisplayValues[self][option] or value
	end

	local function nextOption(t, key)
		local val
		repeat
			key, val = next(t, key)
		until (key == nil or key:find("MOVABLE-") == nil)
		return key, val
	end

	function lib:enumerateOptions()
		return nextOption, self.charOptions or {}
	end

	function lib:registerSetOptionCallback(option, func)
		self.setOptionCallbacks = self.setOptionCallbacks or {}
		self.setOptionCallbacks[option] = self.setOptionCallbacks[option] or {}
		tinsert(self.setOptionCallbacks[option], func)
	end

	local optionsToReset
	
	StaticPopupDialogs["CT_RESETOPTIONS"] = {
		text = "Do you want to reset %s options?",
		button1 = ACCEPT,
		button2 = CANCEL,
		OnAccept = function()
			optionsToReset["CHAR-Unknown- Interim Backup"] = optionsToReset[getCharKey()]
			optionsToReset[getCharKey()] = {}
			C_UI.Reload()
		end,
		timeout = 15,
		whileDead = true,
		hideOnEscape = true,
	}
	
	StaticPopupDialogs["CT_RESETOPTIONS_ALL"] = {
		text = "Do you want to reset %s for all characters?",
		showAlert = true,
		button1 = ACCEPT,
		button2 = CANCEL,
		OnAccept = function()
			wipe(optionsToReset)
			C_UI.Reload()
		end,
		timeout = 15,
		whileDead = true,
		hideOnEscape = true,
	}

	function lib:resetOptions(resetAll)
		if (self.options) then
			optionsToReset = self.options
			StaticPopup_Show(resetAll and "CT_RESETOPTIONS_ALL" or "CT_RESETOPTIONS", self.name)
		end
	end

	local historyToReset, callbackAfterReset
	
	StaticPopupDialogs["CT_RESETHISTORY"] = {
		text = "Do you want to delete this history?",
		button1 = DELETE,
		button2 = CANCEL,
		OnAccept = function()
			wipe(historyToReset)
			callbackAfterReset()
		end,
		timeout = 15,
		whileDead = true,
		hideOnEscape = true,
	}
	
	function lib:resetHistory(history, callback)
		historyToReset = history
		callbackAfterReset = callback or C_UI.Reload
		StaticPopup_Show("CT_RESETHISTORY")
	end
end

-----------------------------------------------
-- Movable Handling

function lib:registerMovable(id, frame, clamped)
	if ( not movables ) then
		movables = { }
	end

	id = "MOVABLE-"..id
	movables[id] = frame
	frame:SetMovable(true)
    if frame.SetIsUnrestricted then frame:SetIsUnrestricted(true) end -- FOR WOW RETAIL COMPAT
	frame:SetClampedToScreen(clamped or false)

	local option = self:getOption(id);
	if ( option ) then
		frame:ClearAllPoints();

		local scale = option[6];
		if ( scale ) then
			frame:SetScale(scale);
			frame:SetPoint(option[1], option[2], option[3], option[4] / scale, option[5] / scale);
		else
			frame:SetPoint(option[1], option[2], option[3], option[4], option[5]);
		end
	end
end

function lib:moveMovable(id)
	movables["MOVABLE-"..id]:StartMoving();
end

function lib:stopMovable(id)
	id = "MOVABLE-"..id;
	local frame = movables[id];
	frame:StopMovingOrSizing();
	frame:SetUserPlaced(false);

	local pos = self:getOption(id);
	if ( pos ) then
		self:clearTable(pos);

		local a, b, c, d, e = frame:GetPoint(1);
		local scale = frame:GetScale();
		if string.upper(a) == "BOTTOMLEFT" or string.upper(a) == "BOTTOMRIGHT" then
			a = "BOTTOM";
			c = "BOTTOM";
			d = math.floor(frame:GetLeft() + (frame:GetWidth() - UIParent:GetWidth()) / 2 + 0.5) * scale;
			e = math.floor(frame:GetTop() - frame:GetHeight() + 0.5) * scale;
		end

		pos[1], pos[2], pos[3], pos[4], pos[5], pos[6] = a, b, c, d, e, scale;
		if (not InCombatLockdown()) then
			frame:ClearAllPoints();
			frame:SetPoint(a, b, c, d, e);
		end
	else
		local a, b, c, d, e = frame:GetPoint(1);
		local scale = frame:GetScale();
		d, e = d * scale, e * scale;

		pos = { a, b, c, d, e, scale };
		self:setOption(id, pos);
	end

	local rel = pos[2];
	if ( rel ) then
		pos[2] = rel:GetName();
	end
end

function lib:resetMovable(id)
	self:setOption("MOVABLE-"..id, nil);
end

function lib:UnregisterMovable(id)
	movables["MOVABLE-"..id] = nil;
end

local function nextMovable(t, key)
	local val
	repeat
		key, val = next(t, key)
	until (key == nil or key:find("MOVABLE-"))
	return key, val
end

function lib:enumerateMovables()
	return nextMovable, self.charOptions or {}
end

-----------------------------------------------
-- Secure Hooks	

function lib:hookWhenFirstLoaded(frame, trigger, func)
	if (_G[frame]) then
		func(self, _G[frame])
		return true;
	elseif (type("trigger") == "string" and _G[trigger]) then
		hooksecurefunc(trigger, function()
			func(self, _G[frame])
			func = nop
		end)
		return true;
	end
	return false;
end

-----------------------------------------------
-- Frame Misc

function lib:createMultiLineEditBox(name, width, height, parent, bdtype, font)
	local frame, scrollFrame, editBox;
	local backdrop;

	if (bdtype == 1) then
		backdrop = {
			bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
			edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
			tile = true, tileSize = 16, edgeSize = 16,
			insets = { left = 5, right = 5, top = 5, bottom = 5 },
		};
	elseif (bdtype == 2) then
		backdrop = {
			bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
			edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
			tile = true, tileSize = 32, edgeSize = 32,
			insets = { left = 5, right = 5, top = 5, bottom = 5 },
		};
	end

	if (backdrop) then
		frame = CreateFrame("Frame", name, parent, BackdropTemplateMixin and "BackdropTemplate");
		frame:SetBackdrop(backdrop);
		frame:SetBackdropBorderColor(0.4, 0.4, 0.4);
		frame:SetBackdropColor(0, 0, 0);
	else
		frame = CreateFrame("Frame", name, parent);
	end
	
	frame:SetHeight(height);
	frame:SetWidth(width);
	frame:SetPoint("TOPLEFT", parent);
	frame:SetPoint("BOTTOMRIGHT", parent, "TOPLEFT", width, -height);
	frame:EnableMouse(true);
	frame:Hide();

	local sfname;
	if (name) then sfname = name .. "ScrollFrame"; end
	scrollFrame = CreateFrame("ScrollFrame", sfname, frame, "UIPanelScrollFrameTemplate");
	scrollFrame:SetPoint("TOPLEFT", frame, "TOPLEFT", 7, -5);
	scrollFrame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -28, 5);

	width = scrollFrame:GetWidth() - 6;

	local ebname;
	if (name) then ebname = name .. "EditBox"; end

	editBox = CreateFrame("EditBox", ebname, frame);
	editBox:SetWidth(width);
	editBox:SetMultiLine(true);
	editBox:EnableMouse(true);
	editBox:SetAutoFocus(false);
	editBox:SetFontObject(font or ChatFontNormal);

	editBox.cursorOffset = 0;
	editBox.cursorHeight = 0;
	editBox:SetText(" ");

	editBox:SetScript("OnCursorChanged", function(self, x, y, w, h) ScrollingEdit_OnCursorChanged(self, x, y-10, w, h); end);
	editBox:SetScript("OnTextChanged", function(self, userInput) ScrollingEdit_OnTextChanged(self, scrollFrame); end);
	editBox:SetScript("OnUpdate", function(self, elapsed) ScrollingEdit_OnUpdate(self, elapsed, scrollFrame); end);
	editBox:SetScript("OnEscapePressed", function(self) self:ClearFocus(); end);
	editBox:SetScript("OnTabPressed", function(self) self:ClearFocus(); end);

	scrollFrame:SetScrollChild(editBox);
	scrollFrame:Show();
	editBox:Show();

	local textButton = CreateFrame("Button", nil, frame);
	textButton:ClearAllPoints();
	textButton:SetPoint("TOPLEFT", scrollFrame);
	textButton:SetPoint("BOTTOMRIGHT", scrollFrame);
	textButton:SetScript("OnClick", function(self, button) self:GetParent().editBox:SetFocus(); end);

	frame.scrollFrame = scrollFrame;
	frame.editBox = editBox;

	return frame;
end

function lib:setRadioButtonTextures(checkbutton)
	local tex = "Interface\\Buttons\\UI-RadioButton";
	checkbutton:SetNormalTexture(tex);
	checkbutton:GetNormalTexture():SetTexCoord(0, 0.25, 0, 1);
	checkbutton:SetDisabledTexture(tex);
	checkbutton:GetDisabledTexture():SetTexCoord(0, 0.25, 0, 1);
	checkbutton:SetPushedTexture(tex);
	checkbutton:GetPushedTexture():SetTexCoord(0.25, 0.5, 0, 1);
	checkbutton:SetHighlightTexture(tex);
	checkbutton:GetHighlightTexture():SetTexCoord(0.51, 0.75, 0, 1);
	checkbutton:GetHighlightTexture():SetBlendMode("ADD");
	checkbutton:SetCheckedTexture(tex);
	checkbutton:GetCheckedTexture():SetTexCoord(0.25, 0.5, 0, 1);
	checkbutton:SetDisabledCheckedTexture(tex);
	checkbutton:GetDisabledCheckedTexture():SetTexCoord(0.25, 0.5, 0, 1);
end

-----------------------------------------------
-- Compression, hashing and character encoding

do
	function lib:hash(text)
		if (type(text) == "string") then
			return LibStub:GetLibrary("LibDeflate"):Adler32(text)
		end
	end

	function lib:compress(text)
		if (type(text) == "string") then
			return LibStub:GetLibrary("LibDeflate"):CompressDeflate(text)
		end
	end

	function lib:decompress(text)
		if (type(text) == "string") then
			return LibStub:GetLibrary("LibDeflate"):DecompressDeflate(text)
		end
	end

	function lib:encode256To64(text)
		if (type(text) ~= "string" or strlen(text) < 1) then return end
		local value = 0
		local bitsAvail = 0
		local encodedParts = lib:getTable()
		for i = 1, text:len() do
			value, bitsAvail = value*256 + text:byte(i), bitsAvail + 8
			while (bitsAvail >= 6) do
				bitsAvail = bitsAvail - 6
				tinsert(encodedParts, string.char(floor(value/2^bitsAvail)+38))
				value = value % 2^bitsAvail
			end
		end
		while (bitsAvail > 0) do
			bitsAvail = bitsAvail - 6
			tinsert(encodedParts, string.char(floor(value/2^bitsAvail)+38))
			value = value % 2^bitsAvail
		end
		local retVal = table.concat(encodedParts)
		retVal = string.char(lib:hash(retVal)%64+38) .. retVal
		lib:freeTable(encodedParts)
		return retVal
	end

	function lib:decode256From64(text)
		if (type(text) ~= "string" or strlen(text) < 2 or lib:hash(text:sub(2))%64+38 ~= text:byte(1)) then return end
		local value = 0
		local bitsAvail = 0
		local decodedParts = lib:getTable()
		for i = 2, text:len() do
			value, bitsAvail = value*64 + text:byte(i) - 38, bitsAvail + 6
			if (bitsAvail >= 8) then
				bitsAvail = bitsAvail - 8
				tinsert(decodedParts, string.char(floor(value/2^bitsAvail)))
				value = value % 2^bitsAvail
			end
		end	
		local retVal = table.concat(decodedParts)
		lib:freeTable(decodedParts)
		return retVal
	end
end

-----------------------------------------------
-- Table serializing

function lib:serializeTable(tbl)
	if (type(tbl) == "table") then
		return LibStub:GetLibrary("AceSerializer-3.0"):Serialize(tbl)
	end
end

function lib:deserializeTable(text)
	if (type(text) == "string") then
		local success, tbl = LibStub:GetLibrary("AceSerializer-3.0"):Deserialize(text)
		if (success) then return tbl end
	end
end

-----------------------------------------------
-- Frame Creation

	local numberSeparator = "#";
	local colonSeparator = ":";
	local commaSeparator = ",";
	local pipeSeparator = "|";

	local numberMatch = "^(.-)"..numberSeparator.."(.*)$";
	local colonMatch = "^(.-)"..colonSeparator.."(.*)$";
	local commaMatch = "^(.-)"..commaSeparator.."(.*)$";
	local pipeMatch = "^(.-)"..pipeSeparator.."(.*)$";

	local function splitNext(re, body)
	    if (body) then
		local pre, post = match(body, re);
		if (pre) then return post, pre; end
		return false, body;
	    end
	end
	local function iterator(str, match) return splitNext, match, str; end

local function splitString(str, match)
	if ( str and match ) then return match:split(str); end
	return str;
end

if (not frameCache) then frameCache = { }; end

local points = {
	tl = "TOPLEFT", tr = "TOPRIGHT", bl = "BOTTOMLEFT", br = "BOTTOMRIGHT",
	l = "LEFT", r = "RIGHT", t = "TOP", b = "BOTTOM", mid = "CENTER", all = "all"
};

local objectHandlers = { };

objectHandlers.frame = function(self, parent, name, virtual, option)
	return CreateFrame("Frame", name, parent, virtual)
end

do
	local function collapse(self)
		if (#self.movedSiblings == 0) then
			local top, bottom, parent = self:GetTop(), self:GetBottom(), self:GetParent()
			local height = max(self.button and top-bottom-20 or top-bottom, 0)
			if (self.button) then
				self.button:SetNormalAtlas("UI-QuestTrackerButton-Expand-Section")
				self.button:SetPushedAtlas("UI-QuestTrackerButton-Expand-Section-Pressed")
				self.button.text:Show()
			end
			while (parent) do
				for i=1, parent:GetNumChildren() do
					local sibling = select(i, parent:GetChildren())
					if (sibling:GetTop() < top and sibling ~= self) then
						sibling:AdjustPointsOffset(0, height)
						tinsert(self.movedSiblings, sibling)
					end
				end
				for i=1, parent:GetNumRegions() do
					local sibling = select(i, parent:GetRegions())
					if (sibling:GetTop() < top) then
						sibling:AdjustPointsOffset(0, height)
						tinsert(self.movedSiblings, sibling)
					end
				end
				if (parent.collapsiblePassthrough) then
					local point, relativeTo, relativePoint, ofsx, ofsy = parent:GetPoint(2)
					parent:SetPoint(point, relativeTo, relativePoint, ofsx, ofsy + height)
					tinsert(self.shrunkParents, parent)
					parent = parent:GetParent()
				elseif (parent.collapsibleChildrenMayShrink) then
					local point, relativeTo, relativePoint, ofsx, ofsy = parent:GetPoint(2)
					parent:SetPoint(point, relativeTo, relativePoint, ofsx, ofsy + height)
					tinsert(self.shrunkParents, parent)					
					parent = nil
				else
					parent = nil
				end
			end
			self:Hide()
		end
	end

	local function expand(self)
		if (#self.movedSiblings > 0) then
			self:Show()
			local top, bottom = self:GetTop(), self:GetBottom()
			local height = max(self.button and top-bottom-20 or top-bottom, 0)
			if (self.button) then
				self.button:SetNormalAtlas("UI-QuestTrackerButton-Collapse-Section")
				self.button:SetPushedAtlas("UI-QuestTrackerButton-Collapse-Section-Pressed")
				self.button.text:Hide()
			end
			for __, sibling in ipairs(self.movedSiblings) do
				sibling:AdjustPointsOffset(0, -height)
			end
			wipe(self.movedSiblings)
			for __, parent in ipairs(self.shrunkParents) do
				local point, relativeTo, relativePoint, ofsx, ofsy = parent:GetPoint(2)	
				parent:SetPoint(point, relativeTo, relativePoint, ofsx, ofsy - height)
			end
			wipe(self.shrunkParents)
		end
	end
		
	local function toggle(self)
		if (self.frame:IsShown()) then self.frame:Collapse() else self.frame:Expand() end
	end
	
	local function autoCollapse(frame, value)
		if (frame.invertAutoCollapse ~= not not value) then frame:Expand() else frame:Collapse() end
	end

	objectHandlers.collapsible = function(self, parent, name, virtual, option, header)
		local frame = CreateFrame("Frame", name, parent, virtual)
		frame.movedSiblings = {}
		frame.shrunkParents = {}
		frame.Collapse = collapse
		frame.Expand = expand
		if (header) then
			local title, align = header:match("(.*):([lr])")
			title = title or header
			local button = CreateFrame("Button", name and name .. "Minimize", parent)
			button:SetPoint(align ~= "r" and "TOPLEFT" or "TOPRIGHT", frame)
			button:SetSize(15,15)
			button:SetNormalAtlas("UI-QuestTrackerButton-Collapse-Section")
			button:SetPushedAtlas("UI-QuestTrackerButton-Collapse-Section-Pressed")
			button:SetHighlightAtlas("UI-QuestTrackerButton-Highlight")
			button:SetScript("OnClick", toggle)
			frame.button = button
			button.frame = frame
			button.text = button:CreateFontString(nil, "ARTWORK", "GameFontNormal")
			button.text:SetText(title)
			button.text:SetPoint(align ~= "r" and "LEFT" or "RIGHT", button, align ~= "r" and "RIGHT" or "LEFT", 2, 0)
			button.text:Hide()
		end
		
		if (option) then
			if (option:sub(1,1) == "~") then
				frame.invertAutoCollapse = true
				option = option:sub(2)
			else
				frame.invertAutoCollapse = false
			end
			self:registerSetOptionCallback(option, function(value) autoCollapse(frame, value) end)
			C_Timer.After(0, function() autoCollapse(frame, self:getDisplayValue(option)) end)
		end
		return frame
	end
end

objectHandlers.button = function(self, parent, name, virtual, option, text)
	local button = CreateFrame("Button", name, parent, virtual);
	if ( text ) then
		local str = self:getText(text)
		button:SetText(type(str) == "string" and str or text)
	end
	return button;
end

local function checkbuttonOnClick(self)
	local checked = self:GetChecked() or false;
	local option = self.option;
	if ( option ) then self.object:setOption(option, checked); end
	if ( checked ) then PlaySound(856); else PlaySound(857); end
end

objectHandlers.checkbutton = function(self, parent, name, virtual, option, text, data)
	local checkbutton = CreateFrame("CheckButton", name, parent, virtual or "InterfaceOptionsBaseCheckButtonTemplate");
	local r, g, b, justify, maxwidth;
	local a, b, c, d, e = splitString(data, colonSeparator);
	if ( tonumber(a) and tonumber(b) and tonumber(c) ) then
		r, g, b = tonumber(a), tonumber(b), tonumber(c);
		justify, maxwidth = d, tonumber(e);
	else
		justify, maxwidth = a, tonumber(b);
	end

	local textObj = checkbutton:CreateFontString(nil, "ARTWORK", "ChatFontNormal");
	textObj:SetPoint("LEFT", checkbutton, "RIGHT", 4, 0);
	checkbutton.text = textObj;
	
	if ( r and g and b ) then textObj:SetTextColor(tonumber(r) or 1, tonumber(g) or 1, tonumber(b) or 1); end
	
	if ( justify ) then
		local h = match(justify, "[lLrRcC]");
		local v = match(justify, "[tTbBmM]");
		if ( h == "l" ) then textObj:SetJustifyH("LEFT") elseif ( h == "r" ) then textObj:SetJustifyH("RIGHT") elseif ( h == "c" ) then textObj:SetJustifyH("CENTER") end
		if ( v == "t" ) then textObj:SetJustifyV("TOP") elseif ( v == "b" ) then textObj:SetJustifyV("BOTTOM") elseif ( v == "m") then textObj:SetJustifyV("MIDDLE") end
	end

	if (maxwidth and maxwidth > 1) then
		lib:blockOverflowText(textObj, maxwidth);
		textObj:SetWidth(maxwidth);
	end

	if ( text ) then textObj:SetText(text) end
	if ( not virtual or not checkbutton:GetScript("OnClick") ) then checkbutton:SetScript("OnClick", checkbuttonOnClick); end
	checkbutton:SetChecked(self:getDisplayValue(option) or false);

	return checkbutton;
end

local dialogBackdrop = {
	bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
	edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
	tile = true, tileSize = 32, edgeSize = 32,
	insets = { left = 11, right = 12, top = 12, bottom = 11 }
};
local tooltipBackdrop = {
	bgFile="Interface\\Tooltips\\UI-Tooltip-Background",
	edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
	tile = true, tileSize = 16, edgeSize = 16,
	insets = { left = 4, right = 4, top = 4, bottom = 4 }
};
objectHandlers.backdrop = function(self, parent, name, virtual, option, backdropType, bgColor, borderColor)
	Mixin(parent, BackdropTemplateMixin or { });
	if ( backdropType == "dialog" ) then parent:SetBackdrop(dialogBackdrop) elseif ( backdropType == "tooltip" ) then parent:SetBackdrop(tooltipBackdrop) end
	local r, g, b, a;
	if ( bgColor ) then r, g, b, a = splitString(bgColor, colonSeparator) end
	parent:SetBackdropColor(tonumber(r) or 0, tonumber(g) or 0, tonumber(b) or 0, tonumber(a) or 0.25);
	if ( borderColor ) then
		r, g, b, a = splitString(borderColor, colonSeparator);
		parent:SetBackdropBorderColor(tonumber(r) or 1, tonumber(g) or 1, tonumber(b) or 1, tonumber(a) or 1);
	end
end

objectHandlers.font = function(self, parent, name, virtual, option, text, data, layer)
	local r, g, b, justify, maxwidth;
	local a, b, c, d, e = splitString(data, colonSeparator);
	if ( tonumber(a) and tonumber(b) and tonumber(c) ) then
		r, g, b = tonumber(a), tonumber(b), tonumber(c);
		justify, maxwidth = d, tonumber(e);
	else
		justify, maxwidth = a, tonumber(b);
	end

	local fontString = parent:CreateFontString(name, layer or "ARTWORK", virtual or "GameFontNormal");
	if ( justify ) then
		local h = match(justify, "[lLrRcC]");
		local v = match(justify, "[tTbBmM]");
		if ( h == "l" ) then fontString:SetJustifyH("LEFT") elseif ( h == "r" ) then fontString:SetJustifyH("RIGHT") elseif ( h == "c" ) then fontString:SetJustifyH("CENTER") end
		if ( v == "t" ) then fontString:SetJustifyV("TOP") elseif ( v == "b" ) then fontString:SetJustifyV("BOTTOM") elseif ( v == "m") then fontString:SetJustifyV("MIDDLE") end
	end
	if (maxwidth and maxwidth > 0) then lib:blockOverflowText(fontString, maxwidth); end
	if ( r and g and b ) then fontString:SetTextColor(tonumber(r) or 1, tonumber(g) or 1, tonumber(b) or 1); end
	fontString:SetText(self:getText(text) or text)
	return fontString;
end

objectHandlers.texture = function(self, parent, name, virtual, option, texture, layer)
	local r, g, b, a = splitString(texture, colonSeparator);
	local tex = parent:CreateTexture(name, layer or "ARTWORK", virtual);
	if ( r and g and b ) then tex:SetColorTexture(tonumber(r) or 1, tonumber(g) or 1, tonumber(b) or 1, tonumber(a) or 1) else tex:SetTexture(texture) end
	return tex;
end

objectHandlers.editbox = function(self, parent, name, virtual, option, font, bdtype, multiline, multilinewidth, multilineheight)
	local frame;
	local backdrop;
	if (multiline) then
		frame = lib:createMultiLineEditBox(name,multilinewidth,multilineheight,parent,bdtype, font);
		if (option) then frame.editBox:SetText(self:getDisplayValue(option) or ""); end
	else
		if (tonumber(bdtype) == 1) then
			backdrop = {
				bgFile = "Interface\\Tooltips\\UI-Tooltip-Background", edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
				tile = true, tileSize = 16, edgeSize = 16, insets = { left = 5, right = 5, top = 5, bottom = 5 },
			};
		elseif (tonumber(bdtype) == 2) then
			backdrop = {
				bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background", edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
				tile = true, tileSize = 32, edgeSize = 32, insets = { left = 5, right = 5, top = 5, bottom = 5 },
			};
		end
		if (backdrop) then
			frame = CreateFrame("EditBox", name, parent, virtual, BackdropTemplateMixin and "BackdropTemplate");
			frame:SetBackdrop(backdrop);
			frame:SetBackdropBorderColor(0.4, 0.4, 0.4);
			frame:SetBackdropColor(0, 0, 0);
		else
			frame = CreateFrame("EditBox", name, parent, virtual);
		end
		if (font) then frame:SetFontObject(font) end
		if (option) then frame:SetText(self:getDisplayValue(option) or ""); end
	end
	return frame;
end

local optionFrameOnMouseUp = function(self) self:GetParent():StopMovingOrSizing(); end
local optionFrameOnEnter = function(self) lib:displayPredefinedTooltip(self, "DRAG"); end
local optionFrameOnMouseDown = function(self, button)
	if ( button == "LeftButton" ) then self:GetParent():StartMoving() elseif ( button == "RightButton" ) then local parent = self:GetParent(); parent:ClearAllPoints(); parent:SetPoint("CENTER", "UIParent", "CENTER") end
end

objectHandlers.optionframe = function(self, parent, name, virtual, option, headerName)
	local frame = CreateFrame("Frame", name, parent, virtual);
	frame:SetBackdrop(dialogBackdrop);
	frame:SetMovable(true);
	frame:SetToplevel(true);
	frame:SetFrameStrata("DIALOG");

	local dragFrame = CreateFrame("Button", nil, frame);
	dragFrame:SetWidth(150); dragFrame:SetHeight(32);
	dragFrame:SetPoint("TOP", -12, 12);
	dragFrame:SetScript("OnMouseDown", optionFrameOnMouseDown);
	dragFrame:SetScript("OnMouseUp", optionFrameOnMouseUp);
	dragFrame:SetScript("OnEnter", optionFrameOnEnter);
	dragFrame:SetScript("OnLeave", optionFrameOnLeave);

	local headerTexture = frame:CreateTexture(nil, "ARTWORK");
	headerTexture:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Header");
	headerTexture:SetWidth(256); headerTexture:SetHeight(64);
	headerTexture:SetPoint("TOP", 0, 12);

	local headerText = frame:CreateFontString(nil, "ARTWORK", "GameFontNormal");
	headerText:SetText(headerName);
	headerText:SetPoint("TOP", headerTexture, 0, -14);

	return frame;
end

local function dropdownSetWidth(self, width)
	self.SetWidth = self.oldSetWidth;
	UIDropDownMenu_SetWidth(self, width);
	self.SetWidth = dropdownSetWidth;
end

local function dropdownClick(self, arg1, arg2, checked)
	local dropdown = UIDROPDOWNMENU_OPEN_MENU or UIDROPDOWNMENU_INIT_MENU;
	if ( dropdown ) then
		local value;
		local option;
		if (arg1) then value = not checked; option = arg1; else value = self.value; option = dropdown.option; UIDropDownMenu_SetSelectedValue(dropdown, value); end
		if ( option ) then dropdown.object:setOption(option, value); end
	end
end

-- FALLBACK PATCH FOR MODERN WOW DROPDOWNS
objectHandlers.dropdown = function(self, parent, name, virtual, option, ...)
	local frame = CreateFrame("Frame", name, parent, virtual or "UIDropDownMenuTemplate");
	if frame.Left then
		frame.oldSetWidth = frame.SetWidth; frame.SetWidth = dropdownSetWidth; frame.ctDropdownClick = dropdownClick;
		local left, right, mid, btn = frame.Left, frame.Middle, frame.Right, frame.Button;
		btn:SetPoint("TOPRIGHT", right, "TOPRIGHT", 12, -12);
		left:SetHeight(50); right:SetHeight(50); mid:SetHeight(50);
	end
	local entries = { ... };
	if UIDropDownMenu_Initialize then
		UIDropDownMenu_Initialize(frame, function()
			local dropdownEntry = {};
			for i = 1, #entries, 1 do
				dropdownEntry.text = entries[i]; dropdownEntry.value = i; dropdownEntry.checked = nil; dropdownEntry.func = dropdownClick;
				UIDropDownMenu_AddButton(dropdownEntry);
			end
		end);
		UIDropDownMenu_SetSelectedValue(frame, self:getDisplayValue(option) or 1);
		UIDropDownMenu_JustifyText(frame, "LEFT");
	end
	return frame;
end

objectHandlers.multidropdown = function(self, parent, name, virtual, option, ...)
	local frame = CreateFrame("Frame", name, parent, virtual or "UIDropDownMenuTemplate");
	if frame.Left then
		frame.oldSetWidth = frame.SetWidth; frame.SetWidth = dropdownSetWidth; frame.ctDropdownClick = dropdownClick;
	end
	local entries = { ... };
	if UIDropDownMenu_Initialize then
		UIDropDownMenu_Initialize(frame, function()
			local dropdownEntry = {};
			for i = 1, #entries, 2 do
				dropdownEntry.text = entries[i]; dropdownEntry.value = (i+1)/2; dropdownEntry.isNotRadio = true; dropdownEntry.checked = self:getDisplayValue(entries[i+1]); dropdownEntry.func = dropdownClick; dropdownEntry.arg1 = entries[i+1];
				UIDropDownMenu_AddButton(dropdownEntry);
			end
		end);
		UIDropDownMenu_JustifyText(frame, "LEFT");
	end
	return frame;
end

local function updateSliderText(slider, value)
	slider.title:SetText(gsub(slider.titleText, "<value>", floor( ( value or slider:GetValue() )*100+0.5)/100));
end

local function updateSliderValue(self, value)
	local valueStep = self:GetValueStep()
	value = floor(value / valueStep  + 0.5) * valueStep
	updateSliderText(self, value);
	local option = self.option;
	if ( option ) then self.object:setOption(option, value); end
end

objectHandlers.slider = function(self, parent, name, virtual, option, text, values)
	local slider = CreateFrame("Slider", name, parent, virtual or "OptionsSliderTemplate");
	local title, low, high = slider.Text, slider.Low, slider.High;
	local titleText, lowText, highText = splitString(text, colonSeparator);
	local minValue, maxValue, step = splitString(values, colonSeparator);

	minValue, maxValue, step = tonumber(minValue), tonumber(maxValue), tonumber(step);
	slider.title, slider.titleText, slider.object, slider.option = title, titleText, self, option;
	low:SetText(lowText or minValue); high:SetText(highText or maxValue);
	slider:SetMinMaxValues(minValue, maxValue); slider:SetValueStep(step);
	slider:SetValue(self:getDisplayValue(option) or (maxValue-minValue)/2);
	slider:SetScript("OnValueChanged", updateSliderValue);
	updateSliderText(slider);
	return slider;
end

-- MODERNIZED COLOR PICKER FOR DRAGONFLIGHT/THE WAR WITHIN
local function colorSwatchCancel()
	local self = ColorPickerFrame.object;
	if not self then return end
	local r, g, b = self.r or 1, self.g or 1, self.b or 1;
	local a = self.opacity or 1;
	local object, option = self.object, self.option;
	if (type(option) == "function") then option = option(); end
	local colors = object:getDisplayValue(option);
	if (colors) then colors[1], colors[2], colors[3] = r, g, b; colors[4] = a; end
	object:setOption(option, colors);
	if self.normalTexture then self.normalTexture:SetVertexColor(r, g, b); end
end

local function colorSwatchColor(customR, customG, customB)
	local self = ColorPickerFrame.object;
	if not self then return end
	local r, g, b = ColorPickerFrame:GetColorRGB();
	if customR then r, g, b = customR, customG, customB end
	local object, option = self.object, self.option;
	if (type(option) == "function") then option = option(); end
	local colors = object:getDisplayValue(option);
	if (colors) then colors[1], colors[2], colors[3] = r, g, b; else colors = {r, g, b, 1} end
	object:setOption(option, colors);
	if self.normalTexture then self.normalTexture:SetVertexColor(r, g, b); end
end

local function colorSwatchOpacity(customA)
	local self = ColorPickerFrame.object;
	if not self then return end
	local a = OpacitySliderFrame:GetValue();
	if customA then a = customA end
	local object, option = self.object, self.option;
	if (type(option) == "function") then option = option(); end
	local colors = object:getDisplayValue(option) or {self.r, self.g, self.b};
	colors[4] = a;
	object:setOption(option, colors);
end

local function colorSwatchShow(self)
	local r, g, b, a;
	local object, option = self.object, self.option;
	if (type(option) == "function") then option = option(); end
	local color = object:getDisplayValue(option);
	if ( color ) then r, g, b, a = unpack(color); elseif (self:GetNormalTexture()) then r, g, b, a = self:GetNormalTexture():GetVertexColor(); else r, g, b, a = 1, 1, 1, 1; end

	self.r, self.g, self.b, self.opacity = r, g, b, a or 1;
	ColorPickerFrame.object = self;
	
	-- NEW UPDATED API FOR COLOR PICKER
	if ColorPickerFrame.SetupColorPickerAndShow then
		ColorPickerFrame:SetupColorPickerAndShow({
			r = r, g = g, b = b, hasOpacity = self.hasAlpha, opacity = 1 - (a or 1),
			swatchFunc = function() local r,g,b = ColorPickerFrame:GetColorRGB(); colorSwatchColor(r,g,b) end,
			cancelFunc = colorSwatchCancel,
			opacityFunc = function() local a = OpacitySliderFrame:GetValue(); colorSwatchOpacity(1 - a) end
		});
	else
		self.opacityFunc = colorSwatchOpacity; self.swatchFunc = colorSwatchColor; self.cancelFunc = colorSwatchCancel; self.hasOpacity = self.hasAlpha;
		UIDropDownMenuButton_OpenColorPicker(self);
	end
	ColorPickerFrame:SetFrameStrata("TOOLTIP"); ColorPickerFrame:Raise();
end

local function colorSwatchOnClick(self) CloseMenus(); colorSwatchShow(self); end
local function colorSwatchOnEnter(self) self.bg:SetVertexColor(1, 0.82, 0); end
local function colorSwatchOnLeave(self) self.bg:SetVertexColor(1, 1, 1); end

objectHandlers.colorswatch = function(self, parent, name, virtual, option, alpha)
	local swatch = CreateFrame("Button", name, parent, virtual);
	local bg = swatch:CreateTexture(nil, "BACKGROUND");
	local normalTexture = swatch:CreateTexture(nil, "ARTWORK");
	normalTexture:SetTexture("Interface\\ChatFrame\\ChatFrameColorSwatch"); normalTexture:SetAllPoints(swatch); swatch:SetNormalTexture(normalTexture);
	bg:SetColorTexture(1, 1, 1); bg:SetPoint("TOPLEFT", swatch, 1, -1); bg:SetPoint("BOTTOMRIGHT", swatch, 0, 1);
	local color = self:getDisplayValue(option);
	if ( color ) then normalTexture:SetVertexColor(color[1], color[2], color[3]); end
	swatch.bg, swatch.normalTexture = bg, normalTexture; swatch.object, swatch.option, swatch.hasAlpha = self, option, alpha;
	swatch:SetScript("OnLeave", colorSwatchOnLeave); swatch:SetScript("OnEnter", colorSwatchOnEnter); swatch:SetScript("OnClick", colorSwatchOnClick);
	return swatch;
end

local function setAnchor(frame, str)
	local rel, pt, xoff, yoff, relpt = "";
	local tmpVal, found;
	for key, value in iterator(str, colonMatch) do
		if ( not yoff ) then tmpVal = tonumber(value); if ( tmpVal ) then if ( xoff ) then yoff = tmpVal else xoff = tmpVal end; found = true; end end
		if ( not found and not relpt ) then tmpVal = points[value]; if ( tmpVal ) then if ( not pt ) then pt = tmpVal else relpt = tmpVal end; found = true; end end
		if ( not found ) then rel = value; end
		found = nil;
	end
	if ( not relpt ) then relpt = pt; end
	local parent = frame:GetParent();
	if ( pt == "all" ) then frame:SetAllPoints( ( parent and parent[rel] ) or _G[rel] or parent) else frame:SetPoint(pt, ( parent and parent[rel] ) or _G[rel] or parent, relpt, xoff, yoff); end
end

local function setAttributes(self, parent, frame, identifier, option, global, strata, width, height, movable, clamped, hidden, anch1, anch2, anch3, anch4)
	frame.object = self; frame.parent = parent;
	if ( identifier ) then if ( parent ) then parent[identifier] = frame; end; if ( tonumber(identifier) ) then local setID = frame.SetID; if ( setID ) then setID(frame, identifier); end end end
	frame.option = option; frame.global = global;
	if ( strata ) then frame:SetFrameStrata(strata); end
	if ( width ) then frame:SetWidth(width); frame:SetHeight(height); end
	if ( movable ) then frame:SetMovable(true); if frame.SetIsUnrestricted then frame:SetIsUnrestricted(true) end end
	if ( clamped ) then frame:SetClampedToScreen(true); end
	if ( hidden ) then frame:Hide(); end
	if ( anch1 ) then frame:ClearAllPoints(); setAnchor(frame, anch1); if ( anch2 ) then setAnchor(frame, anch2); if ( anch3 ) then setAnchor(frame, anch3); if ( anch4 ) then setAnchor(frame, anch4); end end end end
end

local getConversionTable;
local function convertValue(str)
	if ( not str ) then return elseif ( str == "true" ) then return true elseif ( str == "false" ) then return false elseif ( strlen(str) > 0 ) then local tmp = tonumber(str); if ( not tmp ) then return getConversionTable(splitString(str, commaSeparator)); end; return tmp; else return ""; end
end

getConversionTable = function(...)
	local num = select('#', ...);
	if ( num > 1 ) then local tbl = { }; for i = 1, num, 1 do tinsert(tbl, convertValue(select(i, ...))); end; return tbl; end
	return ...;
end

local specialAttributes = { };
local function generalObjectHandler(self, specializedHandler, str, parent, initialValue, overrideName)
	if ( frameCache[str] ) then return frameCache[str](); end
	lib:clearTable(specialAttributes);
	local identifier, name, explicitParent, option, defaultValue, strata, width, height, movable, clamped, hidden, cache, virtual, localInherit;
	local anch1, anch2, anch3, anch4, specFound; local found;
	for key, value in iterator(str, numberMatch) do
		if ( value == "movable" ) then movable = true elseif ( value == "clamped" ) then clamped = true elseif ( value == "hidden" ) then hidden = true elseif ( value == "cache" ) then cache = true else
			if ( not found and not identifier ) then local i, id = splitString(value, colonSeparator); if ( i == "i" and id ) then identifier = id; found = true; end end
			if ( not found and not option ) then local o, opt, def, glb = splitString(value, colonSeparator); if ( o == "o" and opt ) then option = opt; if ( def ) then defaultValue = convertValue(def); end; found = true; end end
			if ( not found and not strata ) then local st, strta = splitString(value, colonSeparator); if ( st == "st" and strta ) then strata = strta; found = true; end end
			if ( not found and not virtual ) then local v, inherit = splitString(value, colonSeparator); if ( v == "v" and inherit ) then virtual = inherit; found = true; end end
			if ( not found and not localInherit ) then local li, inherit = splitString(value, colonSeparator); if ( li == "li" and inherit ) then localInherit = inherit; found = true; end end
			if ( not found and not name ) then local n, frameName = splitString(value, colonSeparator); if ( n == "n" and frameName ) then name = frameName; found = true; end end
			if ( not found and not explicitParent ) then local p, parentName = splitString(value, colonSeparator); if ( p == "p" and parentName ) then if ( parentName == "nil" ) then explicitParent = "nil" else explicitParent = _G[parentName] end; found = true; end end
			if ( not found and not width ) then local s, w, h = splitString(value, colonSeparator); w, h = tonumber(w), tonumber(h); if ( s == "s" and w and h ) then width, height = w, h; found = true; end end
			if ( not found and not anch4 and not specFound ) then local a = splitString(value, colonSeparator) or value; if ( points[a] ) then if ( not anch1 ) then anch1 = value elseif ( not anch2 ) then anch2 = value elseif ( not anch3 ) then anch3 = value elseif ( not anch4 ) then anch4 = value end; found = true; end end
			if ( not found ) then tinsert(specialAttributes, value); specFound = true; end
		end
		found = nil;
	end
	if ( explicitParent == "nil" ) then parent = nil else parent = explicitParent or parent or UIParent; end
	if (overrideName or name) then name = overrideName or name; end
	anch1 = anch1 or "mid";
	if ( option and defaultValue ) then defaultDisplayValues[self][option] = defaultValue; end
	local frame = specializedHandler(self, parent, name, virtual, option, unpack(specialAttributes));
	if ( localInherit ) then lib:getFrame(initialValue[localInherit], frame); end
	if ( not frame ) then return; elseif ( cache ) then
		local cacheAttributes = {}; for k, v in ipairs(specialAttributes) do tinsert(cacheAttributes, v); end
		local cacheFunc = function()
			local frame = specializedHandler(self, parent, name, virtual, option, unpack(cacheAttributes));
			if ( localInherit ) then lib:getFrame(initialValue[localInherit], frame); end
			setAttributes(self, parent, frame, identifier, option, global, strata, width, height, movable, clamped, hidden, anch1, anch2, anch3, anch4);
			return frame;
		end
		frameCache[str] = cacheFunc;
	end
	setAttributes(self, parent, frame, identifier, option, global, strata, width, height, movable, clamped, hidden, anch1, anch2, anch3, anch4);
	return frame;
end

local function parseStringAttributes(self, str, parent, initialValue, overrideName)
	local objectType, remStr = strmatch(str, numberMatch);
	local handler = objectHandlers[objectType or str];
	if ( handler ) then return generalObjectHandler(self, handler, remStr, parent, initialValue, overrideName); end
end

local function getFrame(self, value, origParent, initialValue, overrideName)
	local parent = origParent; local valueType = type(value);
	if ( valueType == "function" ) then
		local key, val = value(); parent = parseStringAttributes(self, key, parent, val, overrideName);
		if ( parent ) then getFrame(self, val, parent, val); end; return parent;
	elseif ( valueType == "table" ) then
		local lower;
		for key, value in pairs(value) do
			lower = strlower(key);
			if ( lower == "postclick" or lower == "preclick" or match(key, "^on") ) then
				if ( parent ) then parent:SetScript(key, value); if ( lower == "onload" ) then parent.execOnLoad = true; end end
			elseif (lower == "ctonoptionset" ) then
				if ( parent and parent.option and type(value) == "function") then self:registerOptionCallback(parent.option, value) end
			else
				local parent = parent; if ( tonumber(key) == nil ) then parent = parseStringAttributes(self, key, parent, initialValue, overrideName); end
				getFrame(self, value, parent, initialValue);
			end
		end
	elseif ( valueType == "string" ) then
		local found;
		for key, val in iterator(value, pipeMatch) do found = true; parseStringAttributes(self, val, parent, initialValue, overrideName); end
		if ( not found ) then parseStringAttributes(self, value, parent, initialValue, overrideName); end; return parent;
	end
	if ( parent ) then
		local getScript = parent.GetScript;
		if ( getScript ) then
			local onLoad = getScript(parent, "OnLoad"); if ( parent.execOnLoad and type(onLoad) == "function" ) then onLoad(parent); end
			if ( parent:IsVisible() ) then local onShow = getScript(parent, "OnShow"); if ( type(onShow) == "function" ) then onShow(parent); end end
		end
		parent.execOnLoad = nil;
	end
	return parent;
end

function lib:getFrame(value, parent, name) return getFrame(self, value, parent, value, name); end

function lib:framesInit()
	local framesList = {}; local frame = {}; frame.offset = 0; frame.size = 0; frame.details = ""; frame.yoffset = 0; frame.top = 0; frame.data = {};
	tinsert(framesList, frame); return framesList;
end

function lib:framesGetData(framesList)
	if (#framesList > 1) then print(self.name .. ": framesEndFrame missing."); end
	local frame = framesList[#framesList]; return frame.data;
end

function lib:framesAddFrame(framesList, offset, size, details, data) self:framesBeginFrame(framesList, offset, size, details, data); self:framesEndFrame(framesList); end

function lib:framesAddObject(framesList, offset, size, details)
	local frame = framesList[#framesList]; local yoffset = frame.yoffset + offset;
	details = gsub(details, "%%y", yoffset); details = gsub(details, "%%b", yoffset - size); details = gsub(details, "%%s", size);
	tinsert(frame.data, details); frame.yoffset = yoffset - size;
end

function lib:framesAddScript(framesList, name, func) local frame = framesList[#framesList]; frame.data[name] = func; end

function lib:framesBeginFrame(framesList, offset, size, details, data)
	local yoffset; local prevFrame = framesList[#framesList];
	if (prevFrame) then yoffset = prevFrame.yoffset else yoffset = 0 end; yoffset = yoffset + offset;
	local frame = {}; frame.offset = offset; frame.size = size; frame.details = details; frame.yoffset = 0; frame.top = yoffset; frame.data = data or {};
	tinsert(framesList, frame);
end

function lib:framesEndFrame(framesList)
	if (#framesList <= 1) then print(self.name .. ": framesEndFrame found with no matching framesBeginFrame."); return; end
	local frame = tremove(framesList); local size = frame.size; local top = frame.top; local below;
	if (size == 0) then below = top + frame.yoffset; size = top - below; else below = top - size; end
	local details = frame.details; details = gsub(details, "%%y", top); details = gsub(details, "%%b", below); details = gsub(details, "%%s", size);
	local prevFrame = framesList[#framesList]; prevFrame.yoffset = below; prevFrame.data[details] = frame.data;
end

function lib:framesGetYOffset(framesList) local frame = framesList[#framesList]; return frame.yoffset; end

local frameTemplates = {}

function lib:framesAddFromTemplate(framesList, offset, size, details, template, ...)
	local children = self:framesInit()
	frameTemplates[template](self, children, ...)
	local child = children[#children]
	self:framesBeginFrame(framesList, offset, size ~= 0 and size or -child.yoffset, details, child.data)
	self:framesEndFrame(framesList)
end

function frameTemplates.ResetTemplate(self, framesList)
	self:framesAddObject(framesList, 0, 17, "font#tl:5%y#v:GameFontNormalLarge#" .. L["CT_Library/Frames/ResetOptionsTemplate/Heading"])
	self:framesBeginFrame(framesList, -5, 26, "checkbutton#tl:10:%y#i:resetAll#" .. L["CT_Library/Frames/ResetOptionsTemplate/ResetAllCheckbox"])
		self:framesAddScript(framesList, "onclick", function(btn) if (btn:GetChecked()) then btn.text:SetTextColor(1, 0.5, 0.5) else btn.text:SetTextColor(1, 1, 1) end end)
	self:framesEndFrame(framesList)
	self:framesBeginFrame(framesList, 0, 30, "button#t:0:%y#s:120:%s#v:UIPanelButtonTemplate#" .. L["CT_Library/Frames/ResetOptionsTemplate/Button"])
		self:framesAddScript(framesList, "onclick", function(btn) self:resetOptions(btn:GetParent().resetAll:GetChecked()) end)
		self:framesAddScript(framesList, "onenter", function(btn) self:displayTooltip(btn, {L["CT_Library/Frames/ResetOptionsTemplate/Heading"], L["CT_Library/Frames/ResetOptionsTemplate/Line1"]}, "CT_ABOVEBELOW", 0, 0, CTCONTROLPANEL) end)
	self:framesEndFrame(framesList)
	self:framesAddObject(framesList, 0, 3*13, "font#t:0:%y#s:0:%s#l#r#" .. L["CT_Library/Frames/ResetOptionsTemplate/Line1"] .. "#0.9:0.9:0.9")
end

--------------------------------------------
-- AddOn Conflict Resolution

local addOnConflictResolutions = {}
local addOnConflictRequests = {}

function lib:registerConflictResolution(conflict, version, func)
	addOnConflictResolutions[conflict] = addOnConflictResolutions[conflict] or {}; addOnConflictResolutions[conflict][version] = addOnConflictResolutions[conflict][version] or {};
	tinsert(addOnConflictResolutions[conflict][version], func);
	if (addOnConflictRequests[conflict] and addOnConflictRequests[conflict][version]) then func(unpack(addOnConflictRequests[conflict][version])); end
end

function libPublic:requestAddOnConflictResolution(conflict, version, ...)
	assert(type(conflict) == "string", "An AddOn asked CTMod to resolve a conflict, but did not provide a string as the name of the conflict")
	assert(version, "An AddOn asked CTMod to resolve a conflict, but did not provide a version number to ensure future-proofing of this AddOn conflict resolution")
	if (addOnConflictResolutions[conflict] and addOnConflictResolutions[conflict][version]) then for __, func in ipairs(addOnConflictResolutions[conflict][version]) do func(...); end end
	addOnConflictRequests[conflict] = addOnConflictRequests[conflict] or {}; addOnConflictRequests[conflict][version] = {...}
end

-----------------------------------------------
-- Control Panel

local controlPanelFrame; local selectedModule; local previousModule; local minWidth, minHeight, maxWidth, maxHeight = 300, 30, 635, 495; local resizeMaxWidth, resizeMaxHeight = 1100, 900;

local function applyControlPanelLayout(frame)
	if ( not frame ) then return end
	local width = frame:GetWidth() or maxWidth; local height = frame:GetHeight() or maxHeight; local listing = frame.listing; local options = frame.options;
	if ( listing ) then listing:ClearAllPoints(); listing:SetPoint("TOPLEFT", frame, "TOPLEFT", 15, -30); listing:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 15, 15); listing:SetWidth(300); end
	if ( options ) then
		options:ClearAllPoints(); options:SetPoint("TOPLEFT", frame, "TOPLEFT", 320, -30); options:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -15, 15);
		if ( options.scrollchild ) then options.scrollchild:SetWidth(max(300, width - 360)); options.scrollchild:SetHeight(max(450, height - 45)); end
		if ( options.scroll ) then options.scroll:ClearAllPoints(); options.scroll:SetPoint("TOPLEFT", options, 0, 4); options.scroll:SetPoint("BOTTOMRIGHT", options, -26, -10); options.scroll:UpdateScrollChildRect(); end
	end
	if ( frame.ctResizeGrip ) then frame.ctResizeGrip:ClearAllPoints(); frame.ctResizeGrip:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -6, 6); end
	frame.width = width; frame.height = height;
end

local function installControlPanelResizer(frame)
	if ( not frame or frame.ctResizableInstalled ) then return end
	frame.ctResizableInstalled = true; frame:SetResizable(true);
	if frame.SetResizeBounds then frame:SetResizeBounds(maxWidth, maxHeight, resizeMaxWidth, resizeMaxHeight); elseif frame.SetMinResize and frame.SetMaxResize then frame:SetMinResize(maxWidth, maxHeight); frame:SetMaxResize(resizeMaxWidth, resizeMaxHeight); end
	local grip = CreateFrame("Button", nil, frame); grip:SetSize(24, 24); grip:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up"); grip:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight"); grip:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down");
	grip:SetScript("OnMouseDown", function() frame:StartSizing("BOTTOMRIGHT"); end); grip:SetScript("OnMouseUp", function() frame:StopMovingOrSizing(); applyControlPanelLayout(frame); end);
	grip:EnableMouse(true); grip:SetFrameStrata("DIALOG"); grip:SetFrameLevel(frame:GetFrameLevel() + 20); grip:SetHitRectInsets(-8, -8, -8, -8);
	grip:SetScript("OnEnter", function(self) GameTooltip:SetOwner(self, "ANCHOR_LEFT"); GameTooltip:SetText("Resize", 1, 0.82, 0, 1, true); GameTooltip:AddLine("Drag to resize the CT control panel.", 1, 1, 1, true); GameTooltip:Show(); end);
	grip:SetScript("OnLeave", function() GameTooltip:Hide(); end); frame.ctResizeGrip = grip;
	frame:HookScript("OnSizeChanged", function(self) applyControlPanelLayout(self); end); applyControlPanelLayout(frame);
end

local function resizer(self, elapsed)
	if (self.height > minHeight and self.isMinimized) then local newHeight = max(self.height + (minHeight-maxHeight)/0.4*elapsed, minHeight); self:SetHeight(newHeight); self.height = newHeight;
	elseif (self.height < maxHeight and not self.isMinimized) then local newHeight = min(self.height + (maxHeight-minHeight)/0.4*elapsed, maxHeight); self:SetHeight(newHeight); self.height = newHeight;		
	elseif (self.options and self.options:IsShown() and self.width < maxWidth) then local newWidth = min(self.width + (maxWidth-minWidth)/0.4*elapsed, maxWidth); self:SetWidth(newWidth); self.width = newWidth;
	elseif (self.options and self.options:IsShown() and self.alpha < 1 and not self.isMinimized) then local newAlpha = min(self.alpha + 5 * elapsed, 1); self.options:SetAlpha(newAlpha); self.alpha = newAlpha;
	else self:SetScript("OnUpdate", nil); end
end

local function selectControlPanelModule(self)
	local parent = self.parent; local newModule = self:GetID()-700; PlaySound(1115); local module = modules[newModule]; local optionsFrame = module.frame; local isExternal = module.external;
	if ( not module or not optionsFrame ) then return end
	if ( not isExternal ) then
		self.bullet:SetVertexColor(1, 0, 0); local obj, module; local num = 700;
		for key, value in ipairs(modules) do if ( value.frame ) then num = num + 1; obj = parent[tostring(num)]; if ( obj ~= self ) then if ( value.external ) then obj.bullet:SetVertexColor(1, 0.41, 0) else obj.bullet:SetVertexColor(1, 0.82, 0) end end end end
	end
	local frameType = type(optionsFrame); local options = controlPanelFrame.options;
	if ( frameType == "function" ) then
		if ( not isExternal ) then optionsFrame = module:getFrame(optionsFrame, options.scrollchild); options.scroll:UpdateScrollChildRect(); module.frame = optionsFrame; if ( selectedModule ) then optionsFrame:Hide(); end else optionsFrame = module:getFrame(optionsFrame, UIParent); module.frame = optionsFrame; end
	elseif ( frameType == "string" ) then optionsFrame = _G[optionsFrame]; end
	parent = parent.parent; local title = module.displayName or module.name;
	if ( not selectedModule ) then
		if ( not isExternal ) then parent.width = 300; parent.alpha = 0; parent:SetScript("OnUpdate", resizer); local options = parent.options; options:SetAlpha(0); options:Show(); options.title:SetText(title); end
	elseif ( not isExternal ) then parent.options.title:SetText(title); local frame = parent.selectedModuleFrame; if ( frame ) then frame:Hide(); end end
	optionsFrame:Show();
	if ( not isExternal ) then
		parent.selectedModuleFrame = optionsFrame; options.scroll:UpdateScrollChildRect(); selectedModule = newModule;
		if (previousModule ~= selectedModule) then local scrollbar = _G[options.scroll:GetName().."ScrollBar"]; scrollbar:SetValue(0); previousModule = selectedModule; end
	else optionsFrame:Raise(); controlPanelFrame:Hide(); end
end

local function controlPanelSkeleton()
	local modListButtonTemplate = {
		"font#i:text#v:ChatFontNormal#l:16:0", "font#i:version#l:r:-57:0##0.65:0.65:0.65", "texture#i:bullet#l:2:-1#s:7:7#1:1:1",
		["onload"] = function(self) self.bullet:SetVertexColor(1, 0.82, 0); self:SetFontString(self.text); end,
		["onenter"] = function(self) local hover = self.parent.hover; hover:ClearAllPoints(); hover:SetPoint("RIGHT", self); hover:Show(); end,
		["onleave"] = function(self) self.parent.hover:Hide(); end, ["onclick"] = selectControlPanelModule,
	};
	return "frame#st:DIALOG#n:CTCONTROLPANEL#clamped#movable#t:mid:0:400#s:300:495", {
		"backdrop#tooltip#0:0:0:0.80",
		["onshow"] = function(self)
			local module, obj; local selectedModuleFrame = self.selectedModuleFrame; selectedModule = nil; self:SetWidth(300); self.options:Hide(); self.selectedModuleFrame = nil; local listing = self.listing; local num = 700; local version;
			for i = 1, #modules, 1 do
				module = modules[i];
				if ( module.frame ) then
					num = num + 1; version = module.version; obj = listing[tostring(num)]; obj:SetID(num); obj:Show(); obj:SetText(module.displayName or module.name);
					if ( version and version ~= "" ) then obj.version:SetText("|c007F7F7Fv|r"..module.version); end
					if ( module.external ) then obj.bullet:SetVertexColor(1, 0.41, 0) else obj.bullet:SetVertexColor(1, 0.82, 0) end
					if ( num == 15 ) then break end
				end
			end
			for i = num + 1, 715, 1 do listing[tostring(i)]:Hide(); end; PlaySound(1115); eventHandler(lib, "CONTROL_PANEL_VISIBILITY", true);
		end,
		["onhide"] = function(self) PlaySound(1115); local selectedModuleFrame = self.selectedModuleFrame; if ( selectedModuleFrame ) then selectedModuleFrame:Hide(); end; eventHandler(lib, "CONTROL_PANEL_VISIBILITY"); end,
		["button#tl:4:-5#br:tr:-4:-25"] = {
			"font#tl#br:bl:296:0#CTMod Midnight Port", "texture#i:bg#all#1:1:1:0.25#BACKGROUND",
			["button#tr:3:6#s:32:32#"] = {
				["onload"] = function(button) button:SetNormalTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Up"); button:SetDisabledTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Up"); button:SetPushedTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Down"); button:SetHighlightTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Highlight"); end,
				["onclick"] = function() PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON); CTCONTROLPANEL:Hide(); end,
			},
			["button#tr:-18:6#s:32:32#n:CTControlPanelMinimizeButton"] = {
				["onload"] = function(button) button:SetNormalTexture("Interface\\Buttons\\UI-Panel-SmallerButton-Up"); button:SetDisabledTexture("Interface\\Buttons\\UI-Panel-SmallerButton-Up"); button:SetPushedTexture("Interface\\Buttons\\UI-Panel-SmallerButton-Down"); button:SetHighlightTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Highlight"); end,
				["onclick"] = function(button) PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON); lib:toggleMinimizeControlPanel(); end,
			},
			["onenter"] = function(self) lib:displayPredefinedTooltip(self, "DRAG"); self.bg:SetVertexColor(1, 0.9, 0.5); end, ["onleave"] = function(self) self.bg:SetVertexColor(1, 1, 1); end,
			["onmousedown"] = function(self, button) if ( button == "LeftButton" ) then self.parent:StartMoving(); end end,
			["onmouseup"] = function(self, button) if ( button == "LeftButton" ) then self.parent:StopMovingOrSizing() elseif ( button == "RightButton" ) then local parent = self.parent; parent:ClearAllPoints(); parent:SetPoint("CENTER", UIParent); end end,
		},
		["frame#s:300:0#tl:15:-30#b:0:15#i:listing"] = {
			"font#tl:-5:0#s:285:64#" .. L["CT_Library/Introduction"] .. "#t", "texture#tl:0:-64#br:tr:-25:-65#1:1:1", "font#tl:-3:-69#v:GameFontNormalLarge#" .. L["CT_Library/ModListing"], "texture#i:hover#l:5:0#s:290:25#hidden#1:1:1:0.125", "texture#i:select#l:5:0#s:290:25#hidden#1:1:1:0.25",
			["button#i:703#hidden#s:263:25#tl:17:-85"] = modListButtonTemplate, ["button#i:704#hidden#s:263:25#tl:17:-110"] = modListButtonTemplate, ["button#i:705#hidden#s:263:25#tl:17:-135"] = modListButtonTemplate, ["button#i:706#hidden#s:263:25#tl:17:-160"] = modListButtonTemplate, ["button#i:707#hidden#s:263:25#tl:17:-185"] = modListButtonTemplate, ["button#i:708#hidden#s:263:25#tl:17:-210"] = modListButtonTemplate, ["button#i:709#hidden#s:263:25#tl:17:-235"] = modListButtonTemplate, ["button#i:710#hidden#s:263:25#tl:17:-260"] = modListButtonTemplate, ["button#i:711#hidden#s:263:25#tl:17:-285"] = modListButtonTemplate, ["button#i:712#hidden#s:263:25#tl:17:-310"] = modListButtonTemplate, ["button#i:713#hidden#s:263:25#tl:17:-335"] = modListButtonTemplate, ["button#i:714#hidden#s:263:25#tl:17:-360"] = modListButtonTemplate, ["button#i:715#hidden#s:263:25#tl:17:-385"] = modListButtonTemplate, ["button#i:701#hidden#s:263:25#tl:17:-410"] = modListButtonTemplate, ["button#i:702#hidden#s:263:25#tl:17:-435"] = modListButtonTemplate,
		},
		["frame#s:315:0#tr:-15:-30#b:t:15:-480#i:options#hidden"] = {
			["onload"] = function(self)
				local child = CreateFrame("Frame", nil, self); child:SetPoint("TOPLEFT", self); child:SetWidth(300); child:SetHeight(450); self.scrollchild = child;
				local scroll = CreateFrame("ScrollFrame", "CT_LibraryOptionsScrollFrame", self, "UIPanelScrollFrameTemplate"); scroll:SetPoint("TOPLEFT", self, 0, 4); scroll:SetPoint("BOTTOMRIGHT", self, -12, -10); scroll:SetScrollChild(child); self.scroll = scroll;
				local tex = scroll:CreateTexture(scroll:GetName() .. "Track", "BACKGROUND"); tex:SetColorTexture(0, 0, 0, 0.3); tex:ClearAllPoints(); tex:SetPoint("TOPLEFT", _G[scroll:GetName().."ScrollBar"], -1, 17); tex:SetPoint("BOTTOMRIGHT", _G[scroll:GetName().."ScrollBar"], 0, -17);
			end,
			"texture#tl:-5:0#br:bl:-4:0#1:1:1", "font#t:0:20#i:title",
		},
	};
end

local function maximizeControlPanel()
	controlPanelFrame.isMinimized = nil; controlPanelFrame:SetScript("OnUpdate", resizer);
	CTControlPanelMinimizeButton:SetNormalTexture("Interface\\Buttons\\UI-Panel-SmallerButton-Up"); CTControlPanelMinimizeButton:SetDisabledTexture("Interface\\Buttons\\UI-Panel-SmallerButton-Up"); CTControlPanelMinimizeButton:SetPushedTexture("Interface\\Buttons\\UI-Panel-SmallerButton-Down");
	if CT_LibraryOptionsScrollFrameScrollBar then CT_LibraryOptionsScrollFrameScrollBar:Show(); end; CTCONTROLPANEL.listing:Show(); CT_LibraryOptionsScrollFrame:SetScale(1); CT_LibraryOptionsScrollFrame:SetAlpha(1);
end

local function minimizeControlPanel()
	controlPanelFrame.isMinimized = true; controlPanelFrame:SetScript("OnUpdate", resizer); controlPanelFrame:SetClipsChildren(true);
	CTControlPanelMinimizeButton:SetNormalTexture("Interface\\Buttons\\UI-Panel-BiggerButton-Up"); CTControlPanelMinimizeButton:SetDisabledTexture("Interface\\Buttons\\UI-Panel-BiggerButton-Up"); CTControlPanelMinimizeButton:SetPushedTexture("Interface\\Buttons\\UI-Panel-BiggerButton-Down");
	if CT_LibraryOptionsScrollFrameScrollBar then CT_LibraryOptionsScrollFrameScrollBar:Hide(); end; CTCONTROLPANEL.listing:Hide(); CT_LibraryOptionsScrollFrame:SetScale(0.00001); CT_LibraryOptionsScrollFrame:SetAlpha(0);
end

local function displayControlPanel()
	if ( not controlPanelFrame ) then controlPanelFrame = lib:getFrame(controlPanelSkeleton); tinsert(UISpecialFrames, controlPanelFrame:GetName()); controlPanelFrame.height = maxHeight; controlPanelFrame.width = minWidth; controlPanelFrame.alpha = 0; installControlPanelResizer(controlPanelFrame); else installControlPanelResizer(controlPanelFrame); end
	maximizeControlPanel(); applyControlPanelLayout(controlPanelFrame); controlPanelFrame:Show();
end

function libPublic:showControlPanel(show)
	if ( show == "toggle" ) then if ( controlPanelFrame and controlPanelFrame:IsVisible() ) then show = false end end
	if ( show ~= false ) then displayControlPanel() elseif ( controlPanelFrame) then controlPanelFrame:Hide() end
end

function CTMod_OnAddonCompartmentClick(__, button)
	if button == "RightButton" and AddonCompartmentFrame and UIDropDownMenu_Initialize and ToggleDropDownMenu then
		if not CT_AddonCompartmentDropdown then
			CreateFrame("Frame", "CT_AddonCompartmentDropdown", AddonCompartmentFrame, "UIDropDownMenuTemplate")
			UIDropDownMenu_Initialize(CT_AddonCompartmentDropdown, function()
				if (UIDROPDOWNMENU_MENU_LEVEL == 1) then
					for i, mod in lib:iterateModules() do
						if (i>2) then
							local info = {}; info.text = mod.name; info.notCheckable = 1;
							if (mod.externalDropDown_Initialize) then info.hasArrow = 1; info.value = mod.name else info.func = mod.customOpenFunction or function() mod:showModuleOptions() end end
							UIDropDownMenu_AddButton(info)
						end
					end
				elseif (_G[UIDROPDOWNMENU_MENU_VALUE] and _G[UIDROPDOWNMENU_MENU_VALUE].externalDropDown_Initialize) then _G[UIDROPDOWNMENU_MENU_VALUE]:externalDropDown_Initialize(UIDROPDOWNMENU_MENU_LEVEL) end
			end, "MENU")
		end
		ToggleDropDownMenu(1, nil, CT_AddonCompartmentDropdown, AddonCompartmentFrame, -300, 0)
	else lib:showControlPanel("toggle") end
end

function CTMod_OnAddonCompartmentEnter(__, frame) GameTooltip:SetOwner(frame,"ANCHOR_LEFT"); GameTooltip:AddDoubleLine("CTMod", lib:getLibVersion()); GameTooltip:AddLine("Left-click: full options", .8, .8, .8); GameTooltip:AddLine("Right-click: quick menu", .8, .8, .8); GameTooltip:Show(); end
function CTMod_OnAddonCompartmentLeave() GameTooltip:Hide() end

function libPublic:toggleMinimizeControlPanel()
	if (controlPanelFrame) then if (controlPanelFrame.isMinimized) then maximizeControlPanel() else minimizeControlPanel() end end
end

function libPublic:showModuleOptions(useCustomFunction)
	self:showControlPanel(true); if (not lib:IsControlPanelShown()) then return end
	local listing = CTCONTROLPANEL.listing; local button; local num = 700;
	if (useCustomFunction and self.customOpenFunction) then self:showControlPanel(false); self:customOpenFunction() else
		for i, v in ipairs(modules) do if (v.frame) then num = num + 1; if (self == v) then button = listing[tostring(num)]; break end end end
		if (button) then button:Click() end
	end
end

function libPublic:IsControlPanelShown() return controlPanelFrame and controlPanelFrame:IsVisible() end
function lib:isModuleOptionTabSelected() return controlPanelFrame and controlPanelFrame:IsVisible() and modules[selectedModule] == self end
function lib:getControlPanelSelectedModule() return modules[selectedModule] end

lib:updateSlashCmd(displayControlPanel, "/ct", "/ctmod");

-----------------------------------------------
-- Settings Import (1)

local module = { }
module.name = "Settings Import"; module.version = ""; registerPseudoModule(module, 1)
module:regEvent("PLAYER_LOGIN", function() module.displayName = "|cFFFFFFCC" .. L["CT_Library/SettingsImport/Heading"]; end)

local optionsFrame, addonsFrame, checkAllButton, fromChar, clipboardPanel
local importDropdownEntry, importFlaggedCharacters, importRealm, importSetPlayer, importRealm2, importPlayerCount

local function populateAddonsList(char)
	local num = 0
	for key, value in ipairs(modules) do
		if ( value ~= module ) then
			local options = value.options; if ( options and options[char] and next(options[char]) ~= nil) then num = num + 1; local obj = addonsFrame[tostring(num)]; obj:Show(); obj:SetChecked(false); obj.text:SetText(value.name) end
		end
	end
	local numAddons = num; num = num + 1; local obj = optionsFrame.actions; obj:ClearAllPoints(); obj:SetPoint("TOPLEFT", optionsFrame, "TOPLEFT", 0, -180 + (-20 * num)); obj:SetWidth(300); obj:SetHeight(150); obj:Show()
	while ( true ) do obj = addonsFrame[tostring(num)]; if ( not obj ) then break end; obj:Hide(); num = num + 1; end
	fromChar = char; addonsFrame:Show(); local actions = optionsFrame.actions; module:setOption("canImport", nil); module:setOption("canDelete", nil); module:setOption("canExport", nil); actions.confirmImport:SetChecked(false); actions.confirmDelete:SetChecked(false); actions.confirmExport:SetChecked(false);
	if (char == module.getCharKey()) then actions.confirmImport:Hide(); actions.importNote:Hide(); actions.importButton:Hide(); actions.confirmExport:Show(); actions.exportNote:Show(); actions.exportButton:Show(); actions.deleteNote:SetText(L["CT_Library/SettingsImport/Actions/DeleteSelfNote"]) else
		actions.confirmImport:Show(); actions.importNote:Show(); actions.importButton:Show(); actions.confirmExport:Hide(); actions.exportNote:Hide(); actions.exportButton:Hide(); actions.deleteNote:SetText(L["CT_Library/SettingsImport/Actions/DeleteOtherNote"])
	end
	checkAllButton:SetChecked(false); return numAddons;
end

local function populateCharDropdownInit()
	local players = {}; local name, realm, options;
	if ( not importDropdownEntry ) then importDropdownEntry = { }; importFlaggedCharacters = { } else lib:clearTable(importDropdownEntry); lib:clearTable(importFlaggedCharacters); end
	for key, value in ipairs(modules) do options = value.options; if ( options ) then for k, v in pairs(options) do if ( not importFlaggedCharacters[k] ) then name, realm = k:match("^CHAR%-([^-]+)%-(.+)$"); if ( name and realm and realm == importRealm ) then importFlaggedCharacters[k] = true; tinsert(players, k); end end end end end
	sort(players); importPlayerCount = 0;
	for key, value in ipairs(players) do
		name, realm = value:match("^CHAR%-([^-]+)%-(.+)$");
		if ( name and realm ) then
			if (value == module.getCharKey()) then importDropdownEntry.text = "|cffffff00" .. name else importDropdownEntry.text = name end
			importDropdownEntry.value = value; importDropdownEntry.checked = nil; importDropdownEntry.func = dropdownClick; if UIDropDownMenu_AddButton then UIDropDownMenu_AddButton(importDropdownEntry); end
			importPlayerCount = importPlayerCount + 1;
		end
	end
	if (importSetPlayer and importRealm) then local value = players[1]; if CT_LibraryDropdown1 and UIDropDownMenu_SetSelectedValue then UIDropDownMenu_SetSelectedValue(CT_LibraryDropdown1, value); end; populateAddonsList(value); end
	if (importPlayerCount == 0) then if CT_LibraryDropdown1 then CT_LibraryDropdown1:Hide(); CT_LibraryDropdown1Label:SetText("No characters found."); end else if CT_LibraryDropdown1 then CT_LibraryDropdown1:Show(); CT_LibraryDropdown1Label:SetText("Character:"); end end
end

local function populateCharDropdown() if UIDropDownMenu_Initialize and CT_LibraryDropdown1 then UIDropDownMenu_Initialize(CT_LibraryDropdown1, populateCharDropdownInit); end end

local function populateServerDropdownInit()
	local servers = {}; local serversort = {}; local name, realm, options;
	if ( not importDropdownEntry ) then importDropdownEntry = { }; importFlaggedCharacters = { } else lib:clearTable(importDropdownEntry); lib:clearTable(importFlaggedCharacters); end
	for key, value in ipairs(modules) do options = value.options; if ( options ) then for k, v in pairs(options) do if ( not importFlaggedCharacters[k] ) then name, realm = k:match("^CHAR%-([^-]+)%-(.+)$"); if ( name ) then importFlaggedCharacters[k] = true; if (not servers[realm]) then servers[realm] = 1 else servers[realm] = servers[realm] + 1 end end end end end end
	for k, v in pairs(servers) do tinsert(serversort, k); end; sort(serversort);
	for key, value in ipairs(serversort) do importDropdownEntry.text = value .. " (" .. servers[value] .. ")"; importDropdownEntry.value = value; importDropdownEntry.checked = nil; importDropdownEntry.func = dropdownClick; if UIDropDownMenu_AddButton then UIDropDownMenu_AddButton(importDropdownEntry); end end
	importPlayerCount = 0;
	if (not importRealm) then local value = serversort[1]; if (importRealm2) then value = importRealm2; end; if CT_LibraryDropdown0 and UIDropDownMenu_SetSelectedValue then UIDropDownMenu_SetSelectedValue(CT_LibraryDropdown0, value); end; module:update("char", value); end
	if (#serversort == 0) then if CT_LibraryDropdown0 then CT_LibraryDropdown0:Hide(); CT_LibraryDropdown0Label:SetText("No servers found."); end else if CT_LibraryDropdown0 then CT_LibraryDropdown0:Show(); CT_LibraryDropdown0Label:SetText("Server:"); end end
end

local function populateServerDropdown() if UIDropDownMenu_Initialize and CT_LibraryDropdown0 then UIDropDownMenu_Initialize(CT_LibraryDropdown0, populateServerDropdownInit); end end

local function hideAddonsList()
	optionsFrame.actions:Hide(); local num = 1; local obj;
	while ( true ) do obj = addonsFrame[tostring(num)]; if ( not obj ) then break end; obj:Hide(); num = num + 1; end; addonsFrame:Hide();
end

local function addonIsChecked(name)
	local num = 1; local obj;
	while ( true ) do obj = addonsFrame[tostring(num)]; if ( not obj or not obj:IsVisible() ) then return false end; if ( obj.text:GetText() == name ) then return obj:GetChecked(); end; num = num + 1; end
end

local function import()
	if ( fromChar and not InCombatLockdown() ) then
		if (not module:getOption("canImport")) then return end; local charKey = module.getCharKey(); local options, success; local fromOptions;
		for modnum, addon in ipairs(modules) do options = addon.options; if ( options and addon ~= module ) then fromOptions = options[fromChar]; if ( fromOptions and addonIsChecked(addon.name) and module:getOption("canImport") ) then options["CHAR-Unknown- Interim Backup"] = fromChar ~= "CHAR-Unknown- Temporary Backup" and options[charKey] or nil; options[charKey] = {}; lib:copyTable(fromOptions, options[charKey]); success = true; end end end
		module:setOption("canImport", nil); if ( success ) then C_UI.Reload() else print(L["CT_Library/SettingsImport/NoAddonsSelected"]); end
	end
end

local function delete()
	if ( fromChar and not InCombatLockdown()) then
		if (not module:getOption("canDelete")) then return end; local options, success; local fromOptions;
		for modnum, addon in ipairs(modules) do options = addon.options; if ( options and addon ~= module ) then fromOptions = options[fromChar]; if ( fromOptions and addonIsChecked(addon.name) and module:getOption("canDelete") ) then if (fromChar == module.getCharKey()) then options["CHAR-Unknown- Interim Backup"] = fromOptions; end; options[fromChar] = nil; success = true; end end end
		module:setOption("canDelete", nil);
		if ( success ) then
			if (fromChar == module.getCharKey()) then C_UI.Reload() end
			local count = populateAddonsList(fromChar);
			if (count == 0) then importRealm = nil; if CT_LibraryDropdown0 and UIDropDownMenu_GetSelectedValue then importRealm2 = UIDropDownMenu_GetSelectedValue(CT_LibraryDropdown0); end; populateServerDropdown(); importRealm2 = nil; if (importPlayerCount == 0) then importRealm = nil; populateServerDropdown(); end end
		else print(L["CT_Library/SettingsImport/NoAddonsSelected"]); end
	end
end

local function closeClipboardPanel() clipboardPanel:Hide(); clipboardPanel.editBox:SetText(""); end

local function validateClipboard()
	local text = clipboardPanel.editBox:GetText();
	if (strlen(text) < 2) then clipboardPanel.warning:SetText(""); clipboardPanel.acceptButton:Disable();
	elseif (lib:hash(text:sub(2))%64+38 ~= text:byte(1)) then clipboardPanel.warning:SetText(L["CT_Library/SettingsImport/Clipboard/ChecksumAlert"]); clipboardPanel.warning:SetTextColor(0.9, 0.4, 0.4); clipboardPanel.acceptButton:Disable();
	else
		text = lib:decode256From64(text); text = lib:decompress(text); local importTable = lib:deserializeTable(text);
		if (importTable) then
			local warn, found; if (importTable.exportGameVersion ~= lib:getGameVersion(true)) then warn = true; clipboardPanel.warning:SetText(L["CT_Library/SettingsImport/Clipboard/GameVersionWarning"]); clipboardPanel.warning:SetTextColor(0.7, 0.7, 0.3); end
			for key, val in pairs(importTable) do
				local module = lib:getModule(key)
				if (module) then found = true; if (module.version ~= val.exportVersion and warn == nil) then warn = true; clipboardPanel.warning:SetText(L["CT_Library/SettingsImport/Clipboard/AddOnVersionWarning"]); clipboardPanel.warning:SetTextColor(0.7, 0.7, 0.3); end
				elseif (key ~= "exportGameVersion" and warn == nil) then warn = true; clipboardPanel.warning:SetText(L["CT_Library/SettingsImport/Clipboard/AddOnMissingWarning"]); clipboardPanel.warning:SetTextColor(0.7, 0.7, 0.3); end
			end
			if (found) then if (warn == nil) then clipboardPanel.warning:SetText(L["CT_Library/SettingsImport/Clipboard/StringValidMessage"]); clipboardPanel.warning:SetTextColor(0.4, 0.9, 0.4); end; clipboardPanel.acceptButton:Enable(); return importTable; else clipboardPanel.warning:SetText(L["CT_Library/SettingsImport/Clipboard/NoAddOnsAlert"]); clipboardPanel.warning:SetTextColor(0.9, 0.4, 0.4); clipboardPanel.acceptButton:Disable(); end
		else clipboardPanel.warning:SetText(L["CT_Library/SettingsImport/Clipboard/FailureAlert"]); clipboardPanel.warning:SetTextColor(0.9, 0.4, 0.4); clipboardPanel.acceptButton:Disable(); end
	end
end

local function copyFromClipboard()
	local importTable = validateClipboard();
	if (importTable) then
		for __, module in ipairs(modules) do if (module.options and module.name) then if (importTable[module.name]) then module.options["CHAR-Unknown- Import String"] = {}; lib:copyTable(importTable[module.name], module.options["CHAR-Unknown- Import String"]) else module.options["CHAR-Unknown- Import String"] = nil end end end
		importRealm = " Import String"; module:setOption("char", "CHAR-Unknown- Import String"); if UIDropDownMenu_SetText then UIDropDownMenu_SetText(CT_LibraryDropdown0, " Import String (1)"); UIDropDownMenu_SetText(CT_LibraryDropdown1, "Unknown"); end; closeClipboardPanel();
	end
end

local function openClipboardPanel(text)
	if (not clipboardPanel) then
		clipboardPanel = CreateFrame("Frame", nil, CTCONTROLPANEL, "UIPanelDialogTemplate"); clipboardPanel:SetFrameLevel(10); clipboardPanel:SetSize(400, 200); clipboardPanel:SetPoint("CENTER", UIParent); clipboardPanel:EnableMouse(true);
		clipboardPanel.label = clipboardPanel:CreateFontString(nil, "ARTWORK", "ChatFontNormal"); clipboardPanel.label:SetPoint("TOP", 0, -40);
		clipboardPanel.warning = clipboardPanel:CreateFontString(nil, "ARTWORK", "ChatFontNormal"); clipboardPanel.warning:SetPoint("BOTTOM", 0, 60);
		clipboardPanel.acceptButton = CreateFrame("Button", nil, clipboardPanel, "UIPanelButtonTemplate"); clipboardPanel.acceptButton:SetText(CONTINUE); clipboardPanel.acceptButton:SetSize(120, 30); clipboardPanel.acceptButton:SetPoint("BOTTOMRIGHT", clipboardPanel, "BOTTOM", -27, 20); clipboardPanel.acceptButton:HookScript("OnClick", copyFromClipboard);
		clipboardPanel.acceptButton:HookScript("OnEnter", function() lib:displayTooltip(clipboardPanel.acceptButton, {CONTINUE, L["CT_Library/SettingsImport/Clipboard/AcceptTip"]}, "CT_ABOVEBELOW", 0, 0, clipboardPanel); end);
		clipboardPanel.cancelButton = CreateFrame("Button", nil, clipboardPanel, "UIPanelButtonTemplate"); clipboardPanel.cancelButton:SetText(CANCEL); clipboardPanel.cancelButton:SetSize(120, 30); clipboardPanel.cancelButton:SetPoint("BOTTOMLEFT", clipboardPanel, "BOTTOM", 27, 20); clipboardPanel.cancelButton:HookScript("OnClick", closeClipboardPanel);
		clipboardPanel.editBox = CreateFrame("EditBox", nil, clipboardPanel, "InputBoxTemplate"); clipboardPanel.editBox:SetSize(300, 50); clipboardPanel.editBox:SetPoint("CENTER"); clipboardPanel.editBox:SetScript("OnEscapePressed", closeClipboardPanel); clipboardPanel.editBox:SetScript("OnHide", closeClipboardPanel);
	end
	clipboardPanel:Show(); optionsFrame.actions.confirmImport:SetChecked(false); optionsFrame.actions.confirmDelete:SetChecked(false); optionsFrame.actions.confirmExport:SetChecked(false); module:setOption("canImport", nil); module:setOption("canDelete", nil); module:setOption("canExport", nil);
	if (type(text) == "string") then clipboardPanel.editBox:SetScript("OnTextChanged", nil); clipboardPanel.editBox:SetScript("OnEnterPressed", closeClipboardPanel); clipboardPanel.editBox:SetText(text); clipboardPanel.acceptButton:Hide(); clipboardPanel.warning:Hide(); clipboardPanel.label:SetText("Copy the entire string below.|n|cffffff00Warning: it might be possible to identify you from your settings."); clipboardPanel.cancelButton:SetText("Close") else
		clipboardPanel.editBox:SetScript("OnTextChanged", validateClipboard); clipboardPanel.editBox:SetScript("OnEnterPressed", copyFromClipboard); clipboardPanel.editBox:SetText(""); clipboardPanel.acceptButton:Show(); clipboardPanel.warning:Show(); clipboardPanel.label:SetText("Paste the entire string below.|n|cffffff00This is a beta feature; use at own risk."); clipboardPanel.cancelButton:SetText("Cancel")
	end
end

local function export(self)
	if ( fromChar ) then
		if (not module:getOption("canExport")) then return end; local options, success; local exportOptions = {["exportGameVersion"] = lib:getGameVersion(true)}; local fromOptions;
		for modnum, addon in ipairs(modules) do if ( addon ~= module and addon.options and addon.name and addon.version) then fromOptions = addon.options[fromChar]; if ( fromOptions and addonIsChecked(addon.name) and module:getOption("canExport") ) then exportOptions[addon.name] = {["exportVersion"] = addon.version}; lib:copyTable(fromOptions, exportOptions[addon.name]); success = true; end end end
		module:setOption("canExport", nil); if ( not success ) then print(L["CT_Library/SettingsImport/NoAddonsSelected"]); return end
		local text = lib:serializeTable(exportOptions); text = lib:compress(text); text = lib:encode256To64(text); if (text) then openClipboardPanel(text) else print("Sorry, something has gone wrong.") end
	end
end

local numBackupsFound = 0
module:regEvent("ADDON_LOADED", function(__, name)
	if (name == LIBRARY_NAME) then StaticPopupDialogs["CT_RECOVEROPTIONS"] = { text = "Did you recently change %s settings?|nA temporary backup is available until you relog.", button2 = OKAY, button3 = SETTINGS, timeout = 60, OnAlt = function() module:showModuleOptions() end, hideOnEscape = true, enterClicksFirstButton = true, whileDead = true, } else
		local addon = module:getModule(name)
		if (addon) then local options = addon.options or _G[addon.name .. "Options"]; if ( options ) then options["CHAR-Unknown- Import String"] = nil; options["CHAR-Unknown- Temporary Backup"] = options["CHAR-Unknown- Interim Backup"]; options["CHAR-Unknown- Interim Backup"] = nil; if (options["CHAR-Unknown- Temporary Backup"]) then numBackupsFound = numBackupsFound + 1; StaticPopup_Show("CT_RECOVEROPTIONS", numBackupsFound == 1 and name or "CTMod") end end end
	end
end)

function module:update(type, value)
	if ( type == "char" and value ) then local name, realm = value:match("^CHAR%-([^-]+)%-(.+)$"); if (name and realm) then self:setOption("char", nil); populateAddonsList(value) else importRealm = value; hideAddonsList(); self:setOption("char", nil); importSetPlayer = 1; populateCharDropdown(); importSetPlayer = nil; CT_LibraryDropdown1Label:Show(); CT_LibraryDropdown1:Show(); end
	elseif (type == "canDelete") then local actions = optionsFrame.actions; if (value) then actions.deleteButton:Enable(); actions.confirmImport:SetChecked(false); actions.confirmExport:SetChecked(false); module:setOption("canImport", nil); module:setOption("canExport", nil) else actions.deleteButton:Disable() end; actions.confirmDelete:SetChecked(value);
	elseif (type == "canImport") then local actions = optionsFrame.actions; if (value) then actions.importButton:Enable(); actions.confirmDelete:SetChecked(false); actions.confirmExport:SetChecked(false); module:setOption("canDelete", nil); module:setOption("canExport", nil) else actions.importButton:Disable() end; actions.confirmImport:SetChecked(value);
	elseif (type == "canExport") then local actions = optionsFrame.actions; if (value) then actions.exportButton:Enable(); actions.confirmImport:SetChecked(false); actions.confirmDelete:SetChecked(false); module:setOption("canImport", nil); module:setOption("canDelete", nil) else actions.exportButton:Disable() end
	end
end

function module.frame()
	local addonsTable = { };
	local optionsTable = {
		"font#tl:5:-5#v:GameFontNormalLarge#" .. L["CT_Library/SettingsImport/Profiles/Heading"],
		"font#tl:20:-30#v:GameFontNormal#" .. L["CT_Library/SettingsImport/Profiles/InternalSubHeading"],
		"font#tl:40:-50#n:CT_LibraryDropdown0Label#v:ChatFontNormal#" .. L["CT_Library/SettingsImport/Profiles/InternalServerLabel"],
		"dropdown#s:155:20#tl:100:-51#o:char#n:CT_LibraryDropdown0#i:serverDropdown",
		"font#tl:40:-75#n:CT_LibraryDropdown1Label#v:ChatFontNormal#" .. L["CT_Library/SettingsImport/Profiles/InternalCharacterLabel"],
		"dropdown#s:155:20#tl:100:-76#o:char#n:CT_LibraryDropdown1#i:charDropdown",
		"font#tl:20:-100#v:GameFontNormal#" .. L["CT_Library/SettingsImport/Profiles/ExternalSubHeading"],
		["button#t:0:-120#s:150:20#v:UIPanelButtonTemplate#" .. L["CT_Library/SettingsImport/Profiles/ExternalButton"]] = {
			["onclick"] = openClipboardPanel, ["onenter"] = function(button) lib:displayTooltip(button, {L["CT_Library/SettingsImport/Profiles/ExternalButton"],L["CT_Library/SettingsImport/Profiles/ExternalButtonTip"] .. "#0.9:0.9:0.9"},"CT_ABOVEBELOW", 0, 0, CTCONTROLPANEL); end,
		},
		["onload"] = function(self) optionsFrame, addonsFrame = self, self.addons; populateServerDropdown(); populateCharDropdown(); module:setOption("canImport", nil); module:setOption("canDelete", nil); module:setOption("canExport", nil); end,
		["checkbutton#tl:24:-170#s:18:18#i:checkAllButton#Select all"] = {
			["onclick"] = function(button) local num = 1; while (addonsFrame[tostring(num)]) do if (addonsFrame[tostring(num)]:IsShown()) then addonsFrame[tostring(num)]:SetChecked(button:GetChecked()) end; num = num + 1 end end,
			["onload"] = function(button) checkAllButton = button; button:SetAlpha(0.75); button.text:SetFontObject(GameFontNormalSmall) end,
		},
		["frame#tl:0:-150#r#i:addons#hidden"] = addonsTable,
		["frame#i:actions#hidden"] = {
			"font#tl:5:0#i:title#v:GameFontNormalLarge#" .. L["CT_Library/SettingsImport/Actions/Heading"],
			"checkbutton#tl:20:-25#i:confirmImport#s:25:25#o:canImport#I want to IMPORT the selected settings.",
			"font#t:0:-45#i:importNote#s:0:20#l#r#" .. L["CT_Library/SettingsImport/Actions/ImportNote"] .. "#0.5:0.5:0.5",
			["button#t:0:-65#s:155:30#i:importButton#v:UIPanelButtonTemplate#Import Settings"] = { ["onclick"] = import, ["onenter"] = function(self) self:GetParent().importNote:SetTextColor(0.7, 0.7, 0.3) end, ["onleave"] = function(self) self:GetParent().importNote:SetTextColor(0.5, 0.5, 0.5) end },
			"checkbutton#tl:20:-105#i:confirmDelete#s:25:25#o:canDelete#I want to DELETE the selected settings.",
			"font#t:0:-125#i:deleteNote#s:0:20#l#r##0.5:0.5:0.5",
			["button#t:0:-145#s:155:30#i:deleteButton#v:UIPanelButtonTemplate#Delete Settings"] = { ["onclick"] = delete, ["onenter"] = function(self) self:GetParent().deleteNote:SetTextColor(0.9, 0.4, 0.4) end, ["onleave"] = function(self) self:GetParent().deleteNote:SetTextColor(0.5, 0.5, 0.5) end },
			"checkbutton#tl:20:-25#i:confirmExport#s:25:25#o:canExport#I want to EXPORT the selected settings.#hidden",
			"font#t:0:-45#i:exportNote#s:0:20#l#r#" .. L["CT_Library/SettingsImport/Actions/ExportNote"] .. "#0.5:0.5:0.5#hidden",
			["button#t:0:-65#s:155:30#i:exportButton#v:UIPanelButtonTemplate#Generate String#hidden"] = { ["onclick"] = export, ["onenter"] = function(self) self:GetParent().exportNote:SetTextColor(0.7, 0.7, 0.3) end, ["onleave"] = function(self) self:GetParent().exportNote:SetTextColor(0.5, 0.5, 0.5) end },
		},
	};
	tinsert(addonsTable, "font#tl:5:0#v:GameFontNormalLarge#" .. L["CT_Library/SettingsImport/AddOns/Heading"]);
	local num = 0;
	for key, value in ipairs(modules) do if ( value ~= module and value.options ) then num = num + 1; tinsert(addonsTable, "checkbutton#i:"..num.."#tl:20:-"..(num * 20 + 20)); end end
	return "frame#all", optionsTable;
end

-----------------------------------------------
-- Help (2)

local module = { }; module.name = "Help"; module.version = LIBRARY_VERSION; registerPseudoModule(module, 2);
module:regEvent("PLAYER_LOGIN", function() module.displayName = "|cFFFFFFCC" .. L["CT_Library/Help/Heading"]; end);

function module.frame()
	local optionsFrameList = module:framesInit()
	local function helpGetData() return module:framesGetData(optionsFrameList); end
	local function helpAddObject(offset, size, details) module:framesAddObject(optionsFrameList, offset, size, details); end
	local function helpBeginFrame(offset, size, details, data) module:framesBeginFrame(optionsFrameList, offset, size, details, data); end
	local function helpEndFrame() module:framesEndFrame(optionsFrameList); end

	local textColor0, textColor1, textColor2, textColor3 = "1.0:1.0:1.0", "0.9:0.9:0.9", "0.7:0.7:0.7", "1.0:0.4:0.4"
		
	helpBeginFrame(-5, 0, "frame#tl:0:%y#r");
		helpAddObject(  0,   17, "font#tl:5:%y#v:GameFontNormalLarge#" .. L["CT_Library/Help/About/Heading"]);
		helpAddObject( -5, 3*14, "font#tl:10:%y#s:0:%s#l:13:0#r#" .. L["CT_Library/Help/About/Credits"] .. "#" .. textColor1 .. ":l");
		helpAddObject(-15,   14, "font#tl:10:%y#s:0:%s#l:13:0#r#" .. L["CT_Library/Help/About/Updates"] .. "#" .. textColor1 .. ":l");
		helpAddObject( -5,   14, "font#tl:30:%y#s:0:%s#l:13:0#Original CTMod - CurseForge# " .. textColor0 .. ":l");
		helpAddObject( -5,   14, "font#tl:45:%y#s:0:%s#l:13:0#CurseForge.com/WoW/Addons/CTMod# " .. textColor0 .. ":l:265");
		helpAddObject( -5,   14, "font#tl:30:%y#s:0:%s#l:13:0#Original CTMod - GitHub# " .. textColor0 .. ":l");
		helpAddObject( -5,   14, "font#tl:45:%y#s:0:%s#l:13:0#GitHub.com/DDCorkum/CTMod# " .. textColor0 .. ":l:265");
		helpAddObject( -5,   14, "font#tl:30:%y#s:0:%s#l:13:0#Original CTMod - WoWInterface# " .. textColor0 .. ":l");
		helpAddObject( -5,   14, "font#tl:45:%y#s:0:%s#l:13:0#WoWInterface.com/downloads/info3826-CTMod.html# " .. textColor0 .. ":l:265");
	helpEndFrame();
	
	helpBeginFrame(-20, 0, "frame#tl:0:%y#br:tr:0:%b");
		local sNotInstalled = L["CT_Library/Help/WhatIs/NotInstalled"];
		helpAddObject(  0,   17, "font#tl:5:%y#v:GameFontNormalLarge#" .. L["CT_Library/Help/WhatIs/Heading"]);
		helpAddObject( -5,   14, "font#tl:10:%y#s:0:%s#r#" .. L["CT_Library/Help/WhatIs/Line1"] .. "#" .. textColor1 .. ":l");
		if (CT_BarMod and CT_BottomBar) then helpAddObject(-10,   14, "font#tl:30:%y#s:0:%s#r#BarMod (/ctbar) and BottomBar (/ctbb)#" .. textColor0 .. ":l"); helpAddObject(  5, 5*14, "font#tl:30:%y#s:0:%s#r#Changes the appearance of action bars and other UI elements.#" .. textColor2 .. ":l")
		elseif (CT_BarMod) then helpAddObject(-10,   14, "font#tl:30:%y#s:0:%s#r#BarMod (/ctbar)#" .. textColor0 .. ":l"); helpAddObject(  5, 3*14, "font#tl:30:%y#s:0:%s#r#Changes action bars.#" .. textColor2 .. ":l"); helpAddObject(-10,   14, "font#tl:30:%y#s:0:%s#r#BottomBar (" .. sNotInstalled .. ")#" .. textColor3 .. ":l")
		elseif (CT_BottomBar) then helpAddObject(-10,   14, "font#tl:30:%y#s:0:%s#r#BarMod (" .. sNotInstalled .. ")#" .. textColor3 .. ":l"); helpAddObject(-10,   14, "font#tl:30:%y#s:0:%s#r#BottomBar (/ctbb)#" .. textColor0 .. ":l")
		else helpAddObject(-10,   14, "font#tl:30:%y#s:0:%s#r#BarMod and BottomBar (" .. sNotInstalled .. ")#" .. textColor3 .. ":l") end
		if (CT_BuffMod) then helpAddObject(-10,   14, "font#tl:30:%y#s:0:%s#r#BuffMod (/ctbuff)#" .. textColor0 .. ":l") else helpAddObject(-10,   14, "font#tl:30:%y#s:0:%s#r#BuffMod (" .. sNotInstalled .. ")#" .. textColor3 .. ":l") end
		if (CT_Core) then helpAddObject(-10,   14, "font#tl:30:%y#s:0:%s#r#Core (/ctcore)#" .. textColor0 .. ":l") else helpAddObject(-10,   14, "font#tl:30:%y#s:0:%s#r#Core (" .. sNotInstalled .. ")#" .. textColor3 .. ":l") end
		if (CT_ExpenseHistory) then helpAddObject(-10,   14, "font#tl:30:%y#s:0:%s#r#ExpenseHistory (/cteh)#" .. textColor0 .. ":l") else helpAddObject(-10,   14, "font#tl:30:%y#s:0:%s#r#ExpenseHistory (" .. sNotInstalled .. ")#" .. textColor3 .. ":l") end
		if (CT_MailMod) then helpAddObject(-10,   14, "font#tl:30:%y#s:0:%s#r#MailMod (/ctmail)#" .. textColor0 .. ":l") else helpAddObject(-10,   14, "font#tl:30:%y#s:0:%s#r#MailMod (" .. sNotInstalled .. ")#" .. textColor3 .. ":l") end
		if (CT_MapMod) then helpAddObject(-10,   14, "font#tl:30:%y#s:0:%s#r#MapMod (/ctmap)#" .. textColor0 .. ":l") else helpAddObject(-10,   14, "font#tl:30:%y#s:0:%s#r#MapMod (" .. sNotInstalled .. ")#" .. textColor3 .. ":l") end
		if (CT_PartyBuffs and CT_UnitFrames) then helpAddObject(-10,   14, "font#tl:30:%y#s:0:%s#r#PartyBuffs and UnitFrames#" .. textColor0 .. ":l")
		elseif (CT_PartyBuffs) then helpAddObject(-10,   14, "font#tl:30:%y#s:0:%s#r#PartyBuffs (/ctparty)#" .. textColor0 .. ":l")
		elseif (CT_UnitFrames) then helpAddObject(-10,   14, "font#tl:30:%y#s:0:%s#r#UnitFrames (/ctuf)#" .. textColor0 .. ":l")
		else helpAddObject(-10,   14, "font#tl:30:%y#s:0:%s#r#PartyBuffs and UnitFrames (" .. sNotInstalled .. ")#" .. textColor3 .. ":l") end
		if (CT_RaidAssist) then helpAddObject(-10,   14, "font#tl:30:%y#s:0:%s#r#RaidAssist (/ctra)#" .. textColor0 .. ":l") else helpAddObject(-10,   14, "font#tl:30:%y#s:0:%s#r#RaidAssist (" .. sNotInstalled .. ")#" .. textColor3 .. ":l") end
		if (CT_Viewport) then helpAddObject(-10,   14, "font#tl:30:%y#s:0:%s#r#Viewport (/ctvp)#" .. textColor0 .. ":l") else helpAddObject(-10,   14, "font#tl:30:%y#s:0:%s#r#Viewport (" .. sNotInstalled .. ")#" .. textColor3 .. ":l") end		
	helpEndFrame();
	
	return "frame#all", helpGetData();
end