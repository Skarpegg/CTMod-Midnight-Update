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
	-- see module.init() that disables the action bar during game load.
	return
end

--------------------------------------------
-- Initialization

local _G = getfenv(0);
local module = _G.CT_BottomBar;

local appliedOptions;
local frame_SetAlpha;
local frame_EnableMouse;

--------------------------------------------
-- Configure gryphons

local savedHideGryphons;

function module:configureGryphons()
	-- Gryphons
	--
	-- When CT_BottomBar and CT_Core are both loaded, we want CT_BottomBar's
	-- gryphon option to have priority over the CT_Core one when the addons
	-- are loading.
	--
	-- CT_Core's default is to not hide the gryphons. CT_BottomBar's default
	-- is to hide the gryphons.
	--
	-- Since CT_BottomBar loads before CT_Core, CT_BottomBar will apply its
	-- gryphon option first, but since CT_Core is not loaded CT_BottomBar
	-- cannot update CT_Core's option.
	--
	-- When CT_Core loads, it applies its gryphon option and updates the
	-- CT_BottomBar option since both addons are now loaded. We'll save
	-- the current CT_BottomBar option in a variable that we will later
	-- apply at PLAYER_LOGIN time so that we can override CT_Core's option.

	-- Save the state of the gryphons as defined by the CT_BottomBar option.
	savedHideGryphons = appliedOptions.hideGryphons;
	-- Hide/show the gryphons.
	module:toggleGryphons(appliedOptions.hideGryphons);
	-- Possibly show the lions instead of gryphons.
	module:showLions(appliedOptions.showLions);
end

function module:restoreGryphons()
	-- This will get called at PLAYER_LOGIN time so that we can override
	-- CT_Core's gryphons option.

	-- Hide/show the gryphons using the saved setting.
	module:toggleGryphons(savedHideGryphons);
	-- Possibly show the lions instead of gryphons.
	module:showLions(appliedOptions.showLions);
end

--------------------------------------------
-- Hide Gryphons

local gryphonLoop;

function module:toggleGryphons(hide)
	if (gryphonLoop) then
		-- Prevent infinite loop.
		gryphonLoop = nil;
		return;
	end
	-- Hide/Show the gryphons
	if ( hide ) then
		if (module:getGameVersion() >= 8) then
			-- Retail
			MainMenuBarArtFrame.LeftEndCap:Hide();
			MainMenuBarArtFrame.RightEndCap:Hide();
		else
			-- Classic
			MainMenuBarLeftEndCap:Hide();
			MainMenuBarRightEndCap:Hide();
		end
	else
		if (module:getGameVersion() >= 8) then
			MainMenuBarArtFrame.LeftEndCap:Show();
			MainMenuBarArtFrame.RightEndCap:Show();
		else
			MainMenuBarLeftEndCap:Show();
			MainMenuBarRightEndCap:Show();
		end
	end
end

--------------------------------------------
-- Show lions instead of gryphons

local shownLions;

function module:showLions(show)
	if (show) then
		(module:getGameVersion() >= 8 and MainMenuBarArtFrame.LeftEndCap or MainMenuBarLeftEndCap):SetTexture("Interface\\MainMenuBar\\UI-MainMenuBar-EndCap-Human");
		(module:getGameVersion() >= 8 and MainMenuBarArtFrame.RightEndCap or MainMenuBarRightEndCap):SetTexture("Interface\\MainMenuBar\\UI-MainMenuBar-EndCap-Human");
		shownLions = true;
	else
		-- Only show the gryphons if we have previously shown the lions.
		if (shownLions) then
			(module:getGameVersion() >= 8 and MainMenuBarArtFrame.LeftEndCap or MainMenuBarLeftEndCap):SetTexture("Interface\\MainMenuBar\\UI-MainMenuBar-EndCap-Dwarf");
			(module:getGameVersion() >= 8 and MainMenuBarArtFrame.RightEndCap or MainMenuBarRightEndCap):SetTexture("Interface\\MainMenuBar\\UI-MainMenuBar-EndCap-Dwarf");
			shownLions = false;
		end
	end
end

--------------------------------------------
-- Hide Background Textures

local hidMainBackground, hidMenuAndBagsBackground;

--From WoW 8.0.1 forward, this only hides the main artwork in the middle but not the micro-button menu and bags artwork in the bottom right
function module:hideTexturesBackground(hide)
	-- Hide/Show the background textures
	
	-- Changed in WoW 8.0.1 to now hide the "small" texture when only the left half is showing.

	if (hide) then
		if (module:getGameVersion() >= 8) then
			-- Retail
			MainMenuBarArtFrameBackground:Hide();
		else
			-- Classic
			MainMenuBarTexture0:Hide();
			MainMenuBarTexture1:Hide();
			StanceBarLeft:SetAlpha(0);
			StanceBarMiddle:SetAlpha(0);
			StanceBarRight:SetAlpha(0);
		end
		hidMainBackground = true;
	else
		-- Only show the textures if we previously hid them.
		if (hidMainBackground) then
			if (module:getGameVersion() >= 8) then
				-- Retail
				MainMenuBarArtFrameBackground:Show();
			else
				-- Classic
				MainMenuBarTexture0:Show();
				MainMenuBarTexture1:Show();
				StanceBarLeft:SetAlpha(1);
				StanceBarMiddle:SetAlpha(1);
				StanceBarRight:SetAlpha(1);
			end
			hidMainBackground = false;
		end
	end
	
end

--From WoW 8.0.1 forward (retail only), this hides the micro-button menu and bags artwork in the bottom right
function module:hideMenuAndBagsBackground(hide)
	-- Hide/Show the background textures
	
	if (hide) then
		if (module:getGameVersion() >= 8) then
			-- Retail
			MicroButtonAndBagsBar:Hide();
		else
			-- Classic
			MainMenuBarTexture2:Hide();
			MainMenuBarTexture3:Hide();
		end
		hidMenuAndBagsBackground = true;
	else
		-- Only show the textures if we previously hid them.
		if (hidMenuAndBagsBackground) then
			if (module:getGameVersion() >= 8) then
				-- Retail
				MicroButtonAndBagsBar:Show();
			else
				-- Classic
				MainMenuBarTexture2:Show();
				MainMenuBarTexture3:Show();
			end
			hidMenuAndBagsBackground = false;
		end
	end

	
end


--------------------------------------------
-- Configure artwork

function module:configureArtwork()
	module:hideTexturesBackground(appliedOptions.hideTexturesBackground);
	module:hideMenuAndBagsBackground(appliedOptions.hideMenuAndBagsBackground);
end

--------------------------------------------
-- MainMenuBar animations.

local animFlag;

MainMenuBar.slideOut:HookScript("OnPlay",
	function(self)
		animFlag = true;
		module:animStarted();
	end
);
MainMenuBar.slideOut:HookScript("OnFinished",
	function(self)
		animFlag= false;
		module:animStopped();
	end
);

function module:isMainMenuBarAnimating()
	return animFlag;
end

--------------------------------------------
-- Disable action bar

local function hooked_SetAlpha(self, alpha)
	frame_SetAlpha(self, 0);
end

local function hooked_RegisterEvent(self, event)
	self:UnregisterEvent(event);
end

local function hooked_EnableMouse(self, enable)
	if (not InCombatLockdown()) then
		frame_EnableMouse(self, false);
	end
end

local function hooked_Show(self)
	if (not InCombatLockdown()) then
		self:Hide();
	end
end

function module:disableActionBar()
	-- Disable the action and bonus action bars.

	-- Disable and hide the ActionButton buttons.
	local name, obj;
	name = "ActionButton";
	for j = 1, 12 do
		obj = _G[name .. j];
		obj:UnregisterAllEvents();
		obj:EnableMouse(false);
		obj:SetAlpha(0);
		obj:Hide();

		-- Try to keep the alpha at zero.
		hooksecurefunc(obj, "SetAlpha", hooked_SetAlpha);

		-- Try to keep events from being re-registered.
		hooksecurefunc(obj, "RegisterEvent", hooked_RegisterEvent);

		-- Try to keep the mouse disabled.
		hooksecurefunc(obj, "EnableMouse", hooked_EnableMouse);

		-- Try to keep the frame hidden.
		hooksecurefunc(obj, "Show", hooked_Show);
		obj:SetAttribute("statehidden", true);
		RegisterStateDriver(obj, "visibility", "hide");
	end

	-- Because we are continuing to use Blizzard's own buttons for the various
	-- CT_BottomBar bars, we need to keep as much of the default UI active as
	-- possible, so that those bars and their buttons can be updated, shown, and
	-- hidden properly by the default UI.
	--
	-- This means that we can't disable the events on the MainMenuBar,
	-- or MainMenuBarArtFrame. We also don't want to hide these frame.
	-- We want Blizzard to continue to manipulate
	-- them.

	-- Don't disable or hide the MainMenuBar. It is used to support
	-- the other bars.

	-- Don't disable or hide the MainMenuBarArtFrame.
end

--------------------------------------------
-- Initialize

function module:mainmenuConfigure()
	-- MainMenuBar Gryphons
	module:configureGryphons();

	-- MainMenuBar artwork
	module:configureArtwork();
end

function module:initMainMenuBar()
	-- Initialize the main menu bar.
	frame_SetAlpha = module.frame_SetAlpha;
	frame_EnableMouse = module.frame_EnableMouse;

	-- Disable mouse in MainMenuBar
	MainMenuBar:EnableMouse(false);
end

function module:mainmenuInit()
	-- Initialize this lua file.
	appliedOptions = module.appliedOptions;
end
