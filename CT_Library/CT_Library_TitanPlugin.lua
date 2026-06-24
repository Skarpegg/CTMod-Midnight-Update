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
------------------------------------------------

-- This file gives users the option to open the CTMod options directly from the TitanPanel bar if it exists

-- ******************************** Constants *******************************
-- Setup the name we want in the global namespace
CTModTitanPlugin = {}
-- Reduce the chance of functions and variables colliding with another addon.
local TS = CTModTitanPlugin
local CT = select(2, ...);

TS.id = "CTMod";
TS.addon = "TitanCTMod";

TS.button_label = TS.id
TS.menu_text = TS.id
TS.tooltip_header = TS.id.." Options"

--  Get data from the TOC file.
TS.version = tostring(C_AddOns.GetAddOnMetadata("CT_Library", "Version")) or "Unknown" 
TS.author = C_AddOns.GetAddOnMetadata("CT_Library", "Author") or "Unknown"
-- ******************************** Variables *******************************
-- ******************************** Functions *******************************


--[[
-- **************************************************************************
-- NAME : TitanStarter_GetButtonText(id)
-- DESC : Calculate bag space logic then display data on button
-- VARS : id = button ID
-- **************************************************************************
--]]
function TitanCTMod_GetButtonText(id)
-- SDK : As specified in "registry"
--       Any button text to set or update goes here
	local button, id = TitanUtils_GetButton(id, true);
	-- SDK : "TitanUtils_GetButton" is used to get a reference to the button Titan created.
	--       The reference is not needed by this example.

	return TS.button_label;
end
--[[
-- **************************************************************************
-- NAME : TitanStarter_GetTooltipText()
-- DESC : Display tooltip text
-- **************************************************************************
--]]
function TitanCTMod_GetTooltipText()
-- SDK : As specified in "registry"
--       Create the tooltip text here
	return "Open the CTMod addon options";
end
--[[
-- **************************************************************************
-- NAME : TitanPanelRightClickMenu_PrepareCTModMenu()
-- DESC : Display rightclick menu options
-- **************************************************************************
--]]
function TitanPanelRightClickMenu_PrepareCTModMenu()
-- SDK : This is a routine that Titan 'assumes' will exist. The name is a specific format
--       "TitanPanelRightClickMenu_Prepare"..ID.."Menu"
--       where ID is the "id" from "registry"
	local info, info1, info2;
--[[ NOTE :
Titan does not use the Blizzard UI drop down menu because it can cause taint issues. 
Instead it uses a custom library provided by arith. It uses the Blizzard routines but
in a taint safe way. The library uses the same names prefixed by "L_" and a drop down creation routine.
The Titan main code will create the drop down menu but the plugin must fill in any buttons it
wants to display. The buttons will be in the same order as they are added (L_UIDropDownMenu_AddButton).
For 'tiered' menus, two things must occur:
1) The button to 'pop' the next level must be created with attribute "hasArrow" as 1 / true and given an appropriate (localized) text label
2)The level of the menu must be checked (L_UIDROPDOWNMENU_MENU_LEVEL). Within the check ensure the cursor is over the 
button (if L_UIDROPDOWNMENU_MENU_VALUE == "Options", where "Options" is the developer assigned .value)
Then add additional buttons as desired.
For this example plugin, we show the standard Titan buttons plus options to determine what numbers to display.
--]]
-- menu creation is beyond the scope of this example
-- but note the Titan get / set routines and other Titan routines being used.
-- SDK : "TitanPanelRightClickMenu_AddTitle" is used to place the title in the (sub)menu

	local DDM = LibStub:GetLibrary("LibUIDropDownMenu-4.0", true)
	
	-- compatibility with older versions of TitanPanel using LibUIDropDownMenu-2.0
	DDM = DDM or {
		UIDropDownMenu_AddSeparator = function(self, ...) L_UIDropDownMenu_AddSeparator(...) end,
		UIDropDownMenu_AddButton = function(self, ...) L_UIDropDownMenu_AddButton(...) end,
	}

	-- level 1 menu
	if L_UIDROPDOWNMENU_MENU_LEVEL == 1 then
		TitanPanelRightClickMenu_AddTitle(TitanPlugins[TS.id].menuText);
		for i, module in CT:iterateModules() do
			info = {};
			info.text = module.name;


			info.notCheckable = 1;
			if (module.externalDropDown_Initialize) then
				-- shows a custom dropdown provided by the module
				info.hasArrow = 1;
				info.value = module.name;
			else
				-- opens the customOpenFunction() if it exists, or just opens the standard module options
				info.func = function(...)
					if (module.customOpenFunction) then
						module:customOpenFunction(...);
					else
						module:showModuleOptions();
					end
				end;
			end		
			if (i > 2) then
				DDM:UIDropDownMenu_AddButton(info);
			elseif (i == 1) then
				info1 = info;
			else
				info2 = info;
			end
		end
		DDM:UIDropDownMenu_AddSeparator(1);
		DDM:UIDropDownMenu_AddButton(info1);
		DDM:UIDropDownMenu_AddButton(info2);
		
		-- SDK : "TitanPanelRightClickMenu_AddSpacer" is used to put a blank line in the menu
		TitanPanelRightClickMenu_AddSpacer();     
		TitanPanelRightClickMenu_AddCommand("Hide", TS.id, TITAN_PANEL_MENU_FUNC_HIDE);
		-- SDK : The routine above is used to put a "Hide" (localized) in the menu.
	
	elseif (_G[L_UIDROPDOWNMENU_MENU_VALUE] and _G[L_UIDROPDOWNMENU_MENU_VALUE].externalDropDown_Initialize) then
		_G[L_UIDROPDOWNMENU_MENU_VALUE]:externalDropDown_Initialize(L_UIDROPDOWNMENU_MENU_LEVEL, function(...) DDM:UIDropDownMenu_AddButton(...); end)
	end

end

local listener = CreateFrame("Frame", nil, UIParent)
local alreadyDoneListening = nil;
listener:RegisterEvent("ADDON_LOADED");
listener:SetScript("OnEvent",
	function(addon)
		if (TitanPanelTooltip and not alreadyDoneListening) then
			local f = CreateFrame("Button", "TitanPanelCTModButton", listener, "TitanPanelComboTemplate");
			f:SetFrameStrata("FULLSCREEN");
			f.registry = {
				id = TS.id,
				-- SDK : "id" MUST be unique to all the Titan specific addons
				-- Last addon loaded with same name wins...
				version = TS.version,
				-- SDK : "version" the version of your addon that Titan displays
				category = "Interface",
				-- SDK : "category" is where the user will find your addon when right clicking
				--       on the Titan bar.
				--       Currently: General, Combat, Information, Interfacem, Profession - These may change!
				menuText = TS.menu_text,
				-- SDK : "menuText" is the text Titan displays when the user finds your addon by right clicking
				--       on the Titan bar.
				buttonTextFunction = "TitanCTMod_GetButtonText", 
				-- SDK : "buttonTextFunction" is in the global name space due to the way Titan uses the routine.
				--       This routine is called to set (or update) the button text on the Titan bar.
				tooltipTitle = TS.tooltip_header,
				-- SDK : "tooltipTitle" will be used as the first line in the tooltip.
				tooltipTextFunction = "TitanCTMod_GetTooltipText", 
				-- SDK : "tooltipTextFunction" is in the global name space due to the way Titan uses the routine.
				--       This routine is called to fill in the tooltip of the button on the Titan bar.
				--       It is a typical tooltip and is drawn when the cursor is over the button.
				savedVariables = {
				-- SDK : "savedVariables" are variables saved by character across logins.
				--      Get - TitanGetVar (id, name)
				--      Set - TitanSetVar (id, name, value)
					-- SDK : The 2 variables below are for our example
					--ShowStarterNum = 1,
					--ShowUsedSlots = false,
					-- SDK : Titan will handle the 3 variables below but the addon code must put it on the menu
					ShowIcon = 1,
					ShowLabelText = 1,
					ShowColoredText = 1,               
				},
				icon = "Interface\\Addons\\CT_Library\\Images\\minimapIcon",
				iconWidth = 16,
			};
			alreadyDoneListening = true;
			f:HookScript("OnClick",
				function(self, button)
					if (button == "LeftButton") then
						local CT = _G["CT_Library"];
						if (CT) then
							CT:showControlPanel(true);
						end
					end
				end
			);
					
		end
	end);
