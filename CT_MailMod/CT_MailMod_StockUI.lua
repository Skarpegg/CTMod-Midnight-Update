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
-- Constants

local MAX_CONTAINER_ITEMS = MAX_CONTAINER_ITEMS or 36;		-- This constant was deprecated in WoW 8.3

--------------------------------------------
-- Modified Stock UI for the Inbox

-- Move the icons 20 to the right of where Blizzard puts them.
do
	-- Safeguard: only runs if the classic MailItem buttons actually exist in this client
	if MailItem1 then
		MailItem1:SetPoint("TOPLEFT", "InboxFrame", "TOPLEFT", 13 + 20, -70);
		local item;
		local maxDisplay = INBOXITEMS_TO_DISPLAY or 7;
		for i = 1, maxDisplay, 1 do
			item = _G["MailItem"..i];
			if item then
				item:SetWidth(280);
				local expireTime = _G["MailItem" .. i .. "ExpireTime"];
				if expireTime then
					expireTime:SetPoint("TOPRIGHT", item, "TOPRIGHT", 10, -4);
				end
			end
		end
	end
end

-- Some font strings
local fsNumSelected;
local fsInboxCount;
do
	-- Number of selected messages
	fsNumSelected = InboxFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall");
	fsNumSelected:SetText("");
	fsNumSelected:SetPoint("TOPLEFT", InboxFrame, "TOPLEFT", 63, -48);

	-- Number of messages in the inbox
	fsInboxCount = InboxFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall");
	fsInboxCount:SetText("");
	fsInboxCount:SetPoint("TOPLEFT", InboxFrame, "TOPLEFT", 63, -8);
	if MailFrame.TitleContainer then
		fsInboxCount:SetParent(MailFrame.TitleContainer)
	end
end


-- Add the "Mailbox Overflow" button
do
	
	module:getFrame( {
		["button#n:CTMailModMailboxButton#s:130:30#t:b:0:-5#v:UIPanelButtonTemplate#Overflow: 51"] = {
			["onload"] = function(self)
				self:SetNormalFontObject("GameFontHighlightSmall");
				self:SetHighlightFontObject("GameFontHighlightSmall");
				self:SetDisabledFontObject("GameFontHighlightSmall");
			end,
			["onclick"] = function(self, arg1)
				if ( arg1 == "LeftButton" ) then
					if (not module.isProcessing) then
						module:closeOpenMail();
						local data = {actionType = "download"};
						module:addMailAction(data, module.actionDownloadMail);
						module:beginIncomingProcessing();
					end
				end
			end,
			["onenter"] = function(self)
				GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT", 0, 5);
				GameTooltip:SetText(module.text["CT_MailMod/MAILBOX_BUTTON_TIP1"]);
				GameTooltip:Show();
			end,
			["onleave"] = function(self)
				GameTooltip:Hide();
			end
		},
	}, InboxTooMuchMail);
	
	local reloadmailtimer = nil;
	local functionrunning = nil;
	
	local function enableReloadMailboxButton()
		if (reloadmailtimer == nil) then
			return;
		elseif (reloadmailtimer > GetTime()) then
			CTMailModMailboxButton:SetText(format(module.text["CT_MailMod/MAILBOX_DOWNLOAD_MORE_SOON"],floor(reloadmailtimer - GetTime())));  --Download more mail in %d seconds
			C_Timer.After(0.5,enableReloadMailboxButton);
		else
			CTMailModMailboxButton:SetText(module.text["CT_MailMod/MAILBOX_DOWNLOAD_MORE_NOW"]);
			CTMailModMailboxButton:Enable();
			reloadmailtimer = nil;
			functionrunning = nil;
		end
			
	end
	
	local function secondsUntilAllowed()
		if (C_Mail and C_Mail.CanCheckInbox) then
			-- Introduced in WoW 8.3
			return select(2, C_Mail.CanCheckInbox());
		else
			-- Classic compatibility
			return 60;
		end
	end
	
	function module:inboxUpdateMailboxCount()
		-- Update the button that shows the number of items still in the mailbox.
		-- (the number of items that have not been downloaded to the inbox).
		local button = CTMailModMailboxButton;
		if (not module.opt.inboxShowMailbox) then
			button:Hide();
			return;
		else
			button:Show();
		end
		local enable;
		local mailCount, totalCount = GetInboxNumItems();
		if (totalCount) then
			if (totalCount > mailCount) then
				if (not module.maxShownMails) then
					module.maxShownMails = mailCount;  -- Max is currently 50 (Nov 23 2009)
				end
				if (mailCount < module.maxShownMails) then
					enable = true;
				end
			end
			button:SetText(format(module.text["CT_MailMod/MAILBOX_OVERFLOW_COUNT"], totalCount - mailCount));
			button:Show();
			if (reloadmailtimer == nil) then
				reloadmailtimer = GetTime() + secondsUntilAllowed();
			end
		else
			button:Hide();
		end
		if (button.mailmodEnable ~= nil) then
			enable = button.mailmodEnable;  -- Forced enable/disable
		end
		if (enable) then
			if (button:IsEnabled() == false and not functionrunning) then
				functionrunning = true;
				enableReloadMailboxButton();
			end
		else
			button:Disable();
		end
	end
	

	local function customEvents_MailboxButton(self, event, data)
		local button = CTMailModMailboxButton;
		if (event == "INCOMING_UPDATE") then
			module:inboxUpdateMailboxCount();

		elseif (event == "INCOMING_START") then
			-- Disable everything
			button.mailmodEnable = false;
			button:Disable();

		elseif (event == "INCOMING_STOP") then
			-- Restore everything
			button.mailmodEnable = nil;
			module:inboxUpdateMailboxCount();
		end
	end
	module:regCustomEvent("INCOMING_UPDATE", customEvents_MailboxButton);
	module:regCustomEvent("INCOMING_START", customEvents_MailboxButton);
	module:regCustomEvent("INCOMING_STOP", customEvents_MailboxButton);
end

-- The "Open Selected" and "Return Selected" buttons
do

	local pressedOpenAll = false;	-- indicates the user pressed OpenAllMail, Blizzard's button that is overloaded below

	module:getFrame( {
		["button#n:CTMailModOpenSelected#s:68:25#l:tl:143:-39.5#v:UIPanelButtonTemplate#" .. module.text["CT_MailMod/Inbox/OpenSelectedButton"]] = {
			["onclick"] = function(self, arg1)
				if ( arg1 == "LeftButton" ) then
					if (module.isProcessing) then
						if (pressedOpenAll) then
							OpenAllMail:SetText(OPEN_ALL_MAIL_BUTTON)
							pressedOpenAll = false
						end
						module:cancelProcessing()
					else
						if (module:inboxGetNumSelected() == 0) then
							DEFAULT_CHAT_FRAME:AddMessage(module.text["CT_MailMod/NOTHING_SELECTED"])
						else
							if (IsShiftKeyDown()) then
								-- Only open mail from the auction house
								local hasAHMessages = false
								local patterns =
								{
									AUCTION_EXPIRED_MAIL_SUBJECT:sub(1,-4),			-- removes " %s" or "%s."
									--AUCTION_INVOICE_MAIL_SUBJECT:sub(1,-4),
									AUCTION_OUTBID_MAIL_SUBJECT:sub(1,-4),
									AUCTION_REMOVED_MAIL_SUBJECT:sub(1,-4),
									AUCTION_SOLD_MAIL_SUBJECT:sub(1,-4),
									AUCTION_WON_MAIL_SUBJECT:sub(1,-4),
								}
								for i = 1, GetInboxNumItems() do
									--if (GetInboxInvoiceInfo(i)) then
									if (module.selectedMail[i]) then
										local subject = select(4,GetInboxHeaderInfo(i))
										if (
											subject:find(patterns[1]) 
											or subject:find(patterns[2])
											or subject:find(patterns[3])
											or subject:find(patterns[4])
											or subject:find(patterns[5])
										) then
											hasAHMessages = true
										else							
											module.selectedMail[i] = false
											module.selectAllMail = false
										end
									end
								end
								module:inboxUpdateSelection()
								if (hasAHMessages) then
									module:closeOpenMail()
									module:retrieveSelected()
								else
									DEFAULT_CHAT_FRAME:AddMessage(module.text["CT_MailMod/NOTHING_FROM_AH"])
								end
							else
								module:closeOpenMail()
								module:retrieveSelected()
							end
						end
					end
				end
			end,
			["onenter"] = function(self)
				module:displayTooltip(self, {module.text["CT_MailMod/Inbox/OpenSelectedTip"], "|n|c0080A0FF" .. SHIFT_KEY .. "|r - " .. module.text["CT_MailMod/Inbox/OpenSelectedTip2"] .. "#0.9:0.9:0.9"}, "ANCHOR_TOPLEFT", 30, -60)
			end,
			["onload"] = function(self)
				module:registerConflictResolution("ClassicGuildBank", 1, function()			
					-- move our frame down a bit and make it smaller, so there is more room for them
					self:SetPoint("LEFT", InboxFrame, "TOPLEFT", 155, -49.5)
					self:SetSize(65, 19)
					self:SetNormalFontObject("GameFontNormalSmall")
				end);
			end
		},
		["button#n:CTMailModReturnSelected#s:68:25#l:tl:212:-39.5#v:UIPanelButtonTemplate#" .. module.text["CT_MailMod/Inbox/ReturnSelectedButton"]] = {
			["onclick"] = function(self, arg1)
				if ( arg1 == "LeftButton" ) then
					if (module:inboxGetNumSelected() == 0) then
						DEFAULT_CHAT_FRAME:AddMessage(module.text["CT_MailMod/NOTHING_SELECTED"]);
					else
						module:closeOpenMail();
						module:returnSelected();
					end
				end
			end,
			["onenter"] = function(self)
				GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT", 30, -60);
				GameTooltip:SetText(module.text["CT_MailMod/Inbox/ReturnSelectedTip"]);
				GameTooltip:Show();
			end,
			["onleave"] = function(self)
				GameTooltip:Hide();
			end,
			["onload"] = function(self)
				module:registerConflictResolution("ClassicGuildBank", 1, function()			
					-- move our frame down a bit and make it smaller, so there is more room for them
					self:SetPoint("LEFT", InboxFrame, "TOPLEFT", 219, -49.5);
					self:SetSize(65, 19);
					self:SetNormalFontObject("GameFontNormalSmall");
				end);
			end
		},
	}, InboxFrame);


	-- Override Blizzard's OpenAllMail button.

	module:regCustomEvent("INCOMING_START", function()
		OpenAllMail:Disable()
	end)

	module:regCustomEvent("INCOMING_STOP", function()
		if (pressedOpenAll) then
			pressedOpenAll = false;
			OpenAllMailMixin.OnClick(OpenAllMail)
		else
			OpenAllMail:Enable()
		end

	end)

	OpenAllMail:SetScript("OnClick", function(self)		
		module:inboxSelectAll()
		if (module:inboxGetNumSelected() > 0) then
			pressedOpenAll = true
			OpenAllMail:SetText(OPEN_ALL_MAIL_BUTTON_OPENING)
			CTMailModOpenSelected:Click("LeftButton")
		else
			return false
		end

	end)

	function module:updateOpenCloseButtons()
		if (module.opt.showCheckboxes) then
			CTMailModOpenSelected:Show();
			CTMailModReturnSelected:Show();
		else
			CTMailModOpenSelected:Hide();
			CTMailModReturnSelected:Hide();
		end
	end

	local function customEvents_OpenReturn(self, event, data)
		if (event == "INCOMING_START") then
			CTMailModOpenSelected:SetText(module.text["CT_MailMod/STOP_SELECTED"]);
			CTMailModOpenSelected:Enable();
			CTMailModReturnSelected:Hide();

		elseif (event == "INCOMING_STOP") then
			-- Restore everything
			CTMailModOpenSelected:SetText(module.text["CT_MailMod/Inbox/OpenSelectedButton"]);
			CTMailModOpenSelected:Enable();
			CTMailModReturnSelected:Show();
		end
	end
	module:regCustomEvent("INCOMING_START", customEvents_OpenReturn);
	module:regCustomEvent("INCOMING_STOP", customEvents_OpenReturn);

end

-- Select All checkbox, mail selection checkboxes, and mail numbers.
local checkboxes = { };
do
	local checkboxTbl;

	-- The Select All checkbox
	module:getFrame( {
		["checkbutton#n:CTMailModSelectAll#s:24:24#l:tl:59:-38#v:InterfaceOptionsCheckButtonTemplate##1:0.82:0"] = {
			["onclick"] = function(self, arg1)
				if (self:GetChecked()) then
					module:inboxSelectAll();
					PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON or 856);
				else
					module:inboxUnselectAll();
					PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_OFF or 857);
				end
				module:inboxUpdateSelection();
			end,
			["onload"] = function(self)
				-- Safeguard: if the text object or its parent lacks script methods in Retail, give them fallbacks
				if self.text then
					if not self.text.HookScript then self.text.HookScript = function() end end
					if not self.text.OnMouseDown then self.text.OnMouseDown = function() end end
				end
				if not self.HookScript then self.HookScript = function() end end
				if not self.OnMouseDown then self.OnMouseDown = function() end end

				self.text:SetText(module.text["CT_MailMod/SELECT_ALL"]);
				self.text:SetPoint("LEFT", self, "RIGHT", 1, 0);
				self:SetHitRectInsets(0, -55, 0, 0);
				module:registerConflictResolution("ClassicGuildBank", 1, function(cgbButton)		
					-- ask the ClassGuildBank button to move up a bit and be smaller
					cgbButton:SetSize(129, 19);
					cgbButton:SetNormalFontObject("GameFontNormalSmall");
					cgbButton:ClearAllPoints();
					cgbButton:SetPoint('BOTTOM', 28, 471);
				end);
			end,
			["onenter"] = function(self)
				self.text:SetTextColor(1, 1, 1);
			end,
			["onleave"] = function(self)
				self.text:SetTextColor(1, 0.82, 0);
			end,
		},
	}, InboxFrame);

	function module:updateSelectAllCheckbox()
		if (module.opt.showCheckboxes) then
			CTMailModSelectAll:Show();
			fsNumSelected:Show();
		else
			CTMailModSelectAll:Hide();
			fsNumSelected:Hide();
		end
	end

	local similarSubjects = {
		(gsub(AUCTION_EXPIRED_MAIL_SUBJECT, "%%s", ".*")),  -- "Auction expired: %s";
		(gsub(AUCTION_OUTBID_MAIL_SUBJECT, "%%s", ".*")),  -- "Outbid on %s";
		(gsub(AUCTION_REMOVED_MAIL_SUBJECT, "%%s", ".*")),  -- "Auction cancelled: %s";
		(gsub(AUCTION_SOLD_MAIL_SUBJECT, "%%s", ".*")),  -- "Auction successful: %s";
		(gsub(AUCTION_WON_MAIL_SUBJECT, "%%s", ".*")),  -- "Auction won: %s";
		(gsub(COD_PAYMENT, "%%s", ".*")),  -- "COD Payment: %s";
	};

	-- The message checkboxes
	local function checkboxOnClick(self, button)
		-- User clicked on a message checkbox.
		local offset = (InboxFrame.pageNum - 1) * INBOXITEMS_TO_DISPLAY;
		local mailIndex = offset + self:GetID();
		local mailCount = GetInboxNumItems();
		local status;

		if (mailIndex > mailCount) then
			status = false;
			module:inboxUnselectSingle(mailIndex);
			module.rangeStart = nil;

		elseif (IsAltKeyDown()) then
			-- Alt Left-Click to select all messages with same/similar subject
			-- Alt Right-Click to unselect all messages with same/similar subject
			local subject = select(4, GetInboxHeaderInfo(mailIndex));
			if (not subject) then
				subject = "";
			end
			-- Try to find a pattern
			local pattern;
			for i, v in ipairs(similarSubjects) do
				if (subject:find(v)) then
					pattern = v;
					break;
				end
			end
			local text;
			if (not pattern) then
				-- If there is a quantity at the end of the subject then extract all but the quantity.
				local name = subject:match("^(.*) %(%d*%)$");  -- "Frostweave Cloth (20)"
				-- text == subject without any quantity
				-- pattern == subject with quantity pattern
				if (name) then
					text = name;
				else
					text = subject;
				end
				pattern = "^" .. text .. " %(%d*%)$";
			end
			if (button == "LeftButton") then
				status = true;  -- Select
				if (module.opt.inboxSubjectNew) then
					module:inboxUnselectAll();
				end
			else
				status = false; -- Unselect
			end
			for i = 1, mailCount do
				local found;
				local subject = select(4, GetInboxHeaderInfo(i));
				if (not subject) then
					subject = "";
				end
				if (text) then
					found = (subject == text);
					if (not found) then
						found = subject:find(pattern);
					end
				else
					found = subject:find(pattern);
				end
				if (found) then
					if (status) then
						module:inboxSelectSingle(i);
					else
						module:inboxUnselectSingle(i);
					end
				end
			end
			module.rangeStart = nil;

		elseif (IsControlKeyDown()) then
			-- Ctrl Left-Click to select all messages from this sender.
			-- Ctrl Right-Click to unselect all messages from this sender.
			local sentfrom = select(3, GetInboxHeaderInfo(mailIndex));
			if (not sentfrom) then
				sentfrom = UNKNOWN;
			end
			if (button == "LeftButton") then
				status = true;  -- Select
				if (module.opt.inboxSenderNew) then
					module:inboxUnselectAll();
				end
			else
				status = false; -- Unselect
			end
			for i = 1, mailCount do
				local sender = select(3, GetInboxHeaderInfo(i));
				if (not sender) then
					sender = UNKNOWN;
				end
				if (sentfrom == sender) then
					if (status) then
						module:inboxSelectSingle(i);
					else
						module:inboxUnselectSingle(i);
					end
				end
			end
			module.rangeStart = nil;

		elseif (IsShiftKeyDown() and not module.rangeStart) then
			-- Shift Click the first message in the range.
			-- This should not change the checkbox's state, so
			-- we need to counter the effect of the user's click.
			if (self:GetChecked()) then
				self:SetChecked(false);
			else
				self:SetChecked(true);
			end
			module.rangeStart = mailIndex;

		elseif (IsShiftKeyDown() and module.rangeStart) then
			-- Shift Left-Click the last message in the range to select.
			-- Shift Right-Click the last message in the range to unselect.
			local first, last;
			if (module.rangeStart > mailCount) then
				module.rangeStart = mailCount;
			end
			if (module.rangeStart < mailIndex) then
				first = module.rangeStart;
				last = mailIndex;
			else
				first = mailIndex;
				last = module.rangeStart;
			end
			if (button == "LeftButton") then
				status = true;  -- Select
				if (module.opt.inboxRangeNew) then
					module:inboxUnselectAll();
				end
			else
				status = false; -- Unselect
			end
			for i = first, last do
				if (status) then
					module:inboxSelectSingle(i);
				else
					module:inboxUnselectSingle(i);
				end
			end
			module.rangeStart = nil;
		else
			-- Unmodified click of the checkbox.
			if (self:GetChecked()) then
				status = true;
				module:inboxSelectSingle(mailIndex);
			else
				status = false;
				module:inboxUnselectSingle(mailIndex);
			end
			module.rangeStart = nil;
		end

		if (status) then
			PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON or 856);
		else
			PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_OFF or 857);
			module.selectAllMail = false;
		end

		module:inboxUpdateSelection();
	end

	local function checkboxFunc()
		if ( not checkboxTbl ) then
			checkboxTbl = {
				["onload"] = function(self)
					-- Safeguard: if the object lacks basic script methods in Retail, give it empty fallbacks
					if not self.HookScript then self.HookScript = function() end end
					if not self.OnMouseDown then self.OnMouseDown = function() end end
					
					self:RegisterForClicks("LeftButtonUp", "RightButtonUp");
				end,
				["onclick"] = checkboxOnClick,
				["onenter"] = function(self)
					if (module.opt.toolSelectMsg) then
						GameTooltip:SetOwner(self, "ANCHOR_BOTTOMRIGHT", 304, 42);
						GameTooltip:SetText(module.text["CT_MailMod/SELECT_MESSAGE_TIP1"]);
						GameTooltip:AddLine(module.text["CT_MailMod/SELECT_MESSAGE_TIP2"], 1, 1, 0.5);
						GameTooltip:Show();
					end
				end,
				["onleave"] = function(self)
					GameTooltip:Hide();
				end
			};
		end
		return "checkbutton#s:24:24#r:l:1:-5#v:UICheckButtonTemplate", checkboxTbl;
	end

	for i = 1, INBOXITEMS_TO_DISPLAY, 1 do
		local mcb, fs;

		-- Create a message checkbox
		mcb = module:getFrame(checkboxFunc, _G["MailItem" .. i], "CT_MailMod_InboxSelect" .. i);
		mcb:SetID(i);
		checkboxes[i] = mcb;
		mcb.text:Hide();
		mcb:Hide();

		-- Create a message number (normal)
		fs = mcb:CreateFontString(nil, "ARTWORK", "ChatFontSmall");
		fs:SetPoint("BOTTOM", mcb, "TOP", 0, 0);
		mcb.textSmall = fs;

		-- Create a message number (when it is the start of a range)
		fs = mcb:CreateFontString(nil, "ARTWORK", "ChatFontNormal");
		fs:SetPoint("BOTTOM", mcb, "TOP", 0, 0);
		mcb.textNormal = fs;
	end

	function module:inboxUpdateSelection()
		-- Update the mail selection checkboxes, the select all checkbox, and the number of items selected.
		local offset = (InboxFrame.pageNum - 1) * INBOXITEMS_TO_DISPLAY;
		local mailCount, totalCount = GetInboxNumItems();
		if (not totalCount) then
			totalCount = mailCount;
		end
		local mailIndex;
		local showMessageNumbers = module.opt.inboxShowNumbers;
		for key, chbox in ipairs(checkboxes) do
			mailIndex = key + offset;
			if (mailIndex > mailCount) then
				-- Hide it
				module.selectedMail[mailIndex] = false;
				chbox:Hide();
			else
				-- Show the line
				if (showMessageNumbers) then
					-- Show message numbers above the mail checkboxes.
					chbox:ClearAllPoints();
					chbox:SetPoint("RIGHT", _G["MailItem" .. key], "LEFT", 1, -6);
					if (module.rangeStart and module.rangeStart == mailIndex) then
						-- Start of a selection range (use a different color and font size)
						chbox.textNormal:SetTextColor(1, 0.82, 0);
						chbox.textNormal:SetText(mailIndex);
						chbox.textSmall:Hide();
						chbox.textNormal:Show();
					else
						-- Not start of a selection range
						chbox.textSmall:SetTextColor(1, 1, 1);
						chbox.textSmall:SetText(mailIndex);
						chbox.textSmall:Show();
						chbox.textNormal:Hide();
					end
				else
					-- Don't show message numbers above the mail checkboxes
					chbox:ClearAllPoints();
					chbox:SetPoint("RIGHT", _G["MailItem" .. key], "LEFT", 1, 0);
					chbox.textSmall:Hide();
					chbox.textNormal:Hide();
				end
				
				-- Show the checkbox ONLY if the feature isn't disabled (since CT_MailMod v8.1.0.2)
				if (module.opt.showCheckboxes) then
					chbox:Show();
				else
					chbox:Hide();
				end

			end
			-- Set or clear the check mark in the selection checkbox.
			if (module:inboxIsSelected(mailIndex)) then
				chbox:SetChecked(true);
			else
				chbox:SetChecked(false);
			end
		end
		-- Update the "Select All" checkbox.
		CTMailModSelectAll:SetChecked(module.selectAllMail);
		-- Show the number of mails that are currently selected in the inbox.
		if (module:inboxGetNumSelected() > 1) then
			fsNumSelected:SetText(format(module.text["CT_MailMod/NUMBER_SELECTED_PLURAL"], module:inboxGetNumSelected()));
		elseif (module:inboxGetNumSelected() == 1) then
			fsNumSelected:SetText(format(module.text["CT_MailMod/NUMBER_SELECTED_SINGLE"], module:inboxGetNumSelected()));
		else
			fsNumSelected:SetText(format(module.text["CT_MailMod/NUMBER_SELECTED_ZERO"], module:inboxGetNumSelected()));
		end
	end

	local function customEvents_MailCheckboxes(self, event, data)
		if (event == "INCOMING_UPDATE") then
			module:inboxUpdateSelection();

		elseif (event == "INCOMING_START") then
			-- Disable everything
			CTMailModSelectAll:Disable();
			for key, value in ipairs(checkboxes) do
				value:Disable();
			end

		elseif (event == "INCOMING_STOP") then
			-- Restore everything
			CTMailModSelectAll:Enable();
			for key, value in ipairs(checkboxes) do
				value:Enable();
			end
		end
	end
	module:regCustomEvent("INCOMING_UPDATE", customEvents_MailCheckboxes);
	module:regCustomEvent("INCOMING_START", customEvents_MailCheckboxes);
	module:regCustomEvent("INCOMING_STOP", customEvents_MailCheckboxes);
end


-- Quick action (expiry) buttons
local quickAction = { };
do
	local quickActionTbl;

	local function quickActionFunc()
		if ( not quickActionTbl ) then
			quickActionTbl = {
				["onload"] = function(self)
					if not self.HookScript then self.HookScript = function() end end
					if not self.OnMouseDown then self.OnMouseDown = function() end end
				end,
				["onclick"] = function(self, button)
					local offset = (InboxFrame.pageNum - 1) * INBOXITEMS_TO_DISPLAY;
					local mailIndex = offset + self:GetID();
					local action = self.ctmailmodAction;
					if (action == 1) then
						-- Return the message
						if (not module.isProcessing) then
							module:closeOpenMail();
							module:returnSingle(mailIndex);
						end
					elseif (action == 2) then
						-- Delete the message
						if (not module.isProcessing) then
							module:closeOpenMail();
							module:deleteSingle(mailIndex);
						end
					end
				end,
				["onenter"] = function(self)
					local action = self.ctmailmodAction;
					GameTooltip:SetOwner(self, "ANCHOR_RIGHT", 0, 16);
					if (action == 1) then
						GameTooltip:SetText(module.text["CT_MailMod/QUICK_RETURN_TIP1"]);
						GameTooltip:Show();
					elseif (action == 2) then
						GameTooltip:SetText(module.text["CT_MailMod/QUICK_DELETE_TIP1"]);
						GameTooltip:Show();
					end
				end,
				["onleave"] = function(self)
					GameTooltip:Hide();
				end
			};
		end

		return "button#s:28:28#tr:br:0:0", quickActionTbl;
	end

	for i = 1, INBOXITEMS_TO_DISPLAY, 1 do
		local btn;

		-- Expiry time buttons
		btn = module:getFrame(quickActionFunc, _G["MailItem" .. i .. "ExpireTime"], "CT_MailMod_InboxAction" .. i);
		btn:SetID(i);
		quickAction[i] = btn;
	end

	function module:inboxUpdateQuickAction()
		-- Update the quick action buttons in the inbox frame.
		local offset = (InboxFrame.pageNum - 1) * INBOXITEMS_TO_DISPLAY;
		local mailCount, totalCount = GetInboxNumItems();
		if (not totalCount) then
			totalCount = mailCount;
		end
		local mailIndex;
		local showQuickActions = module.opt.inboxShowExpiry;
		local quick;
		for key, chbox in ipairs(checkboxes) do
			mailIndex = key + offset;
			quick = quickAction[key];
			if (mailIndex > mailCount) then
				-- Hide the line
				quick:Hide();
			else
				-- Show the line
				local mailItem = _G["MailItem" .. key .. "Subject"];
				-- Quick action buttons
				if (showQuickActions) then
					mailItem:SetWidth(220);
					if (InboxItemCanDelete(mailIndex)) then
						-- Show the delete button below the expiry time.
						quick:SetHeight(26);
						quick:SetWidth(26);
						quick:SetPoint("TOPRIGHT", quick:GetParent(), "BOTTOMRIGHT", 3, 3);
						quick:SetNormalTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Up");
						quick:SetPushedTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Down");
						quick:SetHighlightTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Highlight");
						quick:Show();
						quick.ctmailmodAction = 2; -- delete
					else
						-- Show the return button below the expiry time.
						quick:SetHeight(20);
						quick:SetWidth(20);
						quick:SetPoint("TOPRIGHT", quick:GetParent(), "BOTTOMRIGHT", 0, 0);
						quick:SetNormalTexture("Interface\\Buttons\\UI-SpellbookIcon-PrevPage-Up");
						quick:SetPushedTexture("Interface\\Buttons\\UI-SpellbookIcon-PrevPage-Down");
						quick:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight");
						quick:Show();
						quick.ctmailmodAction = 1; -- return
					end
				else
					-- Don't show a quick action button below the expiry time
					mailItem:SetWidth(248);
					quick:Hide();
				end
			end
		end
	end

	local function customEvents_QuickAction(self, event, data)
		if (event == "INCOMING_UPDATE") then
			module:inboxUpdateQuickAction();

		elseif (event == "INCOMING_START") then
			-- Disable everything
			for key, value in ipairs(quickAction) do
				value:Disable();
			end

		elseif (event == "INCOMING_STOP") then
			-- Restore everything
			for key, value in ipairs(quickAction) do
				value:Enable();
			end
		end
	end
	module:regCustomEvent("INCOMING_UPDATE", customEvents_QuickAction);
	module:regCustomEvent("INCOMING_START", customEvents_QuickAction);
	module:regCustomEvent("INCOMING_STOP", customEvents_QuickAction);
end

-- Inbox frame update routines
do
	function module:inboxUpdateOther()
		-- Update other items in the inbox frame.
		local offset = (InboxFrame.pageNum - 1) * INBOXITEMS_TO_DISPLAY;
		local mailCount, totalCount = GetInboxNumItems();
		if (not totalCount) then
			totalCount = mailCount;
		end
		local mailIndex;
		local showTwoLineSubjects = module.opt.inboxShowLong;
		for key, chbox in ipairs(checkboxes) do
			mailIndex = key + offset;

			-- Show two-line or one-line subjects.
			local mailItem = _G["MailItem" .. key .. "Subject"];
			if (showTwoLineSubjects) then
				mailItem:SetHeight(36);
			else
				mailItem:SetHeight(18);
			end
		end
		-- Hide Blizzard's "too much" mail text at top of inbox.
		-- In WoW 3.3 they change this from a fontstring into a frame,
		-- but the name of the new frame is the same as the fontstring,
		-- and the name of the variable holding the text is also the same.
		InboxTooMuchMail:ClearAllPoints();
		InboxTooMuchMail:SetPoint("TOP", MailFrame, "BOTTOM", 0, -50);
		--InboxTooMuchMail:SetBackdrop(
		--	{
		--		bgFile = "Interface/Tooltips/UI-Tooltip-Background",
		--		backdropColor = { r=1, g=0, b=0, a=0.05 },
		--	}
		--);
		local tex = InboxTooMuchMail:CreateTexture(nil, "BACKGROUND");
		tex:SetAllPoints(true);
		tex:SetColorTexture(0.0, 0.0, 0.0, 0.25);
		if (totalCount > mailCount) then
			-- User has more mail than the game will allow in the inbox.
			-- Display a message in the chat window once per mailbox open
			if (not module.tooMuchMail) then
				module.tooMuchMail = true;
				DEFAULT_CHAT_FRAME:AddMessage(gsub(INBOX_TOO_MUCH_MAIL, "\124n", " "));
			end
		end
		if (module.opt.inboxShowInbox) then
			-- Show the number of items that are in the inbox
			if (totalCount > mailCount) then
				fsInboxCount:SetText("|cFFFF6666" .. mailCount .. " / " .. totalCount);
			else
				fsInboxCount:SetText(mailCount .. " messages");
			end
			fsInboxCount:Show();
		else
			fsInboxCount:Hide();
		end
	end

	local function inboxframe_update()
		-- Called after Blizzard's InboxFrame_Update() function.
		module:inboxUpdateOther();
		module:inboxUpdateSelection();
		module:inboxUpdateQuickAction();
		module:inboxUpdateMailboxCount();
	end
	hooksecurefunc("InboxFrame_Update", inboxframe_update);

	module:regCustomEvent("INCOMING_UPDATE", function(self, event)
		module:inboxUpdateOther();
	end);

	local function updatePendingMail()
		if (InboxFrame and InboxFrame:IsVisible()) then
			inboxframe_update();
		end
	end
	module:regEvent("UPDATE_PENDING_MAIL", updatePendingMail);

	function module:calculateInboxPage(mailIndex)
		-- Returns the page number in the inbox that the specified mail index appears on.
		return ceil(mailIndex / INBOXITEMS_TO_DISPLAY);
	end

	function module:gotoInboxPage(page)
		-- Displays the specified inbox page.
		InboxFrame.pageNum = page;
		InboxFrame_Update();
	end

	function module:gotoInboxMailPage(mailIndex)
		-- Displays the inbox page that the specified mail index appears on.
		local page = module:calculateInboxPage(mailIndex);
		module:gotoInboxPage(page);
	end
end

-- Add the mail log button
do
	local btn = CreateFrame("Button", nil, InboxFrame, "UIPanelButtonTemplate");

	btn:SetWidth(50);
	btn:SetHeight(25);
	btn:SetText(module.text["CT_MailMod/MAIL_LOG"]);
	btn:SetPoint("TOPLEFT", 282, -27);
	btn:SetScript("OnClick", function(...)
		module.toggleMailLog();
	end);
	btn:SetScript("OnEnter", function(...)
		GameTooltip:SetOwner(btn, "ANCHOR_TOPLEFT", 30, -60);
		GameTooltip:SetText("Open the CT_MailMod Log");
		GameTooltip:Show();
	end);
	btn:SetScript("OnLeave", function(...)
		GameTooltip:Hide();
	end);

	function module:updateMailLogButton()
		if (module.opt.hideLogButton) then
			btn:Hide();
		else
			btn:Show();
		end
	end
	
	module:registerConflictResolution("ClassicGuildBank", 1, function()			
		-- move our frame down a bit and make it smaller, so there is more room for them
		btn:SetPoint("TOPLEFT", 284, -40);
		btn:SetSize(48, 19);
		btn:SetNormalFontObject("GameFontNormalSmall");
	end);
end

-- Mail icon buttons
do
	-- Blizzard calls InboxFrameItem_OnEnter() from the OnEnter and OnUpdate
	-- scripts.
	--
	-- The only thing Blizzard's code puts in the tooltip is the number of items,
	-- the amount of money, and the cod amount.  If your mouse was to remain over
	-- the mail icon button after shift-clicking it then it would update the
	-- tooltip as items/money was taken.
	--
	-- In our case, we are disabling the mail icon buttons once incoming processing
	-- begins. When the button is disabled the tooltip gets hidden, so calling the
	-- function from the OnUpdate script does us no good at that point.
	--
	-- We are going to disable each mail icon button's OnUpdate script to prevent
	-- it from calling our OnEnter function, since having it call it does nothing
	-- useful for us and uses up some resources.
	do
		local button;
		for i = 1, INBOXITEMS_TO_DISPLAY, 1 do
			button = _G["MailItem" .. i .. "Button"];
			button:SetScript("OnUpdate", function(...) end);
		end
	end

	local battlePetTooltip -- dummy tooltip frame for its return values prior to WoW 10.x

	-- Extra lines for mail icon button tooltip
	local function CT_MailMod_InboxFrameItem_OnEnter(self, ...)
		-- This is a post hook routine for Blizzard's InboxFrameItem_OnEnter
		-- function. Blizzard calls it during the OnEnter and OnUpdate scripts,
		-- however we've disabled the OnUpdate script since it does nothing
		-- useful for us.
		local mailIndex = self.index;
		local mail = module:loadMail(self.index);
		local showMulti = module.opt.toolMultipleItems;
		local gap;

		if (showMulti and mail.numItems > 1) then
			GameTooltip:AddLine(" ");
			-- Safe attachment constant for Retail
			local maxReceive = ATTACHMENTS_MAX_RECEIVE or 16;
			for i = 1, maxReceive do
				local name, itemID, itemTexture, count, quality, canUse = GetInboxItem(mailIndex, i);
				if (name) then
					local itemLink = GetInboxItemLink(mailIndex, i);
					local petSpecies, petQuality, petLevel, petName
					if C_TooltipInfo then
						-- WoW 10.x
						local data = C_TooltipInfo.GetInboxItem(mailIndex, i)
						if data then
							-- TooltipUtil.SurfaceArgs(data)  -- no longer required from WoW 10.1.0
							petSpecies, petQuality, petLevel, petName = data.battlePetSpeciesID, data.battlePetBreedQuality, data.battlePetLevel, data.battlePetName
						end
					else
						battlePetTooltip = battlePetTooltip or CreateFrame("GameTooltip", "CT_MailMod_BattlePetScanningTooltip")	-- deliberately does not inherit any templates, prior to WoW 10.x
						__, petSpecies, petLevel, petQuality, __, __, __, petName = battlePetTooltip:SetInboxItem(mailIndex, i)
					end
					if petSpecies then
						itemLink = ("%s|Hitem:%d:0:0:0:0:0:0:0:0:0|h[%s]|h|r"):format(
							petQuality == 1 and "|cffffffff" or petQuality == 2 and "|cff1eff00" or petQuality == 3 and "|cff0070dd" or petQuality == 4 and "|cffa335ee" or "|cff9d9d9d",
							petSpecies,
							petName
						)
						if petLevel and petLevel > 1 then
							itemLink = ("%s (%s)"):format(itemLink, BATTLE_PET_CAGE_TOOLTIP_LEVEL:format(petLevel))
						end
					else
						itemLink = itemLink or ("["..name.."]")
					end
					
					if (count == 1) then
--						GameTooltip:AddLine(itemLink);
						GameTooltip:AddLine("|T" .. itemTexture .. ":0|t" .. itemLink)
					else
--						GameTooltip:AddLine(itemLink .. " x " .. count);
						GameTooltip:AddLine("|T" .. itemTexture .. ":0|t" .. itemLink .. " x " .. count)
					end
--					-- Note: GameTooltip:AddTexture() only supports 10 textures, so
--					-- if there are more than 10 items attached to the message
--					-- then the 11th, etc will not show a texture in the tooltip.
--					-- This can be overcome by using "|T" .. itemTexture .. ":0|t" in a call to GameTooltip:AddLine().
--					GameTooltip:AddTexture(itemTexture);
				end
			end
		end

		if (mail:canMassOpen()) then
			if (not gap) then
				GameTooltip:AddLine(" ");
				gap = true;
			end
			GameTooltip:AddLine(module.text["CT_MailMod/MAIL_OPEN_CLICK"], 1, 1, 0.5);
		end

		if (mail:canMassReturn()) then
			if (not gap) then
				GameTooltip:AddLine(" ");
				gap = true;
			end
			GameTooltip:AddLine(module.text["CT_MailMod/MAIL_RETURN_CLICK"], 1, 1, 0.5);
		end

		GameTooltip:Show();
	end
	hooksecurefunc("InboxFrameItem_OnEnter", CT_MailMod_InboxFrameItem_OnEnter);

	local function customEvents_MailIconButtons(self, event, data)
		if (event == "INCOMING_START") then
			-- Disable everything
			for i = 1, INBOXITEMS_TO_DISPLAY do
				_G["MailItem" .. i .. "Button"]:Disable();
			end

		elseif (event == "INCOMING_STOP") then
			-- Restore everything
			for i = 1, INBOXITEMS_TO_DISPLAY do
				_G["MailItem" .. i .. "Button"]:Enable();
			end
		end
	end
	module:regCustomEvent("INCOMING_START", customEvents_MailIconButtons);
	module:regCustomEvent("INCOMING_STOP", customEvents_MailIconButtons);
end


-- Right click the Prev/Next page buttons
do
	InboxPrevPageButton:ClearAllPoints();
	InboxPrevPageButton:SetPoint("CENTER", InboxFrame, "BOTTOMLEFT", 30, 110);

	InboxNextPageButton:ClearAllPoints();
	InboxNextPageButton:SetPoint("CENTER", InboxFrame, "BOTTOMLEFT", 305, 110);

	InboxNextPageButton:RegisterForClicks("LeftButtonUp", "RightButtonUp");
	InboxPrevPageButton:RegisterForClicks("LeftButtonUp", "RightButtonUp");

	local function inboxNextPage(self, button, ...)
		if (button == "RightButton" or IsShiftKeyDown()) then
			local lastPage = ceil(GetInboxNumItems() / INBOXITEMS_TO_DISPLAY);
			if (lastPage < 1) then
				lastPage = 1;
			end
			InboxFrame.pageNum = lastPage;
			InboxFrame_Update();
		end
	end
	InboxNextPageButton:HookScript("OnClick", inboxNextPage);

	local function inboxPrevPage(self, button, ...)
		if (button == "RightButton" or IsShiftKeyDown()) then
			InboxFrame.pageNum = 1;
			InboxFrame_Update();
		end
	end
	InboxPrevPageButton:HookScript("OnClick", inboxPrevPage);
end

-- Clicking upper left corner stack of mail icon will open CT_MailMod options window.
do
	local frame = CreateFrame("Button", nil, MailFrame);
	frame:SetHeight(58);
	frame:SetWidth(58);
	frame:SetPoint("TOPLEFT", MailFrame, "TOPLEFT", -7, 6);
	frame:Show();
	frame:RegisterForClicks("AnyUp")
	frame:SetScript("OnClick", function(self, button, ...)
		if button == "RightButton" then
			module.toggleMailLog();
		else
			module:showModuleOptions();
		end
	end);
	frame:SetScript("OnEnter", function(self, ...)
		GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT", 0, 5);
		GameTooltip:SetText("CT_MailMod");
		GameTooltip:AddLine(module.text["CT_MailMod/MAILBOX_OPTIONS_TIP1"], 0.9, 0.9, 0.9, nil, 1);
		GameTooltip:Show();
	end);
	frame:SetScript("OnLeave", function(self, ...)
		GameTooltip:Hide();
	end);
end

function InboxFrame_OnClick(self, index)
	-- This is a replacement for Blizzard's InboxFrame_OnClick function.
	--
	-- New lines of code are surrounded by, or ended with: -- *new*
	-- Modified lines of code are surrounded by, or ended with: -- *mod*
	-- *new*
	if ( IsAltKeyDown() or IsShiftKeyDown() ) then
		-- Retrieve the contents of this mail.
		if (not module.isProcessing) then
			module:closeOpenMail();
			module:retrieveSingle(self.index);
		end
		self:SetChecked(false);
		return;
	elseif ( IsControlKeyDown() ) then
		-- Return this mail.
		if (not module.isProcessing) then
			module:closeOpenMail();
			module:returnSingle(self.index);
		end
		self:SetChecked(false);
		return;
	end

	-- Show/Hide the OpenMailFrame.
	-- *new*
	if ( self:GetChecked() ) then
		InboxFrame.openMailID = index;
		OpenMailFrame.updateButtonPositions = true;
		OpenMail_Update();
		--OpenMailFrame:Show();
		ShowUIPanel(OpenMailFrame);
		OpenMailFrameInset:SetPoint("TOPLEFT", 4, -80);
		PlaySound(SOUNDKIT.IG_BACKPACK_OPEN or 829); -- Made safe for Retail
		module:initOpenMail(); -- *new*
	else
		InboxFrame.openMailID = 0;
		HideUIPanel(OpenMailFrame);
	end
	InboxFrame_Update();
end

function InboxFrame_OnModifiedClick(self, index)
	-- This is a replacement for Blizzard's InboxFrame_OnModifiedClick function.
	--
	-- New lines of code are surrounded by, or ended with: -- *new*
	-- Modified lines of code are surrounded by, or ended with: -- *mod*
	-- *mod*
--	local _, _, _, _, _, cod = GetInboxHeaderInfo(index);
--	if ( cod <= 0 ) then
--		AutoLootMailItem(index);
--	end
	-- *mod*
	InboxFrame_OnClick(self, index);
end

function InboxGetMoreMail()
	-- This is a replacement for Blizzard's InboxGetMoreMail function
	-- that was added to MailFrame.lua in the WoW 3.3 patch.
	--
	-- In that patch they added a call to InboxGetMoreMail() in a couple
	-- of places: a) When a MAIL_SUCCESS event arrived, b) When the
	-- InboxNextPage() or InboxPrevPage() functions are called.
	--
	-- This replacement function does nothing when called. This prevents
	-- CheckInbox() from getting called at times that we would rather
	-- it not be.
end

-- Send Mail Auto-Complete Filters

local sendmailframe;
local filterdropdown;

function CT_MailMod_UpdateFilterDropDown()
	if (module:getOption("sendmailAutoCompleteUse")) then
		filterdropdown:Show();
	else
		filterdropdown:Hide();
	end

end

do
	sendmailframe = module:getFrame("multidropdown#s:1:40#l:r:0:0:SendMailNameEditBox#n:CT_MailModDropdown_autoCompleteFilters#o:autoCompleteFilters:1#" .. module.text["CT_MailMod/AutoCompleteFilter/Online"] .. "#sendmailAutoCompleteOnline#" .. module.text["CT_MailMod/AutoCompleteFilter/Friends"] .. "#sendmailAutoCompleteFriends#" .. module.text["CT_MailMod/AutoCompleteFilter/Guild"] .. "#sendmailAutoCompleteGuild#" .. module.text["CT_MailMod/AutoCompleteFilter/Group"] .. "#sendmailAutoCompleteGroup#" .. module.text["CT_MailMod/AutoCompleteFilter/Recent"] .. "#sendmailAutoCompleteInteracted#" .. module.text["CT_MailMod/AutoCompleteFilter/Account"] .. "#sendmailAutoCompleteAccount",SendMailFrame);
	filterdropdown = select(#(sendmailframe:GetChildren())-1, sendmailframe:GetChildren());
	filterdropdown:SetScale(0.8);
	filterdropdown.Left:ClearAllPoints();
	filterdropdown.Left:SetPoint("LEFT", SendMailNameEditBox, "RIGHT", -12, 0);
	filterdropdown.Left:SetSize(0.001, 0.001);
	filterdropdown.Middle:ClearAllPoints();
	filterdropdown.Middle:SetPoint("LEFT", SendMailNameEditBox, "RIGHT", 6, 0);
	filterdropdown.Right:ClearAllPoints();
	filterdropdown.Right:SetPoint("LEFT", SendMailNameEditBox, "RIGHT", 0, 0);
	filterdropdown.Right	:SetSize(0.001, 0.001);
	-- Pin the clickable arrow button to the right of the name box; otherwise it keeps
	-- the template's default placement and drifts down over the subject field.
	local arrowButton = filterdropdown.Button or _G[(filterdropdown:GetName() or "") .. "Button"];
	if (arrowButton) then
		arrowButton:ClearAllPoints();
		arrowButton:SetPoint("LEFT", SendMailNameEditBox, "RIGHT", -2, 0);
	end
	filterdropdown:SetScript("OnEnter", function(...)
		GameTooltip:SetOwner(filterdropdown, "ANCHOR_TOPLEFT", 35, 10);
		GameTooltip:SetText(module.text["CT_MailMod/Send/AutoComplete/Heading"]);
		GameTooltip:AddLine(module.text["CT_MailMod/Send/AutoComplete/Tip"], 0.9, 0.9, 0.9);
		GameTooltip:Show();
	end);
	filterdropdown:SetScript("OnLeave", function(...)
		GameTooltip:Hide();
	end);
end


--------------------------------------------
-- Preventing the send-mail frame's edit boxes from losing focus during common tasks


if (module:getGameVersion() >= 8) then		-- this resolves a nuisance introduced in WoW 8.3; not present in Classic (yet)
	local focus;
	local enabled = true;	-- by default, this feature is on
	
	function module.protectFocus(enable)
		enabled = enable;
	end
	
	local function wipeFocus()
		focus = nil;
	end
	
	local function onEditFocusGained(editbox)
		focus = nil;
	end
		
	local function onEditFocusLost(editbox)
		if (enabled) then
			focus = editbox;
			C_Timer.After(0.0001, wipeFocus);
		end
	end
		
	local function trigger()
		if (focus) then
			focus:SetFocus();
		end
	end
	
	SendMailNameEditBox:HookScript("OnEditFocusGained", onEditFocusGained);
	SendMailSubjectEditBox:HookScript("OnEditFocusGained", onEditFocusGained);
	SendMailBodyEditBox:HookScript("OnEditFocusGained", onEditFocusGained);
	SendMailMoneyGold:HookScript("OnEditFocusGained", onEditFocusGained);
	SendMailMoneySilver:HookScript("OnEditFocusGained", onEditFocusGained);
	SendMailMoneyCopper:HookScript("OnEditFocusGained", onEditFocusGained);

	SendMailNameEditBox:HookScript("OnEditFocusLost", onEditFocusLost);
	SendMailSubjectEditBox:HookScript("OnEditFocusLost", onEditFocusLost);
	SendMailBodyEditBox:HookScript("OnEditFocusLost", onEditFocusLost);
	SendMailMoneyGold:HookScript("OnEditFocusLost", onEditFocusLost);
	SendMailMoneySilver:HookScript("OnEditFocusLost", onEditFocusLost);
	SendMailMoneyCopper:HookScript("OnEditFocusLost", onEditFocusLost);

	for __, button in pairs({
		StackSplitFrame and StackSplitFrame.OkayButton,
		StackSplitFrame and StackSplitFrame.CancelButton,
		SendMailSendMoneyButton,
		SendMailCODButton,
	}) do
		-- Safeguard: only runs if the button actually exists and supports script methods
		if button and type(button) == "table" and button.HookScript then
			button:HookScript("OnMouseDown", trigger);
		end
	end
	
	-- Safe hook for outgoing attachments (modern Retail global function)
	if SendMailAttachmentButton_OnMouseDown then
		hooksecurefunc("SendMailAttachmentButton_OnMouseDown", function(self, button)
			if trigger then trigger() end
		end)
	else
		-- Fail-safe fallback for Classic / older clients
		local maxReceive = ATTACHMENTS_MAX_RECEIVE or 16;
		for i=1, maxReceive do
			local frame = _G["SendMailAttachment"..i];
			if (frame and type(frame) == "table" and frame.HookScript) then
				frame:HookScript("OnMouseDown", trigger)
			end
		end
	end
	
	-- Safe and modernized bag hook for Retail (The War Within compatible)
	local listener = CreateFrame("Frame")
	listener:SetScript("OnEvent", function()
		if ContainerFrameItemButtonTemplate_OnMouseDown then
			hooksecurefunc("ContainerFrameItemButtonTemplate_OnMouseDown", function(self, button)
				if trigger then trigger() end
			end)
		else
			-- Fail-safe fallback for bags in older clients
			local maxContainerItems = MAX_CONTAINER_ITEMS or 36;
			for bag=1, 5 do
				for slot=1, maxContainerItems do
					local frame = _G["ContainerFrame" .. bag .. "Item" .. slot];
					if (frame and type(frame) == "table" and frame.HookScript) then
						frame:HookScript("OnMouseDown", trigger);
					end
				end
			end
		end
	end)
	listener:RegisterEvent("PLAYER_LOGIN")

end