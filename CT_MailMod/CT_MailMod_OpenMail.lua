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


-- OpenMailFrame related routines


--------------------------------------------
-- Initialize open mail object

function module:initOpenMail()
	-- Initialize the mail object we're using for the OpenMailFrame.
	local mail;
	local mailIndex = InboxFrame.openMailID;
	if (mailIndex and mailIndex > 0) then
		mail = module:loadMail(mailIndex);

		local button = OpenMailMoneyButton;
		button:Enable();
		SetItemButtonDesaturated(button, false, 0.5, 0.5, 0.5)
		button.ctData = nil;
		button.ctClicked = nil;

		local maxReceive = ATTACHMENTS_MAX_RECEIVE or 16; -- Safeguard for Retail
		for i = 1, maxReceive do
			local button = _G["OpenMailAttachmentButton" .. i];
			if button then
				button:Enable();
				SetItemButtonDesaturated(button, false, 0.5, 0.5, 0.5)
				button.ctData = nil;
				button.ctClicked = nil;
			end
		end
	end
	module.openMail = mail;
end

--------------------------------------------
-- Close the OpenMailFrame.

function module:closeOpenMail()
	InboxFrame.openMailID = nil;
	HideUIPanel(OpenMailFrame);
end

--------------------------------------------
-- The frame is being hidden.

-- In the MailFrame.xml file, Blizzard specifies the OnHide
-- script handler for the OpenMailFrame as follows:
-- 	<OnHide function="OpenMailFrame_OnHide"/>
-- That syntax causes it to assign a reference to the function.
--
-- We want to alter the internal behaviour of the OpenMailFrame_OnHide
-- function, so a post hook of the function doesn't do us any good.
-- Plus, a posthook of their function would never get called due to
-- the syntax they used in the xml for the OnHide script handler
-- (each time the OnHide script is executed they are calling a
-- reference to the function, rather than looking up the global
-- function name).
--
-- We can't just create a replacement OpenMailFrame_OnHide function
-- due to the syntax they used for the OnHide script handler in the
-- xml file (the OnHide script handler has been assigned a reference
-- to the original function).
--
-- So, in addition to creating a replacement OpenMailFrame_OnHide function,
-- we will also need to assign a new OnHide script handler that will
-- call our replacement function.


-- Replace the OpenMailFrame_OnHide function with our own version.
--
-- Most of the code is the same as the original function.
-- New lines of code are surrounded by, or ended with: -- *new*
-- Modified lines of code are surrounded by, or ended with: -- *mod*
--
function OpenMailFrame_OnHide()
	StaticPopup_Hide("DELETE_MAIL");
	if ( not InboxFrame.openMailID ) then
		if InboxFrame_Update then InboxFrame_Update(); end
		PlaySound(SOUNDKIT.IG_BACKPACK_CLOSE or 830); -- Made safe for Retail
		return;
	end

	-- Determine if this is an auction temp invoice
	local bodyText, texture, isTakeable, isInvoice = GetInboxText(InboxFrame.openMailID);
	local isAuctionTempInvoice = false;
	if ( isInvoice ) then
		local invoiceType, itemName, playerName, bid, buyout, deposit, consignment, moneyDelay, etaHour, etaMin = GetInboxInvoiceInfo(InboxFrame.openMailID);
		if (invoiceType == "seller_temp_invoice") then
			isAuctionTempInvoice = true;
		end
	end

	-- If mail contains no items, then delete it on close
	local packageIcon, stationeryIcon, sender, subject, money, CODAmount, daysLeft, itemCount, wasRead, wasReturned, textCreated  = GetInboxHeaderInfo(InboxFrame.openMailID);
	if ( money == 0 and not itemCount and textCreated and not isAuctionTempInvoice ) then
		-- *mod*
		-- The only mail that doesn't auto-delete when all money and items are removed,
		-- is mail that contains text.
		--
		-- Blizzard's "if" (see above) wants to delete the mail when all money and
		-- items have been taken, and the textCreated property is true.
		--
		-- The textCreated property is true for all returned mail (even if the text
		-- attachment was never taken, and even if it never had any text in it),
		-- for mail where the text attachment was taken, for "auction successful"
		-- mail (which has no text), and for "auction won" mail (which has no text).
		--
		-- However, deleting a mail when the OpenMailFrame is being hidden, could
		-- cause problems for us.
		--
		--   The user might have messages selected in the inbox, and deleting a mail
		--   could cause the remaining mail in the inbox to shift, resulting in the
		--   wrong messages being selected.
		--
		--   We may still be processing mail when the OpenMailFrame gets closed.
		--   We don't want the mail to be deleted while we are still working with it.
		--
		-- Also, since returned mail without text will auto delete when the last item is
		-- taken from it, there is no need to try and delete it here as well.
		--
		-- To avoid these types of problems, mail containing text should be manually
		-- deleted by the user via the "Delete" button on the OpenMailFrame (instead of
		-- clicking the close button), or by using the "x" button below the expiry time
		-- on the inbox window.
		--
		-- *mod*
		-- DeleteInboxItem(InboxFrame.openMailID);  -- *mod*
	end
	InboxFrame.openMailID = 0;
	InboxFrame_Update();
	PlaySound(SOUNDKIT.IG_BACKPACK_CLOSE or 830);
end

-- Replace the OnHide script for the OpenMailFrame with our own.
--
OpenMailFrame:SetScript("OnHide",
	function(...)
		-- Call our modified replacement function.
		OpenMailFrame_OnHide();
		-- Finish with the mail object assigned to the OpenMailFrame window,
		-- although it may still be referenced by the current action being
		-- processed.
		module.openMail = nil;
	end
);

--------------------------------------------
-- Attachment buttons

--
-- The OnClick script (see MailFrame.xml) for the virtual
-- OpenMailAttachment button, calls the OpenMailAttachment_OnClick
-- function using the global function name.
--
-- We are going to provide a replacement OpenMailAttachment_OnClick
-- function since we want full control of what it does.
--
function OpenMailAttachment_OnClick(self, itemIndex)
	-- User clicked on an item attachment in the OpenMailFrame.
	local mail = module.openMail;
	if (not mail) then
		return;
	end
	-- Do not add the action to the queue if we are already processing,
	-- unless the current action type is "takeitem" or "takemoney".
	if (module.isProcessing) then
		local actionType = module:getCurrentActionType();
		if (not (actionType == "takeitem" or actionType == "takemoney")) then
			return;
		end
	end
	-- Don't add the action if we have already clicked the item attachment.
	if (not self.ctClicked) then
		-- The user can click an attachment button, even if previously
		-- clicked ones have not finished retrieving their item yet.
		-- Each button click adds an action to the queue which will be
		-- handled once the existing actions are completed.

		-- We need to keep track of which item attachments have been clicked
		-- to prevent the user from clicking the same one more than once, since
		-- that would cause us to add multiple actions for the same attachment.
		self.ctClicked = true;

		SetItemButtonDesaturated(self, true, 0.5, 0.5, 0.5)

		-- Retrieve a single item from the current mail in the OpenMailFrame.
		-- There can be more than one "takeitem" action in the queue.
		local data = {actionType = "takeitem", mail = mail, itemIndex = itemIndex};
		module:addMailAction(data, module.actionRetrieveOpenMailItem);

		self.ctData = data;

		if (not module.isProcessing) then
			module:beginIncomingProcessing();
		end
	else
		-- Clicking an already clicked attachment will remove it from the queue
		-- as long as it is not the one currently being processed.
		local removed = module:removeMailAction(self.ctData);
		if (removed) then
			SetItemButtonDesaturated(self, false, 0.5, 0.5, 0.5)
			self.ctClicked = nil;
			self.ctData = nil;
		end
	end
end

--
-- We are going to provide a replacement OnClick script for
-- the OpenMailMoneyButton button since we want full control
-- of what it does.
--
OpenMailMoneyButton:SetScript("OnClick",
	function (self, ...)
		if (not self) then
			-- In case another addon hooks this script and doesn't pass the self value.
			self = OpenMailMoneyButton;
		end
		-- User clicked on the money attachment button.
		local mail = module.openMail;
		if (not mail) then
			return;
		end
		-- Do not add the action to the queue if we are already processing,
		-- unless the current action type is "takeitem".
		if (module.isProcessing) then
			local actionType = module:getCurrentActionType();
			if (not (actionType == "takeitem")) then
				return;
			end
		end
		-- Don't add the action if we have already clicked the money attachment.
		if (not self.ctClicked) then
			-- Keep track of the fact that the user has clicked the money attachment.
			self.ctClicked = true;

			SetItemButtonDesaturated(self, true, 0.5, 0.5, 0.5)

			-- Retrieve money attachment from the current mail in the OpenMailFrame.
			-- There may already be "takeitem" actions in the queue.
			local data = {actionType = "takemoney", mail = mail};
			module:addMailAction(data, module.actionRetrieveOpenMailMoney);

			self.ctData = data;

			if (not module.isProcessing) then
				module:beginIncomingProcessing();
			end
		else
			local removed = module:removeMailAction(self.ctData);
			if (removed) then
				SetItemButtonDesaturated(self, false, 0.5, 0.5, 0.5)
				self.ctClicked = nil;
				self.ctData = nil;
			end
		end
	end
);

--------------------------------------------
-- The Delete/Return button.

--
-- We are going to provide a replacement OpenMail_Delete
-- function since we want full control of what it does.
--
function OpenMail_Delete()
	local mail = module.openMail;
	if (not mail) then
		return;
	end
	if (module.isProcessing) then
		return;
	end
	if (InboxItemCanDelete(mail.id)) then
		-- Delete the mail
		module:deleteSingle(mail.id);
	else
		-- Return the mail
		module:returnSingle(mail.id);
	end
end

--
-- We are going to provide a replacement OnClick script
-- for the OpenMailDeleteButton button since we want full
-- control of what it does.
--
OpenMailDeleteButton:SetScript("OnClick",
	function(...)
		OpenMail_Delete();
	end
);

--------------------------------------------
-- Custom event handling to disable/enable stuff before/during/after processing.

local function customEvents_OpenMailButtons(self, event, data)
	local actionType;
	if (data and data.actionType) then
		actionType = data.actionType;
	end
	if (event == "INCOMING_START") then
		-- Disable everything
		OpenMailDeleteButton:Disable();

		local button = OpenMailMoneyButton;
		button:Disable();
		SetItemButtonDesaturated(button, false, 0.5, 0.5, 0.5)

		local maxReceive = ATTACHMENTS_MAX_RECEIVE or 16; -- Safeguard for Retail
		for i = 1, maxReceive do
			local button = _G["OpenMailAttachmentButton" .. i];
			if button then
				button:Disable();
				SetItemButtonDesaturated(button, false, 0.5, 0.5, 0.5)
			end
		end

	elseif (event == "INCOMING_ACTION_START") then
		-- If user is taking items or money from the open mail window,
		-- then we can re-enable the attachment buttons so they can be
		-- clicked during processing.
		-- Once a "takeitem" or "takemoney" action is detected, we know that
		-- those will be the only action types placed in the queue during
		-- this processing phase because we've taken steps to prevent other
		-- types of actions from getting added.
		if (actionType == "takeitem" or actionType == "takemoney") then
			OpenMailMoneyButton:Enable();
			local maxReceive = ATTACHMENTS_MAX_RECEIVE or 16; -- Safeguard for Retail
			for i = 1, maxReceive do
				_G["OpenMailAttachmentButton" .. i]:Enable();
			end
		end

	elseif (event == "INCOMING_STOP") then
		-- Restore everything
		OpenMailDeleteButton:Enable();

		local button = OpenMailMoneyButton;
		button:Enable();
		SetItemButtonDesaturated(button, false, 0.5, 0.5, 0.5)
		button.ctData = nil;
		button.ctClicked = nil;

		local maxReceive = ATTACHMENTS_MAX_RECEIVE or 16; -- Safeguard for Retail
		for i = 1, maxReceive do
			local button = _G["OpenMailAttachmentButton" .. i];
			if button then
				button:Enable();
				SetItemButtonDesaturated(button, false, 0.5, 0.5, 0.5)
				button.ctData = nil;
				button.ctClicked = nil;
			end
		end
	end
end
module:regCustomEvent("INCOMING_START", customEvents_OpenMailButtons);
module:regCustomEvent("INCOMING_ACTION_START", customEvents_OpenMailButtons);
module:regCustomEvent("INCOMING_STOP", customEvents_OpenMailButtons);
