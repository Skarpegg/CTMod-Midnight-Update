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
-- Pet Bar

local function addon_UpdateOrientation(self, orientation, spacing)
	-- Update the orientation of the frame.
	-- self == pet bar object
	-- orientation == "ACROSS" or "DOWN"
	-- spacing == distance between butons

	if (InCombatLockdown()) then
		return;
	end

	orientation = orientation or "ACROSS";
	spacing = spacing or appliedOptions.petBarSpacing or 6;

	PetActionButton1:ClearAllPoints();
	PetActionButton1:SetPoint("BOTTOMLEFT", self.frame);

	local obj;
	for i = 2, 10 do
		obj = _G["PetActionButton" .. i];
		obj:ClearAllPoints();
		if ( orientation == "ACROSS" ) then
			obj:SetPoint("LEFT", _G["PetActionButton" .. (i-1)], "RIGHT", spacing, 0);
		else
			obj:SetPoint("TOP", _G["PetActionButton" .. (i-1)], "BOTTOM", 0, -spacing);
		end
	end
end

local function addon_HideTextures(self)
	-- Hide the textures

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
	-- self == pet bar object

	addon_HideTextures(self);

	if (not InCombatLockdown()) then
		PetActionBarFrame:EnableMouse(0);

		local obj1 = PetActionButton1;
		local obj2 = PetActionButton10;

		self.helperFrame:ClearAllPoints();
		self.helperFrame:SetPoint("TOPLEFT", obj1);
		self.helperFrame:SetPoint("BOTTOMRIGHT", obj2);

		addon_UpdateOrientation(self, self.orientation, appliedOptions.petBarSpacing);

		module:update("petBarScale", appliedOptions.petBarScale);
		module:update("petBarSpacing", appliedOptions.petBarSpacing);
		module:update("petBarOpacity", appliedOptions.petBarOpacity);
	end
end

local function addon_ApplyOption(optName, value)

	local self = module.ctPetBar;

	if (self.isDisabled) then
		return;
	end

	if (optName == "petBarSpacing") then
		-- Must not be in combat.
		self:rotateFunc(self.orientation, value);
		return;
	end

	local func;

	if (optName == "petBarScale") then
		-- Must not be in combat.
		if (InCombatLockdown()) then
			return;
		end
		func = PetActionButton1.SetScale;

	elseif (optName == "petBarOpacity") then
		-- Can be done while in combat.
		func = PetActionButton1.SetAlpha;
	end

	if (func) then
		for i = 1, 10 do
			func(_G["PetActionButton" .. i], value);
		end
	end
end

local function addon_OnEvent(self, event, arg1, ...)
	if (module.ctPetBar.isDisabled) then
		return;
	end

	if (event == "PET_BAR_UPDATE" or (event == "UNIT_PET" and arg1 == "player") or event == "PET_UI_UPDATE") then
		module.ctPetBar:updateVisibility();
	end
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
		-- Hide pet bar textures
		self:updateTextureVisibility(false);
	end
end

local function addon_Enable(self)
	local frame = self.helperFrame;

	frame:RegisterEvent("PET_BAR_UPDATE");
	frame:RegisterEvent("PET_UI_UPDATE");
	frame:RegisterEvent("UNIT_PET");

	frame:SetScript("OnEvent", addon_OnEvent);
	
	-- hides the default bar securely
	RegisterStateDriver(PetActionBarFrame,"visibility","hide");

end

local function addon_Disable(self)
	local frame = self.helperFrame;

	frame:UnregisterEvent("PET_BAR_UPDATE");
	frame:UnregisterEvent("PET_UI_UPDATE");
	frame:UnregisterEvent("UNIT_PET");

	frame:SetScript("OnEvent", nil);
	
	-- allows the default bar to behave pseudo-normally, securely
	RegisterStateDriver(PetActionBarFrame,"visibility","[@pet,noexists]hide; show");

	if (CT_BarMod and CT_BarMod.CT_BarMod_Shift_Pet_UpdatePositions) then
		CT_BarMod.CT_BarMod_Shift_Pet_UpdatePositions();
	end

	-- Call Blizzard's function which may adjust the position
	-- of the bar, and hide/show some textures.
	UIParent_ManageFramePositions();
end

local function addon_Config(self)
	-- Perform a one time configuration after bar has been initialized by addon:init().
	if (not self.isDisabled) then
		module.updatePetBar("petBarScale", appliedOptions.petBarScale);
		module.updatePetBar("petBarOpacity", appliedOptions.petBarOpacity);
		module.updatePetBar("petBarSpacing", appliedOptions.petBarSpacing);
	end
end

local function addon_Init(self)
	-- Initialization
	-- self == pet bar object

	appliedOptions = module.appliedOptions;

	module.ctPetBar = self;
	module.updatePetBar = addon_ApplyOption;

	local frame = CreateFrame("Frame", "CT_BottomBar_" .. self.frameName .. "_GuideFrame");
	self.helperFrame = frame;
	
	-- causes bar to be hidden if there is no pet (see CT_BottomBar_Addons.lua)
	self.frame.RequiresPetToShow = 1;

	return true;
end

local function addon_Register()
	module:registerAddon(
		"Pet Bar",  -- option name
		"PetBar",  -- used in frame names
		module.text["CT_BottomBar/Options/PetBar"],  -- shown in options window & tooltips
		module.text["CT_BottomBar/Options/PetBar"],  -- title for horizontal orientation
		"Pet",  -- title for vertical orientation
		{ "BOTTOMLEFT", ctRelativeFrame, "BOTTOM", -98, 107 },
		{ -- settings
			orientation = "ACROSS",
			UIParent_ManageFramePositions = addon_UIParent_ManageFramePositions,
		},
		addon_Init,
		nil,  -- no post init function
		addon_Config,
		addon_Update,
		addon_UpdateOrientation,
		addon_Enable,
		addon_Disable,
		"helperFrame",
		PetActionButton1,
		PetActionButton2,
		PetActionButton3,
		PetActionButton4,
		PetActionButton5,
		PetActionButton6,
		PetActionButton7,
		PetActionButton8,
		PetActionButton9,
		PetActionButton10,
		"",  -- Empty string indicates start of textures
		SlidingActionBarTexture0,
		SlidingActionBarTexture1
	);
end

module.loadedAddons["Pet Bar"] = addon_Register;
