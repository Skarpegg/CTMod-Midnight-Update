------------------------------------------------
--               CT_UnitFrames                --
--                                            --
-- Heavily customizable mod that allows you   --
-- to modify the Blizzard unit frames into    --
-- your personal style and liking.            --
-- Please do not modify or otherwise          --
-- redistribute this without the consent of   --
-- the CTMod Team. Thank you.                 --
------------------------------------------------

local module = select(2, ...);

--------------------------------------------
-- API

local GetCVar = GetCVar or C_CVar.GetCVar;

--------------------------------------------
-- General Mod Code (rewrite imminent!)

tinsert(UISpecialFrames, "CT_UnitFramesOptionsFrame"); -- So we can close it with escape
CT_UnitFramesOptions = {
	["styles"] = {
		[1] = { -- Box (Player)
			{2, 1, 1, 1, 1}, -- On health bar
			{1, 1, 1, 1, 1}, -- Right of health bar
			{1, 1, 1, 1, 1}, -- On mana bar
			{1, 1, 1, 1, 1}, -- Right of mana bar
		},
		[2] = { -- Box (Party)
			{1, 1, 1, 1, 1}, -- On health bar
			{1, 1, 1, 1, 1}, -- Right of health bar
			{1, 1, 1, 1, 1}, -- On mana bar
			{1, 1, 1, 1, 1}, -- Right of mana bar
		},
		[3] = { -- Box (Target)
			{2, 1, 1, 1, 1}, -- On health bar
			{1, 1, 1, 1, 1}, -- Left of health bar
			{1, 1, 1, 1, 1}, -- On mana bar
			{1, 1, 1, 1, 1}, -- Left of mana bar
			{2, 1, 1, 1, 1}, -- Enemy health bar
		},
		[4] = { -- Box (Target of Target)
			{2, 1, 1, 1, 1}, -- On health bar
			{1, 1, 1, 1, 1}, -- Left of health bar
			{1, 1, 1, 1, 1}, -- On mana bar
			{1, 1, 1, 1, 1}, -- Left of mana bar
			{2, 1, 1, 1, 1}, -- Enemy health bar
		},
		[5] = { -- Box (Focus)
			{2, 1, 1, 1, 1}, -- On health bar
			{1, 1, 1, 1, 1}, -- Left of health bar
			{1, 1, 1, 1, 1}, -- On mana bar
			{1, 1, 1, 1, 1}, -- Left of mana bar
			{2, 1, 1, 1, 1}, -- Enemy health bar
		},
		[6] = { -- Box (Pet)
			{1, 1, 1, 1, 1}, -- On health bar
			{1, 1, 1, 1, 1}, -- Right of health bar
			{1, 1, 1, 1, 1}, -- On mana bar
			{1, 1, 1, 1, 1}, -- Right of mana bar		
		},
	},
};
CT_UnitFramesOptions_NumSelections = {
	4, 4, 5, 5, 5, 4
};

-- OnLoad handlers
function CT_UnitFrameOptions_OnLoad(self)
	Mixin(self, BackdropTemplateMixin or {});
	self:SetBackdrop({
		bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		tile = true,
		tileSize = 16,
		edgeSize = 16,
		insets = { left = 5, right = 5, top = 5, bottom = 5 },
	});
	self:SetBackdropColor(0, 0, 0, 0.8);
	self:RegisterEvent("PLAYER_LOGIN");
	--self:RegisterEvent("VARIABLES_LOADED");
	self:RegisterEvent("PLAYER_REGEN_ENABLED");
	self:RegisterEvent("PLAYER_REGEN_DISABLED");
end

function CT_UnitFramesOptions_Radio_OnLoad(self)
	_G[self:GetName() .. "Name"]:SetText(CT_UFO_RADIO[self:GetID()]);
end

function CT_UnitFramesOptions_Selection_OnLoad(self)
	local box = self:GetParent():GetID();
	local id = self:GetID();

	if ( CT_UnitFramesOptions_NumSelections[box] == 2 ) then
		_G[self:GetName() .. "Name"]:SetText(CT_UFO_SELECTION[id + (1-mod(id, 2))]);
	else
		if (box == 3 or box == 4 or box == 5) then
			-- Target, Assist, Focus
			_G[self:GetName() .. "Name"]:SetText(CT_UFO_SELECTION2[id]);
		else
			_G[self:GetName() .. "Name"]:SetText(CT_UFO_SELECTION[id]);
		end
	end
end

function CT_UnitFramesOptions_Box_OnLoad(self)
	_G[self:GetName() .. "Name"]:SetText(CT_UFO_BOX[self:GetID()]);
	if ( self:GetID() == 1 ) then
		_G[self:GetName() .. "PlayerTextLeftCBName"]:SetText(CT_UFO_TEXTLEFT);
		_G[self:GetName() .. "PlayerCoordsRightCBName"]:SetText(CT_UFO_SHOWCOORDS);
	elseif ( self:GetID() == 2) then
		_G[self:GetName() .. "PartyClassColorCBName"]:SetText(CT_UFO_PARTYCLASSCOLORS);
	elseif ( self:GetID() == 3 ) then
		_G[self:GetName() .. "ClassFrameCBName"]:SetText(CT_UFO_TARGETCLASS);
		_G[self:GetName() .. "TargetTextRightCBName"]:SetText(CT_UFO_TEXTRIGHT);
		_G[self:GetName() .. "ShowToTCBName"]:SetText(CT_UFO_TARGETOFTARGET);
	elseif ( self:GetID() == 4 ) then
		_G[self:GetName() .. "TargetofAssistCBName"]:SetText(CT_UFO_TARGETOFASSIST);
		_G[self:GetName() .. "AssistCastbarCBName"]:SetText(CT_UFO_ASSISTCASTBAR);
		_G[self:GetName() .. "AssistTextRightCBName"]:SetText(CT_UFO_TEXTRIGHT);
	elseif ( self:GetID() == 5 ) then
		_G[self:GetName() .. "TargetofFocusCBName"]:SetText(CT_UFO_TARGETOFFOCUS);
		_G[self:GetName() .. "FocusCastbarCBName"]:SetText(CT_UFO_FOCUSCASTBAR);
		_G[self:GetName() .. "FocusTextRightCBName"]:SetText(CT_UFO_TEXTRIGHT);
	end
end

-- OnEvent
function CT_UnitFrameOptions_OnEvent(self, event, ...)
	if (event == "PLAYER_REGEN_DISABLED") then
		CT_UnitFramesOptionsFrameBox4DisplayCB:Disable();
		CT_UnitFramesOptionsFrameBox4TargetofAssistCB:Disable();
		CT_UnitFramesOptionsFrameBox5DisplayCB:Disable();
		CT_UnitFramesOptionsFrameBox5TargetofFocusCB:Disable();
		CT_UnitFramesOptionsFrameBox4LockCB:Disable();
		CT_UnitFramesOptionsFrameBox5LockCB:Disable();
	elseif (event == "PLAYER_REGEN_ENABLED") then
		CT_UnitFramesOptionsFrameBox4DisplayCB:Enable();
		CT_UnitFramesOptionsFrameBox4TargetofAssistCB:Enable();
		CT_UnitFramesOptionsFrameBox5DisplayCB:Enable();
		CT_UnitFramesOptionsFrameBox5TargetofFocusCB:Enable();
		CT_UnitFramesOptionsFrameBox4LockCB:Enable();
		CT_UnitFramesOptionsFrameBox5LockCB:Enable();
	elseif (event == "PLAYER_LOGIN") then
		local fixLeft, fixEnemy;

		-- added in 8.0.1.5.
		CT_UnitFramesOptions.playerCoordsRight = not not CT_UnitFramesOptions.playerCoordsRight;

		-- Assign default values if any rows are missing, and upgrade current users if needed.
		if (not CT_UnitFramesOptions["styles"]) then
			CT_UnitFramesOptions["styles"] = {};
		end
		for box = 1, #CT_UnitFramesOptions_NumSelections do
			if (not CT_UnitFramesOptions["styles"][box]) then
				CT_UnitFramesOptions["styles"][box] = {};
			end

			for i = 1, CT_UnitFramesOptions_NumSelections[box] do
				if (not CT_UnitFramesOptions["styles"][box][i]) then
					CT_UnitFramesOptions["styles"][box][i] = {1, 1, 1, 1, 1};
				end
			end
		end
		
		-- Temporary code to convert information that was in a beta version (9.0.5.6a) but has never been in an actual release version
		if(CT_UnitFramesOptions.styles[1][6]) then
			CT_UnitFramesOptions.styles[6][1] = CT_UnitFramesOptions.styles[1][5];
			CT_UnitFramesOptions.styles[6][3] = CT_UnitFramesOptions.styles[1][6];
			CT_UnitFramesOptions.styles[1][6] = nil;
			CT_UnitFramesOptions.styles[1][5] = nil;
		end
		
		CT_UnitFramesOptions_Radio_Update();
	end
end

-- OnClick handlers
function CT_UnitFramesOptions_Radio_OnClick(self)
	local radioId, selectionId, boxId = self:GetID(), self:GetParent():GetID(), self:GetParent():GetParent():GetID();
	CT_UnitFramesOptions.styles[boxId][selectionId][1] = radioId;
	CT_UnitFramesOptions_Radio_Update();
end

-- Function to update the frame
function CT_UnitFramesOptions_Radio_Update()
	for box = 1, #CT_UnitFramesOptions_NumSelections do
		for selection = 1, CT_UnitFramesOptions_NumSelections[box], 1 do
			for radio = 1, 5, 1 do
				_G["CT_UnitFramesOptionsFrameBox" .. box .. "Selection" .. selection .. "Radio" .. radio]:Enable();
				_G["CT_UnitFramesOptionsFrameBox" .. box .. "Selection" .. selection .. "Radio" .. radio .. "Name"]:SetTextColor(0.7, 0.7, 0.7, 1.0);
				_G["CT_UnitFramesOptionsFrameBox" .. box .. "Selection" .. selection .. "Radio" .. radio]:SetChecked(false);
				local color = CT_UnitFramesOptions.styles[box][selection];
				_G["CT_UnitFramesOptionsFrameBox" .. box .. "Selection" .. selection .. "ColorSwatchNormalTexture"]:SetVertexColor(color[2], color[3], color[4]);
			end
		end
	end

	for boxId, box in pairs(CT_UnitFramesOptions.styles) do
		for selectionId, selection in pairs(box) do
			_G["CT_UnitFramesOptionsFrameBox" .. boxId .. "Selection" .. selectionId .. "Radio" .. selection[1] ]:SetChecked(true);
			_G["CT_UnitFramesOptionsFrameBox" .. boxId .. "Selection" .. selectionId .. "Radio" .. selection[1] .. "Name"]:SetTextColor(1.0, 1.0, 1.0, 1.0);
		end
	end

	CT_UnitFramesOptionsFrameBox1PlayerTextLeftCB:SetChecked(CT_UnitFramesOptions.playerTextLeft);
	CT_UnitFramesOptionsFrameBox1PlayerCoordsRightCB:SetChecked(CT_UnitFramesOptions.playerCoordsRight);
	CT_UnitFramesOptionsFrameBox2PartyClassColorCB:SetChecked(CT_UnitFramesOptions.partyClassColor ~= false);
	CT_UnitFramesOptionsFrameBox3ClassFrameCB:SetChecked(CT_UnitFramesOptions.displayTargetClass);
	CT_UnitFramesOptionsFrameBox3TargetTextRightCB:SetChecked(CT_UnitFramesOptions.targetTextRight);
	CT_UnitFramesOptionsFrameBox3ShowToTCB:SetChecked(GetCVar("showTargetOfTarget") == "1");
	CT_UnitFramesOptionsFrameBox4DisplayCB:SetChecked(CT_UnitFramesOptions.shallDisplayAssist);
	CT_UnitFramesOptionsFrameBox4TargetofAssistCB:SetChecked(CT_UnitFramesOptions.shallDisplayTargetofAssist);
	CT_UnitFramesOptionsFrameBox4AssistCastbarCB:SetChecked(CT_UnitFramesOptions.showAssistCastbar);
	CT_UnitFramesOptionsFrameBox4AssistTextRightCB:SetChecked(CT_UnitFramesOptions.assistTextRight);
	CT_UnitFramesOptionsFrameBox4AssistBuffsOnTopCB:SetChecked(CT_UnitFramesOptions.assistBuffsOnTop);
	CT_UnitFramesOptionsFrameBox5DisplayCB:SetChecked(CT_UnitFramesOptions.shallDisplayFocus);
	CT_UnitFramesOptionsFrameBox5TargetofFocusCB:SetChecked(CT_UnitFramesOptions.shallDisplayTargetofFocus);
	CT_UnitFramesOptionsFrameBox5FocusCastbarCB:SetChecked(CT_UnitFramesOptions.showFocusCastbar);
	CT_UnitFramesOptionsFrameBox5FocusTextRightCB:SetChecked(CT_UnitFramesOptions.focusTextRight);
	CT_UnitFramesOptionsFrameBox5FocusBuffsOnTopCB:SetChecked(CT_UnitFramesOptions.focusBuffsOnTop);
	CT_UnitFramesOptionsFrameBox5HideStdFocusCB:SetChecked(CT_UnitFramesOptions.hideStdFocus);

	CT_UnitFramesOptionsFrameOneColorHealthCB:SetChecked(CT_UnitFramesOptions.oneColorHealth);
	CT_UnitFramesOptionsFrameLargeBreakUpCB:SetChecked(CT_UnitFramesOptions.largeBreakUp ~= false);
	CT_UnitFramesOptionsFrameLargeAbbreviateCB:SetChecked(CT_UnitFramesOptions.largeAbbreviate ~= false);
	CT_UnitFramesOptionsFrameMakeFontLikeRetailCB:SetChecked(CT_UnitFramesOptions.makeFontLikeRetail);

	if ( CT_UnitFramesOptions.displayTargetClass ) then
		CT_TargetFrameClassFrame:Show();
		CT_SetTargetClass();
	else
		CT_TargetFrameClassFrame:Hide();
	end

	if (CT_FocusFrame) then
		CT_FocusFrame_ToggleStandardFocus();
	end

	-- Call the functions to update player/target/target of target/party
	module:ShowPlayerFrameBarText();
	module:AnchorPlayerFrameSideText();
	
	module:ShowTargetFrameBarText();
	module:AnchorTargetFrameSideText();
		
	module:ShowPartyFrameBarText();
	module:AnchorPartyFrameSideText();
	
	if (CT_AssistFrame) then
		module:ShowAssistFrameBarText();
		module:AnchorAssistFrameSideText();
	end

	if (CT_FocusFrame) then	
		module:ShowFocusFrameBarText();
		module:AnchorFocusFrameSideText();
	end

	module:ShowPetFrameBarText();
	module:AnchorPetFrameSideText();
	

end

-- Color swatch functions
function CT_UnitFrameOptions_ColorSwatch_ShowColorPicker(self, frame)
	local selectionId, boxId = self:GetParent():GetID(), self:GetParent():GetParent():GetID();
	frame.r = CT_UnitFramesOptions.styles[boxId][selectionId][2];
	frame.g = CT_UnitFramesOptions.styles[boxId][selectionId][3];
	frame.b = CT_UnitFramesOptions.styles[boxId][selectionId][4];
	frame.opacity = CT_UnitFramesOptions.styles[boxId][selectionId][5];
	frame.boxId = boxId;
	frame.selectionId = selectionId;
	frame.opacityFunc = CT_UnitFrameOptions_ColorSwatch_SetOpacity;
	frame.swatchFunc = CT_UnitFrameOptions_ColorSwatch_SetColor;
	frame.cancelFunc = CT_UnitFrameOptions_ColorSwatch_CancelColor;
	frame.hasOpacity = 1;
	UIDropDownMenuButton_OpenColorPicker(frame);
end

function CT_UnitFrameOptions_ColorSwatch_SetColor()
	local r, g, b = ColorPickerFrame:GetColorRGB();
	local boxId, selectionId = CT_UnitFramesOptionsFrame.boxId, CT_UnitFramesOptionsFrame.selectionId;
	CT_UnitFramesOptions.styles[boxId][selectionId][2] = r;
	CT_UnitFramesOptions.styles[boxId][selectionId][3] = g;
	CT_UnitFramesOptions.styles[boxId][selectionId][4] = b;

	CT_UnitFramesOptions_Radio_Update();
end

function CT_UnitFrameOptions_ColorSwatch_CancelColor()
	local boxId, selectionId = CT_UnitFramesOptionsFrame.boxId, CT_UnitFramesOptionsFrame.selectionId;
	CT_UnitFramesOptions.styles[boxId][selectionId][2] = CT_UnitFramesOptionsFrame.r;
	CT_UnitFramesOptions.styles[boxId][selectionId][3] = CT_UnitFramesOptionsFrame.g;
	CT_UnitFramesOptions.styles[boxId][selectionId][4] = CT_UnitFramesOptionsFrame.b;
	CT_UnitFramesOptions.styles[boxId][selectionId][5] = CT_UnitFramesOptionsFrame.opacity;

	CT_UnitFramesOptions_Radio_Update();
end

function CT_UnitFrameOptions_ColorSwatch_SetOpacity()
	local a = OpacitySliderFrame:GetValue();
	local boxId, selectionId = CT_UnitFramesOptionsFrame.boxId, CT_UnitFramesOptionsFrame.selectionId;
	CT_UnitFramesOptions.styles[boxId][selectionId][5] = a;

	CT_UnitFramesOptions_Radio_Update();
end

-- Checkboxes
function CT_UnitFramesOptions_Box_CB_OnClick(self)
	if ( self:GetParent():GetID() == 1 ) then
		-- Box1
		if (self:GetID() == 18) then
			-- "Show health/mana on left"
			CT_UnitFramesOptions.playerTextLeft = self:GetChecked();
			module:AnchorPlayerFrameSideText();
		elseif (self:GetID() == 63) then
			-- "Show player coordinates"
			CT_UnitFramesOptions.playerCoordsRight = self:GetChecked();
			CT_PlayerFrame_PlayerCoords();
		end
	elseif ( self:GetParent():GetID() == 2 ) then
		-- Box2
		if (self:GetID() == 65) then
			-- "Use class colors"
			CT_UnitFramesOptions.partyClassColor = self:GetChecked();
			module.UpdatePartyFrameClassColors();
		end
	elseif ( self:GetParent():GetID() == 3 ) then
		-- Box3
		if (self:GetID() == 12) then
			-- "Show the class"
			CT_UnitFramesOptions.displayTargetClass = self:GetChecked();
		elseif (self:GetID() == 18) then
			-- "Show health/mana on right"
			CT_UnitFramesOptions.targetTextRight = self:GetChecked();
			module:AnchorTargetFrameSideText();
		elseif (self:GetID() == 64) then
			if (self:GetChecked()) then
				SetCVar("showTargetOfTarget", 1);
			else
				SetCVar("showTargetOfTarget",0);
			end
			ConsoleExec("RELOADUI");
		end
	elseif ( self:GetParent():GetID() == 4 ) then
		-- Box4
		if (self:GetID() == 15) then
			-- "Show the target"
			CT_UnitFramesOptions.shallDisplayTargetofAssist = self:GetChecked();
			if (not InCombatLockdown()) then
				if ( self:GetChecked() ) then
					RegisterUnitWatch(CT_TargetofAssistFrame);
					CT_TargetofAssist_Update(CT_TargetofAssistFrame);
				else
					UnregisterUnitWatch(CT_TargetofAssistFrame);
					CT_TargetofAssistFrame:Hide();
				end
			end
--			if ( not UnitAffectingCombat("player") ) then
--				CT_AssistFrame_OnEvent(CT_AssistFrame, "PLAYER_REGEN_ENABLED");
--			end
		elseif (self:GetID() == 16) then
			-- "Show the casting bar"
			CT_UnitFramesOptions.showAssistCastbar = self:GetChecked();
			CT_Assist_ToggleSpellbar(CT_AssistFrame.spellbar);
--			CT_Assist_Spellbar_OnEvent(CT_AssistFrame.spellbar, "CVAR_UPDATE", "SHOW_TARGET_CASTBAR");
		elseif (self:GetID() == 18) then
			-- "Show health/mana on right"
			CT_UnitFramesOptions.assistTextRight = self:GetChecked();
			module:AnchorAssistFrameSideText();
		elseif (self:GetID() == 19) then
			-- "Show buffs on top"
			CT_UnitFramesOptions.assistBuffsOnTop = self:GetChecked();
			CT_AssistFrame.buffsOnTop = CT_UnitFramesOptions.assistBuffsOnTop;
			CT_AssistFrame_UpdateAuras(CT_AssistFrame);
		elseif (self:GetID() == 14) then
			-- "Display this frame"
			CT_UnitFramesOptions.shallDisplayAssist = self:GetChecked();
			if (not InCombatLockdown()) then
				if ( self:GetChecked() ) then
					CT_UnitFrames_ResetPosition("CT_AssistFrame_Drag")
					RegisterUnitWatch(CT_AssistFrame);
					CT_AssistFrame_Update(CT_AssistFrame);
				else
					UnregisterUnitWatch(CT_AssistFrame);
					CT_AssistFrame:Hide();
				end
			end
--			if ( not UnitAffectingCombat("player") ) then
--				CT_AssistFrame_OnEvent(CT_AssistFrame, "PLAYER_REGEN_ENABLED");
--			end
		end
	else
		-- Box5
		if (self:GetID() == 15) then
			-- "Show the target"
			CT_UnitFramesOptions.shallDisplayTargetofFocus = self:GetChecked();
			if (not InCombatLockdown()) then
				if ( self:GetChecked() ) then
					RegisterUnitWatch(CT_TargetofFocusFrame);
					CT_TargetofFocus_Update(CT_TargetofFocusFrame);
				else
					UnregisterUnitWatch(CT_TargetofFocusFrame);
					CT_TargetofFocusFrame:Hide();
				end
			end
--			if ( not UnitAffectingCombat("player") ) then
--				CT_FocusFrame_OnEvent(CT_FocusFrame, "PLAYER_REGEN_ENABLED");
--			end
		elseif (self:GetID() == 16) then
			-- "Show the casting bar"
			CT_UnitFramesOptions.showFocusCastbar = self:GetChecked();
			CT_Focus_ToggleSpellbar(CT_FocusFrame.spellbar);
--			CT_Focus_Spellbar_OnEvent(CT_FocusFrame.spellbar, "CVAR_UPDATE", "SHOW_TARGET_CASTBAR");
		elseif (self:GetID() == 17) then
			-- "Hide standard focus frame"
			CT_UnitFramesOptions.hideStdFocus = self:GetChecked();
			CT_FocusFrame_ToggleStandardFocus();
		elseif (self:GetID() == 18) then
			-- "Show health/mana on right"
			CT_UnitFramesOptions.focusTextRight = self:GetChecked();
			module:AnchorFocusFrameSideText();
		elseif (self:GetID() == 19) then
			-- "Show buffs on top"
			CT_UnitFramesOptions.focusBuffsOnTop = self:GetChecked();
			CT_FocusFrame.buffsOnTop = CT_UnitFramesOptions.focusBuffsOnTop;
			CT_FocusFrame_UpdateAuras(CT_FocusFrame);
		elseif (self:GetID() == 14) then
			-- "Display this frame"
			CT_UnitFramesOptions.shallDisplayFocus = self:GetChecked();
			if (not InCombatLockdown()) then
				if ( self:GetChecked() ) then
					CT_UnitFrames_ResetPosition("CT_FocusFrame_Drag")
					RegisterUnitWatch(CT_FocusFrame);
					CT_FocusFrame_Update(CT_FocusFrame);
				else
					UnregisterUnitWatch(CT_FocusFrame);
					CT_FocusFrame:Hide();
				end
			end
--			if ( not UnitAffectingCombat("player") ) then
--				CT_FocusFrame_OnEvent(CT_FocusFrame, "PLAYER_REGEN_ENABLED");
--			end
		end
	end
	CT_UnitFramesOptions_Radio_Update();
end

-- Lock Handler
-- The [index] must match the ID of the checkbox, and is also used to save the settings.
local lockTable =
{ 
	--[1] = { drag = "CT_PlayerFrame_Drag", cb = "CT_UnitFramesOptionsFrameBox1LockCB" },
	--[2] = { drag = "CT_TargetFrame_Drag", cb = "CT_UnitFramesOptionsFrameBox3LockCB" },
	[3] = CT_AssistFrame and { drag = "CT_AssistFrame_Drag", cb = "CT_UnitFramesOptionsFrameBox4LockCB" },
	[4] = CT_FocusFrame and { drag = "CT_FocusFrame_Drag",  cb = "CT_UnitFramesOptionsFrameBox5LockCB" },	-- nil in Classic Era
}

function CT_UnitFramesOptions_Lock_CB_OnClick(obj, checked, id)
	if ( not CT_UnitFramesOptions.unlock ) then
		CT_UnitFramesOptions.unlock = { };
	end

	local lockdata = lockTable[id];
	CT_UnitFramesOptions.unlock[id] = not checked;

	if ( checked ) then
		_G[lockdata.drag]:Hide();
	else
		_G[lockdata.drag]:Show();
	end
	obj:SetChecked(checked);
end


module.currBoxFrame = nil;

function CT_UnitFrameOptionsBoxSelectionButton_OnShow(self)
	local id = self:GetID()
	local total, padding = 6, 4
	if not CT_FocusFrame then
		total = total - 1
		padding = padding + 3
		if id == 5 then
			return
		elseif id > 5 then
			id = id - 1
		end
	end
	if not CT_AssistFrame then
		total = total - 1
		padding = padding + 3
		if id == 4 then
			return
		elseif id > 4 then
			id = id - 1
		end
	end	
	local width = (500 - 3*padding) / total
	self:SetPoint("TOPLEFT", (width*(id-1))+2*padding, -45)
	self:SetSize(width-padding, 21)
	self:SetScript("OnShow", nil)
end

function CT_UnitFrameOptions_SetOptionsFrame(btn)
	local id = btn and btn:GetID() or 1
	
	CT_UnitFramesOptionsFramePlayerOptions:SetEnabled(id ~= 1);
	CT_UnitFramesOptionsFramePartyOptions:SetEnabled(id ~= 2);
	CT_UnitFramesOptionsFrameTargetOptions:SetEnabled(id ~= 3);
	CT_UnitFramesOptionsFrameAssistOptions:SetEnabled(id ~= 4);
	CT_UnitFramesOptionsFrameFocusOptions:SetEnabled(id ~= 5);
	CT_UnitFramesOptionsFramePetOptions:SetEnabled(id ~= 6);
	
	CT_UnitFramesOptionsFrameBox1:SetShown(id == 1);
	CT_UnitFramesOptionsFrameBox2:SetShown(id == 2);
	CT_UnitFramesOptionsFrameBox3:SetShown(id == 3);
	CT_UnitFramesOptionsFrameBox4:SetShown(id == 4);
	CT_UnitFramesOptionsFrameBox5:SetShown(id == 5);
	CT_UnitFramesOptionsFrameBox6:SetShown(id == 6);
end

function CT_UnitFramesOptions_OneColorHealth_CB_OnClick(self, checked)
	CT_UnitFramesOptions.oneColorHealth = checked; -- nil, 1
	module:ShowPlayerFrameBarText();
	module:ShowPartyFrameBarText();
	module:ShowTargetFrameBarText();
	if (CT_AssistFrame) then
		module:ShowAssistFrameBarText();
	end
	if (CT_FocusFrame) then
		module:ShowFocusFrameBarText();
	end
end

function CT_UnitFramesOptions_LargeBreakUp_CB_OnClick(self, checked)
	CT_UnitFramesOptions.largeBreakUp = (not not checked); -- false if checked == nil, true if 1
	module:ShowPlayerFrameBarText();
	module:ShowPartyFrameBarText();
	module:ShowTargetFrameBarText();
	if (CT_AssistFrame) then
		module:ShowAssistFrameBarText();
	end
	if (CT_FocusFrame) then
		module:ShowFocusFrameBarText();
	end
end

function CT_UnitFramesOptions_LargeAbbreviate_CB_OnClick(self, checked)
	CT_UnitFramesOptions.largeAbbreviate = (not not checked); -- false if checked == nil, true if 1
	module:ShowPlayerFrameBarText();
	module:ShowPartyFrameBarText();
	module:ShowTargetFrameBarText();
	if (CT_AssistFrame) then
		module:ShowAssistFrameBarText();
	end
	if (CT_FocusFrame) then	
		module:ShowFocusFrameBarText();
	end
end

function CT_UnitFramesOptions_MakeFontLikeRetail_CB_OnClick(self, checked)
	CT_UnitFramesOptions.makeFontLikeRetail = (not not checked); -- false if checked == nil, true if 1
	if (CT_UnitFramesOptions.makeFontLikeRetail) then
		CT_UnitFrames_TextStatusBarText:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE");
	else
		CT_UnitFrames_TextStatusBarText:CopyFontObject(TextStatusBarText);
	end
end

--------------------------------------------
-- Mod Options

-- function to open and close the window, that can be recognized by CT_Library (to bypass the CTMod panel)
module.customOpenFunction = function()
	CT_UnitFramesOptionsFrame:Show()
end

-- Slash command
module:setSlashCmd(module.customOpenFunction, "/uf", "/ctuf", "/unitframes");

-- Mod Initialization
module.update = function(self, option, value)
	if ( option == "init" ) then
		if (CT_AssistFrame) then
			CT_AssistFrame.buffsOnTop = CT_UnitFramesOptions.assistBuffsOnTop;
			if ( CT_UnitFramesOptions.shallDisplayAssist ) then
				RegisterUnitWatch(CT_AssistFrame);
				CT_AssistFrame_Update(CT_AssistFrame);
			else
				UnregisterUnitWatch(CT_AssistFrame);
				CT_AssistFrame:Hide();
			end
			if ( CT_UnitFramesOptions.shallDisplayTargetofAssist ) then
				RegisterUnitWatch(CT_TargetofAssistFrame);
				CT_TargetofAssist_Update(CT_TargetofAssistFrame);
			else
				UnregisterUnitWatch(CT_TargetofAssistFrame);
				CT_TargetofAssistFrame:Hide();
			end		
		end
		
		if (CT_FocusFrame) then
			CT_FocusFrame.buffsOnTop = CT_UnitFramesOptions.focusBuffsOnTop;
			if ( CT_UnitFramesOptions.shallDisplayFocus ) then
				RegisterUnitWatch(CT_FocusFrame);
				CT_FocusFrame_Update(CT_FocusFrame);
			else
				UnregisterUnitWatch(CT_FocusFrame);
				CT_FocusFrame:Hide();
			end
			if ( CT_UnitFramesOptions.shallDisplayTargetofFocus ) then
				RegisterUnitWatch(CT_TargetofFocusFrame);
				CT_TargetofFocus_Update(CT_TargetofFocusFrame);
			else
				UnregisterUnitWatch(CT_TargetofFocusFrame);
				CT_TargetofFocusFrame:Hide();
			end
		end
		
		if ( not CT_UnitFramesOptions.unlock ) then
			CT_UnitFramesOptions.unlock = { };
		end

		local unlock = CT_UnitFramesOptions.unlock;
		for i, lockdata in pairs(lockTable) do
			CT_UnitFramesOptions_Lock_CB_OnClick(_G[lockdata.cb], not unlock[i], i);
		end

		CT_UnitFrameOptions_SetOptionsFrame();
		
		CT_PlayerFrame_PlayerCoords()
		
		if (CT_Core and CT_Core.addCastingBarFrame) then
			-- Allows CT_Core 8.1.0.3 and later to add timer to casting bars
			CT_Core.addCastingBarFrame("CT_FocusFrameSpellBar");
			CT_Core.addCastingBarFrame("CT_AssistFrameSpellBar");
		end
	end
end

--------------------------------------------
-- Options Frame Code

-- module.frame = "CT_UnitFramesOptionsFrame";
-- module.external = true;

module.frame = function()
	local options = {};
	local yoffset = 5;
	local ysize;

	-- Tips
	ysize = 60;
	options["frame#tl:0:-" .. yoffset .. "#br:tr:0:-".. (yoffset + ysize)] = {
		"font#tl:5:0#v:GameFontNormalLarge#Tips",
		"font#t:0:-25#s:0:30#l:13:0#r#You can use /uf, /ctuf, or /unitframes to open the CT_UnitFrames window.#0.6:0.6:0.6:l",
	};

	-- General Options
	yoffset = yoffset + ysize + 15;
	ysize = 140;
	options["frame#tl:0:-" .. yoffset .. "#br:tr:0:-".. (yoffset + ysize)] = {
		"font#tl:5:0#v:GameFontNormalLarge#Options",
		"font#t:5:-25#s:0:30#l:13:0#r#Click the button below to open the CT_UnitFrames window.#0.6:0.6:0.6:l",
		"font#t:5:-60#s:0:30#l:13:0#r#Shift-click the button if you want to leave the CTMod Control Panel open.#0.6:0.6:0.6:l",
		["button#t:0:-100#s:120:30#n:CT_UnitFrames_OpenWindow_Button#v:GameMenuButtonTemplate#Open window"] = {
			["onclick"] = function(self)
				CT_UnitFramesOptionsFrame:Show();
				if (not IsShiftKeyDown()) then
					module:showControlPanel(false);
				end
			end,
		},
	};
	yoffset = yoffset + ysize;

	return "frame#all", options;
end