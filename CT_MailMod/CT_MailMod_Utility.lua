------------------------------------------------
--                 CT_MailMod                 --
--                                            --
-- Mail several items at once with almost no  --
-- effort at all. Also takes care of opening  --
-- several mail items at once, reducing the   --
-- time spent on maintaining the inbox for    --
-- bank mules and such.                       --
-- Please do not modify or otherwise          --
-- redistribute this without the consent of   --
-- the CTMod Team. Thank you.                 --
------------------------------------------------

local _G = getfenv(0);
local module = _G["CT_MailMod"];

--------------------------------------------
-- Utility Functions

function module:getTimeFromOffset(dayOffset)
	local seconds = math.floor(dayOffset*(24*3600)+0.5);
	local tbl = date("*t");
	tbl.sec = tbl.sec + seconds;
	return time(tbl);
end

function module:getPlayerName(name)
	name = name or UnitName("player");
	return ("%s @ %s"):format(name, GetRealmName());
end

function module:filterName(str)
	local name, realm = str:match("^(.-) @ (.+)$");
	if ( realm == GetRealmName() ) then
		return name;
	else
		return str;
	end
end

--------------------------------------------
-- Custom Events

do
	local events = { };
	
	function module:regCustomEvent(event, func)
		local tbl = events[event] or { };
		tinsert(tbl, func);
		events[event] = tbl;
	end
	
	function module:raiseCustomEvent(event, ...)
		local tbl = events[event];
		if ( tbl ) then
			for key, value in ipairs(tbl) do
				value(module, event, ...);
			end
		end
	end
end

--------------------------------------------
-- Block trades when mailbox is open

do
	local blockOption;
	local blockOriginal;
	local blockcvar = "blockTrades";

	local function restoreBlockState()
		-- Restore blocking to its original state, which could be disabled or enabled.
		if (blockOriginal) then
			if C_CVar and C_CVar.SetCVar then
				C_CVar.SetCVar(blockcvar, blockOriginal);
			else
				SetCVar(blockcvar, blockOriginal);
			end
			blockOriginal = nil;
		end
	end

	local function enableBlockState()
		-- Change blocking state to enabled.
		if (blockOriginal == nil) then
			-- Save the original blocking state before we change it.
			if C_CVar and C_CVar.GetCVar then
				blockOriginal = C_CVar.GetCVar(blockcvar);
			else
				blockOriginal = GetCVar(blockcvar);
			end
		end
		-- Blocking is now enabled.
		if C_CVar and C_CVar.SetCVar then
			C_CVar.SetCVar(blockcvar, "1");
		else
			SetCVar(blockcvar, "1");
		end
	end

	-- If leaving the world, or the window is being closed, then restore
	-- blocking to its original state.
	module:regEvent("PLAYER_LEAVING_WORLD", restoreBlockState);
	module:regEvent("MAIL_CLOSED", restoreBlockState);

	-- If the mailbox frame has just opened, and the user wants to block while
	-- at the mailbox, then start blocking.
	module:regEvent("MAIL_SHOW", function()
		if (blockOption) then
			enableBlockState();
		end
	end);

	-- Configure blocking option.
	module.configureBlockTradesMail = function(block)
		blockOption = block; -- Save the option's value in a local variable
		if (blockOption) then
			-- User wants to block trades while at this window.
			-- If the frame is currently shown, then start blocking.
			if ( (MailFrame and MailFrame:IsShown()) ) then
				enableBlockState();
			end
		else
			-- User does not want to block trades while at this window.
			-- If we are currently blocking trades (ie. if we have the original
			-- blocking state saved), then restore to the original blocking state.
			if (blockOriginal) then
				restoreBlockState();
			end
		end
	end
end

--------------------------------------------
-- Open/close bags

do
	-- Blizzard's code in MailFrame.lua...
	--   The backpack opens when the mail frame is shown.
	--   Clicking the mail frame's upper right close button does not close the backpack.
	--   Pressing ESC to close the mail frame does close the backpack.

	-- To prevent taint in WoW 10.0.0, remove ContainerFrameItemButtonMixin:SetBagID() before it ever gets called but only if CT_Core isn't already doing this and the user is not combining bags
	module:regEvent("PLAYER_LOGIN", function()
		if ContainerFrameMixin and not (CT_Core and not CT_Core:getOption("disableBagAutomation") or C_CVar.GetCVarBool("combinedBags")) and (module.opt.openAllBags or module.opt.openBackpack or module.opt.openNoBags or module.opt.closeAllBags) then
			-- Safe assignment for modern WoW Retail
			if ContainerFrameItemButtonMixin and ContainerFrameItemButtonMixin.SetBagID then
				ContainerFrameItemButtonMixin.SetBagID = nop
			else
				local maxContainers = NUM_CONTAINER_FRAMES or 5;
				for i=1, maxContainers do
					for j=1, 36 do
						local frame = _G["ContainerFrame"..i.."Item"..j]
						if frame then
							frame.SetBagID = nop
						end
					end
				end
			end
		end
	end)

	local function mailboxOpened()
		local openAllBags = module.opt.openAllBags;
		local openBackpack = module.opt.openBackpack;
		local openNoBags = module.opt.openNoBags;
		
		if (openAllBags or openBackpack or openNoBags) and not C_CVar.GetCVarBool("combinedBags") then
			-- First, close all bags.
			-- This also ensures that no bags are open when we call OpenAllBags()
			-- since that function will do nothing if at least one bag is already open.
			CloseAllBags();
			if (openBackpack) then
				-- Open just the backpack
				OpenBackpack();
			elseif (openAllBags) then
				-- Open all the bags
				OpenAllBags();
			end
		end
	end

	local function mailboxClosed()
		if (module.opt.closeAllBags) then
			-- Close all bags.
			CloseAllBags();
		end
	end

	module:regEvent("MAIL_SHOW", mailboxOpened);
	module:regEvent("MAIL_CLOSED", mailboxClosed);
end

--------------------------------------------
-- Convert money into a string.

function module:convertMoneyToString(copper)
	local amount3 = module.text["CT_MailMod/SEND_MAIL_MONEY_SUBJECT_GOLD"];
	local amount2 = module.text["CT_MailMod/SEND_MAIL_MONEY_SUBJECT_SILVER"];
	local amount1 = module.text["CT_MailMod/SEND_MAIL_MONEY_SUBJECT_COPPER"];
	local gold, silver, mult;
	if (copper < 0) then
		copper = -copper;
		mult = -1;
	else
		mult = 1;
	end
	gold = floor(copper / 10000);
	copper = copper - gold * 10000;
	silver = floor(copper / 100);
	copper = copper - silver * 100;
	if (gold > 0) then
		return amount3:format(mult * gold, mult * silver, mult * copper);
	elseif (silver > 0) then
		return amount2:format(mult * silver, mult * copper);
	else
		return amount1:format(mult * copper);
	end
end
