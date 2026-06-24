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

local appliedOptions;

--------------------------------------------
-- Miscellaneous

local checkVehicleUI = not not VehicleSeatIndicator

function module:hasVehicleUI()
	if (checkVehicleUI) then
		local hasVehicleUI = CT_BottomBar_SecureFrame:GetAttribute("has-vehicleui");
		local hasSkin = UnitVehicleSkin("player") and UnitVehicleSkin("player") ~= "";
		return hasVehicleUI and hasSkin;
	else
		return false;
	end
end

function module:hasOverrideUI()
	if (checkVehicleUI) then
		local hasOverrideUI = CT_BottomBar_SecureFrame:GetAttribute("has-overridebar");
		local hasSkin = GetOverrideBarSkin() and GetOverrideBarSkin() ~= "";
		return hasOverrideUI and hasSkin;
	else
		return false;
	end
end

--------------------------------------------
-- OverrideActionBar animations.

local animFlag;

if (OverrideActionBar) then
	-- WoW Classic does not have an OverrideActionBar
	OverrideActionBar.slideOut:HookScript("OnPlay",
		function(self)
			animFlag= true;
			module:animStarted();
		end
	);
	OverrideActionBar.slideOut:HookScript("OnFinished",
		function(self)
			animFlag= false;
			module:animStopped();
		end
	);
end
function module:isOverrideActionBarAnimating()
	return animFlag;
end

--------------------------------------------
-- Show and hide the override action bar.

local isOverrideHidden;  -- nil == not shown or hidden yet, true == we've shown it, false == we've hidden it.
local overrideFrames = {
	-- The frames related to the OverrideActionBar frame.
	"OverrideActionBar",
	"OverrideActionBarPitchFrame",
	"OverrideActionBarPitchFramePitchUpButton",
	"OverrideActionBarPitchFramePitchDownButton",
	"OverrideActionBarLeaveFrame",
	"OverrideActionBarLeaveFrameLeaveButton",
	"OverrideActionBarExpBar",
	"OverrideActionBarExpBarOverlayFrame",
	"OverrideActionBarHealthBar",
	"OverrideActionBarPowerBar",
	"OverrideActionBarButton1",
	"OverrideActionBarButton1Cooldown",
	"OverrideActionBarButton2",
	"OverrideActionBarButton2Cooldown",
	"OverrideActionBarButton3",
	"OverrideActionBarButton3Cooldown",
	"OverrideActionBarButton4",
	"OverrideActionBarButton4Cooldown",
	"OverrideActionBarButton5",
	"OverrideActionBarButton5Cooldown",
	"OverrideActionBarButton6",
	"OverrideActionBarButton6Cooldown",
};

local function override_Hooked_SetAlpha(self, alpha)
	if (OverrideActionBar) then
		-- Hook of the SetAlpha function for the override bar frames.
		-- Something other than CT_BottomBar is calling the frame's :SetAlpha().

		-- Keep track of the last update value.
		self.ctSaveAlpha = alpha;
		-- If we have the override bar hidden, then "hide" the frame.
		if (isOverrideHidden) then
			if (self.ctInUse) then
				-- We are using the frame in CT_BottomBar.
				-- Set the value to the one we are using.
				alpha = self.ctUseAlpha;
			else
				-- Set the value to 0 to "hide" the frame.
				alpha = 0;
			end
			module.frame_SetAlpha(self, alpha);
	--	else
	--		-- We have shown the override bar, or we haven't done anything with it yet.
	--		-- Allow the change to stick. Don't override it.
		end
	end
end

local function override_Hooked_EnableMouse(self, enable)
	if (OverrideActionBar) then
		-- Hook of the EnableMouse function for the override bar frames.
		-- Something other than CT_BottomBar is calling the frame's :EnableMouse().

		-- Keep track of the last update value.
		self.ctSaveMouse = enable;
		-- If we have the override bar hidden, then "hide" the frame.
		if (isOverrideHidden) then
			if (self.ctInUse) then
				-- We are using the frame in CT_BottomBar.
				-- Set the value to the one we are using.
				enable = self.ctUseMouse;
			else
				-- Set the value to false to "hide" the frame.
				enable = false;
			end
			if (not (self:IsProtected() and InCombatLockdown())) then
				module.frame_EnableMouse(self, enable);
			end
	--	else
	--		-- We have shown the override bar, or we haven't done anything with it yet.
	--		-- Allow the change to stick. Don't override it.
		end
	end
end

local function override_HideFrames()
	if (OverrideActionBar) then
		-- Hide the override bar frames.
		local frame, alpha, mouse;
		local inCombatLockdown = InCombatLockdown();

		for i, name in ipairs(overrideFrames) do
			frame = _G[name];
			if (frame and frame.ctInUse) then
				-- We are using the frame in CT_BottomBar.
				-- Set the values to the ones being used.
				alpha = frame.ctUseAlpha;
				mouse = frame.ctUseMouse;
			else
				-- Set the values so that we "hide" the frame.
				alpha = 0;
				mouse = false;
			end
			module.frame_SetAlpha(frame, alpha);
			if (not (frame:IsProtected() and inCombatLockdown)) then
				module.frame_EnableMouse(frame, mouse);
			end
		end
	end
end

local function override_ShowFrames()
	if (OverrideActionBar) then
		-- Show the override bar frames.
		local frame, alpha, mouse;
		local inCombatLockdown = InCombatLockdown();

		for i, name in ipairs(overrideFrames) do
			frame = _G[name];
			if (frame) then
				if (frame.ctInUse) then
					-- We are using the frame in CT_BottomBar.
					-- Set the values to the ones being used.
					alpha = frame.ctUseAlpha;
					mouse = frame.ctUseMouse;
				else
					-- Set the values so that we "show" the frame by restoring the saved values.
					alpha = frame.ctSaveAlpha;
					mouse = frame.ctSaveMouse;
				end
				module.frame_SetAlpha(frame, alpha);
				if (not (frame:IsProtected() and inCombatLockdown)) then
					module.frame_EnableMouse(frame, mouse);
				end
			end
		end
	end
end

function module:showOverrideActionBar()
	if (OverrideActionBar) then
		-- We have not shown it yet, or it is hidden.
		if (InCombatLockdown()) then
			-- Don't do anything while in combat lockdown.
			-- Don't call :needOverrideUpdate. When the player gets out of combat, another
			-- function will be called and it will attempt to show or hide the override bar.
			return false;
		end
		if (module:isBlizzardAnimating()) then
			-- We'll need to use the OnUpdate to wait for the animation to stop.
			module:needOverrideUpdate(1); -- 1 == need to show override bar
			return false;
		end

		-- Show the override bar frames.
		override_ShowFrames();

		isOverrideHidden = false;  -- We have now shown it.
		module:needOverrideUpdate(nil);  -- No longer need to update the override bar.
		return true;
	end
end

function module:hideOverrideActionBar()
	if (OverrideActionBar) then
		-- Hide the override action bar.
		-- Returns: true if the bar was successfully hidden.
		--         false if the bar failed to be hidden.

		-- We have not hidden it yet, or it is shown.
		if (InCombatLockdown()) then
			-- We can't do anything while in combat lockdown.
			-- Don't call :needOverrideUpdate. When the player gets out of combat, another
			-- function will be called and it will attempt to show or hide the override bar.
			return false;
		end
		if (module:isBlizzardAnimating()) then
			-- We'll need to use the OnUpdate to wait for the animation to stop.
			module:needOverrideUpdate(2); -- 2 == need to hide override bar
			return false;
		end

		-- Hide the override bar frames.
		override_HideFrames();

		isOverrideHidden = true;  -- We have now hidden it.
		module:needOverrideUpdate(nil);  -- No longer need to update the override bar.
		return true;
	end
end

function module:override_OnUpdate(value)
	if (OverrideActionBar) then
		-- Called by CT_BottomBar_OnUpdateFunc when we need to update the override bar
		-- because we were previously unable to do so.
		if (value == 1) then
			-- Show the override action bar.
			module:showOverrideActionBar();
		elseif (value == 2) then
			-- Hide the override action bar.
			module:hideOverrideActionBar();
		end
	end
end

--------------------------------------------
-- Initialize

function module:initOverrideActionBar()
	if (OverrideActionBar) then
		-- Initialize the override action bar

		local frame;
		for i, name in ipairs(overrideFrames) do
			frame = _G[name];
			frame.ctInUse = false;
			frame.ctUseAlpha = 0;
			frame.ctUseMouse = false;
			frame.ctSaveAlpha = frame:GetAlpha();
			frame.ctSaveMouse = frame:IsMouseEnabled();
			-- Hook some of the frame's functions.
			hooksecurefunc(frame, "SetAlpha", override_Hooked_SetAlpha);
			hooksecurefunc(frame, "EnableMouse", override_Hooked_EnableMouse);
		end
	end
end

function module:overrideInit()
	-- Initialize this lua file.
	appliedOptions = module.appliedOptions;
end