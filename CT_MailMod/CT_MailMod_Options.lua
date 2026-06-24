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

local _G = getfenv(0)
local module = select(2, ...)

local L = module.text;

--------------------------------------------

local defaultLogColor = { 0, 0, 0, 0.75 };

--------------------------------------------
-- Options Window

local optionsFrameList;
local function optionsInit()
	optionsFrameList = module:framesInit();
end
local function optionsGetData()
	return module:framesGetData(optionsFrameList);
end
local function optionsAddFrame(offset, size, details, data)
	module:framesAddFrame(optionsFrameList, offset, size, details, data);
end
local function optionsAddObject(offset, size, details)
	module:framesAddObject(optionsFrameList, offset, size, details);
end
local function optionsAddScript(name, func)
	module:framesAddScript(optionsFrameList, name, func);
end
local function optionsBeginFrame(offset, size, details, data)
	module:framesBeginFrame(optionsFrameList, offset, size, details, data);
end
local function optionsEndFrame()
	module:framesEndFrame(optionsFrameList);
end

local function optionsAddTooltip(text, anchor, offx, offy, owner)
	module:framesAddScript(optionsFrameList, "onenter", function(obj) module:displayTooltip(obj, text, anchor, offx, offy, owner); end);
end

local optionsFrame;

module.frame = function()
	local textColor1 = "0.9:0.9:0.9";
	local textColor2 = "0.7:0.7:0.7";
	local textColor3 = "0.9:0.72:0.0";

	optionsInit();

	optionsBeginFrame(-5, 0, "frame#tl:0:%y#r");
		-- Tips
		optionsAddObject(  0,   17, "font#tl:5:%y#v:GameFontNormalLarge#" .. L["CT_MailMod/Options/Tips/Heading"]);
		optionsAddObject( -2, 2*14, "font#t:0:%y#l:13:0#r#" .. L["CT_MailMod/Options/Tips/Line1"] .. "#" .. textColor2 .. ":l");

		-- General Options
		optionsAddObject(-20,   17, "font#tl:5:%y#v:GameFontNormalLarge#" .. L["CT_MailMod/Options/General/Heading"]);
		optionsAddObject( -5,   26, "checkbutton#tl:10:%y#o:blockTrades#" .. L["CT_MailMod/Options/General/BlockTradesCheckButton"] .. "#l:268");
		optionsAddObject(  6,   26, "checkbutton#tl:10:%y#o:showMoneyChange#" .. L["CT_MailMod/Options/General/NetIncomeCheckButton"] .. "#l:268");

		optionsAddObject(-20,   17, "font#tl:5:%y#v:GameFontNormalLarge#" .. L["CT_MailMod/Options/Bags/Heading"]);
		optionsAddObject( -8, 4*13, "font#t:0:%y#l:13:0#r#" .. L["CT_MailMod/Options/Bags/Line1"] .. "#" .. textColor2 .. ":l");

		optionsAddObject( -6,   15, "font#tl:15:%y#v:ChatFontNormal#" .. L["CT_MailMod/Options/Bags/OpenLabel"]);
		optionsAddObject( -3,   26, "checkbutton#tl:35:%y#o:openAllBags#i:openAllBags#" .. L["CT_MailMod/Options/Bags/OpenAllCheckButton"] .. "#l:233");
		optionsAddObject(  6,   26, "checkbutton#tl:35:%y#o:openBackpack#i:openBackpack#" .. L["CT_MailMod/Options/Bags/OpenBackpackCheckButton"] .. "#l:233");
		optionsAddObject(  6,   26, "checkbutton#tl:35:%y#o:openNoBags#i:openNoBags#" .. L["CT_MailMod/Options/Bags/CloseAllCheckButton"] .. "#l:233");

		optionsAddObject( -6,   15, "font#tl:15:%y#v:ChatFontNormal#" .. L["CT_MailMod/Options/Bags/CloseLabel"]);
		optionsAddObject( -3,   26, "checkbutton#tl:35:%y#o:closeAllBags#" .. L["CT_MailMod/Options/Bags/CloseAllCheckButton"] .. "#l:233");

		-- Inbox Options
		optionsAddObject(-20,   17, "font#tl:5:%y#v:GameFontNormalLarge#" .. L["CT_MailMod/Options/Inbox/Heading"]);
		optionsAddObject(  6,   26, "checkbutton#tl:10:%y#o:inboxShowLong:true#" .. L["CT_MailMod/Options/Inbox/ShowLongCheckButton"] .. "#l:268");
		optionsAddObject(  6,   26, "checkbutton#tl:10:%y#o:inboxShowExpiry:true#" .. L["CT_MailMod/Options/Inbox/ShowExpiryCheckButton"] .. "#l:268");
		optionsAddObject(  6,   26, "checkbutton#tl:10:%y#o:inboxShowInbox:true#" .. L["CT_MailMod/Options/Inbox/ShowInboxCheckButton"] .. "#l:268");
		optionsAddObject(  6,   26, "checkbutton#tl:10:%y#o:inboxShowMailbox:true#" .. L["CT_MailMod/Options/Inbox/ShowMailboxCheckButton"] .. "#l:268");
		optionsAddObject(  6,   26, "checkbutton#tl:10:%y#o:toolMultipleItems:true#" .. L["CT_MailMod/Options/Inbox/MultipleItemsCheckButton"] .. "#l:268");
		optionsBeginFrame( 6,   26, "checkbutton#tl:10:%y#o:hideLogButton#" .. L["CT_MailMod/Options/Inbox/HideLogCheckButton"] .. "#l:268");
			optionsAddTooltip({"This only hides the button; options further below control logging","While hidden, right-click on the 'globe' or type /maillog#" .. textColor1}, "ANCHOR_BOTTOMRIGHT", 15, -25);
		optionsEndFrame();

		-- Inbox Checkboxes
		optionsAddObject(-10,   17, "font#tl:13:%y#v:GameFontNormal#" .. L["CT_MailMod/Options/Inbox/Checkboxes/Heading"] .. "#" .. textColor3 .. ":l");
		optionsBeginFrame(  17,   17, "button#tl:250:%y#s:40:%s#v:UIPanelButtonTemplate#?");
			optionsAddTooltip({L["CT_MailMod/Options/Inbox/Checkboxes/Heading"],L["CT_MailMod/SELECT_MESSAGE_TIP2"]}, "ANCHOR_RIGHT", 35, 0);
		optionsEndFrame();
		optionsAddObject(  0, 2*13, "font#t:0:%y#l:13:0#r#" .. L["CT_MailMod/Options/Inbox/Checkboxes/Line1"] .. "#" .. textColor2 .. ":l");
		optionsAddObject(  0,   26, "checkbutton#tl:10:%y#o:showCheckboxes:true#" .. L["CT_MailMod/Options/Inbox/Checkboxes/ShowCheckboxesCheckButton"] .. "#l:268");
		optionsBeginFrame( 0, 0, "frame#tl:0:%y#br:tr:0:%b");
			optionsAddObject(  6,   26, "checkbutton#tl:20:%y#o:toolSelectMsg:true#" .. L["CT_MailMod/Options/Inbox/SelectMsgCheckButton"] .. "#l:258");
			optionsAddObject(  6,   26, "checkbutton#tl:20:%y#o:inboxShowNumbers:true#" .. L["CT_MailMod/Options/Inbox/Checkboxes/ShowNumbersCheckButton"] .. "#l:258");
			optionsBeginFrame( 6,   26, "checkbutton#tl:20:%y#o:inboxSenderNew:true#" .. L["CT_MailMod/Options/Inbox/Checkboxes/SenderNewCheckButton"] .. "#l:258")
				optionsAddTooltip({L["CT_MailMod/Options/Inbox/Checkboxes/SenderNewCheckButton"],L["CT_MailMod/Options/Inbox/Checkboxes/SenderNewTip"] .. "#" .. textColor1}, "ANCHOR_RIGHT", 35, 0);
			optionsEndFrame();
			optionsBeginFrame( 6,   26, "checkbutton#tl:20:%y#o:inboxRangeNew:true#" .. L["CT_MailMod/Options/Inbox/Checkboxes/RangeNewCheckButton"] .. "#l:258")
				optionsAddTooltip({L["CT_MailMod/Options/Inbox/Checkboxes/RangeNewCheckButton"],L["CT_MailMod/Options/Inbox/Checkboxes/RangeNewTip"] .. "#" .. textColor1}, "ANCHOR_RIGHT", 35, 0);
			optionsEndFrame();
			optionsAddScript( "onupdate",
				function (frame)
					frame:SetAlpha((module.opt.showCheckboxes and 1) or 0.5);
				end
			);
		optionsEndFrame();
		
		-- Send Mail Options
		optionsAddObject(-20,   17, "font#tl:5:%y#v:GameFontNormalLarge#" .. L["CT_MailMod/Options/SendMail/Heading"]);
		optionsAddObject( -5,   26, "checkbutton#tl:10:%y#o:sendmailAltClickItem#" .. L["CT_MailMod/Options/SendMail/AltClickCheckButton"] .. "#l:268");
		optionsAddObject(  6,   26, "checkbutton#tl:10:%y#o:sendmailMoneySubject:true#" .. L["CT_MailMod/Options/SendMail/ReplaceSubjectCheckButton"] .. "#l:268");
		optionsBeginFrame(6,   26, "checkbutton#tl:10:%y#o:sendmailAutoCompleteUse#" .. L["CT_MailMod/Options/SendMail/FilterAutoCompleteCheckButton"] .. "#l:268");
			optionsAddTooltip({
				L["CT_MailMod/Options/SendMail/FilterAutoCompleteCheckButton"],
				L["CT_MailMod/Options/SendMail/FilterAutoCompleteTip"] .. "#" .. textColor1,
				" - " .. L["CT_MailMod/AutoCompleteFilter/Account"] .. "#" .. textColor2,
				" - " .. L["CT_MailMod/AutoCompleteFilter/Friends"] .. "#" .. textColor2,
				" - " .. L["CT_MailMod/AutoCompleteFilter/Group"] .. "#" .. textColor2,
				" - " .. L["CT_MailMod/AutoCompleteFilter/Guild"] .. "#" .. textColor2,
				" - " .. L["CT_MailMod/AutoCompleteFilter/Online"] .. "#" .. textColor2,
				" - " .. L["CT_MailMod/AutoCompleteFilter/Recent"] .. "#" .. textColor2,				
			}, "CT_ABOVEBELOW", 0, 0, CTCONTROLPANEL);
		optionsEndFrame();
		if (module:getGameVersion() >= 8) then
			optionsBeginFrame(6, 26, "checkbutton#tl:10:%y#o:sendmailProtectFocus:true#" .. L["CT_MailMod/Options/SendMail/ProtectEditFocusCheckButton"] .. "#l:268");
				optionsAddTooltip({
					L["CT_MailMod/Options/SendMail/ProtectEditFocusCheckButton"],
					L["CT_MailMod/Options/SendMail/ProtectEditFocusTip"] .. "#" .. textColor2,
				}, "CT_ABOVEBELOW", 0, 0, CTCONTROLPANEL);
			optionsEndFrame();
		end

		-- Mail Log Options
		optionsAddObject(-20,   17, "font#tl:5:%y#v:GameFontNormalLarge#" .. L["CT_MailMod/Options/MailLog/Heading"]);
		optionsBeginFrame(  17,   17, "button#tl:250:%y#s:40:%s#v:UIPanelButtonTemplate#?");
			optionsAddTooltip({L["CT_MailMod/Options/MailLog/Heading"],L["CT_MailMod/Options/MailLog/Tip"] .. "#" .. textColor2}, "ANCHOR_RIGHT", 35, 0);
		optionsEndFrame();
		optionsAddObject( -5,   26, "checkbutton#tl:10:%y#o:printLog#" .. L["CT_MailMod/Options/MailLog/PrintCheckButton"] .. "#l:268");
		optionsAddObject(  6,   26, "checkbutton#tl:10:%y#o:saveLog:true#" .. L["CT_MailMod/Options/MailLog/SaveCheckButton"] .. "#l:268");
		optionsAddObject( -5,   26, "checkbutton#tl:10:%y#o:logOpenedMail:true#" .. L["CT_MailMod/Options/MailLog/LogOpennedCheckButton"] .. "#l:268");
		optionsAddObject(  6,   26, "checkbutton#tl:10:%y#o:logReturnedMail:true#" .. L["CT_MailMod/Options/MailLog/LogReturnedCheckButton"] .. "#l:268");
		optionsAddObject(  6,   26, "checkbutton#tl:10:%y#o:logDeletedMail:true#" .. L["CT_MailMod/Options/MailLog/LogDeletedButton"] .. "#l:268");
		optionsAddObject(  6,   26, "checkbutton#tl:10:%y#o:logSentMail:true#" .. L["CT_MailMod/Options/MailLog/LogSentCheckButton"] .. "#l:268");

		optionsAddObject(-10,   16, "colorswatch#tl:15:%y#s:16:16#o:logColor:" .. defaultLogColor[1] .. "," .. defaultLogColor[2] .. "," .. defaultLogColor[3] .. "," .. defaultLogColor[4] .. "#true");
		optionsAddObject( 14,   15, "font#tl:40:%y#v:ChatFontNormal#" .. L["CT_MailMod/Options/MailLog/BackgroundLabel"]);

		optionsAddObject(-25,   17, "slider#t:0:%y#o:logWindowScale:1#s:175:%s#" .. L["CT_MailMod/Options/MailLog/ScaleSliderLabel"] .. "#0.20:2:0.01");

		optionsAddObject(-20, 1*13, "font#t:0:%y#l:13:0#r#" .. L["CT_MailMod/Options/MailLog/Delete/Heading"] .. "#" .. textColor3 .. ":l");
		optionsBeginFrame(  -5,   30, "button#t:0:%y#s:120:%s#v:UIPanelButtonTemplate#i:deleteLogButton#" .. L["CT_MailMod/Options/MailLog/Delete/Button"]);
			optionsAddScript("onclick",
				function()
					module:resetHistory(CT_MailModOptions.mailLog, module.updateMailLog)
				end
			);
		optionsEndFrame();
		
		-- Reset Options
		optionsBeginFrame(-20	, 0, "frame#tl:0:%y#br:tr:0:%b");
			optionsAddObject(  0,   17, "font#tl:5:%y#v:GameFontNormalLarge#" .. L["CT_MailMod/Options/Reset/Heading"]);
			optionsAddObject( -5,   26, "checkbutton#tl:10:%y#o:resetAll#" .. L["CT_MailMod/Options/Reset/ResetAllCheckbox"] .. "#l:268");
			optionsBeginFrame(  -5,   30, "button#t:0:%y#s:120:%s#v:UIPanelButtonTemplate#" .. L["CT_MailMod/Options/Reset/ResetButton"]);
				optionsAddScript("onclick", function(self)
					if (module:getOption("resetAll")) then
						local copyOfMailLog = {CT_MailModOptions["mailLog"]}
						CT_MailModOptions = {};
						CT_MailModOptions["mailLog"] = copyOfMailLog[1];
					else
						if (not CT_MailModOptions or not type(CT_MailModOptions) == "table") then
							CT_MailModOptions = {};
						else
							CT_MailModOptions[module:getCharKey()] = nil;
						end
					end
					ConsoleExec("RELOADUI");
				end);
			optionsEndFrame();
			optionsAddObject( -7, 2*15, "font#t:0:%y#l#r#" .. L["CT_MailMod/Options/Reset/Line 1"] .. "#" .. textColor2);
		optionsEndFrame();

		optionsAddScript("onload",
			function (self)
				optionsFrame = self;
			end
		);
	optionsEndFrame();

	return "frame#all", optionsGetData();
end

local function getoption(name, default)
	local value;
	value = module:getOption(name);
	if (value == nil) then
		return default;
	else
		return value;
	end
end

module.opt = {};

function module:init()
	
	local opt = module.opt;	
	
	-- Temporary
	local charLog = module:getOption("mailLog")
	if (CT_MailModOptions) then
		CT_MailModOptions.mailLog = CT_MailModOptions.mailLog or {}	
		if (charLog) then
			for __, v in ipairs(charLog) do
				tinsert(CT_MailModOptions.mailLog, v)
			end
			module:setOption("mailLog", nil)
		end
	end

	-- General
	opt.openBackpack = getoption("openBackpack", false);
	opt.openAllBags = getoption("openAllBags", false);
	opt.closeAllBags = getoption("closeAllBags", false);
	opt.blockTrades = getoption("blockTrades", false);
	opt.showMoneyChange = getoption("showMoneyChange", false);

	-- Inbox
	opt.inboxShowNumbers = getoption("inboxShowNumbers", true);
	opt.inboxShowLong = getoption("inboxShowLong", true);
	opt.inboxShowExpiry = getoption("inboxShowExpiry", true);
	opt.inboxShowInbox = getoption("inboxShowInbox", true);
	opt.inboxShowMailbox = getoption("inboxShowMailbox", true);
	opt.toolMultipleItems = getoption("toolMultipleItems", true);
	opt.toolSelectMsg = getoption("toolSelectMsg", true);

	-- Message selection
	opt.inboxSenderNew = getoption("inboxSenderNew", true);
	opt.inboxRangeNew = getoption("inboxRangeNew", true);

	-- Mail Log
	opt.printLog = getoption("printLog", false);
	opt.saveLog = getoption("saveLog", true);
	opt.logOpenedMail = getoption("logOpenedMail", true);
	opt.logReturnedMail = getoption("logReturnedMail", true);
	opt.logDeletedMail = getoption("logDeletedMail", true);
	opt.logSentMail = getoption("logSentMail", true);
	opt.logWindowScale = getoption("logWindowScale", 1);
	opt.logColor = getoption("logColor", defaultLogColor);
	opt.hideLogButton = getoption("hideLogButton", false);
	module:updateMailLogButton();
	opt.showCheckboxes = getoption("showCheckboxes", true);
	module:updateOpenCloseButtons();
	module:updateSelectAllCheckbox();

	-- Send Mail
	opt.sendmailAltClickItem = getoption("sendmailAltClickItem", true);
	opt.sendmailMoneySubject = getoption("sendmailMoneySubject", true);
	-- Safeguard for Retail: only run if the function actually exists and is loaded
	if module.configureSendToNameAutoComplete then
		module.configureSendToNameAutoComplete();
	end
	local temp = getoption("sendmailAutoCompleteUse", 5);  -- 5 is a non-sensical value, demonstrating the var was never set
	if (temp == 5) then
		module:setOption("sendmailAutoCompleteUse", true, CT_SKIP_UPDATE_FUNC);
		module:setOption("sendmailAutoCompleteFriends", true, CT_SKIP_UPDATE_FUNC);
		module:setOption("sendmailAutoCompleteGuild", true, CT_SKIP_UPDATE_FUNC);
		module:setOption("sendmailAutoCompleteInteracted", true, CT_SKIP_UPDATE_FUNC);
		module:setOption("sendmailAutoCompleteGroup", true, CT_SKIP_UPDATE_FUNC);
		module:setOption("sendmailAutoCompleteOnline", true, CT_SKIP_UPDATE_FUNC);
		module:setOption("sendmailAutoCompleteAccount", true, CT_SKIP_UPDATE_FUNC);
	end
	if (module:getGameVersion() >= 8) then
		module.protectFocus(module:getOption("sendmailProtectFocus") ~= false);
	end

end

function module:update(optName, value)
	local opt = module.opt;
	opt[optName] = value;

	if (
		optName == "inboxShowNumbers" or
		optName == "inboxShowLong" or
		optName == "inboxShowExpiry" or
		optName == "inboxShowInbox" or
		optName == "inboxShowMailbox"
	) then
		module:raiseCustomEvent("INCOMING_UPDATE");

	elseif (optName == "logWindowScale") then
		module:scaleMailLog();

	elseif (optName == "logColor") then
		module:updateMailLogColor();

	elseif (optName == "hideLogButton") then
		module:updateMailLogButton();

	elseif (optName == "showCheckboxes") then
		module:updateOpenCloseButtons();  -- hide the open/close buttons
		module:updateSelectAllCheckbox(); -- hide the select all checkbox
		module:inboxUpdateSelection();    -- hide any currently open checkboxes

	elseif (optName == "blockTrades") then
		module.configureBlockTradesMail(value);

	elseif (
		optName == "sendmailAutoCompleteUse" or
		optName == "sendmailAutoCompleteFriends" or
		optName == "sendmailAutoCompleteGuild" or
		optName == "sendmailAutoCompleteInteracted" or
		optName == "sendmailAutoCompleteGroup" or
		optName == "sendmailAutoCompleteOnline" or
		optName == "sendmailAutoCompleteAccount"
	) then
		module.configureSendToNameAutoComplete();

	elseif (optName == "sendmailProtectFocus") then
		module.protectFocus(value)

	elseif (optName == "openAllBags") then
		if (value) then
			local value = false;
			opt.openBackpack = value;
			opt.openNoBags = value;
			module:setOption("openBackpack", value, CT_SKIP_UPDATE_FUNC);
			module:setOption("openNoBags", value, CT_SKIP_UPDATE_FUNC);
			if (optionsFrame) then
				optionsFrame.openBackpack:SetChecked(value);
				optionsFrame.openNoBags:SetChecked(value);
			end
		end

	elseif (optName == "openBackpack") then
		if (value) then
			local value = false;
			opt.openAllBags = value;
			opt.openNoBags = value;
			module:setOption("openAllBags", value, CT_SKIP_UPDATE_FUNC);
			module:setOption("openNoBags", value, CT_SKIP_UPDATE_FUNC);
			if (optionsFrame) then
				optionsFrame.openAllBags:SetChecked(value);
				optionsFrame.openNoBags:SetChecked(value);
			end
		end

	elseif (optName == "openNoBags") then
		if (value) then
			local value = false;
			opt.openAllBags = value;
			opt.openBackpack = value;
			module:setOption("openAllBags", value, CT_SKIP_UPDATE_FUNC);
			module:setOption("openBackpack", value, CT_SKIP_UPDATE_FUNC);
			if (optionsFrame) then
				optionsFrame.openAllBags:SetChecked(value);
				optionsFrame.openBackpack:SetChecked(value);
			end
		end

	end
end

function module:externalDropDown_Initialize(level, addButtonFunc)		-- addButtonFunc allows integration with LibUIDropDownMenu used by Titan Panel
	-- Safeguard in case the global dropdown functions are unavailable (e.g. removed in a future patch)
	if not addButtonFunc and not UIDropDownMenu_AddButton then return end
	
	addButtonFunc = addButtonFunc or UIDropDownMenu_AddButton
	level = level or UIDROPDOWNMENU_MENU_LEVEL or 1
	local info = { };
	info.text = "CT_MailMod";
	info.isTitle = 1;
	info.justifyH = "CENTER";
	info.notCheckable = 1;
	addButtonFunc(info, level);

	wipe(info);
	info.text = "Open options";
	info.notCheckable = 1;
	info.func = function()
		module:showModuleOptions();
	end
	addButtonFunc(info, level);
	
	wipe(info);
	info.text = "Open mail log";
	info.notCheckable = 1;
	info.func = module.showMailLog;
	addButtonFunc(info, level);
end