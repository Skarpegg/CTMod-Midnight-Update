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

module.selectedMail = {};

--------------------------------------------
-- Selecting and unselecting mail

function module:inboxSelectAll()
	-- Select all mail.
	local selectedMail = module.selectedMail;
	local mailCount = GetInboxNumItems();
	for i = 1, mailCount do
		selectedMail[i] = true;
	end
	module.rangeStart = nil;
	module.selectAllMail = true;
end

function module:inboxUnselectAll()
	-- Unselect all mail.
	local selectedMail = module.selectedMail;
	local mailCount = GetInboxNumItems();
	for k, v in pairs(selectedMail) do
		selectedMail[k] = false;
	end
	module.rangeStart = nil;
	module.selectAllMail = false;
end

function module:inboxSelectSingle(mailIndex)
	-- Select single mail.
	module.selectedMail[mailIndex] = true;
	module.rangeStart = nil;
end

function module:inboxUnselectSingle(mailIndex)
	-- Unselect single mail.
	module.selectedMail[mailIndex] = false;
	module.rangeStart = nil;
	module.selectAllMail = false;
end

function module:inboxIsSelected(mailIndex)
	-- Is the specified mail selected?
	return module.selectedMail[mailIndex];
end

function module:inboxGetNumSelected()
	-- Returns number of messages that are selected.
	local selectedMail;
	local numSelected = 0;
	selectedMail = module.selectedMail;
	for k, v in pairs(selectedMail) do
		if (v) then
			numSelected = numSelected + 1;
		end
	end
	return numSelected;
end

--------------------------------------------
-- Retrieving selected mail

function module:retrieveSelected()
	-- Open all mail that has been selected in the inbox.
	if (module.isProcessing) then
		return false;
	end
	-- Add selected mail starting with the oldest.
	-- This is easier to work with than starting with the newest,
	-- since we will know that the mail ids that are in the queue
	-- won't change during processing if a mail gets deleted.
	-- It also has the benefit of causing log entries to appear
	-- in the same order as the selected mail in the inbox.
	local selectedMail = module.selectedMail;
	local mailCount = GetInboxNumItems();
	for i = mailCount, 1, -1 do
		if (selectedMail[i]) then
			local mail = module:loadMail(i);
			local data = {actionType = "takeall", mail = mail};
			module:addMailAction(data, module.actionRetrieveMail);
		end
	end
	return module:beginIncomingProcessing();
end

function module:retrieveSingle(mailIndex)
	-- Select a single mail in the inbox and then retrieve it.
	if (module.isProcessing) then
		return false;
	end
	module:inboxUnselectAll();
	module:inboxSelectSingle(mailIndex);
	module:inboxUpdateSelection();
	return module:retrieveSelected();
end

--------------------------------------------
-- Returning selected mail

function module:returnSelected()
	-- Return all mail that has been selected in the inbox.
	if (module.isProcessing) then
		return false;
	end
	-- Add selected mail starting with the oldest.
	local selectedMail = module.selectedMail;
	local mailCount = GetInboxNumItems();
	for i = mailCount, 1, -1 do
		if (selectedMail[i]) then
			local mail = module:loadMail(i);
			local data = {actionType = "return", mail = mail};
			module:addMailAction(data, module.actionReturnMail);
		end
	end
	return module:beginIncomingProcessing();
end

function module:returnSingle(mailIndex)
	-- Select a single mail in the inbox and then return it.
	if (module.isProcessing) then
		return false;
	end
	module:inboxUnselectAll();
	module:inboxSelectSingle(mailIndex);
	module:inboxUpdateSelection();
	return module:returnSelected();
end

--------------------------------------------
-- Deleting selected mail

function module:deleteSelected()
	-- Delete all mail that has been selected in the inbox.
	if (module.isProcessing) then
		return false;
	end
	-- Add selected mail starting with the oldest.
	local selectedMail = module.selectedMail;
	local mailCount = GetInboxNumItems();
	for i = mailCount, 1, -1 do
		if (selectedMail[i]) then
			local mail = module:loadMail(i);
			local data = {actionType = "delete", mail = mail};
			module:addMailAction(data, module.actionDeleteMail);
		end
	end
	return module:beginIncomingProcessing();
end

function module:deleteSingle(mailIndex)
	-- Select a single mail in the inbox and then delete it.
	if (module.isProcessing) then
		return false;
	end
	module:inboxUnselectAll();
	module:inboxSelectSingle(mailIndex);
	module:inboxUpdateSelection();
	return module:deleteSelected();
end
