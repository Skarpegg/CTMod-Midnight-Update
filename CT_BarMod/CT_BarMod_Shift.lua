------------------------------------------------
--               CT_BarMod                    --
--                                            --
-- Intuitive yet powerful action bar addon,   --
-- featuring per-button positioning as well   --
-- as scaling while retaining the concept of  --
-- grouped buttons and action bars.           --
--                                            --
-- Please do not modify or otherwise          --
-- redistribute this without the consent of   --
-- the CTMod Team. Thank you.                 --
------------------------------------------------

-- This file deals with shifting the party frames
-- and focus frame to the right,
-- as well as shifting up the multicast action bar,
-- (formerly used by totems), the pet bar,
-- the two-button possess bar, and the stance (class) bar.

--------------------------------------------
-- Initialization

local module = select(2, ...);

-- End Initialization
--------------------------------------------

if module:getGameVersion() >= 10 then
	CT_BarMod_Shift_Init = nop
	return
end

--------------------------------------------
-- Local Copies

local next = next;
local hooksecurefunc = hooksecurefunc;
local GetNumShapeshiftForms = GetNumShapeshiftForms;
local GetPossessInfo = GetPossessInfo;
local HasMultiCastActionBar = HasMultiCastActionBar;
local InCombatLockdown = InCombatLockdown;
local IsSpellKnown = IsSpellKnown;

-- End Local Copies
--------------------------------------------

local frameSetPoint;
local frameClearAllPoints;

-------------------------------
-- Shift the party frames

local partyShifted, shiftParty, reshiftParty;

function CT_BarMod_Shift_Party_SetFlag()
	-- Set flag that indicates we need to shift the party frames when possible.
	-- This gets called when the user toggles the shift party option.
	shiftParty = 1;
end

function CT_BarMod_Shift_Party_SetReshiftFlag()
	-- Set flag that indicates we need to reshift the party frames when possible.
	-- This gets called when the user changes the shift party offset option.
	reshiftParty = 1;
end

local function CT_BarMod_Shift_Party_Move2(shift)
	if (InCombatLockdown()) then
		return;
	end
	local point, rel, relpoint, x, y = PartyMemberFrame1:GetPoint(1);
	if ( shift and point and rel and relpoint and x and y ) then
		if (not partyShifted) then
			local offset = module:getOption("shiftPartyOffset") or 37;
			x = x + offset;
			partyShifted = offset;  -- Remember the offset used.
			PartyMemberFrame1:SetPoint(point, rel, relpoint, x, y);
		end
	else
		if (partyShifted) then
			local offset = partyShifted;  -- Use the remembered offset.
			x = x - offset;
			partyShifted = nil;
			PartyMemberFrame1:SetPoint(point, rel, relpoint, x, y);
		end
	end
	shiftParty = nil;
end

function CT_BarMod_Shift_Party_Move()
	if (InCombatLockdown()) then
		return;
	end
	if (reshiftParty) then
		-- We need to reshift the frames (the offset was changed).
		if (partyShifted) then
			-- Shift the frames back before reshifting with the new offset.
			CT_BarMod_Shift_Party_Move2(false);
		end
		reshiftParty = nil;
	end
	-- Shift (or unshift) the frames using the current values of the options.
	CT_BarMod_Shift_Party_Move2( module:getOption("shiftParty") ~= false );
end

-------------------------------
-- Shift the focus frame

local focusShifted, shiftFocus, reshiftFocus;

function CT_BarMod_Shift_Focus_SetFlag()
	if (not FocusFrame) then
		return;
	end
	-- Set flag that indicates we need to shift the focus frame when possible.
	-- This gets called when the user toggles the shift focus option.
	shiftFocus = 1;
end

function CT_BarMod_Shift_Focus_SetReshiftFlag()
	if (not FocusFrame) then
		return;
	end
	-- Set flag that indicates we need to reshift the focus frame when possible.
	-- This gets called when the user toggles the shift focus offset option.
	reshiftFocus = 1;
end

local function CT_BarMod_Shift_Focus_Move2(shift)
	if (InCombatLockdown() or not FocusFrame) then
		return;
	end
	local point, rel, relpoint, x, y = FocusFrame:GetPoint(1);
	if ( shift ) then
		if (not focusShifted) then
			local offset = module:getOption("shiftFocusOffset") or 37;
			x = x + offset;
			focusShifted = offset;  -- Remember the offset used.
			FocusFrame:SetPoint(point, rel, relpoint, x, y);
		end
	else
		if (focusShifted) then
			local offset = focusShifted;  -- Use the remembered offset.
			x = x - offset;
			focusShifted = nil;
			FocusFrame:SetPoint(point, rel, relpoint, x, y);
		end
	end
	shiftFocus = nil;
end

function CT_BarMod_Shift_Focus_Move()
	if (InCombatLockdown() or not FocusFrame) then
		return;
	end
	if (reshiftFocus) then
		-- We need to reshift the frames (the offset was changed).
		if (focusShifted) then
			-- Shift the frames back before reshifting with the new offset.
			CT_BarMod_Shift_Focus_Move2(false);
		end
		reshiftFocus = nil;
	end
	-- Shift (or unshift) the frames using the current values of the options.
	CT_BarMod_Shift_Focus_Move2( module:getOption("shiftFocus") ~= false );
end

-------------------------------
-- Shift the MultiCast bar.

--[[  removed in 2012


local function CT_BarMod_Shift_MultiCast_areWeShifting()
	if (module:getGameVersion() == 1) then
		return false;
	end
	if (CT_BottomBar and CT_BottomBar.ctMultiCast) then
		-- This version of CT_BottomBar supports deactivation of this bar.
		if (not CT_BottomBar.ctMultiCast.isDisabled) then
			-- The bar is activated.
			-- Let CT_BottomBar handle it.
			return false;
		end
		-- This bar has been deactivated by CT_BottomBar.
		-- We will handle it.
	elseif (CT_BottomBar) then
		-- This version of CT_BottomBar does not support deactivation of this bar.
		-- Let CT_BottomBar handle it.
		return false;
	end
	-- We will handle shifting of this bar.
	return true;
end

local multicastIsShifted;
local multicastNeedToMove;

-- knownMultiCastSummonSpells
-- index: TOTEM_MULTI_CAST_SUMMON_SPELLS 
-- value: spellId if the spell is known, nil otherwise
local knownMultiCastSummonSpells = { };

-- knownMultiCastRecallSpells
-- index: TOTEM_MULTI_CAST_RECALL_SPELLS 
-- value: spellId if the spell is known, nil otherwise
local knownMultiCastRecallSpells = { };

local function CT_BarMod_Shift_MultiCast_GetShiftOption()
	return (module:getOption("shiftMultiCast") ~= false);
end

local function CT_BarMod_Shift_MultiCast_UpdateTextures()
	if (not CT_BarMod_Shift_MultiCast_areWeShifting()) then
		return;
	end
end

local function CT_BarMod_Shift_MultiCast_SummonSpellButton_Update(frame, self)
	-- This is a modified version of MultiCastSummonSpellButton_Update
	-- from MultiCastActionBarFrame.lua.

	-- first update which multi-cast spells we actually know
	for index, spellId in next, TOTEM_MULTI_CAST_SUMMON_SPELLS do
		knownMultiCastSummonSpells[index] = (IsSpellKnown(spellId) and spellId) or nil;
	end

	-- update the spell button
	local spellId = knownMultiCastSummonSpells[self:GetID()];
--	self.spellId = spellId;
	if ( HasMultiCastActionBar() and spellId ) then
		-- reanchor the first slot button take make room for this button
		local width = self:GetWidth();
		local xOffset = width + 8 + 3;
		local page;
		for i = 1, NUM_MULTI_CAST_PAGES do
			page = _G["MultiCastActionPage"..i];
			frameClearAllPoints(page);
			frameSetPoint(page, "BOTTOMLEFT", frame, "BOTTOMLEFT", xOffset, 3);
		end
		frameClearAllPoints(MultiCastSlotButton1);
		frameSetPoint(MultiCastSlotButton1, "BOTTOMLEFT", frame, "BOTTOMLEFT", xOffset, 3);

		self:Show();
	else
		-- reanchor the first slot button take the place of this button
		local xOffset = 3;
		local page;
		for i = 1, NUM_MULTI_CAST_PAGES do
			page = _G["MultiCastActionPage"..i];
			frameClearAllPoints(page);
			frameSetPoint(page, "BOTTOMLEFT", frame, "BOTTOMLEFT", xOffset, 3);
		end
		frameClearAllPoints(MultiCastSlotButton1);
		frameSetPoint(MultiCastSlotButton1, "BOTTOMLEFT", frame, "BOTTOMLEFT", xOffset, 3);

		self:Hide();
	end

	frameSetPoint(MultiCastSlotButton1, "CENTER", frame, "CENTER", 0, 0);
	frameSetPoint(MultiCastSlotButton2, "CENTER", frame, "CENTER", 0, 0);
	frameSetPoint(MultiCastSlotButton3, "CENTER", frame, "CENTER", 0, 0);
	frameSetPoint(MultiCastSlotButton4, "CENTER", frame, "CENTER", 0, 0);

	frameClearAllPoints(MultiCastSummonSpellButton);
	frameSetPoint(MultiCastSummonSpellButton, "BOTTOMLEFT", frame, "BOTTOMLEFT", 3, 3);
end

local function CT_BarMod_Shift_MultiCast_RecallSpellButton_Update(frame, self)
	-- This is a modified version of MultiCastRecallSpellButton_Update
	-- from MultiCastActionBarFrame.lua.

	-- first update which multi-cast spells we actually know
	for index, spellId in next, TOTEM_MULTI_CAST_RECALL_SPELLS do
		knownMultiCastRecallSpells[index] = (IsSpellKnown(spellId) and spellId) or nil;
	end

	-- update the spell button
	local spellId = knownMultiCastRecallSpells[self:GetID()];
--	self.spellId = spellId;
	if ( HasMultiCastActionBar() and spellId ) then
		-- anchor to the last shown slot
		local activeSlots = MultiCastActionBarFrame.numActiveSlots;
		if ( activeSlots > 0 ) then
			frameClearAllPoints(self);
			frameSetPoint(self, "LEFT", _G["MultiCastSlotButton"..activeSlots], "RIGHT", 8, 0);
			frameSetPoint(self, "BOTTOMLEFT", frame, "BOTTOMLEFT", 36, 3);
		end

		self:Show();
	else
		frameClearAllPoints(self);
		frameSetPoint(self, "LEFT", MultiCastSummonSpellButton, "RIGHT", 8, 0);
		frameSetPoint(self, "BOTTOMLEFT", frame, "BOTTOMLEFT", 36, 3);

		self:Hide();
	end
end

function CT_BarMod_Shift_MultiCast_UpdatePositions()
	if (not CT_BarMod_Shift_MultiCast_areWeShifting()) then
		return;
	end

	CT_BarMod_Shift_MultiCast_UpdateTextures();

	if (InCombatLockdown()) then
		return;
	end

	local frame;
	local shift = CT_BarMod_Shift_MultiCast_GetShiftOption();

	if (shift) then
		local frame1, frame2, yoffset;
		frame1 = CT_BarMod_MultiCastActionBarFrame;
		frame2 = MultiCastActionBarFrame;

		yoffset = 7;
		if (PetActionBarFrame_IsAboveStance and PetActionBarFrame_IsAboveStance()) then
			yoffset = 0;
		end

		frame1:SetHeight(frame2:GetHeight());
		frame1:SetWidth(frame2:GetWidth());
		frame1:ClearAllPoints();
		frame1:SetPoint("BOTTOMLEFT", frame2, "TOPLEFT", 0, yoffset)

		frame2:EnableMouse(false);

		multicastIsShifted = true;
		frame = frame1;
	else
		if (multicastIsShifted) then
			local frame2 = MultiCastActionBarFrame;

			frame2:EnableMouse(true);

			multicastIsShifted = false;
			frame = frame2;
		else
			return;
		end
	end

	-- update the multi cast spells
	CT_BarMod_Shift_MultiCast_SummonSpellButton_Update(frame, MultiCastSummonSpellButton);
	CT_BarMod_Shift_MultiCast_RecallSpellButton_Update(frame, MultiCastRecallSpellButton);
end

local function CT_BarMod_Shift_MultiCast_SetPoint(self, ap, rt, rp, x, y)
	-- (hook) This is a post hook of the .SetPoint and .SetAllPoints functions
	CT_BarMod_Shift_MultiCast_UpdatePositions();
end

local function CT_BarMod_Shift_MultiCast_OnUpdate()
	-- (hook) This is a post hook of the MultiCastActionBarFrame_OnUpdate function in MultiCastActionBarFrame.lua
	--
	-- Blizzard calls MultiCastActionBarFrame_OnUpdate from MultiCastActionBarFrame.xml using
	-- the <OnUpdate function="MultiCastActionBarFrame_OnUpdate"/> syntax,
	-- so we have to hook the OnUpdate script in order for our function
	-- to get called.
	--
	if (not MultiCastActionBarFrame.completed) then
		-- MultiCast bar is sliding into place.
		multicastNeedToMove = 1;
	else
		-- MultiCast bar has finished sliding into place.
		if (multicastNeedToMove) then
			CT_BarMod_Shift_MultiCast_UpdatePositions();
			multicastNeedToMove = nil;
		end
	end
end

local function CT_BarMod_Shift_MultiCast_Init()
	local frame1, frame2;

	-- Our frame for the MultiCast action buttons
	frame1 = CreateFrame("Frame", "CT_BarMod_MultiCastActionBarFrame");
	frame2 = MultiCastActionBarFrame;

	frame1:SetParent(UIParent);
	frame1:EnableMouse(false);
	frame1:SetHeight(frame2:GetHeight());
	frame1:SetWidth(frame2:GetWidth());
	frame1:SetPoint("BOTTOMLEFT", frame2, "TOPLEFT", 0, 0)
	frame1:SetAlpha(1);
	frame1:Hide();

	for i = 1, 4 do
		hooksecurefunc(_G["MultiCastSlotButton" .. i], "SetPoint", CT_BarMod_Shift_MultiCast_SetPoint);
		hooksecurefunc(_G["MultiCastSlotButton" .. i], "SetAllPoints", CT_BarMod_Shift_MultiCast_SetPoint);
	end

	hooksecurefunc(MultiCastSummonSpellButton, "SetPoint", CT_BarMod_Shift_MultiCast_SetPoint);
	hooksecurefunc(MultiCastSummonSpellButton, "SetAllPoints", CT_BarMod_Shift_MultiCast_SetPoint);

	hooksecurefunc(MultiCastRecallSpellButton, "SetPoint", CT_BarMod_Shift_MultiCast_SetPoint);
	hooksecurefunc(MultiCastRecallSpellButton, "SetAllPoints", CT_BarMod_Shift_MultiCast_SetPoint);

	-- Hook the function and any xml script handler using the function= syntax to call it.
	hooksecurefunc("MultiCastActionBarFrame_OnUpdate", CT_BarMod_Shift_MultiCast_OnUpdate);
	frame2:HookScript("OnUpdate", CT_BarMod_Shift_MultiCast_OnUpdate);

	CT_BarMod_Shift_MultiCast_UpdatePositions();
end

removed in 2012 --]]

-------------------------------
-- Shift the pet bar.

local function CT_BarMod_Shift_Pet_areWeShifting()
	if (CT_BottomBar and CT_BottomBar.ctPetBar) then
		-- This version of CT_BottomBar supports deactivation of this bar.
		if (not CT_BottomBar.ctPetBar.isDisabled) then
			-- The bar is activated.
			-- Let CT_BottomBar handle it.
			return false;
		end
		-- This bar has been deactivated by CT_BottomBar.
		-- We will handle it.
	elseif (CT_BottomBar) then
		-- This version of CT_BottomBar does not support deactivation of this bar.
		-- Let CT_BottomBar handle it.
		return false;
	end
	-- We will handle shifting of this bar.
	return true;
end

local petIsShifted;
local petNeedToMove;

local function CT_BarMod_Shift_Pet_GetShiftOption()
	return (module:getOption("shiftPet") ~= false);
end

local function CT_BarMod_Shift_Pet_UpdateTextures()
	if (not CT_BarMod_Shift_Pet_areWeShifting()) then
		return;
	end

	local shift = CT_BarMod_Shift_Pet_GetShiftOption();
	
	if (shift) then
		SlidingActionBarTexture0:Hide();
		SlidingActionBarTexture1:Hide();
	else
		if (petIsShifted) then
			if ( MultiBarBottomLeft:IsShown() ) then
				SlidingActionBarTexture0:Hide();
				SlidingActionBarTexture1:Hide();
			else
				if (PetActionBarFrame_IsAboveStance and PetActionBarFrame_IsAboveStance()) then
					SlidingActionBarTexture0:Hide();
					SlidingActionBarTexture1:Hide();
				else
					SlidingActionBarTexture0:Show();
					SlidingActionBarTexture1:Show();
				end
			end
		else
			return;
		end
	end
end

function CT_BarMod_Shift_Pet_UpdatePositions()
	if (not CT_BarMod_Shift_Pet_areWeShifting()) then
		return;
	end

	CT_BarMod_Shift_Pet_UpdateTextures();

	if (InCombatLockdown()) then
		return;
	end

	local frame, yoffset;
	frame = CT_BarMod_PetActionBarFrame;	
	local shift = CT_BarMod_Shift_Pet_GetShiftOption();

	PetActionButton1:ClearAllPoints();
	PetActionButton1:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 36, 2);
	
	if (shift) then
			CT_BarMod_PetActionBarFrame:ClearAllPoints();
			CT_BarMod_PetActionBarFrame:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, module:getOption("shiftPetOffset") or 113);
			CT_BarMod_PetActionBarFrame:SetPoint("LEFT", PetActionBarFrame);
			PetActionBarFrame:EnableMouse(false);
			petIsShifted = true;

	else
			CT_BarMod_PetActionBarFrame:ClearAllPoints();
			CT_BarMod_PetActionBarFrame:SetPoint("BOTTOMLEFT", PetActionBarFrame, "BOTTOMLEFT", 0, 0);
			PetActionBarFrame:EnableMouse(true);
			petIsShifted = false;
	end
end

local function CT_BarMod_Shift_Pet_Init()
	local frame;

	-- Our frame for the pet action buttons
	frame = CreateFrame("Frame", "CT_BarMod_PetActionBarFrame");
	frame:SetSize(0.0001, 0.0001);
	frame:Hide();

	CT_BarMod_Shift_Pet_UpdatePositions();
	
end

-------------------------------
-- Shift the possess bar.

local function CT_BarMod_Shift_Possess_areWeShifting()
	if (PossessBarFrame) then
		if (CT_BottomBar and CT_BottomBar.ctPossess) then
			-- This version of CT_BottomBar supports deactivation of this bar.
			if (not CT_BottomBar.ctPossess.isDisabled) then
				-- The bar is activated.
				-- Let CT_BottomBar handle it.
				return false;
			end
			-- This bar has been deactivated by CT_BottomBar.
			-- We will handle it.
		elseif (CT_BottomBar) then
			-- This version of CT_BottomBar does not support deactivation of this bar.
			-- Let CT_BottomBar handle it.
			return false;
		end
		-- We will handle shifting of this bar.
		return true;
	else
		-- Classic
		return false;
	end
end

local possessIsShifted;

local function CT_BarMod_Shift_Possess_GetShiftOption()
	return (module:getOption("shiftPossess") ~= false);
end

local function CT_BarMod_Shift_Possess_UpdateTextures()
	if (not CT_BarMod_Shift_Possess_areWeShifting()) then
		return;
	end

	local shift = CT_BarMod_Shift_Possess_GetShiftOption();
	if (shift) then
		local background;
		for i=1, NUM_POSSESS_SLOTS do
			background = _G["PossessBackground"..i];
			background:Hide();
		end
	else
		if (possessIsShifted) then
			local texture, name, enabled;
			local background;
			for i=1, NUM_POSSESS_SLOTS do
				background = _G["PossessBackground"..i];
				texture, name, enabled = GetPossessInfo(i);
				if ( enabled ) then
					background:Show();
				else
					background:Hide();
				end
			end
		else
			return;
		end
	end
end

function CT_BarMod_Shift_Possess_UpdatePositions()
	if (not CT_BarMod_Shift_Possess_areWeShifting()) then
		return;
	end

	CT_BarMod_Shift_Possess_UpdateTextures();

	if (InCombatLockdown()) then
		return;
	end

	local frame;
	local shift = CT_BarMod_Shift_Possess_GetShiftOption();

	if (shift) then
		local frame1, frame2;
		frame1 = CT_BarMod_PossessBarFrame;
		frame2 = PossessBarFrame;

		frame1:SetHeight(frame2:GetHeight());
		frame1:SetWidth(frame2:GetWidth());
		frame1:ClearAllPoints();
		frame1:SetPoint("BOTTOMLEFT", frame2, "TOPLEFT", 0, 12)

		frame2:EnableMouse(false);

		possessIsShifted = true;
		frame = frame1;
	else
		if (possessIsShifted) then
			local frame2 = PossessBarFrame;

			frame2:EnableMouse(true);

			possessIsShifted = false;
			frame = frame2;
		else
			return;
		end
	end

	frameClearAllPoints(PossessButton1);
	frameSetPoint(PossessButton1, "BOTTOMLEFT", frame, 10, 3);

	local obj;
	for i = 2, 2, 1 do
		obj = _G["PossessButton"..i];
		frameClearAllPoints(obj);
		frameSetPoint(obj, "LEFT", _G["PossessButton"..(i-1)], "RIGHT", 8, 0);
	end
end

local function CT_BarMod_Shift_Possess_SetPoint(self, ap, rt, rp, x, y)
	-- (hook) This is a post hook of the .SetPoint and .SetAllPoints functions
	CT_BarMod_Shift_Possess_UpdatePositions();
end

local function CT_BarMod_Shift_Possess_Update()
	-- (hook) This is a post hook of the PossessBar_Update function in PossessActionBar.lua
	--
	-- Blizzard's PossessBar_Update function gets called:
	-- a) from ActionBarController_OnEvent in ActionBarController.lua for the events
	--    UPDATE_POSSESS_BAR
	-- b) from ActionBarController_UpdateAll in ActionBarController.lua.
	-- Blizzard calls UIParent_ManageFramePositions at the end of PossessBar_Update if
	-- it determines that it needs to call it.
	--
	CT_BarMod_Shift_Possess_UpdatePositions();
end

local function CT_BarMod_Shift_Possess_UpdateState()
	-- (hook) This is a post hook of the PossessBar_UpdateState function in PossessActionBar.lua
	--
	-- Blizzard's PossessBar_UpdateState function gets called:
	-- a) from PossessBar_Update in PossessActionBar.lua
	--
	CT_BarMod_Shift_Possess_UpdateTextures();
end

local function CT_BarMod_Shift_Possess_Init()
	if (PossessBarFrame) then	-- Classic vs. Retail
		local frame1, frame2;

		-- Our frame for the possess action buttons
		frame1 = CreateFrame("Frame", "CT_BarMod_PossessBarFrame");
		frame2 = PossessBarFrame;

		frame1:SetParent(UIParent);
		frame1:EnableMouse(false);
		frame1:SetHeight(frame2:GetHeight());
		frame1:SetWidth(frame2:GetWidth());
		frame1:SetPoint("BOTTOMLEFT", frame2, "TOPLEFT", 0, 0)
		frame1:SetAlpha(1);
		frame1:Hide();

		for i = 1, 2 do
			hooksecurefunc(_G["PossessButton" .. i], "SetPoint", CT_BarMod_Shift_Possess_SetPoint);
			hooksecurefunc(_G["PossessButton" .. i], "SetAllPoints", CT_BarMod_Shift_Possess_SetPoint);
		end

		hooksecurefunc("PossessBar_Update", CT_BarMod_Shift_Possess_Update);
		hooksecurefunc("PossessBar_UpdateState", CT_BarMod_Shift_Possess_UpdateState);

		CT_BarMod_Shift_Possess_UpdatePositions();
	end
end

-------------------------------
-- Shift the stance (class) bar.

local function CT_BarMod_Shift_Stance_areWeShifting()
	if (CT_BottomBar and CT_BottomBar.ctClassBar) then
		-- This version of CT_BottomBar supports deactivation of this bar.
		if (not CT_BottomBar.ctClassBar.isDisabled) then
			-- The bar is activated.
			-- Let CT_BottomBar handle it.
			return false;
		end
		-- This bar has been deactivated by CT_BottomBar.
		-- We will handle it.
	elseif (CT_BottomBar) then
		-- This version of CT_BottomBar does not support deactivation of this bar.
		-- Let CT_BottomBar handle it.
		return false;
	end
	-- We will handle shifting of this bar.
	return true;
end

local stanceIsShifted;

local function CT_BarMod_Shift_Stance_GetShiftOption()
	return (module:getOption("shiftShapeshift") ~= false);
end

local function CT_BarMod_Shift_Stance_UpdateTextures()
	if (not CT_BarMod_Shift_Stance_areWeShifting()) then
		return;
	end

	local shift = CT_BarMod_Shift_Stance_GetShiftOption();
	if (shift) then
		StanceBarLeft:Hide();
		StanceBarRight:Hide();
		StanceBarMiddle:Hide();
		for i=1, NUM_STANCE_SLOTS do
			_G["StanceButton"..i]:GetNormalTexture():SetWidth(52);
			_G["StanceButton"..i]:GetNormalTexture():SetHeight(52);
		end
	else
		if (stanceIsShifted) then
			if ( MultiBarBottomLeft:IsShown() ) then
				if ( StanceBarFrame ) then
					StanceBarLeft:Hide();
					StanceBarRight:Hide();
					StanceBarMiddle:Hide();
					for i=1, NUM_STANCE_SLOTS do
						_G["StanceButton"..i]:GetNormalTexture():SetWidth(52);
						_G["StanceButton"..i]:GetNormalTexture():SetHeight(52);
					end
				end
			else
				if ( StanceBarFrame ) then
					if ( GetNumShapeshiftForms() > 2 ) then
						StanceBarMiddle:Show();
					end
					StanceBarLeft:Show();
					StanceBarRight:Show();
					for i=1, NUM_STANCE_SLOTS do
						_G["StanceButton"..i]:GetNormalTexture():SetWidth(64);
						_G["StanceButton"..i]:GetNormalTexture():SetHeight(64);
					end
				end
			end
		else
			return;
		end
	end
end

function CT_BarMod_Shift_Stance_UpdatePositions()
	if (not CT_BarMod_Shift_Stance_areWeShifting()) then
		return;
	end

	CT_BarMod_Shift_Stance_UpdateTextures();

	if (InCombatLockdown()) then
		return;
	end

	local frame;
	local shift = CT_BarMod_Shift_Stance_GetShiftOption();

	if (shift) then
		local frame1, frame2;
		frame1 = CT_BarMod_StanceBarFrame;
		frame2 = StanceBarFrame;

		frame1:SetHeight(frame2:GetHeight());
		frame1:SetWidth(frame2:GetWidth());
		frame1:ClearAllPoints();
		frame1:SetPoint("BOTTOMLEFT", frame2, "TOPLEFT", 0, 13)

		frame2:EnableMouse(false);

		stanceIsShifted = true;
		frame = frame1;
	else
		if (stanceIsShifted) then
			local frame2 = StanceBarFrame;

			frame2:EnableMouse(true);

			stanceIsShifted = false;
			frame = frame2;
		else
			return;
		end
	end

	local xoffset;
	if (GetNumShapeshiftForms() == 1) then
		xoffset = 12;  -- 12 as seen in StanceBar_Update() in StanceBar.lua
	else
		xoffset = 10;
	end

	frameClearAllPoints(StanceButton1);
	frameSetPoint(StanceButton1, "BOTTOMLEFT", frame, xoffset, 3);

	local obj;
	for i = 2, 10, 1 do
		obj = _G["StanceButton"..i];
		frameClearAllPoints(obj);
		if (i == 2) then
			xoffset = 8;  -- 8 as seen in StanceBar.xml
		else
			xoffset = 7;
		end
		frameSetPoint(obj, "LEFT", _G["StanceButton"..(i-1)], "RIGHT", xoffset, 0);
	end
end

local function CT_BarMod_Shift_Stance_SetPoint(self, ap, rt, rp, x, y)
	-- (hook) This is a post hook of the .SetPoint and .SetAllPoints functions
	CT_BarMod_Shift_Stance_UpdatePositions();
end

local function CT_BarMod_Shift_Stance_Update()
	-- (hook) This is a post hook of the StanceBar_Update function in StanceBar.lua
	--
	-- Blizzard's StanceBar_Update function gets called:
	-- a) from StanceBar_OnEvent in StanceBar.lua for the event UPDATE_SHAPESHIFT_COOLDOWN
	-- b) from ActionBarController_OnEvent in ActionBarController.lua for the events
	--    UPDATE_SHAPESHIFT_FORM, UPDATE_SHAPESHIFT_FORMS, UPDATE_SHAPESHIFT_USABLE,
	--    UPDATE_POSSESS_BAR
	-- c) from ActionBarController_UpdateAll in ActionBarController.lua.
	-- Blizzard calls UIParent_ManageFramePositions at the end of StanceBar_Update if
	-- it determines that it needs to call it.

	-- Blizzard's function re-anchors StanceButton1 when the player has only 1 shapeshift form.
	-- We have to undo their anchor and re-establish our own.
	-- If we are in combat when Blizzard does it, then there is nothing we can do about it,
	-- since the button is protected.
	CT_BarMod_Shift_Stance_UpdatePositions();
end

local function CT_BarMod_Shift_Stance_Init()
	local frame1, frame2;

	-- Our frame for the class action buttons
	frame1 = CreateFrame("Frame", "CT_BarMod_StanceBarFrame");  -- formerly "CT_BarMod_ShapeshiftBarFrame" prior to WoW 5.0
	frame2 = StanceBarFrame;

	frame1:SetParent(UIParent);
	frame1:EnableMouse(false);
	frame1:SetHeight(frame2:GetHeight());
	frame1:SetWidth(frame2:GetWidth());
	frame1:SetPoint("BOTTOMLEFT", frame2, "TOPLEFT", 0, 0)
	frame1:SetAlpha(1);
	frame1:Hide();

	for i = 1, 10 do
		hooksecurefunc(_G["StanceButton" .. i], "SetPoint", CT_BarMod_Shift_Stance_SetPoint);
		hooksecurefunc(_G["StanceButton" .. i], "SetAllPoints", CT_BarMod_Shift_Stance_SetPoint);
	end

	hooksecurefunc("StanceBar_Update", CT_BarMod_Shift_Stance_Update);

	CT_BarMod_Shift_Stance_UpdatePositions();
end

-------------------------------
-- UIParent_ManageFramePositions

local function CT_BarMod_Shift_UIParent_ManageFramePositions()
	-- (hook) This is called after Blizzard's UIParent_ManageFramePositions function in UIParent.lua.
	-- removed from game in 2012 -- CT_BarMod_Shift_MultiCast_UpdateTextures();
	CT_BarMod_Shift_Pet_UpdateTextures();
	CT_BarMod_Shift_Possess_UpdateTextures();
	CT_BarMod_Shift_Stance_UpdateTextures();
end

-------------------------------
-- OnEvent

local function CT_BarMod_Shift_OnEvent(self, event, arg1, ...)

	if (event == "PLAYER_ENTERING_WORLD" or event == "PLAYER_LOGIN") then
		-- Set flags so we will shift the party and focus frames if needed.
		CT_BarMod_Shift_Party_SetFlag();
		CT_BarMod_Shift_Focus_SetFlag();
	end

	if (event == "PLAYER_LOGIN") then
		-- When CT_BottomBar is loaded we don't want CT_BarMod to reposition
		-- the multicast, pet, possess, and class bars if the bar is activated
		-- in CT_BottomBar.

		--[[ removed from game in 2012
		-- If CT_BottomBar is not loaded, or if it supports deactivation of this bar...
		if ((not CT_BottomBar) or (CT_BottomBar and CT_BottomBar.ctMultiCast)) then
			CT_BarMod_Shift_MultiCast_Init();
		end --]]

		-- If CT_BottomBar is not loaded, or if it supports deactivation of this bar...
		if ((not CT_BottomBar) or (CT_BottomBar and CT_BottomBar.ctPetBar)) then
			CT_BarMod_Shift_Pet_Init();
		end

		-- If CT_BottomBar is not loaded, or if it supports deactivation of this bar...
		if ((not CT_BottomBar) or (CT_BottomBar and CT_BottomBar.ctPossess)) then
			CT_BarMod_Shift_Possess_Init();
		end

		-- If CT_BottomBar is not loaded, or if it supports deactivation of this bar...
		if ((not CT_BottomBar) or (CT_BottomBar and CT_BottomBar.ctClassBar)) then
			CT_BarMod_Shift_Stance_Init();
		end

		-- We need to hook the UIParent_ManageFramePositions function since it
		-- may hide/show some textures.
		hooksecurefunc("UIParent_ManageFramePositions", CT_BarMod_Shift_UIParent_ManageFramePositions);

		-- Since Blizzard uses the "function=" syntax in their xml scripts to
		-- call UIParent_ManageFramePositions, we will have to hook all scripts
		-- that do this. This is necessary because scripts using this syntax don't
		-- call post hooks of functions created using hooksecurefunc().
		-- 	<OnShow function="UIParent_ManageFramePositions"/>
		-- 	<OnHide function="UIParent_ManageFramePositions"/>

		StanceBarFrame:HookScript("OnShow", CT_BarMod_Shift_UIParent_ManageFramePositions);
		StanceBarFrame:HookScript("OnHide", CT_BarMod_Shift_UIParent_ManageFramePositions);

		DurabilityFrame:HookScript("OnShow", CT_BarMod_Shift_UIParent_ManageFramePositions);
		DurabilityFrame:HookScript("OnHide", CT_BarMod_Shift_UIParent_ManageFramePositions);
		
		PetActionBarFrame:HookScript("OnShow", CT_BarMod_Shift_UIParent_ManageFramePositions);
		PetActionBarFrame:HookScript("OnHide", CT_BarMod_Shift_UIParent_ManageFramePositions);

		if (PossessBarFrame) then
			PossessBarFrame:HookScript("OnShow", CT_BarMod_Shift_UIParent_ManageFramePositions);
			PossessBarFrame:HookScript("OnHide", CT_BarMod_Shift_UIParent_ManageFramePositions);		
		end
		
		if (MultiCastActionBarFrame) then
			MultiCastActionBarFrame:HookScript("OnShow", CT_BarMod_Shift_UIParent_ManageFramePositions);
			MultiCastActionBarFrame:HookScript("OnHide", CT_BarMod_Shift_UIParent_ManageFramePositions);
		end
		
		if (module:getGameVersion() <= 7) then
			-- Classic
			ReputationWatchBar:HookScript("OnHide", CT_BarMod_Shift_UIParent_ManageFramePositions);
			MainMenuBarMaxLevelBar:HookScript("OnShow", CT_BarMod_Shift_UIParent_ManageFramePositions);
			MainMenuBarMaxLevelBar:HookScript("OnHide", CT_BarMod_Shift_UIParent_ManageFramePositions);
		end
	end

	if (event == "PLAYER_REGEN_ENABLED" or event == "PLAYER_ENTERING_WORLD") then
		-- Shift the part and focus frames if needed.
		if (shiftParty) then
			CT_BarMod_Shift_Party_Move();
		end
		if (shiftFocus) then
			CT_BarMod_Shift_Focus_Move();
		end

		-- Ensure everything is where it should be.
		CT_BarMod_Shift_UpdatePositions();

	elseif (event == "PLAYER_REGEN_DISABLED") then
		-- Ensure everything is where it should be.
		CT_BarMod_Shift_UpdatePositions();

	end
end

-------------------------------
-- Miscellaneous

function CT_BarMod_Shift_UpdatePositions()
	-- removed in 2012 -- CT_BarMod_Shift_MultiCast_UpdatePositions();
	CT_BarMod_Shift_Pet_UpdatePositions();
	CT_BarMod_Shift_Possess_UpdatePositions();
	CT_BarMod_Shift_Stance_UpdatePositions();
end

function CT_BarMod_Shift_ResetPositions()
	CT_BarMod_Shift_UpdatePositions();
end

function CT_BarMod_Shift_Init()
	-- Frame to watch for events
	local frame = CreateFrame("Frame", "CT_BarMod_Shift_EventFrame");

	frameSetPoint = frame.SetPoint;
	frameClearAllPoints = frame.ClearAllPoints;

	frame:SetScript("OnEvent", CT_BarMod_Shift_OnEvent);

	frame:RegisterEvent("PLAYER_REGEN_ENABLED");
	frame:RegisterEvent("PLAYER_REGEN_DISABLED");
	frame:RegisterEvent("PLAYER_LOGIN");
	frame:RegisterEvent("PLAYER_ENTERING_WORLD");

	frame:Show();

	-- Finish initializing in the PLAYER_LOGIN and PLAYER_ENTERING_WORLD events,
	-- so that we can be sure if CT_BottomBar is loaded or not (it will load
	-- after CT_BarMod).
end

-- CT_BottomBar 4.008 and greater use these:
-- removed in 2012 -- module.CT_BarMod_Shift_MultiCast_UpdatePositions = CT_BarMod_Shift_MultiCast_UpdatePositions;
module.CT_BarMod_Shift_Pet_UpdatePositions = CT_BarMod_Shift_Pet_UpdatePositions;
module.CT_BarMod_Shift_Possess_UpdatePositions = CT_BarMod_Shift_Possess_UpdatePositions;
module.CT_BarMod_Shift_Stance_UpdatePositions = CT_BarMod_Shift_Stance_UpdatePositions;
