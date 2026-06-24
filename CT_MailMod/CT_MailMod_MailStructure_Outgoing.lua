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
-- Incoming Mail Structure

local outMail = { };
local outMail_meta = { __index = outMail };

-- Creates the main mail structure.
function module:newOutgoingMail(sendTo, subject, body)
	local mail = setmetatable(self:getTable(), outMail_meta);
	mail.sender = module:getPlayerName();  -- "name @ server"
	mail.receiver = module:getPlayerName(sendTo);  -- "name @ server"
	mail.subject = subject or "";
	mail.body = body or "";
	mail.money = 0;
	mail.codAmount = 0;
	mail.numItems = 0;
	mail.logItems = {};
	mail.logMoney = 0;
	mail.serial = nil;
	return mail;
end

function outMail:getName()
	return string.format("'%s', To %s", self.subject, self.receiver);
end

--------------------------------------------
-- Sending Related

local receiverText;
local subjectText;
local bodyText;
local codAmount;
local moneyAmount;
local logItems = {};

local function sendmailGetItemInfo(itemIndex)
	-- Get item link and quantity.
	local link = GetSendMailItemLink(itemIndex);
	if (link) then
		-- Return item link, and quantity
		return link:match("|H(item:[^|]+)|h"), (select(4, GetSendMailItem(itemIndex)));
	end
	-- Link is nil if no item is attached to the slot.
	return nil, nil;
end

local function sendmailGetItems()
	-- Get list of attachments to be sent.
	logItems = {};
	local link, count;
	-- Safeguard for Retail where ATTACHMENTS_MAX_SEND has been removed (default is 12 slots)
	local maxSend = ATTACHMENTS_MAX_SEND or 12;
	for i = 1, maxSend do
		link, count = sendmailGetItemInfo(i);
		-- If no item is attached to this slot, then 'link' will be nil.
		if (link and count) then
			-- Item is attached in this slot.
			tinsert(logItems, {link, count});
		end
	end
end

local function sendmailGetCOD()
	-- Get COD amount
	local value = GetSendMailCOD();
	-- Remember the largest amount before we see the MAIL_SEND_SUCCESS event.
	if (value > codAmount) then
		codAmount = value;
	end
end

local function sendmailGetMoney()
	-- Get money amount
	local value = GetSendMailMoney();
	-- Remember the largest amount before we see the MAIL_SEND_SUCCESS event.
	if (value and moneyAmount and value > moneyAmount) then
		moneyAmount = value;
	end
end

local function sendmailResetValues()
	receiverText = module:getPlayerName();  -- "name @ server"
	subjectText = "Not available due to another addon";
	bodyText = "";
	codAmount = 0;
	moneyAmount = 0;			
end

local function sendmailResetValuesAndItems()
	sendmailResetValues();
	logItems = {};
end

local function sendmailMailSent()
	-- Mail was sent.

	-- Create a mail object.
	local mail = module:newOutgoingMail(receiverText, subjectText, bodyText);
	mail.money = moneyAmount;
	mail.codAmount = codAmount;

	if (mail.codAmount > 0) then
		mail.logMoney = -mail.codAmount;
	else
		mail.logMoney = mail.money;
	end

	mail.logItems = {};
	for i, v in ipairs(logItems) do
		mail.logItems[i] = { v[1], v[2] };
	end

	mail.numItems = #(mail.logItems);

	-- Log the outgoing message.
	mail.logPending = false;
	mail.logFunc = module.logOutgoing;
	mail.logPrint = true;
	mail.logSuccess = true;
	mail.logMessage = "CT_MailMod/MAIL_SEND_OK";
	module:logOutgoing(mail.logSuccess, mail, mail.logMessage)

	-- Reset values and items.
	sendmailResetValuesAndItems();
end

hooksecurefunc("SendMail",
	function(name, subject, body)
		-- Capture information about the mail being sent.
		receiverText = name or "";
		subjectText = subject or "";
		bodyText = body or "";
	end
);

module:regEvent("MAIL_CLOSED", sendmailResetValuesAndItems);
module:regEvent("MAIL_SHOW", sendmailResetValuesAndItems);
module:regEvent("MAIL_FAILED", sendmailResetValues);
module:regEvent("MAIL_SUCCESS", sendmailResetValues);
module:regEvent("MAIL_SEND_SUCCESS", sendmailMailSent);
module:regEvent("MAIL_SEND_INFO_UPDATE", sendmailGetItems);
module:regEvent("SEND_MAIL_COD_CHANGED", sendmailGetCOD);
module:regEvent("SEND_MAIL_MONEY_CHANGED", sendmailGetMoney);
