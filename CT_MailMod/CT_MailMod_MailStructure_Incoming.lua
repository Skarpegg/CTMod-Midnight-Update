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
local module = select(2, ...)

--------------------------------------------
-- Incoming Mail Structure

local incMail = { };
local incMail_meta = { __index = incMail };

local mailSerial = 0;

-- Creates the main mail structure.
function module:loadMail(id)
	--
	-- .id
	-- .serial
	--
	-- These are updated by incMail:update()
	-- .from
	-- .sender
	-- .subject
	-- .money
	-- .codAmount
	-- .daysleft
	-- .numItems
	-- .wasRead
	-- .wasReturned
	-- .textCreated
	-- .canReply
	-- .isGM
	-- .receiver
	--
	-- These are used by all of the incoming mail actions
	-- and the mail log routines.
	-- .logPending
	-- .logFunc
	-- .logMoney
	-- .logItems
	-- .logSuccess
	-- .logMessage
	-- .logPrint
	--
	-- Refer to individual actions for other object members.
	--
	local mail = setmetatable(module:getTable(), incMail_meta);
	mail.id = id;
	mail:getNewSerial();
	mail:update();
	return mail;
end

function incMail:update()
	local _, _, sender, subject, money, codAmount, daysleft, numItems,
		wasRead, wasReturned, textCreated, canReply, isGM = GetInboxHeaderInfo(self.id);
	self.from = sender;  -- Might be nil.
	if (not sender) then
		sender = UNKNOWN;
	end
	self.sender = module:getPlayerName(sender);  -- "name @ server"
	self.subject = subject or " ";
	self.money = money or 0;
	self.codAmount = codAmount or 0;
	self.daysleft = daysleft or 0;
	self.numItems = numItems or 0;
	self.wasRead = wasRead;
	self.wasReturned = wasReturned;
	self.textCreated = textCreated;
	self.canReply = canReply;
	self.isGM = isGM;
	self.receiver = module:getPlayerName(); -- "name @ server"
end

function incMail:getNewSerial()
	-- Assign new serial number to the mail.
	-- The serial number is used by the module:logMessage() function
	-- to allow multiple updates to the same log entry, which is used
	-- when retrieving items from the OpenMailFrame.
	mailSerial = mailSerial + 1;
	self.serial = mailSerial;
end

function incMail:getName()
	return string.format("'%s', From %s", self.subject, self.sender);
end

function incMail:canMassOpen()
	-- Don't open a message from a GM.
	if (self.isGM) then
		return false;
	end
	-- Don't open message with a cod amount.
	if (self.codAmount ~= 0) then
		return false;
	end
	-- Don't open a message if there is no items and no money.
	if (self.numItems == 0 and self.money == 0) then
		return false;
	end
	-- Dont' open consortium crafting orders (because its acting buggy)
	if select(6, GetInboxText(self.id)) then
		return false
	end
	return true;
end

function incMail:canMassReturn()
	-- Don't return if no sender.
	if (not self.from) then
		return false;
	end
	-- Don't return if message was already returned to us.
	if (self.wasReturned) then
		return false;
	end
	-- Don't return GM messages.
	if (self.isGM) then
		return false;
	end
	-- Don't return messages that have no items, no money, and no cod amount.
	if (self.numItems == 0 and self.money == 0 and self.codAmount == 0) then
		return false;
	end
	-- Dont' return consortium crafting orders
	if select(6, GetInboxText(self.id)) then
		return false
	end
	-- Don't return messages that cannot be replied to.
	if (not self.canReply) then
		return false;
	end
	-- Can return message if it is not deletable.
	return not InboxItemCanDelete(self.id);
end

function incMail:getFirstItem()
	-- Get information about the first item in the message.
	local maxReceive = ATTACHMENTS_MAX_RECEIVE or 16; -- Safeguard for Retail
	local itemIndex = 1;
	local name, itemID, itemTexture, count, quality, canUse = GetInboxItem(self.id, itemIndex);
	while (not name and itemIndex < maxReceive) do
		itemIndex = itemIndex + 1;
		name, itemID, itemTexture, count, quality, canUse = GetInboxItem(self.id, itemIndex);
	end
	return name, itemTexture, count, quality, canUse;
end

function incMail:getItemInfo(itemIndex)
	-- Get item link and quantity.
	local link = GetInboxItemLink(self.id, itemIndex);
	if (link) then
		-- Return item link, and quantity
		return link:match("|H(item:[^|]+)|h"), (select(4, GetInboxItem(self.id, itemIndex)));
	end
	-- Link is nil if the item has already been removed from the mail.
	return nil, nil;
end

function incMail:getLogItems()
	-- Build list of items to be logged.
	self.logItems = {};
	if (self.numItems > 0) then
		local maxReceive = ATTACHMENTS_MAX_RECEIVE or 16; -- Safeguard for Retail
		local link, count;
		for i = 1, maxReceive do
			link, count = self:getItemInfo(i);
			-- If user has already removed this item from this email, then 'link' will be nil for this item.
			if (link and count) then
				-- Item is still attached to the email.
				tinsert(self.logItems, {link, count});
			end
		end
	end
end

function incMail:advanceToNextItem()
	-- Advance to the next attachment number.
	if (self.nextItem) then
		self.nextItem = self.nextItem + 1;
	end
end

function incMail:verifyMail()
	-- Compare some of the mail object's values against the actual values.
	--
	-- This can be used as an extra safety check to try and ensure
	-- we've got the correct mail id. The test is not perfect since
	-- there could be more than one mail with the same information.
	--
	-- Note: If something calls CheckInbox() then it could result
	-- in a failed comparison (which is a good thing) since the
	-- inbox contents will probably be different, and the days left
	-- values will likely have changed.
	local check = module:loadMail(self.id);
	if (
		check.from == self.from and
		check.subject == self.subject and
		check.daysleft == self.daysleft
	) then
		-- Matched.
		return true;
	end
	-- Something didn't match.
	return false;
end

--------------------------------------------
-- Retrieve all money and items from a mail.

function incMail:retrieveSelectedMail(cancelProcessing)
	-- Retrieves items and money from a mail.
	--
	-- Returns:
	--   0 == Continue calling this function
	--   1 == Continue calling this function after a delay
	--   2 == Cancel all processing
	--   3 == Proceed to the next action in the queue
	--
	-- Additional mail object members used by this function:
	-- .init
	-- .lastTime
	-- .nextItem
	-- .lastItem
	-- .mailCount
	-- .haveTakenMoney
	--
	local inboxNumItems = GetInboxNumItems();
	if (not self.init) then
		self.init = true;

		self.lastTime = GetTime();

		self.nextItem = 1;
		self.lastItem = nil;
		self.haveTakenMoney = false;

		self.mailCount = inboxNumItems;
		module:gotoInboxMailPage(self.id);

		self.body = GetInboxText(self.id);  -- Flag message as read.

		self.logPending = false;
		self.logFunc = module.logIncoming;
		self.logPrint = true;
		self.logMoney = 0;
		self.logItems = {};

		if (self:canMassOpen()) then
			self.logSuccess = true;
			self.logMessage = module.text["CT_MailMod/MAIL_OPEN_OK"];
			module:printLogMessage(self.logSuccess, self, self.logMessage);
			self.logPrint = false;
		else
			if (self.codAmount > 0) then
				-- Don't open COD messages.
				self.body = "|cffff0000" .. COD .. "|r " .. self.body
				message = module.text["CT_MailMod/MAIL_OPEN_IS_COD"]
			elseif (self.isGM) then
				-- Don't open GM messages.
				self.body = "|cff00c0ffGM: |r" .. self.body
				message = module.text["CT_MailMod/MAIL_OPEN_IS_GM"]
			elseif (self.money == 0 and self.numItems == 0) then
				-- Don't open messages with no money or items.
				message = module.text["CT_MailMod/MAIL_OPEN_NO_ITEMS_MONEY"]
			else
				-- Cannot open this message.
				message = module.text["CT_MailMod/MAIL_OPEN_CANNOT_OPEN"]
			end
			module:logIncoming(false, self, message);
			return 3;
		end
	end
	if (cancelProcessing) then
		-- Processing is being cancelled.
		module:logPending(self);
		return 2;
	end
	if (GetTime() - self.lastTime > module.timeoutValue) then
		-- It is taking too long to retrieve money or current item.
		module:logIncoming(false, self, "CT_MailMod/MAIL_TIMEOUT");
		return 2;
	end
	if (self.mailCount ~= inboxNumItems) then
		-- The number of messages in the inbox has changed.
		module:logPending(self);
		if (inboxNumItems > self.mailCount) then
			-- The number of items in the inbox has increased.
			-- This is probably the result of a call to CheckInbox()
			-- which may add mail to the inbox.
			-- This could cause problems with regards to correctly knowing
			-- which messages are selected, so we need to cancel processing.
			return 2;
		end
		-- The mail has been deleted from the inbox.
		return 3;
	end
	self:update();  -- Get current information
	if (self.codAmount > 0) then
		-- Extra safety check (should never get here).
		-- Don't attempt to open a COD mail.
		module:logPending(self);
		return 3;
	end
	if (self.money > 0) then
		-- Retrieve money from the mail.
		if (not self.haveTakenMoney) then
			-- Take the money
			self.haveTakenMoney = true;

			self.logMoney = self.money;
			self.logPending = true;

			TakeInboxMoney(self.id);
			self.lastTime = GetTime();

			-- If no items left, then unselect this message now,
			-- rather than waiting for the action to complete.
			-- This prevents it from looking like the wrong mail
			-- is selected when this mail auto-deletes and the
			-- next mail shifts into its spot in the inbox frame.
			if (self.numItems == 0) then
				module:inboxUnselectSingle(self.id);
				module:inboxUpdateSelection();
			end
			
			return 1;
		end
		-- We've already taken the money.
		-- Keep waiting for the remaining amount to update.
		return 0;
	end
	if (self.numItems > 0) then
		-- Retrieve next item from the mail.
		local maxReceive = ATTACHMENTS_MAX_RECEIVE or 16; -- Safeguard for Retail
		local itemIndex = self.nextItem;
		local link, count = self:getItemInfo(itemIndex);
		while (not link and itemIndex < maxReceive) do
			itemIndex = itemIndex + 1;
			link, count = self:getItemInfo(itemIndex);
		end
		self.nextItem = itemIndex;
		if (link) then
			-- Don't issue multiple calls to TakeInboxItem() for the same item
			-- to avoid certain error messages.
			if (itemIndex ~= self.lastItem) then
				-- Take the item
				tinsert(self.logItems, {link, count});
				self.logPending = true;

				TakeInboxItem(self.id, itemIndex);
				self.lastTime = GetTime();
				self.lastItem = itemIndex;

				-- If this is the last item, then unselect this message now,
				-- rather than waiting for the action to complete.
				-- This prevents it from looking like the wrong mail
				-- is selected when this mail auto-deletes and the
				-- next mail shifts into its spot in the inbox frame.
				if (self.numItems == 1) then
					module:inboxUnselectSingle(self.id);
					module:inboxUpdateSelection();
					
					if select(6, GetInboxText(self.id)) then
						-- This is a special case for crafting orders that do not self-delete
						-- after taking the last item, so we should just move on.
						module:logPending(self)
						return 3
					end
					
				end
				return 1;
			end
			-- Keep waiting for the item to be taken.
			return 0;
		else
			-- No more items to be taken.
			-- This probably means we were unable to take one or more
			-- of the attachments (might have been carrying too many of
			-- an item), we advanced past it, and now we've run out of
			-- attachments.
			module:logPending(self);
			return 3;
		end
	end
	-- When the last item/money is removed from a mail, the game
	-- will auto-delete the mail if it does not contain any text.
	--
	-- However, it make take some time after we remove the last
	-- item/mony before the game auto-deletes the mail and updates
	-- the number of items in the inbox.
	--
	-- If we were to advance to the next mail without waiting for the
	-- number of inbox items to change, then the change may occur while
	-- we are processing that next mail. If it did, then we'd incorrectly
	-- think that the mail we are now processing is the one that got
	-- auto-deleted, when in fact it was the previous one.
	--
	-- To ensure that the number of inbox items will change while we are
	-- still processing the mail that we removed the money/items from,
	-- we will continue to wait if this mail does not contain any text.
	local text = GetInboxText(self.id);
	if (not text or text == "") then
		-- This mail contains no text (and no money/items).
		-- This mail should get auto-deleted by the game, so keep
		-- waiting for the number of items in the inbox to change.
		return 0;
	end
	-- The game won't auto-delete mail that contains text.
	module:logPending(self);
	return 3;
end

--------------------------------------------
-- Return a mail.

function incMail:returnSelectedMail(cancelProcessing)
	-- Return a selected mail.
	--
	-- Returns:
	--   0 == Continue calling this function
	--   1 == Continue calling this function after a delay
	--   2 == Cancel all processing
	--   3 == Proceed to the next action in the queue
	--
	-- Additional mail object members used by this function:
	-- .init
	-- .lastTime
	-- .mailCount
	-- .haveReturned
	--
	local inboxNumItems = GetInboxNumItems();
	if (not self.init) then
		self.init = true;

		self.lastTime = GetTime();

		self.mailCount = inboxNumItems;
		module:gotoInboxMailPage(self.id);

		GetInboxText(self.id);  -- Flag message as read.

		self.logPending = false;
		self.logFunc = module.logReturned;
		self.logPrint = true;
		self.logMoney = 0;
		self.logItems = {};

		self.haveReturned = false;

		if (self:canMassReturn()) then
			-- Can return the mail.
			self.logSuccess = true;
			self.logMessage = "CT_MailMod/MAIL_RETURN_OK";
			module:printLogMessage(self.logSuccess, self, self.logMessage);
			self.logPrint = false;
		else
			-- Mail cannot be returned.
			local message;
			if (not self.from) then
				-- No sender.
				message = "CT_MailMod/MAIL_RETURN_NO_SENDER";
			elseif (self.wasReturned) then
				-- Message was already returned to us.
				message = "CT_MailMod/MAIL_RETURN_IS_RETURNED";
			elseif (self.isGM) then
				-- Message is from a GM.
				message = "CT_MailMod/MAIL_RETURN_IS_GM";
			elseif (self.numItems == 0 and self.money == 0 and self.codAmount == 0) then
				-- Messages has no items, no money, and no cod amount.
				message = "CT_MailMod/MAIL_RETURN_NO_ITEMS_MONEY";
			elseif (not self.canReply) then
				-- Message cannot be replied to.
				message = "CT_MailMod/MAIL_RETURN_NO_REPLY";
			else
				-- Message is deletable (ie. not returnable).
				message = "CT_MailMod/MAIL_RETURN_NO";
			end
			module:logReturned(false, self, message);
			return 3;
		end
	end
	if (cancelProcessing) then
		-- Processing is being cancelled.
		module:logPending(self);
		return 2;
	end
	if (GetTime() - self.lastTime > module.timeoutValue) then
		-- It is taking too long to return the mail.
		module:logIncoming(false, self, "CT_MailMod/MAIL_TIMEOUT");
		return 2;
	end
	if (self.mailCount ~= inboxNumItems) then
		-- The number of messages in the inbox has changed.
		module:logPending(self);
		if (inboxNumItems > self.mailCount) then
			-- The number of items in the inbox has increased.
			-- This is probably the result of a call to CheckInbox()
			-- which may add mail to the inbox.
			-- This could cause problems with regards to correctly knowing
			-- which messages are selected, so we need to cancel processing.
			return 2;
		end
		-- The mail has been deleted from the inbox.
		return 3;
	end
	if (not self.haveReturned) then
		-- Return the mail.
		self.haveReturned = true;

		if (self.codAmount > 0) then
			-- Log the cod amount that is in the mail being returned,
			-- as a negative money value.
			self.logMoney = -self.codAmount;
		else
			-- Log the money amount that is in the mail being returned.
			self.logMoney = self.money;
		end
		self:getLogItems();
		self.logPending = true;

		module:closeOpenMail();
		ReturnInboxItem(self.id);

		-- Unselect this message now,
		-- rather than waiting for the action to complete.
		-- This prevents it from looking like the wrong mail
		-- is selected when this mail returns and the
		-- next mail shifts into its spot in the inbox frame.
		module:inboxUnselectSingle(self.id);
		module:inboxUpdateSelection();
		return 1;
	end
	-- The mail has not been returned yet.
	-- Keep waiting.
	return 0;
end

--------------------------------------------
-- Delete a mail.

local mailToDelete;

function incMail:cancelMailDelete()
	-- Set the flag to cancel the delete of the mail.
	self.cancelDelete = true;
end

function module:hideMailDeletePopups()
	-- Hide any static popups that may have been opened
	-- when trying to delete a mail.
	StaticPopup_Hide("CT_MAILMOD_DELETE_MAIL");
	StaticPopup_Hide("CT_MAILMOD_DELETE_MONEY");
end

local function deleteMail(mail)
	-- Delete a mail from the inbox.
	local del = false;
	-- Do a final safety check before deleting.
	if (mail:verifyMail()) then
		del = true;
	end
	if (not del) then
		-- Don't delete the mail
		mail.logPending = false;
		mail:cancelMailDelete();
	else
		-- Delete the mail
		mail.logMoney = mail.money;
		mail:getLogItems();
		mail.logPending = true;

		module:printLogMessage(mail.logSuccess, mail, mail.logMessage);
		mail.logPrint = false;

		module:closeOpenMail();
		DeleteInboxItem(mail.id);
		mail.haveDeleted2 = true;

		-- Unselect this message now,
		-- rather than waiting for the action to complete.
		-- This prevents it from looking like the wrong mail
		-- is selected when this mail deletes and the
		-- next mail shifts into its spot in the inbox frame.
		module:inboxUnselectSingle(mail.id);
		module:inboxUpdateSelection();
	end
end

StaticPopupDialogs["CT_MAILMOD_DELETE_MAIL"] = {
	text = DELETE_MAIL_CONFIRMATION,
	button1 = ACCEPT,
	button2 = CANCEL,
	OnAccept = function(self)
		deleteMail(mailToDelete);
		mailToDelete = nil;
	end,
	OnCancel = function(self)
		mailToDelete.logPending = false;
		mailToDelete:cancelMailDelete();
		mailToDelete = nil;
	end,
	showAlert = 1,
	timeout = 0,
	hideOnEscape = 1,
};

StaticPopupDialogs["CT_MAILMOD_DELETE_MONEY"] = {
	text = DELETE_MONEY_CONFIRMATION,
	button1 = ACCEPT,
	button2 = CANCEL,
	OnAccept = function(self)
		deleteMail(mailToDelete);
		mailToDelete = nil;
	end,
	OnCancel = function(self)
		mailToDelete.logPending = false;
		mailToDelete:cancelMailDelete();
		mailToDelete = nil;
	end,
	OnShow = function(self)
		MoneyFrame_Update(self.moneyFrame, mailToDelete.money)
	end,
	hasMoneyFrame = 1,
	showAlert = 1,
	timeout = 0,
	hideOnEscape = 1,
};

function incMail:deleteSelectedMail(cancelProcessing)
	-- Delete a selected mail.
	--
	-- Returns:
	--   0 == Continue calling this function
	--   1 == Continue calling this function after a delay
	--   2 == Cancel all processing
	--   3 == Proceed to the next action in the queue
	--
	-- Additional mail object members used by this function:
	-- .init
	-- .lastTime
	-- .mailCount
	-- .cancelDelete
	-- .haveDeleted1
	-- .haveDeleted2
	--
	local inboxNumItems = GetInboxNumItems();
	if (not self.init) then
		self.init = true;

		self.lastTime = GetTime();

		self.mailCount = inboxNumItems;
		module:gotoInboxMailPage(self.id);

		GetInboxText(self.id);  -- Flag message as read.

		self.logPending = false;
		self.logFunc = module.logDeleted;
		self.logPrint = true;
		self.logMoney = 0;
		self.logItems = {};

		self.haveDeleted1 = false;
		self.haveDeleted2 = nil;
		self.cancelDelete = nil;

		if (InboxItemCanDelete(self.id)) then
			-- Can delete the mail.
			self.logSuccess = true;
			self.logMessage = "CT_MailMod/MAIL_DELETE_OK";
			-- Don't print a log message now (in case there is a static popup).
		else
			-- Mail cannot be deleted.
			module:logDeleted(false, self, "CT_MailMod/MAIL_DELETE_NO");
			return 3;
		end
	end
	if (cancelProcessing) then
		-- Processing is being cancelled.
		module:hideMailDeletePopups();
		module:logPending(self);
		return 2;
	end
	if (self.cancelDelete) then
		-- We are deliberately cancelling the deletion of this mail (user might
		-- have clicked cancel in a static popup window).
		module:hideMailDeletePopups();
		module:logPending(self);
		return 3;
	end
	if (mailToDelete) then
		-- We have a static popup window open.
		-- While we do, we don't want the timeout to occur.
		-- Reset self.lastTime so we don't time right after the
		-- user closes the static popup window.
		self.lastTime = GetTime();
	else
		if (GetTime() - self.lastTime > module.timeoutValue) then
			-- It is taking too long to delete the mail.
			module:hideMailDeletePopups();
			module:logIncoming(false, self, "CT_MailMod/MAIL_TIMEOUT");
			return 2;
		end
	end
	if (self.mailCount ~= inboxNumItems) then
		-- The number of messages in the inbox has changed.
		module:hideMailDeletePopups();
		module:logPending(self);
		if (inboxNumItems > self.mailCount) then
			-- The number of items in the inbox has increased.
			-- This is probably the result of a call to CheckInbox()
			-- which may add mail to the inbox.
			-- This could cause problems with regards to correctly knowing
			-- which messages are selected, so we need to cancel processing.
			return 2;
		end
		-- The mail has been deleted from the inbox,
		return 3;
	end
	if (not self.haveDeleted1) then
		-- Delete the mail.
		self.haveDeleted1 = true;
		self.haveDeleted2 = false;

		if (self.numItems > 0) then
			-- Show a popup window asking the user if they are sure they
			-- want to delete the mail. The popup window will inform the
			-- user what money/items will be deleted.
			mailToDelete = self;
			local itemName = self:getFirstItem();
			if (self.money > 0) then
				if (self.numItems > 1) then
					-- "some money and %d items including %s"
					itemName = format(module.text["CT_MailMod/DELETE_POPUP3"], self.numItems, itemName);
				else
					-- "some money and %s"
					itemName = format(module.text["CT_MailMod/DELETE_POPUP2"], itemName);
				end
			else
				if (self.numItems > 1) then
					-- "%d items including %s"
					itemName = format(module.text["CT_MailMod/DELETE_POPUP1"], self.numItems, itemName);
				end
			end
			StaticPopup_Show("CT_MAILMOD_DELETE_MAIL", itemName);
			return 0;

		elseif (self.money > 0) then
			-- Show a popup window asking the user if they are sure they
			-- want to delete the mail. The popup window will inform the
			-- user what money will be deleted.
			mailToDelete = self;
			StaticPopup_Show("CT_MAILMOD_DELETE_MONEY");
			return 0;
		else
			deleteMail(self);  -- may set self.haveDeleted2 to true
		end
	end
	if (self.haveDeleted2) then  -- may get set via the StaticPopup or the deleteMail() call a few lines up.
		-- We have issued a DeleteInboxItem() call.
		self.haveDeleted2 = nil;
		return 1;
	end
	-- The mail has not been deleted yet.
	-- Keep waiting.
	return 0;
end

--------------------------------------------
-- This function is shared by:
--
--    incMail:retrieveItemFromOpenMail
--    incMail:retrieveMoneyFromOpenMail

function incMail:retrieveFromOpenMailInit()
	-- Open mail intialization.
	self.openInit = true;

	self:getNewSerial();

	GetInboxText(self.id);  -- Flag message as read.

	self.logPending = false;
	self.logFunc = module.logIncoming;
	self.logMoney = 0;
	self.logItems = {};

	self.itemInit = false;
	self.moneyInit = false;
end

--------------------------------------------
-- Take an attachment from the OpenMailFrame window.

local mailWithItem;

function incMail:cancelTakeItem()
	-- Set the flag to cancel the take of the current item from the OpenMailFrame.
	self.cancelTake = true;
end

function module:hideOpenMailTakeItemPopups()
	-- Hide any static popups that may have been opened
	-- when trying to take an item from an open mail.
	StaticPopup_Hide("CT_MAILMOD_COD_ALERT");
	StaticPopup_Hide("CT_MAILMOD_COD_CONFIRMATION");
end

StaticPopupDialogs["CT_MAILMOD_COD_ALERT"] = {
	text = COD_INSUFFICIENT_MONEY,
	button1 = CLOSE,
	OnAccept = function(self)
		mailWithItem.logPending = false;
		mailWithItem:cancelTakeItem();
		mailWithItem = nil;
	end,
	OnCancel = function(self)
		mailWithItem.logPending = false;
		mailWithItem:cancelTakeItem();
		mailWithItem = nil;
	end,
	timeout = 0,
	hideOnEscape = 1
};

StaticPopupDialogs["CT_MAILMOD_COD_CONFIRMATION"] = {
	text = COD_CONFIRMATION,
	button1 = ACCEPT,
	button2 = CANCEL,
	OnAccept = function(self)
		local mail = mailWithItem;
		local mailIndex = mail.id;
		local itemIndex = mail.nextItem;
		local link, count = mail:getItemInfo(itemIndex);
		if (link) then
			-- Take the item
			mail.logSuccess = true;
			mail.logMessage = "CT_MailMod/MAIL_TAKE_ITEM_OK";
			module:printLogMessage(mail.logSuccess, mail, mail.logMessage);
			mail.logPrint = false;

			tinsert(mail.logItems, {link, count});
			if (mail.codAmount > 0) then
				-- Log the COD amount paid as negative money.
				mail.logMoney = -mail.codAmount;
			end
			mail.logPending = true;

			TakeInboxItem(mailIndex, itemIndex);
			mail.haveTakenItem2 = true;

			mail.lastTime = GetTime();
			mail.lastItem = itemIndex;
		end
		mailWithItem = nil;
	end,
	OnCancel = function(self)
		mailWithItem.logPending = false;
		mailWithItem:cancelTakeItem();
		mailWithItem = nil;
	end,
	OnShow = function(self)
		MoneyFrame_Update(self.moneyFrame, OpenMailFrame.cod);
	end,
	hasMoneyFrame = 1,
	timeout = 0,
	hideOnEscape = 1
};

-- There is also a COD_CONFIRMATION_AUTO_LOOT static popup
-- that Blizzard uses, however we're not using the
-- AutoLootMailItem() function in CT_MailMod.

local function retrieveOpenItem(mail)
	-- Retrieve one item from the open mail.
	local mailIndex = mail.id;
	local itemIndex = mail.nextItem;
	local link, count = mail:getItemInfo(itemIndex);
	if (link) then
		-- Don't issue multiple calls to TakeInboxItem() for the same item
		-- to avoid certain error messages.
		if (itemIndex ~= mail.lastItem) then
			if (mail.codAmount > 0 and mail.codAmount > GetMoney()) then
				mailWithItem = mail;
				StaticPopup_Show("CT_MAILMOD_COD_ALERT");

			elseif (mail.codAmount > 0) then
				mailWithItem = mail;
				OpenMailFrame.lastTakeAttachment = itemIndex;
				StaticPopup_Show("CT_MAILMOD_COD_CONFIRMATION");
				OpenMailFrame.updateButtonPositions = false;
			else
				-- Take the item
				mail.logSuccess = true;
				mail.logMessage = "CT_MailMod/MAIL_TAKE_ITEM_OK";
				module:printLogMessage(mail.logSuccess, mail, mail.logMessage);
				mail.logPrint = false;

				tinsert(mail.logItems, {link, count});
				mail.logPending = true;

				TakeInboxItem(mailIndex, itemIndex);
				mail.haveTakenItem2 = true;

				mail.lastTime = GetTime();
				mail.lastItem = itemIndex;

				OpenMailFrame.updateButtonPositions = false;
			end
			-- Uses a modern and safe sound call for Retail
			PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON or 856);
		end
		return true;
	end
	return false;
end

function incMail:retrieveItemFromOpenMail(cancelProcessing)
	-- Retrieves an item from an open mail.
	--
	-- Returns:
	--   0 == Continue calling this function
	--   1 == Continue calling this function after a delay
	--   2 == Cancel all processing
	--   3 == Proceed to the next action in the queue
	--   4 == Proceed to the next action in the queue. Take failed.
	--   5 == Proceed to the next action in the queue. Take succeeded.
	--
	-- Additional mail object members used by this function:
	-- .openInit
	-- .lastTime
	-- .nextItem
	-- .lastItem
	-- .mailCount
	--
	-- .itemInit
	-- .itemCount
	-- .cancelTake
	-- .haveTakenItem1
	-- .haveTakenItem2
	--
	-- .moneyInit
	--
	local inboxNumItems = GetInboxNumItems();
	if (not self.openInit) then
		-- Open mail intialization.
		-- Usually done once per open mail.
		self:retrieveFromOpenMailInit();
	end
	if (not self.itemInit) then
		-- Initialization for taking an item from the open mail.
		-- Should be done each time an item is to be taken from the open mail frame.

		-- self.nextItem should have already been assigned the item number to be taken.
		self.lastItem = nil;
		self.lastTime = GetTime();
		self.mailCount = inboxNumItems;
		self.logPrint = true;

		self.cancelTake = false;
		self.haveTakenItem1 = false;
		self.haveTakenItem2 = false;

		mailWithItem = nil;
	end
	if (cancelProcessing) then
		-- Processing is being cancelled.
		module:hideOpenMailTakeItemPopups();
		module:logPending(self);
		return 2;
	end
	if (self.cancelTake) then
		-- The user cancelled the take of an item,
		-- or we got the error that the user was carrying too many of the item.
		module:hideOpenMailTakeItemPopups();
		return 3;
	end
	if (mailWithItem) then
		-- We have a static popup window open.
		-- While we do, we don't want the timeout to occur.
		-- Reset self.lastTime so we don't time right after the
		-- user closes the static popup window.
		self.lastTime = GetTime();
	else
		if (GetTime() - self.lastTime > module.timeoutValue) then
			-- It is taking too long to retrieve the current item.
			module:hideOpenMailTakeItemPopups();
			module:logIncoming(false, self, "CT_MailMod/MAIL_TIMEOUT");
			return 2;
		end
	end
	if (self.mailCount ~= inboxNumItems) then
		-- The number of messages in the inbox has changed.
		module:hideOpenMailTakeItemPopups();
		module:logPending(self);
		if (inboxNumItems > self.mailCount) then
			-- The number of items in the inbox has increased.
			-- This is probably the result of a call to CheckInbox()
			-- which may add mail to the inbox.
			-- This could cause problems with regards to correctly knowing
			-- which messages are selected, so we need to cancel processing.
			return 2;
		end
		-- The mail has been deleted from the inbox.
		return 3;
	end
	self:update();  -- Get current information
	if (not self.itemInit) then
		self.itemInit = true;
		-- Remember how many items before we try to take this one.
		self.itemCount = self.numItems;
	end
	if (self.itemCount ~= self.numItems) then
		-- The item has been taken.
		-- We're finished with this item.
		module:logPending(self);
		return 3;
	end
	if (not self.haveTakenItem1) then
		-- Take the item
		self.haveTakenItem1 = true;
		self.haveTakenItem2 = false;
		retrieveOpenItem(self);  -- may set self.haveTakenItem2 to true
	end
	if (self.haveTakenItem2) then  -- may get set via the StaticPopup or the retrieveOpenItem() call a few lines up.
		-- We issued a TakeInboxItem() call.
		self.haveTakenItem2 = nil;
		return 1
	end
	-- The item has not been removed from the mail yet.
	-- Keep waiting.
	return 0;
end

--------------------------------------------
-- Take a money attachment from the OpenMailFrame window.

function incMail:retrieveMoneyFromOpenMail(cancelProcessing)
	-- Retrieves money from an open mail.
	--
	-- Returns:
	--   0 == Continue calling this function
	--   1 == Continue calling this function after a delay
	--   2 == Cancel all processing
	--   3 == Proceed to the next action in the queue
	--
	-- Additional mail object members used by this function:
	-- .openInit
	-- .lastTime
	-- .mailCount
	--
	-- .itemInit
	--
	-- .moneyInit
	-- .haveTakenMoney
	--
	local inboxNumItems = GetInboxNumItems();
	if (not self.openInit) then
		-- Open mail intialization.
		-- Usually done once per open mail.
		self:retrieveFromOpenMailInit();
	end
	if (not self.moneyInit) then
		-- Initialization for taking money attachment from the open mail.
		self.lastTime = GetTime();
		self.mailCount = inboxNumItems;
		self.logPrint = true;
		self.haveTakenMoney = nil;
	end
	if (cancelProcessing) then
		-- Processing is being cancelled.
		module:logPending(self);
		return 2;
	end
	if (GetTime() - self.lastTime > module.timeoutValue) then
		-- It is taking too long to retrieve the money attachment.
		module:logIncoming(false, self, "CT_MailMod/MAIL_TIMEOUT");
		return 2;
	end
	if (self.mailCount ~= inboxNumItems) then
		-- The number of messages in the inbox has changed.
		module:logPending(self);
		if (inboxNumItems > self.mailCount) then
			-- The number of items in the inbox has increased.
			-- This is probably the result of a call to CheckInbox()
			-- which may add mail to the inbox.
			-- This could cause problems with regards to correctly knowing
			-- which messages are selected, so we need to cancel processing.
			return 2;
		end
		-- The mail has been deleted from the inbox.
		return 3;
	end
	if (not self.moneyInit) then
		self.moneyInit = true;
	end
	self:update()  -- Get current info
	if (self.money == 0) then
		-- The money has been taken.
		module:logPending(self);
		return 3;
	end
	if (not self.haveTakenMoney) then
		-- Take the money
		self.haveTakenMoney = true;

		self.logSuccess = true;
		self.logMessage = "CT_MailMod/MAIL_TAKE_MONEY_OK";
		module:printLogMessage(self.logSuccess, self, self.logMessage);
		self.logPrint = false;

		self.logMoney = self.money;
		self.logPending = true;

		OpenMailFrame.updateButtonPositions = false;
		TakeInboxMoney(self.id);

		self.lastTime = GetTime();
		return 1;
	end
	-- The money was not removed from the mail yet.
	-- Keep waiting.
	return 0;
end

--------------------------------------------
-- Download mail into the inbox.

local downloadNumItems;

function module:downloadMail(cancelProcessing)
	-- Download mail into the inbox.
	--
	-- Returns:
	--   0 == Continue calling this function
	--   1 == Continue calling this function after a delay
	--   2 == Cancel all processing
	--   3 == Proceed to the next action in the queue
	--
	local inboxNumItems, totalCount = GetInboxNumItems();
	if (downloadNumItems == nil) then
		-- Intialize
		downloadNumItems = inboxNumItems;
		print(module.text["CT_MailMod/MAIL_DOWNLOAD_BEGIN"]);
		module:inboxUnselectAll();
		module:inboxUpdateSelection();
	end
	if (cancelProcessing) then
		-- Processing is being cancelled.
		downloadNumItems = nil;
		return 2;
	end
	if (inboxNumItems > downloadNumItems) then
		-- Mail has been downloaded into the inbox.
		downloadNumItems = nil;
		print(module.text["CT_MailMod/MAIL_DOWNLOAD_END"]);
		return 3;
	end
	CheckInbox();
	return 0;
end

--------------------------------------------
-- Mail Actions

function module:actionRetrieveMail(data)
	-- This is a function which can be added as a mail action
	-- to retrieve a mail from the inbox.
	--
	-- Values:
	--   data.actionType == action type (should be: "takeall")
	--   data.procInit == initialization flag (should initially be: nil)
	--   data.mail == mail object
	--   data.cancel == is set to true when processing is being cancelled
	--
	local mail, ret;
	mail = data.mail;
	if (not data.procInit) then
		if (data.cancel or not mail:verifyMail()) then
			return nil;
		end
		data.procInit = true;
		module:beginIncomingAction(data);
	end
	ret = mail:retrieveSelectedMail(data.cancel);
	if (ret >= 2) then
		-- Finished with this mail
		module:endIncomingAction(data);
		data.procInit = nil;
	end
	return module:getProcessingReturnValue(ret);
end

function module:actionReturnMail(data)
	-- This is a function which can be added as a mail action
	-- to return a mail from the inbox.
	--
	-- Values:
	--   data.actionType == action type (should be: "return")
	--   data.procInit == initialization flag (should initially be: nil)
	--   data.mail == mail object
	--   data.cancel == is set to true when processing is being cancelled
	--
	local mail, ret;
	mail = data.mail;
	if (not data.procInit) then
		if (data.cancel or not mail:verifyMail()) then
			return nil;
		end
		data.procInit = true;
		module:beginIncomingAction(data);
	end
	ret = mail:returnSelectedMail(data.cancel);
	if (ret >= 2) then
		-- Finished with this mail
		module:endIncomingAction(data);
		data.procInit = nil;
	end
	return module:getProcessingReturnValue(ret);
end

function module:actionDeleteMail(data)
	-- This is a function which can be added as a mail action
	-- to delete a mail from the inbox.
	--
	-- Values:
	--   data.actionType == action type (should be: "delete")
	--   data.procInit == initialization flag (should initially be: nil)
	--   data.mail == mail object
	--   data.cancel == is set to true when processing is being cancelled
	--
	local mail, ret;
	mail = data.mail;
	if (not data.procInit) then
		if (data.cancel or not mail:verifyMail()) then
			return nil;
		end
		data.procInit = true;
		module:beginIncomingAction(data);
	end
	ret = mail:deleteSelectedMail(data.cancel);
	if (ret >= 2) then
		-- Finished with this mail
		module:endIncomingAction(data);
		data.procInit = nil;
	end
	return module:getProcessingReturnValue(ret);
end

function module:actionRetrieveOpenMailItem(data)
	-- This is a function which can be added as a mail action
	-- to retrieve an item attachment from the OpenMailFrame.
	--
	-- Values:
	--   data.actionType == action type (should be: "takeitem")
	--   data.procInit == initialization flag (should initially be: nil)
	--   data.mail == mail object
	--   data.itemIndex == index number of the item attachment to be taken (1 to n)
	--   data.cancel == is set to true when processing is being cancelled
	--
	local mail, ret;
	mail = data.mail;
	if (not data.procInit) then
		if (data.cancel or not mail:verifyMail()) then
			return nil;
		end
		data.procInit = true;
		module:beginIncomingAction(data);
		mail.itemInit = false;  -- Reset the itemInit flag each time user clicks on an attachment to take it.
		mail.nextItem = data.itemIndex;  -- Attachment number to take.
	end
	ret = mail:retrieveItemFromOpenMail(data.cancel);
	if (ret >= 2) then
		if (ret == 2) then
			-- Cancel all processing.

			-- Reset the mail.openInit value to ensure we start
			-- a new log entry, etc if the user tries to take
			-- another item.
			mail.openInit = false;
		else
			-- Finished with this item.
		end
		module:endIncomingAction(data);
		data.procInit = nil;
	end
	return module:getProcessingReturnValue(ret);
end

function module:actionRetrieveOpenMailMoney(data)
	-- This is a function which can be added as a mail action
	-- to retrieve a money attachment from the OpenMailFrame.
	--
	-- Values:
	--   data.actionType == action type (should be: "takemoney")
	--   data.procInit == initialization flag (should initially be: nil)
	--   data.mail == mail object
	--   data.cancel == is set to true when processing is being cancelled
	--
	local mail, ret;
	mail = data.mail;
	if (not data.procInit) then
		if (data.cancel or not mail:verifyMail()) then
			return nil;
		end
		data.procInit = true;
		module:beginIncomingAction(data);
		mail.moneyInit = false;
	end
	ret = mail:retrieveMoneyFromOpenMail(data.cancel);
	if (ret >= 2) then
		if (ret == 2) then
			-- Cancel all processing.

			-- Reset the mail.openInit value to ensure we start
			-- a new log entry, etc if the user tries to take
			-- another item.
			mail.openInit = false;
		end
		module:endIncomingAction(data);
		data.procInit = nil;
	end
	return module:getProcessingReturnValue(ret);
end

function module:actionDownloadMail(data)
	-- This is a function which can be added as a mail action
	-- to download mail into the inbox.
	--
	-- Values:
	--   data.actionType == action type (should be: "download")
	--   data.procInit == initialization flag (should initially be: nil)
	--   data.cancel == is set to true when processing is being cancelled
	--
	local ret;
	if (not data.procInit) then
		if (data.cancel) then
			return nil;
		end
		data.procInit = true;
		module:beginIncomingAction(data);
	end
	ret = module:downloadMail(data.cancel);
	if (ret >= 2) then
		module:endIncomingAction(data);
		data.procInit = nil;
	end
	return module:getProcessingReturnValue(ret);
end

--------------------------------------------
-- Processing control

function module:beginIncomingProcessing()
	-- Call this to start incoming mail processing.
	--
	-- Returns: true if processing begins.
	--          false if processing already in progress.

	-- This is usually called after a user clicks a button
	-- and actions are added to the mail action queue.
	--
	-- The INCOMING_START event can be use to prepare the UI
	-- for processing. Certain items may need to be enabled
	-- or disabled, etc.

	if (module.isProcessing) then
		return false;
	end
	if (not module:beginProcessing(module.endIncomingProcessing)) then
		return false;
	end

	module:raiseCustomEvent("INCOMING_START");

	return true;
end

function module:endIncomingProcessing()
	-- This gets called from module:endProcessing() when all incoming mail
	-- processing has finished.

	module:inboxUnselectAll();
	module:inboxUpdateSelection();

	module:raiseCustomEvent("INCOMING_STOP");
end

function module:beginIncomingAction(data)
	-- Call this function at the start of an incoming mail action function.
	--
	-- The INCOMING_ACTION_START event can be use to prepare the UI
	-- for processing the current action. Certain items may need to be
	-- enabled or disabled, etc.

	module:raiseCustomEvent("INCOMING_ACTION_START", data);
end

function module:endIncomingAction(data)
	-- Call this function at the end of an incoming mail action function.
	--
	-- The INCOMING_ACTION_STOP event can be use to return certain items
	-- to a disabled or enabled state, etc (perhaps to the state they were
	-- in at the INCOMING_START event).

	local mail = data.mail;

	if (mail) then
		module:inboxUnselectSingle(mail.id);
		module:inboxUpdateSelection();
	end

	-- Hide any of the CTMod static popup windows that might still be on screen.
	module:hideMailDeletePopups();
	module:hideOpenMailTakeItemPopups()

	-- To be safe, also hide the Blizzard static popups.
	StaticPopup_Hide("DELETE_MAIL");
	StaticPopup_Hide("DELETE_MONEY");
	StaticPopup_Hide("COD_ALERT");
	StaticPopup_Hide("COD_CONFIRMATION");
	StaticPopup_Hide("COD_CONFIRMATION_AUTO_LOOT");

	module:raiseCustomEvent("INCOMING_ACTION_STOP", data);
end
