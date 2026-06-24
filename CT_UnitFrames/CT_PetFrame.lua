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

local module = select(2, ...)

local function CT_PetFrame_HealthTextStatusBar_UpdateTextString(bar)
	if (CT_UnitFramesOptions) then
		module:UpdateStatusBarTextString(bar, CT_UnitFramesOptions.styles[6][1])
		CT_UnitFrames_HealthBar_OnValueChanged(bar, tonumber(bar:GetValue()), not CT_UnitFramesOptions.oneColorHealth)
		module:UpdateBesideBarTextString(bar, CT_UnitFramesOptions.styles[6][2], CT_PetHealthRight)
	end
end

local function CT_PetFrame_ManaTextStatusBar_UpdateTextString(bar)
	if (CT_UnitFramesOptions) then
		module:UpdateStatusBarTextString(bar, CT_UnitFramesOptions.styles[6][3])
		module:UpdateBesideBarTextString(bar, CT_UnitFramesOptions.styles[6][4], CT_PetManaRight)
	end
end

module:regEvent("PLAYER_LOGIN", function()
	-- See CT_PartyFrame.lua
	PetFrameHealthBar.ctFont = CT_UnitFrames_PetStatusBarText
	PetFrameManaBar.ctFont = CT_UnitFrames_PetStatusBarText
	PetFrameManaBar.ctOffset = -1.5
	
	PetFrameHealthBar:HookScript("OnEnter", CT_PetFrame_HealthTextStatusBar_UpdateTextString)
	PetFrameHealthBar:HookScript("OnLeave", CT_PetFrame_HealthTextStatusBar_UpdateTextString)
	PetFrameHealthBar:HookScript("OnValueChanged", CT_PetFrame_HealthTextStatusBar_UpdateTextString)
	PetFrameManaBar:HookScript("OnEnter", CT_PetFrame_ManaTextStatusBar_UpdateTextString)
	PetFrameManaBar:HookScript("OnLeave", CT_PetFrame_ManaTextStatusBar_UpdateTextString)
	PetFrameManaBar:HookScript("OnValueChanged", CT_PetFrame_ManaTextStatusBar_UpdateTextString)
	
	-- incoming heals on classic
	if (UnitGetTotalAbsorbs == nil) then
		module:addClassicIncomingHeals(PetFrame)
	end
end)

function module:ShowPetFrameBarText()
	CT_PetFrame_HealthTextStatusBar_UpdateTextString(PetFrameHealthBar)
	CT_PetFrame_ManaTextStatusBar_UpdateTextString(PetFrameManaBar)
end

function module:AnchorPetFrameSideText()
	local xoff = CT_UnitFramesOptions.petTextSpacing or GetPetHappiness and 50 or 0
	CT_PetHealthRight:ClearAllPoints()
	CT_PetHealthRight:SetPoint("LEFT", PetFrame, "TOPRIGHT", 3 + xoff, -25)
	CT_PetManaRight:ClearAllPoints()
	CT_PetManaRight:SetPoint("LEFT", PetFrame, "TOPRIGHT", 3 + xoff, -35)
end

function CT_PetFrameSlider_OnLoad(self)
	_G[self:GetName().."Text"]:SetText(CT_UFO_PARTYTEXTSIZE)
	_G[self:GetName().."High"]:SetText(CT_UFO_PARTYTEXTSIZE_LARGE)
	_G[self:GetName().."Low"]:SetText(CT_UFO_PARTYTEXTSIZE_SMALL)
	self:SetMinMaxValues(1, 5)
	self:SetValueStep(0.5)
	self:SetObeyStepOnDrag(true)
	self.tooltipText = "Allows you to change the text size of the pet health & mana texts."
end