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
-- General Logging

-- Log entry timestamps:
--
--   The timestamp used in log entries created prior to CT_MailMod 3.210
--   was intended to be the time that the mail was sent. However, the
--   calculation was not correct, and the resulting times could be off
--   by as much as plus or minus 30 days (it depended on when the user
--   opened the message during the mail's expiry period).
--
--   This was the old calculation:
--      module:getTimeFromOffset(-mail.timeleft)
--
--   In order to properly calculate the sent time, you need to know
--   the maximum expiry time for every possible type of mail.
--   This is what would have worked (if mail.maxtimeleft could be
--   determined):
--      module:getTimeFromOffset(-(mail.maxtimeleft - mail.timeleft))
--
--   However, the maximum expiry time is not provided by the server, and
--   it can vary from 31 days to just a few days or less, depending on
--   what type of mail you are dealing with (auction house mail, mail your
--   friend sent you, mail that Blizzard sent you, a new pet you got in the
--   mail, temporary invoices, etc).
--
--   As of CT_MailMod 3.210, new log entries are recorded in the log with
--   a timestamp equal to the time that the log entry was created.

local checkMailTime
hooksecurefunc("CheckInbox", function()
	checkMailTime = time()
end)
SendMailMailButton:HookScript("PreClick", function()
	checkMailTime = time()
end)

local function encodeLogEntry(success, type, mail, message)
	-- Encode a log entry
	local entry;
	local receiver, sender;

	if (mail) then
		if (type == "returned") then
			-- For mail being returned, log the entry as
			-- coming from the person doing the returning.
			-- (the receiver becomes the sender of the returned mail)
			-- (this is the same as if they had opened it and sent a new mail)
			receiver = mail.sender;
			sender = mail.receiver;
		else
			receiver = mail.receiver;
			sender = mail.sender;
		end
	end
	
	local timestamp, expires
	local maxDuration = mail.codAmount > 0 and 259200 or 2678400
	if (type == "outgoing") then
		timestamp = time()
		expires = timestamp + maxDuration
	else
		expires = checkMailTime + math.floor(mail.daysleft*86400+0.5)
		timestamp = expires - maxDuration
	end

	if ( success and mail ) then
		-- Format:
		--   success, type, receiver, sender, money, timestamp, expires, num items (N)
		--   subject, item_1 string, item_2, string, ..., item_N string
		--
		local numItems = 0;
		local items = "";
		local money = mail.logMoney;
		local list = mail.logItems;
		if (list) then
			-- Build list of items taken so far
			local link, count;
			local entry;
			numItems = #list;
			for i = 1, numItems do
				entry = list[i];
				items = items .. ("#%s/%d"):format(entry[1], entry[2]);  -- link, count
			end
		end
		money = money or 0;
		if (mail.body and mail.body ~= "") then
			-- added in CT_MailMod 
			entry = ("4#%s#%s#%s#%s#%d-%d#%d#%s#%s"):format(type, receiver, sender, money, timestamp, expires, numItems, mail.body:gsub("#","\26"), mail.subject) .. items;
		else
			entry = ("1#%s#%s#%s#%s#%d-%d#%d#%s"):format(type, receiver, sender, money, timestamp, expires, numItems, mail.subject) .. items;
		end

	elseif ( not success and message ) then
		if (not mail) then
			-- Old type "0" format: (no longer added to the log as of CT_MailMod 3.210)
			--   success, type, message
			-- entry = ("0#%s#%s"):format(type, message);

			-- Type "3" format: (added as of CT_MailMod 3.210)
			--   success, type, timestamp, message
			entry = ("3#%s#%d#%s"):format(type, timestamp, message);
		else
			-- Format:
			--   success, type, receiver, sender, subject, timestamp, expires, message
			entry = ("2#%s#%s#%s#%s#%d-%d#%s"):format(type, receiver, sender, mail.subject, timestamp, expires, message);
		end
	end

	return entry;
end

local function decodeLogEntry(logMsg)
	-- Decode a log entry
	local receiver, sender, subject, money, timestamp, expires, numItems, items, message, body

	local success, type, msg = logMsg:match("^(%d)#([^#]*)#(.*)$")
	if ( success == "1" or success == "4") then
		-- Success
		receiver, sender, money, timestamp, expires, numItems, message = msg:match("^([^#]*)#([^#]*)#([^#]*)#(%d*)%-?(%d-)#([^#]*)#(.*)$")
		if (success == "1") then
			subject, items = message:match("^(.-)#("..("[^#]+#"):rep(tonumber(numItems)-1).."[^#]+)$")
			body = ""
			if ( not items ) then
				subject = message
				items = ""
			end
		else -- if success == "4" then
			body, subject, items = message:match("^([^#]+)#(.+)#("..("[^#]+#"):rep(tonumber(numItems)-1).."[^#]+)$")
			if (not items) then
				items = ""
				body, subject = message:match("^([^#]+)#(.+)$")
				body = body and body:gsub("\26","#") or ""
			end
		end
		if (items == "") then
			return true, type, nil, receiver, sender, subject, tonumber(money), tonumber(timestamp), tonumber(expires), body
		else
			return true, type, nil, receiver, sender, subject, tonumber(money), tonumber(timestamp), tonumber(expires), body, ("#"):split(items)
		end

	elseif (success == "2") then
		-- New as of CT_MailMod 3.210
		-- Failure
		receiver, sender, subject, timestamp, expires, message = msg:match("^([^#]*)#([^#]*)#([^#]*)#(%d*)%-?(%d-)#(.*)$");
		return false, type, message, receiver, sender, subject, 0, tonumber(timestamp), tonumber(expires), "";

	elseif (success == "3") then
		-- New as of CT_MailMod 3.210
		-- Failure
		timestamp, expires, message = msg:match("^(%d*)%-?(%d-)#(.*)$");
		return false, type, message, nil, nil, nil, 0, tonumber(timestamp), tonumber(expires);

	else
		-- Type "0" record.
		-- As of CT_MailMod 3.210 these are no longer being added to the mail log (type "3" is now being added instead).
		-- This code is here to handle existing log entries, or future unknown record types.
		-- Failure
		return false, type, msg, nil, nil, nil, 0, 0, 0, "";
	end
end

-- date("%a, %b %d %I:%M%p", time());

local function getLogTable()
	-- Obtain a reference to the mail log table.
	local log = CT_MailModOptions.mailLog or {}
	CT_MailModOptions.mailLog = log
	return log
end

--------------------------------------------
-- Filtering coroutine (preventing fps drop with large data sets, by doing a little work at a time)

local filterProgress = 0;		-- The number of lines in the log table that have been processed so far.  Reset to zero whenever the filter changes, so the coroutine knows to redo its job.
local notBusyFiltering = true;		-- Flag to permit other code chunks to get things in motion.
local getFilteredTable;			-- Function to fetch the filter table, defined inside the do block below.
do
	-- Subset of the entire mail log table based on the current filter (sometimes incomplete) 
	local filteredLog = {};		
	
	-- Values decoded from an entry in the log table
	local success, action, message, receiver, sender, subject, money, timestamp;
	local items = {};
	
	-- Helper func, used by the coroutine to see if a pattern appears inside the localized names of any items.
	local function checkAttachments(pattern)
		for y = 1, 16 do
			if (items[y]) then
				local link = items[y]:match("^([^/]+)/(.+)$");
				-- Safe lookup that also falls back on the game's internal Item cache
				local name = GetItemInfo(link);
				if (not name and C_Item and C_Item.GetItemInfo) then
					local itemInfo = C_Item.GetItemInfo(link);
					name = itemInfo and itemInfo.itemName;
				end
				if (name and name:lower():find(pattern)) then
					return true;
				end
			else
				return false;
			end
		end
	end

	function getFilteredTable()  -- local; mimics a coroutine without actually making one.
		local filter = CT_MailMod_MailLog_FilterEditBox:GetText():lower();
		local log = getLogTable();
		if (filterProgress > #log or filterProgress < #filteredLog) then
			wipe(filteredLog);
			filterProgress = 0;
		elseif (filterProgress == #log) then
			return filteredLog;
		end
		
		local startTime = debugprofilestop();
		while (filterProgress < #log) do
			filterProgress = filterProgress + 1;
			local entry = log[filterProgress];

			success, action, message, receiver,
				sender, subject, money, timestamp, expires, body,
				items[1], items[2], items[3], items[4],
				items[5], items[6], items[7], items[8],
				items[9], items[10], items[11], items[12],
				items[13], items[14], items[15], items[16] = decodeLogEntry(entry);
			
			action =
				action == "returned" and module.text["CT_MailMod/MailLog/Return"]
				or action == "deleted" and module.text["CT_MailMod/MailLog/Delete"]
				or action == "outgoing" and module.text["CT_MailMod/MailLog/Send"]
				or action == "incoming" and module.text["CT_MailMod/MailLog/Open"]
				or "";

			local shouldInclude = true;
			for piece in filter:gmatch("%S+") do
				local property, value = piece:match("(.-):(.*)");
				if (
					property == "to" and (receiver == nil or not receiver:lower():find(value))
					or property == "from" and (sender == nil or not sender:lower():find(value))
					or property == "subject" and (subject == nil or not subject:lower():find(value))
					or property == "message" and (message == nil or not message:lower():find(value))
					or property == "action" and (action == nil or not action:lower():find(value))
					or property == "date" and (timestamp == nil or not date("%b %d %Y%m%d %Y-%m-%d %H:%M:%S", timestamp):lower():find(value))
					or property == "money" and (tonumber(money or 0) == 0 or not string.find(money, value))
					or property == "item" and (items[1] == nil or not checkAttachments(value))
					or (
						property ~= "to" 
						and property ~= "from" 
						and property ~= "subject" 
						and property ~= "message"
						and property ~= "action"
						and property ~= "date"
						and property ~= "money"
						and property ~= "item"
					) and not (
						receiver and receiver:lower():find(piece) 
						or sender and sender:lower():find(piece)
						or subject and subject:lower():find(piece) 
						or message and message:lower():find(piece)
						or action and action:lower():find(piece)
						or date("%b %d %y%m%d %y-%m-%d %H:%M:%S", timestamp):lower():find(piece) 
						or tonumber(piece) and money and string.find(money, piece)
						or checkAttachments(piece)
					)
				) then
					shouldInclude = false;
					break;	-- only breaks the for loop, not the outer while loop
				end
			end
			if (shouldInclude) then
				tinsert(filteredLog, entry);
			end

		
			-- If this loop has been running for over 20ms and still is not done, then defer some work until the next frame.  But only check once every 100 iterations.
			if (filterProgress % 100 == 0 and filterProgress ~= #log and debugprofilestop() - startTime > 20) then
				notBusyFiltering = false;
				CT_MailMod_MailLog.scrollChildren:SetAlpha(0.7);
				C_Timer.After(0, module.updateMailLog);
				return false;	-- sorry, but we are NOT ready to display results to the user yet!
			end
		end
		
		-- If we get this far, then filtering has reached its conclusion!
		notBusyFiltering = true;
		CT_MailMod_MailLog.scrollChildren:SetAlpha(1);
		return filteredLog;
	end
end

function module:printLogMessage(success, mail, message)
	-- Print a message in the chat window.
	if (module.opt.printLog) then
		local message = module.text[message];
		if (mail) then
			message = ("%s: %s"):format(mail:getName(), message);
		end
		(success and module.printformat or module.errorformat)(module, "<CT_MailMod> %s", message);
	end
end

local logSerial = 0;  -- Used to keep track of which mail object is associated with the most recent log entry.

local function writeLogEntry(self, type, success, mail, message)
	-- Write a log entry (it will either add a new one, or update the most recent one)
	if (not mail or (mail and mail.logPrint)) then
		-- Print a message in the chat window
		module:printLogMessage(success, mail, message);
	end
	if (module.opt.saveLog) then
		-- Encode the message, etc as a log entry.
		local entry = encodeLogEntry(success, type, mail, message);

		-- If this mail object is the same as the one associated with the most
		-- recent log entry then update that log entry, otherwise add a new log entry.
		local log = getLogTable()
		local previous = #log
		if (mail and mail.serial and mail.serial == logSerial and previous > 0) then
			log[previous] = entry  -- Update the existing entry
		elseif (type == "incoming" and previous > 0) then
				local found
				local monthago = time()-2678400
				for i=previous, max(1,previous-50), -1 do		-- starting with the most recent message, and moving backwards, but going back no further than 50 messages (arbitrary)
					local __, olderType, __, olderReceiver, olderSender, olderSubject, __, olderTimestamp, olderExpires = decodeLogEntry(log[i])
					if (olderTimestamp < monthago) then  -- stop if reaching messages sent over 31 days ago
						found = false
						break
					elseif(
						olderExpires
						and abs(checkMailTime + mail.daysleft*86400 - olderExpires) < 2
						and mail.subject == olderSubject
						and mail.receiver == olderReceiver 
						and mail.sender == olderSender
					) then
						found = true
						break
					end
				end
				if (not found) then
					tinsert(log, entry)
				end
		else
			tinsert(log, entry)  -- Add new entry
		end

		if (mail) then
			-- Remember the mail serial number associated with the most recent log entry.
			logSerial = mail.serial;
			-- Save the message
			mail.logMessage = message;
		else
			-- The most recent log entry does not belong to a mail object.
			logSerial = 0;
		end
		if (not success) then
			-- If the message just written was for a failure (error message),
			-- then ensure the next log entry will not replace the one that
			-- was just written.
			logSerial = 0;
		end
		-- Update the mail log display.
		module:updateMailLog();
	end
end

--------------------------------------------
-- Write pending log entry

function module:logPending(mail)
	if (mail and mail.logPending) then
		-- There is mail information that needs to be logged.
		local logFunc = mail.logFunc;
		if (logFunc) then
			logFunc(module, mail.logSuccess, mail, mail.logMessage);
		end
		mail.logPending = false;
		-- Can't clear the mail.logItems or mail.logMoney here,
		-- since taking items from the OpenMailFrame depends on
		-- maintaining those values while the user is taking items.
	end
end

--------------------------------------------
-- Incoming Mail Log

function module:logIncoming(success, mail, message)
	-- Log an incoming mail message.
	if (not module.opt.logOpenedMail) then
		-- User is not logging opened mail.
		return;
	end
	if (mail and not success) then
		-- We are dealing with a mail object and an error message.
		if (mail.logPending) then
			-- There is log information pending.
			-- We may need to create a log entry to record things taken so far.
			if (#mail.logItems > 0 or mail.logMoney ~= 0) then
				-- Add a log entry for the items/money that has been taken already.
				module:logPending(mail);
				-- Since we've just logged the pending items, and since we'll be
				-- writing an error message, we can go ahead and clear the .logItems
				-- and .logMoney values.
				mail.logItems = {};
				mail.logMoney = 0;
			end
			-- There is no longer anything pending to be logged,
			-- so reset the module.logPending flag.
			mail.logPending = false;
		end

		-- Reset the log serial number to 0 to ensure that the next log entry (the error message)
		-- does not replace the most recent log entry.
		logSerial = 0;

		-- Reset the mail.logPrint value to true.
		-- This will ensure that the error message will be displayed
		-- in chat (if the user has the option enabled).
		mail.logPrint = true;
	end
	writeLogEntry(module, "incoming", success, mail, message);
end

--------------------------------------------
-- Returned Mail Log

function module:logReturned(success, mail, message)
	-- Log a returned mail message.
	if (module.opt.logReturnedMail) then
		writeLogEntry(module, "returned", success, mail, message);
	end
end

--------------------------------------------
-- Deleted Mail Log

function module:logDeleted(success, mail, message)
	-- Log a deleted mail message.
	if (module.opt.logDeletedMail) then
		writeLogEntry(module, "deleted", success, mail, message);
	end
end

--------------------------------------------
-- Outgoing Mail Log

function module:logOutgoing(success, mail, message)
	-- Log an outgoing mail message.
	if (module.opt.logSentMail) then
		return writeLogEntry(module, "outgoing", success, mail, message);
	end
end


--------------------------------------------
-- Mail Log UI

do
	local updateMailLog;
	local resizeMailLog;
	local resizingMailLog;
	local numRows = 24
	local logHeight = 82 + numRows*22
	local defaultLogWidth = 800;
	local function mailLogFrameSkeleton()
		local scrollChild = {
			-- "texture#tl#br:0:1#1:1:1:0.25"
--			"texture#s:40:20#l:5:0#i:icon",
			"font#l:5:0#i:icontext#v:GameFontNormal##1:1:1:l:48",
			"font#s:100:20#l:55:0#i:receiver#v:GameFontNormal##1:1:1:l",
			"font#s:100:20#l:155:0#i:sender#v:GameFontNormal##1:1:1:l",
			"font#s:60:20#t:tl:285:0#i:date#v:GameFontNormal##1:1:1:l",
			"font#s:150:20#l:315:0#i:subject#v:ChatFontNormal##1:1:1:l",
			"font#r:-10:0#t#b#i:comment#v:GameFontNormal##1:1:1:l",
			-- Having a moneyframe "here", but creating it dynamically later
			-- Having several icons "here", but creating them dynamically later
			["onenter"] = function(self)
				module:displayTooltip(self,
				{
					self.icontext:GetText() or "", 
					self.sender:GetText() and "|cffcccccc" .. module.text["CT_MailMod/MailLog/Receiver"] .. " -|r " .. self.receiver:GetText() .. "#1:1:1", 
					self.receiver:GetText() and "|cffcccccc" .. module.text["CT_MailMod/MailLog/Sender"] .. " -|r " .. self.sender:GetText() .. "#1:1:1", 
					self.timestamp and "|cffcccccc" .. module.text["CT_MailMod/MailLog/Date"] .. " -|r " .. date("%Y-%m-%d %H:%M:%S", self.timestamp) .. "#1:1:1", 
					self.subject:GetText() and "|cffcccccc" .. module.text["CT_MailMod/MailLog/Subject"] .. " -|r " .. gsub(self.subject:GetText(),"#","~") .. "#1:1:1",
					self.tooltip1,
					self.tooltip2,
				}, "CT_ABOVEBELOW", 0, 0, CT_MailMod_MailLog);
			end
		}

		return "frame#n:CT_MailMod_MailLog#s:" .. defaultLogWidth .. ":" .. logHeight, {
			"backdrop#tooltip#0:0:0:0.75",
			"font#t:0:-10#v:GameFontNormalHuge#" .. module.text["CT_MailMod/MAIL_LOG"] .. "#1:1:1",

			"font#tl:tl:60:-47#i:receiverHeading#v:GameFontNormalLarge#" .. module.text["CT_MailMod/MailLog/Receiver"] .. "#1:1:1:c:100",
			"font#tl:tl:160:-47#i:senderHeading#v:GameFontNormalLarge#" .. module.text["CT_MailMod/MailLog/Sender"] .. "#1:1:1:c:100",
			"font#t:tl:285:-47#i:dateHeading#v:GameFontNormalLarge#" .. module.text["CT_MailMod/MailLog/Date"] .. "#1:1:1:c:55",
			"font#tl:tl:320:-47#i:subjectHeading#v:GameFontNormalLarge#" .. module.text["CT_MailMod/MailLog/Subject"] .. "#1:1:1:c:150",
			"font#tl:tl:475:-47#i:contentsHeading#v:GameFontNormalLarge#Contents#1:1:1:c:150",

			--"font#tl:20:-40#v:GameFontNormalLarge#Filter:#1:1:1",
			--"dropdown#n:CT_MAILMOD_MAILLOGDROPDOWN1#tl:80:-43#All Mail#Incoming Mail#Outgoing Mail",
			--"dropdown#n:CT_MAILMOD_MAILLOGDROPDOWN2#tl:220:-43#i:charDropdown#All Characters",

			["button#s:100:25#tr:-5:-5#n:CT_MailMod_Close_Button#v:GameMenuButtonTemplate#Close"] = {
				["onclick"] = function(self)
					HideUIPanel(CT_MailMod_MailLog);
				end,
			},
			--"button#s:100:25#tr:-135:-38#n:CT_MailMod_ResetData_Button#v:GameMenuButtonTemplate#Reset Data",
			"texture#tl:5:-67#br:tr:-5:-69#1:0.82:0",

			["editbox#tl:50:-10#s:200:25#n:CT_MailMod_MailLog_FilterEditBox#v:SearchBoxTemplate"] = {
				["onload"] = function(self)
					self:HookScript("OnTextChanged", function()
						-- There is a coroutine that will apply the filter 'a little bit at a time' to prevent fps drop.
						-- Each time the coroutine resumes, it uses filterProgress to know where it should start from.
						-- This also will refrain from going bonkers and consuming CPU usage when characters are changed rapidly (possible with fast typers, or holding backspace).
						
						filterProgress = 0;  -- Let the coroutine know to start from scratch on the next resume.
						
						if (notBusyFiltering) then
							notBusyFiltering = false;
							C_Timer.After(0.2, module.updateMailLog);	-- Multiple keystrokes in less than 0.2 sec will merge into a single call.
						end
					end);
					self:SetMaxLetters(255);	  -- another safeguard to avoid fps drops: excessively long filter texts perform poorly
					self:SetScript("OnShow", nil);
				end,
			},
			
			["button#tl:265:-10#s:25:25#?#v:GameMenuButtonTemplate"] = {
				["onenter"] = function(self)
					module:displayTooltip(self, {"Just start typing, or use filters such as...", "  action:|cff666666" .. module.text["CT_MailMod/MailLog/Open"] .. "|r|n  to|cff666666:Bob  |r|n  from:|cff666666" .. UnitName("player") .. "|r|n  date:|cff666666" .. date("%Y%m%d") .. "  (or other date/time formats)|r|n  subject:|cff666666HelloWorld!|r|n  money:|cff6666669000|r|n  item:|cff666666cloth|r|n  message:|cff666666foo|r#0.9:0.9:0.9"}, "ANCHOR_BOTTOMRIGHT");
				end,
			},

			["frame#tl:5:-72#br:-5:5#i:scrollChildren"] = {
				["frame#s:0:20#tl:0:0#r#i:1"] = scrollChild,
				["frame#s:0:21#tl:0:-22#r#i:2"] = scrollChild,
				["frame#s:0:21#tl:0:-44#r#i:3"] = scrollChild,
				["frame#s:0:21#tl:0:-66#r#i:4"] = scrollChild,
				["frame#s:0:21#tl:0:-88#r#i:5"] = scrollChild,
				["frame#s:0:21#tl:0:-110#r#i:6"] = scrollChild,
				["frame#s:0:21#tl:0:-132#r#i:7"] = scrollChild,
				["frame#s:0:21#tl:0:-154#r#i:8"] = scrollChild,
				["frame#s:0:21#tl:0:-176#r#i:9"] = scrollChild,
				["frame#s:0:21#tl:0:-198#r#i:10"] = scrollChild,
				["frame#s:0:21#tl:0:-220#r#i:11"] = scrollChild,
				["frame#s:0:21#tl:0:-242#r#i:12"] = scrollChild,
				["frame#s:0:21#tl:0:-264#r#i:13"] = scrollChild,
				["frame#s:0:21#tl:0:-286#r#i:14"] = scrollChild,
				["frame#s:0:21#tl:0:-308#r#i:15"] = scrollChild,
				["frame#s:0:21#tl:0:-330#r#i:16"] = scrollChild,
				["frame#s:0:21#tl:0:-352#r#i:17"] = scrollChild,
				["frame#s:0:21#tl:0:-374#r#i:18"] = scrollChild,
				["frame#s:0:21#tl:0:-396#r#i:19"] = scrollChild,
				["frame#s:0:21#tl:0:-418#r#i:20"] = scrollChild,
				["frame#s:0:21#tl:0:-440#r#i:21"] = scrollChild,
				["frame#s:0:21#tl:0:-462#r#i:22"] = scrollChild,
				["frame#s:0:21#tl:0:-484#r#i:23"] = scrollChild,
				["frame#s:0:21#tl:0:-506#r#i:24"] = scrollChild,
				["onload"] = function(self) 
					self:SetAlpha(0.7);
					self:SetClipsChildren(true)
				end,
			},

			["onload"] = function(self)
				local txDragRight, txDragLeft;
				if self.SetIsUnrestricted then self:SetIsUnrestricted(true) end				
				self:SetFrameLevel(100);
				self:EnableMouse(true);
				module:registerMovable("MAILLOG", self, true);

				-- Scroll Frame (made safe for modern WoW)
				local scrollFrame = CreateFrame("ScrollFrame", "CT_MailMod_MailLog_ScrollFrame",
					self, "FauxScrollFrameTemplate, BackdropTemplate");
				scrollFrame:SetPoint("TOPLEFT", self, 5, -72);
				scrollFrame:SetPoint("BOTTOMRIGHT", self, -26, 5);
				scrollFrame:SetScript("OnVerticalScroll", function(self, offset, ...)
					FauxScrollFrame_OnVerticalScroll(self, offset, 20, updateMailLog);
				end);
				scrollFrame:SetFrameLevel(scrollFrame:GetFrameLevel() + 1);
				

				-- Resizing frames
				local onUpdate = function(self, elapsed, ...)
					if (resizingMailLog) then
						self.resizingTimer = self.resizingTimer + elapsed;
						if (self.resizingTimer > 0.1) then
							self.resizingTimer = 0;
							resizeMailLog(self:GetParent());
						end
					end
				end;
				local onEnter = function(self, ...)
					module:displayPredefinedTooltip(self, "RESIZE");
					self:SetScript("OnUpdate", onUpdate);
					if (self.side == "RIGHT" and txDragRight) then
						txDragRight:SetTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight");
					elseif (self.side == "LEFT" and txDragLeft) then
						txDragLeft:SetTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight");
					end
				end;
				local onLeave = function(self, ...)
					self:SetScript("OnUpdate", nil);
					if (self.side == "RIGHT" and txDragRight) then
						txDragRight:SetTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up");
					elseif (self.side == "LEFT" and txDragLeft) then
						txDragLeft:SetTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up");
					end
				end;
				local onMouseDown = function(self, button, ...)
					if (button == "LeftButton") then
						resizingMailLog = true;
						self.resizingTimer = 0;
						self:GetParent():StartSizing(self.side);
						if (self.side == "RIGHT" and txDragRight) then
							txDragRight:SetTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down");
						elseif (self.side == "LEFT" and txDragLeft) then
							txDragLeft:SetTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down");
						end
					end
				end;
				local onMouseUp = function(self, button, ...)
					if (button == "LeftButton") then
						self:GetParent():StopMovingOrSizing();
						resizingMailLog = false;
						module:setOption("mailLogWidth", self:GetParent():GetWidth());
						if (self.side == "RIGHT" and txDragRight) then
							txDragRight:SetTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up");
						elseif (self.side == "LEFT" and txDragLeft) then
							txDragLeft:SetTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up");
						end
					end
				end;

				self:SetResizable(true)
				if self.SetResizeBounds then
					-- WoW 10.x
					self:SetResizeBounds(defaultLogWidth - 100, logHeight, UIParent:GetWidth(), logHeight)
				else
					self:SetMaxResize(UIParent:GetWidth(), logHeight)
					self:SetMinResize(defaultLogWidth - 100, logHeight)
				end

				local rightFrame = CreateFrame("Frame", "CT_MailMod_MailLog_RightResizeFrame", self);
				rightFrame.side = "RIGHT";
				rightFrame.resizingTimer = 0;
				rightFrame:SetPoint("TOPRIGHT", self, "TOPRIGHT", 0, 0);
				rightFrame:SetPoint("BOTTOMLEFT", self, "BOTTOMRIGHT", -5, 0);
				rightFrame:EnableMouse(true);
				rightFrame:SetScript("OnEnter", onEnter);
				rightFrame:SetScript("OnLeave", onLeave);
				rightFrame:SetScript("OnMouseDown", onMouseDown);
				rightFrame:SetScript("OnMouseUp", onMouseUp);

				local leftFrame = CreateFrame("Frame", "CT_MailMod_MailLog_LeftResizeFrame", self);
				leftFrame.side = "LEFT";
				leftFrame.resizingTimer = 0;
				leftFrame:SetPoint("TOPLEFT", self, "TOPLEFT", 0, 0);
				leftFrame:SetPoint("BOTTOMRIGHT", self, "BOTTOMLEFT", 5, 0);
				leftFrame:EnableMouse(true);
				leftFrame:SetScript("OnEnter", onEnter);
				leftFrame:SetScript("OnLeave", onLeave);
				leftFrame:SetScript("OnMouseDown", onMouseDown);
				leftFrame:SetScript("OnMouseUp", onMouseUp);

				local cornerFrameRight = CreateFrame("Frame", "CT_MailMod_MailLog_CornerResizeFrameRight", self);
				cornerFrameRight.side = "RIGHT";
				cornerFrameRight:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", 0, 0);
				cornerFrameRight:SetHeight(10);
				cornerFrameRight:SetWidth(36);
				cornerFrameRight:SetScale(0.72);
				cornerFrameRight:EnableMouse(true);
				cornerFrameRight:SetScript("OnEnter", onEnter);
				cornerFrameRight:SetScript("OnLeave", onLeave);
				cornerFrameRight:SetScript("OnMouseDown", onMouseDown);
				cornerFrameRight:SetScript("OnMouseUp", onMouseUp);
				cornerFrameRight:SetFrameLevel( CT_MailMod_MailLog_ScrollFrameScrollBarScrollDownButton:GetFrameLevel() + 1 );
				cornerFrameRight:Show();

				txDragRight = cornerFrameRight:CreateTexture();	--local txDrag is at start of onload function
				txDragRight:SetTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up");
				txDragRight:SetPoint("BOTTOMRIGHT", cornerFrameRight, "BOTTOMRIGHT", -3, 3);
				txDragRight:Show();

				local cornerFrameLeft = CreateFrame("Frame", "CT_MailMod_MailLog_CornerResizeFrameLeft", self);
				cornerFrameLeft.side = "LEFT";
				cornerFrameLeft:SetPoint("BOTTOMLEFT", self, "BOTTOMLEFT", 0, 0);
				cornerFrameLeft:SetHeight(10);
				cornerFrameLeft:SetWidth(36);
				cornerFrameLeft:SetScale(0.72);
				cornerFrameLeft:EnableMouse(true);
				cornerFrameLeft:SetScript("OnEnter", onEnter);
				cornerFrameLeft:SetScript("OnLeave", onLeave);
				cornerFrameLeft:SetScript("OnMouseDown", onMouseDown);
				cornerFrameLeft:SetScript("OnMouseUp", onMouseUp);
				cornerFrameLeft:SetFrameLevel( CT_MailMod_MailLog_ScrollFrameScrollBarScrollDownButton:GetFrameLevel() + 1 );
				cornerFrameLeft:Show();

				txDragLeft = cornerFrameLeft:CreateTexture();	--local txDrag is at start of onload function
				txDragLeft:SetTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up");
				SetClampedTextureRotation(txDragLeft, 90);
				txDragLeft:SetPoint("BOTTOMLEFT", cornerFrameLeft, "BOTTOMLEFT", 3, 3);
				txDragLeft:Show();



				local width = module:getOption("mailLogWidth");
				self:SetWidth(width or defaultLogWidth);
				resizeMailLog(self);
			end,

			["onmousedown"] = function(self, button)
				if ( button == "LeftButton" ) then
					module:moveMovable("MAILLOG");
				end
			end,

			["onmouseup"] = function(self, button)
				if ( button == "LeftButton" ) then
					module:stopMovable("MAILLOG");
				elseif ( button == "RightButton" ) then
					module:resetMovable("MAILLOG");
					self:ClearAllPoints();
					self:SetPoint("CENTER", UIParent);
				end
			end,

			["onenter"] = function(self)
				module:displayPredefinedTooltip(self, "DRAG");
			end,
		};
	end

	local updateMailEntry, mailLogFrame;

	do
		local createMoneyFrame;
		do
			local moneyTypeInfo = {
				UpdateFunc = function(self)
					return self.staticMoney;
				end,
				collapse = 1,
				truncateSmallCoins = 1,
			};

			createMoneyFrame = function(parent, id) -- Local
				local frameName = "CT_MailMod_MailLogMoneyFrame"..id;
				local frame = CreateFrame("Frame", frameName, parent, "SmallMoneyFrameTemplate");
				frame:SetPoint("LEFT", parent.subject, "RIGHT", 0, 0)

				_G[frameName.."GoldButton"]:EnableMouse(false);
				_G[frameName.."SilverButton"]:EnableMouse(false);
				_G[frameName.."CopperButton"]:EnableMouse(false);

				frame.moneyType = "STATIC";
				frame.hasPickup = 0;
				frame.info = moneyTypeInfo
				return frame;
			end
		end

		local createItemFrame;
		do
			local function itemOnEnter(self, ...)
				GameTooltip:SetOwner(self, "ANCHOR_CURSOR");
				GameTooltip:SetHyperlink(self.link);
				GameTooltip:AddLine(("Item Count: \124cffffffff%d\r"):format(self.count), 1, 0.82, 0);
				GameTooltip:Show();
			end

			local function itemOnLeave(self, ...)
				GameTooltip:Hide();
			end

			createItemFrame = function(parent, id) -- Local
				local button = CreateFrame("Button", nil, parent);
				button:SetWidth(16);
				button:SetHeight(16);
				if (id > 1) then
					button:SetPoint("LEFT", parent.items[id-1], "RIGHT", 2, 0)
				else
					button:SetPoint("LEFT", parent.subject, "RIGHT", 0, 0)
				end
				button:SetScript("OnEnter", itemOnEnter);
				button:SetScript("OnLeave", itemOnLeave);
				button.countFontString = button:CreateFontString(nil, "OVERLAY", "NumberFontNormalSmall");
				button.countFontString:SetPoint("BOTTOMRIGHT", 4, -1);
				return button;
			end
		end

		local function formatPlayer(name)
			if ( name == module:getPlayerName() ) then
				name = "\124cff888888" .. name .. "\124r";
			elseif ( module:nameIsPlayer(name) ) then
				name = ("\124cffffd100%s\124r"):format(module:filterName(name));
			else
				name = module:filterName(name);
			end
			return name;
		end

		updateMailEntry = function(frame, i, success, type, message, receiver, sender, subject, money, timestamp, expires, body, ...) -- Local
			local moneyFrame = frame.moneyFrame;
			local items = select('#', ...);

			frame.timestamp = timestamp;
			frame.expires = expires

			body = body or ""
			frame.tooltip1 = message or body
			frame.tooltip2 = message and body

			if ( success ) then
				-- Success

				receiver = formatPlayer(receiver)
				sender = formatPlayer(sender)
				frame.receiver:SetText(receiver)
				frame.sender:SetText(sender)
				frame.date:SetText(date("%y %m %d", timestamp))
				frame.subject:SetText(subject)
				frame.comment:SetText(body:gsub("\n", " "))
			else
				-- Failure
				money = 0;

				if (receiver) then
					receiver = formatPlayer(receiver)
					sender = formatPlayer(sender)

					frame.receiver:SetText(receiver)
					frame.sender:SetText(sender)
					frame.date:SetText(date("%y %m %d", timestamp))
					frame.subject:SetText(subject)
					frame.comment:SetText(body:gsub("\n", " "))
				else
					frame.receiver:SetText("")
					frame.sender:SetText("")
					frame.date:SetText(date("%y %m %d", timestamp))
					frame.subject:SetText("")
					frame.comment:SetText(message)
				end
			end

			-- Icon
--			frame.icon:SetTexture("Interface\\AddOns\\CT_MailMod\\Images\\mail_"..type);
			if (type == "returned") then
				frame.icontext:SetText(module.text["CT_MailMod/MailLog/Return"]);
			elseif (type == "deleted") then
				frame.icontext:SetText(module.text["CT_MailMod/MailLog/Delete"]);
			elseif (type == "outgoing") then
				frame.icontext:SetText(module.text["CT_MailMod/MailLog/Send"]);
			elseif (type == "incoming") then
				frame.icontext:SetText(module.text["CT_MailMod/MailLog/Open"]);
			else
				frame.icontext:SetText("");
			end

			-- Handling money
			if ( money > 0 ) then  -- Money taken or sent
				if ( not moneyFrame ) then
					moneyFrame = createMoneyFrame(frame, i);
					frame.moneyFrame = moneyFrame;
				end
				SetMoneyFrameColor(moneyFrame:GetName(), "white");
				moneyFrame:Show();
				MoneyFrame_Update(moneyFrame:GetName(), money);
			elseif ( money < 0 ) then  -- COD paid or requested
				if ( not moneyFrame ) then
					moneyFrame = createMoneyFrame(frame, i);
					frame.moneyFrame = moneyFrame;
				end
				SetMoneyFrameColor(moneyFrame:GetName(), "red");
				moneyFrame:Show();
				MoneyFrame_Update(moneyFrame:GetName(), -money);
			elseif ( moneyFrame ) then
				MoneyFrame_Update(moneyFrame:GetName(), 0);
				moneyFrame:Hide();
			end

			-- Handling items
			if (not frame.items) then
				frame.items = {};
			end
			for y = 1, module.MAX_ATTACHMENTS, 1 do
				local item = frame.items[y];
				if ( y <= items ) then
					if ( not item ) then
						item = createItemFrame(frame, y);
						frame.items[y] = item;
					end
					local link, count = (select(y, ...));
					link, count = link:match("^([^/]+)/(.+)$");
					if ( link and count ) then
						-- Safe icon retrieval for Retail via C_Item
						local itemIcon = "Interface\\Icons\\INV_Misc_QuestionMark";
						if C_Item and C_Item.GetItemIconByID then
							itemIcon = C_Item.GetItemIconByID(link) or itemIcon;
						else
							itemIcon = select(10, GetItemInfo(link)) or itemIcon;
						end
						item:SetNormalTexture(itemIcon);
						item.link = link;
						item.count = count;
						local num = tonumber(count);
						if (num and num > 1) then
							item.countFontString:SetText(num < 10 and num or "*");
						else
							item.countFontString:SetText("");
						end
						item:Show();
					else
						item:Hide();
					end
				elseif ( item ) then
					item:Hide();
				end
			end
					
			
			if (frame.moneyFrame and frame.moneyFrame:IsShown()) then
				if (frame.items[1] and frame.items[1]:IsShown()) then
					frame.items[1]:SetPoint("LEFT", frame.subject, "RIGHT", 55, 0)
					local i, x = 2, 78
					while (frame.items[i] and frame.items[i]:IsShown()) do
						x = x + 18
						i = i + 1
					end
					frame.comment:SetPoint("LEFT", frame.subject, "RIGHT", x, 0)
				else
					frame.comment:SetPoint("LEFT", frame.subject, "RIGHT", 55, 0)
				end
			elseif (frame.items[1] and frame.items[1]:IsShown()) then
				frame.items[1]:SetPoint("LEFT", frame.subject, "RIGHT", 0, 0)
				local i, x = 2, 23
				while (frame.items[i] and frame.items[i]:IsShown()) do
					x = x + 18
					i = i + 1
				end
				frame.comment:SetPoint("LEFT", frame.subject, "RIGHT", x, 0)
			else
				frame.comment:SetPoint("LEFT", frame.subject, "RIGHT", 0, 0)
			end
		end
	end

	resizeMailLog = function(logFrame)
		local tostring = tostring;
		local diff = logFrame:GetWidth() - defaultLogWidth;
		local subjectWidth = 200 + diff*0.6;
		local children = logFrame.scrollChildren;

		logFrame.contentsHeading:SetPoint("TOPLEFT", logFrame, "TOPLEFT", 520 + diff*0.6, -47)

		for i = 1, numRows do
			local frame = children[tostring(i)];
			frame.subject:SetWidth(subjectWidth);
		end
	end



	updateMailLog = function()
		-- STEP 1: Create a filtered list of which items to show (by default, show all).
		-- STEP 2: Update the scroll-bar for the filtered number of items
		-- STEP 3: Show the filtered items based on where the scroll-bar is now.
		-- STEP 1:
		local filteredLog = getFilteredTable(); -- returns a table if filtering is done, or false if it is still in progress.  (When there are more than 500 entries, it will only sift through 500 each frame to prevent fps dropping.)
		if (filteredLog) then

			-- STEP 2: Safe execution of the scroll update in Retail
			if FauxScrollFrame_Update then
				FauxScrollFrame_Update(CT_MailMod_MailLog_ScrollFrame, #filteredLog, numRows, 20);
			end
			local offset = FauxScrollFrame_GetOffset and FauxScrollFrame_GetOffset(CT_MailMod_MailLog_ScrollFrame) or 0;

			-- STEP 3:
			local children, frame = mailLogFrame.scrollChildren;
			for i = 1, numRows, 1 do
				frame = children[tostring(i)];
				if (filteredLog[#filteredLog+1-offset-i]) then  -- reversed, so that newer items are at the top
					updateMailEntry(frame, i, decodeLogEntry(filteredLog[#filteredLog+1-offset-i]));
					frame:Show();
				else
					frame:Hide();
				end
			end
		
		end
	end

	function module:updateMailLog()
		if (CT_MailMod_MailLog and CT_MailMod_MailLog:IsShown()) then
			updateMailLog();
		end
	end

	local function showMailLog()
		if ( not mailLogFrame ) then
			mailLogFrame = module:getFrame(mailLogFrameSkeleton);
		end
		module:scaleMailLog();
		module:updateMailLogColor();
		tinsert(UISpecialFrames, "CT_MailMod_MailLog");
		ShowUIPanel(CT_MailMod_MailLog);
		updateMailLog();
	end

	local function toggleMailLog()
		if ( not mailLogFrame ) then
			showMailLog();
		else
			if (mailLogFrame:IsShown()) then
				HideUIPanel(mailLogFrame);
			else
				showMailLog();
			end
		end
	end

	function module:scaleMailLog()
		if (mailLogFrame) then
			mailLogFrame:SetScale(module.opt.logWindowScale);
		end
	end

	function module:updateMailLogColor()
		if (mailLogFrame) then
			local c = module.opt.logColor;
			mailLogFrame:SetBackdropColor(c[1], c[2], c[3], c[4]);
		end
	end

	module:setSlashCmd(toggleMailLog, "/maillog");
	module.showMailLog = showMailLog;
	module.toggleMailLog = toggleMailLog;
end
