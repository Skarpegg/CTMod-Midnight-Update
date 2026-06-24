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

--------------------------------------------
-- Initialization

local module = select(2, ...)
local _G = getfenv(0);

local MODULE_NAME = "CT_MailMod";
local MODULE_VERSION = strmatch(C_AddOns.GetAddOnMetadata(MODULE_NAME, "version"), "^([%d.]+)");

module.name = MODULE_NAME;
module.version = MODULE_VERSION;

CT_Library:registerModule(module);
_G[MODULE_NAME] = module;

-- Max attachment slots
--
-- This is used in CT_MailMod_MailLog.lua to limit the number of attachments displayed.
-- This is used in CT_MailMod_MailStructure_Outgoing.lua
module.MAX_ATTACHMENTS = 12;

-- The other programs use Blizzard's constants (refer to MailFrame.lua) for the maximum
-- number of receive slots. This is currently more (16) than players are currently
-- allowed to send (12):
-- ATTACHMENTS_MAX_RECEIVE = 16;

-- Maximum number of send slots (as defined by Blizzard in MailFrame.lua):
-- ATTACHMENTS_MAX_SEND = 12;

module.processingSpeed1 = 0.05;  -- time in seconds between calls to the mail updater function (which processes actions).
module.processingSpeed2 = 0.05;  -- minimum time in seconds between mail API function calls (ie. TakeInboxItem, etc).
module.timeoutValue = 30;  -- time in seconds until the current action times out (may not apply to some actions or static popups)

--[[
module.mailmodDebug = true;
function module:debugprint(...)
	if (module.mailmodDebug) then
		print(...);
	end
end
]]

--------------------------------------------
-- Table Pool

do
	local tblPool = setmetatable({ }, { __mode="v" }); -- Weak table (values)
	
	function module:getTable()
		return tremove(tblPool) or { };
	end
	
	function module:releaseTable(tbl)
		module:clearTable(tbl, true);
		tinsert(tblPool, tbl);
	end
end

--------------------------------------------
-- Mail Updaters

do
	local updaters = {};  -- functions to be called
	local startValues = {};  -- number of seconds between calls
	
	function module:registerMailUpdater(t, func)
		startValues[func] = t;
		updaters[func] = t;
	end

	function module:zeroMailUpdater(func)
		-- Zero the time remaining until the updater function is run.
		if (updaters[func]) then
			updaters[func] = 0;
		end
	end
	
	local f = CreateFrame("Frame");
	local pairs = pairs; -- Local copy for speed
	
	f:SetScript("OnUpdate", function(self, elapsed, ...)
		for key, value in pairs(updaters) do
			value = value - elapsed;
			if ( value <= 0 ) then
				-- It is time to call the updater function.
				local delay = key(module, key);
				-- Reschedule the updater function.
				if (delay) then
					-- Use the number of seconds returned from the updater.
					updaters[key] = delay + value;
				else
					-- Use the original number of seconds.
					updaters[key] = startValues[key] + value;
				end
			else
				-- Update the time remaining.
				updaters[key] = value;
			end
		end
	end);
	
	f:SetScript("OnEvent", function(self, event, ...)
		if ( event == "MAIL_SHOW" ) then
			self:Show();
		else
			self:Hide();
		end
	end);
	
	f:RegisterEvent("MAIL_SHOW");
	f:RegisterEvent("MAIL_CLOSED");
	f:Hide();
end

--------------------------------------------
-- Stuff to do when the mailbox gets opened/closed.

local suppressDownloadPrint;  -- Set in mailboxOpened(), and used in testforNewMail().

do
	local moneyAtOpen;
	local mailboxOpen;

	local function mailboxOpened()
		mailboxOpen = true;
		moneyAtOpen = GetMoney();
		suppressDownloadPrint = true;
		module.tooMuchMail = false;
		module:raiseCustomEvent("INCOMING_UPDATE");
	end

	local function mailboxClosed()
		
		if (not mailboxOpen) then
			-- Game may send two MAIL_CLOSED events.
			-- We only need to deal with one of them.
			return;
		end

		module:cancelProcessing();

		if (module:getOption("showMoneyChange")) then
			local moneyDifference = GetMoney() - moneyAtOpen;
			if (moneyDifference < 0) then
				print(format(module.text["CT_MailMod/MONEY_DECREASED"], module:convertMoneyToString(-moneyDifference)));
			elseif (moneyDifference > 0) then
				print(format(module.text["CT_MailMod/MONEY_INCREASED"], module:convertMoneyToString(moneyDifference)));
			end
		end

		mailboxOpen = nil;
	end

	module:regEvent("MAIL_SHOW", mailboxOpened)
	
	module:regEvent("PLAYER_LOGOUT", mailboxClosed)  -- when player logs out or reloads ui
	
	--module:regEvent("PLAYER_INTERACTION_MANAGER_FRAME_SHOW", function(__, type) if type == Enum.PlayerInteractionType.MailInfo then mailboxOpened() end end)
	module:regEvent("PLAYER_INTERACTION_MANAGER_FRAME_HIDE", function(__, type) if type == Enum.PlayerInteractionType.MailInfo then mailboxClosed() end end)  -- formerly MAIL_CLOSED
end

--------------------------------------------
-- Watch for an increase in the number of items in the inbox.

do
	local lastMailCount = 0;

	local function testForNewMail()
		-- If the number of messages increases while we're processing,
		-- then cancel the processing to avoid message selection issues.
		--
		-- The number of messages shouldn't increase unless something
		-- makes a call to CheckInbox() such as the "download" action
		-- (which we will account for), or some other addon.
		--
		-- Uses the addon's internal mailboxOpen status to stay safe in Retail
		if (mailboxOpen or (MailFrame and MailFrame:IsVisible())) then
			local mailCount = GetInboxNumItems();
			if (mailCount > lastMailCount) then

				-- Attempt to access the item links for all attachments.
				-- The game usually returns an item link the first time
				-- GetInboxItemLink() is called for an attachment. However,
				-- for some people since the 3.3 patch, it has been
				-- returning nil as the link, but only the first time
				-- it is called. Subsequent calls for an item always
				-- seem to return a valid link (even after exiting and
				-- restarting the game).
				-- This loop is to ensure we have called the function
				-- at least once before the user does something that will
				-- result in a call to the function, thus hopefully preventing
				-- it from returning a nil item link.
				-- Made safe for Retail where ATTACHMENTS_MAX_RECEIVE has been moved or removed
				local maxReceive = ATTACHMENTS_MAX_RECEIVE or (unzipping and 16) or 16;
				for i = lastMailCount + 1, mailCount do
					for j = 1, maxReceive do
						GetInboxItemLink(i, j);
					end
				end

				-- If not processing, then unselect all messages when the inbox
				-- count goes up.
				if (module.isProcessing) then
					-- Currently processing.
					-- If user isn't downloading mail, then cancel processing.
					local actionType = module:getCurrentActionType();
					if (actionType ~= "download") then
						print(module.text["CT_MailMod/MAIL_DOWNLOAD_END"]);
						module:cancelProcessing();
						module:closeOpenMail();
					end
				else
					-- Not processing, but the inbox count went up.
					if (suppressDownloadPrint) then
						-- Only suppress this message once (when the mailbox opens).
						suppressDownloadPrint = false;
					else
						print(module.text["CT_MailMod/MAIL_DOWNLOAD_END"]);
					end
					-- Make sure nothing is selected.
					module:inboxUnselectAll();
					module:inboxUpdateSelection();
				end
			end
			lastMailCount = mailCount;
		end
	end

	module:regEvent("MAIL_INBOX_UPDATE", testForNewMail);
end

--------------------------------------------
-- Special errors

do
	local lootErrors = {
		[ERR_ITEM_MAX_COUNT] = true,  -- "You can't carry any more of those items."
		[ERR_INV_FULL] = true,  -- "Inventory is full."
	};

	local function onEvent(event, arg1, ...)
		if (event == "UI_ERROR_MESSAGE" and lootErrors[arg1]) then
			-- Only worry about the error if we are currently doing processing.
			if (not module.isProcessing) then
				return;
			end

			-- The errors we're currently checking for will only occur
			-- when we're retrieving mail item attachments (ie. incoming processing).

			local mail, data, action;

			-- Determine if the current action is for a mail object.
			data, action = module:currentMailAction();
			mail = nil;
			if (type(action) == "function") then
				if (data and data.mail) then
					-- This action is for a mail object.
					mail = data.mail;
				end
			elseif (type(action) == "string") then
				-- Old style mail action (shouldn't be any more of these).
				mail = data;
			end

			if (mail) then
				-- If there is still a cod amount, then this was the first item
				-- we tried to take from a cod mail. Because the take failed, the
				-- cod amount was not paid. So, make sure that the cod amount
				-- does not get logged.
				if (mail.codAmount > 0) then
					mail.logMoney = 0;
				end
				-- Forget the last item since it wasn't actually taken.
				if (mail.logItems) then
					tremove(mail.logItems);
				end
			end

			-- Log anything pending and then log the error message.
			module:setText("CT_MailMod/MAIL_LOOT_ERROR_WORK", arg1);
			module:logIncoming(false, mail, "CT_MailMod/MAIL_LOOT_ERROR_WORK");

			if (mail) then
				if (arg1 == ERR_ITEM_MAX_COUNT) then
					-- User is carrying too many of the item they tried to take.
					local actionType = data.actionType;
					if (actionType == "takeall") then
						-- Advance to the next attachment number.
						mail:advanceToNextItem();
					elseif (actionType == "takeitem") then
						-- Cancel the take of the current item.
						mail:cancelTakeItem();
					else
						module:cancelProcessing();
					end
				else
					-- User's inventory is full.
					-- Stop all processing so user can deal with the inventory situation.
					module:cancelProcessing();
				end
			else
				module:cancelProcessing();
			end
		end
	end

	module:regEvent("UI_ERROR_MESSAGE", onEvent);
end

--------------------------------------------
-- Slash command.

local function slashCommand(msg)
	module:showModuleOptions();
end

module:setSlashCmd(slashCommand, "/ctmail", "/ctmm", "/ctmailmod", "/ctcourrier");
-- enUS: /ctmail, /ctmm, /ctmailmod
-- frFR: /ctcourrier
