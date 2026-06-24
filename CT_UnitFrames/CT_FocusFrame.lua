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
-- This is a modified version of Blizzard's TargetFrame
-- (originally based on the 3.2 source, adapted since)
-- plus some additional functions.
-- This file displays focus, and focustarget frames.

local unit1 = "focus";
local unit2 = "focustarget";

-- MAX_COMBO_POINTS = 5;
-- MAX_TARGET_DEBUFFS = 16;
-- MAX_TARGET_BUFFS = 32;

-- aura positioning constants
local AURA_START_X = 5;
local AURA_START_Y = 32;
local AURA_OFFSET_Y = 3;
local LARGE_AURA_SIZE = 21;
local SMALL_AURA_SIZE = 17;
local AURA_ROW_WIDTH = 122;
local TOT_AURA_ROW_WIDTH = 101;
local NUM_TOT_AURA_ROWS = 2;

local PLAYER_UNITS = {
	player = true,
	vehicle = true,
	pet = true,
};

function CT_FocusFrame_OnLoad(self)

	-- self == The main unit frame
	self.noTextPrefix = true;
	self.showLevel = true;
	self.showPVP = true;
	self.showLeader = false;
	self.showThreat = true;
	self.showPortrait = true;
	self.showClassification = true;
	self.showAuraCount = true;
--	self:SetHitRectInsets(96, 40, 10, 9);		-- allows mouseover over health and mana bars

	self.statusCounter = 0;
	self.statusSign = -1;
	self.unitHPPercent = 1;

	local thisName = self:GetName();
	self.borderTexture = _G[thisName.."TextureFrameTexture"];
	self.highLevelTexture = _G[thisName.."TextureFrameHighLevelTexture"];
	self.pvpIcon = _G[thisName.."TextureFramePVPIcon"];
	self.prestigePortrait = _G[thisName.."TextureFramePrestigePortrait"];
	self.prestigeBadge = _G[thisName.."TextureFramePrestigeBadge"];
	self.leaderIcon = _G[thisName.."TextureFrameLeaderIcon"];
	self.raidTargetIcon = _G[thisName.."TextureFrameRaidTargetIcon"];
	self.questIcon = UnitIsQuestBoss and _G[thisName.."TextureFrameQuestIcon"];		-- Cataclysm
	self.levelText = _G[thisName.."TextureFrameLevelText"];
	self.deadText = _G[thisName.."TextureFrameDeadText"];
	self.petBattleIcon = PetBattleFrame and _G[thisName.."TextureFramePetBattleIcon"];	-- Retail
	self.TOT_AURA_ROW_WIDTH = TOT_AURA_ROW_WIDTH;
	-- set simple frame
	if ( not self.showLevel ) then
		self.highLevelTexture:Hide();
		self.levelText:Hide();
	end
	-- set threat frame
	local threatFrame;
	if ( self.showThreat ) then
		threatFrame = _G[thisName.."Flash"];
	end
	-- set portrait frame
	local portraitFrame;
	if ( self.showPortrait ) then
		portraitFrame = _G[thisName.."Portrait"];
	end
	
	local args =
		module:getGameVersion() >= 10 and {
			unit1,
			_G[thisName.."TextureFrameName"],
			"Target", -- WoW 10.x frameType
			portraitFrame,
			_G[thisName.."HealthBar"],
			_G[thisName.."TextureFrameHealthBarText"],
			_G[thisName.."ManaBar"],
			_G[thisName.."TextureFrameManaBarText"],
			threatFrame,
			"player",
			_G[thisName.."NumericalThreat"],
			_G[thisName.."MyHealPredictionBar"],
			_G[thisName.."OtherHealPredictionBar"],
			_G[thisName.."TotalAbsorbBar"],
			_G[thisName.."TotalAbsorbBarOverlay"],
			_G[thisName.."TextureFrameOverAbsorbGlow"],
			_G[thisName.."TextureFrameOverHealAbsorbGlow"],
			_G[thisName.."HealAbsorbBar"],
			_G[thisName.."HealAbsorbBarLeftShadow"],
			_G[thisName.."HealAbsorbBarRightShadow"],	
		}
		or {
			unit1,
			_G[thisName.."TextureFrameName"],
			-- in WoW 10.x, this is where the frameType goes
			portraitFrame,
			_G[thisName.."HealthBar"],
			_G[thisName.."TextureFrameHealthBarText"],
			_G[thisName.."ManaBar"],
			_G[thisName.."TextureFrameManaBarText"],
			threatFrame,
			"player",
			_G[thisName.."NumericalThreat"],
			UnitGetTotalAbsorbs and _G[thisName.."MyHealPredictionBar"] or _G[thisName.."MyHealPredictionBar"]:Hide() and nil,		-- classic compatibility
			UnitGetTotalAbsorbs and _G[thisName.."OtherHealPredictionBar"] or _G[thisName.."OtherHealPredictionBar"]:Hide() and nil,
			UnitGetTotalAbsorbs and _G[thisName.."TotalAbsorbBar"] or _G[thisName.."TotalAbsorbBar"]:Hide() and nil,
			UnitGetTotalAbsorbs and _G[thisName.."TotalAbsorbBarOverlay"] or _G[thisName.."TotalAbsorbBarOverlay"]:Hide() and nil,
			UnitGetTotalAbsorbs and _G[thisName.."TextureFrameOverAbsorbGlow"] or _G[thisName.."TextureFrameOverAbsorbGlow"]:Hide() and nil,
			UnitGetTotalHealAbsorbs and _G[thisName.."TextureFrameOverHealAbsorbGlow"] or _G[thisName.."TextureFrameOverHealAbsorbGlow"]:Hide() and nil,
			UnitGetTotalHealAbsorbs and _G[thisName.."HealAbsorbBar"] or _G[thisName.."HealAbsorbBar"]:Hide() and nil,
			UnitGetTotalHealAbsorbs and _G[thisName.."HealAbsorbBarLeftShadow"] or _G[thisName.."HealAbsorbBarLeftShadow"]:Hide() and nil,
			UnitGetTotalHealAbsorbs and _G[thisName.."HealAbsorbBarRightShadow"] or _G[thisName.."HealAbsorbBarRightShadow"]:Hide() and nil,
		}
		
	UnitFrame_Initialize(self, unpack(args));

	-- incoming heals on classic
	if (UnitGetTotalAbsorbs == nil) then
		module:addClassicIncomingHeals(self)
	end

	self.noTextPrefix = true;
	CT_FocusFrame_Update(self);

	self:RegisterEvent("PLAYER_ENTERING_WORLD");
	self:RegisterEvent("PLAYER_FOCUS_CHANGED");
	self:RegisterUnitEvent("UNIT_HEALTH", unit1);
	self:RegisterUnitEvent("UNIT_MAXHEALTH", unit1)
	if ( self.showLevel ) then
		self:RegisterUnitEvent("UNIT_LEVEL", unit1);
	end
	self:RegisterUnitEvent("UNIT_FACTION", unit1, "player");
	if ( self.showClassification ) then
		self:RegisterUnitEvent("UNIT_CLASSIFICATION_CHANGED", unit1);
	end
	self:RegisterUnitEvent("UNIT_AURA", unit1);
	if ( self.showLeader ) then
		self:RegisterUnitEvent("PLAYER_FLAGS_CHANGED", unit1);
	end
	self:RegisterUnitEvent("UNIT_TARGET", unit1);
	self:RegisterEvent("GROUP_ROSTER_UPDATE");
	self:RegisterEvent("RAID_TARGET_UPDATE");
	self:RegisterEvent("PLAYER_REGEN_ENABLED");
	self:RegisterEvent("PLAYER_REGEN_DISABLED");

	local frameLevel = _G[thisName.."TextureFrame"]:GetFrameLevel();
--	self.healthbar:SetFrameLevel(frameLevel-1);
--	self.manabar:SetFrameLevel(frameLevel-1);
	self.spellbar:SetFrameLevel(frameLevel-1);

--	local showmenu = function()
--		ToggleDropDownMenu(1, nil, _G[thisName.."DropDown"], thisName, 120, 10);
--	end
--	SecureUnitButton_OnLoad(self, self.unit, showmenu);
	SecureUnitButton_OnLoad(self, self.unit);

	self:SetAttribute("type", "target");
	self:SetAttribute("unit", self.unit);
	RegisterUnitWatch(self);

	self.healthbar:SetScript("OnLeave",
		function()
			GameTooltip:Hide();
		end
	);
	self.manabar:SetScript("OnLeave",
		function()
			GameTooltip:Hide();
		end
	);

	ClickCastFrames = ClickCastFrames or { };
	ClickCastFrames[self] = true;

	-- Set alpha of heal prediction bars to 0 so that they do not
	-- briefly appear as full length bars when our frame is
	-- initially shown. We'll restore one frame after the OnShow script
	if (self.myHealPredictionBar) then
		-- Retail
		self.myHealPredictionBar:SetAlpha(0);
		self.otherHealPredictionBar:SetAlpha(0);
	end
end

function CT_FocusFrame_Update(self)
	-- self == The main unit frame

	-- This check is here so the frame will hide when the focus goes away
	-- even if some of the functions below are hooked by addons.
	if ( UnitExists(self.unit) ) then

		-- Moved here to avoid taint from functions below
		if ( self.totFrame ) then
			CT_TargetofFocus_Update(self.totFrame);
		end

		UnitFrame_Update(self);
		if ( self.showLevel ) then
			CT_FocusFrame_CheckLevel(self);
		end
		CT_FocusFrame_CheckFaction(self);
		if ( self.showClassification ) then
			CT_FocusFrame_CheckClassification(self);
		end
		CT_FocusFrame_CheckDead(self);
		if ( self.showLeader ) then
			if ( UnitLeadsAnyGroup(self.unit) ) then
				if ( HasLFGRestrictions() ) then
					self.leaderIcon:SetTexture("Interface\\LFGFrame\\UI-LFG-ICON-PORTRAITROLES");
					self.leaderIcon:SetTexCoord(0, 0.296875, 0.015625, 0.3125);
				else
					self.leaderIcon:SetTexture("Interface\\GroupFrame\\UI-Group-LeaderIcon");
					self.leaderIcon:SetTexCoord(0, 1, 0, 1);
				end
				self.leaderIcon:Show();
			else
				self.leaderIcon:Hide();
			end
		end
		CT_FocusFrame_UpdateAuras(self);
		if ( self.petBattleIcon ) then
			CT_FocusFrame_CheckBattlePet(self);
			self.petBattleIcon:SetAlpha(1.0);
		end
		CT_FocusHealthCheck(self.healthbar);
	end
end

function CT_FocusFrame_OnEvent(self, event, arg1, ...)
	-- self == The main unit frame

	if (arg1 == "focus") then
		UnitFrame_OnEvent(self, event, "focus")
	elseif (type(arg1) == "string" and UnitIsUnit(arg1, "focus")) then
		-- happens when you focus yourself, or when your focus targets themself
		UnitFrame_OnEvent(self, event, "focus")
		if (event == "UNIT_HEALTH" or event == "UNIT_MAXHEALTH") then
			UnitFrameHealthBar_OnEvent(self.healthbar, event, "focus")
		end
	end	

	if ( event == "PLAYER_ENTERING_WORLD" ) then
		if (CT_UnitFramesOptions.shallDisplayFocus) then
			RegisterUnitWatch(self);
		else
			UnregisterUnitWatch(self);
			self:Hide();
		end
		if (CT_UnitFramesOptions.shallDisplayTargetofFocus) then
			RegisterUnitWatch(self.totFrame);
		else
			UnregisterUnitWatch(self.totFrame);
			self.totFrame:Hide();
		end
		if (not InCombatLockdown()) then
			CT_UnitFrames_ResetDragLink(_G[self:GetName().."_Drag"]);
		end
		CT_FocusFrame_Update(self);

	elseif ( event == "PLAYER_FOCUS_CHANGED" ) then
		-- Moved here to avoid taint from functions below
		CT_FocusFrame_Update(self);
		CT_FocusFrame_UpdateRaidTargetIcon(self);
--		CloseDropDownMenus();

--		if ( UnitExists(self.unit) ) then
--			if ( UnitIsEnemy(self.unit, "player") ) then
--				PlaySound(873);
--			elseif ( UnitIsFriend("player", self.unit) ) then
--				PlaySound(867);
--			else
--				PlaySound(871);
--			end
--		end

	elseif ( event == "UNIT_HEALTH" ) then
		--if ( arg1 == self.unit ) then
			CT_FocusFrame_CheckDead(self);
			CT_FocusHealthCheck(self.healthbar);
		--end

	elseif ( event == "UNIT_LEVEL" ) then
		--if ( arg1 == self.unit ) then
			CT_FocusFrame_CheckLevel(self);
		--end

	elseif ( event == "UNIT_FACTION" ) then
		CT_FocusFrame_CheckFaction(self);
		if ( self.showLevel ) then
			CT_FocusFrame_CheckLevel(self);
		end

	elseif ( event == "UNIT_CLASSIFICATION_CHANGED" ) then
		if ( arg1 == self.unit ) then
			CT_FocusFrame_CheckClassification(self);
		end

	elseif ( event == "UNIT_AURA" ) then
		--if ( arg1 == self.unit ) then
			CT_FocusFrame_UpdateAuras(self);
		--end

	elseif ( event == "PLAYER_FLAGS_CHANGED" ) then
		--if ( arg1 == self.unit and self.showLeader ) then
			if ( UnitLeadsAnyGroup(self.unit) ) then
				self.leaderIcon:Show();
			else
				self.leaderIcon:Hide();
			end
		--end

	elseif ( event == "GROUP_ROSTER_UPDATE" ) then
		if ( self.totFrame ) then
			CT_TargetofFocus_Update(self.totFrame);
		end
		CT_FocusFrame_CheckFaction(self);
		CT_FocusFrame_Update(self);

	elseif ( event == "RAID_TARGET_UPDATE" ) then
		CT_FocusFrame_UpdateRaidTargetIcon(self);

	elseif ( event == "PLAYER_REGEN_ENABLED" ) then
		if (CT_UnitFramesOptions.shallDisplayFocus) then
			RegisterUnitWatch(self);
		else
			UnregisterUnitWatch(self);
		end
		if (CT_UnitFramesOptions.shallDisplayTargetofFocus) then
			RegisterUnitWatch(self.totFrame);
		else
			UnregisterUnitWatch(self.totFrame);
		end
		CT_UnitFrames_ResetDragLink(_G[self:GetName().."_Drag"]);

	elseif ( event == "PLAYER_REGEN_DISABLED" ) then
		if (CT_UnitFramesOptions.shallDisplayFocus) then
			RegisterUnitWatch(self);
		else
			UnregisterUnitWatch(self);
		end
		if (CT_UnitFramesOptions.shallDisplayTargetofFocus) then
			RegisterUnitWatch(self.totFrame);
		else
			UnregisterUnitWatch(self.totFrame);
		end
		CT_UnitFrames_ResetDragLink(_G[self:GetName().."_Drag"]);
	elseif (event == "UNIT_TARGET") then
		CT_FocusFrame_Update(self)
	end
end

function CT_FocusFrame_OnShow(self)
	-- self == The main unit frame
	
	if (self.myHealPredictionBar) then
		C_Timer.After(0.01, function()
			self.myHealPredictionBar:SetAlpha(1);
			self.otherHealPredictionBar:SetAlpha(1);
		end);
	end

	-- self.ctUpdateTicker = self.ctUpdateTicker or C_Timer.NewTicker(0.1, function() CT_FocusFrame_Update(self) end);	
	if (UnitFrame_UpdateThreatIndicator) then
		self.ctThreatTicker = self.ctThreatTicker or C_Timer.NewTicker(0.5, function() UnitFrame_UpdateThreatIndicator(self.threatIndicator, self.threatNumericIndicator, self.feedbackUnit); end);
	end
end

function CT_FocusFrame_OnHide(self)
	-- self == The main unit frame
	if (self.ctUpdateTicker) then
		self.ctUpdateTicker:Cancel();
		self.ctUpdateTicker = nil;
	end
	if (self.ctThreatTicker) then
		self.ctThreatTicker:Cancel();
		self.ctThreatTicker = nil;
	end

--	PlaySound(684);
--	CloseDropDownMenus();
end

function CT_FocusFrame_CheckLevel(self)
	-- self == The main unit frame
	local focusLevel = UnitLevel(self.unit);

	if ( UnitIsCorpse(self.unit) ) then
		self.levelText:Hide();
		self.highLevelTexture:Show();
	elseif ( self.petBattleIcon and (UnitIsWildBattlePet(self.unit) or UnitIsBattlePetCompanion(self.unit)) ) then
		local petLevel = UnitBattlePetLevel(self.unit);
		self.levelText:SetVertexColor(1.0, 0.82, 0.0);
		self.levelText:SetText( petLevel );
		self.levelText:Show();
		self.highLevelTexture:Hide();
	elseif ( focusLevel > 0 ) then
		-- Normal level focus
		self.levelText:SetText(focusLevel);
		-- Color level number
		if ( UnitCanAttack("player", self.unit) ) then
			local color = GetQuestDifficultyColor(focusLevel);
			self.levelText:SetVertexColor(color.r, color.g, color.b);
		else
			self.levelText:SetVertexColor(1.0, 0.82, 0.0);
		end
		self.levelText:Show();
		self.highLevelTexture:Hide();
	else
		-- Focus is too high level to tell
		self.levelText:Hide();
		self.highLevelTexture:Show();
	end
end

function CT_FocusFrame_CheckFaction(self)
	-- self == The main unit frame
	if ( not UnitPlayerControlled(self.unit) and UnitIsTapDenied(self.unit) ) then
		self.nameBackground:SetVertexColor(0.5, 0.5, 0.5);
		if ( self.portrait and not self.ctPortraitTicker ) then
			self.portrait:SetVertexColor(0.5, 0.5, 0.5);
		end
	else
		self.nameBackground:SetVertexColor(UnitSelectionColor(self.unit));
		if ( self.portrait and not self.ctPortraitTicker ) then
			self.portrait:SetVertexColor(1.0, 1.0, 1.0);
		end
	end

	if ( self.showPVP ) then
		local factionGroup = UnitFactionGroup(self.unit);
		if ( UnitIsPVPFreeForAll(self.unit) ) then
			local honorLevel = UnitHonorLevel and UnitHonorLevel(self.unit);
			local honorRewardInfo = honorLevel and C_PvP.GetHonorRewardInfo and C_PvP.GetHonorRewardInfo(honorLevel);
			if (honorRewardInfo) then
				self.prestigePortrait:SetAtlas("honorsystem-portrait-neutral", false);
				self.prestigeBadge:SetTexture(honorRewardInfo.badgeFileDataID);
				self.prestigePortrait:Show();
				self.prestigeBadge:Show();
				self.pvpIcon:Hide();
			else
				self.prestigePortrait:Hide();
				self.prestigeBadge:Hide();
				self.pvpIcon:SetTexture("Interface\\TargetingFrame\\UI-PVP-FFA");
				self.pvpIcon:Show();
			end
		elseif ( factionGroup and factionGroup ~= "Neutral" and UnitIsPVP(self.unit) ) then
			local honorLevel = UnitHonorLevel and UnitHonorLevel(self.unit);
			local honorRewardInfo = honorLevel and C_PvP.GetHonorRewardInfo and C_PvP.GetHonorRewardInfo(honorLevel);
			if (honorRewardInfo) then
				self.prestigePortrait:SetAtlas("honorsystem-portrait-"..factionGroup, false);
				self.prestigeBadge:SetTexture(honorRewardInfo.badgeFileDataID);
				self.prestigePortrait:Show();
				self.prestigeBadge:Show();
				self.pvpIcon:Hide();
			else
				self.prestigePortrait:Hide();
				self.prestigeBadge:Hide();
				self.pvpIcon:SetTexture("Interface\\TargetingFrame\\UI-PVP-"..factionGroup);
				self.pvpIcon:Show();
			end		
		else
			self.prestigePortrait:Hide();
			self.prestigeBadge:Hide();
			self.pvpIcon:Hide();
		end
	end
end

function CT_FocusFrame_CheckBattlePet(self)
	-- self == The main unit frame
	if ( UnitIsWildBattlePet(self.unit) or UnitIsBattlePetCompanion(self.unit) ) then
		local petType = UnitBattlePetType(self.unit);
		self.petBattleIcon:SetTexture("Interface\\TargetingFrame\\PetBadge-"..PET_TYPE_SUFFIX[petType]);
		self.petBattleIcon:Show();
	else
		self.petBattleIcon:Hide();
	end
end

function CT_FocusFrame_CheckClassification(self, forceNormalTexture)
	-- self == The main unit frame
	local classification = UnitClassification(self.unit);
	self.nameBackground:Show();
	self.manabar:Show();
	self.manabar.TextString:Show();
--	self.threatIndicator:SetTexture("Interface\\TargetingFrame\\UI-TargetingFrame-Flash");

	if ( forceNormalTexture ) then
		self.borderTexture:SetTexture("Interface\\TargetingFrame\\UI-TargetingFrame");
	elseif ( classification == "minus" ) then
		self.borderTexture:SetTexture("Interface\\TargetingFrame\\UI-TargetingFrame-Minus");
		self.nameBackground:Hide();
		self.manabar:Hide();
		self.manabar.TextString:Hide();
		forceNormalTexture = true;
	elseif ( classification == "worldboss" or classification == "elite" ) then
		self.borderTexture:SetTexture("Interface\\TargetingFrame\\UI-TargetingFrame-Elite");
	elseif ( classification == "rareelite" ) then
		self.borderTexture:SetTexture("Interface\\TargetingFrame\\UI-TargetingFrame-Rare-Elite");
	elseif ( classification == "rare" ) then
		self.borderTexture:SetTexture("Interface\\TargetingFrame\\UI-TargetingFrame-Rare");
	else
		self.borderTexture:SetTexture("Interface\\TargetingFrame\\UI-TargetingFrame");
		forceNormalTexture = true;
	end

	if ( forceNormalTexture ) then
		self.haveElite = nil;
		if ( classification == "minus" ) then
			self.Background:SetSize(119,12);
			self.Background:SetPoint("BOTTOMLEFT", self, "BOTTOMLEFT", 7, 47);
		else
			self.Background:SetSize(119,25);
			self.Background:SetPoint("BOTTOMLEFT", self, "BOTTOMLEFT", 7, 35);
		end
--		if ( self.threatIndicator ) then
--			if ( classification == "minus" ) then
--				self.threatIndicator:SetTexture("Interface\\TargetingFrame\\UI-TargetingFrame-Minus-Flash");
--				self.threatIndicator:SetTexCoord(0, 1, 0, 1);
--				self.threatIndicator:SetWidth(256);
--				self.threatIndicator:SetHeight(128);
--				self.threatIndicator:SetPoint("TOPLEFT", self, "TOPLEFT", -24, 0);
--			else
--				self.threatIndicator:SetTexCoord(0, 0.9453125, 0, 0.181640625);
--				self.threatIndicator:SetWidth(242);
--				self.threatIndicator:SetHeight(93);
--				self.threatIndicator:SetPoint("TOPLEFT", self, "TOPLEFT", -24, 0);
--			end
--		end
	else
		self.haveElite = true;
		--TargetFrameBackground:SetSize(119,41);
		self.Background:SetSize(119,25);
		self.Background:SetPoint("BOTTOMLEFT", self, "BOTTOMLEFT", 7, 35);
--		if ( self.threatIndicator ) then
--			self.threatIndicator:SetTexCoord(0, 0.9453125, 0.181640625, 0.400390625);
--			self.threatIndicator:SetWidth(242);
--			self.threatIndicator:SetHeight(112);
--			self.threatIndicator:SetPoint("TOPLEFT", self, "TOPLEFT", -22, 9);
--		end
	end

	if (self.questIcon) then
		if (UnitIsQuestBoss(self.unit)) then
			self.questIcon:Show();
		else
			self.questIcon:Hide();
		end
	end
end

function CT_FocusFrame_CheckDead(self)
	-- self == The main unit frame
	if ( (UnitHealth(self.unit) <= 0) and UnitIsConnected(self.unit) ) then
		self.deadText:Show();
		return true;
	else
		self.deadText:Hide();
		return false;
	end
end


local largeBuffList = {};
local largeDebuffList = {};

function CT_FocusFrame_UpdateAuras(self)
	-- self == The main unit frame
	local frame, frameName;
	local frameIcon, frameCount, frameCooldown;
	local name, icon, count, debuffType, duration, expirationTime, caster, canStealOrPurge, spellId, _;
	local frameStealable;
	local numBuffs = 0;
	local playerIsFocus = UnitIsUnit(PlayerFrame.unit, self.unit);
	local selfName = self:GetName();
	local canAssist = UnitCanAssist("player", self.unit);

	local filter		-- intentionally nil
	
	for i=1, MAX_TARGET_BUFFS do
		name, icon, count, debuffType, duration, expirationTime, caster, canStealOrPurge, _ , spellId = UnitBuff(self.unit, i, filter);

		frameName = selfName .. "Buff" .. i;
		frame = _G[frameName];
		if ( not frame ) then
			if ( not icon ) then
				break;
			else
				frame = CreateFrame("Button", frameName, self, "CT_FocusBuffFrameTemplate");
				frame.unit = self.unit;
				frame.Cooldown:GetRegions():ClearAllPoints()	-- Hack.  Prevents any font string from appearing to show the cooldown duration while action bar cooldowns are displayed.
			end
		end
		if ( icon and ( not self.maxBuffs or i <= self.maxBuffs ) ) then
			frame:SetID(i);

			-- set the icon
			frameIcon = _G[frameName.."Icon"];
			frameIcon:SetTexture(icon);

			-- set the count
			frameCount = _G[frameName.."Count"];
			if ( count > 1 ) then
				frameCount:SetText(count);
				frameCount:Show();
			else
				frameCount:Hide();
			end

			-- Handle cooldowns
			frameCooldown = _G[frameName.."Cooldown"];
			if ( duration > 0 ) then
				frameCooldown:Show();
				CooldownFrame_Set(frameCooldown, expirationTime - duration, duration, 1);
			else
				frameCooldown:Hide();
			end

			-- Show stealable frame if the focus is not the current player and the buff is stealable.
			frameStealable = _G[frameName.."Stealable"];
			if ( not playerIsFocus and canStealOrPurge ) then
				frameStealable:Show();
			else
				frameStealable:Hide();
			end

--			-- set the buff to be big if the focus is not the player and the buff is cast by the player or his pet
--			largeBuffList[i] = (not playerIsFocus and PLAYER_UNITS[caster]);

			-- set the buff to be big if the buff is cast by the player or his pet
			largeBuffList[i] = PLAYER_UNITS[caster];

			numBuffs = numBuffs + 1;

			frame:ClearAllPoints();
			frame:Show();
		else
			frame:Hide();
		end
	end

	local color;
	local frameBorder;
	local numDebuffs = 0;
	local isEnemy = UnitCanAttack("player", self.unit);

	local frameNum = 1;
	local index = 1;

	while ( frameNum <= (self.maxDebuffs or MAX_TARGET_DEBUFFS) ) do
		local debuffName = UnitDebuff(self.unit, index, filter);
		if ( debuffName ) then
			if ( CT_FocusFrame_ShouldShowDebuff(self.unit, index, filter) ) then
				name, icon, count, debuffType, duration, expirationTime, caster = UnitDebuff(self.unit, index, filter);
				frameName = selfName.."Debuff"..frameNum;
				frame = _G[frameName];
				if ( icon ) then
					if ( not frame ) then
						frame = CreateFrame("Button", frameName, self, "CT_FocusDebuffFrameTemplate");
						frame.unit = self.unit;
					end
					frame:SetID(index);

					-- set the icon
					frameIcon = _G[frameName.."Icon"];
					frameIcon:SetTexture(icon);

					-- set the count
					frameCount = _G[frameName.."Count"];
					if ( count > 1 ) then
						frameCount:SetText(count);
						frameCount:Show();
					else
						frameCount:Hide();
					end

					-- Handle cooldowns
					frameCooldown = _G[frameName.."Cooldown"];
					if ( duration > 0 ) then
						frameCooldown:Show();
						CooldownFrame_Set(frameCooldown, expirationTime - duration, duration, 1);
					else
						frameCooldown:Hide();
					end

					-- set debuff type color
					if ( debuffType ) then
						color = DebuffTypeColor[debuffType];
					else
						color = DebuffTypeColor["none"];
					end
					frameBorder = _G[frameName.."Border"];
					frameBorder:SetVertexColor(color.r, color.g, color.b);

					-- set the debuff to be big if the buff is cast by the player or his pet
					largeDebuffList[index] = (PLAYER_UNITS[caster]);

					numDebuffs = numDebuffs + 1;

					frame:ClearAllPoints();
					frame:Show();

					frameNum = frameNum + 1;
				end
			end
			index = index + 1;
		else
			break;
		end
	end

	for i = frameNum, MAX_TARGET_DEBUFFS do
		local frame = _G[selfName.."Debuff"..i];
		if ( frame ) then
			frame:Hide();
		else
			break;
		end
	end

	self.auraRows = 0;

	local mirrorAurasVertically = false;
	if ( self.buffsOnTop ) then
		mirrorAurasVertically = true;
	end
	local haveTargetofFocus;
	if ( self.totFrame ) then
		haveTargetofFocus = self.totFrame:IsShown();
	end
	self.spellbarAnchor = nil;
	local maxRowWidth;
	-- update buff positions
	maxRowWidth = ( haveTargetofFocus and TOT_AURA_ROW_WIDTH ) or AURA_ROW_WIDTH;
	CT_FocusFrame_UpdateAuraPositions(self, selfName.."Buff", numBuffs, numDebuffs, largeBuffList, CT_FocusFrame_UpdateBuffAnchor, maxRowWidth, 3, mirrorAurasVertically);
	-- update debuff positions
	maxRowWidth = ( haveTargetofFocus and self.auraRows < NUM_TOT_AURA_ROWS and TOT_AURA_ROW_WIDTH ) or AURA_ROW_WIDTH;
	CT_FocusFrame_UpdateAuraPositions(self, selfName.."Debuff", numDebuffs, numBuffs, largeDebuffList, CT_FocusFrame_UpdateDebuffAnchor, maxRowWidth, 4, mirrorAurasVertically);
	-- update the spell bar position
	if ( self.spellbar ) then
		CT_Focus_Spellbar_AdjustPosition(self.spellbar);
	end
end

function CT_FocusFrame_ShouldShowDebuff(unit, index, filter)
	--This is an enemy
	if ( SHOW_ALL_ENEMY_DEBUFFS == "1" or not UnitCanAttack("player", unit) ) then
		return true;
	else
		local name, icon, count, debuffType, duration, expirationTime, unitCaster, canStealOrPurge, shouldConsolidate, spellId, canApplyAura, isBossDebuff, points1, points2, points3, isCastByPlayer = UnitDebuff(unit, index, filter);

		local hasCustom, alwaysShowMine, showForMySpec = SpellGetVisibilityInfo(spellId, "ENEMY_TARGET");
		if ( hasCustom ) then
			return showForMySpec or (alwaysShowMine and (unitCaster == "player" or unitCaster == "pet" or unitCaster == "vehicle") );
		else
			return not isCastByPlayer or unitCaster == "player" or unitCaster == "pet" or unitCaster == "vehicle";
		end
	end
end

function CT_FocusFrame_UpdateAuraPositions(self, auraName, numAuras, numOppositeAuras, largeAuraList, updateFunc, maxRowWidth, offsetX, mirrorAurasVertically)
	-- self == The main unit frame

	-- A lot of this complexity is in place to allow the auras to wrap around the target of focus frame if it's shown

	-- Position auras
	local size;
	local offsetY = AURA_OFFSET_Y;
	-- current width of a row, increases as auras are added and resets when a new aura's width exceeds the max row width
	local rowWidth = 0;
	local firstBuffOnRow = 1;
	for i=1, numAuras do
		-- update size and offset info based on large aura status
		if ( largeAuraList[i] ) then
			size = LARGE_AURA_SIZE;
			offsetY = AURA_OFFSET_Y + AURA_OFFSET_Y;
		else
			size = SMALL_AURA_SIZE;
		end

		-- anchor the current aura
		if ( i == 1 ) then
			rowWidth = size;
			self.auraRows = self.auraRows + 1;
		else
			rowWidth = rowWidth + size + offsetX;
		end
		if ( rowWidth > maxRowWidth ) then
			-- this aura would cause the current row to exceed the max row width, so make this aura
			-- the start of a new row instead
			updateFunc(self, auraName, i, numOppositeAuras, firstBuffOnRow, size, offsetX, offsetY, mirrorAurasVertically);

			rowWidth = size;
			self.auraRows = self.auraRows + 1;
			firstBuffOnRow = i;
			offsetY = AURA_OFFSET_Y;

			if ( self.auraRows > NUM_TOT_AURA_ROWS ) then
				-- if we exceed the number of tot rows, then reset the max row width
				-- note: don't have to check if we have tot because AURA_ROW_WIDTH is the default anyway
				maxRowWidth = AURA_ROW_WIDTH;
			end
		else
			updateFunc(self, auraName, i, numOppositeAuras, i - 1, size, offsetX, offsetY, mirrorAurasVertically);
		end
	end
end

function CT_FocusFrame_UpdateBuffAnchor(self, buffName, index, numDebuffs, anchorIndex, size, offsetX, offsetY, mirrorVertically)
	-- self == The main unit frame

	--For mirroring vertically
	local point, relativePoint;
	local startY, auraOffsetY;
	if ( mirrorVertically ) then
		point = "BOTTOM";
		relativePoint = "TOP";
		startY = -15;
--		if ( self.threatNumericIndicator:IsShown() ) then
--			startY = startY + self.threatNumericIndicator:GetHeight();
--		end
		offsetY = - offsetY;
		auraOffsetY = -AURA_OFFSET_Y;
	else
		point = "TOP";
		relativePoint="BOTTOM";
		startY = AURA_START_Y;
		auraOffsetY = AURA_OFFSET_Y;
	end

	local buff = _G[buffName..index];
	if ( index == 1 ) then
		if ( UnitIsFriend("player", self.unit) or numDebuffs == 0 ) then
			-- unit is friendly or there are no debuffs...buffs start on top
			buff:SetPoint(point.."LEFT", self, relativePoint.."LEFT", AURA_START_X, startY);
		else
			-- unit is not friendly and we have debuffs...buffs start on bottom
			buff:SetPoint(point.."LEFT", self.debuffs, relativePoint.."LEFT", 0, -offsetY);
		end
		self.buffs:SetPoint(point.."LEFT", buff, point.."LEFT", 0, 0);
		self.buffs:SetPoint(relativePoint.."LEFT", buff, relativePoint.."LEFT", 0, -auraOffsetY);
		self.spellbarAnchor = buff;
	elseif ( anchorIndex ~= (index-1) ) then
		-- anchor index is not the previous index...must be a new row
		buff:SetPoint(point.."LEFT", _G[buffName..anchorIndex], relativePoint.."LEFT", 0, -offsetY);
		self.buffs:SetPoint(relativePoint.."LEFT", buff, relativePoint.."LEFT", 0, -auraOffsetY);
		self.spellbarAnchor = buff;
	else
		-- anchor index is the previous index
		buff:SetPoint(point.."LEFT", _G[buffName..anchorIndex], point.."RIGHT", offsetX, 0);
	end

	-- Resize
	buff:SetWidth(size);
	buff:SetHeight(size);
end

function CT_FocusFrame_UpdateDebuffAnchor(self, debuffName, index, numBuffs, anchorIndex, size, offsetX, offsetY, mirrorVertically)
	-- self == The main unit frame
	local buff = _G[debuffName..index];
	local isFriend = UnitIsFriend("player", self.unit);

	--For mirroring vertically
	local point, relativePoint;
	local startY, auraOffsetY;
	if ( mirrorVertically ) then
		point = "BOTTOM";
		relativePoint = "TOP";
		startY = -15;
--		if ( self.threatNumericIndicator:IsShown() ) then
--			startY = startY + self.threatNumericIndicator:GetHeight();
--		end
		offsetY = - offsetY;
		auraOffsetY = -AURA_OFFSET_Y;
	else
		point = "TOP";
		relativePoint="BOTTOM";
		startY = AURA_START_Y;
		auraOffsetY = AURA_OFFSET_Y;
	end

	if ( index == 1 ) then
		if ( isFriend and numBuffs > 0 ) then
			-- unit is friendly and there are buffs...debuffs start on bottom
			buff:SetPoint(point.."LEFT", self.buffs, relativePoint.."LEFT", 0, -offsetY);
		else
			-- unit is not friendly or there are no buffs...debuffs start on top
			buff:SetPoint(point.."LEFT", self, relativePoint.."LEFT", AURA_START_X, startY);
		end
		self.debuffs:SetPoint(point.."LEFT", buff, point.."LEFT", 0, 0);
		self.debuffs:SetPoint(relativePoint.."LEFT", buff, relativePoint.."LEFT", 0, -auraOffsetY);
		if ( ( isFriend ) or ( not isFriend and numBuffs == 0) ) then
			self.spellbarAnchor = buff;
		end
	elseif ( anchorIndex ~= (index-1) ) then
		-- anchor index is not the previous index...must be a new row
		buff:SetPoint(point.."LEFT", _G[debuffName..anchorIndex], relativePoint.."LEFT", 0, -offsetY);
		self.debuffs:SetPoint(relativePoint.."LEFT", buff, relativePoint.."LEFT", 0, -auraOffsetY);
		if ( ( isFriend ) or ( not isFriend and numBuffs == 0) ) then
			self.spellbarAnchor = buff;
		end
	else
		-- anchor index is the previous index
		buff:SetPoint(point.."LEFT", _G[debuffName..(index-1)], point.."RIGHT", offsetX, 0);
	end

	-- Resize
	buff:SetWidth(size);
	buff:SetHeight(size);
	local debuffFrame =_G[debuffName..index.."Border"];
	debuffFrame:SetWidth(size+2);
	debuffFrame:SetHeight(size+2);
end

local function CT_FocusFrame_HealthFlash(self)
	-- self == The main unit frame
	if ( UnitIsPlayer(self.unit) and self.unitHPPercent > 0 and self.unitHPPercent <= 0.2 ) then
		local alpha = 255;
		local counter = self.statusCounter + 0.04;
		local sign    = self.statusSign;

		if ( counter > 0.4 ) then
			sign = -sign;
			self.statusSign = sign;
		end
		counter = mod(counter, 0.4);
		self.statusCounter = counter;

		if ( sign == 1 ) then
			alpha = (153  + (counter * 255)) / 255;
		else
			alpha = (255 - (counter * 255)) / 255;
		end

		if ( self.portrait ) then
			self.portrait:SetVertexColor(1.0, 0.0, 0.0, alpha);
		end
	else
		self.ctPortraitTicker:Cancel();
		self.ctPortraitTicker = nil;
	end
end

function CT_FocusHealthCheck(self)
	-- self == The main unit frame's health bar
	local parent = self:GetParent(); -- The main unit frame
	if ( UnitIsPlayer(parent.unit) ) then
		local unitHPMin, unitHPMax, unitCurrHP;
		unitHPMin, unitHPMax = self:GetMinMaxValues();
		unitCurrHP = self:GetValue();
		if (unitHPMax == 0) then
			parent.unitHPPercent = 0;
		else
			parent.unitHPPercent = unitCurrHP / unitHPMax;
		end
		if ( parent.portrait ) then
			if ( UnitIsDead(parent.unit) ) then
				parent.portrait:SetVertexColor(0.35, 0.35, 0.35, 1.0);
			elseif ( UnitIsGhost(parent.unit) ) then
				parent.portrait:SetVertexColor(0.2, 0.2, 0.75, 1.0);
			elseif ( (parent.unitHPPercent > 0) and (parent.unitHPPercent <= 0.2) ) then
				parent.ctPortraitTicker = parent.ctPortraitTicker or  C_Timer.NewTicker(0.05, function() CT_FocusFrame_HealthFlash(parent) end);
			else
				parent.portrait:SetVertexColor(1.0, 1.0, 1.0, 1.0);
			end
		end
	else
		parent.portrait:SetVertexColor(1.0, 1.0, 1.0, 1.0);
	end
	if ( not UnitIsPlayer(parent.unit) ) then
		CT_FocusFrame_CheckFaction(parent);
	end
end

--[[
function CT_FocusFrameDropDown_OnLoad (self)
	UIDropDownMenu_Initialize(self, CT_FocusFrameDropDown_Initialize, "MENU");
end
]]

--[[
function CT_FocusFrameDropDown_Initialize (self)
	local menu;
	local name;
	local id = nil;
	local frame = CT_FocusFrame;
	if ( UnitIsUnit(frame.unit, "player") ) then
		menu = "SELF";
	elseif ( UnitIsUnit(frame.unit, "vehicle") ) then
		-- NOTE: vehicle check must come before pet check for accuracy's sake because
		-- a vehicle may also be considered your pet
		menu = "VEHICLE";
	elseif ( UnitIsUnit(frame.unit, "pet") ) then
		menu = "PET";
	elseif ( UnitIsPlayer(frame.unit) ) then
		id = UnitInRaid(frame.unit);
		if ( id ) then
			menu = "RAID_PLAYER";
			name = GetRaidRosterInfo(id +1);
		elseif ( UnitInParty(frame.unit) ) then
			menu = "PARTY";
		else
			menu = "PLAYER";
		end
	else
		menu = "TARGET";
		name = RAID_TARGET_ICON;
	end
	if ( menu ) then
		UnitPopup_ShowMenu(self, menu, frame.unit, name, id);
	end
end
]]


-- -- Raid target icon function
-- RAID_TARGET_ICON_DIMENSION = 64;
-- RAID_TARGET_TEXTURE_DIMENSION = 256;
-- RAID_TARGET_TEXTURE_COLUMNS = 4;
-- RAID_TARGET_TEXTURE_ROWS = 4;

function CT_FocusFrame_UpdateRaidTargetIcon(self)
	-- self == The main unit frame
	local index = GetRaidTargetIndex(self.unit);
	if ( index ) then
		SetRaidTargetIconTexture(self.raidTargetIcon, index);
		self.raidTargetIcon:Show();
	else
		self.raidTargetIcon:Hide();
	end
end


-- function SetRaidTargetIconTexture (texture, raidTargetIconIndex)
-- 	raidTargetIconIndex = raidTargetIconIndex - 1;
-- 	local left, right, top, bottom;
-- 	local coordIncrement = RAID_TARGET_ICON_DIMENSION / RAID_TARGET_TEXTURE_DIMENSION;
-- 	left = mod(raidTargetIconIndex , RAID_TARGET_TEXTURE_COLUMNS) * coordIncrement;
-- 	right = left + coordIncrement;
-- 	top = floor(raidTargetIconIndex / RAID_TARGET_TEXTURE_ROWS) * coordIncrement;
-- 	bottom = top + coordIncrement;
-- 	texture:SetTexCoord(left, right, top, bottom);
-- end

-- function SetRaidTargetIcon (unit, index)
-- 	if ( GetRaidTargetIndex(unit) and GetRaidTargetIndex(unit) == index ) then
-- 		SetRaidTarget(unit, 0);
-- 	else
-- 		SetRaidTarget(unit, index);
-- 	end
-- end

-- ------------------------------------------------------------------------

function CT_TargetofFocus_OnLoad(self)
	-- self == The "target of" unit frame
	local parent = self:GetParent();
	parent.totFrame = self;

	local thisName = self:GetName();
	local frame = self;

	if module:getGameVersion() >= 10 then
		UnitFrame_Initialize(frame,
			unit2,
			_G[thisName.."TextureFrameName"],
			"TargetOfTarget",
			_G[thisName.."Portrait"],
			_G[thisName.."HealthBar"],
			_G[thisName.."TextureFrameHealthBarText"],
			_G[thisName.."ManaBar"],
			_G[thisName.."TextureFrameManaBarText"]
		)
	else
		UnitFrame_Initialize(frame,
			unit2,
			_G[thisName.."TextureFrameName"],
			_G[thisName.."Portrait"],
			_G[thisName.."HealthBar"],
			_G[thisName.."TextureFrameHealthBarText"],
			_G[thisName.."ManaBar"],
			_G[thisName.."TextureFrameManaBarText"]
		)
	end
	SetTextStatusBarTextZeroText(frame.healthbar, DEAD);
	frame:RegisterUnitEvent("UNIT_AURA", unit2);
	frame.deadText = _G[thisName.."TextureFrameDeadText"];
	SecureUnitButton_OnLoad(frame, frame.unit);

	frame:SetAttribute("type", "target");
	frame:SetAttribute("unit", frame.unit);
	RegisterUnitWatch(frame);

	ClickCastFrames = ClickCastFrames or { };
	ClickCastFrames[frame] = true;
end

function CT_TargetofFocus_OnShow(self)
	-- self == The "target of" unit frame
	CT_FocusFrame_UpdateAuras(self:GetParent());
end

function CT_TargetofFocus_OnHide(self)
	-- self == The "target of" unit frame
	local parent = self:GetParent();
	CT_Focus_Spellbar_AdjustPosition(parent.spellbar);
	CT_FocusFrame_UpdateAuras(self:GetParent());
end

function CT_TargetofFocus_Update(self, elapsed)
	-- self == The "target of" unit frame
	local show;
	local parent = self:GetParent();
	if (not CT_UnitFramesOptions.shallDisplayTargetofFocus) then
		if ( self:IsShown() ) then
			if (not InCombatLockdown()) then
				UnregisterUnitWatch(self);
				parent.haveToT = nil;
				CT_Focus_Spellbar_AdjustPosition(parent.spellbar);
				return;
			end
		end
	end
	parent.haveToT = true;
	CT_Focus_Spellbar_AdjustPosition(parent.spellbar);
	UnitFrame_Update(self);
	CT_TargetofFocus_CheckDead(self);
	CT_TargetofFocus_HealthCheck(self);
	RefreshDebuffs(self, self.unit);
end

function CT_TargetofFocus_OnEvent(self, event, ...)
	if (event == "UNIT_AURA") then
		RefreshDebuffs(self, self.unit);
	else
		UnitFrame_OnEvent(self, event, ...);
	end
end

function CT_TargetofFocus_CheckDead(self)
	-- self == The "target of" unit frame
	if ( (UnitHealth(self.unit) <= 0) and UnitIsConnected(self.unit) ) then
		self.background:SetAlpha(0.9);
		self.deadText:Show();
	else
		self.background:SetAlpha(1);
		self.deadText:Hide();
	end
end

function CT_TargetofFocus_HealthCheck(self)
	-- self == The "target of" unit frame
	if ( UnitIsPlayer(self.unit) ) then
		local unitHPMin, unitHPMax, unitCurrHP;
		unitHPMin, unitHPMax = self.healthbar:GetMinMaxValues();
		unitCurrHP = self.healthbar:GetValue();
		if (unitHPMax == 0) then
			self.unitHPPercent = 0;
		else
			self.unitHPPercent = unitCurrHP / unitHPMax;
		end
		if ( UnitIsDead(self.unit) ) then
			self.portrait:SetVertexColor(0.35, 0.35, 0.35, 1.0);
		elseif ( UnitIsGhost(self.unit) ) then
			self.portrait:SetVertexColor(0.2, 0.2, 0.75, 1.0);
		elseif ( (self.unitHPPercent > 0) and (self.unitHPPercent <= 0.2) ) then
			self.portrait:SetVertexColor(1.0, 0.0, 0.0);
		else
			self.portrait:SetVertexColor(1.0, 1.0, 1.0, 1.0);
		end
	else
		self.portrait:SetVertexColor(1.0, 1.0, 1.0, 1.0);
	end
end

-- -----------------------------------------------------------------------------------

function CT_Focus_Spellbar_OnLoad(self)
	-- self == Spellbar for the main unit frame.
	local parent = self:GetParent();
	parent.spellbar = self;
	parent.auraRows = 0;

	--self.unit = unit1;

	self:RegisterEvent("PLAYER_FOCUS_CHANGED");
	self:RegisterEvent("CVAR_UPDATE");
	self:RegisterEvent("VARIABLES_LOADED");

	local configFunc = CastingBarFrame_OnLoad or CastingBarMixin.OnLoad
	configFunc(self, unit1, false, true);

	local barIcon = self.Icon;
	barIcon:Show();

--	CT_SetFocusSpellbarAspect(self);

	--The focus casting bar has less room for text than most, so shorten it
	self.Text:SetWidth(150);

	-- check to see if the castbar should be shown
--	if ( GetCVar("showTargetCastbar") == "0") then
--		self.showCastbar = false;
--	end
	CT_Focus_ToggleSpellbar(self);
end

function CT_Focus_ToggleSpellbar(self)
	-- self == Spellbar for the main unit frame.
	if ( CT_UnitFramesOptions and not CT_UnitFramesOptions.showFocusCastbar ) then
		self.showCastbar = false;
	else
		self.showCastbar = true;
	end
	if ( not self.showCastbar ) then
		self:Hide();
	elseif ( self.casting or self.channeling ) then
		self:Show();
	end
end

function CT_Focus_Spellbar_OnEvent(self, event, ...)
	-- self == Spellbar for the main unit frame.
	local arg1 = ...

	--	Check for focus specific events
	if ( (event == "VARIABLES_LOADED") or ((event == "CVAR_UPDATE") and (arg1 == "SHOW_FOCUS_CASTBAR")) ) then
--		if ( GetCVar("showTargetCastbar") == "0") then
--			self.showCastbar = false;
--		else
--			self.showCastbar = true;
--		end
--		if ( not self.showCastbar ) then
--			self:Hide();
--		elseif ( self.casting or self.channeling ) then
--			self:Show();
--		end
		CT_Focus_ToggleSpellbar(self);
		return;
	elseif ( event == "PLAYER_FOCUS_CHANGED" ) then
		-- check if the new focus is casting a spell
		local nameChannel  = UnitChannelInfo(self.unit);
		local nameSpell  = UnitCastingInfo(self.unit);
		if ( nameChannel ) then
			event = "UNIT_SPELLCAST_CHANNEL_START";
			arg1 = self.unit;
		elseif ( nameSpell ) then
			event = "UNIT_SPELLCAST_START";
			arg1 = self.unit;
		else
			self.casting = nil;
			self.channeling = nil;
			self:SetMinMaxValues(0, 0);
			self:SetValue(0);
			self:Hide();
			return;
		end
		-- The position depends on the classification of the focus
		CT_Focus_Spellbar_AdjustPosition(self);
	end
	local onEventHandler = CastingBarFrame_OnEvent or CastingBarMixin.OnEvent  -- WoW 10.x
	if ( self.unit == unit1 and strsub(event, 1, 15) == "UNIT_SPELLCAST_" and UnitIsUnit(arg1, self.unit) ) then
		-- arg1 may be a different code than the main unit frame's unit, even though they are the same unit.
		-- If this is the main unit frame, and this is a unit spellcast event, and arg1 is equivalent to the main unit frame's unit...
		-- Pass "focus" (self.unit) instead of arg1 to fool the CastingBarFrame_OnEvent() function into showing the casting bar for our focus frame.
		onEventHandler(self, event, self.unit, select(2, ...));
	else
		onEventHandler(self, event, arg1, select(2, ...));
	end
end

function CT_Focus_Spellbar_AdjustPosition(self)
	-- self == Spellbar for the main unit frame.
	local parentFrame = self:GetParent();
	if ( parentFrame.haveToT ) then
		if ( parentFrame.buffsOnTop or parentFrame.auraRows <= 1 ) then
			self:SetPoint("TOPLEFT", parentFrame, "BOTTOMLEFT", 25, -21 );
		else
			self:SetPoint("TOPLEFT", parentFrame.spellbarAnchor, "BOTTOMLEFT", 20, -15);
		end
	elseif ( parentFrame.haveElite ) then
		if ( parentFrame.buffsOnTop or parentFrame.auraRows <= 1 ) then
			self:SetPoint("TOPLEFT", parentFrame, "BOTTOMLEFT", 25, -5 );
		else
			self:SetPoint("TOPLEFT", parentFrame.spellbarAnchor, "BOTTOMLEFT", 20, -15);
		end
	else
		if ( (not parentFrame.buffsOnTop) and parentFrame.auraRows > 0 ) then
			self:SetPoint("TOPLEFT", parentFrame.spellbarAnchor, "BOTTOMLEFT", 20, -15);
		else
			self:SetPoint("TOPLEFT", parentFrame, "BOTTOMLEFT", 25, 7 );
		end
	end

end

-- ------------------------------------------------------------------
-- Bar text

local function CT_FocusFrame_TextStatusBar_UpdateTextString(bar)
	local self = CT_FocusFrame;

	if (bar == self.healthbar) then
		if (CT_UnitFramesOptions) then
			local style;
			if (UnitIsFriend(self.unit, "player")) then
				style = CT_UnitFramesOptions.styles[5][1];
			else
				style = CT_UnitFramesOptions.styles[5][5];
			end
			module:UpdateStatusBarTextString(bar, style, 0)
			CT_UnitFrames_HealthBar_OnValueChanged(bar, tonumber(bar:GetValue()), not CT_UnitFramesOptions.oneColorHealth)
			module:UpdateBesideBarTextString(bar, CT_UnitFramesOptions.styles[5][2], self.healthBesideText)
		end

	elseif (bar == self.manabar) then
		if (CT_UnitFramesOptions) then
			module:UpdateStatusBarTextString(bar, CT_UnitFramesOptions.styles[5][3], 0)
			module:UpdateBesideBarTextString(bar, CT_UnitFramesOptions.styles[5][4], self.manaBesideText)
		end
	end
end

function CT_FocusFrame_TextStatusBar_OnLoad(bar)
	bar:HookScript("OnValueChanged", CT_FocusFrame_TextStatusBar_UpdateTextString);
	bar:HookScript("OnEnter", CT_FocusFrame_TextStatusBar_UpdateTextString);
	bar:HookScript("OnLeave", CT_FocusFrame_TextStatusBar_UpdateTextString);
end

--[[	-- replaced by CT_FocusFrame_TextStatusBar_OnLoad(bar)
 
	function CT_FocusFrame_ShowTextStatusBarText(bar)
		local self = CT_FocusFrame;
		if (bar == self.healthbar or bar == self.manabar) then
			CT_FocusFrame_TextStatusBar_UpdateTextString(bar);
		end
	end


	function CT_FocusFrame_HideTextStatusBarText(bar)
		local self = CT_FocusFrame;
		if (bar == self.healthbar or bar == self.manabar) then
			CT_FocusFrame_TextStatusBar_UpdateTextString(bar);
		end
	end
	hooksecurefunc("TextStatusBar_UpdateTextString", CT_FocusFrame_TextStatusBar_UpdateTextString);
	hooksecurefunc("ShowTextStatusBarText", CT_FocusFrame_ShowTextStatusBarText);
	hooksecurefunc("HideTextStatusBarText", CT_FocusFrame_HideTextStatusBarText);
--]]

function module:AnchorFocusFrameSideText()
	local self = CT_FocusFrame;
	local fsTable = { self.healthBesideText, self.manaBesideText };
	for i, frame in ipairs(fsTable) do
--		<Anchor point="RIGHT" relativeTo="CT_FocusFrame" relativePoint="TOPLEFT">
--		<AbsDimension x="4" y="-46"/>
		local xoff = (CT_UnitFramesOptions.focusTextSpacing or 0);
		local yoff = -(46 + (i-1)*11);
		local onRight = CT_UnitFramesOptions.focusTextRight;
		frame:ClearAllPoints();
		if (onRight) then
			frame:SetPoint("LEFT", self, "TOPRIGHT", xoff, yoff);
		else
			xoff = xoff - 4;
			frame:SetPoint("RIGHT", self, "TOPLEFT", -xoff, yoff);
		end

	end
end

function module:ShowFocusFrameBarText()
	local self = CT_FocusFrame;
	UnitFrameHealthBar_Update(self.healthbar, self.unit);
	UnitFrameManaBar_Update(self.manabar, self.unit);
end

-- ------------------------------------------------------------------
-- Toggle the default UI's focus frame.

function CT_FocusFrame_ToggleStandardFocus()
	if (InCombatLockdown()) then
		return;
	end
	local frame = FocusFrame;
	if (CT_UnitFramesOptions.hideStdFocus) then
		frame:UnregisterAllEvents();
		frame:Hide();
	else
		frame:RegisterEvent("PLAYER_ENTERING_WORLD");
		frame:RegisterEvent("PLAYER_FOCUS_CHANGED");
		frame:RegisterUnitEvent("UNIT_HEALTH", unit1);
		frame:RegisterUnitEvent("UNIT_LEVEL", unit1);
		frame:RegisterUnitEvent("UNIT_FACTION", unit1);
		frame:RegisterUnitEvent("UNIT_AURA", unit1);
		frame:RegisterEvent("GROUP_ROSTER_UPDATE");
		frame:RegisterEvent("RAID_TARGET_UPDATE");
		if (not frame.smallSize) then
			frame:RegisterUnitEvent("UNIT_CLASSIFICATION_CHANGED", unit1);
			frame:RegisterUnitEvent("PLAYER_FLAGS_CHANGED", unit1);
		end
		if (UnitExists("focus")) then
			frame:Show();
		end
	end
end
