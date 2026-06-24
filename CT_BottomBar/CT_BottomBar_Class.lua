------------------------------------------------
--               CT_BottomBar                 --
--                                            --
-- Breaks up the main menu bar into pieces,   --
-- allowing you to hide and move the pieces   --
-- independently of each other.               --
--                                            --
-- Please do not modify or otherwise          --
-- redistribute this without the consent of   --
-- the CTMod Team. Thank you.                 --
------------------------------------------------

if CT_BottomBar:getGameVersion() >= 10 then
	return
end

--------------------------------------------
-- Initialization

local _G = getfenv(0);
local module = _G.CT_BottomBar;

local ctRelativeFrame = module.ctRelativeFrame;
local appliedOptions;

--------------------------------------------
-- Class Bar (Stance Bar)

local function addon_UpdateOrientation(self, orientation)
	-- Update the frame's orientation.
	-- self == class bar object
	-- orientation == "ACROSS" or "DOWN"

	if (InCombatLockdown()) then
		return;
	end

	orientation = orientation or "ACROSS";

	StanceButton1:ClearAllPoints();
	StanceButton1:SetPoint("BOTTOMLEFT", self.frame);

	local obj;
	local spacing = 8;
	for i = 2, 10, 1 do
		obj = _G["StanceButton"..i];
		obj:ClearAllPoints();
		if ( orientation == "ACROSS" ) then
			obj:SetPoint("LEFT", _G["StanceButton" .. (i-1)], "RIGHT", spacing, 0);
		else
			obj:SetPoint("TOP", _G["StanceButton" .. (i-1)], "BOTTOM", 0, -spacing);
		end
	end
end

local function addon_HideTextures(self)
	if (self.isDisabled) then
		return;
	end

	local frames = self.textures;
	if (frames) then
		for i, frame in ipairs(frames) do
			frame:Hide();
			frame:SetVertexColor(1, 1, 1, 0);
		end
	end
end

local function addon_setNormalTextureSizeForButtons()
	-- Set the normal texture size of the stance buttons.

	-- Since we're not showing the class bar textures,
	-- keep the stance buttons' normal textures
	-- at 52 height & width. Blizzard may have set them
	-- to 64 during UIParent_ManageFramePositions().
	local obj;
	for i = 1, 10, 1 do
		obj = _G["StanceButton"..i];
		if (obj) then
			obj:GetNormalTexture():SetHeight(52);
			obj:GetNormalTexture():SetWidth(52);
		end
	end
end

local function addon_Update(self)
	-- Update the frame
	-- self == class bar object

	addon_HideTextures(self);

	if (not InCombatLockdown()) then
		StanceBarFrame:EnableMouse(0);

		local obj1 = StanceButton1;
		local obj2 = StanceButton10;

		self.helperFrame:ClearAllPoints();
		self.helperFrame:SetPoint("TOPLEFT", obj1);
		self.helperFrame:SetPoint("BOTTOMRIGHT", obj2);

		addon_UpdateOrientation(self, self.orientation);
	end
end

local function addon_HideSomeButtons()
	-- Hide the class buttons that aren't needed.
	local numForms = GetNumShapeshiftForms();
	if (not InCombatLockdown()) then
		for i=1, NUM_STANCE_SLOTS do
			local button = _G["StanceButton"..i];
			if ( i <= numForms ) then
				button:Show();
			else
				button:Hide();
			end
		end
	end
end

local function addon_OnEvent(self, event)
	if (event == "PLAYER_ENTERING_WORLD" or "ACTIVE_TALENT_GROUP_CHANGED") then
		-- The stance buttons start out shown, and Blizzard's stance frame starts out hidden.
		-- Blizzard does not seem to be hiding stance buttons if the current class and spec
		-- does not have any (they know the stance frame is hidden, which keeps the buttons
		-- not visible).
		-- CT_BottomBar keeps our parent frame for the butons shown, but relies on Blizzard
		-- to show/hide the stance buttons. Since they may not hide them, we need to hide
		-- the buttons whenever the player changes class or talent spec.
		addon_HideSomeButtons();
	end
end

local function addon_Hooked_StanceBar_Update()
	-- (hooksecurefunc of StanceBar_Update in StanceBar.lua)

	if (module.ctClassBar.isDisabled) then
		return;
	end

	-- Blizzard's function re-anchors StanceButton1 when the player has only 1 shapeshift form.
	-- That stops us from being able to move the class bar.
	-- We have to undo their anchor and re-establish our own.

	addon_Update(module.ctClassBar);
end

local function addon_UIParent_ManageFramePositions()
	-- Called from CT_BottomBar.lua via hook of Blizzard's UIParent_ManageFramePositions function.
	local self = module.ctClassBar;
	if (not self) then
		return;
	end

	if (self.isDisabled) then
		-- Update saved info about the textures.
		self:saveTextures();
		return;
	else
		-- Hide class bar textures
		self:updateTextureVisibility(false);
	end

	addon_setNormalTextureSizeForButtons();
end

local function addon_Enable(self)
	addon_setNormalTextureSizeForButtons();
end

local function addon_Disable(self)
	-- Adjust textures (based on StanceBar_Update in StanceBar.lua)
	local numForms = GetNumShapeshiftForms();
	if ( numForms > 0 ) then
		if ( numForms == 1 ) then
			StanceBarMiddle:Hide();
			StanceBarRight:ClearAllPoints();
			StanceBarRight:SetPoint("LEFT", "StanceBarLeft", "LEFT", 12, 0);
		elseif ( numForms == 2 ) then
			StanceBarMiddle:Hide();
			StanceBarRight:ClearAllPoints();
			StanceBarRight:SetPoint("LEFT", "StanceBarLeft", "RIGHT", 0, 0);
		else
			StanceBarMiddle:Show();
			StanceBarMiddle:ClearAllPoints();
			StanceBarMiddle:SetPoint("LEFT", "StanceBarLeft", "RIGHT", 0, 0);
			StanceBarMiddle:SetWidth(37 * (numForms-2));
			StanceBarMiddle:SetTexCoord(0, numForms-2, 0, 1);
			StanceBarRight:ClearAllPoints();
			StanceBarRight:SetPoint("LEFT", "StanceBarMiddle", "RIGHT", 0, 0);
		end
	end

	if (CT_BarMod and CT_BarMod.CT_BarMod_Shift_Stance_UpdatePositions) then
		CT_BarMod.CT_BarMod_Shift_Stance_UpdatePositions();
	end

	-- Call Blizzard's function which may adjust the position
	-- of the bar, and hide/show stance textures.
	UIParent_ManageFramePositions();
end

local function addon_Init(self)
	-- Initialization
	-- self == object

	appliedOptions = module.appliedOptions;

	module.ctClassBar = self;

	local frame = CreateFrame("Frame", "CT_BottomBar_" .. self.frameName .. "_GuideFrame");
	self.helperFrame = frame;

	frame:RegisterEvent("PLAYER_ENTERING_WORLD");
	frame:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED");
	frame:SetScript("OnEvent", addon_OnEvent);

	hooksecurefunc("StanceBar_Update", addon_Hooked_StanceBar_Update);

	return true;
end

local function addon_Register()
	module:registerAddon(
		"Class Bar",  -- option name
		"ClassBar",  -- used in frame names
		module.text["CT_BottomBar/Options/ClassBar"],  -- shown in options window & tooltips
		module.text["CT_BottomBar/Options/ClassBar"],  -- title for horizontal orientation
		"Class",  -- title for vertical orientation
		{ "BOTTOMLEFT", ctRelativeFrame, "BOTTOM", -484, 107 },
		{ -- settings
			orientation = "ACROSS",
			-- These classes have this bar and therefore will have this bar enabled by default.
			["perClass"] = {
				["DEATHKNIGHT"] = true, -- presences
				["DRUID"] = true,  -- forms
				["HUNTER"] = true,  -- aspects
				["MONK"] = true,  -- stances
				["PALADIN"] = true,  -- seals
				["PRIEST"] = true,  -- shadowform
				["ROGUE"] = true,  -- stealth, shadow dance
				["WARRIOR"] = true,  -- stances
			},
			UIParent_ManageFramePositions = addon_UIParent_ManageFramePositions,
		},
		addon_Init,
		nil,  -- no post init function
		nil,  -- no config function
		addon_Update,
		addon_UpdateOrientation,
		addon_Enable,
		addon_Disable,
		"helperFrame",
		StanceButton1,
		StanceButton2,
		StanceButton3,
		StanceButton4,
		StanceButton5,
		StanceButton6,
		StanceButton7,
		StanceButton8,
		StanceButton9,
		StanceButton10,
		"",  -- Empty string indicates start of textures
		StanceBarLeft,
		StanceBarMiddle,
		StanceBarRight
	);
end

module.loadedAddons["Class Bar"] = addon_Register;

-- Hide the class buttons that aren't needed.
addon_HideSomeButtons();
