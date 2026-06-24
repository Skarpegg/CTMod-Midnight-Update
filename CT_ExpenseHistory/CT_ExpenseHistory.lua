------------------------------------------------
--              CT_ExpenseHistory             --
--                                            --
-- Keeps a detailed log of expenses for each  --
-- of your characters.                        --
--                                            --
-- Please do not modify or otherwise          --
-- redistribute this without the consent of   --
-- the CTMod Team. Thank you.                 --
--					      --
-- Original credits to Cide and TS            --
-- Maintained by Resike from 2014 to 2017     --
-- Maintained by Dahk Celes (ddc) since 2019  --
------------------------------------------------

--------------------------------------------
-- Initialization

local MODULE_TOC_NAME, module = ...;

local _G = getfenv(0);

local MODULE_TOC_VERSION = strmatch(C_AddOns.GetAddOnMetadata(MODULE_TOC_NAME, "version"), "^([%d.]+)");

module.name = "CT_ExpenseHistory";
module.version = MODULE_TOC_VERSION;
-- module.frame = "CT_ExpenseHistoryFrame";
-- module.external = true;

_G[module.name] = module;

-- GetMerchantItemInfo was removed in Midnight (12.0); use the shared CT_Library adapter, which keeps
-- the old positional returns (backed by C_MerchantFrame.GetItemInfo on modern clients).
local GetMerchantItemInfo = CT_Library.getMerchantItemInfo;
CT_Library:registerModule(module);
tinsert(UISpecialFrames, "CT_ExpenseHistoryFrame");

module.text = module.text or { };	-- see localization.lua
local L = module.text

--------------------------------------------
-- Variables

CT_EH_History = { };
CT_EH_DISPLAYTHRESHOLD = 1; -- 1 Silver
CT_EH_NUMCLASSPILES = 8;
CT_EH_LogSort = {
	["curr"] = 1,
	["way"] = 1 -- Desc
};

CT_EH_LogTable = {};

--------------------------------------------
-- Functions

function CT_EH_Sort(t1, t2)
	if ( t1 and t2 ) then
		return t1[1] >= t2[1]
	end
end

function CT_EH_SortLogBy(id)
	if ( CT_EH_LogSort["curr"] == id ) then
		CT_EH_LogSort["way"] = abs(CT_EH_LogSort["way"]-1);
	else
		CT_EH_LogSort["curr"] = id;
		CT_EH_LogSort["way"] = 1;
	end
	CT_EH_SortLog();
	CT_EH_UpdateLog();
end

local dropdownsInitialized;
function CT_EH_UpdateSummary()
	local _, _, currPlayer, currServer = string.find( CT_ExpenseHistoryFrame.currPlayer or "", "^(.+)@(.+)$");
	if ( currPlayer ) then
		currPlayer = currPlayer .. " @ " .. currServer;
	end

	if (not dropdownsInitialized) then
		-- Delay initializing dropdown menus as long as possible to avoid tainting
		-- frames like CompactRaidFrame1 when it gets created.
		CT_EH_ServerDropDown_OnLoad(CT_ExpenseHistoryFrameServerDropDown);
		CT_EH_DropDown_OnLoad(CT_ExpenseHistoryFrameDropDown);
		dropdownsInitialized = true;
	end

	UIDropDownMenu_SetSelectedName(CT_ExpenseHistoryFrameServerDropDown, ( CT_ExpenseHistoryFrame.currServer or L["CT_ExpenseHistory/Summary/PlayerDistribution/AllServers"] ) );
	UIDropDownMenu_SetWidth(CT_ExpenseHistoryFrameServerDropDown, 100);
	CT_ExpenseHistoryFrameServerDropDownText:SetText(( CT_ExpenseHistoryFrame.currServer or L["CT_ExpenseHistory/Summary/PlayerDistribution/AllServers"] ));

	UIDropDownMenu_SetSelectedName(CT_ExpenseHistoryFrameDropDown, ( currPlayer or L["CT_ExpenseHistory/Summary/PlayerDistribution/AllCharacters"] ) );
	UIDropDownMenu_SetWidth(CT_ExpenseHistoryFrameDropDown, 200);
	CT_ExpenseHistoryFrameDropDownText:SetText(( currPlayer or L["CT_ExpenseHistory/Summary/PlayerDistribution/AllCharacters"] ));

	CT_ExpenseHistoryFrameRecordingText:SetText(format(L["CT_ExpenseHistory/Log/RecordingSince"], date("%m/%d/%Y", CT_EH_History["startUsage"])));

	local classCoords = CLASS_ICON_TCOORDS;  -- Table index is non-localized class name (eg: "WARRIOR")

	local costsTable, totalRepair, numRepairs, totalFlight, totalReagent, totalAmmo, totalMail, totalCost, highCost = CT_EH_GetStats(CT_ExpenseHistoryFrame.currPlayer, CT_ExpenseHistoryFrame.currServer);
	local allCostsTable, _, _, _, _, _, _, _, allHighCost = CT_EH_GetStats(nil, nil);
	table.sort(
		allCostsTable,
		function(a1, a2)
			if ( a1 and a2 ) then
				return a1[1] > a2[1];
			end
		end
	);

	-- Summaries
	local dailyCost, dailyFlight, dailyRepair, dailyReagent, dailyAmmo, dailyMail;
	local avgRepair;
	local numDays = ( time() - CT_EH_History["startUsage"] ) / (24 * 3600);
	if (numDays == 0) then
		dailyCost = 0;
		dailyFlight = 0;
		dailyRepair = 0;
		dailyReagent = 0;
		dailyAmmo = 0;
		dailyMail = 0;
	else
		dailyCost = floor(totalCost / numDays + 0.5);
		dailyFlight = floor(totalFlight / numDays + 0.5);
		dailyRepair = floor(totalRepair / numDays + 0.5);
		dailyReagent = floor(totalReagent / numDays + 0.5);
		dailyAmmo = floor(totalAmmo / numDays + 0.5);
		dailyMail = floor(totalMail / numDays + 0.5);
	end
	if (numRepairs == 0) then
		avgRepair = 0;
	else
		avgRepair = floor(totalRepair / numRepairs + 0.5);
	end
	MoneyFrame_Update("CT_ExpenseHistoryFrameSummaryAverageRepairMoney", avgRepair);
	MoneyFrame_Update("CT_ExpenseHistoryFrameSummaryAvgExpensesPerDayMoney", dailyCost );
	MoneyFrame_Update("CT_ExpenseHistoryFrameSummaryTotalCostMoney", floor(totalCost + 0.5));

	MoneyFrame_Update("CT_ExpenseHistoryFrameSummaryAvgExpensesFlightsMoney", dailyFlight);
	MoneyFrame_Update("CT_ExpenseHistoryFrameSummaryAvgExpensesRepairsMoney", dailyRepair);
	MoneyFrame_Update("CT_ExpenseHistoryFrameSummaryAvgExpensesReagentsMoney", dailyReagent);
	MoneyFrame_Update("CT_ExpenseHistoryFrameSummaryAvgExpensesAmmoMoney", dailyAmmo);
	MoneyFrame_Update("CT_ExpenseHistoryFrameSummaryAvgExpensesMailMoney", dailyMail);

	MoneyFrame_Update("CT_ExpenseHistoryFrameSummaryTotalCostFlightsMoney", floor(totalFlight+0.5));
	MoneyFrame_Update("CT_ExpenseHistoryFrameSummaryTotalCostRepairsMoney", floor(totalRepair+0.5));
	MoneyFrame_Update("CT_ExpenseHistoryFrameSummaryTotalCostReagentsMoney", floor(totalReagent+0.5));
	MoneyFrame_Update("CT_ExpenseHistoryFrameSummaryTotalCostAmmoMoney", floor(totalAmmo+0.5));
	MoneyFrame_Update("CT_ExpenseHistoryFrameSummaryTotalCostMailMoney", floor(totalMail+0.5));

	local i = 0;
	CT_ExpenseHistoryFrame.numPiles = 0;
	for playerIndex, val in pairs(allCostsTable) do
		if ( val[1] >= CT_EH_DISPLAYTHRESHOLD ) then
			i = i + 1;
			if ( i <= CT_EH_NUMCLASSPILES ) then
				-- This 'class' is non-localized.
				local v, formattedCost, class, playerName = val[1], val[2], val[3], val[4];
				if (not class) then
					class = "WARRIOR";
				end
				local height;
				if (allHighCost == 0) then
					height = 0;
				else
					height = 120 * (v / allHighCost);
				end
				if ( height < 2 ) then
					height = 2; -- So we can at least see the bar
				end
				CT_ExpenseHistoryFrame.numPiles = i;
				_G["CT_ExpenseHistoryFrameSummaryDiagramClass" .. i].name = playerName;
				_G["CT_ExpenseHistoryFrameSummaryDiagramClass" .. i]:Show();
				if ( not CT_ExpenseHistoryFrame.isAnimated ) then
					_G["CT_ExpenseHistoryFrameSummaryDiagramClass" .. i .. "Pile"]:SetHeight(height);
				end
				_G["CT_ExpenseHistoryFrameSummaryDiagramClass" .. i .. "Pile"].goalHeight = height;
				_G["CT_ExpenseHistoryFrameSummaryDiagramClass" .. i .. "PileNumber"]:SetText(formattedCost);
				_G["CT_ExpenseHistoryFrameSummaryDiagramClass" .. i .. "Texture"]:SetTexCoord(classCoords[class][1], classCoords[class][2], classCoords[class][3], classCoords[class][4]);
				_G["CT_ExpenseHistoryFrameSummaryDiagramClass" .. i .. "PileBackground"]:SetVertexColor(RAID_CLASS_COLORS[class].r, RAID_CLASS_COLORS[class].g, RAID_CLASS_COLORS[class].b);
			end
		end
	end
	for i = i+1, CT_EH_NUMCLASSPILES, 1 do
		_G["CT_ExpenseHistoryFrameSummaryDiagramClass" .. i]:Hide();
	end
end

function CT_EH_GenerateLog()
	local atServer = "@" .. (CT_ExpenseHistoryFrame.currServer or "");
	CT_EH_LogTable = { };
	for k, v in pairs(CT_EH_History) do
		if ( type(v) == "table" ) then
			for key, val in pairs(v) do
				if ( type(val) == "table" ) then
					if (CT_ExpenseHistoryFrame.currPlayer) then
						-- A specific character at a server.
						if (CT_ExpenseHistoryFrame.currPlayer == k) then
							tinsert(CT_EH_LogTable, { val[3], k, val[2], val[1] });
						end
					else
						if (CT_ExpenseHistoryFrame.currServer) then
							-- All characters at a server.
							if (string.find(k, atServer, 1, true)) then
								tinsert(CT_EH_LogTable, { val[3], k, val[2], val[1] });
							end
						else
							-- All characters
							tinsert(CT_EH_LogTable, { val[3], k, val[2], val[1] });
						end
					end
				end
			end
		end
	end
end

function CT_EH_SortLog()
	table.sort(
		CT_EH_LogTable,
		function(a1, a2)
			if ( a1 and a2 ) then
				if ( CT_EH_LogSort["way"] == 1 ) then
					if ( a1[CT_EH_LogSort["curr"]] == a2[CT_EH_LogSort["curr"]] ) then
						return a1[1] > a2[1];
					else
						return a1[CT_EH_LogSort["curr"]] > a2[CT_EH_LogSort["curr"]];
					end
				else
					if ( a1[CT_EH_LogSort["curr"]] == a2[CT_EH_LogSort["curr"]] ) then
						return a1[1] < a2[1];
					else
						return a1[CT_EH_LogSort["curr"]] < a2[CT_EH_LogSort["curr"]];
					end
				end
			end
		end
	);
end

function CT_EH_UpdateLog()
	local entries = CT_EH_LogTable;
	local numEntries = #entries;
	FauxScrollFrame_Update(CT_ExpenseHistoryFrameLogScrollFrame, numEntries, 22, 20);
	for i=1, 22, 1 do
		local line = _G["CT_ExpenseHistoryFrameLogLine" .. i];
		local dateText = _G["CT_ExpenseHistoryFrameLogLine" .. i .. "Date"];
		local charText = _G["CT_ExpenseHistoryFrameLogLine" .. i .. "Char"];
		local typeText = _G["CT_ExpenseHistoryFrameLogLine" .. i .. "Type"];
		local costFrameName = "CT_ExpenseHistoryFrameLogLine" .. i .. "Cost";

		local index = i + FauxScrollFrame_GetOffset(CT_ExpenseHistoryFrameLogScrollFrame);
		if ( index <= numEntries ) then
			local iStart, iEnd, charName, serverName = string.find(entries[index][2], "^(.+)@(.+)$");
			if ( strlen(charName)+strlen(serverName) > 16 ) then
				-- We have to cut it down
				if ( strlen(serverName) < 8 ) then
					charName = strsub(charName, 0, 16-strlen(serverName));
				elseif ( strlen(charName) < 8 ) then
					serverName = strsub(serverName, 0, 16-strlen(charName));
				else
					charName = strsub(charName, 0, 8);
					serverName = strsub(serverName, 0, 8);
				end
			end
			line:Show();
			dateText:SetText(date("%m/%d/%y", entries[index][1]));
			charText:SetText(charName .. "@" .. serverName);
			typeText:SetText(L["CT_ExpenseHistory/" .. (entries[index][3] or "")] or entries[index][3]);
			MoneyFrame_Update(costFrameName, entries[index][4]);
		else
			line:Hide();
		end
	end
end

function CT_EH_GetStats(player, serverName)
	local classFileNames = {
		[CT_EH_WARRIOR] = "WARRIOR",
		[CT_EH_MAGE] = "MAGE",
		[CT_EH_ROGUE] = "ROGUE",
		[CT_EH_DRUID] = "DRUID",
		[CT_EH_HUNTER] = "HUNTER",
		[CT_EH_SHAMAN] = "SHAMAN",
		[CT_EH_PRIEST] = "PRIEST",
		[CT_EH_WARLOCK] = "WARLOCK",
		[CT_EH_PALADIN] = "PALADIN",
		[CT_EH_DEATHKNIGHT] = "DEATHKNIGHT",
		[CT_EH_MONK] = "MONK",
	};
	local costs, totalRepair, numRepair, totalFlight, totalReagents, totalAmmo, totalMail, totalCost, highCost = { }, 0, 0, 0, 0, 0, 0, 0, 0;
	local class;
	for key, tbl in pairs(CT_EH_History) do
		if ( ( key == player or not player ) and type(tbl) == "table" ) then
			local _, _, playerName, server = string.find(key, "^(.+)@(.+)$");
			if ((not serverName) or (serverName and serverName == server)) then
				local total, totalRep, numRep, totalFli, totalReg, totalAmm, totalMai = CT_EH_GetMoney(key);
				local formattedCost;
				if ( total < 100 ) then
					formattedCost = total .. "c";
				elseif ( total < (100*100) ) then
					formattedCost = floor(total/100) .. "s";
				else
					formattedCost = floor(total/(100*100)) .. "g";
				end
				if ( ( total or 0 ) > highCost ) then
					highCost = total;
				end
				totalRepair = totalRepair + totalRep;
				numRepair = numRepair + numRep;
				totalFlight = totalFlight + totalFli;
				totalReagents = totalReagents + totalReg;
				totalAmmo = totalAmmo + totalAmm;
				totalMail = totalMail + totalMai;
				totalCost = totalCost + total;
				-- tbl.class is a localized class name, tbl.filename is non-localized.
				if (tbl.filename) then
					class = tbl.filename;
				else
					class = classFileNames[tbl.class];
					if (not class) then
						class = "WARRIOR";
					end
				end
				tinsert(costs, { total, formattedCost, class, playerName .. " @ " .. server });
			end
		end
	end
	return costs, totalRepair, numRepair, totalFlight, totalReagents, totalAmmo, totalMail, totalCost, highCost;
end

function CT_EH_StartAnimate()
	for i = 1, CT_ExpenseHistoryFrame.numPiles, 1 do
		local pile = _G["CT_ExpenseHistoryFrameSummaryDiagramClass" .. i .. "Pile"];
		if ( pile:GetParent():IsVisible() ) then
			CT_ExpenseHistoryFrame.isAnimated = 1;
			_G["CT_ExpenseHistoryFrameSummaryDiagramClass" .. i .. "Pile"]:SetHeight(0);
		end
	end
end

function CT_EH_ProcessAnimation(self, elapsed)
	self.elapsed = self.elapsed - elapsed;
	if ( self.elapsed <= 0 ) then
		if ( self.isAnimated ) then
			local keepAnimating = false;
			for i = 1, CT_ExpenseHistoryFrame.numPiles, 1 do
				local pile = _G["CT_ExpenseHistoryFrameSummaryDiagramClass" .. i .. "Pile"];
				local height = pile:GetHeight();
				if ( ( height or 0 ) < pile.goalHeight ) then
					pile:SetHeight(height+(1*((0.017-self.elapsed)/0.017)));
					keepAnimating = true;
				end
			end
			if ( not keepAnimating ) then
				CT_ExpenseHistoryFrame.isAnimated = nil;
			end
		end
		self.elapsed = 0.017;
	end
end

function CT_EH_GetMoney(name)
	local total, totalRep, numRep, totalFli, totalReg, totalAmm, totalMai = 0, 0, 0, 0, 0, 0, 0;
	if ( name and CT_EH_History[name] ) then
		for k, v in pairs(CT_EH_History[name]) do
			if ( k ~= "class" and k ~= "key" and k ~= "filename" ) then
				total = total + v[1];
				if ( v[2] == "Repair" or v[2] == L["CT_ExpenseHistory/Repair"] ) then
					totalRep = totalRep + v[1];
					numRep = numRep + 1;
				elseif ( v[2] == "Flight" or v[2] == L["CT_ExpenseHistory/Flight"] ) then
					totalFli = totalFli + v[1];
				elseif ( v[2] == "Reagent" or v[2] == L["CT_ExpenseHistory/Reagent"] ) then
					totalReg = totalReg + v[1];
				elseif ( v[2] == "Ammo" or v[2] == L["CT_ExpenseHistory/Ammo"] ) then
					totalAmm = totalAmm + v[1];
				elseif ( v[2] == "Mail" or v[2] == L["CT_ExpenseHistory/Mail"] ) then
					totalMai = totalMai + v[1];
				end
			end
		end
	end
	return total, totalRep, numRep, totalFli, totalReg, totalAmm, totalMai;
end

function CT_EH_OnShow()
	PlaySound(1115);
	PanelTemplates_SetTab(CT_ExpenseHistoryFrame, 1);
	CT_ExpenseHistoryFrameSummary:Show();
	CT_ExpenseHistoryFrameLog:Hide();
	CT_EH_UpdateSummary();
	CT_EH_StartAnimate();
end

function CT_EH_OnEvent(event)
	if ( event == "PLAYER_LOGIN" ) then
		CT_EH_History["startUsage"] = CT_EH_History["startUsage"] or time();
		
		local player = UnitName("player") .. "@" .. GetRealmName();
		local class, filename = UnitClass("player");
		
		CT_EH_History[player] = CT_EH_History[player] or { ["key"] = player };
		CT_EH_History[player].class = class	-- if a toon is deleted and remade as a new class, this will update it
		CT_EH_History[player].filename = filename
	end
end

-- Data collection
function CT_EH_UpdateRepair(arg1, arg2)
	if InRepairMode() and GameTooltip:IsShown() and GameTooltipMoneyFrame1 and GameTooltipMoneyFrame1:IsShown() then
		local gold, silver, copper = 
			tonumber(GameTooltipMoneyFrame1GoldButtonText:GetText()) or 0,
			tonumber(GameTooltipMoneyFrame1SilverButtonText:GetText()) or 0,
			tonumber(GameTooltipMoneyFrame1CopperButtonText:GetText()) or 0
		MerchantFrame.repairCost = MerchantFrame.repairCost + gold*10000 + silver*100 + copper
	end
end

hooksecurefunc("PickupInventoryItem", CT_EH_UpdateRepair)
if C_Container and C_Container.UseContainerItem then
	hooksecurefunc(C_Container, "UseContainerItem", CT_EH_UpdateRepair)
	hooksecurefunc(C_Container, "PickupContainerItem", CT_EH_UpdateRepair)
else
	hooksecurefunc("UseContainerItem", CT_EH_UpdateRepair)
	hooksecurefunc("PickupContainerItem", CT_EH_UpdateRepair)
end


CT_EH_oldRepairAllItems = RepairAllItems;
function CT_EH_newRepairAllItems(...)
	local repairAllCost, canRepair = GetRepairAllCost();
	if ( canRepair and repairAllCost <= GetMoney() and not (...) ) then
		if ( MerchantFrame.repairCost ) then
			MerchantFrame.repairCost = MerchantFrame.repairCost + repairAllCost;
		end
	end
	CT_EH_oldRepairAllItems(...);
end
RepairAllItems = CT_EH_newRepairAllItems;

module.customOpenFunction = function()
	if ( CT_ExpenseHistoryFrame:IsVisible() ) then
		HideUIPanel(CT_ExpenseHistoryFrame);
	else
		ShowUIPanel(CT_ExpenseHistoryFrame);
	end
end

SlashCmdList["EXPENSEHISTORY"] = module.customOpenFunction;

SLASH_EXPENSEHISTORY1 = "/eh";
SLASH_EXPENSEHISTORY2 = "/expensehistory";
SLASH_EXPENSEHISTORY3 = "/cteh";

function CT_EH_DropDown_OnLoad(self)
	UIDropDownMenu_Initialize(self, CT_EH_DropDown_Initialize);
end

function CT_EH_DropDown_Initialize()
	local players = {};
	for k, v in pairs(CT_EH_History) do
		if ( type(v) == "table" ) then
			local total = CT_EH_GetMoney(k);
			if ( total >= CT_EH_DISPLAYTHRESHOLD ) then
				local _, _, playerName, server = string.find(k, "^(.+)@(.+)$");
				if ((not CT_ExpenseHistoryFrame.currServer) or (CT_ExpenseHistoryFrame.currServer and CT_ExpenseHistoryFrame.currServer == server)) then
					tinsert(players, k);
				end
			end
		end
	end
	sort(players);

	local dropdown, info;
	dropdown = CT_ExpenseHistoryFrameDropDown;
	info = { };
	info.text = "All Characters";
	info.value = nil;
	info.checked = ( not CT_ExpenseHistoryFrame.currPlayer );
	info.func = CT_EH_DropDown_OnClick;
	UIDropDownMenu_AddButton(info);
	for i, k in pairs(players) do
		local _, _, playerName, server = string.find(k, "^(.+)@(.+)$");
		info.text = playerName .. " @ " .. server;
		info.value = k;
		info.checked = ( CT_ExpenseHistoryFrame.currPlayer == k );
		info.func = CT_EH_DropDown_OnClick;
		UIDropDownMenu_AddButton(info);
	end
end

function CT_EH_DropDown_OnClick(self)
	if ( self:GetID() == 1 ) then
		CT_ExpenseHistoryFrame.currPlayer = nil;
	else
		CT_ExpenseHistoryFrame.currPlayer = self.value;
	end
	CT_EH_UpdateSummary();
end

function CT_EH_ServerDropDown_OnLoad(self)
	UIDropDownMenu_Initialize(self, CT_EH_ServerDropDown_Initialize);
end

function CT_EH_ServerDropDown_Initialize()
	local servers = {};
	local serversort = {};
	for k, v in pairs(CT_EH_History) do
		if ( type(v) == "table" ) then
			local total = CT_EH_GetMoney(k);
			if ( total >= CT_EH_DISPLAYTHRESHOLD ) then
				local _, _, playerName, server = string.find(k, "^(.+)@(.+)$");
				if (not servers[server]) then
					servers[server] = 1;
				else
					servers[server] = servers[server] + 1;
				end
			end
		end
	end
	for k, v in pairs(servers) do
		tinsert(serversort, k);
	end
	sort(serversort);

	local dropdown, info;
	dropdown = CT_ExpenseHistoryFrameServerDropDown;
	info = { };
	info.text = "All servers";
	info.value = nil;
	info.checked = ( not CT_ExpenseHistoryFrame.currServer );
	info.func = CT_EH_ServerDropDown_OnClick;
	UIDropDownMenu_AddButton(info);
	for k, v in ipairs(serversort) do
		info.text = v .. " (" .. servers[v] .. ")";
		info.value = v;
		info.checked = ( CT_ExpenseHistoryFrame.currServer == v );
		info.func = CT_EH_ServerDropDown_OnClick;
		UIDropDownMenu_AddButton(info);
	end
end

function CT_EH_ServerDropDown_OnClick(self)
	if ( self:GetID() == 1 ) then
		CT_ExpenseHistoryFrame.currServer = nil;
	else
		CT_ExpenseHistoryFrame.currServer = self.value;
	end
	-- Reset character pull down to "All characters"
	CT_ExpenseHistoryFrame.currPlayer = nil
	-- Re initialize character pull down so it only has players from selected server.
	CT_EH_DropDown_Initialize();
	CT_EH_UpdateSummary();
end

function CT_EH_Tab_OnClick(self)
	if ( self:GetID() == 1 ) then
		_G["CT_ExpenseHistoryFrameSummary"]:Show();
		_G["CT_ExpenseHistoryFrameLog"]:Hide();
		CT_EH_UpdateSummary();
	elseif ( self:GetID() == 2 ) then
		_G["CT_ExpenseHistoryFrameSummary"]:Hide();
		_G["CT_ExpenseHistoryFrameLog"]:Show();
		CT_EH_GenerateLog();
		CT_EH_SortLog();
		CT_EH_UpdateLog();
	end
	PlaySound(841);
	PanelTemplates_SetTab(CT_ExpenseHistoryFrame, self:GetID());
end

-- Find out if vendor is reagent vendor
--[[		-- REMOVED IN 8.2.5.6 -- it isn't really clear why this was even necessary
function CT_EH_IsVendor(tbl)
	for i = 1, GetMerchantNumItems(), 1 do
		local name, texture, price, quantity, numAvailable, isUsable = GetMerchantItemInfo(i);
		if ( name and tbl[strlower(name)] ) then
			return true;
		end
	end
	return false;
end
--]]

MerchantFrame:HookScript("OnShow", function(self)
--[[	if ( CT_EH_IsVendor(CT_EH_SCANFORREAGENTS) ) then		-- it isn't really clear why this was even necessary.
		MerchantFrame.reagentCost = 0;
	else
		MerchantFrame.reagentCost = nil;
	end
	if ( CT_EH_IsVendor(CT_EH_SCANFORAMMO) ) then
		MerchantFrame.ammoCost = 0;
	else
		MerchantFrame.ammoCost = nil;
	end
	local repairAllCost, canRepair = GetRepairAllCost();
	if ( canRepair ) then
		MerchantFrame.repairCost = 0;
	else
		MerchantFrame.repairCost = nil;
	end
--]]
	MerchantFrame.reagentCost = 0;
	MerchantFrame.ammoCost = 0;
	MerchantFrame.repairCost = 0;
end);

MerchantFrame:HookScript("OnHide", function(self)
	if ( MerchantFrame.reagentCost and MerchantFrame.reagentCost > 0 ) then
		CT_EH_AddExpense(MerchantFrame.reagentCost, "Reagent")
	end
	if ( MerchantFrame.ammoCost and MerchantFrame.ammoCost > 0 ) then
		CT_EH_AddExpense(MerchantFrame.ammoCost, "Ammo")
	end
	if ( MerchantFrame.repairCost and MerchantFrame.repairCost > 0 ) then
		CT_EH_AddExpense(MerchantFrame.repairCost, "Repair")
	end
	MerchantFrame.repairCost = nil;
	MerchantFrame.reagentCost = nil;
	MerchantFrame.ammoCost = nil;
end);

local CT_EH_SCANFORREAGENTS =
{
	"Arcane Powder",
	"Ankh",
	"Ashwood Seed",
	"Corpse Dust",
	"Demonic Figurine",
	"Devout Candle",
	"Flash Powder",
	"Flintweed Seed",
	"Holy Candle",
	"Hornbeam Seed",
	"Infernal Stone",
	"Ironwood Seed",
	"Maple Seed",
	"Rune of Portals",
	"Rune of Teleportation",
	"Sacred Candle",
	"Starleaf Seed",
	"Stranglethorn Seed",
	"Symbol of Divinity",
	"Symbol of Divinity",
	"Symbol of Kings",
	"Wild Berries",
	"Wild Quillvine",
	"Wild Spineleaf",
	"Wild Thornroot",
}

local CT_EH_SCANFORAMMO =
{
	"Accurate Slugs",
	"Balanced Throwing Dagger",
	"Blackflight Arrow",
	"Blacksteel Throwing Dagger",
	"Crude Throwing Axe",
	"Deadly Throwing Axe",
	"Felbane Slugs",
	"Frostbite Bullets",
	"Gleaming Throwing Axe",
	"Halaani Grimshot",
	"Halaani Razorshaft",
	"Heavy Throwing Dagger",
	"Heavy Shot",
	"Hellfire Shot",
	"Ice Threaded Arrow",
	"Ice Threaded Bullet",
	"Impact Shot",
	"Ironbite Shell",
	"Jagged Arrow",
	"Jagged Throwing Axe",
	"Keen Throwing Knife",
	"Light Shot",
	"Mysterious Arrow",
	"Mysterious Shell",
	"Razor Arrow",
	"Rough Arrow",
	"Scout's Arrow",
	"Sharp Arrow",
	"Sharp Throwing Axe",
	"Small Throwing Knife",
	"Smooth Pebble",
	"Solid Shot",
	"Terrorshaft Arrow",
	"Timeless Arrow",
	"Timeless Shell",
	"Warden's Arrow",
	"Weighted Throwing Axe",
	"Wicked Arrow",
	"Wicked Throwing Dagger",
}

-- Hook BuyMerchantItem()
local localizedReagents, localizedAmmo;
local CT_EH_oldBuyMerchantItem = BuyMerchantItem;
function BuyMerchantItem(id, qty)
	local name, texture, price, quantity, numAvailable, isUsable = GetMerchantItemInfo(id);
	local realPrice = price*(qty or 1);
	CT_EH_oldBuyMerchantItem(id, qty);
	if (name) then
		if (not localizedReagents or not localizedAmmo) then
			localizedReagents = { };
			for __, val in ipairs(CT_EH_SCANFORREAGENTS) do
				localizedReagents[L["CT_ExpenseHistory/Reagent/" .. val]] = true;
			end
			localizedAmmo = { };
			for __, val in ipairs(CT_EH_SCANFORAMMO) do
				localizedAmmo[L["CT_ExpenseHistory/Ammo/" .. val]] = true;
			end
		end
		if ( MerchantFrame.reagentCost and localizedReagents[name] and realPrice <= GetMoney() ) then
			MerchantFrame.reagentCost = MerchantFrame.reagentCost + realPrice;
		end
		if ( MerchantFrame.ammoCost and localizedAmmo[name] and realPrice <= GetMoney() ) then
			MerchantFrame.ammoCost = MerchantFrame.ammoCost + realPrice;
		end
	end
end

function CT_EH_SendMail(target, subject, body)
	local price = SendMailCostMoneyFrame.staticMoney;
	if ( price <= GetMoney() and price > 0 ) then
		CT_EH_AddExpense(price, "Mail")
	end
end
hooksecurefunc("SendMail", CT_EH_SendMail);

-- Hook TakeTaxiNode()
CT_EH_oldTakeTaxiNode = TakeTaxiNode;
function CT_EH_newTakeTaxiNode(id)
	if ( GetMoney() >= TaxiNodeCost(id) and TaxiNodeCost(id) > 0 ) then
		CT_EH_AddExpense(TaxiNodeCost(id), "Flight")
	end
	CT_EH_oldTakeTaxiNode(id);
end
TakeTaxiNode = CT_EH_newTakeTaxiNode;

function CT_EH_AddExpense(cost, item)
	local key = UnitName("player") .. "@" .. GetRealmName();
	tinsert(CT_EH_History[key], { cost, item, time() });
	if (CT_ExpenseHistoryFrame:IsShown()) then
		if (PanelTemplates_GetSelectedTab(CT_ExpenseHistoryFrame) == 1) then
			CT_EH_UpdateSummary();
		else
			CT_EH_GenerateLog();
			CT_EH_SortLog();
			CT_EH_UpdateLog();
		end
	end
end


--------------------------------------------
-- CT_ExpenseHistoryFrame

function CT_ExpenseHistoryFrame_OnLoad(self)
		
		local tab1 = CreateFrame("Button", "CT_ExpenseHistoryFrameTab1", self, module:getGameVersion() >= 10 and "CharacterFrameTabTemplate" or "CharacterFrameTabButtonTemplate", 1)
		tab1:SetText(L["CT_ExpenseHistory/Summary/Heading"])
		tab1:SetPoint("CENTER", self, "BOTTOMLEFT", 60, -8)
		tab1:SetSize(115, 32)
		tab1:SetFrameLevel(2)
		tab1:SetScript("OnClick", CT_EH_Tab_OnClick)
			
		local tab2 = CreateFrame("Button", "CT_ExpenseHistoryFrameTab2", self, module:getGameVersion() >= 10 and "CharacterFrameTabTemplate" or "CharacterFrameTabButtonTemplate", 2)
		tab2:SetText(L["CT_ExpenseHistory/Log/Heading"])
		tab2:SetPoint("LEFT", tab1, "RIGHT", -16, 0)
		tab2:SetSize(115, 32)
		tab2:SetFrameLevel(2)
		tab2:SetScript("OnClick", CT_EH_Tab_OnClick)

		self:RegisterEvent("PLAYER_LOGIN");
		self.elapsed = 0;
		PanelTemplates_SetNumTabs(self, 2);
		PanelTemplates_SetTab(self, 1);
		Mixin(self, BackdropTemplateMixin or { });
		self:SetBackdrop({
			bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
			edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
			tile = true,
			tileSize = 32,
			edgeSize = 32,
			insets = { left = 11, right = 12, top = 12, bottom = 11 },
		});
end


--------------------------------------------
-- Options Frame Code

module.frame = function()
	local options = {};
	local yoffset = 5;
	local ysize;

	-- Tips
	ysize = 60;
	options["frame#tl:0:-" .. yoffset .. "#br:tr:0:-".. (yoffset + ysize)] = {
		"font#tl:5:0#v:GameFontNormalLarge#Tips",
		"font#t:0:-25#s:0:30#l:13:0#r#You can use /eh, /cteh, or /expensehistory to open the CT_ExpenseHistory window.#0.6:0.6:0.6:l",
	};

	-- General Options
	yoffset = yoffset + ysize + 15;
	ysize = 140;
	options["frame#tl:0:-" .. yoffset .. "#br:tr:0:-".. (yoffset + ysize)] = {
		"font#tl:5:0#v:GameFontNormalLarge#Options",
		"font#t:5:-25#s:0:30#l:13:0#r#Click the button below to open the CT_ExpenseHistory window.#0.6:0.6:0.6:l",
		"font#t:5:-60#s:0:30#l:13:0#r#Shift-click the button if you want to leave the CTMod Control Panel open.#0.6:0.6:0.6:l",
		["button#t:0:-100#s:120:30#n:CT_ExpenseHistory_OpenWindow_Button#v:GameMenuButtonTemplate#Open window"] = {
			["onclick"] = function(self)
				CT_ExpenseHistoryFrame:Show();
				if (not IsShiftKeyDown()) then
					module:showControlPanel(false);
				end
			end,
		},
	};
	yoffset = yoffset + ysize;

	return "frame#all", options;
end
