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

local module = _G.CT_BottomBar

local ctRelativeFrame = module.ctRelativeFrame
local appliedOptions

local customStatusBarManager

--------------------------------------------
-- Status Tracking Bar Manager

local function addon_Update(self)
	-- Update the frame
	-- self == status tracking bar manager object

	self.frame:SetWidth(appliedOptions.customStatusBarWidth or 768)
	
	customStatusBarManager:UpdateBarsShown()
	
	self.helperFrame:ClearAllPoints()
	self.helperFrame:SetPoint("TOPLEFT", self.frame, "TOPLEFT", -5, 5)
	self.helperFrame:SetPoint("BOTTOMRIGHT", self.frame, "BOTTOMRIGHT", 5, -8)
	
end


local function addon_Enable(self)
	StatusTrackingBarManager:Hide();
	customStatusBarManager:Show();
end

local function addon_Disable(self)
	StatusTrackingBarManager:Show();
	customStatusBarManager:Hide();
end

local function addon_Init(self)
	-- Initialization
	-- self == status tracking bar manager object

	appliedOptions = module.appliedOptions;
	module.ctStatusBar = self;
	module.CT_BottomBar_StatusBar_SetWidth = function() addon_Update(self) end

	if MainMenuBarArtFrame then
		self.frame:SetFrameLevel(MainMenuBarArtFrame:GetFrameLevel() + 1)
	end
	self.frame.OnStatusBarsUpdated = CT_BottomBar_StatusBar_OnStatusBarsUpdated;
	
	self.helperFrame = CreateFrame("Frame", "CT_BottomBar_" .. self.frameName .. "_GuideFrame")
	
	customStatusBarManager = CreateFrame("Frame", "CT_StatusTrackingBarManager", self.frame)
	
	-- duplicating StatusTrackingBarManager, now that in WoW 10.0 one cannot simply inherit StatusTrackingBarManagerTemplate
	Mixin(customStatusBarManager, StatusTrackingManagerMixin)
	customStatusBarManager:SetSize(571, 34)
	-- customStatusBarManager:SetPoint("BOTTOM")		-- superceded by the addon
	customStatusBarManager.BottomBarFrameTexture = customStatusBarManager:CreateTexture()
	customStatusBarManager.BottomBarFrameTexture:SetPoint("BOTTOMLEFT")
	customStatusBarManager.BottomBarFrameTexture:SetAtlas("UI-HUD-ExperienceBar-Frame", true)
	customStatusBarManager.BottomBarFrameTexture:Hide()
	customStatusBarManager.TopBarFrameTexture = customStatusBarManager:CreateTexture()
	customStatusBarManager.TopBarFrameTexture:SetPoint("BOTTOMLEFT", customStatusBarManager.BottomBarFrameTexture, "TOPLEFT", 0, -3)
	customStatusBarManager.TopBarFrameTexture:SetAtlas("UI-HUD-ExperienceBar-Frame", true)
	customStatusBarManager.TopBarFrameTexture:Hide()
	customStatusBarManager:SetScript("OnEvent", customStatusBarManager.OnEvent)
	customStatusBarManager:OnLoad()
	
	-- additional rules unique to CT_BottomBar
	customStatusBarManager:SetPoint("TOPLEFT", self.frame, 0, 10)
	customStatusBarManager:SetPoint("RIGHT", self.frame)
	customStatusBarManager.BottomBarFrameTexture:SetPoint("RIGHT")
	customStatusBarManager.TopBarFrameTexture:SetPoint("RIGHT", customStatusBarManager.BottomBarFrameTexture)
	
	-- Adding the bars
	customStatusBarManager:AddBarFromTemplate("Frame", "ReputationStatusBarTemplate")
	customStatusBarManager:AddBarFromTemplate("Frame", "HonorStatusBarTemplate")
	customStatusBarManager:AddBarFromTemplate("Frame", "ArtifactStatusBarTemplate")
	customStatusBarManager:AddBarFromTemplate("Frame", "ExpStatusBarTemplate")
    customStatusBarManager:AddBarFromTemplate("Frame", "AzeriteBarTemplate")
    
	customStatusBarManager.UpdateBarsShown = CT_BottomBar_StatusBar_UpdateBarsShown;
	for i, bar in ipairs(customStatusBarManager.bars) do
		-- prevents mouseover text (such as how much xp or rep you have) from appearing overtop the world map frame
		bar.OverlayFrame:SetFrameStrata("MEDIUM");	
	end

	addon_Update(self);
	
	return true;
end

local function addon_PostInit(self)
	if (module:getOption("enableStatus Bar") == false) then addon_Disable(self); end
	CT_BottomBar_StatusBar_UpdateBarsShown(self)	
end


function CT_BottomBar_StatusBar_UpdateBarsShown(self)
 	local visibleBars = {};
 	if ( customStatusBarManager.bars[1].ShouldBeVisible() and not module:getOption("customStatusBarHideReputation")) then	table.insert(visibleBars, customStatusBarManager.bars[1]); end
  	if ( customStatusBarManager.bars[2].ShouldBeVisible() and not module:getOption("customStatusBarHideHonor")) then table.insert(visibleBars, customStatusBarManager.bars[2]); end
  	if ( customStatusBarManager.bars[3].ShouldBeVisible() and not module:getOption("customStatusBarHideArtifact")) then table.insert(visibleBars, customStatusBarManager.bars[3]); end
  	if ( customStatusBarManager.bars[4].ShouldBeVisible() and not module:getOption("customStatusBarHideExp")) then	table.insert(visibleBars, customStatusBarManager.bars[4]); end
  	if ( customStatusBarManager.bars[5].ShouldBeVisible() and not module:getOption("customStatusBarHideAzerite")) then table.insert(visibleBars, customStatusBarManager.bars[5]); end
   	table.sort(visibleBars, function(left, right) return left:GetPriority() < right:GetPriority() end);
	customStatusBarManager:LayoutBars(visibleBars); 	
end

function CT_BottomBar_StatusBar_OnStatusBarsUpdated(self)
	--This is supposed to be lots of shifting, but meh
end

local function addon_Register()
	module:registerAddon(
		"Status Bar",  -- option name
		"StatusBar",  -- used in frame names
		module.text["CT_BottomBar/Options/StatusBar"],  -- shown in options window & tooltips
		module.text["CT_BottomBar/Options/StatusBar"],  -- title for horizontal orientation
		nil,  -- title for vertical orientation
		{ "BOTTOM", ctRelativeFrame, "BOTTOM", 0, 18 },
		{ -- settings
			orientation = "ACROSS",
		},
		addon_Init,
		addon_PostInit,  -- no post init function
		nil,  -- no config function
		addon_Update,
		nil,  -- no orientation function
		addon_Enable,
		addon_Disable,
		"helperFrame",
		StatusBarTrackingManager
	);
end



module.loadedAddons["Status Bar"] = addon_Register;