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

--------------------------------------------
-- Classic Compatibility

local function nop() end
local function n0p() return 0 end

-- Class Colors
local GetClassColor = GetClassColor;
do
	-- classic compatibility
	local colors =
	{
		["HUNTER"] = {0.67, 0.83, 0.45, "ffabd473"},
		["WARLOCK"] = {0.53, 0.53, 0.93, "ff8787ed"},
		["PRIEST"] = {1.00, 1.00, 1.00, "ffffffff"},
		["PALADIN"] = {0.96, 0.55, 0.73, "fff58cba"},
		["MAGE"] = {0.25, 0.78, 0.92, "ff40c7eb"},
		["ROGUE"] = {1.00, 0.96, 0.41, "fffff569"},
		["DRUID"] = {1.00, 0.49, 0.04, "ffff7d0a"},
		["SHAMAN"] = {0.00, 0.44, 0.87, "ff0070de"},
		["WARRIOR"] = {0.78, 0.61, 0.43, "ffc79c6e"},
		["DEATHKNIGHT"] = {0.77, 0.12, 0.23, "ffc41f3b"},
		["MONK"] = {0.00, 1.00, 0.59, "ff00ff96"},
		["DEMONHUNTER"] = {0.64, 0.19, 0.79, "ffa330c9"},
		
	}
	GetClassColor = GetClassColor or function(fileName)
		if (fileName and colors[fileName]) then
			return unpack(colors[fileName]);
		else
			return 0.5, 0.5, 0.5, "ff808080";
		end
	end
end

-- Incoming heals and absorbs
local UnitGetTotalAbsorbs = UnitGetTotalAbsorbs or n0p

-- Role icons
local UnitGroupRolesAssigned = UnitGroupRolesAssigned or nop -- doesn't exist in classic
local UnitPhaseReason = UnitPhaseReason	or function(unit) return UnitIsWarModePhased and UnitIsWarModePhased(unit) and 2 or not UnitInPhase(unit) and 0 or nil end	-- compatibility with Classic, BFA and Shadowlands
local GetInspectSpecialization = GetInspectSpecialization or nop
local GetSpecialization = GetSpecialization or nop
local GetSpecializationInfo = GetSpecializationInfo or nop
local GetSpecializationRoleByID = GetSpecializationRoleByID or nop

-- Status messages
local IncomingSummonStatus = (C_IncomingSummon and C_IncomingSummon.IncomingSummonStatus) or n0p


--------------------------------------------
-- Pseudo-Object-Oriented Design

local StaticCTRAReadyCheck		-- Adds features to help you share your ready check status with raid members
local StaticCTRAFrames			-- Wrapper over all raid-frame portions of the addon
local StaticClickCastBroker		-- Brokers what spells a CTRAPlayerFrame object should cast when right-clicked; owned by CTRAFrames
local NewCTRAWindow			-- Set of player frames sharing a common appearance and anchor point; owned by CTRAFrames
local NewCTRAPlayerFrame		-- A single, interactive player frame that is contained in a window; owned by CTRAWindow
local NewCTRATargetFrame		-- A single, interactive target frame that is contained in a window; owned by CTRAWindow


--------------------------------------------
-- Initialization

local MODULE_TOC_NAME, module = ...
local _G = getfenv(0)

local MODULE_TOC_VERSION = strmatch(C_AddOns.GetAddOnMetadata(MODULE_TOC_NAME, "version"), "^([%d.]+)")

module.name = "CT_RaidAssist"
module.version = MODULE_TOC_VERSION

_G[module.name] = module
CT_Library:registerModule(module)

module.text = module.text or { }	-- see localization.lua
local L = module.text

-- In WoW Midnight, unit health/power values can be restricted "secret numbers" (e.g. in combat) that
-- insecure code cannot compare or do arithmetic with. ctSafeNumber returns the value when it is a
-- normal comparable number, or nil when restricted/missing, so callers can skip the bar update
-- instead of crashing with "attempt to compare/perform arithmetic on a secret number value".
local ctSafeNumber = CT_Library.safeValue;	-- shared secret-value sanitizer (see CT_Library.lua); returns nil when restricted
local DebuffTypeColor = CT_Library.DebuffTypeColor;	-- shared fallback (global is nil in Midnight)

-- UnitInRange returns a restricted "secret boolean" to tainted code in Midnight; a boolean test on it
-- throws. Treat an unreadable result as in-range (so the frame just uses its normal color); a real
-- nil/false range result passes through unchanged. See CT_Library.safeBool.
local function inRangeSafe(unit)
	return CT_Library.safeBool(UnitInRange(unit), true);
end

-- triggered by module.update("init")
function module:init()	
	module.CTRAReadyCheck = StaticCTRAReadyCheck()
	module.CTRAFrames = StaticCTRAFrames()
	module.ClickCastBroker = StaticClickCastBroker()
	
	-- placeholder for converting settings from older versions of the addon
	--[[if (not module:getOption("CTRA_LastConversion") or module:getOption("CTRA_LastConversion") < 8.307) then
		module:setOption("CTRA_LastConversion", 8.307)
		
	end--]]
end

-- triggered by CT_Library whenever a setting changes, and upon initialization, to call functions associated with tailoring various functionality as required
function module:update(option, value)
	if (option == "init") then
		module:init()
	else
		StaticCTRAReadyCheck():Update(option, value)
		StaticCTRAFrames():Update(option, value)
	end
end

--produces the options frames
function module.frame()
	-- see CT_Library
	local optionsFrameList = module:framesInit()
		
	-- Ready Check Monitor
	StaticCTRAReadyCheck():Frame(optionsFrameList)

	-- Custom Raid Frames
	StaticCTRAFrames():Frame(optionsFrameList)
	
	-- Reset Options
	module:framesAddFromTemplate(optionsFrameList, -20, 0, "frame#tl:0:%y#br:tr:0:%b#i:ResetFrame", "ResetTemplate")

	-- see CT_Library
	return "frame#all", module:framesGetData(optionsFrameList)
end

local function slashCommand()
	module:showModuleOptions()
end

module:setSlashCmd(slashCommand, "/ctra", "/ctraid", "/ctraidassist")
 

--------------------------------------------
-- Extended Ready Checks

function StaticCTRAReadyCheck()

	-- STATIC PUBLIC INTERFACE
	local obj = { };
	StaticCTRAReadyCheck = function() return obj; end
	
	-- PRIVATE PROPERTIES
	local extendReadyChecks = module:getOption("CTRA_ExtendReadyChecks") ~= false;
	local monitorDurability = module:getOption("CTRA_MonitorDurability") or 50;
	
	local invSlots =
	{
		-- {name, 			point,		relTo,				relPoint, xOff, yOff,		width, height,	leftTexCoord, rightTexCoord, topTexCoord, bottomTexCoord},
		{INVSLOT_HEAD,		"TOP",		"",					"TOP",		0,	-10,		18,	22,			0.0,		0.140625,	0.0,		0.171875},
		{INVSLOT_SHOULDER,	"TOP",		INVSLOT_HEAD,		"BOTTOM",	0,	16,			48,	22,			0.140625,	0.515625,	0.0,		0.171875},
		{INVSLOT_CHEST,		"TOP",		INVSLOT_SHOULDER,	"TOP",		0,	-7,			20,	22,			0.515625,	0.6640625,	0.0,		0.171875},
		{INVSLOT_WRIST,		"TOP",		INVSLOT_SHOULDER,	"BOTTOM",	0,	7,			44,	22,			0.6640625,	1.0,		0.0,		0.171875},
		{INVSLOT_HAND,		"TOP",		INVSLOT_WRIST,		"BOTTOM",	0,	15,			42,	18,			0.0,		0.328125,	0.171875,	0.3046875},
		{INVSLOT_WAIST,		"TOP",		INVSLOT_CHEST,		"BOTTOM",	0,	6,			16,	5,			0.328125,	0.46875,	0.171875,	0.203125},
		{INVSLOT_LEGS,		"TOP",		INVSLOT_WAIST,		"BOTTOM",	0,	2,			29,	20,			0.46875,	0.6875,		0.171875,	0.3203125},
		{INVSLOT_FEET,		"TOP",		INVSLOT_LEGS,		"BOTTOM",	0,	8,			41,	32,			0.6875,		1.0,		0.171875,	0.4140625},
		{INVSLOT_MAINHAND,	"RIGHT",	INVSLOT_WRIST,		"LEFT",		0,	-6,			20,	45,			0.0,		0.140625,	0.3203125,	0.6640625},
		{INVSLOT_OFFHAND,	"LEFT",		INVSLOT_WRIST,		"RIGHT",	0,	10,			25,	31,			0.1875,		0.375,		0.3203125,	0.5546875},
		--{"OffWeapon",		"LEFT",		INVSLOT_WRIST,		"RIGHT",	0,	-6,			20,	45,			0.0,		0.140625,	0.3203125,	0.6640625},
		{INVSLOT_RANGED,	"TOP",		INVSLOT_OFFHAND,	"BOTTOM",	0,	5,			28,	38,			0.1875,		0.3984375,	0.5546875,	0.84375},
	}

	-- PRIVATE METHODS
	local function configureAfterReadyCheckFrame()
		local frame = CreateFrame("Frame", nil, UIParent);
		frame:Hide();
		frame:SetSize(323,97);
		frame:SetPoint("CENTER", 0, -10);
		frame:RegisterEvent("PLAYER_REGEN_DISABLED");
		frame:RegisterEvent("GROUP_LEFT");
		frame:RegisterEvent("READY_CHECK");
		frame:RegisterUnitEvent("READY_CHECK_CONFIRM", "player");
		frame:RegisterEvent("READY_CHECK_FINISHED");
		frame:SetScript("OnEvent",
			function(self, event, arg1)
				if (event == "PLAYER_REGEN_DISABLED") then
					self:Hide();
				elseif (event == "GROUP_LEFT") then
					self:Hide();
				elseif (event == "READY_CHECK") then
					self:Hide();
					SetPortraitTexture(frame.portrait, arg1)
					self.status = GetReadyCheckStatus("player");
					self.initiator = arg1;
				elseif (event == "READY_CHECK_CONFIRM") then
					self.status = GetReadyCheckStatus("player");
				elseif (event == "READY_CHECK_FINISHED") then
					if (extendReadyChecks) then
						if (self.status == "waiting") then
							self:Show();
							self.text:SetText(L["CT_RaidAssist/AfterNotReadyFrame/WasAFK"]);
						elseif (self.status == "notready") then
							self:Show();
							self.text:SetText(L["CT_RaidAssist/AfterNotReadyFrame/WasNotReady"]);
						elseif (not self.status) then
							self:Show();
							SetPortraitTexture(frame.portrait, "player");
							self.text:SetText(L["CT_RaidAssist/AfterNotReadyFrame/MissedCheck"]);
							self.initiator = nil;
						end
					else
						self.initiator = nil;
					end
				end
			end
		);

		frame.portrait = frame:CreateTexture(nil, "BACKGROUND");
		frame.portrait:SetSize(50,50);
		frame.portrait:SetPoint("TOPLEFT", 7, -6);

		frame.texture = frame:CreateTexture(nil, "ARTWORK");
		frame.texture:SetSize(323, 97);
		frame.texture:SetTexture("Interface\\RaidFrame\\UI-ReadyCheckFrame");
		frame.texture:SetTexCoord(0, 0.630859375, 0, 0.7578125);
		frame.texture:SetPoint("TOPLEFT");

		frame.text = frame:CreateFontString(nil, "ARTWORK", "GameFontNormal");
		frame.text:SetSize(240, 0);
		frame.text:SetJustifyV("MIDDLE");
		frame.text:SetPoint("CENTER", frame, "TOP", 20, -35);
		frame.text:SetText("Are you ready now?");

		frame.footnote = frame:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall");
		frame.footnote:SetPoint("BOTTOMRIGHT", -10, 10);
		frame.footnote:SetTextColor(0.35, 0.35, 0.35);
		frame.footnote:SetText("/ctra");

		frame.returnedButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate");
		frame.returnedButton:SetText("Ready");
		frame.returnedButton:SetSize(119, 24);
		frame.returnedButton:SetPoint("TOPRIGHT", frame, "TOP", 13, -55);
		frame.returnedButton:SetScript("OnClick",
			function()
				PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON);
				frame:Hide();
				if (frame.initiator and UnitExists(frame.initiator) and inRangeSafe(frame.initiator)) then
					DoEmote("ready", frame.initiator);
				else
					SendChatMessage("Ready", "RAID");
				end
				frame.initiator = nil;
			end
		);

		frame.goingafkButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate");
		frame.goingafkButton:SetText("Cancel");
		frame.goingafkButton:SetSize(119, 24);
		frame.goingafkButton:SetPoint("TOPLEFT", frame, "TOP", 17, -55);
		frame.goingafkButton:SetScript("OnClick",
			function()
				frame:Hide();
			end
		);
	end
	
	local function configureDurabilityMonitor()
	
		local frame = CreateFrame("Frame", nil, UIParent);
		frame:Hide();
		frame:SetSize(110, 120);
		frame:SetPoint("LEFT", ReadyCheckFrame, "RIGHT", 10, 0);
		frame:RegisterEvent("PLAYER_REGEN_DISABLED");
		frame:RegisterEvent("GROUP_LEFT");
		frame:RegisterEvent("READY_CHECK");
		frame:RegisterUnitEvent("READY_CHECK_CONFIRM", "player");
		frame:RegisterEvent("READY_CHECK_FINISHED");
		frame:RegisterEvent("UPDATE_INVENTORY_DURABILITY");
		frame:SetScript("OnEvent",
			function(__, event)
				if (InCombatLockdown()) then return; end
				if (event == "READY_CHECK") then
					frame:Show();
				else
					frame:Hide();
				end
			end
		);
		
		frame.closeButton = CreateFrame("Button", nil, frame, "SecureHandlerClickTemplate");
		frame.closeButton:SetSize(24, 24);
		frame.closeButton:SetPoint("TOPRIGHT");
		frame.closeButton:SetNormalTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Up");
		frame.closeButton:SetPushedTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Down");
		frame.closeButton:SetHighlightTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Highlight");
		frame.closeButton:SetAttribute("_onclick", [=[ self:GetParent():Hide(); ]=]);
		
		frame.text = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal");
		frame.text:SetPoint("BOTTOM", 0, 24);
		
		for __, bodyPart in ipairs(invSlots) do
			frame[bodyPart[1]] = frame:CreateTexture(nil, "ARTWORK");
			frame[bodyPart[1]]:SetTexture("Interface\\Durability\\UI-Durability-Icons");
			frame[bodyPart[1]]:SetPoint(bodyPart[2], (bodyPart[3] ~= "" and frame[bodyPart[3]]) or frame, bodyPart[4], bodyPart[5], bodyPart[6]);
			frame[bodyPart[1]]:SetSize(bodyPart[7], bodyPart[8]);
			frame[bodyPart[1]]:SetTexCoord(bodyPart[9], bodyPart[10], bodyPart[11], bodyPart[12]);
		end

		frame:SetScript("OnShow", 
			function()
				local worst, worstTex = 100, "";
				for __, bodyPart in ipairs(invSlots) do
					local current, maximum = GetInventoryItemDurability(bodyPart[1]);
					if (maximum and maximum > 0) then
						if (current/maximum * 100 < worst) then
							worst = floor(current/maximum * 100);
							worstTex = GetInventoryItemTexture("player", bodyPart[1]);
						end
						if (current == 0) then
							frame[bodyPart[1]]:SetVertexColor(1.0, 0.0, 0.0, 1.00);
						elseif (current/maximum > monitorDurability/100) then
							frame[bodyPart[1]]:SetVertexColor(1.0, 1.0, 1.0, 1.00 - 0.50 * current / maximum);
						else
							frame[bodyPart[1]]:SetVertexColor(1.0, 1.0, 0.0, 1.00 - 0.50 * current / maximum);
						end
					else
						frame[bodyPart[1]]:SetVertexColor(1.0, 1.0, 1.0, 0.25);
					end
				end
				frame.text:SetText("|T" .. worstTex ..  ":0|t " .. worst .. "%");
				if (worst >= monitorDurability) then
					frame:Hide();
				end
			end
		);
	end
	
	-- PUBLIC METHODS
	
	function obj:Update(option, value)
		if (option == "CTRA_ExtendReadyChecks") then
			extendReadyChecks = value;
		elseif (option == "CTRA_MonitorDurability") then
			monitorDurability = value;
		end
	end
	
	function obj:Frame(optionsFrameList)
		-- helper functions to shorten the code a bit
		local optionsAddObject = function(offset, size, details) module:framesAddObject(optionsFrameList, offset, size, details); end
		local optionsAddTooltip = function(text) module:framesAddScript(optionsFrameList, "onenter", function(obj) module:displayTooltip(obj, text, "CT_ABOVEBELOW", 0, 0, CTCONTROLPANEL); end); end
		local optionsBeginFrame = function(offset, size, details, data) module:framesBeginFrame(optionsFrameList, offset, size, details, data); end
		local optionsEndFrame = function() module:framesEndFrame(optionsFrameList); end
		
		-- commonly used colors
		local textColor1 = "#0.9:0.9:0.9";
		local textColor2 = "#0.7:0.7:0.7";

		-- Heading
		optionsAddObject(-20, 17, "font#tl:5:%y#v:GameFontNormalLarge#" .. L["CT_RaidAssist/Options/ReadyCheckMonitor/Heading"]);
		--optionsAddObject(-5, 2*14, "font#tl:15:%y#s:0:%s#l:13:0#r#" .. L["CT_RaidAssist/Options/ReadyCheckMonitor/Line1"] .. textColor2 .. ":l");
		
		-- Extend overdue readychecks
		optionsBeginFrame(-15, 26, "checkbutton#tl:10:%y#n:CTRA_ExtendReadyChecksCheckButton#o:CTRA_ExtendReadyChecks:1#" .. L["CT_RaidAssist/Options/ReadyCheckMonitor/ExtendReadyChecksCheckButton"] .. "#l:268");
			optionsAddTooltip({L["CT_RaidAssist/Options/ReadyCheckMonitor/ExtendReadyChecksCheckButton"],L["CT_RaidAssist/Options/ReadyCheckMonitor/ExtendReadyChecksTooltip"] .. textColor1});
		optionsEndFrame();
		
		-- Monitor and share durability
		optionsBeginFrame(0, 26, "checkbutton#tl:10:%y#n:CTRA_ShareDurabilityCheckButton#o:CTRA_ShareDurability:true#" .. L["CT_RaidAssist/Options/ReadyCheckMonitor/ShareDurabilityCheckButton"] .. "#l:268");
			optionsAddTooltip({L["CT_RaidAssist/Options/ReadyCheckMonitor/ShareDurabilityCheckButton"],L["CT_RaidAssist/Options/ReadyCheckMonitor/ShareDurabilityTooltip"] .. textColor1});
		optionsEndFrame();
		optionsAddObject(-5, 2*14, "font#tl:15:%y#s:0:%s#l:13:0#r#" .. L["CT_RaidAssist/Options/ReadyCheckMonitor/MonitorDurabilityLabel"] .. textColor2 .. ":l");
		optionsAddObject( -20	, 17, "slider#tl:50:%y#s:200:%s#n:CTRA_MonitorDurabilitySlider#o:CTRA_MonitorDurability:50#" .. L["CT_RaidAssist/Options/ReadyCheckMonitor/MonitorDurabilitySlider"] .. "#0:50:5");


	end
	
	-- PUBLIC CONSTRUCTOR
	do
		configureAfterReadyCheckFrame();
		configureDurabilityMonitor();
		return obj;
	end
end


--------------------------------------------
-- CTRAFrames

function StaticCTRAFrames()

	-- PUBLIC STATIC INTERFACE
	local obj = { };
	StaticCTRAFrames = function() return obj; end
	
	-- private properties, and where applicable their default values
	local windows = { };			-- non-interactive frames that anchor and orient assigned collections of PlayerFrames, TargetFrames and LabelFrames
	local selectedWindow = nil;		-- the currently selected window
	local enabledState;			-- are the raidframes enabled (but possibly hidden if not in a raid)
	local settingsOverlayToStopClicks;	-- button that sits overtop several options to stop interactions with them
	local dummyFrame;			-- pretend CTRAPlayerFrame to illustrate options
	local optionsWaiting = { };		-- options to be applied once combat ends
	local defaultFramesHooked;		-- prevents hooks from being applied multiple times

	-- private methods
	
	-- prevents the default blizzard frames from appearing, and prints a notice if the user tries to use them
	local function hideDefaultFrames()		
		
		-- STEP 1: Hide the frames
		-- STEP 2: Do step 3 once only
		-- STEP 3: Send a message the first time someone tries to show the frames while CT is hiding them
		
		-- STEP 1:
		RegisterStateDriver(CompactRaidFrameContainer, "visibility", "hide");
		
		-- STEP 2:
		if defaultFramesHooked then return; end
		defaultFramesHooked = 1;
		
		-- STEP 3:
		local function forHooking()
			if (module:getOption("CTRAFrames_HideBlizzardDefaultFrames") ~= false and obj:IsEnabled() and defaultFramesHooked == 1) then
				print("Note:|n  CT_RaidAssist is hiding Blizzard's default raid frames.|n  Please type |cFFFFFF00/ctra|r to reconfigure this behaviour");
				defaultFramesHooked = 2;
			end
		end
		for i=1, 8 do
			local button = _G["CompactRaidFrameManagerDisplayFrameFilterOptionsFilterGroup" .. i];
			if (button) then
				button:HookScript("OnClick", forHooking);
			end
		end
		if (CompactRaidFrameManagerDisplayFrameHiddenModeToggle) then
			CompactRaidFrameManagerDisplayFrameHiddenModeToggle:HookScript("OnClick", forHooking);
		end
	end
	
	-- allows the default blizzard frames to reappear
	local function showDefaultFrames()
		
		-- STEP 1: Stop forcing the frames to be hidden
		-- STEP 2: Update them to their natural state
		
		-- STEP 1:
		UnregisterStateDriver(CompactRaidFrameContainer, "visibility");
		
		-- STEP 2:
		--CompactRaidFrameManager_SetSetting("IsShown",CompactUnitFrameProfiles_GetAutoActivationState());    --    (IsInRaid() and true) or (IsInGroup() and CompactRaidFrameManagerDisplayFrameHiddenModeToggle.shownMode) or false);
		--CompactRaidFrameContainer_TryUpdate(CompactRaidFrameContainer);
	end
	
	-- public methods
	function obj:Enable()
		-- STEP 1: if not already enabled, do steps 2-4
		-- STEP 2: create (if necessary) and enable CTRAWindow objects
		-- STEP 3: set a flag to respond positively to IsEnabled() queries
		-- STEP 4: focus the options menu if it is created already (otherwise, this step will occur when it is created)
		-- STEP 5: hide the default ui frames (if appropriate)
		
		--STEP 1:
		if (not self:IsEnabled() and not InCombatLockdown()) then
			
			--STEP 2:
			for i = 1, (module:getOption("CTRAFrames_NumEnabledWindows") or 1) do
				if (not windows[i]) then
					windows[i] = NewCTRAWindow(self);
				end
				windows[i]:Enable(i);
			end
			
			-- STEP 3
			enabledState = true;
			if (not selectedWindow) then
				selectedWindow = 1
			end
			
			-- STEP 4:
			windows[selectedWindow]:Focus();
			if (settingsOverlayToStopClicks) then 
				settingsOverlayToStopClicks:Hide();
			end
			
			-- STEP 5:
			if (module:getOption("CTRAFrames_HideBlizzardDefaultFrames")) then
				hideDefaultFrames();
			end
		end		
	end
	
	function obj:Disable()
		-- STEP 1: if not already disabled, do steps 2-4
		-- STEP 2: disable all current CTRAWindow objects
		-- STEP 3: set a flag to respond negatively to IsEnabled() queries
		-- STEP 4: stop hiding the blizzard default frames
		
		--STEP 1:
		if (self:IsEnabled() and not InCombatLockdown()) then
			--STEP 2:
			for __, window in ipairs(windows) do
				if (window:IsEnabled()) then
					-- the windows are disabled and stored in windows for future use; they are not 'deleted' because WoW won't garbage collect frames
					window:Disable();	-- the window and its assigned content deregisters from all events
				end
			end
			
			-- STEP 3
			enabledState = nil;
			
			if (settingsOverlayToStopClicks) then
				settingsOverlayToStopClicks:Show();
			end
			
			-- STEP 4:
			showDefaultFrames();
		end
	end
	
	function obj:IsEnabled()
		return enabledState;
	end

	function obj:ToggleEnableState (value)
		if (
			(value or module:getOption("CTRAFrames_EnableFrames")) == 1
			or ((value or module:getOption("CTRAFrames_EnableFrames") or 2) == 2 and IsInRaid())  --  default
			or ((value or module:getOption("CTRAFrames_EnableFrames")) == 3 and IsInGroup())
		) then
			self:Enable();
		else
			self:Disable();
		end
	end
		
	function obj:Update(option, value)
		if (option) then
			optionsWaiting[option] = value;
		end
		if (not InCombatLockdown()) then
			for key, val in pairs(optionsWaiting) do
				if (key == "CTRAFrames_EnableFrames") then
					self:ToggleEnableState(val);
				elseif (key == "CTRAFrames_HideBlizzardDefaultFrames") then
					if (val and obj:IsEnabled()) then
						hideDefaultFrames();
					else
						showDefaultFrames();
					end
				elseif (
					key == "CTRAFrames_ClickCast_UseCliqueAddon"
					or key == "CTRAFrames_ClickCast_ToggleMenu"
					or key == "CTRAFrames_ClickCast_Target"
				) then
					--StaticClickCastBroker:Update(key, val); 	-- not currently used
					for __, window in ipairs(windows) do
						window:Update(key, val);		-- all the windows need to update their secureButton
					end
				elseif (key:sub(1,21) == "CTRAFrames_ClickCast_" and key:len() > 21) then
					StaticClickCastBroker():Update(key:sub(22), val);
				end
			end
			wipe(optionsWaiting);
		end
		for i, window in ipairs(windows) do
			if (option) then
				if (strfind(option, "CTRAWindow" .. i .. "_") == 1) then
					window:Update(strsub(option,strfind(option, "_")+1), value);
				end
			else
				window:Update();
			end
		end
		if (dummyFrame and option and strfind(option, "CTRAWindow" .. (selectedWindow or 1) .. "_") == 1) then
			dummyFrame:Update(strsub(option,strfind(option, "_")+1), value);
		end
	end
	
	function obj:Frame(optionsFrameList)
		-- helper functions to shorten the code a bit
		local optionsAddObject = function(offset, size, details) module:framesAddObject(optionsFrameList, offset, size, details); end
		local optionsAddScript = function(name, func) module:framesAddScript(optionsFrameList, name, func); end
		local optionsAddTooltip = function(text, anchor) module:framesAddScript(optionsFrameList, "onenter", function(obj) module:displayTooltip(obj, text, anchor or "CT_ABOVEBELOW", 0, 0, CTCONTROLPANEL); end); end
		local optionsBeginFrame = function(offset, size, details, data) module:framesBeginFrame(optionsFrameList, offset, size, details, data); end
		local optionsEndFrame = function() module:framesEndFrame(optionsFrameList); end
		
		local optionsWindowizeObject = function(property) 
			-- overloads the traditional CT_Library behaviour
			optionsAddScript("onload",
				function(obj)
					obj.option = function() return "CTRAWindow" .. selectedWindow .. "_" .. property; end
				end
			);
		end

		local optionsWindowizeSlider = function(property) 
			-- overloads the traditional CT_Library behaviour; same as above but with .suspend property
			optionsAddScript("onload",
				function(slider)
					slider.option = function()
						if (slider.suspend) then
							return nil;
						else
							return "CTRAWindow" .. selectedWindow .. "_" .. property;
						end
					end
				end
			);
		end
								
		-- commonly used colors
		local textColor1 = "#0.9:0.9:0.9";
		local textColor2 = "#0.7:0.7:0.7";
		local textColor3 = "#1.0:1.0:0.6";	-- subheadings
		
		
		-- Heading
		optionsAddObject(-30, 17, "font#tl:5:%y#v:GameFontNormalLarge#" .. L["CT_RaidAssist/Options/Frames/Heading"]); -- Custom Raid Frames
		
		-- General Options
		optionsAddObject(-20, 15, "font#t:0:%y#n:CTRAFrames_EnableFramesLabel#" .. L["CT_RaidAssist/Options/Frames/EnableLabel"] .. textColor3 .. ":l"); -- Enable custom raid frames
		optionsBeginFrame(-5, 24, "dropdown#t:0:%y#s:150:%s#n:CTRAFrames_EnableFramesDropDown#o:CTRAFrames_EnableFrames:2" .. L["CT_RaidAssist/Options/Frames/EnableDropDown"]);
			optionsAddScript("onload", function(dropdown)
				UIDropDownMenu_JustifyText(dropdown,"CENTER");
			end);
		optionsEndFrame();
		optionsBeginFrame( -15,  20, "checkbutton#tl:10:%y#n:CTRAFrames_HideBlizzardDefaultFramesCheckButton#o:CTRAFrames_HideBlizzardDefaultFrames:true#" .. L["CT_RaidAssist/Options/Frames/HideBlizzardDefaultCheckButton"] .. "#l:268");
			optionsAddTooltip({L["CT_RaidAssist/Options/Frames/HideBlizzardDefaultCheckButton"],L["CT_RaidAssist/Options/Frames/HideBlizzardDefaultTooltip"] .. textColor1});
		optionsEndFrame();

		-- Everything below this line will pseudo-disable when the frames are disabled
		optionsBeginFrame(-5, 0, "frame#tl:0:%y#br:tr:0:%b#n:");
			optionsAddScript("onload",
				function(frame)
					settingsOverlayToStopClicks = CreateFrame("Button", nil, frame);
					settingsOverlayToStopClicks:SetAllPoints();
					settingsOverlayToStopClicks:RegisterForClicks("AnyDown", "AnyUp");
					local tex = settingsOverlayToStopClicks:CreateTexture(nil, "OVERLAY");
					tex:SetAllPoints();
					tex:SetColorTexture(0,0,0,0.50);
					settingsOverlayToStopClicks:SetFrameLevel(25);
					settingsOverlayToStopClicks:HookScript("OnEnter",
						function()
							module:displayTooltip(settingsOverlayToStopClicks, {L["CT_RaidAssist/Options/Frames/DisabledTip"],L["CT_RaidAssist/Options/Frames/EnableLabel"] .. " " .. UIDropDownMenu_GetText(CTRAFrames_EnableFramesDropDown) .. textColor1}, "ANCHOR_CURSOR");
							CTRAFrames_EnableFramesLabel:SetTextColor(1,1,0);
						end
					);
					settingsOverlayToStopClicks:HookScript("OnLeave",
						function()
							CTRAFrames_EnableFramesLabel:SetTextColor(1, 1, 0.6);
						end
					);
				end
			);
		
			-- Click Casting
			optionsAddObject(-15,  17, "font#tl:5:%y#v:GameFontNormal#" .. L["CT_RaidAssist/Options/ClickCast/Heading"]);
			if (Clique) then
				optionsAddObject(-5, 1*14, "font#tl:10:%y#s:0:%s#l:13:0#r#Clique addon detected!#1:0.5:0.5:l");
				optionsAddObject(0,    26, "checkbutton#tl:10:%y#n:CTRAFrames_ClickCast_UseCliqueAddonCheckButton#o:CTRAFrames_ClickCast_UseCliqueAddon:true#Use Clique instead of CTRA keybinds?#1:0.5:0.5:l:268");	
			end
			local buff, removeDebuff, rezCombat, rezNoCombat = StaticClickCastBroker():GetAllSpellsForClass();
			if (#buff > 0) then
				optionsAddObject(-5, 14, "font#tl:15:%y#" .. L["CT_RaidAssist/Options/ClickCast/BuffSubheading"] .. textColor3 .. ":l#v:GameFontNormalSmall");
				for __, details in ipairs(buff) do
					optionsAddObject(-6, 13, "font#tl:15:%y#" .. details.name .. "#0.2:0.8:0.4:l:146#v:GameFontNormalSmall");
					optionsBeginFrame(13, 13, "dropdown#tl:162:%y#s:107:%s#o:CTRAFrames_ClickCast_" .. details.id .. ":" .. details.option .. L["CT_RaidAssist/Options/ClickCast/DropDownOptions"]);
						optionsAddTooltip("spell:" .. details.id);
					optionsEndFrame();
				end
			end
			if (#removeDebuff > 0) then
				optionsAddObject(-10, 14, "font#tl:15:%y#" .. L["CT_RaidAssist/Options/ClickCast/RemoveDebuffSubheading"] .. textColor3 .. ":l#v:GameFontNormalSmall");
				for __, details in ipairs(removeDebuff) do
					optionsAddObject(-6, 14, "font#tl:15:%y#" .. details.name .. "#0.8:0.4:0.4:l:146#v:GameFontNormalSmall");
					optionsBeginFrame(14, 14, "dropdown#tl:162:%y#s:107:%s#o:CTRAFrames_ClickCast_" .. details.id .. ":" .. details.option .. L["CT_RaidAssist/Options/ClickCast/DropDownOptions"]);
						optionsAddTooltip("spell:" .. details.id);
					optionsEndFrame();
				end
			end
			if (#rezCombat > 0) then
				optionsAddObject(-10, 14, "font#tl:15:%y#" .. L["CT_RaidAssist/Options/ClickCast/RezCombatSubheading"] .. textColor3 .. ":l#v:GameFontNormalSmall");
				for __, details in ipairs(rezCombat) do
					optionsAddObject(-6, 14, "font#tl:15:%y#" .. details.name .. "#0.6:0.6:0.6:l:146#v:GameFontNormalSmall");
					optionsBeginFrame(14, 14, "dropdown#tl:162:%y#s:107:%s#o:CTRAFrames_ClickCast_" .. details.id .. ":" .. details.option .. L["CT_RaidAssist/Options/ClickCast/DropDownOptions"]);
						optionsAddTooltip("spell:" .. details.id);
					optionsEndFrame();
				end	
			end
			if (#rezNoCombat > 0) then
				optionsAddObject(-10, 14, "font#tl:15:%y#" .. L["CT_RaidAssist/Options/ClickCast/RezNoCombatSubheading"] .. textColor3 .. ":l#v:GameFontNormalSmall");
				for __, details in ipairs(rezNoCombat) do
					optionsAddObject(-6, 14, "font#tl:15:%y#" .. details.name .. "#0.6:0.6:0.6:l:146#v:GameFontNormalSmall");
					optionsBeginFrame(14, 14, "dropdown#tl:162:%y#s:107:%s#o:CTRAFrames_ClickCast_" .. details.id .. ":" .. details.option .. L["CT_RaidAssist/Options/ClickCast/DropDownOptions"]);
						optionsAddTooltip("spell:" .. details.id);
					optionsEndFrame();
				end
			end
			optionsAddObject(-10, 14, "font#tl:15:%y#" .. L["CT_RaidAssist/Options/ClickCast/UtilitySubheading"] .. textColor3 .. ":l#v:GameFontNormalSmall");
			optionsAddObject(-6, 14, "font#tl:15:%y#" .. L["CT_RaidAssist/Options/ClickCast/ToggleMenuLabel"] .. textColor1 .. ":l:146#v:GameFontNormalSmall");
			optionsAddObject(14, 14, "dropdown#tl:162:%y#s:107:%s#o:CTRAFrames_ClickCast_ToggleMenu:7" .. L["CT_RaidAssist/Options/ClickCast/DropDownOptions"]);
			optionsAddObject(-6, 14, "font#tl:15:%y#" .. L["CT_RaidAssist/Options/ClickCast/TargetLabel"] .. textColor1 .. ":l:146#v:GameFontNormalSmall");
			optionsAddObject(14, 14, "dropdown#tl:162:%y#s:107:%s#o:CTRAFrames_ClickCast_Target:1" .. L["CT_RaidAssist/Options/ClickCast/TargetDropDown"]);

			-- Window Selection
			optionsBeginFrame(0, 0, "frame#tl:0:%y#br:tr:0:%b");

				-- Heading
				optionsAddObject(-15,  17, "font#tl:5:%y#v:GameFontNormal#n:CTRAFrames_SelectedWindowHeading#" .. L["CT_RaidAssist/Options/WindowControls/Heading"]);
				optionsAddObject(-5, 2*14, "font#tl:15:%y#s:0:%s#l:13:0#r#" .. L["CT_RaidAssist/Options/WindowControls/Line1"] .. textColor2 .. ":l");
				
				-- select which window to configure
				optionsAddObject(-10, 14, "font#tl:15:%y#v:ChatFontNormal#" .. L["CT_RaidAssist/Options/WindowControls/SelectionLabel"]);
				optionsBeginFrame(19, 24, "button#tl:105:%y#s:24:%s#n:CTRAFrames_PreviousWindowButton");
					optionsAddScript("onclick",
						function(button)
							if (selectedWindow > 1) then
								selectedWindow = selectedWindow - 1;
								windows[selectedWindow]:Focus();
								UIDropDownMenu_SetText(CTRAFrames_WindowSelectionDropDown, format(L["CT_RaidAssist/WindowTitle"],selectedWindow));
								if (selectedWindow == 1) then
									button:Disable();
								end
								CTRAFrames_NextWindowButton:Enable();
							end
						end
					);
					optionsAddScript("onload",
						function(button)
							button:SetNormalTexture("Interface\\Buttons\\UI-SpellbookIcon-PrevPage-Up");
							button:SetPushedTexture("Interface\\Buttons\\UI-SpellbookIcon-PrevPage-Down");
							button:SetDisabledTexture("Interface\\Buttons\\UI-SpellbookIcon-PrevPage-Disabled");
							button:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight");
							button:Disable();
						end
					);
				optionsEndFrame();
				optionsBeginFrame(24, 24, "button#tl:125:%y#s:24:%s#n:CTRAFrames_NextWindowButton");
					optionsAddScript("onclick",
						function(button)
							if (selectedWindow < (module:getOption("CTRAFrames_NumEnabledWindows") or 1)) then
								selectedWindow = selectedWindow + 1;
								windows[selectedWindow]:Focus();
								UIDropDownMenu_SetText(CTRAFrames_WindowSelectionDropDown, format(L["CT_RaidAssist/WindowTitle"],selectedWindow));
								if (selectedWindow == (module:getOption("CTRAFrames_NumEnabledWindows") or 1)) then
									button:Disable();
								end
								CTRAFrames_PreviousWindowButton:Enable();
							end
						end
					);
					optionsAddScript("onload",
						function(button)
							button:SetNormalTexture("Interface\\Buttons\\UI-SpellbookIcon-NextPage-Up");
							button:SetPushedTexture("Interface\\Buttons\\UI-SpellbookIcon-NextPage-Down");
							button:SetDisabledTexture("Interface\\Buttons\\UI-SpellbookIcon-NextPage-Disabled");
							button:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight");
							if ((module:getOption("CTRAFrames_NumEnabledWindows") or 1) == 1) then
								button:Disable();
							end
						end
					);
				optionsEndFrame();
				optionsBeginFrame(20, 20, "dropdown#tl:140:%y#n:CTRAFrames_WindowSelectionDropDown");
					optionsAddScript("onload",
						function(dropdown)
							UIDropDownMenu_SetText(dropdown, "Window 1");
							UIDropDownMenu_Initialize(dropdown,
								function(frame, level)
									for i=1, (module:getOption("CTRAFrames_NumEnabledWindows") or 1) do
										local dropdownEntry = { }
										dropdownEntry.text = format(L["CT_RaidAssist/WindowTitle"],i);
										dropdownEntry.value = i;
										dropdownEntry.func = function()
											selectedWindow = i;
											print(format(L["CT_RaidAssist/Options/WindowControls/WindowSelectedMessage"],i));
											if ((module:getOption("CTRAFrames_NumEnabledWindows") or 1) == 1) then
												CTRAFrames_PreviousWindowButton:Disable();
												CTRAFrames_NextWindowButton:Disable();
											elseif ((module:getOption("CTRAFrames_NumEnabledWindows") or 1) == selectedWindow) then
												CTRAFrames_PreviousWindowButton:Enable();
												CTRAFrames_NextWindowButton:Disable();
											elseif (selectedWindow == 1) then
												CTRAFrames_PreviousWindowButton:Disable();
												CTRAFrames_NextWindowButton:Enable();
											else
												CTRAFrames_PreviousWindowButton:Enable();
												CTRAFrames_NextWindowButton:Enable();
											end
											windows[i]:Focus();
											UIDropDownMenu_SetText(frame, format(L["CT_RaidAssist/WindowTitle"],i));
										end
										UIDropDownMenu_AddButton(dropdownEntry, level);
									end
								end
							)
						end
					);
				optionsEndFrame();

				-- create a new window
				optionsBeginFrame(-5, 30, "button#tl:15:%y#s:80:%s#v:UIPanelButtonTemplate#" .. L["CT_RaidAssist/Options/WindowControls/AddButton"]);
					optionsAddScript("onclick", 
						function()
							selectedWindow = (module:getOption("CTRAFrames_NumEnabledWindows") or 1) + 1;
							module:setOption("CTRAFrames_NumEnabledWindows", selectedWindow);
							if (not windows[selectedWindow]) then
								windows[selectedWindow] = NewCTRAWindow(self)
							end
							windows[selectedWindow]:Enable(selectedWindow);
							windows[selectedWindow]:Focus();
							UIDropDownMenu_SetText(CTRAFrames_WindowSelectionDropDown, format(L["CT_RaidAssist/WindowTitle"],selectedWindow));
							CTRAFrames_DeleteWindowButton:Enable(); -- the delete button may have been previously disabled if there was only one window available
							CTRAFrames_PreviousWindowButton:Enable();
							CTRAFrames_NextWindowButton:Disable();
							print(format(L["CT_RaidAssist/Options/WindowControls/WindowAddedMessage"],selectedWindow));
						end
					);
					optionsAddTooltip({L["CT_RaidAssist/Options/WindowControls/AddTooltip"] .. "#1:0.82:1"}, "ANCHOR_TOPLEFT");
				optionsEndFrame();
				
				-- clone an existing window
				optionsBeginFrame( 30, 30, "button#tl:110:%y#s:80:%s#v:UIPanelButtonTemplate#" .. L["CT_RaidAssist/Options/WindowControls/CloneButton"]);
					optionsAddScript("onclick", 
						function()
							local windowToClone = selectedWindow;
							selectedWindow = (module:getOption("CTRAFrames_NumEnabledWindows") or 1) + 1;
							module:setOption("CTRAFrames_NumEnabledWindows", selectedWindow);
							if (not windows[selectedWindow]) then
								windows[selectedWindow] = NewCTRAWindow(self);
							end
							windows[selectedWindow]:Enable(selectedWindow, windowToClone);
							windows[selectedWindow]:Focus();
							UIDropDownMenu_SetText(CTRAFrames_WindowSelectionDropDown, format(L["CT_RaidAssist/WindowTitle"],selectedWindow));
							CTRAFrames_DeleteWindowButton:Enable(); -- the delete button may have been previously disabled if there was only one window available
							CTRAFrames_PreviousWindowButton:Enable();
							CTRAFrames_NextWindowButton:Disable();
							print(format(L["CT_RaidAssist/Options/WindowControls/WindowClonedMessage"],selectedWindow));
						end
					);
					optionsAddTooltip({L["CT_RaidAssist/Options/WindowControls/CloneTooltip"] .. "#1:0.82:1#w"}, "ANCHOR_TOPLEFT");
				optionsEndFrame();
				
				-- delete a window
				optionsBeginFrame( 30, 30, "button#tl:205:%y#s:80:%s#v:UIPanelButtonTemplate#" .. L["CT_RaidAssist/Options/WindowControls/DeleteButton"] .. "#n:CTRAFrames_DeleteWindowButton");
					optionsAddScript("onclick", 
						function(button)
							-- make sure the user really means it, and that this isn't the very last window
							if ((module:getOption("CTRAFrames_NumEnabledWindows") or 1) == 1) then
								return;
							end
							
							if (not IsShiftKeyDown()) then
								print(L["CT_RaidAssist/Options/WindowControls/DeleteTooltip"]);
								return;
							end
							
							--delete the window, and push this frame to the end of the table
							local windowToDelete = windows[selectedWindow];
							windowToDelete:Disable(true); -- now the window is disabled, and its settings are also DELETED because the flag was set to true
							module:setOption("CTRAFrames_NumEnabledWindows", (module:getOption("CTRAFrames_NumEnabledWindows") or 1) - 1); -- now we are tracking one fewer window being enabled
							tinsert(windows,tremove(windows,selectedWindow)); -- pushes this frame to the end of the table, beyond numEnabledWindows
							
							-- inform remaining windows of their new positions, and copy saved variable data from their previous positions
							for i=selectedWindow, module:getOption("CTRAFrames_NumEnabledWindows"), 1 do
								windows[i]:Enable(i,i+1); 
							end
							
							-- if we previously deleted the last-most window, then we need to go earlier in the stack
							if (selectedWindow > module:getOption("CTRAFrames_NumEnabledWindows")) then
								-- we are now looking at a non-enabled window that is at the end of the stack (possible the one we just deleted)
								selectedWindow = module:getOption("CTRAFrames_NumEnabledWindows");
							end
							
							-- update the appearance of the options frame
							windows[selectedWindow]:Focus(); -- the options panel should now focus on this window
							UIDropDownMenu_SetText(CTRAFrames_WindowSelectionDropDown, format(L["CT_RaidAssist/WindowTitle"],selectedWindow));
							if (module:getOption("CTRAFrames_NumEnabledWindows") == 1) then
								button:Disable();
								CTRAFrames_PreviousWindowButton:Disable();
								CTRAFrames_NextWindowButton:Disable();
							elseif (selectedWindow == module:getOption("CTRAFrames_NumEnabledWindows")) then
								CTRAFrames_NextWindowButton:Disable();
							elseif (selectedWindow == 1) then
								CTRAFrames_PreviousWindowButton:Disable();
							end
							print(format(L["CT_RaidAssist/Options/WindowControls/WindowDeletedMessage"],windowToDelete));
						end
					);
					optionsAddTooltip({L["CT_RaidAssist/Options/WindowControls/DeleteTooltip"] .. "#1:0.82:1#w"}, "ANCHOR_TOPLEFT");
					optionsAddScript("onshow",
						function(button)
							if ((module:getOption("CTRAFrames_NumEnabledWindows") or 1) == 1) then
								button:Disable();
							end
						end
					);
				optionsEndFrame();
				
			optionsEndFrame();
		
			-- Settings for the current window
			optionsBeginFrame(0, 0, "frame#tl:0:%y#br:tr:0:%b#");
				
				-- Groups, Roles, Classes
				optionsAddObject(-20,   17, "font#tl:5:%y#v:GameFontNormal#" .. L["CT_RaidAssist/Options/Window/Groups/Header"]);
				optionsAddObject(-5, 2*14, "font#tl:15:%y#s:0:%s#l:13:0#r#" .. L["CT_RaidAssist/Options/Window/Groups/Line1"] .. textColor2 .. ":l");
				optionsAddObject(-10,  20, "font#tl:15:%y#s:0:%s#" .. L["CT_RaidAssist/Options/Window/Groups/GroupHeader"] .. textColor1 .. ":l");
				for i=1, 8 do
					optionsBeginFrame( -5,  20, "checkbutton#tl:10:%y#n:CTRAWindow_ShowGroup" .. i .. "CheckButton#Gp " .. i);
						optionsAddScript("onload",
							function(button)
								button.option = function() return "CTRAWindow" .. selectedWindow .. "_ShowGroup" .. i; end
								button:SetFrameLevel(20);
							end
							
						);
						optionsAddTooltip({L["CT_RaidAssist/Options/Window/Groups/GroupTooltipHeader"],L["CT_RaidAssist/Options/Window/Groups/GroupTooltipContent"]}, "CT_BESIDE", 0, 0, CTCONTROLPANEL);
					optionsEndFrame();
				end
				optionsAddObject(220, 20, "font#tl:100:%y#s:0:%s#" .. L["CT_RaidAssist/Options/Window/Groups/RoleHeader"] .. textColor1 .. ":l");
				for __, val in ipairs((module:getGameVersion() >= 5 and {"Myself", "Tanks", "Heals", "Melee", "Range", "Pets"}) or {"Myself", "Pets"}) do
					optionsBeginFrame( -5,  25, "checkbutton#tl:100:%y#n:CTRAWindow_Show" .. val .. "CheckButton#" .. val);
						optionsAddScript("onload",
							function(button)
								button.option = function() return "CTRAWindow" .. selectedWindow .. "_Show" .. val; end
								button:SetFrameLevel(21);
							end
						);
					optionsEndFrame();
				end
				if(module:getGameVersion() < 5) then
					optionsAddObject(-5, 115, "font#tl:100:%y#Sort by tank, \nheals, and dps \nunavailable \nin Classic" .. textColor2 .. ":l");
				end
				optionsAddObject(200, 20, "font#tl:190:%y#s:0:%s#" .. L["CT_RaidAssist/Options/Window/Groups/ClassHeader"] .. textColor1 .. ":l");
				for __, class in ipairs(
					module:getGameVersion() >= 7 and 
						{
							{"DeathKnights", LOCALIZED_CLASS_NAMES_MALE.DEATHKNIGHT},
							{"DemonHunters", LOCALIZED_CLASS_NAMES_MALE.DEMONHUNTER},
							{"Druids", LOCALIZED_CLASS_NAMES_MALE.DRUID},
							{"Hunters", LOCALIZED_CLASS_NAMES_MALE.HUNTER},
							{"Mages", LOCALIZED_CLASS_NAMES_MALE.MAGE},
							{"Monks", LOCALIZED_CLASS_NAMES_MALE.MONK},
							{"Paladins", LOCALIZED_CLASS_NAMES_MALE.PALADIN},
							{"Priests", LOCALIZED_CLASS_NAMES_MALE.PRIEST},
							{"Rogues", LOCALIZED_CLASS_NAMES_MALE.ROGUE},
							{"Shamans", LOCALIZED_CLASS_NAMES_MALE.SHAMAN},
							{"Warlocks", LOCALIZED_CLASS_NAMES_MALE.WARLOCK},
							{"Warriors", LOCALIZED_CLASS_NAMES_MALE.WARRIOR},
						}
					or module:getGameVersion() >= 3 and
						{
							{"DeathKnights", LOCALIZED_CLASS_NAMES_MALE.DEATHKNIGHT},
							{"Druids", LOCALIZED_CLASS_NAMES_MALE.DRUID},
							{"Hunters", LOCALIZED_CLASS_NAMES_MALE.HUNTER},
							{"Mages", LOCALIZED_CLASS_NAMES_MALE.MAGE},
							{"Paladins", LOCALIZED_CLASS_NAMES_MALE.PALADIN},
							{"Priests", LOCALIZED_CLASS_NAMES_MALE.PRIEST},
							{"Rogues", LOCALIZED_CLASS_NAMES_MALE.ROGUE},
							{"Shamans", LOCALIZED_CLASS_NAMES_MALE.SHAMAN},
							{"Warlocks", LOCALIZED_CLASS_NAMES_MALE.WARLOCK},
							{"Warriors", LOCALIZED_CLASS_NAMES_MALE.WARRIOR},
						}
					or 
						{
							{"Druids", LOCALIZED_CLASS_NAMES_MALE.DRUID},
							{"Hunters", LOCALIZED_CLASS_NAMES_MALE.HUNTER},
							{"Mages", LOCALIZED_CLASS_NAMES_MALE.MAGE},
							{"Paladins", LOCALIZED_CLASS_NAMES_MALE.PALADIN},
							{"Priests", LOCALIZED_CLASS_NAMES_MALE.PRIEST},
							{"Rogues", LOCALIZED_CLASS_NAMES_MALE.ROGUE},
							{"Shamans", LOCALIZED_CLASS_NAMES_MALE.SHAMAN},
							{"Warlocks", LOCALIZED_CLASS_NAMES_MALE.WARLOCK},
							{"Warriors", LOCALIZED_CLASS_NAMES_MALE.WARRIOR},
						}
				) do
					optionsBeginFrame( -5, (module:getGameVersion() >= 7 and 15) or 20, "checkbutton#tl:190:%y#n:CTRAWindow_Show" .. class[1] .. "CheckButton#" .. class[2] .. "#l:90");
						optionsAddScript("onload",
							function(button)
								button.option = function() return "CTRAWindow" .. selectedWindow .. "_Show" .. class[1]; end
								button:SetFrameLevel(22);
							end
						);
					optionsEndFrame();
				end
				
				-- Duplicates
				optionsBeginFrame(-5, 26, "checkbutton#tl:10:%y#n:CTRAWindow_ShowDuplicatesOnceOnlyCheckButton:true#" .. L["CT_RaidAssist/Options/Window/Groups/ShowDuplicatesOnceOnlyCheckButton"] .. "#l:268");
					optionsWindowizeObject("ShowDuplicatesOnceOnly");
					optionsAddTooltip({L["CT_RaidAssist/Options/Window/Groups/ShowDuplicatesOnceOnlyCheckButton"],L["CT_RaidAssist/Options/Window/Groups/ShowDuplicatesOnceOnlyTip"] .. textColor1});
				optionsEndFrame();
				
				-- Labels
				optionsBeginFrame(-5, 26, "checkbutton#tl:10:%y#n:CTRAWindow_ShowGroupLabelsCheckButton:true#" .. L["CT_RaidAssist/Options/Window/Groups/ShowGroupLabelsCheckButton"] .. "#l:268");
					optionsWindowizeObject("ShowGroupLabels");
					optionsAddTooltip({L["CT_RaidAssist/Options/Window/Groups/ShowGroupLabelsCheckButton"],L["CT_RaidAssist/Options/Window/Groups/ShowGroupLabelsTip"] .. textColor1});
				optionsEndFrame();
				
				-- Orientation and Wrapping
				optionsAddObject(-5,   17, "font#tl:5:%y#v:GameFontNormal#" .. L["CT_RaidAssist/Options/Window/Layout/Heading"]);
				optionsAddObject(-5, 2*14, "font#tl:15:%y#s:0:%s#l:13:0#r#" .. L["CT_RaidAssist/Options/Window/Layout/Tip"] .. textColor2 .. ":l");
				optionsAddObject(-15, 26, "font#tl:15:%y#" .. L["CT_RaidAssist/Options/Window/Layout/OrientationLabel"] .. textColor1 .. ":l");
				optionsBeginFrame(26,   20, "dropdown#tl:140:%y#s:100:%s#n:CTRAWindow_OrientationDropDown" .. L["CT_RaidAssist/Options/Window/Layout/OrientationDropdown"]);
					optionsWindowizeObject("Orientation");
				optionsEndFrame();
				optionsAddObject(-26, 20, "font#l:tl:15:%y#" .. L["CT_RaidAssist/Options/Window/Layout/WrapLabel"] .. textColor1 .. ":l");
				optionsBeginFrame(26, 17, "slider#tl:160:%y#s:110:%s#n:CTRAWindow_WrapAfterSlider#" .. L["CT_RaidAssist/Options/Window/Layout/WrapSlider"] .. ":2:40#2:40:1");
					optionsWindowizeSlider("WrapAfter");
					optionsAddTooltip({L["CT_RaidAssist/Options/Window/Layout/WrapTooltipHeader"],L["CT_RaidAssist/Options/Window/Layout/WrapTooltipContent"]});
				optionsEndFrame();
				optionsBeginFrame(-10, 15, "checkbutton#tl:40:%y#n:CTRAWindow_GrowUpwardCheckButton#Grow Upward");
					optionsWindowizeObject("GrowUpward");
				optionsEndFrame();
				optionsBeginFrame(15, 15, "checkbutton#tl:160:%y#n:CTRAWindow_GrowLeftCheckButton#Grow Left");
					optionsWindowizeObject("GrowLeft");
				optionsEndFrame();
				
				-- Size and Spacing
				optionsAddObject(-20,   17, "font#tl:5:%y#v:GameFontNormal#Size and Spacing");
				optionsAddObject(-5, 2*14, "font#tl:15:%y#s:0:%s#l:13:0#r#Should frames touch each other, or be spaced apart vertically and horizontally?" .. textColor2 .. ":l");
				optionsBeginFrame(-20, 17, "slider#tl:15:%y#s:130:%s#n:CTRAWindow_HorizontalSpacingSlider#HSpacing = <value>:Touching:Far#0:100:1");
					optionsWindowizeSlider("HorizontalSpacing");
				optionsEndFrame();
				optionsBeginFrame( 17, 17, "slider#tl:160:%y#s:130:%s#n:CTRAWindow_VerticalSpacingSlider#VSpacing = <value>:Touching:Far#0:100:1");
					optionsWindowizeSlider("VerticalSpacing");
				optionsEndFrame();
				optionsAddObject(-30,   20, "font#l:tl:13:%y#r:tl:158:%y#" .. L["CT_RaidAssist/Options/Window/Size/BorderThicknessLabel"] .. textColor1 .. ":l:290");
				optionsBeginFrame(26,   20, "dropdown#tl:140:%y#s:110:%s#n:CTRAWindow_BorderThicknessDropDown" .. L["CT_RaidAssist/Options/Window/Size/BorderThicknessDropDown"]);
					optionsWindowizeObject("BorderThickness");
				optionsEndFrame();
				optionsAddObject(-20, 1*14, "font#tl:15:%y#s:0:%s#l:13:0#r#How big should the frames themselves be?" .. textColor2 .. ":l");
				optionsBeginFrame(-20, 17, "slider#tl:50:%y#s:200:%s#n:CTRAWindow_PlayerFrameScaleSlider#Scale = <value>%:50%:150%#50:150:5");
					optionsWindowizeSlider("PlayerFrameScale");
				optionsEndFrame();

				
				-- Appearance of Player Frames
				optionsAddObject(-20,   17, "font#tl:5:%y#v:GameFontNormal#" .. L["CT_RaidAssist/Options/Window/Appearance/Heading"]);
				optionsAddObject(-5, 2*14, "font#tl:15:%y#s:0:%s#l:13:0#r#" .. L["CT_RaidAssist/Options/Window/Appearance/Line1"] .. textColor2 .. ":l");
				optionsBeginFrame( -5, 30, "button#tl:15:%y#s:80:%s#v:UIPanelButtonTemplate#Classic#n:CTRAWindow_ClassicSchemeButton");
					optionsAddScript("onclick", 
						function()
							local presetClassic =
							{
								"ColorUnitFullHealthCombat",
								"ColorUnitZeroHealthCombat",
								"ColorUnitFullHealthNoCombat",
								"ColorUnitZeroHealthNoCombat",
								"ColorReadyCheckWaiting",
								"ColorReadyCheckNotReady",
								"ColorBackground",
								"ColorBackgroundDeadOrGhost",
								"ColorBackgroundClass",
								"ColorBorder",
								"ColorBorderBeyondRange",
								"ColorBorderClass",
								"BorderThickness",
								"HealthBarAsBackground",
								"EnablePowerBar",
							}
							for __, property in ipairs(presetClassic) do
								module:setOption("CTRAWindow" .. selectedWindow .. "_" .. property, nil);		--the default is to look like classic, so just nil them out
								self:Update("CTRAWindow" .. selectedWindow .. "_" .. property, windows[selectedWindow]:GetProperty(property));	-- forces the window's update function to actually trigger with the default
							end
							windows[selectedWindow]:Focus();
						end
					);
					optionsAddTooltip({"Classic", "Keep the retro look from CTRA in Vanilla: |n- Original color scheme|n- Original health and power bars|n- Health doesn't change color when injured#0.9:0.9:0.9"});
				optionsEndFrame();
				optionsBeginFrame( 30, 30, "button#tl:110:%y#s:80:%s#v:UIPanelButtonTemplate#Hybrid#n:CTRAWindow_HybridSchemeButton");
					optionsAddScript("onclick", 
						function()
							local presetHybrid =
							{
								["ColorUnitFullHealthCombat"] = {0.00, 1.00, 0.00, 0.75},
								["ColorUnitZeroHealthCombat"] = {1.00, 1.00, 0.00, 1.00},
								["ColorUnitFullHealthNoCombat"] = {0.00, 1.00, 0.00, 0.75},
								["ColorUnitZeroHealthNoCombat"] = {0.00, 1.00, 0.00, 1.00},
								["ColorReadyCheckWaiting"] = {0.40, 0.40, 0.40, 0.80},
								["ColorReadyCheckNotReady"] = {0.80, 0.40, 0.40, 0.80},
								["ColorBackground"] = {0.00, 0.05, 0.80, 0.55},
								["BorderThickness"] = 2,
								["HealthBarAsBackground"] = false,
								["EnablePowerBar"] = false,
							}							
							for key, val in pairs(presetHybrid) do
								module:setOption("CTRAWindow" .. selectedWindow .. "_" .. key, val);
							end
							windows[selectedWindow]:Focus();
						end
					);
					optionsAddTooltip({"Hybrid","In-between the classic and modern looks: |n- Health bar changes color a bit when injured|n- No power bar (mana, rage, etc.)|n- In-between color scheme#0.9:0.9:0.9"});
				optionsEndFrame();
				optionsBeginFrame( 30, 30, "button#tl:205:%y#s:80:%s#v:UIPanelButtonTemplate#Modern#n:CTRAWindow_ModernSchemeButton");
					optionsAddScript("onclick", 
						function()
							local presetModern =
							{
								["ColorUnitFullHealthCombat"] = {0.00, 1.00, 0.00, 0.50},
								["ColorUnitZeroHealthCombat"] = {1.00, 0.00, 0.00, 1.00},
								["ColorUnitFullHealthNoCombat"] = {0.00, 1.00, 0.00, 0.00},
								["ColorUnitZeroHealthNoCombat"] = {1.00, 0.00, 0.00, 1.00},
								["ColorReadyCheckWaiting"] = {0.35, 0.35, 0.35, 0.65},
								["ColorReadyCheckNotReady"] = {0.80, 0.35, 0.35, 0.65},
								["ColorBackground"] = {0.00, 0.00, 0.60, 0.60},
								["BorderThickness"] = 1,
								["HealthBarAsBackground"] = true,
								["EnablePowerBar"] = false,
							}						
							for key, val in pairs(presetModern) do
								module:setOption("CTRAWindow" .. selectedWindow .. "_" .. key, val);
							end
							windows[selectedWindow]:Focus();
						end
					);
					optionsAddTooltip({"Modern", "Adopt a modern feel like many retail addons|n- Health bar fills the whole background|n- No power/mana bar|n- Health bar is hidden away outside combat|n- Health bar changes bright colors when injured#0.9:0.9:0.9"});
				optionsEndFrame();
				optionsBeginFrame(-10, 26, "checkbutton#tl:10:%y#n:CTRAWindow_HealthBarAsBackgroundCheckButton:false#" .. L["CT_RaidAssist/Options/Window/Appearance/HealthBarAsBackgroundCheckButton"] .. "#l:268");
					optionsWindowizeObject("HealthBarAsBackground");
					optionsAddTooltip({L["CT_RaidAssist/Options/Window/Appearance/HealthBarAsBackgroundCheckButton"],L["CT_RaidAssist/Options/Window/Appearance/HealthBarAsBackgroundTooltip"] .. textColor1});
				optionsEndFrame();
				optionsBeginFrame(0, 26, "checkbutton#tl:10:%y#n:CTRAWindow_EnablePowerBarCheckButton:true#" .. L["CT_RaidAssist/Options/Window/Appearance/EnablePowerBarCheckButton"] .. "#l:268");
					optionsWindowizeObject("EnablePowerBar");
					optionsAddTooltip({L["CT_RaidAssist/Options/Window/Appearance/EnablePowerBarCheckButton"],L["CT_RaidAssist/Options/Window/Appearance/EnablePowerBarTooltip"] .. textColor1});
				optionsEndFrame();
				optionsBeginFrame(0, 26, "checkbutton#tl:10:%y#n:CTRAWindow_ShowHealthTextCheckButton:false#" .. L["CT_RaidAssist/Options/Window/Appearance/ShowHealthTextCheckButton"] .. "#l:268");
					optionsWindowizeObject("ShowHealthText");
					optionsAddTooltip({L["CT_RaidAssist/Options/Window/Appearance/ShowHealthTextCheckButton"],L["CT_RaidAssist/Options/Window/Appearance/ShowHealthTextTooltip"] .. textColor1});
				optionsEndFrame();
				optionsBeginFrame(0, 26, "checkbutton#tl:10:%y#n:CTRAWindow_EnableTargetFrameCheckButton:true#" .. L["CT_RaidAssist/Options/Window/Appearance/EnableTargetFrameCheckButton"] .. "#l:268");
					optionsWindowizeObject("EnableTargetFrame");
					optionsAddTooltip({L["CT_RaidAssist/Options/Window/Appearance/EnableTargetFrameCheckButton"],L["CT_RaidAssist/Options/Window/Appearance/EnableTargetFrameTooltip"] .. textColor1});
				optionsEndFrame();
				optionsBeginFrame(0, 26, "checkbutton#tl:38:%y#n:CTRAWindow_TargetHealthCheckButton:true#" .. L["CT_RaidAssist/Options/Window/Appearance/TargetHealthCheckButton"] .. "#l:240");
					optionsWindowizeObject("TargetHealth");
					optionsAddTooltip({L["CT_RaidAssist/Options/Window/Appearance/TargetHealthCheckButton"],L["CT_RaidAssist/Options/Window/Appearance/TargetHealthTooltip"] .. textColor1});
				optionsEndFrame();
				optionsBeginFrame(0, 26, "checkbutton#tl:38:%y#n:CTRAWindow_TargetPowerCheckButton:true#" .. L["CT_RaidAssist/Options/Window/Appearance/TargetPowerCheckButton"] .. "#l:240");
					optionsWindowizeObject("TargetPower");
					optionsAddTooltip({L["CT_RaidAssist/Options/Window/Appearance/TargetPowerCheckButton"],L["CT_RaidAssist/Options/Window/Appearance/TargetPowerTooltip"] .. textColor1});
				optionsEndFrame();
				if (UnitGetTotalAbsorbs ~= n0p) then
					optionsAddObject(-21,   20, "font#l:tl:13:%y#r:tl:158:%y#" .. L["CT_RaidAssist/Options/Window/Appearance/ShowTotalAbsorbsLabel"] .. textColor1 .. ":l:290");
					optionsBeginFrame(26,   20, "dropdown#tl:140:%y#s:110:%s#n:CTRAWindow_ShowTotalAbsorbsDropDown" .. L["CT_RaidAssist/Options/Window/Appearance/ShowTotalAbsorbsDropDown"]);
						optionsWindowizeObject("ShowTotalAbsorbs");
						optionsAddTooltip({L["CT_RaidAssist/Options/Window/Appearance/ShowTotalAbsorbsLabel"],L["CT_RaidAssist/Options/Window/Appearance/ShowTotalAbsorbsTip"] .. textColor1});
					optionsEndFrame();	
				end
				optionsAddObject(-21,   20, "font#l:tl:13:%y#r:tl:158:%y#" .. L["CT_RaidAssist/Options/Window/Appearance/ShowIncomingHealsLabel"] .. textColor1 .. ":l:290");
				optionsBeginFrame(26,   20, "dropdown#tl:140:%y#s:110:%s#n:CTRAWindow_ShowIncomingHealsDropDown" .. L["CT_RaidAssist/Options/Window/Appearance/ShowIncomingHealsDropDown"]);
					optionsWindowizeObject("ShowIncomingHeals");
					optionsAddTooltip({L["CT_RaidAssist/Options/Window/Appearance/ShowIncomingHealsLabel"],L["CT_RaidAssist/Options/Window/Appearance/ShowIncomingHealsTip"] .. textColor1});
				optionsEndFrame();	
				
				-- Buffs and Debuffs
				optionsAddObject(-10,   17, "font#tl:5:%y#v:GameFontNormal#" .. L["CT_RaidAssist/Options/Window/Auras/Heading"]);
				optionsAddObject(-21,   20, "font#l:tl:13:%y#r:tl:158:%y#" .. L["CT_RaidAssist/Options/Window/Auras/NoCombatLabel"] .. textColor1 .. ":l:290");
				optionsBeginFrame(26,   20, "dropdown#tl:140:%y#s:110:%s#n:CTRAWindow_AuraFilterNoCombatDropDown" .. L["CT_RaidAssist/Options/Window/Auras/DropDown"]);
					optionsWindowizeObject("AuraFilterNoCombat");
				optionsEndFrame();				
				optionsAddObject(-21,   20, "font#l:tl:13:%y#r:tl:158:%y#" .. L["CT_RaidAssist/Options/Window/Auras/CombatLabel"] .. textColor1 .. ":l:290");
				optionsBeginFrame(26,   20, "dropdown#tl:140:%y#s:110:%s#n:CTRAWindow_AuraFilterCombatDropDown" .. L["CT_RaidAssist/Options/Window/Auras/DropDown"]);
					optionsWindowizeObject("AuraFilterCombat");
				optionsEndFrame();
				optionsBeginFrame(-10, 15, "checkbutton#tl:10:%y#n:CTRAWindow_ShowBossAurasCheckButton#" .. L["CT_RaidAssist/Options/Window/Auras/ShowBossCheckButton"] .. "#l:268");
					optionsWindowizeObject("ShowBossAuras");
					optionsAddTooltip({L["CT_RaidAssist/Options/Window/Auras/ShowBossCheckButton"],L["CT_RaidAssist/Options/Window/Auras/ShowBossTip"] .. textColor1});
				optionsEndFrame();
				optionsBeginFrame(-10, 15, "checkbutton#tl:10:%y#n:CTRAWindow_ShowReverseCooldownCheckButton#" .. L["CT_RaidAssist/Options/Window/Auras/ShowReverseCooldownCheckButton"] .. "#l:268");
					optionsWindowizeObject("ShowReverseCooldown");
					optionsAddTooltip({L["CT_RaidAssist/Options/Window/Auras/ShowReverseCooldownCheckButton"],L["CT_RaidAssist/Options/Window/Auras/ShowReverseCooldownTip"] .. textColor1});
				optionsEndFrame();
				optionsBeginFrame(-10, 15, "checkbutton#tl:10:%y#n:CTRAWindow_RemovableDebuffColorCheckButton#" .. L["CT_RaidAssist/Options/Window/Auras/RemovableDebuffColorCheckButton"] .. "#l:268");
					optionsWindowizeObject("RemovableDebuffColor");
					optionsAddTooltip({L["CT_RaidAssist/Options/Window/Auras/RemovableDebuffColorCheckButton"],L["CT_RaidAssist/Options/Window/Auras/RemovableDebuffColorTip"] .. textColor1});
				optionsEndFrame();
				
				-- Colors
				optionsAddObject(-20, 17, "font#tl:5:%y#v:GameFontNormal#Colors");
				optionsAddObject(-5,  14, "font#tl:15:%y#s:0:%s#l:13:0#r#" .. L["CT_RaidAssist/Options/Window/Color/Line1"] .. textColor2 .. ":l");
				optionsBeginFrame(-10, 0, "frame#tl:0:%y#br:tr:0:%b#");
					optionsAddScript("onload",
						function(frame)
							dummyFrame = NewCTRAPlayerFrame(
								{
									GetProperty = function(__, property)
										if (not selectedWindow) then
											windows[1] = NewCTRAWindow(self);
											selectedWindow = 1;
										end
										if (property) then
											return windows[selectedWindow]:GetProperty(property);
										else
											return nil;
										end
									end,
									GetUnitNameFont = function()
										if (not selectedWindow) then
											windows[1] = NewCTRAWindow(self);
											selectedWindow = 1;
										end
										return windows[selectedWindow]:GetUnitNameFont();
									end,
									GetCountFont = function()
										if (not selectedWindow) then
											windows[1] = NewCTRAWindow(self);
											selectedWindow = 1;
										end
										return windows[selectedWindow]:GetCountFont();
									end,
									GetHealthBarFont = function()
										if (not selectedWindow) then
											windows[1] = NewCTRAWindow(self);
											selectedWindow = 1;
										end
										return windows[selectedWindow]:GetHealthBarFont();
									end,
								},
								frame,
								true	-- this flag informs the frame it is a dummy representation of a real one
							);
							if (not selectedWindow) then
								windows[1] = NewCTRAWindow(self);
								selectedWindow = 1;
								windows[1]:Enable(1);
								windows[1]:Disable();
							end
							dummyFrame:Enable("player", 5, 0);
						end
					);
					for i, item in ipairs({
						{property = "ColorBackground", label = "Background Alive", tooltip = "Background when the unit is alive", hasAlpha = "true"},
						{property = "ColorBackgroundDeadOrGhost", label = "Background Dead", tooltip = "Background when the unit is dead or a ghost", hasAlpha = "true"},
						{property = "ColorBorder", label = "Border In Range", tooltip = "Border when the unit is within 30 yards"},
						{property = "ColorBorderBeyondRange", label = "Border Too Far", tooltip = "Border when the unit is not found within 30 yards"},
						{property = "ColorUnitFullHealthNoCombat", label = "Full Health No Combat", tooltip = "Color of the health bar at 100% outside combat"},
						{property = "ColorUnitZeroHealthNoCombat", label = "Near Death No Combat", tooltip = "Color of the health bar when nearly dead outside combat"},
						-- START OF LEFT COLUMN
						{property = "ColorUnitFullHealthCombat", label = "Full Health Combat", tooltip = "Color of the health bar at 100% during combat"},
						{property = "ColorUnitZeroHealthCombat", label = "Near Death Combat", tooltip = "Color of the health bar when nearly dead during combat"},
					}) do
						optionsBeginFrame((i == 7 and 37) or -5, 16, "colorswatch#tl:" .. ((i > 6 and "0") or "151") .. ":%y#s:16:16#n:CTRAWindow_" .. item.property .. "ColorSwatch#true");  -- the final #true causes it to use alpha
							optionsWindowizeObject(item.property);
							optionsAddScript("onenter",
								function(swatch)
									local r, g, b, a = unpack(windows[selectedWindow]:GetProperty(item.property));
									swatch.bg:SetVertexColor(1, 0.82, 0);
									module:displayTooltip(swatch, {item.tooltip .. "#" .. 1 - ((1-r)/3) .. ":" .. 1 - ((1-g)/3) .. ":" .. 1 - ((1-b)/3) , "Current:  |cFFFF6666r = " .. floor(100*r) .. "%|r, |cFF66FF66g = " .. floor(100*g) .. "%|r, |cFF6666FFb = " .. floor(100*b) .. ((a and ("%|r, |cFFFFFFFFa = " .. floor(100*a) .. "%")) or "%")}, "CT_ABOVEBELOW", 0, 0, CTCONTROLPANEL);
								end
							);
						optionsEndFrame();
						optionsAddObject(16, 16, "font#tl:" .. ((i > 6 and "19") or "170") .. ":%y#s:0:%s#l:13:0#" .. item.label .. textColor1 .. ":l:132");
					end;
				optionsEndFrame();
								
				optionsAddObject(-5, 2*14, "font#tl:15:%y#s:0:%s#l:13:0#r#" .. L["CT_RaidAssist/Options/Window/Color/Line2"] .. textColor2 .. ":l");

				optionsBeginFrame(-15, 17, "slider#tl:15:%y#s:130:%s#n:CTRAWindow_ColorBackgroundClassSlider#" .. L["CT_RaidAssist/Options/Window/Color/BackgroundClassSlider"] .. ":Off:100%#0:100:5");
					optionsWindowizeSlider("ColorBackgroundClass");
					optionsAddTooltip({L["CT_RaidAssist/Options/Window/Color/BackgroundClassHeading"],L["CT_RaidAssist/Options/Window/Color/BackgroundClassTip"] .. textColor1});
				optionsEndFrame();
				optionsBeginFrame(17, 17, "slider#tl:160:%y#s:130:%s#n:CTRAWindow_ColorBorderClassSlider#" .. L["CT_RaidAssist/Options/Window/Color/BorderClassSlider"] .. ":Off:100%#0:100:5");
					optionsWindowizeSlider("ColorBorderClass");
					optionsAddTooltip({L["CT_RaidAssist/Options/Window/Color/BorderClassHeading"],L["CT_RaidAssist/Options/Window/Color/BorderClassTip"] .. textColor1});
				optionsEndFrame();
				
				optionsAddObject(-20,0, "frame#t:0:%y#s:1:1");	-- delete this if ever more options are added underneath
			
			optionsEndFrame();  -- end of the window
			
			-- this is called only once the entire frame has been created
			optionsAddScript("onshow",
				function()
					if (self:IsEnabled()) then
						windows[selectedWindow]:Focus();
						for i=1, (module:getOption("CTRAFrames_NumEnabledWindows") or 1) do
							windows[i]:ShowAnchor();
						end
						settingsOverlayToStopClicks:Hide();
					else
						settingsOverlayToStopClicks:Show();
					end
				end
			);
			
			optionsAddScript("onhide",
				function()
					for i=1, #(windows) do
						windows[i]:HideAnchor();
					end
				end
			);
		optionsEndFrame();  -- end of everything below the "enable CTRA frames" checkbox
		return;  -- nothing is returned because this is entirely encapsulated within the existing optionsFrameList event begun by CTRA:frame()
	end

	function obj:GetDummyFrame()
		return dummyFrame;
	end
	
	-- public constructor
	do
		local function doUpdate()
			obj:ToggleEnableState();
			obj:Update();
		end
		module:regEvent("PLAYER_LOGIN", doUpdate);		-- defers creating the frames until the player is in the game
		module:regEvent("GROUP_ROSTER_UPDATE", doUpdate);	-- the frames might enable only during raids, groups, or always!
		module:regEvent("UNIT_PET", doUpdate);			-- in case the user wishes to display pets as members of the raid
		module:regEvent("PLAYER_REGEN_ENABLED", doUpdate);	-- in case the player's membership in a group/raid changed during combat
		return obj;
	end
end


--------------------------------------------
-- CTRAWindow

function NewCTRAWindow(owningCTRAFrames)	-- local at the top of this file
	
	-- public interface
	local obj = { };

	-- private properties
	local owner = owningCTRAFrames;	-- pointer to the interface of CTRAFrames object that owns this window
	local windowID;			-- nil if disabled, or the number corresponding to which window this is
	local anchorFrame;		-- small movable anchor to orient the window
	local windowFrame;		-- appearance of the window itself
	local playerFrames = { };	-- CTRAPlayerFrame objects
	local targetFrames = { };	-- CTRATargetFrame objects
	local nameFont;			-- Font object shared by all player and target frames within this window for the unit name
	local countFont;		-- Font object shared by all buff frames within this window for the stacks count
	local healthBarFont;		-- Font object shared by all health bars within this window for the health percentage
	local labels = { };		-- FontStrings above each group
	local roster = { };		-- list of the current raid or group used when constructing CTRAPlayerFrame and CTRATargetFrame objects
	local currentOptions = { };	-- current options of this window
	local pendingOptions = { };	-- options awaiting application to this window

	local defaultOptions = 		-- configuration data for the default options in showing a window
	{
		["ShowGroup1"] = true,		-- default is to show groups 1 to 8
		["ShowGroup2"] = true,
		["ShowGroup3"] = true,
		["ShowGroup4"] = true,
		["ShowGroup5"] = true,
		["ShowGroup6"] = true,
		["ShowGroup7"] = true,
		["ShowGroup8"] = true,
		["ShowMyself"] = false,
		["ShowTanks"] = false,
		["ShowHeals"] = false,
		["ShowMelee"] = false,
		["ShowRange"] = false,
		["ShowPets"] = false,
		["ShowDeathKnights"] = false,
		["ShowDemonHunters"] = false,
		["ShowDruids"] = false,
		["ShowHunters"] = false,
		["ShowMages"] = false,
		["ShowMonks"] = false,
		["ShowPaladins"] = false,
		["ShowPriests"] = false,
		["ShowRogues"] = false,
		["ShowShamans"] = false,
		["ShowWarlocks"] = false,
		["ShowWarriors"] = false,
		["ShowDuplicatesOnceOnly"] = true,
		["ShowGroupLabels"] = false,
		["Orientation"] = 1,		-- columns
		["GrowUpward"] = false,
		["GrowLeft"] = false,
		["WrapAfter"] = 5,
		["HorizontalSpacing"] = 4,
		["VerticalSpacing"] = 4,
		["PlayerFrameScale"] = 100,
		["ColorUnitFullHealthCombat"] = {0.00, 1.00, 0.00, 1.00},
		["ColorUnitZeroHealthCombat"] = {0.00, 1.00, 0.00, 1.00},
		["ColorUnitFullHealthNoCombat"] = {0.00, 1.00, 0.00, 1.00},
		["ColorUnitZeroHealthNoCombat"] = {0.00, 1.00, 0.00, 1.00},
		["ColorBackground"] = {0.00, 0.10, 0.90, 0.50},
		["ColorBackgroundDeadOrGhost"] = {0.10, 0.10, 0.10, 0.50},
		["ColorBackgroundClass"] = 0,
		["ColorBorder"] = {1.00, 1.00, 1.00, 0.75},
		["ColorBorderBeyondRange"] = {0.10, 0.10, 0.10, 0.75},
		["ColorBorderClass"] = 0,
		["ColorReadyCheckWaiting"] = {0.45, 0.45, 0.45, 1.00},
		["ColorReadyCheckNotReady"] = {0.80, 0.45, 0.45, 1.00},
		["BorderThickness"] = 3, 	-- thick
		["RemovableDebuffColor"] = true,
		["HealthBarAsBackground"] = false,
		["EnablePowerBar"] = true,
		["AuraFilterNoCombat"] = 1,
		["AuraFilterCombat"] = 2,
		["ShowBossAuras"] = true,
		["ShowReverseCooldown"] = true,
		["EnableTargetFrame"] = false,
		["TargetHealth"] = false,
		["TargetPower"] = false,
		["ShowTotalAbsorbs"] = 1,
		["ShowIncomingHeals"] = 1,
		["ShowHealthText"] = false,
	};

	local groupTypeFuncs =
	{	-- Constants and sorting functions used in obj:Update()
		-- {
		--	[1] = property,			-- name of the associated saved variable to check for, if this category is to be displayed
		--	[2] = sortFunc,			-- function to determine which units are included, receiving a rosterEntry as an argument
		--	[3] = labelText,		-- label to show if ShowLabels is true
		--	[4] = labelAbbrText,		-- abbreviated label to show when multiple groups/classes/roles appear in the same column or row
		-- }

		{"ShowGroup1", function(rosterEntry) return rosterEntry.group == 1; end, "Group 1", "1",},
		{"ShowGroup2", function(rosterEntry) return rosterEntry.group == 2; end, "Group 2", "2",},
		{"ShowGroup3", function(rosterEntry) return rosterEntry.group == 3; end, "Group 3", "3",},
		{"ShowGroup4", function(rosterEntry) return rosterEntry.group == 4; end, "Group 4", "4",},
		{"ShowGroup5", function(rosterEntry) return rosterEntry.group == 5; end, "Group 5", "5",},
		{"ShowGroup6", function(rosterEntry) return rosterEntry.group == 6; end, "Group 6", "6",},
		{"ShowGroup7", function(rosterEntry) return rosterEntry.group == 7; end, "Group 7", "7",},
		{"ShowGroup8", function(rosterEntry) return rosterEntry.group == 8; end, "Group 8", "8",},		
		{	"ShowMyself",
			function(rosterEntry) return rosterEntry.isPlayer; end,
			"Myself",
			"Self"
		},
		{
			"ShowTanks",
			function(rosterEntry) return rosterEntry.role == "TANK" or rosterEntry.role == "maintank" or rosterEntry.role == "mainassist"; end,
			"Tanks",
		},
		{
			"ShowHeals",
			function(rosterEntry) return rosterEntry.role == "HEALER"; end,
			"Healers",
			"Heals",
		},
		{
			"ShowMelee",
			function(rosterEntry)
				return rosterEntry.role == "DAMAGER" and (
					rosterEntry.class == "WARRIOR"			
					or rosterEntry.class == "PALADIN"
					or (rosterEntry.class == "HUNTER" and GetInspectSpecialization(rosterEntry.unit) == 255)
					or rosterEntry.class == "ROGUE"
					or rosterEntry.class == "DEATHKNIGHT"
					or (rosterEntry.class == "SHAMAN" and GetInspectSpecialization(rosterEntry.unit) == 263)
					or rosterEntry.class == "MONK"
					or (rosterEntry.class == "DRUID" and GetInspectSpecialization(rosterEntry.unit) == 103)
					or rosterEntry.class == "DEMONHUNTER"
				);
			end,
			"Melee",
			"MDps"
		},
		{
			"ShowRange",
			function(rosterEntry)
				return rosterEntry.role == "DAMAGER" and (
				(rosterEntry.class == "HUNTER" and GetInspectSpecialization(rosterEntry.unit) ~= 255)   --if GetInspectSpecialization fails (returns 0) then we assume ranged just to at least show the player in a frame
				or rosterEntry.class == "PRIEST"
				or (rosterEntry.class == "SHAMAN" and GetInspectSpecialization(rosterEntry.unit) ~= 263)
				or rosterEntry.class == "MAGE"
				or rosterEntry.class == "WARLOCK"
				or (rosterEntry.class == "DRUID" and GetInspectSpecialization(rosterEntry.unit) ~= 103)
				);
			end,
			"Ranged",
			"RDps"
		},
		{"ShowPets", function(rosterEntry) return rosterEntry.role == "PET"; end, PETS, },
		{"ShowDeathKnights", function(rosterEntry) return rosterEntry.class == "DEATHKNIGHT"; end, LOCALIZED_CLASS_NAMES_MALE.DEATHKNIGHT, },
		{"ShowDemonHunters", function(rosterEntry) return rosterEntry.class == "DEMONHUNTER"; end, LOCALIZED_CLASS_NAMES_MALE.DEMONHUNTER, },
		{"ShowDruids", function(rosterEntry) return rosterEntry.class == "DRUID"; end, LOCALIZED_CLASS_NAMES_MALE.DRUID,},
		{"ShowHunters", function(rosterEntry) return rosterEntry.class == "HUNTER"; end, LOCALIZED_CLASS_NAMES_MALE.HUNTER,},
		{"ShowMages", function(rosterEntry) return rosterEntry.class == "MAGE"; end, LOCALIZED_CLASS_NAMES_MALE.MAGE, },
		{"ShowMonks", function(rosterEntry) return rosterEntry.class == "MONK"; end, LOCALIZED_CLASS_NAMES_MALE.MONK, },
		{"ShowPaladins", function(rosterEntry) return rosterEntry.class == "PALADIN"; end, LOCALIZED_CLASS_NAMES_MALE.PALADIN, },
		{"ShowPriests", function(rosterEntry) return rosterEntry.class == "PRIEST"; end, LOCALIZED_CLASS_NAMES_MALE.PRIEST, },
		{"ShowRogues", function(rosterEntry) return rosterEntry.class == "ROGUE"; end, LOCALIZED_CLASS_NAMES_MALE.ROGUE, },
		{"ShowShamans", function(rosterEntry) return rosterEntry.class == "SHAMAN"; end, LOCALIZED_CLASS_NAMES_MALE.SHAMAN, },
		{"ShowWarlocks", function(rosterEntry) return rosterEntry.class == "WARLOCK"; end, LOCALIZED_CLASS_NAMES_MALE.WARLOCK, },
		{"ShowWarriors", function(rosterEntry) return rosterEntry.class == "WARRIOR"; end, LOCALIZED_CLASS_NAMES_MALE.WARRIOR, },		
	};

	-- PRIVATE METHODS
	
	local function anchorLabel(label)
		label:ClearAllPoints();
		if (obj:GetProperty("Orientation") == 1 or obj:GetProperty("Orientation") == 3) then
			label:SetPoint(
				"CENTER",
				(
					(obj:GetProperty("GrowLeft") and -1) or 1)
					*(label.id - ((obj:GetProperty("GrowLeft") and 1.5) or 0.5))
					*(87 + obj:GetProperty("HorizontalSpacing")
				),
				(
					(obj:GetProperty("GrowUpward") and obj:GetProperty("EnableTargetFrame") and -20)
					or 0
				)
			);
		else
			label:SetPoint(
				(obj:GetProperty("GrowLeft") and "LEFT") or "RIGHT",
				(obj:GetProperty("GrowLeft") and 87) or 0,
				(
					((obj:GetProperty("GrowUpward") and 1) or -1)
					* (label.id - ((obj:GetProperty("EnableTargetFrame") and 0.5) or 0.25))
					* (
						37
						+ obj:GetProperty("VerticalSpacing") 
						+ ((obj:GetProperty("EnableTargetFrame") and 20) or 0)
						+ (((obj:GetProperty("EnableTargetFrame") and obj:GetProperty("TargetHealth") and not obj:GetProperty("HealthBarAsBackground")) and 4) or 0)
						+ (((obj:GetProperty("EnableTargetFrame") and obj:GetProperty("TargetPower")) and 4) or 0)
					)
				)
			);
		end
		label:SetWidth(87 + obj:GetProperty("HorizontalSpacing")/2);
		module:blockOverflowText(label, 87 + obj:GetProperty("HorizontalSpacing")/2);
	end
	
	local function updateFonts()
		nameFont = nameFont or CreateFont("CTRAWindow" .. (windowID or 1) .. "NameFont")
		countFont = countFont or CreateFont("CTRAWindow" .. (windowID or 1) .. "CountFont")
		healthBarFont = healthBarFont or CreateFont("CTRAWindow" .. (windowID or 1) .. "HealthBarFont")
		local scale, UIScale = obj:GetProperty("PlayerFrameScale"), windowFrame:GetEffectiveScale();
		local fontHeight = 2 + floor(9 * UIScale * scale*0.01);
		nameFont:SetFont("Fonts\\FRIZQT__.TTF", fontHeight, obj:GetProperty("HealthBarAsBackground") and "OUTLINE" or "");
		healthBarFont:SetFont("Fonts\\FRIZQT__.TTF", fontHeight-1, "OUTLINE");
		countFont:SetFont("Fonts\\ARIALN.TTF", fontHeight, "OUTLINE")
		return nameFont, countFont, healthBarFont;
	end
	
	-- PUBLIC METHODS
	function obj:Enable(asWindow, copyFromWindow)
		assert(type(asWindow) == "number" and asWindow > 0, "CTRA Window being enabled without a valid number");
		if (InCombatLockdown()) then return; end
		
		
		-- STEP 1: If copyFromWindow then this window should clone the settings from something else before proceeding further
		-- STEP 2: If this window has never been enabled, then create its component windowFrame and anchorFrame
		-- STEP 3: If this window was not previously enabled, then register for all events
		-- STEP 4: Position the anchor via module:RegisterMovable
		-- STEP 5: Set flags to track the frame's enabled identity
		-- STEP 6: Initialize and/or update the child frames
		-- STEP 7: If the CT options are currently open, show the movable anchor

		
		
		-- STEP 1:
		if (copyFromWindow and type(copyFromWindow) == "number") then
			for key, __ in pairs(defaultOptions) do
				module:setOption("CTRAWindow" .. asWindow .. "_" .. key,module:getOption("CTRAWindow" .. copyFromWindow .. "_" .. key), CT_SKIP_UPDATE_FUNC);
			end
		end
		
		-- STEP 2:
		if (not anchorFrame or not windowFrame) then
			-- anchor to handle positioning, with assistance from CT_Library
			anchorFrame = CreateFrame("Frame", nil, UIParent);
			anchorFrame:SetSize(80,16);
			anchorFrame:SetFrameLevel(4);	-- places it above windowFrame (1), and above the visualFrame (2) and secureButton (3) components of CTRAPlayerFrame
			--the frame's anchor point will be set later in step 4
			anchorFrame.texture = anchorFrame:CreateTexture(nil,"BACKGROUND");
			anchorFrame.texture:SetAllPoints(true);
			anchorFrame.texture:SetColorTexture(1,1,0,0.5);
			anchorFrame:SetScript("OnMouseDown",
				function()
					if (windowID) then
						module:moveMovable("CTRAWindow" .. windowID)
					end
				end
			);
			anchorFrame:SetScript("OnMouseUp",
				function()
					if (windowID) then
						module:stopMovable("CTRAWindow" .. windowID)
					end
				end
			);
			anchorFrame:SetScript("OnEnter",
				function()
					module:displayTooltip(anchorFrame, {"Left-click to drag this window"}, "ANCHOR_TOPRIGHT");
				end
			);
			-- indicator which window this is
			anchorFrame.text = anchorFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal");
			anchorFrame.text:SetPoint("LEFT", anchorFrame, "LEFT", 5, 0);
			anchorFrame.text:SetTextColor(1,1,1,1);
			
			-- window that player frames reside in
			windowFrame = CreateFrame("Frame", nil, UIParent);
			windowFrame:SetScale((module:getGameVersion() == 1 and 1) or 1.03);
			windowFrame:SetSize(1,1);	-- arbitrary, just to make it exist
			windowFrame:SetPoint("LEFT", anchorFrame, "LEFT");
			windowFrame:Show();
			windowFrame:SetScript("OnEvent",
				function(__, event)
					if (event == "GROUP_ROSTER_UPDATE" or event == "PLAYER_ENTERING_WORLD" or event == "PLAYER_REGEN_ENABLED") then
						self:Update();
					end
				end
			);
		end
		
		
		-- STEP 3:
		if (not self:IsEnabled()) then
			windowFrame:RegisterEvent("GROUP_ROSTER_UPDATE");
			windowFrame:RegisterEvent("PLAYER_ENTERING_WORLD");
			windowFrame:RegisterEvent("PLAYER_REGEN_ENABLED");
		end
		
		-- STEP 4:
		anchorFrame:ClearAllPoints();
		anchorFrame:SetPoint("CENTER", -300/asWindow, UIParent:GetHeight()/(3 + asWindow)); -- lays out new windows near the middle of the screen, slightly offset from each other
		module:registerMovable("CTRAWindow" .. asWindow, anchorFrame, true);
		
		-- STEP 5:
		windowID = asWindow;
		
		-- STEP 6:
		self:Update();
		
		-- STEP 7:
		if (module:IsControlPanelShown()) then
			self:ShowAnchor();
		else
			self:HideAnchor();
		end
		
		for key, __ in pairs(currentOptions) do
			currentOptions[key] = nil;
		end
	end
	
	function obj:Disable(deletePermanently)
		
		-- STEP 1: If deletePermanently then the settings for this window must be eliminated
		-- STEP 2: Deregister from all events
		-- STEP 3: Disable all child frames
		-- STEP 4: Disappear the anchor via module:UnregisterMovable
		-- STEP 5: Set flags to track the frame's disabled state
		-- STEP 6: Remove the anchor (which might already be hidden)
		
		-- STEP 1:
		if (deletePermanently and windowID) then
			for key, __ in pairs(defaultOptions) do
				module:setOption("CTRAWindow" .. windowID .. "_" .. key, nil, CT_SKIP_UPDATE_FUNC);
			end
			module:resetMovable("CTRAWindow" .. windowID);
		end
		
		-- STEP 2:
		windowFrame:UnregisterEvent("GROUP_ROSTER_UPDATE");
		windowFrame:UnregisterEvent("PLAYER_ENTERING_WORLD");
		windowFrame:UnregisterEvent("PLAYER_REGEN_ENABLED");
		
		-- STEP 3:
		for __, playerframe in pairs(playerFrames) do
			playerframe:Disable();
		end
		for __, targetframe in pairs(targetFrames) do
			targetframe:Disable();
		end
		for __, label in pairs(labels) do
			label:SetText("");
		end;
		
		-- STEP 4:
		module:UnregisterMovable("CTRAWindow" .. windowID);
		self:HideAnchor();
		
		-- STEP 5:
		windowID = nil;		
	end
	
	function obj:IsEnabled()
		return windowID ~= nil;
	end
	
	function obj:GetWindowID()
		return windowID;
	end
	
	-- returns the value associated with this window, or returns
	function obj:GetProperty(option)
		local id = windowID or 1;		--even if CTRAFrames are disabled and no windowID has ever been set, the options menu might still ask a sample player frame and need to configur eit.
		if (currentOptions[option]) then
			return currentOptions[option];
		end
		local savedValue = module:getOption("CTRAWindow" .. id .. "_" .. option);
		if (savedValue ~= nil) then
			currentOptions[option] = savedValue;
			return savedValue;
		end
		currentOptions[option] = defaultOptions[option];
		return defaultOptions[option];
	end
	
	
	function obj:Update(option, value)
		-- STEP 1: Update children and local copies of saved variables
		-- STEP 2: While out of combat, update any pending options
		-- STEP 3: If enabled, continue to steps 3 and 4.
		-- STEP 4: Outside combat, obtain a roster of self, party members and raid members to use during step 2
		-- STEP 5: Determine which players to show in this window, and construct/configure CTRAPlayerFrames accordingly
		
		-- STEP 1:
		if (option) then
			currentOptions[option] = value;
			pendingOptions[option] = value;
			for __, obj in ipairs(playerFrames) do
				obj:Update(option, value);
			end
			for __, obj in ipairs(targetFrames) do
				obj:Update(option, value);
			end
		end
		
		-- STEP 2:
		if (not InCombatLockdown()) then
			for key, val in pairs(pendingOptions) do
				if (key == "PlayerFrameScale") then
					updateFonts();
					for __, label in ipairs(labels) do
						label:SetScale(val/100);
					end					
				elseif (
					key == "GrowUpward"
					or key == "GrowLeft"
					or key == "EnableTargetFrame"
					or key == "HorizontalSpacing"
					or key == "VerticalSpacing"
					or key == "Orientation"
					or key == "EnableTargetFrame"
					or key == "TargetHealth"
					or key == "TargetPower"
				) then
					for __, label in ipairs(labels) do
						anchorLabel(label);
					end
				elseif (key == "HealthBarAsBackground") then
					updateFonts();
				end
			end
			wipe(pendingOptions);
		end

		-- STEP 3:
		if (not obj:IsEnabled()) then
			return;
		end

		-- STEP 4:
		wipe(roster);
		local numPets = 0;
		if (IsInRaid() or UnitExists("raid2")) then
			for i=1, min(MAX_RAID_MEMBERS, GetNumGroupMembers()) do
				local name, __, subgroup, __, __, fileName, __, __, __, role, __, combatRole = GetRaidRosterInfo(i);
				roster[i + numPets] = 
				{
					["name"] = name,
					["class"] = fileName,
					["role"] = (
						(combatRole ~= "NONE" and combatRole)  
						or role
						or GetSpecializationRoleByID(GetInspectSpecialization("raid" .. i))
					),
					["isPlayer"] = UnitIsUnit("raid" .. i, "player");
					["group"] = subgroup,
					["unit"] = "raid" .. i,
					["requestShow"] = 1,
				}
				if (UnitExists(format("raid%dpet", i))) then
					numPets = numPets + 1;
					roster[i + numPets] =
					{
						["role"] = "PET",
						["isPlayer"] = false,
						["unit"] = format("raid%dpet", i),
						["requestShow"] = 1,
					}
				end
			end
		else
			roster[1] = 
			{
				["name"] = UnitName("player"),
				["class"] = select(2, UnitClass("player")),
				["role"] = (
					(UnitGroupRolesAssigned("player") ~= "NONE" and UnitGroupRolesAssigned("player"))
					or select(5, GetSpecializationInfo(GetSpecialization()))
				),
				["isPlayer"] = true,
				["group"] = 1,
				["unit"] = "player",
				["requestShow"] = 1,
			}
			if (UnitExists("playerpet")) then
				numPets = 1;
				roster[2] =
				{
					["role"] = "PET",
					["isPlayer"] = false,
					["unit"] = "playerpet",
					["requestShow"] = 1,
				}
			end
			if (IsInGroup()) then
				for i=1, GetNumGroupMembers()-1 do
					roster[i+1 + numPets] = 
					{
						["name"] = UnitName("party" .. i),
						["class"] = select(2, UnitClass("party" .. i)),
						["role"] = (
							UnitGroupRolesAssigned("party" .. i) 
							or GetSpecializationRoleByID(GetInspectSpecialization("party" .. i))
						),
						["isPlayer"] = false,
						["group"] = 1,
						["unit"] = "party" .. i,
						["requestShow"] = 1,
					}
					if (UnitExists(format("party%dpet",i))) then
						numPets = numPets + 1;
						roster[i+1 + numPets] =
						{
							["role"] = "PET",
							["isPlayer"] = false,
							["unit"] = format("party%dpet",i),
							["requestShow"] = 1,
						}
					end
				end
			end
		end

		-- STEP 5:
		local categories = groupTypeFuncs;
		local x = 0;
		local y = 0;
		local w = 0;
		local rows = 0;
		local cols = 0;
		for __, frame in pairs(playerFrames) do
			frame:Disable();
		end
		for __, frame in pairs(targetFrames) do
			frame:Disable();
		end
		for __, label in pairs(labels) do
			label:SetText("");
		end
		local playersShown, labelsShown = 0, 0;	
		for __, category in pairs(categories) do  -- (from step 2)	
			local firstFrameOfCategory = true; -- to manage group labels when wrapping and merging are both active
			if self:GetProperty(category[1]) then

				-- this group must be shown, if there is anyone in it to show
				for __, rosterEntry in ipairs(roster) do
					if (rosterEntry.requestShow and category[2](rosterEntry)) then

						-- show this person
						playersShown = playersShown + 1;
						playerFrames[playersShown] = playerFrames[playersShown] or NewCTRAPlayerFrame(self, windowFrame);
						playerFrames[playersShown]:Enable(rosterEntry.unit, (self:GetProperty("GrowLeft") and -x) or x, (self:GetProperty("GrowUpward") and -y + 50) or y - 10);
						if (self:GetProperty("EnableTargetFrame")) then
							targetFrames[playersShown] = targetFrames[playersShown] or NewCTRATargetFrame(self, windowFrame);
							targetFrames[playersShown]:Enable(rosterEntry.unit .. "target", (self:GetProperty("GrowLeft") and -x) or x, (self:GetProperty("GrowUpward") and -y + 12) or y - 48);	-- 38 lower than the associated playerFrame
						end
						if (self:GetProperty("ShowDuplicatesOnceOnly")) then
							rosterEntry.requestShow = nil;
						end
						if (self:GetProperty("ShowGroupLabels")) then	
							if (w == 0) then
								labelsShown = labelsShown + 1
							end
							if (not labels[labelsShown]) then
								labels[labelsShown] = windowFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall");
								labels[labelsShown].id = labelsShown;
								labels[labelsShown]:SetJustifyH("CENTER");
								labels[labelsShown]:SetJustifyV("MIDDLE");
								labels[labelsShown]:SetScale(self:GetProperty("PlayerFrameScale")/100);
								labels[labelsShown]:SetTextColor(1,1,1);
								anchorLabel(labels[labelsShown]);
							end
							if (firstFrameOfCategory) then
								local text = labels[labelsShown]:GetText();
								if (text and text ~= "") then
									if (text:sub(1,6) == "Group ") then
										text = "Groups " .. text:sub(7);
									end
									labels[labelsShown]:SetText(text .. ", " .. (category[4] or category[3]));
								else
									labels[labelsShown]:SetText(category[3]);
								end
							end
						end
						firstFrameOfCategory = false;

						-- move the anchor (and wrap to a new col/row if necessary) for the next person, and keep track of the max number of rows and columns in use
						w = w + 1;
						if (w == self:GetProperty("WrapAfter")) then
							if (self:GetProperty("Orientation") == 1 or self:GetProperty("Orientation") == 3) then
								x = x + 87 + self:GetProperty("HorizontalSpacing");
								y = 0;
								if (w > rows) then
									rows = w;
								end
								if (w == 1) then
									-- first entry in a new column!
									cols = cols + 1;
								end
							else
								x = 0;
								y = (
									y 
									- 37
									- self:GetProperty("VerticalSpacing") 
									- ((self:GetProperty("EnableTargetFrame") and 20) or 0)
									- (((self:GetProperty("EnableTargetFrame") and self:GetProperty("TargetHealth") and not self:GetProperty("HealthBarAsBackground")) and 4) or 0)
									- (((self:GetProperty("EnableTargetFrame") and self:GetProperty("TargetPower")) and 4) or 0)
								);
								if (w > cols) then
									cols = w;
								end
								if (w == 1) then
									-- first entry in a new row!
									rows = rows + 1
								end
							end
							w = 0;
						else
							if (self:GetProperty("Orientation") == 1 or self:GetProperty("Orientation") == 3) then
								-- x = x;
								y = (
									y 
									- 37
									- self:GetProperty("VerticalSpacing") 
									- ((self:GetProperty("EnableTargetFrame") and 20) or 0)
									- (((self:GetProperty("EnableTargetFrame") and self:GetProperty("TargetHealth") and not self:GetProperty("HealthBarAsBackground")) and 4) or 0)
									- (((self:GetProperty("EnableTargetFrame") and self:GetProperty("TargetPower")) and 4) or 0)
								);
								if (w > rows) then
									rows = w;
								end
								if (w == 1) then
									-- first entry in a new column!
									cols = cols + 1;
								end
							else
								x = x + 87 + self:GetProperty("HorizontalSpacing");
								-- y = y;
								if (w > cols) then
									cols = w;
								end
								if (w == 1) then
									-- first entry in a new row!
									rows = rows + 1
								end
							end
						end
					end
				end

				-- move the anchor to the start of a new row/col if appropriate
				if (w > 0 and (self:GetProperty("Orientation") == 1 or self:GetProperty("Orientation") == 2)) then
					w = 0;
					if (self:GetProperty("Orientation") == 1) then
						x = x + 87 + self:GetProperty("HorizontalSpacing");
						y = 0;
					else
						x = 0;
						y = (
							y 
							- 37
							- self:GetProperty("VerticalSpacing") 
							- ((self:GetProperty("EnableTargetFrame") and 20) or 0)
							- (((self:GetProperty("EnableTargetFrame") and self:GetProperty("TargetHealth") and not self:GetProperty("HealthBarAsBackground")) and 4) or 0)
							- (((self:GetProperty("EnableTargetFrame") and self:GetProperty("TargetPower")) and 4) or 0)
						);
					end	
				end

			end
		end
	end
	
	function obj:Focus()
		if (not self:IsEnabled()) then
			return;
		end
		for key, __ in pairs(defaultOptions) do
			if (_G["CTRAWindow_" .. key .. "CheckButton"]) then
				_G["CTRAWindow_" .. key .. "CheckButton"]:Enable();
				_G["CTRAWindow_" .. key .. "CheckButton"]:SetChecked(self:GetProperty(key));
			elseif (_G["CTRAWindow_" .. key .. "DropDown"]) then
				local dropdown = _G["CTRAWindow_" .. key .. "DropDown"];
				UIDropDownMenu_EnableDropDown(dropdown)
				UIDropDownMenu_Initialize(dropdown, dropdown.initialize);
				UIDropDownMenu_SetSelectedValue(dropdown, self:GetProperty(key));
			elseif (_G["CTRAWindow_" .. key .. "Slider"]) then
				_G["CTRAWindow_" .. key .. "Slider"]:Enable();
				_G["CTRAWindow_" .. key .. "Slider"].suspend = 1;			-- hack to stop OnValueChanged from storing the value in SavedVariables
				_G["CTRAWindow_" .. key .. "Slider"]:SetValue(self:GetProperty(key));
				_G["CTRAWindow_" .. key .. "Slider"].suspend = nil;
			elseif (_G["CTRAWindow_" .. key .. "ColorSwatch"]) then
				local swatch = _G["CTRAWindow_" .. key .. "ColorSwatch"];
				swatch:Enable();
				local tex = swatch:GetNormalTexture();
				tex:SetVertexColor(unpack(self:GetProperty(key)));
			end
		end
		local dummyFrame = owner:GetDummyFrame();
		if (dummyFrame) then
			dummyFrame:Enable("player", 0, 0 + 0.00001 * windowID);
			dummyFrame:Update("PlayerFrameScale", self:GetProperty("PlayerFrameScale"));
			
		end
	end
	
	function obj:ShowAnchor()
		if (self:IsEnabled() and not InCombatLockdown()) then
			anchorFrame:Show();
			anchorFrame.text:SetText(format(L["CT_RaidAssist/WindowTitle"],windowID));
		else
			self:HideAnchor();
		end
	end
	
	function obj:HideAnchor()
		if (anchorFrame and not InCombatLockdown()) then
			anchorFrame:Hide();
		end
	end
	
	function obj:GetUnitNameFont()
		return nameFont or updateFonts()
	end
	
	function obj:GetCountFont()
		return countFont or select(2,updateFonts())
	end
	
	function obj:GetHealthBarFont()
		return healthBarFont or select(3,updateFonts())
	end
		
	-- public constructor
	return obj;
end

--------------------------------------------
-- Spells

function StaticClickCastBroker()

	-- STATIC PUBLIC INTERFACE
	local obj = { };
	StaticClickCastBroker = function() return obj; end

	-- PRIVATE PROPERTIES

	local class = select(2,UnitClass("player"));
	local attributes = { };
	local allBuff = { };				-- all buffs for this class, in this edition of the game
	local allRemoveDebuff = { };			-- ditto
	local allRezCombat = { };			-- ditto
	local allRezNoCombat = { };			-- ditto
	local canBuff = { };				-- chosen buffs the player can do right now
	local canRemoveDebuff = { };			-- ditto
	local canRezCombat = { };			-- ditto
	local canRezNoCombat = { };			-- ditto
	local cachedMacro1;				-- a macro if this class can click-cast, or nil
	local cachedMacro2;				-- a macro if this class can remove debuffs outside combat, or nil
	local tooltipLeft, tooltipRight = { }, { };	-- preformatted text for the left and right sides of the tooltip
	local registeredPlayerFrames = { };		-- callback functions to each player frame that may need to update for new right clicks

	-- PRIVATE METHODS
	
	-- Records which spells the player could cast if they were high enough level and learned the spell
	local function configureSpells(resetFlag)
		-- STEP 1: wipe all existing spell data
		-- STEP 2: iterate through all spells the player might ever be able to do on this toon
		-- STEP 3: record (or reset and record) the spell data to an intermediary table
		
		-- STEP 1:
		wipe(allBuff);
		wipe(allRemoveDebuff);
		wipe(allRezCombat);
		wipe(allRezNoCombat);
		
		-- STEP 3:  (step 2 follows underneath)
		local function addToTable(table, id, localizedName, defaultModifier, defaultButton)
			local option = module:getOption("CTRAFrames_ClickCast_" .. id)
			if (resetFlag and option) then
				module:setOption("CTRA_Frames_ClickCast_" .. id, nil);
				option = nil;
			end
			if (not option) then
				tinsert(table, {
					["name"] = localizedName,
					["enabled"] = true,
					["modifier"] = defaultModifier,
					["button"] = defaultButton,
					["id"] = id,
					["option"] = (
						(defaultModifier == "nomod" and (defaultButton == 2 and 1 or 6))
						or (defaultModifier == "mod:shift" and (defaultButton == 2 and 2 or 7))
						or (defaultModifier == "mod:ctrl" and (defaultButton == 2 and 3 or 8))
						or (defaultModifier == "mod:alt" and (defaultButton == 2 and 4 or 9))
						or 5
						
					),
					["attribute"] = (
						defaultModifier == "nomod" and "type" .. defaultButton				-- type2
						or defaultModifier and defaultModifier:sub(5) .. "-type" .. defaultButton  	-- nil or shift-type2
					),
				});
			elseif (option == 5) then
				tinsert(table, {
					["name"] = localizedName,
					["enabled"] = false,
					["modifier"] = nil,
					["button"] = nil,
					["id"] = id,
					["option"] = 5,
					["attribute"] = nil,
				});		
			else
				tinsert(table, {
					["name"] = localizedName,
					["enabled"] = true,
					["modifier"] = (
						option == 2 and "mod:shift"
						or option == 3 and "mod:ctrl"
						or option == 4 and "mod:alt"
						or option == 7 and "mod:shift"
						or option == 8 and "mod:ctrl"
						or option == 9 and "mod:alt"
						or "nomod"	-- option == 1 or option == 6
						
					),
					["button"] = option < 5 and 2 or 1,
					["id"] = id,
					["option"] = option,
					["attribute"] = (
						option == 2 and "shift-type2"
						or option == 3 and "ctrl-type2"
						or option == 4 and "alt-type2"
						or option == 6 and "type1"
						or option == 7 and "shift-type1"
						or option == 8 and "ctrl-type1"
						or option == 9 and "alt-type1"
						or "type2"	-- option == 1
					),
				});
			end		
		end
	
		-- STEP 2: (uses the function above for brevity)
	
		-- allBuff
		if (module.CTRA_Configuration_Buffs[class]) then
			for __, details in ipairs(module.CTRA_Configuration_Buffs[class]) do
				if (details.name) then
					addToTable(allBuff, details.id, details.name, details.modifier, details.button);
				end
			end
		end

		-- allRemoveDebuff
		if (module.CTRA_Configuration_FriendlyRemoves[class]) then
			for __, details in ipairs(module.CTRA_Configuration_FriendlyRemoves[class]) do
				if (details.name) then
					addToTable(allRemoveDebuff, details.id, details.name, details.modifier, details.button);
				end
			end
		end
		
		-- allRezCombat and allRezNoCombat
		if (module.CTRA_Configuration_RezAbilities[class]) then
			for __, details in ipairs(module.CTRA_Configuration_RezAbilities[class]) do
				if (details.name) then
					if (details.combat) then
						addToTable(allRezCombat, details.id, details.name, details.modifier, details.button);
					end
					if (details.nocombat) then
						addToTable(allRezNoCombat, details.id, details.name, details.modifier, details.button);
					end
				end
			end
		end
	end
	
	local function updateSpells()
		-- STEP 1: wipe all existing spell data
		-- STEP 2: record which spells the player can cast
		-- STEP 3: wipe all cached macros (to ensure they are refreshed with the newest spell data)
		-- STEP 4: direct all registered CTRAPlayerFrames to update their various attributes

		-- STEP 1:
		wipe(canBuff);
		wipe(canRemoveDebuff);
		wipe(canRezCombat);
		wipe(canRezNoCombat);
		wipe(attributes);
		wipe(tooltipLeft);
		wipe(tooltipRight);
		
		local spec = GetSpecialization and GetSpecialization()
		
		-- STEP 2:
		-- canBuff
		for __, details in ipairs(allBuff) do
			if (details.enabled and CT_Library.getSpellName(details.name)) then
				local key = details.button .. ", " .. details.modifier;
				if (not canBuff[key]) then
					canBuff[key] = details.name;
					tinsert(tooltipLeft, "|cFF33CC66nocombat, " .. key:gsub("1","left"):gsub("2","right"):gsub(", nomod", ""):gsub("mod:", ""));
					tinsert(tooltipRight, "|cFF33CC66" .. details.name:gsub("#", ""));
					attributes[details.attribute] = true;
				end
			end
		end
		
		-- canRemoveDebuff
		for __, details in ipairs(allRemoveDebuff) do
			if (details.enabled and CT_Library.getSpellName(details.name) and (details.spec == nil or spec == nil or details.spec == spec)) then
				local key = details.button .. ", " .. details.modifier;
				if (not canRemoveDebuff[key]) then
					canRemoveDebuff[key] = details.name;
					tinsert(tooltipLeft, "|cFFCC6666combat, " .. key:gsub("1","left"):gsub("2","right"):gsub(", nomod", ""):gsub("mod:", ""));
					tinsert(tooltipRight, "|cFFCC6666" .. details.name:gsub("#", ""));
					attributes[details.attribute] = true;
				end
			end
		end
		
		-- canRezCombat
		for __, details in ipairs(allRezCombat) do
			if (details.enabled and CT_Library.getSpellName(details.name)) then
				local key = details.button .. ", " .. details.modifier;
				if (not canRezCombat[key]) then
					canRezCombat[key] = details.name;
					tinsert(tooltipLeft, "|cFF999999combat, dead, " .. key:gsub("1","left"):gsub("2","right"):gsub(", nomod", ""):gsub("mod:", ""));
					tinsert(tooltipRight, "|cFF999999" .. details.name:gsub("#", ""));
					attributes[details.attribute] = true;
				end
			end
		end
		
		-- canRezNoCombat
		for __, details in ipairs(allRezNoCombat) do
			if (details.enabled and CT_Library.getSpellName(details.name)) then
				local key = details.button .. ", " .. details.modifier;
				if (not canRezNoCombat[key]) then
					canRezNoCombat[key] = details.name;
					tinsert(tooltipLeft, "|cFF999999nocombat, dead, " .. key:gsub("1","left"):gsub("2","right"):gsub(", nomod", ""):gsub("mod:", ""));
					tinsert(tooltipRight, "|cFF999999" .. details.name:gsub("#", ""));
					attributes[details.attribute] = true;
				end
			end
		end
		
		-- STEP 3:
		cachedMacro1 = nil;
		cachedMacro2 = nil;
		
		-- STEP 4:
		for __, func in pairs(registeredPlayerFrames) do
			func();
		end
	end
	
	local function draftMacros()
		local macro1, macro2;
		local hasDebuffs;
		for key, spellName in pairs(canRemoveDebuff) do		-- [@party1, exists, nodead, combat, nomod] Abolish Poison; [@party1, nodead, combat, mod:shift] Remove Curse;
			macro1 = (macro1 or "/cast") .. " [@mouseover, exists, nodead, combat, btn:" .. key .. "] " .. spellName .. ";";
			macro2 = (macro2 or "/cast") .. " [@mouseover, exists, nodead, btn:" .. key .. "] " .. spellName .. ";";
			hasDebuffs = true;
		end				
		for key, spellName in pairs(canBuff) do			-- [@party1, exists, nodead, nocombat, nomod] Arcane Intellect; [@party1, nodead, nocombat, button:2, mod:shift] Arcane Brilliance;
			macro1 = (macro1 or "/cast") .. " [@mouseover, exists, nodead, nocombat, btn:" .. key .. "] " .. spellName .. ";";
			macro2 = (macro2 or "/cast") .. " [@mouseover, exists, nodead, nocombat, btn:" .. key .. "] " .. spellName .. ";";
		end	
		for key, spellName in pairs(canRezCombat) do			-- [@party1, exists, dead, combat, nomod] Rebirth;
			macro1 = (macro1 or "/cast") .. " [@mouseover, exists, dead, combat, btn:" .. key .. "] " .. spellName .. ";";
			macro2 = (macro2 or "/cast") .. " [@mouseover, exists, dead, combat, btn:" .. key .. "] " .. spellName .. ";";
		end							
		for key, spellName in pairs(canRezNoCombat) do		-- [@party1, exists, dead, nocombat, nomod] Resurrection;
			macro1 = (macro1 or "/cast") .. " [@mouseover, exists, dead, nocombat, btn:" .. key .. "] " .. spellName .. ";";
			macro2 = (macro2 or "/cast") .. " [@mouseover, exists, dead, nocombat, btn:" .. key .. "] " .. spellName .. ";";
		end
		cachedMacro1, cachedMacro2 = macro1, hasDebuffs and macro2;
	end
	
	-- PUBLIC METHODS
	
	-- CTRA frames register themselves to be informed when their macros may be out of date
	function obj:Register(callbackFunc)
		if (type(callbackFunc) == "function") then
			tinsert(registeredPlayerFrames, callbackFunc);
		end
	end
	
	-- returns two macros, one to be used ordinarily and the other to be used exclusively out of combat when there is a removable debuff
	-- the first macro is nil if click-casting if this class has no click casting
	-- the second macro is nil if this class should not do anything different outside combat
	function obj:GetMacros()
		if (not cachedMacro1) then
			draftMacros();
		end
		return cachedMacro1, cachedMacro2, attributes;
	end
	
	-- adds several double-lines to the tooltip (default: GameTooltip) describing each spell and how to click-cast it
	-- also adds a single line that saying "Right click..." if there is at least one click-castable spell
	do
		local pattern = "%s - %s#s:0.85";
		function obj:PopulateTooltip(tooltipTable)
			if (Clique and module:getOption("CTRAFrames_ClickCast_UseCliqueAddon") ~= false) then
				return;
			end
			for i=1, #tooltipLeft do
				if (i==1) then
					tinsert(tooltipTable, "|nClick casting...#0.9:0.9:0.9#s:0.8");
				end
				tinsert(tooltipTable, pattern:format(tooltipLeft[i], tooltipRight[i]));
			end
		end
	end
	
	function obj:GetAllSpellsForClass()
		return allBuff, allRemoveDebuff, allRezCombat, allRezNoCombat;
	end
	
	function obj:Update(option, value)
		if (tonumber(option)) then
			configureSpells();
			updateSpells();
		end
	end
	
	function obj:Refresh()
		configureSpells();
		updateSpells();
	end
	
	function obj:Reset()
		configureSpells(true);
		updateSpells();
	end
	
	-- CONSTRUCTOR
	do
		module:regEvent("PLAYER_LOGIN", obj.Refresh);
		module:regEvent("LEARNED_SPELL_IN_TAB", updateSpells);	-- removed in modern clients (skipped harmlessly); see SPELLS_CHANGED below
		module:regEvent("SPELLS_CHANGED", updateSpells);	-- modern replacement: fires on learning spells, spec/talent changes
		if (module:getGameVersion() >= 3) then
			module:regEvent("ACTIVE_TALENT_GROUP_CHANGED", updateSpells);
		end
		return obj;
	end
end




--------------------------------------------
-- CTRAPlayerFrame

function NewCTRAPlayerFrame(parentInterface, parentFrame, isDummy)
	
	-- PUBLIC INTERFACE
	
	local obj = { };
	
	-- PRIVATE PROPERTIES
	
	local owner;			-- pointer to the CTRAWindow interface for calling functions like :GetProperty()
	local parent;			-- pointer to the CTRAWindow's frame object that is a parent for the visualFrame
	local visualFrame;		-- generic frame that shows various textures
	local secureButton;		-- SecureUnitActionButton that sits in front and responds to mouseclicks
	local secureButtonDebuffFirst;	-- SecureUnitActionButton that sits in front and responds to mouseclicks
	local secureButtonCliqueFirst;	-- SecureUnitActionButton that sits in front and allows itself to be configured by Clique addon
	local listenerFrame;		-- generic frame that listens to various events
	local requestedUnit;		-- the unit that this object is requested to display at the next opportunity
	local requestedXOff;		-- the x coordinate to position this object's frames at the next opportunity (relative to parent's left)w
	local requestedYOff;		-- the y coordinate to position this object's frames at the next opportunity (relative to parent's top)
	local shownUnit;		-- the unit that this object is currently showing (which cannot change during combat)
	local shownXOff;		-- the x coordinate this frame is currently showing
	local shownYOff;		-- the y coordinate this frame is currently showingw
	local isPet;			-- flag that, when true, indicates this unit is actually a player's pet instead of a normal player
	local optionsWaiting = { };	-- a list of options that need to be triggered once combat ends
	local absorbSetting;		-- a flag to control the behaviour of the total-absorb bar
	local incomingSetting;		-- a flag to control the behaviour of the incoming-heal bar (aka prediction bar)
	
	-- graphical textures and fontstrings of visualFrame
	local background;
	local colorBackgroundRed, colorBackgroundGreen, colorBackgroundBlue, colorBackgroundAlpha;
	local colorBackgroundDeadOrGhostRed, colorBackgroundDeadOrGhostGreen, colorBackgroundDeadOrGhostBlue, colorBackgroundDeadOrGhostAlpha;
	local colorBorderRed, colorBorderGreen, colorBorderBlue, colorBorderAlpha;
	local colorBorderBeyondRangeRed, colorBorderBeyondRangeGreen, colorBorderBeyondRangeBlue, colorBorderBeyondRangeAlpha;
	local healthBarFullCombat, healthBarZeroCombat, healthBarFullNoCombat, healthBarZeroNoCombat;
	local healthBarText;
	local absorbBarFullCombat, absorbBarZeroCombat, absorbBarFullNoCombat, absorbBarZeroNoCombat, absorbBarOverlay;
	local incomingBarFullCombat, incomingBarZeroCombat, incomingBarFullNoCombat, incomingBarZeroNoCombat;
	local healthBarWidth;
	local powerBar, powerBarWidth;
	local roleTexture;
	local unitNameFontString;
	local auraBossShown = { };
	local auraBoss1, auraBoss2, auraBoss3, auraBoss4;
	local aura1, aura2, aura3, aura4, aura5;
	local statusTexture, statusFontString, statusNoticeBackground, statusAlarmBackground;
	local durabilityAverage, durabilityBroken, durabilityTime;
	local DEFAULT_DEBUFF_COLOR = {r = 1, g = 0, b = 0};
	
	-- PRIVATE FUNCTIONS

	-- very frequently updates the border to reflect game state; see updateBackdrop() and createBackdrop()
	local function updateBackdropBorder()
		if (shownUnit and UnitExists(shownUnit)) then
			if (UnitIsDeadOrGhost(shownUnit)) then
				local unit = (isPet and shownUnit:sub(1,-4)) or shownUnit;
				if (inRangeSafe(unit) or UnitIsUnit(unit, "player")) then
					visualFrame:SetBackdropBorderColor(colorBorderRed, colorBorderGreen, colorBorderBlue, colorBorderAlpha);
				else
					visualFrame:SetBackdropBorderColor(colorBorderBeyondRangeRed, colorBorderBeyondRangeGreen, colorBorderBeyondRangeBlue, colorBorderBeyondRangeAlpha);
				end
			else
				local removableDebuff = C_UnitAuras.GetAuraDataByIndex(shownUnit, 1, "RAID HARMFUL")
				if (removableDebuff and owner:GetProperty("RemovableDebuffColor")) then
					local color = DebuffTypeColor[removableDebuff.dispelName] or DEFAULT_DEBUFF_COLOR;
					local unit = (isPet and shownUnit:sub(1,-4)) or shownUnit;
					if (inRangeSafe(unit) or UnitIsUnit(unit, "player")) then
						visualFrame:SetBackdropBorderColor(color.r, color.g, color.b, colorBorderAlpha*0.8 + 0.2);
					else
						visualFrame:SetBackdropBorderColor(colorBorderBeyondRangeRed, colorBorderBeyondRangeGreen, colorBorderBeyondRangeBlue, colorBorderBeyondRangeAlpha);
					end
				else
					local classR, classG, classB = GetClassColor(select(2,UnitClass(shownUnit)));
					local unit = (isPet and shownUnit:sub(1,-4)) or shownUnit;
					if (inRangeSafe(unit) or UnitIsUnit(unit, "player")) then
						local ratio = owner:GetProperty("ColorBorderClass")/100;
						if (classR and ratio > 0) then
							visualFrame:SetBackdropBorderColor(colorBorderRed * (1-ratio) + classR * ratio, colorBorderGreen * (1-ratio) + classG * ratio, colorBorderBlue * (1-ratio) + classB * ratio, colorBorderAlpha);
						else
							visualFrame:SetBackdropBorderColor(colorBorderRed, colorBorderGreen, colorBorderBlue, colorBorderAlpha);
						end
					else
						visualFrame:SetBackdropBorderColor(colorBorderBeyondRangeRed, colorBorderBeyondRangeGreen, colorBorderBeyondRangeBlue, colorBorderBeyondRangeAlpha);
					end
				end
			end
		end	
	end
	
	-- frequently updates the background and borders to reflect game state; see createBackdrop()
	local function updateBackdrop()
		if (shownUnit and UnitExists(shownUnit)) then
			if (UnitIsDeadOrGhost(shownUnit)) then
				background:SetColorTexture(colorBackgroundDeadOrGhostRed, colorBackgroundDeadOrGhostGreen, colorBackgroundDeadOrGhostBlue, colorBackgroundDeadOrGhostAlpha);
				local unit = (isPet and shownUnit:sub(1,-4)) or shownUnit;
				if (inRangeSafe(unit) or UnitIsUnit(unit, "player")) then
					visualFrame:SetBackdropBorderColor(colorBorderRed, colorBorderGreen, colorBorderBlue, colorBorderAlpha);
				else
					visualFrame:SetBackdropBorderColor(colorBorderBeyondRangeRed, colorBorderBeyondRangeGreen, colorBorderBeyondRangeBlue, colorBorderBeyondRangeAlpha);
				end
			else
				local removableDebuff = C_UnitAuras.GetAuraDataByIndex(shownUnit, 1, "RAID HARMFUL")
				if (removableDebuff and owner:GetProperty("RemovableDebuffColor")) then
					local color = DebuffTypeColor[removableDebuff.dispelName] or DEFAULT_DEBUFF_COLOR;
					background:SetColorTexture(colorBackgroundRed/2 + color.r/2, colorBackgroundGreen/2 + color.g/2, colorBackgroundBlue/2 + color.b/2, colorBackgroundAlpha*0.8 + 0.2);
					local unit = (isPet and shownUnit:sub(1,-4)) or shownUnit;
					if (inRangeSafe(unit) or UnitIsUnit(unit, "player")) then
						visualFrame:SetBackdropBorderColor(color.r, color.g, color.b, colorBorderAlpha*0.8 + 0.2);
					else
						visualFrame:SetBackdropBorderColor(colorBorderBeyondRangeRed, colorBorderBeyondRangeGreen, colorBorderBeyondRangeBlue, colorBorderBeyondRangeAlpha);
					end
				else
					local classR, classG, classB = GetClassColor(select(2,UnitClass(shownUnit)));
					local ratio = owner:GetProperty("ColorBackgroundClass")/100;
					if (classR and ratio > 0) then
						background:SetColorTexture(colorBackgroundRed * (1-ratio) + classR * ratio, colorBackgroundGreen * (1-ratio) + classG * ratio, colorBackgroundBlue * (1-ratio) + classB * ratio, colorBackgroundAlpha);
					else
						background:SetColorTexture(colorBackgroundRed, colorBackgroundGreen, colorBackgroundBlue, colorBackgroundAlpha);
					end
					local unit = (isPet and shownUnit:sub(1,-4)) or shownUnit;
					if (inRangeSafe(unit) or UnitIsUnit(unit, "player")) then
						ratio = owner:GetProperty("ColorBorderClass")/100;
						if (classR and ratio > 0) then
							visualFrame:SetBackdropBorderColor(colorBorderRed * (1-ratio) + classR * ratio, colorBorderGreen * (1-ratio) + classG * ratio, colorBorderBlue * (1-ratio) + classB * ratio, colorBorderAlpha);
						else
							visualFrame:SetBackdropBorderColor(colorBorderRed, colorBorderGreen, colorBorderBlue, colorBorderAlpha);
						end
					else
						visualFrame:SetBackdropBorderColor(colorBorderBeyondRangeRed, colorBorderBeyondRangeGreen, colorBorderBeyondRangeBlue, colorBorderBeyondRangeAlpha);
					end
				end
			end
		end
	end
	
	-- infrequently configures the backdrop and borders according to user settings; see createBackdrop()
	local function configureBackdrop()
		visualFrame.backdropInfo.edgeSize = 10 + 2 * owner:GetProperty("BorderThickness");
		if (visualFrame.ApplyBackdrop) then
			visualFrame:ApplyBackdrop();
		else
			-- classic
			visualFrame:SetBackdrop(visualFrame.backdropInfo);
		end
		colorBackgroundRed, colorBackgroundGreen, colorBackgroundBlue, colorBackgroundAlpha = unpack(owner:GetProperty("ColorBackground"));
		colorBackgroundDeadOrGhostRed, colorBackgroundDeadOrGhostGreen, colorBackgroundDeadOrGhostBlue, colorBackgroundDeadOrGhostAlpha = unpack(owner:GetProperty("ColorBackgroundDeadOrGhost"));	
		colorBorderRed, colorBorderGreen, colorBorderBlue, colorBorderAlpha = unpack(owner:GetProperty("ColorBorder"));
		colorBorderBeyondRangeRed, colorBorderBeyondRangeGreen, colorBorderBeyondRangeBlue, colorBorderBeyondRangeAlpha = unpack(owner:GetProperty("ColorBorderBeyondRange"));
	end
	
	-- permanently creates the background and borders
	local function createBackdrop()
		background = visualFrame:CreateTexture(nil, "BACKGROUND");
		background:SetPoint("TOPLEFT", visualFrame, 3, -3);
		background:SetPoint("BOTTOMRIGHT", visualFrame, -3, 3);	
		visualFrame.backdropInfo = {edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border"};
		
		-- frequent range check that affects the border only
		C_Timer.NewTicker(0.5, updateBackdropBorder);
		
		-- initial configuration
		configureBackdrop()
	end
		
	-- frequently updates the health, absorb and incoming bars to reflect game state
	local function updateHealthBar()
		if (shownUnit and UnitExists(shownUnit) and not UnitIsDeadOrGhost(shownUnit)) then
			-- the unit is alive and should have a health bar
			local health, healthMax = ctSafeNumber(UnitHealth(shownUnit)), ctSafeNumber(UnitHealthMax(shownUnit));
			if (not (health and healthMax and healthMax > 0)) then return; end	-- restricted "secret number" (e.g. in combat); skip rather than crash
			local healthRatio = health / healthMax;
			local absorbRatio = (ctSafeNumber(UnitGetTotalAbsorbs(shownUnit, absorbSetting)) or 0) / healthMax;
			local incomingRatio = (ctSafeNumber(UnitGetIncomingHeals(shownUnit, incomingSetting)) or 0) / healthMax;
			if (healthRatio > 1) then
				healthRatio = 1;
			elseif (healthRatio < 0.001) then
				healthRatio = 0.001;
			end
			if (healthRatio + absorbRatio > 1) then
				absorbRatio = 1.001 - healthRatio;
			elseif (absorbRatio < 0.001) then
				absorbRatio = 0.001;
			end
			if (healthRatio + absorbRatio + incomingRatio > 1.002) then
				incomingRatio = 1.002 - healthRatio - absorbRatio;
			elseif (incomingRatio < 0.001) then
				incomingRatio = 0.001;
			end
			healthBarFullCombat:SetWidth(healthBarWidth * healthRatio)
			absorbBarFullCombat:SetWidth(healthBarWidth * absorbRatio)
			incomingBarFullCombat:SetWidth(healthBarWidth * incomingRatio)
			if (InCombatLockdown() or UnitAffectingCombat(shownUnit)) then
				healthBarFullCombat:SetAlpha(healthRatio * healthBarFullCombat.maxAlpha);
				healthBarZeroCombat:SetAlpha((1 - healthRatio)  * healthBarZeroCombat.maxAlpha);
				healthBarFullNoCombat:SetAlpha(0);
				healthBarZeroNoCombat:SetAlpha(0);
				absorbBarFullCombat:SetAlpha(healthRatio * healthBarFullCombat.maxAlpha * 0.8);
				absorbBarZeroCombat:SetAlpha((1 - healthRatio)  * healthBarZeroCombat.maxAlpha * 0.8);
				absorbBarFullNoCombat:SetAlpha(0);
				absorbBarZeroNoCombat:SetAlpha(0);
				absorbBarOverlay:SetAlpha(healthBarZeroCombat.maxAlpha * 0.8);
				incomingBarFullCombat:SetAlpha(healthRatio * healthBarFullCombat.maxAlpha * 0.4);
				incomingBarZeroCombat:SetAlpha((1 - healthRatio)  * healthBarZeroCombat.maxAlpha * 0.4);
				incomingBarFullNoCombat:SetAlpha(0);
				incomingBarZeroNoCombat:SetAlpha(0);
			else
				healthBarFullNoCombat:SetAlpha(healthRatio * healthBarFullNoCombat.maxAlpha);
				healthBarZeroNoCombat:SetAlpha((1 - healthRatio)  * healthBarZeroNoCombat.maxAlpha);				
				healthBarFullCombat:SetAlpha(0);
				healthBarZeroCombat:SetAlpha(0);
				absorbBarFullNoCombat:SetAlpha(healthRatio * healthBarFullCombat.maxAlpha * 0.8);
				absorbBarZeroNoCombat:SetAlpha((1 - healthRatio)  * healthBarZeroCombat.maxAlpha * 0.8);
				absorbBarFullCombat:SetAlpha(0);
				absorbBarZeroCombat:SetAlpha(0);
				absorbBarOverlay:SetAlpha(healthBarZeroCombat.maxAlpha * 0.8);
				incomingBarFullNoCombat:SetAlpha(healthRatio * healthBarFullCombat.maxAlpha * 0.4);
				incomingBarZeroNoCombat:SetAlpha((1 - healthRatio)  * healthBarZeroCombat.maxAlpha * 0.4);
				incomingBarFullCombat:SetAlpha(0);
				incomingBarZeroCombat:SetAlpha(0);
			end
			if (healthRatio < 1) then
				healthBarText:SetText(string.format("%d%%", healthRatio*100));
			else
				healthBarText:SetText("");
			end
		else
			-- the unit is dead, or maybe doesn't even exist, so show nothing!
			healthBarFullCombat:SetAlpha(0);
			healthBarZeroCombat:SetAlpha(0);
			healthBarFullNoCombat:SetAlpha(0);
			healthBarZeroNoCombat:SetAlpha(0);
			absorbBarFullCombat:SetAlpha(0);
			absorbBarZeroCombat:SetAlpha(0);
			absorbBarFullNoCombat:SetAlpha(0);
			absorbBarZeroNoCombat:SetAlpha(0);
			absorbBarOverlay:SetAlpha(0);
			incomingBarFullCombat:SetAlpha(0);
			incomingBarZeroCombat:SetAlpha(0);
			incomingBarFullNoCombat:SetAlpha(0);
			incomingBarZeroNoCombat:SetAlpha(0);
			healthBarText:SetText("");
		end
	end

	-- infrequently configures the health, absorb and incoming bar textures according to user settings; see createHealthBar()
	local function configureHealthBar()
		if (owner:GetProperty("HealthBarAsBackground")) then
			healthBarFullCombat:SetPoint("TOPLEFT", visualFrame, "TOPLEFT", 4,  -4);
			healthBarFullCombat:SetPoint("BOTTOMLEFT", visualFrame, "BOTTOMLEFT", 4, 4);
			healthBarWidth = 82;
			local effectiveScale = visualFrame:GetEffectiveScale();
			healthBarText:SetPoint("BOTTOM", healthBarFullCombat, 0, 7 * effectiveScale);
		else
			healthBarFullCombat:SetPoint("TOPLEFT", visualFrame, "BOTTOMLEFT", 10, 19);
			healthBarFullCombat:SetPoint("BOTTOMLEFT", visualFrame, "BOTTOMLEFT", 10, 12);
			healthBarWidth = 70;
			healthBarText:SetPoint("BOTTOM", healthBarFullCombat);
		end
			
		local r,g,b,a;
		r,g,b,a = unpack(owner:GetProperty("ColorUnitFullHealthCombat"));
		healthBarFullCombat:SetVertexColor(r,g,b);
		absorbBarFullCombat:SetVertexColor(r*0.5+0.5,g*0.5+0.5,b*0.5+0.5);
		incomingBarFullCombat:SetVertexColor(r,g,b);
		healthBarFullCombat.maxAlpha = a;

		r,g,b,a = unpack(owner:GetProperty("ColorUnitZeroHealthCombat"));
		healthBarZeroCombat:SetVertexColor(r,g,b);
		absorbBarZeroCombat:SetVertexColor(r*0.5+0.5,g*0.5+0.5,b*0.5+0.5);
		incomingBarZeroCombat:SetVertexColor(r,g,b);
		healthBarZeroCombat.maxAlpha = a;
		
		r,g,b,a = unpack(owner:GetProperty("ColorUnitFullHealthNoCombat"));
		healthBarFullNoCombat:SetVertexColor(r,g,b);
		absorbBarFullNoCombat:SetVertexColor(r*0.5+0.5,g*0.5+0.5,b*0.5+0.5);
		incomingBarFullNoCombat:SetVertexColor(r,g,b);
		healthBarFullNoCombat.maxAlpha = a;
		
		r,g,b,a = unpack(owner:GetProperty("ColorUnitZeroHealthNoCombat"));
		healthBarZeroNoCombat:SetVertexColor(r,g,b);
		absorbBarZeroNoCombat:SetVertexColor(r*0.5+0.5,g*0.5+0.5,b*0.5+0.5);
		incomingBarZeroNoCombat:SetVertexColor(r,g,b);
		healthBarZeroNoCombat.maxAlpha = a;
		
	
		if (module:getGameVersion() == 1 or owner:GetProperty("ShowTotalAbsorbs") == 3) then
			absorbBarFullCombat:Hide();
			absorbBarZeroCombat:Hide();
			absorbBarFullNoCombat:Hide();
			absorbBarFullNoCombat:Hide();
			absorbBarOverlay:Hide();
			incomingBarFullCombat:SetPoint("TOPLEFT", healthBarFullCombat, "TOPRIGHT");	
			incomingBarFullCombat:SetPoint("BOTTOMLEFT", healthBarFullCombat, "BOTTOMRIGHT");
		else
			absorbBarFullCombat:Show();
			absorbBarZeroCombat:Show();
			absorbBarFullNoCombat:Show();
			absorbBarFullNoCombat:Show();	
			absorbBarOverlay:Show();
			incomingBarFullCombat:SetPoint("TOPLEFT", absorbBarFullCombat, "TOPRIGHT");
			incomingBarFullCombat:SetPoint("BOTTOMLEFT", absorbBarFullCombat, "BOTTOMRIGHT");
			absorbSetting = owner:GetProperty("ShowTotalAbsorbs") == 2;
		end
		
		if (owner:GetProperty("ShowIncomingHeals") == 3) then
			incomingBarFullCombat:Hide();
			incomingBarZeroCombat:Hide();
			incomingBarFullNoCombat:Hide();
			incomingBarFullNoCombat:Hide();
			incomingSetting = nil
		else
			incomingBarFullCombat:Show();
			incomingBarZeroCombat:Show();
			incomingBarFullNoCombat:Show();
			incomingBarFullNoCombat:Show();
			incomingSetting = owner:GetProperty("ShowIncomingHeals") == 2 and player or nil;
		end
		
		healthBarText:SetShown(owner:GetProperty("ShowHealthText"));
	end
	
	-- permanently creates health, absorb and incoming bar textures
	local function createHealthBar()
		healthBarFullCombat = healthBarFullCombat or visualFrame:CreateTexture(nil, "ARTWORK");
		healthBarZeroCombat = healthBarZeroCombat or visualFrame:CreateTexture(nil, "ARTWORK");
		healthBarFullNoCombat = healthBarFullNoCombat or visualFrame:CreateTexture(nil, "ARTWORK");
		healthBarZeroNoCombat = healthBarZeroNoCombat or visualFrame:CreateTexture(nil, "ARTWORK");
		absorbBarFullCombat = absorbBarFullCombat or visualFrame:CreateTexture(nil, "ARTWORK");
		absorbBarZeroCombat = absorbBarZeroCombat or visualFrame:CreateTexture(nil, "ARTWORK");
		absorbBarFullNoCombat = absorbBarFullNoCombat or visualFrame:CreateTexture(nil, "ARTWORK");
		absorbBarZeroNoCombat = absorbBarZeroNoCombat or visualFrame:CreateTexture(nil, "ARTWORK");
		absorbBarOverlay = absorbBarOverlay or visualFrame:CreateTexture(nil, "ARTWORK", nil, 1);
		incomingBarFullCombat = incomingBarFullCombat or visualFrame:CreateTexture(nil, "ARTWORK");
		incomingBarZeroCombat = incomingBarZeroCombat or visualFrame:CreateTexture(nil, "ARTWORK");
		incomingBarFullNoCombat = incomingBarFullNoCombat or visualFrame:CreateTexture(nil, "ARTWORK");
		incomingBarZeroNoCombat = incomingBarZeroNoCombat or visualFrame:CreateTexture(nil, "ARTWORK");		

		healthBarFullCombat:SetTexture("Interface\\TargetingFrame\\UI-StatusBar");
		healthBarZeroCombat:SetTexture("Interface\\TargetingFrame\\UI-StatusBar");
		healthBarFullNoCombat:SetTexture("Interface\\TargetingFrame\\UI-StatusBar");
		healthBarZeroNoCombat:SetTexture("Interface\\TargetingFrame\\UI-StatusBar");
		absorbBarFullCombat:SetTexture("Interface\\RaidFrame\\Shield-Fill");
		absorbBarZeroCombat:SetTexture("Interface\\RaidFrame\\Shield-Fill");
		absorbBarFullNoCombat:SetTexture("Interface\\RaidFrame\\Shield-Fill");
		absorbBarZeroNoCombat:SetTexture("Interface\\RaidFrame\\Shield-Fill");
		absorbBarOverlay:SetTexture("Interface\\RaidFrame\\Shield-Overlay");
		incomingBarFullCombat:SetTexture("Interface\\TargetingFrame\\UI-StatusBar");
		incomingBarZeroCombat:SetTexture("Interface\\TargetingFrame\\UI-StatusBar");
		incomingBarFullNoCombat:SetTexture("Interface\\TargetingFrame\\UI-StatusBar");
		incomingBarZeroNoCombat:SetTexture("Interface\\TargetingFrame\\UI-StatusBar");
		
		healthBarZeroCombat:SetPoint("TOPLEFT", healthBarFullCombat);
		healthBarZeroCombat:SetPoint("BOTTOMRIGHT", healthBarFullCombat);
		
		healthBarFullNoCombat:SetPoint("TOPLEFT", healthBarFullCombat);
		healthBarFullNoCombat:SetPoint("BOTTOMRIGHT", healthBarFullCombat);
		
		healthBarZeroNoCombat:SetPoint("TOPLEFT", healthBarFullCombat);
		healthBarZeroNoCombat:SetPoint("BOTTOMRIGHT", healthBarFullCombat);
		
		absorbBarFullCombat:SetPoint("TOPLEFT", healthBarFullCombat, "TOPRIGHT");
		absorbBarFullCombat:SetPoint("BOTTOMLEFT", healthBarFullCombat, "BOTTOMRIGHT");
		
		absorbBarZeroCombat:SetPoint("TOPLEFT", absorbBarFullCombat);
		absorbBarZeroCombat:SetPoint("BOTTOMRIGHT", absorbBarFullCombat);
		
		absorbBarFullNoCombat:SetPoint("TOPLEFT", absorbBarFullCombat);
		absorbBarFullNoCombat:SetPoint("BOTTOMRIGHT", absorbBarFullCombat);
		
		absorbBarOverlay:SetPoint("TOPLEFT", absorbBarFullCombat);
		absorbBarOverlay:SetPoint("BOTTOMRIGHT", absorbBarFullCombat);
		
		-- incomingBarFullCombat is anchored during configureHealthBar()
		
		incomingBarZeroCombat:SetPoint("TOPLEFT", incomingBarFullCombat);
		incomingBarZeroCombat:SetPoint("BOTTOMRIGHT", incomingBarFullCombat);
		
		incomingBarFullNoCombat:SetPoint("TOPLEFT", incomingBarFullCombat);
		incomingBarFullNoCombat:SetPoint("BOTTOMRIGHT", incomingBarFullCombat);
		
		incomingBarZeroNoCombat:SetPoint("TOPLEFT", incomingBarFullCombat);	
		incomingBarZeroNoCombat:SetPoint("BOTTOMRIGHT", incomingBarFullCombat);
		
		absorbBarOverlay:SetVertTile(true);
		absorbBarOverlay:SetHorizTile(true);
		
		healthBarText = healthBarText or visualFrame:CreateFontString(nil, "ARTWORK", nil , 1)
		healthBarText:SetIgnoreParentScale(true);
		healthBarText:SetFontObject(owner:GetHealthBarFont());
		
		-- initial configuration
		configureHealthBar();
	end

	-- updates the power bar to reflect frequently-changing game state; see updatePowerBarInfrequent() and createPowerBar()
	local function updatePowerBarFrequent()
		if (shownUnit) then
			if (UnitExists(shownUnit) and not UnitIsDeadOrGhost(shownUnit) and owner:GetProperty("EnablePowerBar")) then
				local power, powerMax = ctSafeNumber(UnitPower(shownUnit)), ctSafeNumber(UnitPowerMax(shownUnit));
				if (not (power and powerMax and powerMax > 0)) then powerBar:Hide(); return; end	-- restricted "secret number"; skip rather than crash
				local powerRatio = power / powerMax;
				if (powerRatio < 0.01) then 
					powerBar:Hide();
				else 
					powerBar:SetWidth(powerBarWidth*min(1,powerRatio));
					powerBar:Show();
				end
				-- use the same alpha rules as the health bar for consistency... except base it on UnitPower == UnitPowerMax instead of Health == HealthMax
				if (InCombatLockdown()) then
					powerBar:SetAlpha(powerRatio > 0.99 and owner:GetProperty("ColorUnitFullHealthCombat")[4] or owner:GetProperty("ColorUnitZeroHealthCombat")[4]);
				else
					powerBar:SetAlpha(powerRatio > 0.99 and owner:GetProperty("ColorUnitFullHealthNoCombat")[4] or owner:GetProperty("ColorUnitZeroHealthNoCombat")[4]);
				end	
			else
				powerBar:Hide();
			end
		end
	end
	
	-- updates the power bar to reflect infrequently-changing game state; see updatePowerBarFrequent() and createPowerBar()
	local function updatePowerBarInfrequent()
		if (shownUnit and UnitExists(shownUnit)) then
			local powerType, powerToken, altR, altG, altB = UnitPowerType(shownUnit);
			local info = PowerBarColor[powerToken];
			if ( info ) then
				--The PowerBarColor takes priority
				powerBar:SetVertexColor(info.r, info.g, info.b);
			else
				if (not altR) then
					-- Couldn't find a power token entry. Default to indexing by power type or just mana if  we don't have that either.
					info = PowerBarColor[powerType] or PowerBarColor["MANA"];
					powerBar:SetVertexColor(info.r, info.g, info.b);
				else
					powerBar:SetVertexColor(altR, altG, altB);
				end
			end
		else
			local info = PowerBarColor["MANA"]
			powerBar:SetVertexColor(info.r, info.g, info.b);
		end
	end
	
	-- infrequently configures the power bar texture according to user settings; see createPowerBar()
	local function configurePowerBar()
		if (owner:GetProperty("HealthBarAsBackground")) then	-- the powerBar shifts in size and location to align nicely with the healthBar
			powerBar:SetPoint("BOTTOMLEFT", visualFrame, 4, 4);		
		else
			powerBar:SetPoint("BOTTOMLEFT", visualFrame, 10, 5);
		end
		powerBarWidth = (owner:GetProperty("HealthBarAsBackground") and 82) or 70;
	end
	
	-- creates the power bar texture
	local function createPowerBar()
		powerBar = powerBar or visualFrame:CreateTexture(nil, "ARTWORK", nil, 1);
		powerBar:SetTexture("Interface\\TargetingFrame\\UI-StatusBar");
		powerBar:SetHeight(7);
		
		-- initial configuration
		configurePowerBar();
	end

	-- frequently updates roleTexture to reflect game state; see createRoleTexture()
	local function updateRoleTexture()
		if (shownUnit and UnitExists(shownUnit)) then
			local targetIndex, outOfPhase, roleAssigned = GetRaidTargetIndex(shownUnit), UnitPhaseReason(shownUnit), UnitGroupRolesAssigned(shownUnit);
			if (targetIndex and targetIndex <= 8) then
				roleTexture:SetTexture("Interface\\TargetingFrame\\UI-RaidTargetingIcons");
				if (targetIndex == 1) then
					roleTexture:SetTexCoord(0.00, 0.25, 0.00, 0.25);
				elseif (targetIndex == 2) then
					roleTexture:SetTexCoord(0.25, 0.50, 0.00, 0.25);
				elseif (targetIndex == 3) then
					roleTexture:SetTexCoord(0.50, 0.75, 0.00, 0.25);
				elseif (targetIndex == 4) then
					roleTexture:SetTexCoord(0.75, 1.00, 0.00, 0.25);
				elseif (targetIndex == 5) then
					roleTexture:SetTexCoord(0.00, 0.25, 0.25, 0.50);
				elseif (targetIndex == 6) then
					roleTexture:SetTexCoord(0.25, 0.50, 0.25, 0.50);
				elseif (targetIndex == 7) then
					roleTexture:SetTexCoord(0.50, 0.75, 0.25, 0.50);
				else
					roleTexture:SetTexCoord(0.75, 1.00, 0.25, 0.50);
				end
				roleTexture:Show();
			elseif (outOfPhase) then
				roleTexture:SetTexture("Interface\\TargetingFrame\\UI-PhasingIcon");
				roleTexture:SetTexCoord(0.15625, 0.84375, 0.15625, 0.84375);
				roleTexture:Show();
			elseif (roleAssigned == "DAMAGER") then
				roleTexture:SetTexture("Interface\\LFGFrame\\UI-LFG-ICON-PORTRAITROLES");
				roleTexture:SetTexCoord(0.3125, 0.609375, 0.34375, 0.640625);  -- GetTexCoordsForRoleSmallCircle("DAMAGER");
				roleTexture:Show();
			elseif (roleAssigned == "HEALER") then
				roleTexture:SetTexture("Interface\\LFGFrame\\UI-LFG-ICON-PORTRAITROLES");
				roleTexture:SetTexCoord(0.3125, 0.609375, 0.015625, 0.3125);  -- GetTexCoordsForRoleSmallCircle("HEALER");
				roleTexture:Show();
			elseif (roleAssigned == "TANK") then
				roleTexture:SetTexture("Interface\\LFGFrame\\UI-LFG-ICON-PORTRAITROLES");
				roleTexture:SetTexCoord(0, 0.296875, 0.34375, 0.640625);  -- GetTexCoordsForRoleSmallCircle("TANK");
				roleTexture:Show();
			else	-- no role assigned
				roleTexture:Hide();
			end
		end
	end

	-- permanently creates roleTexture to display the role or raid-target icon
	local function createRoleTexture()
		roleTexture = roleTexture or visualFrame:CreateTexture(nil, "OVERLAY");
		roleTexture:SetSize(12,12);
		roleTexture:SetPoint("TOPLEFT", visualFrame, 1.20, -1.20);
		
		-- no "configureRoleTexture()" function because there are no corresponding user settings
	end
		
	-- frequently updates status indicators to reflect game state; see createRaidStatusIndicators()
	local function updateRaidStatusIndicators()
		if (shownUnit and UnitExists(shownUnit)) then
			local summonStatus, readyStatus, afkStatus, connectionStatus = 
				IncomingSummonStatus(shownUnit), 		 -- at the top of the file, IncomingSummonStatus is defined as C_IncomingSummon.IncomingSummonStatus or it just returns zero in classic
				GetReadyCheckStatus(shownUnit),
				UnitIsAFK(shownUnit),
				UnitIsConnected(shownUnit)
			if (summonStatus > 0) then
				statusTexture:SetTexture(2470702);
				statusTexture:Show();
				statusFontString:Show()
				if (summonStatus == 1) then		-- GetAtlasInfo("Raid-Icon-SummonPending")
					statusTexture:SetTexCoord(0.5390625, 0.7890625, 0.015625, 0.515625);
					statusFontString:SetText("Summoned");
					statusNoticeBackground:Show();
					statusAlarmBackground:Hide();
				elseif (summonStatus == 2) then		-- GetAtlasInfo("Raid-Icon-SummonAccepted")
					statusTexture:SetTexCoord(0.0078125, 0.2578125, 0.15625, 0.515625);
					statusFontString:SetText("Arriving");
					statusNoticeBackground:Show();
					statusAlarmBackground:Hide();
				else					-- GetAtlasInfo("Raid-Icon-SummonDeclined")
					statusTexture:SetTexCoord(0.2734375, 0.5234375, 0.015625, 0.515625);
					statusFontString:SetText("Declined");
					statusNoticeBackground:Hide();
					statusAlarmBackground:Show();  -- alarm!
				end
			elseif (readyStatus) then
				statusTexture:Show();
				if (readyStatus == "notready") then
					statusTexture:SetTexture(READY_CHECK_NOT_READY_TEXTURE);
					statusTexture:SetTexCoord(0,1,0,1);
					statusFontString:Show();
					statusFontString:SetText("Not Ready");
					statusNoticeBackground:Hide();
					statusAlarmBackground:Show();  -- alarm!
				elseif (readyStatus == "waiting") then
					statusFontString:Show();
					statusNoticeBackground:Show();
					statusAlarmBackground:Hide();
					if ((durabilityAverage or 100) < (module:getOption("CTRA_MonitorDurability") or 50) and GetTime() - (durabilityTime or 0) < 30) then
						statusTexture:SetTexture(1121272);
						statusTexture:SetTexCoord(0.4609375, 0.5234375, 0.328125, 0.390625);
						statusFontString:SetText("Gear: " .. durabilityAverage .. "%");
					else
						statusTexture:SetTexture(READY_CHECK_WAITING_TEXTURE);
						statusTexture:SetTexCoord(0,1,0,1);
						statusFontString:SetText("No Reply");
					end
				else
					statusTexture:SetTexture(READY_CHECK_READY_TEXTURE);
					statusTexture:SetTexCoord(0,1,0,1);
					statusFontString:Hide();
					statusNoticeBackground:Hide();
					statusAlarmBackground:Hide();
				end
			elseif (afkStatus) then
				statusTexture:Hide();
				statusFontString:Show();
				statusFontString:SetText("AFK");
				statusNoticeBackground:Show();
				statusAlarmBackground:Hide();
			elseif (connectionStatus == false) then
				statusTexture:Hide();
				statusFontString:Show();
				statusFontString:SetText("DC");
				statusNoticeBackground:Hide();
				statusAlarmBackground:Show();  -- alarm!
			else
				statusTexture:Hide();
				statusFontString:Hide();
				statusNoticeBackground:Hide();
				statusAlarmBackground:Hide();
			end
		else
			statusTexture:Hide();
			statusFontString:Hide();
			statusNoticeBackground:Hide();
			statusAlarmBackground:Show();  -- alarm!
		end
	end
	
	-- infrequently configures raid-status indicators according to user settings; see createRaidStatusIndicators()
	local function configureRaidStatusIndicators()
		statusNoticeBackground:SetVertexColor(unpack(owner:GetProperty("ColorReadyCheckWaiting")));
		statusAlarmBackground:SetVertexColor(unpack(owner:GetProperty("ColorReadyCheckNotReady")));
	end
	
	-- permanently creates textures and a fontstring to describe a toon's readiness for raiding
	local function createRaidStatusIndicators()
		statusTexture = visualFrame:CreateTexture(nil, "OVERLAY");
		statusTexture:SetPoint("BOTTOMLEFT", 1.80, 1.80);
		statusTexture:SetSize(15, 15);
		
		statusFontString = visualFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall");
		statusFontString:SetPoint("TOP", visualFrame, "CENTER");
		
		statusNoticeBackground = visualFrame:CreateTexture(nil, "ARTWORK", nil, 2); -- the 4th parameter, '2', draws this in front of the power bar
		statusNoticeBackground:SetPoint("TOPLEFT", 4, -4);
		statusNoticeBackground:SetPoint("BOTTOMRIGHT", -4, 4);
		statusNoticeBackground:SetColorTexture(1,1,1);
		
		statusAlarmBackground = visualFrame:CreateTexture(nil, "ARTWORK", nil, 2);
		statusAlarmBackground:SetPoint("TOPLEFT", 4, -4);
		statusAlarmBackground:SetPoint("BOTTOMRIGHT", -4, 4);
		statusAlarmBackground:SetColorTexture(1,1,1);
		
		-- This is a hack because certain status changes seemed during development to not consistently
		-- push an event notification to the handler.  Originally introduced at 2 seconds, but now
		-- slowing to 10 seconds in 8.3.0.9 as an experiment to see if this can be fully removed.
		--
		--  Update: In 9.0.5.8 a typo was found which could have been the root cause of the problem.
		--  Now extending this ticker to 15 seconds as a continued experiment to see if it can be removed.
		C_Timer.NewTicker(15, updateRaidStatusIndicators);
		
		-- initial configuration
		configureRaidStatusIndicators();
	end
	
	-- frequently updates unitNameFontString to reflect game state
	local updateUnitNameFontString = function()
		if (shownUnit and UnitExists(shownUnit)) then
			-- show the name, but omit the server
			local name;
			name = strsplit("-", UnitName(shownUnit) or "", 2);
			local classR, classG, classB = GetClassColor(select(2,UnitClass(shownUnit)));
			unitNameFontString:SetText(name);
			while (unitNameFontString:GetStringWidth() > unitNameFontString:GetWidth()) do
				name = name:sub(1, -2);
				unitNameFontString:SetText(name);
			end
			unitNameFontString:SetTextColor(classR, classG, classB);
		else
			unitNameFontString:SetText("");
		end
	end

	-- infrequently configures unitNameFontString according to user settings
	local configureUnitNameFontString = function()	
		local effectiveScale = visualFrame:GetEffectiveScale();
		unitNameFontString:SetPoint("BOTTOMLEFT", visualFrame, "LEFT", 13 * effectiveScale, 2.5 * effectiveScale);
		unitNameFontString:SetPoint("BOTTOMRIGHT", visualFrame, "RIGHT", -13 * effectiveScale, 2.5 * effectiveScale);
	end
	
	-- permanently creates unitNameFontString
	local function createUnitNameFontString()
		unitNameFontString = unitNameFontString or visualFrame:CreateFontString(nil, "OVERLAY");
		unitNameFontString:SetDrawLayer("OVERLAY", 1);	-- in front of icons
		unitNameFontString:SetIgnoreParentScale(true);
		unitNameFontString:SetFontObject(owner:GetUnitNameFont());
		
		-- intial configuration
		configureUnitNameFontString();
	end
	
	local function updateAuraButton(frame, name, icon, count, debuffType, duration, expirationTime)
		frame:Show();
		frame.texture:SetTexture(icon);
		frame.name = name;
		frame.count = count or 0;
		frame.debuffType = debuffType;
		if (frame.text) then
			if (frame.count > 1) then
				local color = DebuffTypeColor[debuffType or ""] or DebuffTypeColor[""];
				frame.text:SetText(count < 100 and count or "*");
				frame.text:SetTextColor(1 - (1-color.r)/2, 1 - (1-color.g)/2, 1 - (1-color.b)/2);
			else
				frame.text:SetText("");
			end
		end
		if (owner:GetProperty("ShowReverseCooldown") and duration and duration >= 12 and expirationTime and expirationTime > 0) then
			frame.cooldown:SetCooldown(expirationTime - duration * 0.4, duration * 0.4);
		else
			frame.cooldown:Clear();
		end
	end

	-- frequently updates buff and debuff icons to reflect game state; see createAuras() and configureAuras()
	local function updateAuras()
		-- STEP 1: prioritized buffs and debuffs for boss encounters, starting at the middle of the frame
		-- STEP 2: other buffs and debuffs, filtered, at the right edge of the frame
	
		-- STEP 1:
		local numShown = 0;
		wipe(auraBossShown);
		local frame = auraBoss1;
		local encounter = module:isInEncounter() or select(3, GetInstanceInfo()) == 8;	-- raid fights, or mythic plus dungeons
		if (encounter and shownUnit and UnitExists(shownUnit) and owner:GetProperty("ShowBossAuras")) then		
			for auraIndex = 1, 40 do
				local aura = C_UnitAuras.GetBuffDataByIndex(shownUnit, auraIndex)
				if aura and frame then
					if  (module.CTRA_Configuration_BossAuras[aura.spellId] and (aura.applications or 0) >= module.CTRA_Configuration_BossAuras[aura.spellId]) then
						auraBossShown[aura.spellId] = true;
						numShown = numShown + 1;
						updateAuraButton(frame, aura.name, aura.icon, aura.applications, aura.dispelName, aura.duration, aura.expirationTime);
						frame = frame.next
					end
				else
					--either no more buffs to show, or no more frames to display them
					break;
				end
			end
			for auraIndex = 1, 40 do
				local aura = C_UnitAuras.GetDebuffDataByIndex(shownUnit, auraIndex)
				if aura and frame then
					if (module.CTRA_Configuration_BossAuras[aura.spellId] and (aura.applications or 0) >= module.CTRA_Configuration_BossAuras[aura.spellId]) then
						auraBossShown[aura.spellId] = true;
						numShown = numShown + 1;
						updateAuraButton(frame, aura.name, aura.icon, aura.applications, aura.dispelName, aura.duration, aura.expirationTime);
						frame = frame.next
					end
				else
					--either no more debuffs to show, or no more frames to display them
					break;
				end
			end
			auraBoss1:SetPoint("BOTTOM", 8 - 8 * min(4,numShown), 5);
			if (numShown > 0) then
				healthBarText:SetPoint("RIGHT", visualFrame, "CENTER");
				healthBarText:SetPoint("LEFT", visualFrame, -10, 0);
			else
				healthBarText:SetPoint("RIGHT", visualFrame);
				healthBarText:SetPoint("LEFT", visualFrame);
			end
		else
			healthBarText:SetPoint("RIGHT", visualFrame);
			healthBarText:SetPoint("LEFT", visualFrame);
		end
		while (numShown  < 4) do
			numShown = numShown + 1;
			frame:Hide();
			frame = frame.next;
		end

		-- STEP 2:
		local filterType = (InCombatLockdown() and owner:GetProperty("AuraFilterCombat") or owner:GetProperty("AuraFilterNoCombat"));
		if(shownUnit and UnitExists(shownUnit) and not UnitIsDeadOrGhost(shownUnit) and filterType ~= 6) then	
			local filterText;
			if (filterType == 1) then
				filterText = "RAID HELPFUL";	-- default out of combat
			elseif (filterType == 2) then
				filterText = "RAID HARMFUL";	-- default in combat
			elseif (filterType == 3) then
				filterText = "HELPFUL";
			elseif (filterType == 4) then
				filterText = "HARMFUL";
			elseif (filterType == 5) then
				filterText = "HELPFUL";		-- further filtered by conditional statements during for loop below
			end
			for auraIndex = 1, 40 do
				local aura = C_UnitAuras.GetAuraDataByIndex(shownUnit, auraIndex, filterText)
				if (aura and frame) then
					if(
						auraBossShown[aura.spellId] ~= true
						and (filterType == 2 or filterType == 4 or not SpellIsSelfBuff(aura.spellId))				-- excludes self-only buffs
						and (filterType ~= 5 or aura.isFromPlayerOrPlayerPet or aura.sourceUnit == "vehicle")		-- complements filterType == 5  (buffs cast by the player only)
					) then
						numShown = numShown + 1;
						updateAuraButton(frame, aura.name, aura.icon, aura.applications, aura.dispelName, aura.duration, aura.expirationTime);
						frame = frame.next;
					end
				else
					--either no more buffs to show, or no more frames to display them
					break;
				end
			end
		end
		while (numShown < 8) do
			numShown = numShown + 1;
			frame:Hide();
			frame = frame.next;
		end
	end
	
	-- infrequently configures the aura and auraBoss textures according to user settings; see createAuras()
	local function configureAuras()
		local bgr, bgg, bgb, bga = unpack(owner:GetProperty("ColorBackground"));
		bgr, bgg, bgb, bga = (bgr or 1) * 0.5, (bgg or 1) * 0.5, (bgb or 1) * 0.5, (bga or 1) * 0.25 + 0.5
	
		aura1.cooldown:SetSwipeColor(bgr, bgg, bgb, bga);
		aura2.cooldown:SetSwipeColor(bgr, bgg, bgb, bga);
		aura3.cooldown:SetSwipeColor(bgr, bgg, bgb, bga);
		aura4.cooldown:SetSwipeColor(bgr, bgg, bgb, bga);
		aura5.cooldown:SetSwipeColor(bgr, bgg, bgb, bga);
		auraBoss1.cooldown:SetSwipeColor(bgr, bgg, bgb, bga);
		auraBoss2.cooldown:SetSwipeColor(bgr, bgg, bgb, bga);
		auraBoss3.cooldown:SetSwipeColor(bgr, bgg, bgb, bga);
	end

	-- permanently creates the aura and auraBoss textures 
	local function createAuras()
		local function constructAura(x, y)
			local frame = CreateFrame("Frame", nil, visualFrame);
			frame:SetSize(10,10);
			frame:SetPoint("TOPRIGHT", x, y);
			frame.texture = frame:CreateTexture(nil, "OVERLAY", nil, 1)		-- just behind boss auras, if there are enough of them
			frame.texture:SetAllPoints();
			frame.texture:SetTexCoord(0.04,0.96,0.04,0.96);
			frame.cooldown = CreateFrame("Cooldown", nil, frame, "CooldownFrameTemplate");
			frame.cooldown:SetAllPoints();
			frame.cooldown:SetDrawEdge(false);
			frame.cooldown:SetReverse(true);
			
			-- Interrupt the WoW 10.x implementation of cooldown timers
			local cooldownTimer = frame.cooldown:GetRegions()
			if cooldownTimer and cooldownTimer:IsObjectType("FontString") then
				cooldownTimer:ClearAllPoints()
			end
			
			return frame;
		end

		local function constructAuraBoss()
			local frame = CreateFrame("Frame", nil, visualFrame);
			frame:SetSize(16,16);
			frame.texture = frame:CreateTexture(nil, "OVERLAY", nil, 2)
			frame.texture:SetAllPoints();
			frame.texture:SetTexCoord(0.04,0.96,0.04,0.96);
			frame.cooldown = CreateFrame("Cooldown", nil, frame, "CooldownFrameTemplate");
			frame.cooldown:SetAllPoints();
			frame.cooldown:SetDrawEdge(false);
			frame.cooldown:SetReverse(true);
			frame.text = frame:CreateFontString(nil, "OVERLAY", nil, 2);		-- just ahead non-boss auras, if there are enough of them
			frame.text:SetFontObject(owner:GetCountFont());
			frame.text:SetIgnoreParentScale(true);
			frame.text:SetPoint("BOTTOM", frame, 1, 0);
			return frame;
		end

		auraBoss1 = auraBoss1 or constructAuraBoss();
		auraBoss2 = auraBoss2 or constructAuraBoss();
		auraBoss3 = auraBoss3 or constructAuraBoss();
		auraBoss4 = auraBoss4 or constructAuraBoss();
		
		aura1 = aura1 or constructAura(-5, -5, aura1Frame);
		aura2 = aura2 or constructAura(-5, -15, aura1Frame);
		aura3 = aura3 or constructAura(-5, -25, aura1Frame);
		aura4 = aura4 or constructAura(-15, -25, aura1Frame);
		aura5 = aura5 or constructAura(-15, -15, aura1Frame);
		
		auraBoss1.next = auraBoss2;
		auraBoss2.next = auraBoss3;
		auraBoss3.next = auraBoss4;
		auraBoss4.next = aura1;
		aura1.next = aura2;
		aura2.next = aura3;
		aura3.next = aura4;
		aura4.next = aura5;
		
		auraBoss2:SetPoint("LEFT", auraBoss1, "RIGHT", 1, 0);
		auraBoss3:SetPoint("LEFT", auraBoss2, "RIGHT", 1, 0);
		auraBoss4:SetPoint("LEFT", auraBoss3, "RIGHT", 1, 0);
		
		-- initial configuration
		configureAuras();
	end
	
	-- frequently displays a tooltip when mousing over secureButton or secureButtonDebuffFirst
	local tooltipTable = { };
	local strings = {
		"%s#%s#%f:%f:%f:1:1:1", 	-- 1 name and level
		"%s#%s#0.5:0.5:0.5", 		-- 2 pet type
		"%s#%s#1:1:1:0.5:0.5:0.5", 	-- 3 race/class and range/phase/group
		"%s#0.5:0.5:0.5",		-- 4 war mode
		"|T%s:0|t %s (%d)#%f:%f:%f",	-- 5 aura with stacks
		"|T%s:0|t %s#%f:%f:%f",		-- 6 aura without stacks
		L["CT_RaidAssist/PlayerFrame/TooltipFooter"] .. "#0.5:0.5:0.5#s:0.8",	-- 7 footer if the window has been configured
		"|T%s:0|t %s from |T%s:0|t %s#0.9:0.9:0.9",				-- 8 complex consumable buff
		"|T%s:0|t %s#0.9:0.9:0.9",						-- 9 simple consumable buff
	};
	local function displayTooltip(button)
		wipe(tooltipTable);
		if (shownUnit and UnitExists(shownUnit)) then
			--GameTooltip:SetOwner(parent, (owner:GetProperty("GrowUpward") and "ANCHOR_BOTTOMRIGHT") or "ANCHOR_TOPLEFT");
			local className, classFilename = UnitClass(shownUnit);
			local r,g,b = GetClassColor(classFilename);
			tinsert(tooltipTable, strings[1]:format(UnitName(shownUnit) or "", UnitLevel(shownUnit) or "", r, g, b));
			local mapid = C_Map.GetBestMapForUnit(shownUnit);
			local subgroup = tonumber(shownUnit:sub(5)) and select(3, GetRaidRosterInfo(tonumber(shownUnit:sub(5))))
			if (isPet) then
				local owner = UnitName(shownUnit:sub(1,-4));
				
				tinsert(tooltipTable, strings[2]:format(select(2, UnitClass(shownUnit:sub(1,-4))) == "HUNTER" and UNITNAME_TITLE_PET) or UNITNAME_TITLE_MINION, owner);
			else
				tinsert(tooltipTable, strings[3]:format(
					(UnitRace(shownUnit) or "") .. " " .. (className or ""),
					(
						(not inRangeSafe(shownUnit) and mapid and C_Map.GetMapInfo(mapid).name)
						or (subgroup and "Gp " .. subgroup) 
						or ""
					)
				));
			end
			if (UnitPhaseReason(shownUnit) == 2) then
				tinsert(tooltipTable, strings[4]:format(C_PvP.IsWarModeDesired() and ERR_PVP_WARMODE_TOGGLE_OFF or ERR_PVP_WARMODE_TOGGLE_ON));
			end

			if (auraBoss1:IsShown()) then
				local color = DebuffTypeColor[auraBoss1.debuffType or ""];
				tinsert(tooltipTable, auraBoss1.count > 1 and strings[5]:format(auraBoss1.texture:GetTexture() or "", auraBoss1.name or "", auraBoss1.count, color.r, color.g, color.b) or strings[6]:format(auraBoss1.texture:GetTexture() or "", auraBoss1.name or "", color.r, color.g, color.b));
				if (auraBoss2:IsShown()) then
					color = DebuffTypeColor[auraBoss2.debuffType or ""];
					tinsert(tooltipTable, auraBoss2.count > 1 and strings[5]:format(auraBoss2.texture:GetTexture() or "", auraBoss2.name or "", auraBoss2.count, color.r, color.g, color.b) or strings[6]:format(auraBoss2.texture:GetTexture() or "", auraBoss2.name or "", color.r, color.g, color.b));
					if (auraBoss3:IsShown()) then
						color = DebuffTypeColor[auraBoss3.debuffType or ""];
						tinsert(tooltipTable, auraBoss3.count > 1 and strings[5]:format(auraBoss1.texture:GetTexture() or "", auraBoss3.name or "", auraBoss3.count, color.r, color.g, color.b) or strings[6]:format(auraBoss3.texture:GetTexture() or "", auraBoss3.name or "", color.r, color.g, color.b));
						if (auraBoss4:IsShown()) then
							color = DebuffTypeColor[auraBoss4.debuffType or ""];
							tinsert(tooltipTable, auraBoss4.count > 1 and strings[5]:format(auraBoss1.texture:GetTexture() or "", auraBoss4.name or "", auraBoss4.count, color.r, color.g, color.b) or strings[6]:format(auraBoss4.texture:GetTexture() or "", auraBoss4.name or "", color.r, color.g, color.b));
						end
					end
				end
			end
			if (aura1:IsShown()) then
				local color = DebuffTypeColor[aura1.debuffType or ""];
				tinsert(tooltipTable, strings[6]:format(aura1.texture:GetTexture() or "", aura1.name or "", color.r, color.g, color.b));
				if (aura2:IsShown()) then
					color = DebuffTypeColor[aura2.debuffType or ""];
					tinsert(tooltipTable, strings[6]:format(aura2.texture:GetTexture() or "", aura2.name or "", color.r, color.g, color.b));
					if (aura3:IsShown()) then
						color = DebuffTypeColor[aura3.debuffType or ""];
						tinsert(tooltipTable, strings[6]:format(aura3.texture:GetTexture() or "", aura3.name or "", color.r, color.g, color.b));
						if (aura4:IsShown()) then
							color = DebuffTypeColor[aura4.debuffType or ""];
							tinsert(tooltipTable, strings[6]:format(aura4.texture:GetTexture() or "", aura4.name or "", color.r, color.g, color.b));
							if (aura5:IsShown()) then
								color = DebuffTypeColor[aura5.debuffType or ""];
								tinsert(tooltipTable, strings[6]:format(aura5.texture:GetTexture() or "", aura5.name or "", color.r, color.g, color.b));
							end
						end
					end
				end
			end

	

			if (not (InCombatLockdown() or isPet)) then
			--[[
				-- Durability
				if (durabilityAverage) then
					local time = GetTime() - (durabilityTime or 0);
					if (durabilityBroken > 0) then
						GameTooltip:AddLine(format(L["CT_RaidAssist/PlayerFrame/TooltipItemsBroken"],durabilityBroken, durabilityAverage, floor(time/60),time - floor(time/60) * 60), 1.0, 1.0, 0.0);
					else
						GameTooltip:AddLine(format(L["CT_RaidAssist/PlayerFrame/TooltipItemsNotBroken"],durabilityAverage,  floor(time/60),time - floor(time/60) * 60), 0.9, 0.9, 0.9);
					end
				end
			--]]
				-- Consumables
				for i=1, 40 do
					local aura = C_UnitAuras.GetAuraDataByIndex(shownUnit, i, "HELPFUL CANCELABLE")
					if not aura then
						break
					end
					local isConsumable = module.CTRA_Configuration_Consumables[aura.spellId];
					if (isConsumable) then
						if (type(isConsumable) == "number") then
							local itemName, __, __, __, __, __, __, __, __, itemIcon = GetItemInfo(isConsumable);
							if (itemName and itemIcon) then
								tinsert(tooltipTable, strings[8]:format(aura.icon, aura.name, itemIcon, itemName));
							else
								tinsert(tooltipTable, strings[9]:format(aura.icon, aura.name));
							end
						else
							tinsert(tooltipTable, strings[9]:format(aura.icon, aura.name));
						end
					end
				end
			
				-- Click-Casting
				StaticClickCastBroker():PopulateTooltip(tooltipTable);
			
				-- CTRA Footer
				if (owner.GetWindowID and not module:getOption("MOVABLE-CTRAWindow" .. owner:GetWindowID())) then
					tinsert(tooltipTable, strings[7]);
				end
				module:displayTooltip(button, tooltipTable, owner:GetProperty("GrowUpward") and "ANCHOR_BOTTOMRIGHT" or "ANCHOR_TOPLEFT", 0, 0, parent);
			else
				module:displayTooltip(button, tooltipTable, owner:GetProperty("GrowUpward") and "ANCHOR_BOTTOMRIGHT" or "ANCHOR_TOPLEFT", 0, 0, parent);
			end
		end
	end
		
	-- infreqently configures secureButton and secureButtonDebuffFirst according to user settings; see createSecureButtons()
	local function configureSecureButtons()
		if (InCombatLockdown()) then return; end
		local broker = StaticClickCastBroker();
		local macro1, macro2, attributes = broker:GetMacros();
		secureButton:SetAttribute("macrotext", macro1);
		secureButtonDebuffFirst:SetAttribute("macrotext", macro2);
		local toggleMenu = module:getOption("CTRAFrames_ClickCast_ToggleMenu") or 7;
		local target = module:getOption("CTRAFrames_ClickCast_Target") or 1;
		secureButton:SetAttribute("type", target == 1 and "target" or nil);
		secureButton:SetAttribute("type2", attributes["type2"] and "macro" or toggleMenu == 1 and "togglemenu" or nil);
		secureButton:SetAttribute("shift-type2", attributes["shift-type2"] and "macro" or toggleMenu == 2 and "togglemenu" or nil);
		secureButton:SetAttribute("ctrl-type2", attributes["ctrl-type2"] and "macro" or toggleMenu == 3 and "togglemenu" or nil);
		secureButton:SetAttribute("alt-type2", attributes["alt-type2"] and "macro" or toggleMenu == 4 and "togglemenu" or nil);
		secureButton:SetAttribute("type1", attributes["type1"] and "macro" or toggleMenu == 6 and "togglemenu" or nil);
		secureButton:SetAttribute("shift-type1", attributes["shift-type1"] and "macro" or toggleMenu == 7 and "togglemenu" or nil);
		secureButton:SetAttribute("ctrl-type1", attributes["ctrl-type1"] and "macro" or toggleMenu == 8 and "togglemenu" or nil);
		secureButton:SetAttribute("alt-type1", attributes["alt-type1"] and "macro" or toggleMenu == 9 and "togglemenu" or nil);
		secureButtonDebuffFirst:SetAttribute("type", target == 1 and "target" or nil);
		secureButtonDebuffFirst:SetAttribute("type2", attributes["type2"] and "macro" or toggleMenu == 1 and "togglemenu" or nil);
		secureButtonDebuffFirst:SetAttribute("shift-type2", attributes["shift-type2"] and "macro" or toggleMenu == 2 and "togglemenu" or nil);
		secureButtonDebuffFirst:SetAttribute("ctrl-type2", attributes["ctrl-type2"] and "macro" or toggleMenu == 3 and "togglemenu" or nil);
		secureButtonDebuffFirst:SetAttribute("alt-type2", attributes["alt-type2"] and "macro" or toggleMenu == 4 and "togglemenu" or nil);
		secureButtonDebuffFirst:SetAttribute("type1", attributes["type1"] and "macro" or toggleMenu == 6 and "togglemenu" or nil);
		secureButtonDebuffFirst:SetAttribute("shift-type1", attributes["shift-type1"] and "macro" or toggleMenu == 7 and "togglemenu" or nil);
		secureButtonDebuffFirst:SetAttribute("ctrl-type1", attributes["ctrl-type1"] and "macro" or toggleMenu == 8 and "togglemenu" or nil);
		secureButtonDebuffFirst:SetAttribute("alt-type1", attributes["alt-type1"] and "macro" or toggleMenu == 9 and "togglemenu" or nil);		
	end

	-- infrequently configures secureButtonCliqueFirst according to user settings; see createSecureButtons()
	local function configureCliqueIntegration(shouldEnable)
		if (Clique and shouldEnable) then
			secureButtonCliqueFirst:Show();
			Clique:RegisterFrame(secureButtonCliqueFirst);
		elseif (Clique) then
			secureButtonCliqueFirst:Hide();
			Clique:UnregisterFrame(secureButtonCliqueFirst);
		else
			secureButtonCliqueFirst:Hide();
		end
	end
	
	-- permanently creates secureButton, secureButtonDebuffFirst and secureButtonCliqueFirst
	local function createSecureButtons()
		-- main button used in most situations
		secureButton = CreateFrame("Button", nil, visualFrame, "SecureUnitButtonTemplate");
		secureButton:SetAllPoints();
		secureButton:RegisterForClicks("AnyDown");
		secureButton:HookScript("OnEnter", displayTooltip);

		-- alternative button with a different macro to prioritize decursing outside combat
		secureButtonDebuffFirst = CreateFrame("Button", nil, secureButton, "SecureUnitButtonTemplate");
		secureButtonDebuffFirst:SetAllPoints();
		secureButtonDebuffFirst:RegisterForClicks("AnyDown");
		secureButtonDebuffFirst:HookScript("OnEnter", displayTooltip);

		-- alternative button that integrates with the Clique addons if present and enabled
		secureButtonCliqueFirst = CreateFrame("Button", nil, secureButton, "SecureUnitButtonTemplate");
		secureButtonCliqueFirst:SetAllPoints();
		secureButtonCliqueFirst:HookScript("OnEnter", displayTooltip);

		-- initial configuration
		local broker = StaticClickCastBroker();
		broker:Register(configureSecureButtons);
		configureSecureButtons()
		configureCliqueIntegration(module:getOption("CTRAFrames_ClickCast_UseCliqueAddon") ~= false);
	end
	
	local function updateDurability(percent, broken, sender, __)
		if (shownUnit and sender == UnitName(shownUnit)) then
			durabilityAverage = percent;
			durabilityBroken = broken;
			durabilityTime = GetTime();
			updateRaidStatusIndicators();
		end
	end
	
	local function clearDurability()
		durabilityAverage, durabilityBroken, durabilityTime = nil, nil, nil;
	end
		
	-- PUBLIC FUNCTIONS
	
	function obj:Enable(unit, xOff, yOff)
		if (not unit) then
			self:Disable();
			return;
		end
		requestedUnit = unit;
		requestedXOff = xOff;
		requestedYOff = yOff;
		self:Update();
	end
	
	function obj:Disable()
		requestedUnit = nil;
		requestedXOff = nil;
		requestedYOff = nil;
		self:Update();
	end
	
	function obj:IsEnabled()
		return requestedUnit ~= nil
	end
	
	function obj:IsShown()
		return shownUnit ~= nil
	end
	
	function obj:Update(option, value)
		-- STEP 1: Construct the secureButton, secureButtonDebuffFirst and visualFrame if required, but only while out of combat, before proceeding to any of the following steps
		-- STEP 2: Respond to changes in the CTRA options affecting how the frames should appear and behaive, but only while out of combat
		-- STEP 3: Respond to changes directed by the parent window (requestedUnit, requestedXOff, requestedYOff) while respecting combat limitations

		-- STEP 1
		if not visualFrame then
			if InCombatLockdown() then
				return;
			else
				-- overall dimensions
				visualFrame = CreateFrame("Frame", nil, parent, BackdropTemplateMixin and "BackdropTemplate");
				visualFrame:SetSize(90, 40);
				visualFrame:SetScale(owner:GetProperty("PlayerFrameScale")/100);
								
				-- secure overlay buttons that can be clicked to do stuff (the secure configuration is made later in step 3)
				if (isDummy) then
					-- this is a mockup that shouldn't do anything interactive.  These are placeholders.
					secureButton = CreateFrame("Button")
					secureButton:SetParent(nil);
					secureButton:ClearAllPoints();
					secureButtonDebuffFirst = CreateFrame("Button", nil, secureButton)
					secureButtonCliqueFirst = CreateFrame("Button", nil, secureButton)
				else
					-- this is a real CTRA frame that should definitely be interactive!
					createSecureButtons();
					configureSecureButtons();
				end 
				
				-- all the non-secure textures to display useful information				
				createBackdrop();				
				createHealthBar();			
				createPowerBar();				
				createRoleTexture();
				createUnitNameFontString();
				createAuras();
				createRaidStatusIndicators();
			end
		end
		
		-- STEP 2:
		if (option) then
			optionsWaiting[option] = value;
		end
		if (not InCombatLockdown()) then
			for key, val in pairs(optionsWaiting) do
				if (key == "PlayerFrameScale") then
					visualFrame:SetScale((val or 100)/100);
					configureUnitNameFontString();
					configureHealthBar();
				elseif (
					   key == "ColorUnitFullHealthCombat"
					or key == "ColorUnitZeroHealthCombat"
					or key == "ColorUnitFullHealthNoCombat"
					or key == "ColorUnitZeroHealthNoCombat"
					or key == "ShowHealthText"
				) then
					configureHealthBar();
				elseif (
					key == "ColorReadyCheckWaiting"
					or key == "ColorReadyCheckNotReady"
				) then
					updateRaidStatusIndicators();
				elseif (
					key == "HealthBarAsBackground"
				) then
					configureHealthBar();
					configurePowerBar();
				elseif (key == "EnablePowerBar") then
					configurePowerBar();
				elseif (
					key == "ColorBackground"
					or key == "ColorBorder"
				) then
					configureBackdrop();
					configureAuras();
				elseif (
					key == "CTRAFrames_ClickCast_UseCliqueAddon"
				) then
					configureCliqueIntegration(val);
				elseif (
					key == "BorderThickness"
				) then
					configureBackdrop();
				else
					-- must be missing an option; so just reconfigure several!  (This is bad; don't do it)
					configureBackdrop();
					configureHealthBar();
					configurePowerBar();
					configureUnitNameFontString();
					configureAuras();
				end
			end
			wipe(optionsWaiting);
		end
		
		-- STEP 3:
		if (not InCombatLockdown() and (requestedUnit ~= shownUnit or requestedXOff ~= shownXOff or requestedYOff ~= shownYOff)) then
			-- set the flags
			shownUnit = requestedUnit;
			shownXOff = requestedXOff;
			shownYOff = requestedYOff;
			
			if (shownUnit and shownUnit:sub(-3, -1) == "pet") then
				isPet = true;
			else
				isPet = false;
			end

			-- register or de-register events
			if (not listenerFrame) then
				listenerFrame = CreateFrame("Frame", nil);
				listenerFrame:SetScript("OnEvent",
					function(__, event)
						if (event == "UNIT_NAME_UPDATE") then
							updateUnitNameFontString();
						elseif (event == "UNIT_HEALTH" or event == "UNIT_MAXHEALTH" or event == "UNIT_ABSORB_AMOUNT_CHANGED" or event == "UNIT_HEAL_PREDICTION") then
							updateHealthBar();
							updateBackdrop();
						elseif (event == "UNIT_POWER_UPDATE") then
							updatePowerBarFrequent();
						elseif (event == "UNIT_DISPLAYPOWER") then
							updatePowerBarInfrequent();
						elseif (event == "UNIT_AURA") then
							updateAuras();
							updateBackdrop();
							if (not InCombatLockdown()) then
								if C_UnitAuras.GetAuraDataByIndex(shownUnit, 1, "HARMFUL RAID") then
									secureButtonDebuffFirst:Show();
								else
									secureButtonDebuffFirst:Hide();
								end
							end
						elseif (event == "PLAYER_REGEN_DISABLED") then
							-- update the following BEFORE combat lockdown begins
							secureButtonDebuffFirst:Hide();
							-- update the following AFTER combat lockdown begins
							C_Timer.After(0.001, updateHealthBar);
							C_Timer.After(0.001, updateAuras);
						elseif (event == "PLAYER_REGEN_ENABLED") then
							if C_UnitAuras.GetAuraDataByIndex(shownUnit, 1, "HARMFUL RAID") then
								secureButtonDebuffFirst:Show();
							else
								secureButtonDebuffFirst:Hide();
							end
							updateAuras();
							updateHealthBar();
						elseif (event == "READY_CHECK") then
							local LD = LibStub:GetLibrary("LibDurability", true);
							if (LD) then LD:RequestDurability(); end
							updateRaidStatusIndicators();
						elseif (
							event == "INCOMING_SUMMON_CHANGED"
							or event == "CONFIRM_SUMMON"
							or event == "CANCEL_SUMMON"
							or event == "READY_CHECK_CONFIRM"
							or event == "READY_CHECK_FINISHED"
							or event == "PLAYER_FLAGS_CHANGED"
							or event == "UNIT_CONNECTION"
						) then
							updateRaidStatusIndicators();
							updateRoleTexture();
						elseif (
							event == "RAID_TARGET_UPDATE"
							or event == "UNIT_PHASE"
							--or event == "PARTY_MEMBER_ENABLE"
							--or event == "PARTY_MEMBER_DISABLE"
						) then
							updateRoleTexture();
						end
					end
				);
			end

			-- configure the visualFrame and its children
			if (shownUnit) then
				visualFrame:Show();
				RegisterStateDriver(visualFrame, "visibility", "[@" .. shownUnit .. ", exists] show; hide");
				listenerFrame:UnregisterAllEvents();  -- probably not required, but doing it to be absolute
				listenerFrame:RegisterUnitEvent("UNIT_NAME_UPDATE", shownUnit)
				listenerFrame:RegisterUnitEvent("UNIT_HEALTH", shownUnit)
				listenerFrame:RegisterUnitEvent("UNIT_MAXHEALTH", shownUnit)
				listenerFrame:RegisterUnitEvent("UNIT_POWER_UPDATE", shownUnit)
				listenerFrame:RegisterUnitEvent("UNIT_DISPLAYPOWER", shownUnit)
				listenerFrame:RegisterUnitEvent("UNIT_AURA", shownUnit)
				listenerFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
				listenerFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
				listenerFrame:RegisterEvent("READY_CHECK")
				listenerFrame:RegisterUnitEvent("READY_CHECK_CONFIRM", shownUnit)
				listenerFrame:RegisterEvent("READY_CHECK_FINISHED")
				listenerFrame:RegisterUnitEvent("PLAYER_FLAGS_CHANGED", shownUnit)
				listenerFrame:RegisterUnitEvent("UNIT_CONNECTION", shownUnit)
				listenerFrame:RegisterEvent("CANCEL_SUMMON")
				listenerFrame:RegisterEvent("CONFIRM_SUMMON")
				listenerFrame:RegisterEvent("RAID_TARGET_UPDATE")
				listenerFrame:RegisterUnitEvent("UNIT_PHASE", shownUnit)
				--listenerFrame:RegisterUnitEvent("PARTY_MEMBER_ENABLE")
				--listenerFrame:RegisterUnitEvent("PARTY_MEMBER_DISABLE")
				listenerFrame:RegisterUnitEvent("UNIT_HEAL_PREDICTION", shownUnit)
				if (UnitGetTotalAbsorbs ~= n0p) then
					listenerFrame:RegisterUnitEvent("INCOMING_SUMMON_CHANGED", shownUnit)
					listenerFrame:RegisterUnitEvent("UNIT_ABSORB_AMOUNT_CHANGED", shownUnit)
				end			
			else
				UnregisterStateDriver(visualFrame, "visibility");
				visualFrame:Hide();
				listenerFrame:UnregisterAllEvents();
				return;		-- go absolutely no further if we arn't supposed to be showing anything any more!
			end

			-- reposition the frames
			visualFrame:SetPoint("TOPLEFT", requestedXOff, requestedYOff);

			-- configure the secureButton for the new unit
			secureButton:SetAttribute("unit", shownUnit);
			secureButtonDebuffFirst:SetAttribute("unit", shownUnit);
			secureButtonCliqueFirst:SetAttribute("unit", shownUnit);
			if C_UnitAuras.GetAuraDataByIndex(shownUnit, 1, "HARMFUL RAID") then
				secureButtonDebuffFirst:Show();
			else
				secureButtonDebuffFirst:Hide();
			end
		end
		-- visualFrame's children must be updated whenever group composition changes in case the players have changed position within the group or raid.
		-- if shownUnit exists then it can be assumed the previous conditional evaluated to true at some point and therefore the configure___() funcs have been used
		if (shownUnit) then
			updateBackdrop();
			updateHealthBar();
			updatePowerBarInfrequent();
			updatePowerBarFrequent();
			updateRoleTexture();
			updateUnitNameFontString();
			updateAuras();
			updateRaidStatusIndicators();
			clearDurability();
		end
	end
	
	-- PUBLIC CONSTRUCTOR
	do
		owner = parentInterface;	
		parent = parentFrame;
		
		local LD = LibStub:GetLibrary("LibDurability", true);
		if (LD) then
			LD:Register(obj,updateDurability)
		end
	
		return obj;			-- that's it!  nothing else is done until obj:Enable()
	end
	
end	-- end CTRAPlayerFrame

--------------------------------------------
-- CTRATargetFrame

function NewCTRATargetFrame(parentInterface, parentFrame)
	
	-- PUBLIC INTERFACE
	
	local obj = { };
	
	-- PRIVATE PROPERTIES
	
	local owner;			-- pointer to the CTRAWindow interface for calling functions like :GetProperty()
	local parent;			-- pointer to the CTRAWindow's frame object that is a parent for the visualFrame
	local visualFrame;		-- generic frame that shows various textures
	local secureButton;		-- SecureUnitActionButton that sits in front and responds to mouseclicks
	local listenerFrame;		-- generic frame that listens to various events
	local requestedUnit;		-- the unit that this object is requested to display at the next opportunity
	local requestedXOff;		-- the x coordinate to position this object's frames at the next opportunity (relative to parent's left)w
	local requestedYOff;		-- the y coordinate to position this object's frames at the next opportunity (relative to parent's top)
	local shownUnit;		-- the unit that this object is currently showing (which cannot change during combat)
	local shownXOff;		-- the x coordinate this frame is currently showing
	local shownYOff;		-- the y coordinate this frame is currently showing
	local optionsWaiting = { };	-- a list of options that need to be triggered once combat ends
	
	-- graphical textures and fontstrings of visualFrame
	local background, border;
	local healthBarFullCombat, healthBarZeroCombat, healthBarFullNoCombat, healthBarZeroNoCombat;
	local absorbBarFullCombat, absorbBarZeroCombat, absorbBarFullNoCombat, absorbBarZeroNoCombat, absorbBarOverlay;
	local healthBarText;
	local incomingBarFullCombat, incomingBarZeroCombat, incomingBarFullNoCombat, incomingBarZeroNoCombat;
	local incomingSetting, absorbSetting;
	local healthBarWidth;
	local powerBar, powerBarWidth;
	local unitNameFontString;
	
	-- PRIVATE FUNCTIONS

	-- creates the background and border
	local function createBackdrop()
		background = background or visualFrame:CreateTexture(nil, "BACKGROUND");
		background:SetPoint("TOPLEFT", visualFrame, 3, -3);
		background:SetPoint("BOTTOMRIGHT", visualFrame, -3, 3);
		border = {["edgeFile"] = "Interface\\Tooltips\\UI-Tooltip-Border"};
		
	end
	
	-- configures the background and border according to user settings
	local function configureBackdrop()
		border.edgeSize = 10 + 2 * owner:GetProperty("BorderThickness");
		visualFrame:SetBackdrop(border);
		background:SetColorTexture(unpack(owner:GetProperty("ColorBackground")));
		visualFrame:SetBackdropBorderColor(unpack(owner:GetProperty("ColorBorder")));
	end
	
	-- creates the health, total-absorb and incoming-heal bars
	local function createHealthBar()
		healthBarFullCombat = healthBarFullCombat or visualFrame:CreateTexture(nil, "ARTWORK");
		healthBarZeroCombat = healthBarZeroCombat or visualFrame:CreateTexture(nil, "ARTWORK");
		healthBarFullNoCombat = healthBarFullNoCombat or visualFrame:CreateTexture(nil, "ARTWORK");
		healthBarZeroNoCombat = healthBarZeroNoCombat or visualFrame:CreateTexture(nil, "ARTWORK");
		absorbBarFullCombat = absorbBarFullCombat or visualFrame:CreateTexture(nil, "ARTWORK");
		absorbBarZeroCombat = absorbBarZeroCombat or visualFrame:CreateTexture(nil, "ARTWORK");
		absorbBarFullNoCombat = absorbBarFullNoCombat or visualFrame:CreateTexture(nil, "ARTWORK");
		absorbBarZeroNoCombat = absorbBarZeroNoCombat or visualFrame:CreateTexture(nil, "ARTWORK");
		absorbBarOverlay = absorbBarOverlay or visualFrame:CreateTexture(nil, "ARTWORK", nil, 1);
		incomingBarFullCombat = incomingBarFullCombat or visualFrame:CreateTexture(nil, "ARTWORK");
		incomingBarZeroCombat = incomingBarZeroCombat or visualFrame:CreateTexture(nil, "ARTWORK");
		incomingBarFullNoCombat = incomingBarFullNoCombat or visualFrame:CreateTexture(nil, "ARTWORK");
		incomingBarZeroNoCombat = incomingBarZeroNoCombat or visualFrame:CreateTexture(nil, "ARTWORK");		

		healthBarFullCombat:SetTexture("Interface\\TargetingFrame\\UI-StatusBar");
		healthBarZeroCombat:SetTexture("Interface\\TargetingFrame\\UI-StatusBar");
		healthBarFullNoCombat:SetTexture("Interface\\TargetingFrame\\UI-StatusBar");
		healthBarZeroNoCombat:SetTexture("Interface\\TargetingFrame\\UI-StatusBar");
		absorbBarFullCombat:SetTexture("Interface\\RaidFrame\\Shield-Fill");
		absorbBarZeroCombat:SetTexture("Interface\\RaidFrame\\Shield-Fill");
		absorbBarFullNoCombat:SetTexture("Interface\\RaidFrame\\Shield-Fill");
		absorbBarZeroNoCombat:SetTexture("Interface\\RaidFrame\\Shield-Fill");
		absorbBarOverlay:SetTexture("Interface\\RaidFrame\\Shield-Overlay");
		incomingBarFullCombat:SetTexture("Interface\\TargetingFrame\\UI-StatusBar");
		incomingBarZeroCombat:SetTexture("Interface\\TargetingFrame\\UI-StatusBar");
		incomingBarFullNoCombat:SetTexture("Interface\\TargetingFrame\\UI-StatusBar");
		incomingBarZeroNoCombat:SetTexture("Interface\\TargetingFrame\\UI-StatusBar");

		healthBarZeroCombat:SetPoint("TOPLEFT", healthBarFullCombat);
		healthBarZeroCombat:SetPoint("BOTTOMRIGHT", healthBarFullCombat);
		
		healthBarFullNoCombat:SetPoint("TOPLEFT", healthBarFullCombat);
		healthBarFullNoCombat:SetPoint("BOTTOMRIGHT", healthBarFullCombat);
		
		healthBarZeroNoCombat:SetPoint("TOPLEFT", healthBarFullCombat);
		healthBarZeroNoCombat:SetPoint("BOTTOMRIGHT", healthBarFullCombat);
		
		absorbBarFullCombat:SetPoint("TOPLEFT", healthBarFullCombat, "TOPRIGHT");
		absorbBarFullCombat:SetPoint("BOTTOMLEFT", healthBarFullCombat, "BOTTOMRIGHT");
		
		absorbBarZeroCombat:SetPoint("TOPLEFT", absorbBarFullCombat);
		absorbBarZeroCombat:SetPoint("BOTTOMRIGHT", absorbBarFullCombat);
		
		absorbBarFullNoCombat:SetPoint("TOPLEFT", absorbBarFullCombat);
		absorbBarFullNoCombat:SetPoint("BOTTOMRIGHT", absorbBarFullCombat);
		
		absorbBarOverlay:SetPoint("TOPLEFT", absorbBarFullCombat);
		absorbBarOverlay:SetPoint("BOTTOMRIGHT", absorbBarFullCombat);
		
		incomingBarZeroNoCombat:SetPoint("TOPLEFT", incomingBarFullCombat);	
		incomingBarZeroNoCombat:SetPoint("BOTTOMRIGHT", incomingBarFullCombat);
		
		--incomingBarFullCombat:SetPoint() happens in configureHealthBar()
		
		incomingBarZeroCombat:SetPoint("TOPLEFT", incomingBarFullCombat);
		incomingBarZeroCombat:SetPoint("BOTTOMRIGHT", incomingBarFullCombat);
		
		incomingBarFullNoCombat:SetPoint("TOPLEFT", incomingBarFullCombat);
		incomingBarFullNoCombat:SetPoint("BOTTOMRIGHT", incomingBarFullCombat);
		
		incomingBarZeroNoCombat:SetPoint("TOPLEFT", incomingBarFullCombat);	
		incomingBarZeroNoCombat:SetPoint("BOTTOMRIGHT", incomingBarFullCombat);
		
		absorbBarOverlay:SetVertTile(true);
		absorbBarOverlay:SetHorizTile(true);
		
		healthBarText = healthBarText or visualFrame:CreateFontString(nil, "ARTWORK", nil , 1)
		healthBarText:SetFontObject(owner:GetHealthBarFont());
		healthBarText:SetIgnoreParentScale(true);
	end
	
	-- configures the health, total-absorb and incoming-heal bars according to user settings
	local function configureHealthBar()
		if (owner:GetProperty("HealthBarAsBackground")) then
			healthBarFullCombat:SetPoint("TOPLEFT", visualFrame, "TOPLEFT", 4,  -4);
			healthBarFullCombat:SetPoint("BOTTOMLEFT", visualFrame, "BOTTOMLEFT", 4, 4);
			healthBarWidth = 82;	
		else
			healthBarFullCombat:SetPoint("TOPLEFT", visualFrame, "TOPLEFT", 10, -16);
			healthBarFullCombat:SetPoint("BOTTOMLEFT", visualFrame, "TOPLEFT", 10, -20);
			healthBarWidth = 70;	
		end

		local effectiveScale = visualFrame:GetEffectiveScale();
		healthBarText:SetPoint("TOP", visualFrame, "CENTER", 0, -1 * effectiveScale);
		
		local r,g,b,a;
		r,g,b,a = unpack(owner:GetProperty("ColorUnitFullHealthCombat"));
		healthBarFullCombat:SetVertexColor(r,g,b);
		absorbBarFullCombat:SetVertexColor(r*0.5+0.5,g*0.5+0.5,b*0.5+0.5);
		incomingBarFullCombat:SetVertexColor(r,g,b);
		healthBarFullCombat.maxAlpha = a;

		r,g,b,a = unpack(owner:GetProperty("ColorUnitZeroHealthCombat"));
		healthBarZeroCombat:SetVertexColor(r,g,b);
		absorbBarZeroCombat:SetVertexColor(r*0.5+0.5,g*0.5+0.5,b*0.5+0.5);
		incomingBarZeroCombat:SetVertexColor(r,g,b);
		healthBarZeroCombat.maxAlpha = a;
		
		r,g,b,a = unpack(owner:GetProperty("ColorUnitFullHealthNoCombat"));
		healthBarFullNoCombat:SetVertexColor(r,g,b);
		absorbBarFullNoCombat:SetVertexColor(r*0.5+0.5,g*0.5+0.5,b*0.5+0.5);
		incomingBarFullNoCombat:SetVertexColor(r,g,b);
		healthBarFullNoCombat.maxAlpha = a;
		
		r,g,b,a = unpack(owner:GetProperty("ColorUnitZeroHealthNoCombat"));
		healthBarZeroNoCombat:SetVertexColor(r,g,b);
		absorbBarZeroNoCombat:SetVertexColor(r*0.5+0.5,g*0.5+0.5,b*0.5+0.5);
		incomingBarZeroNoCombat:SetVertexColor(r,g,b);
		healthBarZeroNoCombat.maxAlpha = a;
		
		if (module:getGameVersion() == 1 or owner:GetProperty("ShowTotalAbsorbs") == 3) then
			absorbBarFullCombat:Hide();
			absorbBarZeroCombat:Hide();
			absorbBarFullNoCombat:Hide();
			absorbBarFullNoCombat:Hide();
			absorbBarOverlay:Hide();
			incomingBarZeroNoCombat:SetPoint("TOPLEFT", healthBarFullCombat, "TOPRIGHT");	
			incomingBarZeroNoCombat:SetPoint("BOTTOMLEFT", healthBarFullCombat, "BOTTOMRIGHT");
		else
			absorbBarFullCombat:Show();
			absorbBarZeroCombat:Show();
			absorbBarFullNoCombat:Show();
			absorbBarFullNoCombat:Show();
			absorbBarOverlay:Show();
			incomingBarFullCombat:SetPoint("TOPLEFT", absorbBarFullCombat, "TOPRIGHT");
			incomingBarFullCombat:SetPoint("BOTTOMLEFT", absorbBarFullCombat, "BOTTOMRIGHT");
			absorbSetting = owner:GetProperty("ShowTotalAbsorbs") == 2
		end
		
		if (owner:GetProperty("ShowIncomingHeals") == 1) then
			incomingSetting = nil;
			incomingBarFullCombat:Show();
			incomingBarZeroCombat:Show();
			incomingBarFullNoCombat:Show();
			incomingBarFullNoCombat:Show();	
		else
			incomingBarFullCombat:Show();
			incomingBarZeroCombat:Show();
			incomingBarFullNoCombat:Show();
			incomingBarFullNoCombat:Show();	
			incomingSetting = owner:GetProperty("ShowIncomingHeals") == 2 and "player" or nil
		end
		
		healthBarText:SetShown(owner:GetProperty("ShowHealthText"));
	end
	
	-- updates the health, total-absorb and incoming-heal bars to reflect game state
	local function updateHealthBar()
		if (shownUnit) then
			if (UnitExists(shownUnit) and not UnitIsDeadOrGhost(shownUnit) and owner:GetProperty("TargetHealth")) then
				-- the unit is alive and should have a health bar
				local health, healthMax = ctSafeNumber(UnitHealth(shownUnit)), ctSafeNumber(UnitHealthMax(shownUnit));
				if (not (health and healthMax and healthMax > 0)) then return; end	-- restricted "secret number" (e.g. in combat); skip rather than crash
				local healthRatio = health / healthMax;
				local absorbRatio = (ctSafeNumber(UnitGetTotalAbsorbs(shownUnit, absorbSetting)) or 0) / healthMax;
				local incomingRatio = (ctSafeNumber(UnitGetIncomingHeals(shownUnit, incomingSetting)) or 0) / healthMax;
				if (healthRatio > 1) then
					healthRatio = 1;
				elseif (healthRatio < 0.001) then
					healthRatio = 0.001;
				end
				if (healthRatio + absorbRatio > 1) then
					absorbRatio = 1.001 - healthRatio;
				elseif (absorbRatio < 0.001) then
					absorbRatio = 0.001;
				end
				if (healthRatio + absorbRatio + incomingRatio > 1.002) then
					incomingRatio = 1.002 - healthRatio - absorbRatio;
				elseif (incomingRatio < 0.001) then
					incomingRatio = 0.001;
				end
				healthBarFullCombat:SetWidth(healthBarWidth * healthRatio)
				absorbBarFullCombat:SetWidth(healthBarWidth * absorbRatio)
				incomingBarFullCombat:SetWidth(healthBarWidth * incomingRatio)
				if (UnitIsEnemy(shownUnit,"player")) then
					healthBarFullCombat:SetAlpha(0);
					healthBarZeroCombat:SetAlpha(0);
					healthBarFullNoCombat:SetAlpha(healthBarZeroCombat.maxAlpha);
					healthBarZeroNoCombat:SetAlpha(0);
					absorbBarFullCombat:SetAlpha(0);
					absorbBarZeroCombat:SetAlpha(0);
					absorbBarFullNoCombat:SetAlpha(healthBarZeroCombat.maxAlpha * 0.8);
					absorbBarZeroNoCombat:SetAlpha(0);
					absorbBarOverlay:SetAlpha(healthBarZeroCombat.maxAlpha * 0.8);
					incomingBarFullCombat:SetAlpha(0);
					incomingBarZeroCombat:SetAlpha(0);
					incomingBarFullNoCombat:SetAlpha(healthBarZeroCombat.maxAlpha * 0.4);
					incomingBarZeroNoCombat:SetAlpha(0);
				elseif (InCombatLockdown() or UnitAffectingCombat(shownUnit)) then
					healthBarFullCombat:SetAlpha(healthRatio * healthBarFullCombat.maxAlpha);
					healthBarZeroCombat:SetAlpha((1 - healthRatio)  * healthBarZeroCombat.maxAlpha);
					healthBarFullNoCombat:SetAlpha(0);
					healthBarZeroNoCombat:SetAlpha(0);
					absorbBarFullCombat:SetAlpha(healthRatio * healthBarFullCombat.maxAlpha * 0.8);
					absorbBarZeroCombat:SetAlpha((1 - healthRatio)  * healthBarZeroCombat.maxAlpha * 0.8);
					absorbBarFullNoCombat:SetAlpha(0);
					absorbBarZeroNoCombat:SetAlpha(0);
					absorbBarOverlay:SetAlpha(healthBarZeroCombat.maxAlpha * 0.8);
					incomingBarFullCombat:SetAlpha(healthRatio * healthBarFullCombat.maxAlpha * 0.4);
					incomingBarZeroCombat:SetAlpha((1 - healthRatio)  * healthBarZeroCombat.maxAlpha * 0.4);
					incomingBarFullNoCombat:SetAlpha(0);
					incomingBarZeroNoCombat:SetAlpha(0);
				else
					healthBarFullNoCombat:SetAlpha(healthRatio * healthBarFullNoCombat.maxAlpha);
					healthBarZeroNoCombat:SetAlpha((1 - healthRatio)  * healthBarZeroNoCombat.maxAlpha);				
					healthBarFullCombat:SetAlpha(0);
					healthBarZeroCombat:SetAlpha(0);
					absorbBarFullNoCombat:SetAlpha(healthRatio * healthBarFullCombat.maxAlpha * 0.8);
					absorbBarZeroNoCombat:SetAlpha((1 - healthRatio)  * healthBarZeroCombat.maxAlpha * 0.8);
					absorbBarFullCombat:SetAlpha(0);
					absorbBarZeroCombat:SetAlpha(0);
					absorbBarOverlay:SetAlpha(healthBarZeroCombat.maxAlpha * 0.8);
					incomingBarFullNoCombat:SetAlpha(healthRatio * healthBarFullCombat.maxAlpha * 0.4);
					incomingBarZeroNoCombat:SetAlpha((1 - healthRatio)  * healthBarZeroCombat.maxAlpha * 0.4);
					incomingBarFullCombat:SetAlpha(0);
					incomingBarZeroCombat:SetAlpha(0);
				end
				if (healthRatio < 1) then
					healthBarText:SetText(string.format("%d%%", healthRatio*100));
				else
					healthBarText:SetText("");
				end
			else
				-- the unit is dead, or maybe doesn't even exist, so show nothing!
				healthBarFullCombat:SetAlpha(0);
				healthBarZeroCombat:SetAlpha(0);
				healthBarFullNoCombat:SetAlpha(0);
				healthBarZeroNoCombat:SetAlpha(0);
				absorbBarFullCombat:SetAlpha(0);
				absorbBarZeroCombat:SetAlpha(0);
				absorbBarFullNoCombat:SetAlpha(0);
				absorbBarZeroNoCombat:SetAlpha(0);
				absorbBarOverlay:SetAlpha(0);
				incomingBarFullCombat:SetAlpha(0);
				incomingBarZeroCombat:SetAlpha(0);
				incomingBarFullNoCombat:SetAlpha(0);
				incomingBarZeroNoCombat:SetAlpha(0);
				healthBarText:SetText("");
			end
		end
	end
	
	-- creates the power bar
	local function createPowerBar()
		powerBar = powerBar or visualFrame:CreateTexture(nil, "ARTWORK", nil, 1);
		powerBar:SetTexture("Interface\\TargetingFrame\\UI-StatusBar");
		powerBar:SetHeight(4);	
	end
	
	-- configures the power bar according to user settings
	local function configurePowerBar()

		if (owner:GetProperty("HealthBarAsBackground")) then	-- the powerBar shifts in size and location to align nicely with the healthBar
			powerBar:SetPoint("BOTTOMLEFT", visualFrame, 4, 4);		
		else
			powerBar:SetPoint("BOTTOMLEFT", visualFrame, 10, 4);
		end
		powerBarWidth = (owner:GetProperty("HealthBarAsBackground") and 82) or 70;
	end
	
	-- updates the power bar to reflect infrequently-changing game state
	local function updatePowerBarInfrequent()
		if (shownUnit and UnitExists(shownUnit)) then
			local powerType, powerToken, altR, altG, altB = UnitPowerType(shownUnit);
			local info = PowerBarColor[powerToken];
			if ( info ) then
				--The PowerBarColor takes priority
				powerBar:SetVertexColor(info.r, info.g, info.b);
			else
				if (not altR) then
					-- Couldn't find a power token entry. Default to indexing by power type or just mana if  we don't have that either.
					info = PowerBarColor[powerType] or PowerBarColor["MANA"];
					powerBar:SetVertexColor(info.r, info.g, info.b);
				else
					powerBar:SetVertexColor(altR, altG, altB);
				end
			end
		else
			local info = PowerBarColor["MANA"]
			powerBar:SetVertexColor(info.r, info.g, info.b);
		end	
	end
	
	-- updates the power bar to reflect frequently-changing game state
	local function updatePowerBarFrequent()
		if (shownUnit) then
			if (UnitExists(shownUnit) and not UnitIsDeadOrGhost(shownUnit) and owner:GetProperty("TargetPower")) then
				local power, powerMax = ctSafeNumber(UnitPower(shownUnit)), ctSafeNumber(UnitPowerMax(shownUnit));
				if (not (power and powerMax and powerMax > 0)) then powerBar:Hide(); return; end	-- restricted "secret number"; skip rather than crash
				local powerRatio = power / powerMax;
				if (powerRatio < 0.01) then 
					powerBar:Hide();
				else 
					powerBar:SetWidth(powerBarWidth*min(1,powerRatio));
					powerBar:Show();
				end
				-- use the same alpha rules as the health bar for consistency... except base it on UnitPower == UnitPowerMax instead of Health == HealthMax
				if (InCombatLockdown()) then
					powerBar:SetAlpha(powerRatio > 0.99 and owner:GetProperty("ColorUnitFullHealthCombat")[4] or owner:GetProperty("ColorUnitZeroHealthCombat")[4]);
				else
					powerBar:SetAlpha(powerRatio > 0.99 and owner:GetProperty("ColorUnitFullHealthNoCombat")[4] or owner:GetProperty("ColorUnitZeroHealthNoCombat")[4]);
				end	
			else
				powerBar:Hide();
			end
		end
	end

	-- creates the font strings to dislay the unit's name, with customization to counter the ugly side effects of SetScale()
	local configureUnitNameFontString = function()
		unitNameFontString = unitNameFontString or visualFrame:CreateFontString(nil, "OVERLAY");
		unitNameFontString:SetDrawLayer("OVERLAY", 1);	-- in front of icons
		unitNameFontString:SetIgnoreParentScale(true);
		unitNameFontString:SetFontObject(owner:GetUnitNameFont());
		local effectiveScale = visualFrame:GetEffectiveScale();
		unitNameFontString:SetPoint("TOPLEFT", visualFrame, "TOPLEFT", 4 * effectiveScale, -5 * effectiveScale);
		unitNameFontString:SetPoint("TOPRIGHT", visualFrame, "TOPRIGHT", -4 * effectiveScale, -5 * effectiveScale);	
		unitNameFontString:SetTextColor(1,1,1,1);	-- done here just once, because mobs don't have a class!
	end
	
	-- creates and updates the player's name
	local updateUnitNameFontString = function()
		if (shownUnit) then
			if (UnitExists(shownUnit)) then
				local name = UnitName(shownUnit);
				unitNameFontString:SetText(name);
				while (unitNameFontString:GetStringWidth() > unitNameFontString:GetWidth()) do
					name = name:sub(1,-2);
					unitNameFontString:SetText(name);
				end
			else
				unitNameFontString:SetText("");
			end
		end
	end
	
	local function configureSecureButtons()
		local togglemenu = module:getOption("CTRA_ClickCast_ToggleMenu") or 7;
		local target = module:getOption("CTRA_ClickCast_Target") or 1;
		secureButton:SetAttribute("type", target == 1 and "target" or nil);
		secureButton:SetAttribute("type2", togglemenu == 1 and "togglemenu" or nil);
		secureButton:SetAttribute("shift-type2", togglemenu == 2 and "togglemenu" or nil);
		secureButton:SetAttribute("ctrl-type2", togglemenu == 3 and "togglemenu" or nil);
		secureButton:SetAttribute("alt-type2", togglemenu == 4 and "togglemenu" or nil);
		secureButton:SetAttribute("type1", togglemenu == 6 and "togglemenu" or nil);
		secureButton:SetAttribute("shift-type1", togglemenu == 7 and "togglemenu" or nil);
		secureButton:SetAttribute("ctrl-type1", togglemenu == 8 and "togglemenu" or nil);
		secureButton:SetAttribute("alt-type1", togglemenu == 9 and "togglemenu" or nil);
	end
	
	-- PUBLIC FUNCTIONS
	
	function obj:Enable(unit, xOff, yOff)
		if (not unit) then
			self:Disable();
			return;
		end
		requestedUnit = unit;
		requestedXOff = xOff;
		requestedYOff = yOff;
		self:Update();
	end
	
	function obj:Disable()
		requestedUnit = nil;
		requestedXOff = nil;
		requestedYOff = nil;
		self:Update();
	end
	
	function obj:IsEnabled()
		return requestedUnit ~= nil
	end
	
	function obj:IsShown()
		return shownUnit ~= nil
	end
	
	function obj:Update(option, value)
		-- STEP 1: Construct the secureButton and visualFrame if required, but only while out of combat, before proceeding to any of the following steps
		-- STEP 2: Respond to changes in the CTRA options affecting how the frames should appear and behaive, but only while out of combat
		-- STEP 3: Respond to changes directed by the parent window (requestedUnit, requestedXOff, requestedYOff) while respecting combat limitations


		-- STEP 1
		if not visualFrame or not secureButton then
			if InCombatLockdown() then
				return;
			else
				-- overall dimensions
				visualFrame = CreateFrame("Frame", nil, parent, BackdropTemplateMixin and "BackdropTemplate");
				visualFrame:SetWidth(90);
				visualFrame:SetHeight(20 + (((owner:GetProperty("TargetHealth") and not owner:GetProperty("HealthBarAsBackground")) and 4) or 0) + ((owner:GetProperty("TargetPower") and 4) or 0));
				visualFrame:SetScale(owner:GetProperty("PlayerFrameScale")/100);
								
				-- overlay button that can be clicked to do stuff in combat (the secure configuration is made later in step 3)
				secureButton = CreateFrame("Button", nil, visualFrame, "SecureUnitButtonTemplate");
				secureButton:SetAllPoints();
				secureButton:RegisterForClicks("AnyDown");
				secureButton:HookScript("OnEnter",
					function()
						if (UnitExists(shownUnit)) then
							GameTooltip:SetOwner(parent, "ANCHOR_TOPLEFT");
							GameTooltip:AddDoubleLine(UnitName(shownUnit) or "", UnitLevel(shownUnit) or "", 1,1,1, 1,1,1);
							GameTooltip:Show();
						end
					end
				);
				secureButton:HookScript("OnLeave",
					function()
						GameTooltip:Hide();
					end
				);
				
				-- these secure frames should actually do something!
				configureSecureButtons();
				
				-- insecure textures and appearances to display information non-interactively
				createBackdrop();
				configureBackdrop();
				createHealthBar();
				configureHealthBar();
				createPowerBar();
				configurePowerBar();
			end
		end
		
		-- STEP 2:
		if (option) then
			optionsWaiting[option] = value;
		end
		if (not InCombatLockdown()) then
			for key, val in pairs(optionsWaiting) do
				if (key == "PlayerFrameScale") then
					visualFrame:SetScale((val or 100)/100);
					configureUnitNameFontString();
					configureHealthBar();
				elseif (
					key == "ColorTargetFrameBackground"
					or key == "ColorTargetFrameBorder"
				) then
					configureBackdrop();
				elseif (
					key == "TargetHealth"
					or key == "TargetPower"
				) then
					visualFrame:SetHeight(20 + (((owner:GetProperty("TargetHealth") and not owner:GetProperty("HealthBarAsBackground")) and 4) or 0) + ((owner:GetProperty("TargetPower") and 4) or 0));
				else
					configureBackdrop();
					configureHealthBar();
					configurePowerBar();
					configureSecureButtons();
				end
			end
			wipe(optionsWaiting);
		end
		
		-- STEP 3:
		if (not InCombatLockdown() and (requestedUnit ~= shownUnit or requestedXOff ~= shownXOff or requestedYOff ~= shownYOff)) then
			-- set the flags
			shownUnit = requestedUnit;
			shownXOff = requestedXOff;
			shownYOff = requestedYOff;

			-- register or de-register events
			if (not listenerFrame) then
				listenerFrame = CreateFrame("Frame", nil);
				listenerFrame:SetScript("OnEvent",
					function(__, event)
						if (event == "UNIT_HEALTH" or event == "UNIT_MAXHEALTH" or event == "UNIT_ABSORB_AMOUNT_CHANGED" or event == "UNIT_HEAL_PREDICTION") then
							updateHealthBar();
						elseif (event == "UNIT_POWER_UPDATE") then
							updatePowerBarFrequent();
						elseif (event == "UNIT_DISPLAYPOWER") then
							updatePowerBarInfrequent();
						elseif (event == "UNIT_TARGET") then
							updateHealthBar();
							updatePowerBarInfrequent();
							updatePowerBarFrequent();
							updateUnitNameFontString();
						elseif (event == "UNIT_NAME_UPDATE") then
							updateUnitNameFontString();
						end
					end
				);
			end

			-- configure the visualFrame and its children
			if (shownUnit) then
				visualFrame:Show();
				RegisterStateDriver(visualFrame, "visibility", "[@" .. shownUnit .. ", exists, nodead] show; hide");
				configureUnitNameFontString();
				listenerFrame:UnregisterAllEvents();  -- probably not required, but doing it to be absolute
				listenerFrame:RegisterUnitEvent("UNIT_HEALTH", shownUnit);
				listenerFrame:RegisterUnitEvent("UNIT_MAXHEALTH", shownUnit);
				listenerFrame:RegisterUnitEvent("UNIT_POWER_UPDATE", shownUnit);
				listenerFrame:RegisterUnitEvent("UNIT_DISPLAYPOWER", shownUnit);
				listenerFrame:RegisterUnitEvent("UNIT_NAME_UPDATE", shownUnit);
				listenerFrame:RegisterUnitEvent("UNIT_TARGET", strsub(shownUnit, 1, -7));
				if (module:getGameVersion() >= 2) then
					listenerFrame:RegisterUnitEvent("UNIT_HEAL_PREDICTION", shownUnit);
				end
				if (module:getGameVersion() >= 5) then
					listenerFrame:RegisterUnitEvent("UNIT_ABSORB_AMOUNT_CHANGED", shownUnit);
				end
			else
				UnregisterStateDriver(visualFrame, "visibility");
				visualFrame:Hide();
				listenerFrame:UnregisterAllEvents();
				return;		-- go absolutely no further if we arn't supposed to be showing anything any more!
			end

			-- reposition the frames
			visualFrame:SetPoint("TOPLEFT", requestedXOff, requestedYOff);

			-- configure the secureButton for the new unit
			secureButton:SetAttribute("unit", shownUnit);
		end
		
		-- visualFrame's children must be updated whenever group composition changes in case the players have changed position within the group or raid.
		-- if shownUnit exists then it can be assumed the previous conditional evaluated to true at some point and therefore the configure___() funcs have been used
		if (shownUnit) then
			updateHealthBar();
			updatePowerBarInfrequent();
			updatePowerBarFrequent();
			updateUnitNameFontString();
		end
	end
	
	-- PUBLIC CONSTRUCTOR
	do
		owner = parentInterface;	
		parent = parentFrame;
		return obj;			-- that's it!  nothing else is done until obj:Enable()
	end
end  -- end CTRATargetFrame