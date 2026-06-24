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

--------------------------------------------
-- Initialization

local _G = getfenv(0);
local module = _G.CT_BottomBar;

local ctRelativeFrame = module.ctRelativeFrame;
local appliedOptions;

--------------------------------------------
-- Possess Bar

local function addon_UpdateOrientation(self, orientation)
	-- Update the orientation of the frame.
	-- self == possess bar object

	if (InCombatLockdown()) then
		return;
	end

	orientation = orientation or "ACROSS";

	PossessButton1:ClearAllPoints();
	PossessButton1:SetPoint("BOTTOMLEFT", self.frame);

	local obj;
	for i = 2, 2, 1 do
		obj = _G["PossessButton"..i];
		obj:ClearAllPoints();
		if ( orientation == "ACROSS" ) then
			obj:SetPoint("LEFT", _G["PossessButton"..(i-1)], "RIGHT", 9, 0);
		else
			obj:SetPoint("TOP", _G["PossessButton"..(i-1)], "BOTTOM", 0, -9);
		end
	end
end

local function addon_PossessBar_UpdateState()
	-- Modified version of Blizzard's PossessBar_UpdateState() from PossessActionBar.lua.
	--
	-- They don't always manage to call it to update the possess buttons, so sometimes they
	-- don't appear. I think it has something to do with them not wanting to update the buttons
	-- during the in/out animation of the main menu bar/vehicle menu bars, resulting in the
	-- buttons sometimes not getting updated properly.
	--
	-- This copy of their routine is to allow me to update their state even if Blizzard didn't
	-- manage to get them updated.
	--
	local texture, name, enabled;
	local button, background, icon, cooldown;

	for i=1, NUM_POSSESS_SLOTS do
		-- Possess Icon
		button = _G["PossessButton"..i];
		background = _G["PossessBackground"..i];
		icon = _G["PossessButton"..i.."Icon"];
		texture, name, enabled = GetPossessInfo(i);
		icon:SetTexture(texture);

		--Cooldown stuffs
		cooldown = _G["PossessButton"..i.."Cooldown"];
		cooldown:Hide();

		button:SetChecked(nil);
		icon:SetVertexColor(1.0, 1.0, 1.0);

		if ( enabled ) then
			if (not InCombatLockdown()) then
				button:Show();
			end
			button:SetAlpha(1);
			-- background:Show();
			background:Hide();
		else
			if (not InCombatLockdown()) then
				button:Hide();
			else
				button:SetAlpha(0);
			end
			background:Hide();
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

local function addon_Update(self)
	-- Update the frame
	-- self == possess bar object

	addon_PossessBar_UpdateState();

	if (not InCombatLockdown()) then
		PossessBarFrame:EnableMouse(0);

		local obj1 = PossessButton1;
		local obj2 = PossessButton2;

		self.helperFrame:ClearAllPoints();
		self.helperFrame:SetPoint("TOPLEFT", obj1);
		self.helperFrame:SetPoint("BOTTOMRIGHT", obj2);

		addon_UpdateOrientation(self, self.orientation);
	end
end

local function addon_Hooked_PossessBar_Update()
	-- (hooksecurefunc of PossessBar_Update in PossessActionBar.lua)
	if (module.ctPossess.isDisabled) then
		return;
	end
	addon_Update(module.ctPossess);
end

local function addon_Hooked_PossessBar_UpdateState()
	-- (hooksecurefunc of PossessBar_Updatestate in PossessActionBar.lua)
	-- We need to hide the textures that Blizzard may have shown.
	if (module.ctPossess.isDisabled) then
		return;
	end
	addon_HideTextures(module.ctPossess);
end

local function addon_Disable(self)

	if (CT_BarMod and CT_BarMod.CT_BarMod_Shift_Possess_UpdatePositions) then
		CT_BarMod.CT_BarMod_Shift_Possess_UpdatePositions();
	end

	-- Call Blizzard's function which may adjust the position
	-- of the bar, and hide/show Possess textures.
	UIParent_ManageFramePositions();
end

local function addon_Init(self)
	-- Initialization
	-- self == possess bar object

	appliedOptions = module.appliedOptions;

	module.ctPossess = self;

	local frame = CreateFrame("Frame", "CT_BottomBar_" .. self.frameName .. "_GuideFrame");
	self.helperFrame = frame;

	hooksecurefunc("PossessBar_Update", addon_Hooked_PossessBar_Update);
	hooksecurefunc("PossessBar_UpdateState", addon_Hooked_PossessBar_UpdateState);

	return true;
end

local function addon_Register()
	module:registerAddon(
		"Possess Bar",  -- option name
		"PossessBar",  -- used in frame names
		"Possess Bar",  -- shown in options window & tooltips
		"Possess Bar",  -- title for horizontal orientation
		"Possess",  -- title for vertical orientation
		{ "BOTTOMLEFT", ctRelativeFrame, "BOTTOM", 385, 107 },
		{ -- settings
			orientation = "ACROSS",
		},
		addon_Init,
		nil,  -- no post init function
		nil,  -- no config function
		addon_Update,
		addon_UpdateOrientation,
		nil,  -- no enable func
		addon_Disable,
		"helperFrame",
		PossessButton1,
		PossessButton2,
		"",  -- Empty string indicates start of textures
		PossessBackground1,
		PossessBackground2
	);
end

module.loadedAddons["Possess Bar"] = addon_Register;
