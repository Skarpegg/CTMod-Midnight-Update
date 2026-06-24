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
-- Alt Left Click to add item to Send Mail window

do
	local function CT_MailMod_AddToSendMail(self, button)
		if button == "LeftButton" and IsAltKeyDown() and MailFrame:IsShown() and module.opt.sendmailAltClickItem and not CursorHasItem() then
			if (not SendMailFrame:IsVisible()) then
				-- Switch to the send mail frame.
				if MailFrameTab_OnClick then MailFrameTab_OnClick(nil, 2) end
			end
			-- Pickup and add an item to the send mail window (modernized for C_Container)
			local bag, item = self:GetParent():GetID(), self:GetID()
			if C_Container and C_Container.PickupContainerItem then
				C_Container.PickupContainerItem(bag, item)
			elseif PickupContainerItem then
				PickupContainerItem(bag, item)
			end
			if ClickSendMailItemButton then ClickSendMailItemButton() end
			return true
		end
		return false
	end

	-- Modern Retail registration via Mixin to prevent UI crashes
	if ContainerFrameItemButtonMixin and hooksecurefunc then
		hooksecurefunc(ContainerFrameItemButtonMixin, "OnModifiedClick", CT_MailMod_AddToSendMail)
	elseif CT_Core then
		CT_Core.ContainerFrameItemButton_OnModifiedClick_Register(CT_MailMod_AddToSendMail)
	else
		local maxContainers = NUM_CONTAINER_FRAMES or 5;
		for i=1, maxContainers do
			for j=1, 36 do
				local button = _G["ContainerFrame" .. i .. "Item" .. j]
				if button then
					button:HookScript("OnClick", CT_MailMod_AddToSendMail)
				end
			end
		end
	end
	
end

--------------------------------------------
-- Fill in subject with money amount being entered.
do
	local amount3 = module.text["CT_MailMod/SEND_MAIL_MONEY_SUBJECT_GOLD"];
	local amount2 = module.text["CT_MailMod/SEND_MAIL_MONEY_SUBJECT_SILVER"];
	local amount1 = module.text["CT_MailMod/SEND_MAIL_MONEY_SUBJECT_COPPER"];
	local find3 = "^" .. amount3:gsub("%%d", "%%d+") .. "$";
	local find2 = "^" .. amount2:gsub("%%d", "%%d+") .. "$";
	local find1 = "^" .. amount1:gsub("%%d", "%%d+") .. "$";

	hooksecurefunc(SendMailMoney, "onValueChangedFunc", function ()
		if (not module.opt.sendmailMoneySubject) then
			return;
		end
		local gold, silver, copper;
		local subject = SendMailSubjectEditBox:GetText();
		if (subject == "" or subject:find(find3) or subject:find(find2) or subject:find(find1)) then
			copper = MoneyInputFrame_GetCopper(SendMailMoney);
			if (copper == 0) then
				SendMailSubjectEditBox:SetText("");
			else
				SendMailSubjectEditBox:SetText(module:convertMoneyToString(copper));
			end
		end
	end);
end

--------------------------------------------
-- Configure the auto-complete settings for the send to name edit box.

local setAutoComplete;
local function configureSendToNameAutoComplete()
	if (module:getOption("sendmailAutoCompleteUse")) then
		setAutoComplete = true;
		local include = AUTOCOMPLETE_FLAG_NONE or 0;
		local exclude = AUTOCOMPLETE_FLAG_BNET or 0;
		if (module:getOption("sendmailAutoCompleteFriends")) then
			include = bit.bor(include, AUTOCOMPLETE_FLAG_FRIEND or 0);
		end
		if (module:getOption("sendmailAutoCompleteGuild")) then
			include = bit.bor(include, AUTOCOMPLETE_FLAG_IN_GUILD or 0);
		end
		if (module:getOption("sendmailAutoCompleteInteracted")) then
			include = bit.bor(include, AUTOCOMPLETE_FLAG_INTERACTED_WITH or 0);
		end
		if (module:getOption("sendmailAutoCompleteGroup")) then
			include = bit.bor(include, AUTOCOMPLETE_FLAG_IN_GROUP or 0);
		end
		if (module:getOption("sendmailAutoCompleteOnline")) then
			include = bit.bor(include, AUTOCOMPLETE_FLAG_ONLINE or 0);
		end
		if (module:getOption("sendmailAutoCompleteAccount")) then
			include = bit.bor(include, AUTO_COMPLETE_ACCOUNT_CHARACTER or 0);
		end
		-- SAFEGUARD FOR RETAIL
		if AutoCompleteEditBox_SetAutoCompleteSource then
			AutoCompleteEditBox_SetAutoCompleteSource(SendMailNameEditBox, GetAutoCompleteResults, include, exclude);
		end
	else
		if (setAutoComplete) then
			-- SAFEGUARD FOR RETAIL
			if AutoCompleteEditBox_SetAutoCompleteSource and AUTOCOMPLETE_LIST and AUTOCOMPLETE_LIST.MAIL then
				AutoCompleteEditBox_SetAutoCompleteSource(SendMailNameEditBox, GetAutoCompleteResults, AUTOCOMPLETE_LIST.MAIL.include, AUTOCOMPLETE_LIST.MAIL.exclude);
			end
			setAutoComplete = nil;
		end
	end
	if CT_MailMod_UpdateFilterDropDown then CT_MailMod_UpdateFilterDropDown(); end
end
module.configureSendToNameAutoComplete = configureSendToNameAutoComplete;

