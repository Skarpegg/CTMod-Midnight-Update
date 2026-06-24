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
--                                            --
-- Original credits to Cide and TS (Vanilla)  --
-- Maintained by Resike from 2014 to 2017     --
-- Maintained by Dahk Celes since 2018        --
--                                            --
-- This file provides the /ctbb options menu  --
------------------------------------------------

--------------------------------------------
-- Initialization

local _G = getfenv(0);
local module = _G.CT_BottomBar;

-- All of the bar frames are relative to this frame.
module.ctRelativeFrame = UIParent;

local appliedOptions;
local pendingOptions;

local theOptionsFrame;
local exprepOptionsFrame;

module.text = module.text or {}; --see localization.lua
local L = module.text

----------------------------------------------
-- Miscellaneous

local function updateBarWidgets()
	-- Update the widgets in the "Bars" section of the options window.
	local frame = theOptionsFrame;

	if (frame and frame:IsShown()) then

		frame = frame.bar;

		-- Set the enable rep bar checkbox to the same state as the enable exp bar checkbox.
		-- The two options should be synchronized.
		local cbRep = frame["enableReputation Bar"];
		local cbExp = frame["enableExperience Bar"];
		if (cbRep and cbExp) then
			cbRep:SetChecked( cbExp:GetChecked() );
			cbRep:Hide();
			cbRep:Disable();
			cbRep.text:SetTextColor(0.4, 0.4, 0.4, 1);
		end

		-- Only show the "Hide" checkbox if the "Enable" one is checked.
		for key, obj in ipairs(module.addons) do
			if (not obj.settings.hideFromBarList) then
				if (obj.settings.noHideOption) then
					-- Don't show hide checkbox for this bar (not allowing user to force hide/show).
					frame[obj.optionName]:Hide();
				else
					if (frame["enable" .. obj.optionName]:GetChecked()) then
						frame[obj.optionName]:Show();
					else
						frame[obj.optionName]:Hide();
					end
				end
			end
		end
	end
end

local function updateDisableActionBarWidget()
	local frame = theOptionsFrame;
	if (type(frame) == "table") then
		frame = frame.actionbar;
		local optName = "disableDefaultActionBar";
		local obj = frame[optName];
		obj:SetChecked( appliedOptions[optName] );
	end
end

local preventLoop;
module.updateOptionFromOutside = function(optName, value)
	if (preventLoop) then
		return;
	end

	if optName == "disableDefaultActionBar"
		or optName == "disableDragonflightActionBar"
	then
		module:setOption(optName, value)
	end
	
end

local addonTitles = { }
function module:insertAddonTitle(title)
	addonTitles[#module.addons + 1] = title	
end

------------------------------------------------
-- Show the drag frames.

local function showModules_CTBarMod(self)
	-- If CT_BarMod is detected then show its bars as well.
	if ( self and CT_BarMod and CT_BarMod.show ) then
		-- Call without self parameter to prevent infinite loop.
		CT_BarMod.show(nil);
	end
end

local function showModules(self)
	-- This will show the drag frames.
	-- It is called when the options window opens.
	module.optionsWindowOpen = true;
	for key, obj in ipairs(module.addons) do
		obj:updateDragVisibility(nil);
	end
	if (appliedOptions.showCTBarMod) then
		showModules_CTBarMod(self);
	end
end

module.show = showModules;

------------------------------------------------
-- Hide the drag frames.

local function hideModules_CTBarMod(self)
	-- If CT_BarMod is detected then hide its bars as well.
	if ( self and CT_BarMod and CT_BarMod.hide ) then
		-- Call without self parameter to prevent infinite loop.
		CT_BarMod.hide(nil);
	end
end

local function hideModules(self)
	-- This will hide the drag frames.
	-- It is called when the options window closes.
	module.optionsWindowOpen = false;
	for key, obj in ipairs(module.addons) do
		obj:updateDragVisibility(false);
	end
	hideModules_CTBarMod(self);
end

module.hide = hideModules;

----------------------------------------------
-- Update and apply options.

local function applyUnprotectedOption(optName, value)
	-- Apply an unprotected option.
	--
	-- These will all succeed since they work even if in combat.
	--
	pendingOptions[optName] = nil;
	appliedOptions[optName] = value;
	return true;
end

local function applyProtectedOption(optName, value)
	-- Apply a protected option.
	--
	-- These are options that cannot be applied if we're in combat.
	--
	-- If we can't apply the option, then we'll place the option name
	-- and value in the pendingOptions table. When we get out of combat
	-- we'll apply what ever is in the table.
	--
	if (InCombatLockdown()) then
		pendingOptions[optName] = value;
		return false;
	end
	pendingOptions[optName] = nil;
	appliedOptions[optName] = value;
	-- Special cases
	if (optName == "vehicleHideFrame") then
		-- The vehicle and override bars use the same frame, so we only have
		-- one option in the options window, but the source code is using
		-- two appliedOptions with the same value.
		appliedOptions["overrideHideFrame"] = value;
	elseif (optName == "vehicleHideEnabledBars") then
		-- The vehicle and override bars use the same frame, so we only have
		-- one option in the options window, but the source code is using
		-- two appliedOptions with the same value.
		appliedOptions["overrideHideEnabledBars"] = value;
	end
	return true;
end

function module:applyPendingOptions()
	-- Apply any options that are in the pendingOptions table.
	--
	-- These will only be applied if we are not in combat.
	--
	if (InCombatLockdown()) then
		return;
	end
	if (next(pendingOptions)) then
		-- Need to copy pendingOptions contents into temp table,
		-- otherwise we can end up with an "Invalid key to 'next'"
		-- lua error in function '(for generator)' after we
		-- return from module:update() which sets pendingOptions[optName]
		-- to nil. Can see problem with original code if you deactivate
		-- the Pet Bar, reloaded ui, enter combat, then activate the Pet
		-- Bar. When combat ends it calls this function and you got the
		-- error message after it has called module:update once.

		--for optName, value in pairs(module.pendingOptions) do
		--	module:update(optName, value);
		--end

		local temp = {}
		for optName, value in pairs(pendingOptions) do
			temp[optName] = value;
		end
		for optName, value in pairs(temp) do
			module:update(optName, value);
		end
	end
end

function module:updateOption(optName, value)
	-- Update an option's value.
	-- optName -- name of option to be changed.
	-- value -- new value for the option.

	if (optName == "petBarScale") then
		value = value or 1;
		if (applyProtectedOption(optName, value)) then
			local obj = module.ctPetBar;
			if (obj and not obj.isDisabled) then
				module.updatePetBar(optName, value);
			end
		end

	elseif (optName == "petBarOpacity") then
		value = value or 1;
		if (applyUnprotectedOption(optName, value)) then
			local obj = module.ctPetBar;
			if (obj and not obj.isDisabled) then
				module.updatePetBar(optName, value);
			end
		end

	elseif (optName == "petBarSpacing") then
		value = value or 6;
		if (applyProtectedOption(optName, value)) then
			local obj = module.ctPetBar;
			if (obj and not obj.isDisabled) then
				module.updatePetBar(optName, value);
			end
		end

	elseif (optName == "extraBarTexture") then
		value = not not value;
		if (applyUnprotectedOption(optName, value)) then
			local obj = module.ctExtraBar;
			if (obj and not obj.isDisabled) then
				module.updateExtraBar(optName, value);
			end
		end

	elseif (optName == "extraBarScale") then
		value = value or 1;
		if (applyProtectedOption(optName, value)) then
			local obj = module.ctExtraBar;
			if (obj and not obj.isDisabled) then
				module.updateExtraBar(optName, value);
			end
		end

	elseif (optName == "vehicleHideFrame"
			) then
		value = not not value;
		if (applyProtectedOption(optName, value)) then
--			module:updateSpecialVisibility();
--			module:updateBarVisibility();
			module:updateAllVisibility();
		end

	elseif (optName == "vehicleHideEnabledBars"
			or optName == "petbattleHideEnabledBars"
			) then
		value = value ~= false;
		if (applyProtectedOption(optName, value)) then
			module:updateBarVisibility();
		end

	elseif (optName == "vehicleBarAimButtons") then
		value = value ~= false;
		if (applyUnprotectedOption(optName, value)) then
			-- Call the vehicle bar update function
			local obj = module.ctVehicleBar;
			if (obj and not obj.isDisabled) then
				local func = obj.updateFunc;
				if (func) then
					func(obj);
				end
			end
		end

	elseif (optName == "bagsBarHideBags") then
		value = not not value;
		if (applyUnprotectedOption(optName, value)) then
			local obj = module.ctBagsBar;
			obj:update();
		end

	elseif (optName == "bagsBarSpacing") then
		value = value or 2;
		if (applyUnprotectedOption(optName, value)) then
			-- Call the bags bar update function
			local obj = module.ctBagsBar;
			if (obj and not obj.isDisabled) then
				local func = obj.updateFunc;
				if (func) then
					func(obj);
				end
			end
		end
		
	elseif optName == "microButtonSpacing" then
		value = value or module:getGameVersion() >= 10 and 0 or -3
		if applyUnprotectedOption(optName, value) then
			module.ctMenuBar:updateFunc()
		end

	elseif (optName == "customStatusBarWidth") then				-- used in retail
		value = value or 768;
		if (applyUnprotectedOption(optName, value)) then
			module:CT_BottomBar_StatusBar_SetWidth();
		end
	elseif (optName == "customStatusBarHideReputation" or			-- used in retail
		optName == "customStatusBarHideHonor" or
		optName == "customStatusBarHideArtifact" or
		optName == "customStatusBarHideExp" or
		optName == "customStatusBarHideAzerite"
	) then
		value = value or false;
			if (applyProtectedOption(optName, value)) then
			CT_StatusTrackingBarManager:UpdateBarsShown();
		end
		
	elseif (optName == "repBarHideNoRep" or			-- used in classic
		optName == "repBarCoverExpBar" or
		optName == "expBarShowMaxLevelBar"
	) then
		value = not not value;
		if (applyUnprotectedOption(optName, value)) then
			local obj1 = module.ctRepBar;
			local obj2 = module.ctExpBar;
			local update;
			if (obj1 and not obj1.isDisabled) then
				update = true;
			end
			if (obj2 and not obj2.isDisabled) then
				update = true;
			end
			if (update) then
				-- Call Blizzard's function that updates the reputation and exp bars.
				(ReputationWatchBar_UpdateMaxLevel or ReputationWatchBar_Update)(); -- classic vs cata
			end
		end

	elseif (optName == "repBarWidth") then			-- used in classic
		value = value or EXP_DEFAULT_WIDTH or 1024;
		if (applyUnprotectedOption(optName, value)) then
			module:CT_BottomBar_ExpBar_SetWidth();
			module:CT_BottomBar_RepBar_SetWidth();
		end

	elseif (optName == "expBarWidth") then			-- used in classic
		value = value or EXP_DEFAULT_WIDTH or 1024;
		if (applyUnprotectedOption(optName, value)) then
			module:CT_BottomBar_ExpBar_SetWidth();
			module:CT_BottomBar_RepBar_SetWidth();
		end

	elseif (optName == "repBarNumDivisions") then			-- used in classic
		value = value or 20;
		if (applyUnprotectedOption(optName, value)) then
			module:CT_BottomBar_RepBar_Configure();
		end

	elseif (optName == "expBarNumDivisions") then			-- used in classic
		value = value or 20;
		if (applyUnprotectedOption(optName, value)) then
			module:CT_BottomBar_ExpBar_Configure();
		end

	elseif (optName == "exprepAltBorder") then			-- used in classic
		value = not not value;
		if (applyUnprotectedOption(optName, value)) then
			module:CT_BottomBar_ExpBar_Configure();
			module:CT_BottomBar_RepBar_Configure();
		end

	elseif (optName == "exprepAltDivisions") then			-- used in classic
		value = not not value;
		if (applyUnprotectedOption(optName, value)) then
			module:CT_BottomBar_ExpBar_Configure();
			module:CT_BottomBar_RepBar_Configure();
		end

	elseif (optName == "repBarHideDivisions") then			-- used in classic
		value = not not value;
		if (applyUnprotectedOption(optName, value)) then
			module:CT_BottomBar_RepBar_Configure();
		end

	elseif (optName == "repBarHideBorder") then			-- used in classic
		value = not not value;
		if (applyUnprotectedOption(optName, value)) then
			module:CT_BottomBar_RepBar_Configure();
		end

	elseif (optName == "expBarHideDivisions") then			-- used in classic
		value = not not value;
		if (applyUnprotectedOption(optName, value)) then
			module:CT_BottomBar_ExpBar_Configure();
		end

	elseif (optName == "expBarHideBorder") then			-- used in classic
		value = not not value;
		if (applyUnprotectedOption(optName, value)) then
			module:CT_BottomBar_ExpBar_Configure();
		end

	elseif (optName == "expBarHideAtMaxLevel") then			-- used in classic
		value = not not value;
		if (applyUnprotectedOption(optName, value)) then
			(ReputationWatchBar_UpdateMaxLevel or ReputationWatchBar_Update)();  -- classic vs cata
		end

	elseif (optName == "hideGryphons") then
		value = value ~= false;
		if (applyUnprotectedOption(optName, value)) then
			module:toggleGryphons(value);
		end

	elseif (optName == "showLions") then
		value = not not value;
		if (applyUnprotectedOption(optName, value)) then
			module:showLions(value);
		end

	elseif (optName == "hideTexturesBackground") then
		value = value ~= false;
		if (applyUnprotectedOption(optName, value)) then
			module:hideTexturesBackground(value);
		end

	elseif (optName == "hideMenuAndBagsBackground") then
		value = value ~= false;
		if (applyUnprotectedOption(optName, value)) then
			module:hideMenuAndBagsBackground(value);
		end

	elseif (optName == "showCTBarMod") then
		value = not not value;
		if (applyUnprotectedOption(optName, value)) then
			if (value) then
				showModules_CTBarMod(self);
			else
				hideModules_CTBarMod(self);
			end
		end

	-- REMOVED IN 8.0.1.5 -- elseif (optName == "dragHideTooltip") then
	-- REMOVED IN 8.0.1.5 -- 	value = not not value;
	-- REMOVED IN 8.0.1.5 -- 	applyUnprotectedOption(optName, value);

	elseif (optName == "clampFrames") then
		value = value ~= false;  -- change in 8.0.1.5 to default as true
		if (applyUnprotectedOption(optName, value)) then
			for key, obj in ipairs(module.addons) do
				if (not obj.isDisabled) then
					obj:setClamped(value);
				end
			end
		end

	elseif (optName == "disableDefaultActionBar") then
		-- Disable the default main action bar.
		-- Default: true
		value = value ~= false;
		applyUnprotectedOption(optName, value);

		-- Update the checkbox.
		updateDisableActionBarWidget();

		if (CT_BarMod and CT_BarMod.updateOptionFromOutside) then
			-- Set the corresponding option in CT_BarMod.
			-- It is CT_BottomBar that is responsible for the actual
			-- disabling of the default main action bar.
			preventLoop = true;
			CT_BarMod.updateOptionFromOutside(optName, value);
			preventLoop = nil;
		end
	
	elseif optName == "disableDragonflightActionBar" then
		local time = GetServerTime()
		module:setOption("disableDragonflightActionBarChangedDate", time)
		if CT_BarMod and CT_BarMod.updateOptionFromOutside and not preventLoop then
			preventLoop = true
			CT_BarMod.updateOptionFromOutside("disableDragonflightActionBar", value)		
			preventLoop = nil
		end
		if value then
			MainMenuBar.ctBBHidden = true
			if MainMenuBar.ctBBHiddenInDragonriding then
				module:afterCombat(RegisterAttributeDriver, MainMenuBar, "state-visibility", MainMenuBar.ctBBHiddenInVehicle and "hide" or "[overridebar] show; [vehicleui] show; hide")
			else
				module:afterCombat(RegisterAttributeDriver, MainMenuBar, "state-visibility", MainMenuBar.ctBBHiddenInVehicle and "[bonusbar:5] show; hide" or "[bonusbar:5] show; [overridebar] show; [vehicleui] show; hide")
			end
		elseif MainMenuBar.ctBBHidden then
			MainMenuBar.ctBBHidden = nil
			module:afterCombat(RegisterAttributeDriver, MainMenuBar, "state-visibility", "[overridebar] hide; [vehicleui] hide; show")
		end
		
	elseif optName == "disableDragonflightActionBarInVehicle" then
		MainMenuBar.ctBBHiddenInVehicle = value
		if MainMenuBar.ctBBHidden then
			if MainMenuBar.ctBBHiddenInDragonriding then
				module:afterCombat(RegisterAttributeDriver, MainMenuBar, "state-visibility", value and "hide" or "[overridebar] show; [vehicleui] show; hide")
			else
				module:afterCombat(RegisterAttributeDriver, MainMenuBar, "state-visibility", value and "[bonusbar:5] show; hide" or "[bonusbar:5] show; [overridebar] show; [vehicleui] show; hide")
			end
		end
	elseif optName == "disableDragonflightActionBarWhileDragonriding" then
		MainMenuBar.ctBBHiddenInDragonriding = value
		if MainMenuBar.ctBBHidden then
			if value then
				module:afterCombat(RegisterAttributeDriver, MainMenuBar, "state-visibility", MainMenuBar.ctBBHiddenInVehicle and "hide" or "[overridebar] show; [vehicleui] show; hide")
			else
				module:afterCombat(RegisterAttributeDriver, MainMenuBar, "state-visibility", MainMenuBar.ctBBHiddenInVehicle and "[bonusbar:5] show; hide" or "[bonusbar:5] show; [overridebar] show; [vehicleui] show; hide")
			end
		end
	else
		local found;
		for key, obj in ipairs(module.addons) do
			if (optName == obj.optionName) then
				-- Hide or show the bar.
				if (obj.settings.noHideOption) then
					-- No hide option available to user, so hide our frame.
					-- This noHideOption is for use with bars that Blizzard
					-- will be hiding/showing for us, so hiding our frame
					-- won't affect Blizzard's.
					value = false;
					break;
				end
				if (value == nil) then
					value = obj:isDefaultHidden();
				end
				value = not not value;
				if (not obj.frame:IsProtected()) then
					if (applyUnprotectedOption(optName, value)) then
						obj:updateVisibility();
					end
				else
					if (applyProtectedOption(optName, value)) then
						obj:updateVisibility();
					end
				end
				break;

			elseif (optName == "enable" .. obj.optionName) then
				-- Enable or disable the bar

				-- Don't allow enabling/disabling during combat.
				-- When activating, our frame is not protected
				-- since there are no secure buttons using it as their parent.
				-- When deactivating, our frame is protected since
				-- we have some secure buttons using the frame as their parent.
				--
				-- So, we'll just prevent any enabling/disabling during combat
				-- by pretending that all bars are protected.
				-- Possible future change might use our own flag to indicate
				-- if the bar is protected or unprotected and test for that
				-- rather than using :IsProtected(). This only affects things
				-- when activating/deactivating a bar.

				updateBarWidgets();
				local value0 = value;
				value = not not value;
				local protected = true; -- obj.frame:IsProtected(); -- See above comments
				if (not protected) then

					-- If user enables/disables the exp bar, then do the same
					-- with the rep bar. The two bars work together, and should
					-- both be enabled or disabled at the same time.
					-- The rep bar should be disabled before the exp bar.
					if (optName == "enableExperience Bar") then
						module:setOption("enableReputation Bar", value0);
					end

					if (applyUnprotectedOption(optName, value)) then
						if (value) then
							obj:enable();
						else
							obj:disable();
						end
						-- obj:updateVisibility();
					end
				else
					-- If user enables/disables the exp bar, then do the same
					-- with the rep bar. The two bars work together, and should
					-- both be enabled or disabled at the same time.
					-- The rep bar should be disabled before the exp bar.
					if (optName == "enableExperience Bar") then
						module:setOption("enableReputation Bar", value0);
					end

					if (applyProtectedOption(optName, value)) then
						if (value) then
							obj:enable();
						else
							obj:disable();
						end
						-- obj:updateVisibility();
					end
				end
				break;

			end
		end
	end
end

------------------------------------------------
-- Options Frame

local optionsFrameList;
local function optionsInit()
	optionsFrameList = module:framesInit();
end
local function optionsGetData()
	return module:framesGetData(optionsFrameList);
end
local function optionsAddFrame(offset, size, details, data)
	module:framesAddFrame(optionsFrameList, offset, size, details, data);
end
local function optionsAddObject(offset, size, details)
	module:framesAddObject(optionsFrameList, offset, size, details);
end
local function optionsAddScript(name, func)
	module:framesAddScript(optionsFrameList, name, func);
end
local function optionsBeginFrame(offset, size, details, data)
	module:framesBeginFrame(optionsFrameList, offset, size, details, data);
end
local function optionsAddTooltip (text) module:framesAddScript(optionsFrameList, "onenter", function(obj) module:displayTooltip(obj, text, "CT_ABOVEBELOW", 0, 0, CTCONTROLPANEL) end) end
local function optionsEndFrame()
	module:framesEndFrame(optionsFrameList);
end

module.frame = function()
	-- Function to create the options frame.
	-- Once created, module.frame becomes a table reference to the options frame.

	local textColor0 = "1.0:1.0:1.0";
	local textColor1 = "0.9:0.9:0.9";
	local textColor2 = "0.7:0.7:0.7";
	local textColor3 = "0.9:0.72:0.0";
	local offset;

	optionsInit();

	-- Tips
	optionsBeginFrame(-5, 0, "frame#tl:0:%y#r");
		optionsAddObject( -5, 3*14, "font#t:0:%y#s:0:%s#l:13:0#r#You can use /ctbb, /ctbottom, or /ctbottombar to open this options window directly.#" .. textColor2 .. ":l");
		optionsAddObject( -5, 2*14, "font#t:0:%y#s:0:%s#l:13:0#r#Remember to scroll down!  There are lots of customizations down below.#" .. textColor2 .. ":l");
		if module:getGameVersion() >= 10 then
			optionsAddObject( -5, 2*14, "font#t:0:%y#s:0:%s#l:13:0#r#Starting in Dragonflight (10.0.2), several functions migrated to \"Edit Mode\"#1:0.5:0:l")
		end
	optionsEndFrame();

	-- Bars
	optionsBeginFrame(-20, 0, "frame#tl:0:%y#br:tr:0:%b#i:bar");
		optionsAddObject(  0,    1, "texture#tl:5:%y#br:tr:0:%b#1:1:1");
		optionsAddObject(-15,   17, "font#tl:5:%y#v:GameFontNormalLarge#Movable Bars");

		optionsAddObject(-10, 3*14, "font#t:0:%y#s:0:%s#l:15:0#r#Activate a bar to control it with this addon.  Deactivate it to restore the original condition.#" .. textColor2 .. ":l");

		do
			local left, color;
			for key, obj in ipairs(module.addons) do
				if (addonTitles[key]) then
					optionsAddObject(-10,  14, "font#tl:15:%y#" .. addonTitles[key] .. "#" .. textColor3 .. ":l");
				end
				if ( obj.frames and (not obj.settings.hideFromBarList)) then
					if (obj.settings.optionsIndentBarName) then
						left = 35;
						color = textColor1;
					else
						left = 15;
						color = textColor0;
					end
					optionsAddObject( -5,   14, "font#tl:" .. left .. ":%y#" .. obj.addonName .. "#" .. color .. ":l:150");
					optionsAddObject( 21,   26, "checkbutton#tl:150:%y" .. "#i:enable" .. obj.optionName .. "#o:enable" .. obj.optionName .. ":" .. (module:getOption("enable" .. obj.optionName) ~= false and "true" or "false") .. "#" .. L["CT_BottomBar/Options/MovableBars/Activate"]);
					optionsAddObject( 26,   26, "checkbutton#tl:230:%y" .. "#i:" .. obj.optionName .. "#o:" .. obj.optionName .. ((obj:isDefaultHidden() and ":true") or "") .. "#" .. L["CT_BottomBar/Options/MovableBars/Hide"]);
				end
			end
		end

		optionsAddObject( -5, 3*14, "font#t:0:%y#s:0:%s#l:15:0#r#If a bar does not (de)activate as expected, try\n/console reloadui before resetting#" .. textColor2 .. ":l");

		optionsBeginFrame( -14,   30, "button#t:0:%y#s:200:%s#n:CT_BottomBar_ResetPositions_Button#v:GameMenuButtonTemplate#Reset bar positions");
			optionsAddScript("onclick",
				function(self)
					if ( InCombatLockdown() and self.frame:IsProtected() ) then
						return;
					end
					for key, obj in ipairs(module.addons) do
						obj:resetPosition();
					end
				end
			);
		optionsEndFrame();

		optionsAddScript("onshow",
			function(self)
				for key, obj in ipairs(module.addons) do
					if ( obj.frames and (not obj.settings.hideFromBarList) ) then
						self["enable" .. obj.optionName]:SetHitRectInsets(0, -40, 0, 0);
						self[obj.optionName]:SetHitRectInsets(0, -30, 0, 0);
					end
				end
				updateBarWidgets();
			end
		);
		
		optionsAddObject(  -15,    1, "texture#tl:5:%y#br:tr:0:%b#1:1:1");
		
	optionsEndFrame();
	
	-- General Options
	optionsBeginFrame(-20, 0, "frame#tl:0:%y#br:tr:0:%b");
		optionsAddObject(  0,   17, "font#tl:5:%y#v:GameFontNormalLarge#Important General Options");

		if module:getGameVersion() <= 9 then	
			optionsAddObject(-20,   17, "font#tl:5:%y#v:GameFontNormal#" .. L["CT_BottomBar/Options/General/BackgroundTextures/Heading"]);
			optionsAddObject( -5, 2*14, "font#t:0:%y#s:0:%s#l:13:0#r#" .. L["CT_BottomBar/Options/General/BackgroundTextures/Line1"] .. "#" .. textColor2 .. ":l");
			optionsAddObject( -5,   26, "checkbutton#tl:20:%y#i:showLions#o:showLions#" .. L["CT_BottomBar/Options/General/BackgroundTextures/ShowLionsCheckButton"]);
			optionsAddObject(  6,   26, "checkbutton#tl:20:%y#i:hideGryphons#o:hideGryphons:true#" .. L["CT_BottomBar/Options/General/BackgroundTextures/HideGryphonsCheckButton"]);
			optionsAddObject(  6,   26, "checkbutton#tl:20:%y#i:hideTexturesBackground#o:hideTexturesBackground:true#" .. L["CT_BottomBar/Options/General/BackgroundTextures/HideActionBarCheckButton"]);
			--optionsAddObject( -5, 2*14, "font#t:0:%y#s:0:%s#l:13:0#r#Warning: don't hide the bag/menu background if you unchecked 'Activate' up above#" .. textColor2 .. ":l");
			optionsAddObject(  6,   26, "checkbutton#tl:20:%y#i:hideMenuAndBagsBackground#o:hideMenuAndBagsBackground:true#" .. L["CT_BottomBar/Options/General/BackgroundTextures/HideMenuAndBagsCheckButton"]);
			optionsAddObject(  -15,    1, "texture#tl:5:%y#br:tr:0:%b#1:1:1");
		end

		optionsAddObject(-20,   17, "font#tl:5:%y#v:GameFontNormal#How to move bars");
		optionsAddObject( -5, 2*14, "font#t:0:%y#s:0:%s#l:13:0#r#You can move a bar off the screen if you want... but consider just hiding it instead#" .. textColor2 .. ":l");
		optionsAddObject(  -5,   26, "checkbutton#tl:20:%y#o:clampFrames:true#Cannot drag bars completely off screen");
		if (CT_BarMod) then
			optionsAddObject( -5, 2*14, "font#t:0:%y#s:0:%s#l:13:0#r#The numbered bars are part of CT_BarMod.\nCheck this to move them at the same time.#" .. textColor2 .. ":l");
			optionsAddObject( -5,   26, "checkbutton#tl:20:%y#i:showCTBarMod#o:showCTBarMod#Move CT_BarMod bars at the same time");
		end
	optionsEndFrame();

	-- Bar-Specific Options
	optionsBeginFrame(-20, 0, "frame#tl:0:%y#br:tr:0:%b");
		optionsAddObject(  0,   17, "font#tl:5:%y#v:GameFontNormalLarge#Bar-Specific Options");
	optionsEndFrame();

	-- Action bar options
	optionsBeginFrame(-20, 0, "frame#tl:0:%y#br:tr:0:%b#i:actionbar");
		optionsAddObject(  0,   17, "font#tl:5:%y#v:GameFontNormal#Action Bar")		
		optionsAddObject( -5, 2*14, "font#t:0:%y#s:0:%s#l:20:0#r#This is the main action bar.  It is normally visible except when you are in a vehicle.#" .. textColor2 .. ":l");
		if module:getGameVersion() >= 10 then
			optionsBeginFrame( -5,   26, "checkbutton#tl:20:%y#i:disableDragonflightActionBar#o:disableDragonflightActionBar:true#Hide the default action bar")
				optionsAddScript("onshow", function(btn)
					btn:SetChecked(module:getOption("disableDragonflightActionBar") ~= false)
				end)
			optionsEndFrame()
			optionsBeginFrame( 6,   26, "checkbutton#tl:50:%y#i:disableDragonflightActionBarInVehicle#o:disableDragonflightActionBarInVehicle:true#Also hide it when entering a vehicle")
				optionsAddTooltip({"Also hide the default action bar when entering a vehicle#"..textColor3, "Deselect this if you are hiding the override/vehicle frame and don't have another addon to show the buttons.#"..textColor1})
				optionsAddScript("onshow", function(btn1)
					local btn2 = btn1:GetParent().disableDragonflightActionBar
					if not btn2.hookedByBtn1 then
						btn2.hookedByBtn1 = true
						btn2:HookScript("OnClick", function()
							btn1:SetAlpha(btn2:GetChecked() and 1 or 0.5)
						end)
					end
					btn1:SetAlpha(btn2:GetChecked() and 1 or 0.5)
				end)
			optionsEndFrame()
			optionsBeginFrame( 6,   26, "checkbutton#tl:50:%y#i:disableDragonflightActionBarWhileDragonriding#o:disableDragonflightActionBarWhileDragonriding:false#Also hide it during dragonriding")
				optionsAddTooltip({"Also hide the default action bar during dragonriding#"..textColor3, "Select this if you want to drag the buttons from your spellbook to a different bar.#"..textColor1})
				optionsAddScript("onshow", function(btn3)
					local btn2 = btn3:GetParent().disableDragonflightActionBar
					if not btn2.hookedByBtn3 then
						btn2.hookedByBtn3 = true
						btn2:HookScript("OnClick", function()
							btn3:SetAlpha(btn2:GetChecked() and 1 or 0.5)
						end)
					end
					btn3:SetAlpha(btn2:GetChecked() and 1 or 0.5)
				end)
			optionsEndFrame()
		else
			-- Classic
			optionsAddObject( -5, 2*14, "font#t:0:%y#s:0:%s#l:20:0#r#CT_BottomBar does not include support for manipulating the default main action bar.#" .. textColor2 .. ":l");
			optionsAddObject( -5, 2*14, "font#t:0:%y#s:0:%s#l:20:0#r#The main action bar can either be used in its default state or it can be disabled.#" .. textColor2 .. ":l");
			optionsAddObject( -5, 3*14, "font#t:0:%y#s:0:%s#l:20:0#r#If you disable the bar, you may want to use CT_BarMod version 4.004 (or greater) which includes an alternate main action bar.#" .. textColor2 .. ":l");
			optionsAddObject( -2, 3*14, "font#t:0:%y#s:0:%s#l:20:0#r#NOTE: Disabling or enabling the default main action bar will have no effect until addons are reloaded.#" .. textColor3 .. ":l");

			optionsAddObject( -5,   26, "checkbutton#tl:20:%y#i:disableDefaultActionBar#o:disableDefaultActionBar:true#Disable the default main action bar.")
			optionsBeginFrame(  -8,   30, "button#t:0:%y#s:180:%s#n:CT_BottomBar_DisableActionBar_Button#v:GameMenuButtonTemplate#Reload addons")
				optionsAddScript("onclick",
					function(self)
						ConsoleExec("RELOADUI")
					end
				)
			optionsEndFrame()
		end
		
	optionsEndFrame();

	-- Override Frame
	optionsBeginFrame(-20, 0, "frame#tl:0:%y#br:tr:0:%b");
		optionsAddObject(  0,   17, "font#tl:5:%y#v:GameFontNormal#Override/Vehicle Frame");
		optionsAddObject( -5, 4*14, "font#t:0:%y#s:0:%s#l:20:0#r#This is a large frame used for vehicle and override bars. If you hide the frame you will need to use an alternate bar that can show vehicle and override buttons.#" .. textColor2 .. ":l");
		optionsBeginFrame( -5,   26, "checkbutton#tl:20:%y#o:vehicleHideFrame#Hide the override/vehicle frame")
			optionsAddTooltip({"Hide the override/vehicle frame#"..textColor3, "Make sure you have an alternative!  One option is to show the action bar while in vehicles.#"..textColor1})
		optionsEndFrame()
		optionsAddObject(  6,   26, "checkbutton#tl:20:%y#o:vehicleHideEnabledBars:true#Hide the activated CT_BottomBar bars");
	optionsEndFrame();

	-- Pet Battle Frame
	optionsBeginFrame(-20, 0, "frame#tl:0:%y#br:tr:0:%b");
		optionsAddObject(  0,   17, "font#tl:5:%y#v:GameFontNormal#Pet Battle Frame");
		optionsAddObject( -5,   26, "checkbutton#tl:20:%y#o:petbattleHideEnabledBars:true#Hide the activated CT_BottomBar bars.");
	optionsEndFrame();

	-- Bags Bar
	if (module.ctBagsBar) then
		optionsBeginFrame(-20, 0, "frame#tl:0:%y#br:tr:0:%b");
			optionsAddObject(  0,   17, "font#tl:5:%y#v:GameFontNormal#Bags Bar");

			optionsAddObject( -5, 2*14, "font#t:0:%y#s:0:%s#l:20:0#r#These options will have no effect if the Bags Bar is not activated.#" .. textColor3 .. ":l");

			if not BagBarExpandToggle then
				optionsAddObject( -5,   26, "checkbutton#tl:20:%y#o:bagsBarHideBags#Hide all buttons except for the backpack");
			end

			optionsAddFrame( -25,   17, "slider#tl:30:%y#s:250:%s#i:spacing#n:bagsBarSpacing#o:bagsBarSpacing:2#Button Spacing = <value>#0:25:1");
		optionsEndFrame();
	end
	
	-- Micro menu buttons
	if module.ctMenuBar then
		optionsBeginFrame(-25, 0, "frame#tl:0:%y#br:tr:0:%b#i:menu#r")
			optionsAddObject(  0,   17, "font#tl:5:%y#v:GameFontNormal#Menu Buttons")
			optionsAddFrame( -15,   17, "slider#tl:55:%y#s:210:%s#i:microButtonSpacing#o:microButtonSpacing:" .. (module:getGameVersion() >= 10 and 0 or -3) .. "#Menu Button Spacing = <value>#-3:3:1")
		optionsEndFrame()
	end

	-- Classic Experience & Reputation Bars
	if (module.ctExpBar and module.ctRepBar) then
		optionsBeginFrame(-25, 0, "frame#tl:0:%y#br:tr:0:%b#i:exprep#r");
			optionsAddObject(  0,   17, "font#tl:5:%y#v:GameFontNormalLarge#Experience & Reputation Bars");

			optionsAddObject( -5, 2*14, "font#t:0:%y#s:0:%s#l:20:0#r#These options will have no effect if the Experience Bar is not activated.#" .. textColor3 .. ":l");

			optionsAddObject( -5, 4*14, "font#t:0:%y#s:0:%s#l:20:0#r#If you are using the game's default action bars, the game will shift the action bars up or down in response to the showing or hiding of the exp and rep bars.#" .. textColor2 .. ":l");

			optionsAddObject( -5, 2*14, "font#t:0:%y#s:0:%s#l:20:0#r#The default width of the experience and reputation frames is 1024.#" .. textColor2 .. ":l");

			optionsAddFrame( -25,   17, "slider#tl:55:%y#s:210:%s#i:repBarWidth#o:repBarWidth:1024#Rep Frame width = <value>#1:2048:1");
			do
				local function updateRepSize(size)
					local minSize, maxSize = exprepOptionsFrame.repBarWidth:GetMinMaxValues();
					if (size < minSize) then
						size = minSize;
					end
					if (size > maxSize) then
						size = maxSize;
					end
					exprepOptionsFrame.repBarWidth:SetValue(size);
				end

				optionsBeginFrame(  17,  24, "button#tl:22:%y#s:24:%s");
					optionsAddScript("onclick",
						function(self, button)
							local size = module:getOption("repBarWidth") or 1024;
							if (button == "RightButton") then
								size = size - 5;
							else
								size = size - 1;
							end
							updateRepSize(size);
						end
					);
					optionsAddScript("onload",
						function(self)
							exprepOptionsFrame = self.parent;
							self:RegisterForClicks("LeftButtonUp", "RightButtonUp");
							self:SetNormalTexture("Interface\\Buttons\\UI-SpellbookIcon-PrevPage-Up");
							self:SetPushedTexture("Interface\\Buttons\\UI-SpellbookIcon-PrevPage-Down");
							self:SetDisabledTexture("Interface\\Buttons\\UI-SpellbookIcon-PrevPage-Disabled");
							self:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight");
						end
					);
				optionsEndFrame();
				optionsBeginFrame(  25,  24, "button#tl:275:%y#s:24:%s");
					optionsAddScript("onclick",
						function(self)
							local size = module:getOption("repBarWidth") or 1024;
							if (button == "RightButton") then
								size = size + 5;
							else
								size = size + 1;
							end
							updateRepSize(size);
						end
					);
					optionsAddScript("onload",
						function(self)
							self:RegisterForClicks("LeftButtonUp", "RightButtonUp");
							self:SetNormalTexture("Interface\\Buttons\\UI-SpellbookIcon-NextPage-Up");
							self:SetPushedTexture("Interface\\Buttons\\UI-SpellbookIcon-NextPage-Down");
							self:SetDisabledTexture("Interface\\Buttons\\UI-SpellbookIcon-NextPage-Disabled");
							self:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight");
						end
					);
				optionsEndFrame();
			end

			optionsAddFrame( -20,   17, "slider#tl:55:%y#s:210:%s#i:expBarWidth#o:expBarWidth:1024#Exp Frame width = <value>#1:2048:1");
			do
				local function updateExpSize(size)
					local minSize, maxSize = exprepOptionsFrame.expBarWidth:GetMinMaxValues();
					if (size < minSize) then
						size = minSize;
					end
					if (size > maxSize) then
						size = maxSize;
					end
					exprepOptionsFrame.expBarWidth:SetValue(size);
				end

				optionsBeginFrame(  17,  24, "button#tl:22:%y#s:24:%s");
					optionsAddScript("onclick",
						function(self, button)
							local size = module:getOption("expBarWidth") or 1024;
							if (button == "RightButton") then
								size = size - 5;
							else
								size = size - 1;
							end
							updateExpSize(size);
						end
					);
					optionsAddScript("onload",
						function(self)
							exprepOptionsFrame = self.parent;
							self:RegisterForClicks("LeftButtonUp", "RightButtonUp");
							self:SetNormalTexture("Interface\\Buttons\\UI-SpellbookIcon-PrevPage-Up");
							self:SetPushedTexture("Interface\\Buttons\\UI-SpellbookIcon-PrevPage-Down");
							self:SetDisabledTexture("Interface\\Buttons\\UI-SpellbookIcon-PrevPage-Disabled");
							self:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight");
						end
					);
				optionsEndFrame();
				optionsBeginFrame(  25,  24, "button#tl:275:%y#s:24:%s");
					optionsAddScript("onclick",
						function(self, button)
							local size = module:getOption("expBarWidth") or 1024;
							if (button == "RightButton") then
								size = size + 5;
							else
								size = size + 1;
							end
							updateExpSize(size);
						end
					);
					optionsAddScript("onload",
						function(self)
							self:RegisterForClicks("LeftButtonUp", "RightButtonUp");
							self:SetNormalTexture("Interface\\Buttons\\UI-SpellbookIcon-NextPage-Up");
							self:SetPushedTexture("Interface\\Buttons\\UI-SpellbookIcon-NextPage-Down");
							self:SetDisabledTexture("Interface\\Buttons\\UI-SpellbookIcon-NextPage-Disabled");
							self:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight");
						end
					);
				optionsEndFrame();
			end

			optionsAddObject(-15,   26, "checkbutton#tl:20:%y#o:repBarHideBorder#Hide reputation border.");
			optionsAddObject(  6,   26, "checkbutton#tl:20:%y#o:repBarHideDivisions#Hide reputation divisions.");
			optionsAddFrame( -15,   17, "slider#tl:55:%y#s:210:%s#i:repBarNumDivisions#o:repBarNumDivisions:20#Reputation divisions = <value>#1:20:1");

			optionsAddObject(-15,   26, "checkbutton#tl:20:%y#o:expBarHideBorder#Hide experience border.");
			optionsAddObject(  6,   26, "checkbutton#tl:20:%y#o:expBarHideDivisions#Hide experience divisions.");
			optionsAddFrame( -15,   17, "slider#tl:55:%y#s:210:%s#i:expBarNumDivisions#o:expBarNumDivisions:20#Experience divisions = <value>#1:20:1");

			optionsAddObject(-25,   26, "checkbutton#tl:20:%y#o:exprepAltBorder#Use reputation border in experience frame.");
			optionsAddObject(  6,   26, "checkbutton#tl:20:%y#o:exprepAltDivisions#Display the borders on top of the divisions.");
			optionsAddObject(  6,   26, "checkbutton#tl:20:%y#o:expBarHideAtMaxLevel#Hide exp bar if max level");

			optionsAddObject(-10, 5*14, "font#t:0:%y#s:0:%s#l:20:0#r#Enabling all three of the following options emulates the game's behavior for a maximum level character (but works at any level) as long as the exp bar and rep bar are not deliberately hidden.#" .. textColor2 .. ":l");
			optionsAddObject(  3,   26, "checkbutton#tl:20:%y#o:repBarHideNoRep#Hide reputation when not monitoring one.");
			optionsAddObject(  6,   26, "checkbutton#tl:20:%y#o:repBarCoverExpBar#Show rep bar in the exp frame.");
			optionsAddObject(  6,   26, "checkbutton#tl:20:%y#o:expBarShowMaxLevelBar#Show solid exp bar if no rep and exp bars.");

		optionsEndFrame();
	end

	-- Retail consolidated Status Bar showing experience, reputation and different types of power (Legion artifact, Draenor azerite, etc.)
	if (module.ctStatusBar) then
		optionsBeginFrame(-25, 0, "frame#tl:0:%y#br:tr:0:%b#i:status#r");
			optionsAddObject(  0,   17, "font#tl:5:%y#v:GameFontNormal#Exp/Rep/Power Status Bars");

			optionsAddObject( -5, 2*14, "font#t:0:%y#s:0:%s#l:20:0#r#These options will have no effect if the Status Bar is not activated.#" .. textColor3 .. ":l");

			optionsAddObject( -5, 4*14, "font#t:0:%y#s:0:%s#l:20:0#r#If you are using the game's default status bars, the game will shift the action bars up or down in response to the showing or hiding of the exp and rep bars.#" .. textColor2 .. ":l");

			optionsAddObject( -5, 2*14, "font#t:0:%y#s:0:%s#l:20:0#r#The default width of the experience and reputation frames is 571.#" .. textColor2 .. ":l");
	
			optionsAddFrame( -25,   17, "slider#tl:55:%y#s:210:%s#i:customStatusBarWidth#o:customStatusBarWidth:768#Status Frame width = <value>#1:1024:1");
			optionsAddObject(  0,   35, "font#tl:20:-206:%y#v:GameFontNormal#Hide bars");
			optionsAddObject( -5, 3*14, "font#t:0:%y#s:0:%s#l:20:0#r#The game shows the two highest-priority bars.  Use these options to hide them always.#" .. textColor2 .. ":l");
			optionsAddObject( -5,   26, "checkbutton#tl:20:%y#o:customStatusBarHideExp#Never display experience bar");
			optionsAddObject(  0,   26, "checkbutton#tl:20:%y#o:customStatusBarHideReputation#Never display reputation bar");
			optionsAddObject(  0,   26, "checkbutton#tl:20:%y#o:customStatusBarHideHonor#Never display honor bar");
			optionsAddObject(  0,   26, "checkbutton#tl:20:%y#o:customStatusBarHideArtifact#Never display Legion artifact bar");
			optionsAddObject(  0,   26, "checkbutton#tl:20:%y#o:customStatusBarHideAzerite#Never display BFA Azerite bar");

		optionsEndFrame();
	end
	
	-- Extra Bar
	if (module.ctExtraBar) then
		optionsBeginFrame(-20, 0, "frame#tl:0:%y#br:tr:0:%b");
			optionsAddObject(  0,   17, "font#tl:5:%y#v:GameFontNormal#Extra Bar");

			optionsAddObject( -5, 2*14, "font#t:0:%y#s:0:%s#l:20:0#r#The following options will have no effect if the Extra Bar is not activated.#" .. textColor3 .. ":l");
			optionsAddObject( -5, 3*14, "font#t:0:%y#s:0:%s#l:20:0#r#The Extra Bar consists of a single button which the game will show when needed (usually during certain boss fights).#" .. textColor2 .. ":l");

			optionsAddObject( -5,   26, "checkbutton#tl:20:%y#o:extraBarTexture#Hide bar textures.");

			optionsAddFrame( -25,   17, "slider#tl:30:%y#s:250:%s#i:scale#n:extraBarScale#o:extraBarScale:1#Scale = <value>#0.25:2:0.01");
		optionsEndFrame();
	end

	-- Pet Bar
	if (module.ctPetBar) then
		optionsBeginFrame(-30, 0, "frame#tl:0:%y#br:tr:0:%b");
			optionsAddObject(  0,   17, "font#tl:5:%y#v:GameFontNormal#Pet Bar");

			optionsAddObject( -5, 2*14, "font#t:0:%y#s:0:%s#l:20:0#r#These options will have no effect if the Pet Bar is not activated.#" .. textColor3 .. ":l");

			optionsAddFrame( -25,   17, "slider#tl:30:%y#s:250:%s#i:scale#n:petBarScale#o:petBarScale:1#Scale = <value>#0.25:2:0.01");
			optionsAddFrame( -25,   17, "slider#tl:30:%y#s:250:%s#i:opacity#n:petBarOpacity#o:petBarOpacity:1#Opacity = <value>#0:1:0.01");
			optionsAddFrame( -25,   17, "slider#tl:30:%y#s:250:%s#i:spacing#n:petBarSpacing#o:petBarSpacing:6#Button Spacing = <value>#0:25:1");
		optionsEndFrame();
	end

	-- Vehicle Tools Bar
	if (module.ctVehicleBar) then
		optionsBeginFrame(-30, 0, "frame#tl:0:%y#br:tr:0:%b");
			optionsAddObject(  0,   17, "font#tl:5:%y#v:GameFontNormal#Vehicle Tools Bar");

			optionsAddObject( -5, 2*14, "font#t:0:%y#s:0:%s#l:20:0#r#These options will have no effect if the Vehicle Tools Bar is not activated.#" .. textColor3 .. ":l");
			optionsAddObject( -2, 3*14, "font#t:0:%y#s:0:%s#l:20:0#r#If you are in a vehicle with no abilities then a leave vehicle button will be shown on this bar only if the vehicle can be exited.#" .. textColor2 .. ":l");
			optionsAddObject( -2, 3*14, "font#t:0:%y#s:0:%s#l:20:0#r#If you are in a vehicle with abilities then buttons on this bar will only be visible if you are hiding the standard vehicle frame.#" .. textColor2 .. ":l");
			optionsAddObject( -2, 2*14, "font#t:0:%y#s:0:%s#l:20:0#r#The first spot on this bar will be used for a 'leave vehicle' button when applicable.#" .. textColor2 .. ":l");
			optionsAddObject( -5,   26, "checkbutton#tl:20:%y#o:vehicleBarAimButtons:true#Include room for the two aiming buttons.");
		optionsEndFrame();
	end

	-- Reset Options
	optionsBeginFrame(-20, 0, "frame#tl:0:%y#br:tr:0:%b");
		optionsAddObject(  0,    1, "texture#tl:5:%y#br:tr:0:%b#1:1:1");

		optionsAddObject(-15,   17, "font#tl:5:%y#v:GameFontNormalLarge#Reset CT_BottomBar Options");
		optionsAddObject( -5,   26, "checkbutton#tl:20:%y#o:resetAll#Reset options for all of your characters");
		optionsBeginFrame( -10,   30, "button#t:0:%y#s:120:%s#v:UIPanelButtonTemplate#Reset options");
			optionsAddScript("onclick",
				function(self)
					if (module:getOption("resetAll")) then
						CT_BottomBarOptions = {};
					else
						if (not CT_BottomBarOptions or not type(CT_BottomBarOptions) == "table") then
							CT_BottomBarOptions = {};
						else
							CT_BottomBarOptions[module:getCharKey()] = nil;
						end
					end
					ConsoleExec("RELOADUI");
				end
			);
		optionsEndFrame();
		optionsAddObject( -2, 4*14, "font#t:0:%y#s:0:%s#l#r#Note: This will reset options and bar positions to default and then reload your UI.#" .. textColor2);
	optionsEndFrame();

	optionsAddScript("onshow",
		function(self)
			showModules(self);
		end
	);

	optionsAddScript("onhide",
		function(self)
			hideModules(self);
		end
	);

	optionsAddScript("onload",
		function(self)
			theOptionsFrame = self;
		end
	);

	return "frame#all", optionsGetData();
end

------------------------------------------------
-- Initialize

function module:optionsInitApplied()
	-- Initialize the applied options table.

	local value, new, old;

	-- We will refer to the applied options table rather than using module:getOption()
	-- during the rest of the addon when we need an option that we know has been
	-- successfully applied.

	appliedOptions.showCTBarMod = not not module:getOption("showCTBarMod");
	-- REMOVED IN 8.0.1.5 -- appliedOptions.dragHideTooltip = not not module:getOption("dragHideTooltip");
	appliedOptions.clampFrames = module:getOption("clampFrames") ~= false;

	appliedOptions.hideGryphons = module:getOption("hideGryphons") ~= false;
	appliedOptions.showLions = not not module:getOption("showLions");
	appliedOptions.hideTexturesBackground = module:getOption("hideTexturesBackground") ~= false;
	appliedOptions.hideMenuAndBagsBackground = module:getOption("hideMenuAndBagsBackground") ~= false;

	for key, obj in ipairs(module.addons) do
		local settings = obj.settings;
		local defaultOrientation = (settings.orientation or "ACROSS");

		local value = module:getOption(obj.optionName);
		if (value == nil) then
			value = obj:isDefaultHidden();
		end
		appliedOptions[obj.optionName] = not not value;

		appliedOptions["orientation" .. obj.optionName] = module:getOption("orientation" .. obj.optionName) or defaultOrientation;
		obj.orientation = appliedOptions["orientation" .. obj.optionName];

		appliedOptions["enable" .. obj.optionName] = module:getOption("enable" .. obj.optionName) ~= false;
		obj.isDisabled = not appliedOptions["enable" .. obj.optionName];
	end

	appliedOptions.disableDefaultActionBar = module:getOption("disableDefaultActionBar") ~= false
	if CT_BarMod then
		appliedOptions.disableDragonflightActionBar = module:getOption("disableDragonflightActionBar") ~= false
	else
		appliedOptions.disableDragonflightActionBar = module:getOption("disableDragonflightActionBar")
	end
	appliedOptions.disableDragonflightActionBarInVehicle = module:getOption("disableDragonflightActionBarInVehicle") ~= false

	appliedOptions.bagsBarHideBags = not not module:getOption("bagsBarHideBags");
	appliedOptions.bagsBarSpacing = module:getOption("bagsBarSpacing");	-- if nil, the addon knows what to do for each version of the game

	if (module.ctExpBar and module.ctRepBar) then
		-- Make sure the enable Rep and Exp bar appliedOptions, and the .isDisabled property are synchronized.
		-- The user will be changing the enable exp bar option, which will in turn change the enable rep bar option.
		appliedOptions["enable" .. "Reputation Bar"] = appliedOptions["enable" .. "Experience Bar"];
		module.ctRepBar.isDisabled = module.ctExpBar.isDisabled;
	end
	
	appliedOptions.microButtonSpacing = module:getOption("microButtonSpacing") or module:getGameVersion() >= 10 and 0 or -3

	appliedOptions.customStatusBarWidth = min(1024, module:getOption("customStatusBarWidth") or 768) -- before CT_BarMod 10.0.0.4, values up to 2048 were permitted.
	appliedOptions.repBarHideNoRep = not not module:getOption("repBarHideNoRep");
	appliedOptions.repBarCoverExpBar = not not module:getOption("repBarCoverExpBar");
	appliedOptions.expBarShowMaxLevelBar = not not module:getOption("expBarShowMaxLevelBar");
	appliedOptions.expBarHideDivisions = not not module:getOption("expBarHideDivisions");
	appliedOptions.expBarHideBorder = not not module:getOption("expBarHideBorder");
	appliedOptions.repBarHideDivisions = not not module:getOption("repBarHideDivisions");
	appliedOptions.repBarHideBorder = not not module:getOption("repBarHideBorder");
	appliedOptions.expBarWidth = module:getOption("expBarWidth") or EXP_DEFAULT_WIDTH or 1024;
	appliedOptions.repBarWidth = module:getOption("repBarWidth") or EXP_DEFAULT_WIDTH or 1024;
	appliedOptions.exprepAltBorder = module:getOption("exprepAltBorder");
	appliedOptions.exprepAltDivisions = module:getOption("exprepAltDivisions");
	appliedOptions.expBarNumDivisions = module:getOption("expBarNumDivisions") or 20;
	appliedOptions.repBarNumDivisions = module:getOption("repBarNumDivisions") or 20;
	appliedOptions.expBarHideAtMaxLevel = module:getOption("expBarHideAtMaxLevel");

	appliedOptions.petBarScale = module:getOption("petBarScale") or 1;
	appliedOptions.petBarOpacity = module:getOption("petBarOpacity") or 1;
	appliedOptions.petBarSpacing = module:getOption("petBarSpacing") or 6;

	appliedOptions.extraBarTexture = not not module:getOption("extraBarTexture");
	appliedOptions.extraBarScale = module:getOption("extraBarScale") or 1;

	appliedOptions.vehicleBarAimButtons = module:getOption("vehicleBarAimButtons") ~= false;

	appliedOptions.vehicleHideFrame = not not module:getOption("vehicleHideFrame");
	appliedOptions.overrideHideFrame = appliedOptions.vehicleHideFrame;  -- using same value as the vehicle option
	appliedOptions.petbattleHideFrame = nil;  -- no support for hiding pet battle UI

	-- Hide enabled bars when in a vehicle.
	appliedOptions.vehicleHideEnabledBars = module:getOption("vehicleHideEnabledBars") ~= false;
	appliedOptions.overrideHideEnabledBars = appliedOptions.vehicleHideEnabledBars; -- using same value as vehicle option
	appliedOptions.petbattleHideEnabledBars = module:getOption("petbattleHideEnabledBars") ~= false;
end

function module:optionsInit()
	-- Initialize this lua file.
	appliedOptions = module.appliedOptions;
	pendingOptions = module.pendingOptions;
end

--------------------------------------------
-- Old options

-- CT_BottomBar 4.0200
-- - The key ring was removed from the game.
-- 	["MOVABLE-Key Ring"]
-- 	["enableKey Ring"]
-- 	["Key Ring"]
