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
-- Bags Bar

local function addon_UpdateOrientation(self, orientation)
	-- Anchor the frames according to the specified orientation
	-- self == bags bar object
	-- orientation == "ACROSS" or "DOWN"

	local frames = self.frames;
	local obj;
	local spacing;

	orientation = orientation or "ACROSS";
	if (module:getGameVersion() >= 8) then
		spacing = spacing or appliedOptions.bagsBarSpacing or 2;
	else
		spacing = spacing or appliedOptions.bagsBarSpacing or 4;
	end
	
	local width = 0
	for i = 2, #frames do
		obj = frames[i];
		obj:ClearAllPoints();
		obj:SetParent(self.frame);
		width = width + obj:GetWidth()
	end
	if (appliedOptions.bagsBarHideBags and not BagBarExpandToggle) then
		local backpack = frames[#frames];
		for i = 2, #frames - 1 do
			obj = frames[i];
			obj:SetPoint("CENTER", backpack);
			obj:Hide();
		end
		backpack:SetPoint("BOTTOMLEFT", self.frame, 0, 0);
		backpack:Show();
	else
		frames[#frames]:SetPoint("BOTTOMRIGHT", self.frame, width + spacing*(#frames-2), 0)
		for i=#frames-1, 2, -1 do
			obj = frames[i];
			if ( orientation == "ACROSS" ) then
				if BagBarExpandToggle and i == #frames-1 then
					obj:SetPoint("RIGHT", frames[i+1], "LEFT", -(spacing + BagBarExpandToggle:GetWidth()), 0)
				else
					obj:SetPoint("RIGHT", frames[i+1], "LEFT", -spacing, 0)
				end
			else
				obj:SetPoint("BOTTOM", frames[i+1], "TOP", 0, spacing)
			end
			if not BagBarExpandToggle then
				obj:Show()
			end
		end
	end
end

local function addon_Update(self)
	-- Update the frame
	-- self == bags bar object

	-- Anchor the guide frame
	local obj1;
	local obj2;
	if (appliedOptions.bagsBarHideBags) then
		obj1 = MainMenuBarBackpackButton;  -- Left most bag
		obj2 = MainMenuBarBackpackButton;  -- Right most bag
	else
		obj1 = CharacterReagentBag0Slot or CharacterBag3Slot;  -- Left most bag
		obj2 = MainMenuBarBackpackButton;  -- Right most bag
	end

	self.helperFrame:ClearAllPoints();
	self.helperFrame:SetPoint("TOPLEFT", obj1, 0, 0);
	self.helperFrame:SetPoint("BOTTOMRIGHT", obj2);

	-- Anchor the objects.
	addon_UpdateOrientation(self, self.orientation);
end

local function addon_Init(self)
	-- Initialization
	-- self == bags bar object

	appliedOptions = module.appliedOptions;

	module.ctBagsBar = self;

	if MainMenuBarArtFrame then
		-- before WoW 10.x
		self.frame:SetFrameLevel(MainMenuBarArtFrame:GetFrameLevel() + 1)
	end

	local frame = CreateFrame("Frame", "CT_BottomBar_" .. self.frameName .. "_GuideFrame");
	self.helperFrame = frame;
	
	if CharacterReagentBag0Slot then
		local oldFunc = CharacterReagentBag0Slot.SetBarExpanded
		function CharacterReagentBag0Slot.SetBarExpanded(slot, isExpanded)
			if self.isDisabled then
				oldFunc(slot, isExpanded)
			else
				slot:SetShown(isExpanded)
			end
		end
	end
	
	if BagBarExpandToggle then
		MainMenuBarBackpackButton:HookScript("OnShow", function()
			BagBarExpandToggle:Show()
		end)
		
		MainMenuBarBackpackButton:HookScript("OnHide", function()
			BagBarExpandToggle:Hide()
		end)
	end
	
	return true;
end

local addon_Disable = BagBarExpandToggle and function(self)
	--BagBarExpandToggle:Click()
	--BagBarExpandToggle:Click()		-- is this necessary?
end

local addon_Enable = addon_Disable

local function addon_Register()
	local x, y;
	if (module:getGameVersion() >= 8) then
		x = 345;
		y = 28;
	else
		x = 300;
		y = 2;
	end	
	
	local frames = {CharacterBag3Slot, CharacterBag2Slot, CharacterBag1Slot, CharacterBag0Slot, MainMenuBarBackpackButton}
	if CharacterReagentBag0Slot then
		tinsert(frames, 1, CharacterReagentBag0Slot)
	end
	
	module:registerAddon(
		"Bags Bar",  -- option name
		"BagsBar",  -- used in frame names
		module.text["CT_BottomBar/Options/BagsBar"],  -- shown in options window & tooltips
		module.text["CT_BottomBar/Options/BagsBar"],  -- title for horizontal orientation
		"Bags",  -- title for vertical orientation
		{ "BOTTOMLEFT", ctRelativeFrame, "BOTTOM", x, y },  --default position
		{ -- settings
			orientation = "ACROSS",
			saveShown = true, -- save/load the shown state of frames
		},
		addon_Init,
		nil,  -- no post init function
		nil,  -- no config function
		addon_Update,
		addon_UpdateOrientation,
		addon_Enable,
		addon_Disable,
		"helperFrame",
		unpack(frames)
	);
end

module.loadedAddons["Bags Bar"] = addon_Register;
