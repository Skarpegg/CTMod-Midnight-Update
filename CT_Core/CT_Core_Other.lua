------------------------------------------------
--                  CT_Core                   --
--                                            --
-- Core addon for doing basic and popular     --
-- things in an intuitive way.                --
-- Please do not modify or otherwise          --
-- redistribute this without the consent of   --
-- the CTMod Team. Thank you.                 --
------------------------------------------------

local _G = getfenv(0);
local module = _G.CT_Core;
local NUM_CHAT_WINDOWS = NUM_CHAT_WINDOWS;
local WatchFrame = ObjectiveTrackerFrame or QuestWatchFrame or WatchFrame;  -- QuestWatchFrame in WoW Classic


--------------------------------------------
-- Quest Levels

local displayLevels = false;

local questLogPrefixes = {
	[GROUP] = "+",
	[RAID] = "R",
	[RAID .. " (25)"] = "R",
	[RAID .. " (10)"] = "R",
	[PVP] = "P",
	[LFG_TYPE_DUNGEON] = "D",
};

local function toggleDisplayLevels(enable)
	-- defaults to true only prior to Legion, when level scaling was first introduced
	displayLevels = enable or module:getGameVersion() < 7 and enable == nil
end

if (module:getGameVersion() == 1) then

	QuestLog_Update = function(self)
		local numEntries, numQuests = GetNumQuestLogEntries();
		if ( numEntries == 0 ) then
			EmptyQuestLogFrame:Show();
			QuestLogFrameAbandonButton:Disable();
			QuestLogFrame.hasTimer = nil;
			QuestLogDetailScrollFrame:Hide();
			QuestLogExpandButtonFrame:Hide();
		else
			EmptyQuestLogFrame:Hide();
			QuestLogFrameAbandonButton:Enable();
			QuestLogDetailScrollFrame:Show();
			QuestLogExpandButtonFrame:Show();
		end

		-- Update Quest Count
		QuestLogQuestCount:SetText(format(QUEST_LOG_COUNT_TEMPLATE, numQuests, MAX_QUESTLOG_QUESTS));
		QuestLogCountMiddle:SetWidth(QuestLogQuestCount:GetWidth());

		-- ScrollFrame update
		FauxScrollFrame_Update(QuestLogListScrollFrame, numEntries, QUESTS_DISPLAYED, QUESTLOG_QUEST_HEIGHT, nil, nil, nil, QuestLogHighlightFrame, 293, 316 )

		-- Update the quest listing
		QuestLogHighlightFrame:Hide();

		local questIndex, questLogTitle, questTitleTag, questNumGroupMates, questNormalText, questHighlight, questCheck;
		local questLogTitleText, level, questTag, isHeader, isCollapsed, isComplete, color;
		local numPartyMembers, partyMembersOnQuest, tempWidth, textWidth;
		for i=1, QUESTS_DISPLAYED, 1 do
			questIndex = i + FauxScrollFrame_GetOffset(QuestLogListScrollFrame);
			questLogTitle = _G["QuestLogTitle"..i];
			questTitleTag = _G["QuestLogTitle"..i.."Tag"];
			questNumGroupMates = _G["QuestLogTitle"..i.."GroupMates"];
			questCheck = _G["QuestLogTitle"..i.."Check"];
			questNormalText = _G["QuestLogTitle"..i.."NormalText"];
			questHighlight = _G["QuestLogTitle"..i.."Highlight"];
			if ( questIndex <= numEntries ) then
-- CT_CORE CLASSIC ERA QUEST LOG MODIFICATION STARTS HERE
				questLogTitleText, level, questTag, isHeader, isCollapsed, isComplete, frequency, questID, startEvent, displayQuestID, isOnMap, hasLocalPOI, isTask, isBounty, isStory, isHidden, isScaling = GetQuestLogTitle(questIndex);
				if (displayLevels and questLogTitleText and level and level > 0) then
					if (questTag) then
						questLogTitleText = "[" .. level .. "+] " .. questLogTitleText;
					else
						questLogTitleText = "[" .. level .. "] " .. questLogTitleText;
					end
				end
-- CT_CORE CLASSIC ERA QUEST LOG MODIFICATION ENDS HERE
				if ( isHeader ) then
					if ( questLogTitleText ) then
						questLogTitle:SetText(questLogTitleText);
					else
						questLogTitle:SetText("");
					end

					if ( isCollapsed ) then
						questLogTitle:SetNormalTexture("Interface\\Buttons\\UI-PlusButton-Up");
					else
						questLogTitle:SetNormalTexture("Interface\\Buttons\\UI-MinusButton-Up"); 
					end
					questHighlight:SetTexture("Interface\\Buttons\\UI-PlusButton-Hilight");
					questNumGroupMates:SetText("");
					questCheck:Hide();
				else
					questLogTitle:SetText("  "..questLogTitleText);
					--Set Dummy text to get text width *SUPER HACK*
					QuestLogDummyText:SetText("  "..questLogTitleText);

					questLogTitle:ClearNormalTexture();
					questHighlight:SetTexture("");

					-- If not a header see if any nearby group mates are on this quest
					partyMembersOnQuest = 0;
					for j=1, GetNumSubgroupMembers() do
						if ( IsUnitOnQuest(questIndex, "party"..j) ) then
							partyMembersOnQuest = partyMembersOnQuest + 1;
						end
					end
					if ( partyMembersOnQuest > 0 ) then
						questNumGroupMates:SetText("["..partyMembersOnQuest.."]");
					else
						questNumGroupMates:SetText("");
					end
				end
				-- Save if its a header or not
				questLogTitle.isHeader = isHeader;

				-- Set the quest tag
				if ( isComplete and isComplete < 0 ) then
					questTag = FAILED;
				elseif ( isComplete and isComplete > 0 ) then
					questTag = COMPLETE;
				end
				if ( questTag ) then
					questTitleTag:SetText("("..questTag..")");
					-- Shrink text to accomdate quest tags without wrapping
					tempWidth = 275 - 15 - questTitleTag:GetWidth();

					if ( QuestLogDummyText:GetWidth() > tempWidth ) then
						textWidth = tempWidth;
					else
						textWidth = QuestLogDummyText:GetWidth();
					end

					questNormalText:SetWidth(tempWidth);

					-- If there's quest tag position check accordingly
					questCheck:Hide();
					if ( IsQuestWatched(questIndex) ) then
						if ( questNormalText:GetWidth() + 24 < 275 ) then
							questCheck:SetPoint("LEFT", questLogTitle, "LEFT", textWidth+24, 0);
						else
							questCheck:SetPoint("LEFT", questLogTitle, "LEFT", textWidth+10, 0);
						end
						questCheck:Show();
					end
				else
					questTitleTag:SetText("");
					-- Reset to max text width
					if ( questNormalText:GetWidth() > 275 ) then
						questNormalText:SetWidth(260);
					end

					-- Show check if quest is being watched
					questCheck:Hide();
					if ( IsQuestWatched(questIndex) ) then
						if ( questNormalText:GetWidth() + 24 < 275 ) then
							questCheck:SetPoint("LEFT", questLogTitle, "LEFT", QuestLogDummyText:GetWidth()+24, 0);
						else
							questCheck:SetPoint("LEFT", questNormalText, "LEFT", questNormalText:GetWidth(), 0);
						end
						questCheck:Show();
					end
				end

				-- Color the quest title and highlight according to the difficulty level
				local playerLevel = UnitLevel("player");
				if ( isHeader ) then
					color = QuestDifficultyColors["header"];
				else
					color = GetQuestDifficultyColor(level);
				end
				questLogTitle:SetNormalFontObject(color.font);
				questTitleTag:SetTextColor(color.r, color.g, color.b);
				questNumGroupMates:SetTextColor(color.r, color.g, color.b);
				questLogTitle.r = color.r;
				questLogTitle.g = color.g;
				questLogTitle.b = color.b;
				questLogTitle:Show();

				-- Place the highlight and lock the highlight state
				if ( QuestLogFrame.selectedButtonID and GetQuestLogSelection() == questIndex ) then
					QuestLogSkillHighlight:SetVertexColor(questLogTitle.r, questLogTitle.g, questLogTitle.b);
					QuestLogHighlightFrame:SetPoint("TOPLEFT", "QuestLogTitle"..i, "TOPLEFT", 0, 0);
					QuestLogHighlightFrame:Show();
					questTitleTag:SetTextColor(HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b);
					questNumGroupMates:SetTextColor(HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b);
					questLogTitle:LockHighlight();
				else
					questLogTitle:UnlockHighlight();
				end

			else
				questLogTitle:Hide();
			end
		end

		-- Set the expand/collapse all button texture
		local numHeaders = 0;
		local notExpanded = 0;
		-- Somewhat redundant loop, but cleaner than the alternatives
		for i=1, numEntries, 1 do
			local index = i;
			local questLogTitleText, level, questTag, isHeader, isCollapsed = GetQuestLogTitle(i);
			if ( questLogTitleText and isHeader ) then
				numHeaders = numHeaders + 1;
				if ( isCollapsed ) then
					notExpanded = notExpanded + 1;
				end
			end
		end
		-- If all headers are not expanded then show collapse button, otherwise show the expand button
		if ( notExpanded ~= numHeaders ) then
			QuestLogCollapseAllButton.collapsed = nil;
			QuestLogCollapseAllButton:SetNormalTexture("Interface\\Buttons\\UI-MinusButton-Up");
		else
			QuestLogCollapseAllButton.collapsed = 1;
			QuestLogCollapseAllButton:SetNormalTexture("Interface\\Buttons\\UI-PlusButton-Up");
		end

		-- Update Quest Count
		QuestLogQuestCount:SetText(format(QUEST_LOG_COUNT_TEMPLATE, numQuests, MAX_QUESTLOG_QUESTS));
		QuestLogCountMiddle:SetWidth(QuestLogQuestCount:GetWidth());

		-- If no selection then set it to the first available quest
		if ( GetQuestLogSelection() == 0 ) then
			QuestLog_SetFirstValidSelection();
		end

		-- Determine whether the selected quest is pushable or not
		if ( numEntries == 0 ) then
			QuestFramePushQuestButton:Disable();
		elseif ( GetQuestLogPushable() and IsInGroup() ) then
			QuestFramePushQuestButton:Enable();
		else
			QuestFramePushQuestButton:Disable();
		end
	end
	
	
	
	QuestWatch_Update = function()
		local numObjectives;
		local questWatchMaxWidth = 0;
		local tempWidth;
		local watchText;
		local text, type, finished;
		local questTitle
		local watchTextIndex = 1;
		local questIndex;
		local objectivesCompleted;
	
		for i=1, GetNumQuestWatches() do
			questIndex = GetQuestIndexForWatch(i);
			if ( questIndex ) then
				numObjectives = GetNumQuestLeaderBoards(questIndex);
			
				--If there are objectives set the title
				if ( numObjectives > 0 ) then
					-- Set title
					watchText = _G["QuestWatchLine"..watchTextIndex];
-- CT_CORE CLASSIC ERA OBJECTIVES TRACKER MODIFICATION STARTS HERE
					-- watchText:SetText(GetQuestLogTitle(questIndex));
					local questLogTitleText, level, questTag = GetQuestLogTitle(questIndex);
					if (displayLevels and questLogTitleText and level and level > 0) then
						if (questTag) then
							questLogTitleText = "[" .. level .. "+] " .. questLogTitleText;
						else
							questLogTitleText = "[" .. level .. "] " .. questLogTitleText;
						end
					end
					watchText:SetText(questLogTitleText);
-- CT_CORE CLASSIC ERA OBJECTIVES TRACKER MODIFICATION ENDS HERE
					tempWidth = watchText:GetWidth();
					-- Set the anchor of the title line a little lower
					if ( watchTextIndex > 1 ) then
						watchText:SetPoint("TOPLEFT", "QuestWatchLine"..(watchTextIndex - 1), "BOTTOMLEFT", 0, -4);
					end
					watchText:Show();
					if ( tempWidth > questWatchMaxWidth ) then
						questWatchMaxWidth = tempWidth;
					end
					watchTextIndex = watchTextIndex + 1;
					objectivesCompleted = 0;
					for j=1, numObjectives do
						text, type, finished = GetQuestLogLeaderBoard(j, questIndex);

						watchText = _G["QuestWatchLine"..watchTextIndex];
						-- Set Objective text
						watchText:SetText(" - "..text);
						-- Color the objectives
						if ( finished ) then
							watchText:SetTextColor(HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b);
							objectivesCompleted = objectivesCompleted + 1;
						else
							watchText:SetTextColor(0.8, 0.8, 0.8);
						end
						tempWidth = watchText:GetWidth();
						if ( tempWidth > questWatchMaxWidth ) then
							questWatchMaxWidth = tempWidth;
						end
						watchText:SetPoint("TOPLEFT", "QuestWatchLine"..(watchTextIndex - 1), "BOTTOMLEFT", 0, 0);
						watchText:Show();
						watchTextIndex = watchTextIndex + 1;
					end
					-- Brighten the quest title if all the quest objectives were met
					watchText = _G["QuestWatchLine"..watchTextIndex-numObjectives-1];
					if ( objectivesCompleted == numObjectives ) then
						watchText:SetTextColor(NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b);
					else
						watchText:SetTextColor(0.75, 0.61, 0);
					end
				end
			end
		end
	
		-- Set tracking indicator
		if ( GetNumQuestWatches() > 0 ) then
			QuestLogTrackTracking:SetVertexColor(0, 1.0, 0);
		else
			QuestLogTrackTracking:SetVertexColor(1.0, 0, 0);
		end
		
		-- If no watch lines used then hide the frame and return
		if ( watchTextIndex == 1 ) then
			QuestWatchFrame:Hide();
			return;
		else
			QuestWatchFrame:Show();
			QuestWatchFrame:SetHeight(watchTextIndex * 13);
			QuestWatchFrame:SetWidth(questWatchMaxWidth + 10);
		end
	
		-- Hide unused watch lines
		for i=watchTextIndex, MAX_QUESTWATCH_LINES do
			_G["QuestWatchLine"..i]:Hide();
		end
	
		UIParent_ManageFramePositions();
	end

elseif (module:getGameVersion() == 2) then

	hooksecurefunc("QuestLog_Update", function(self)
		local numEntries, numQuests = GetNumQuestLogEntries();
		if ( numEntries == 0 ) then
			EmptyQuestLogFrame:Show();
			QuestLogFrameAbandonButton:Disable();
			QuestLogFrame.hasTimer = nil;
			QuestLogDetailScrollFrame:Hide();
			QuestLogExpandButtonFrame:Hide();
		else
			EmptyQuestLogFrame:Hide();
			QuestLogFrameAbandonButton:Enable();
			QuestLogDetailScrollFrame:Show();
			QuestLogExpandButtonFrame:Show();
		end

		-- Update Quest Count
		QuestLogUpdateQuestCount(numQuests);

		-- ScrollFrame update
		FauxScrollFrame_Update(QuestLogListScrollFrame, numEntries, QUESTS_DISPLAYED, QUESTLOG_QUEST_HEIGHT, nil, nil, nil, QuestLogHighlightFrame, 293, 316 )

		-- Update the quest listing
		QuestLogHighlightFrame:Hide();

		local questIndex, questLogTitle, questTitleTag, questNumGroupMates, questNormalText, questHighlight, questCheck;
		local questLogTitleText, level, questTag, isHeader, isCollapsed, isComplete, color;
-- CT_CORE TBC CLASSIC QUEST LOG MODIFICATION STARTS HERE
		local frequency, questID, startEvent, displayQuestID, isOnMap, hasLocalPOI, isTask, isBounty, isStory, isHidden, isScaling;
		local numPartyMembers, partyMembersOnQuest, tempWidth, textWidth;
		for i=1, QUESTS_DISPLAYED, 1 do
			questIndex = i + FauxScrollFrame_GetOffset(QuestLogListScrollFrame);
			questLogTitle = _G["QuestLogTitle"..i];
			questTitleTag = _G["QuestLogTitle"..i.."Tag"];
			questNumGroupMates = _G["QuestLogTitle"..i.."GroupMates"];
			questCheck = _G["QuestLogTitle"..i.."Check"];
			questNormalText = _G["QuestLogTitle"..i.."NormalText"];
			questHighlight = _G["QuestLogTitle"..i.."Highlight"];
			if ( questIndex <= numEntries ) then
				questLogTitleText, level, questTag, isHeader, isCollapsed, isComplete, frequency, questID, startEvent, displayQuestID, isOnMap, hasLocalPOI, isTask, isBounty, isStory, isHidden, isScaling = GetQuestLogTitle(questIndex);

				if (displayLevels and questLogTitleText and level and level > 0) then
					if (questTag) then
						questLogTitleText = "[" .. level .. "+] " .. questLogTitleText;
					else
						questLogTitleText = "[" .. level .. "] " .. questLogTitleText;
					end
				end
-- CT_CORE TBC CLASSIC QUEST LOG MODIFICATION ENDS HERE
				if ( isHeader ) then
					if ( questLogTitleText ) then
						questLogTitle:SetText(questLogTitleText);
					else
						questLogTitle:SetText("");
					end

					if ( isCollapsed ) then
						questLogTitle:SetNormalTexture("Interface\\Buttons\\UI-PlusButton-Up");
					else
						questLogTitle:SetNormalTexture("Interface\\Buttons\\UI-MinusButton-Up"); 
					end
					questHighlight:SetTexture("Interface\\Buttons\\UI-PlusButton-Hilight");
					questNumGroupMates:SetText("");
					questCheck:Hide();
				else
					questLogTitle:SetText("  "..questLogTitleText);
					--Set Dummy text to get text width *SUPER HACK*
					QuestLogDummyText:SetText("  "..questLogTitleText);

					questLogTitle:SetNormalTexture("");
					questHighlight:SetTexture("");

					-- If not a header see if any nearby group mates are on this quest
					partyMembersOnQuest = 0;
					for j=1, GetNumSubgroupMembers() do
						if ( IsUnitOnQuest(questIndex, "party"..j) ) then
							partyMembersOnQuest = partyMembersOnQuest + 1;
						end
					end
					if ( partyMembersOnQuest > 0 ) then
						questNumGroupMates:SetText("["..partyMembersOnQuest.."]");
					else
						questNumGroupMates:SetText("");
					end
				end
				-- Save if its a header or not
				questLogTitle.isHeader = isHeader;

				-- Set the quest tag
				if ( isComplete and isComplete < 0 ) then
					questTag = FAILED;
				elseif ( isComplete and isComplete > 0 ) then
					questTag = COMPLETE;
				end
				if ( questTag ) then
					questTitleTag:SetText("("..questTag..")");
					-- Shrink text to accomdate quest tags without wrapping
					tempWidth = 275 - 15 - questTitleTag:GetWidth();

					if ( QuestLogDummyText:GetWidth() > tempWidth ) then
						textWidth = tempWidth;
					else
						textWidth = QuestLogDummyText:GetWidth();
					end

					questNormalText:SetWidth(tempWidth);

					-- If there's quest tag position check accordingly
					questCheck:Hide();
					if ( IsQuestWatched(questIndex) ) then
						if ( questNormalText:GetWidth() + 24 < 275 ) then
							questCheck:SetPoint("LEFT", questLogTitle, "LEFT", textWidth+24, 0);
						else
							questCheck:SetPoint("LEFT", questLogTitle, "LEFT", textWidth+10, 0);
						end
						questCheck:Show();
					end
				else
					questTitleTag:SetText("");
					-- Reset to max text width
					if ( questNormalText:GetWidth() > 275 ) then
						questNormalText:SetWidth(260);
					end

					-- Show check if quest is being watched
					questCheck:Hide();
					if ( IsQuestWatched(questIndex) ) then
						if ( questNormalText:GetWidth() + 24 < 275 ) then
							questCheck:SetPoint("LEFT", questLogTitle, "LEFT", QuestLogDummyText:GetWidth()+24, 0);
						else
							questCheck:SetPoint("LEFT", questNormalText, "LEFT", questNormalText:GetWidth(), 0);
						end
						questCheck:Show();
					end
				end

				-- Color the quest title and highlight according to the difficulty level
				if ( isHeader ) then
					color = QuestDifficultyColors["header"];
				else
					color = GetQuestDifficultyColor(level);
				end
				questLogTitle:SetNormalFontObject(color.font);
				questTitleTag:SetTextColor(color.r, color.g, color.b);
				questNumGroupMates:SetTextColor(color.r, color.g, color.b);
				questLogTitle.r = color.r;
				questLogTitle.g = color.g;
				questLogTitle.b = color.b;
				questLogTitle:Show();

				-- Place the highlight and lock the highlight state
				if ( QuestLogFrame.selectedButtonID and GetQuestLogSelection() == questIndex ) then
					QuestLogSkillHighlight:SetVertexColor(questLogTitle.r, questLogTitle.g, questLogTitle.b);
					QuestLogHighlightFrame:SetPoint("TOPLEFT", "QuestLogTitle"..i, "TOPLEFT", 0, 0);
					QuestLogHighlightFrame:Show();
					questTitleTag:SetTextColor(HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b);
					questNumGroupMates:SetTextColor(HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b);
					questLogTitle:LockHighlight();
				else
					questLogTitle:UnlockHighlight();
				end

			else
				questLogTitle:Hide();
			end
		end

		-- Set the expand/collapse all button texture
		local numHeaders = 0;
		local notExpanded = 0;
		-- Somewhat redundant loop, but cleaner than the alternatives
		for i=1, numEntries, 1 do
			local index = i;
			local questLogTitleText, level, questTag, isHeader, isCollapsed = GetQuestLogTitle(i);
			if ( questLogTitleText and isHeader ) then
				numHeaders = numHeaders + 1;
				if ( isCollapsed ) then
					notExpanded = notExpanded + 1;
				end
			end
		end
		-- If all headers are not expanded then show collapse button, otherwise show the expand button
		if ( notExpanded ~= numHeaders ) then
			QuestLogCollapseAllButton.collapsed = nil;
			QuestLogCollapseAllButton:SetNormalTexture("Interface\\Buttons\\UI-MinusButton-Up");
		else
			QuestLogCollapseAllButton.collapsed = 1;
			QuestLogCollapseAllButton:SetNormalTexture("Interface\\Buttons\\UI-PlusButton-Up");
		end

		-- Update Quest Count
		QuestLogQuestCount:SetText(format(QUEST_LOG_COUNT_TEMPLATE, numQuests, MAX_QUESTLOG_QUESTS));

		-- If no selection then set it to the first available quest
		if ( GetQuestLogSelection() == 0 ) then
			QuestLog_SetFirstValidSelection();
		end

		-- Determine whether the selected quest is pushable or not
		if ( numEntries == 0 ) then
			QuestFramePushQuestButton:Disable();
		elseif ( GetQuestLogPushable() and IsInGroup() ) then
			QuestFramePushQuestButton:Enable();
		else
			QuestFramePushQuestButton:Disable();
		end
	end); -- end posthook of QuestLog_Update
	
	hooksecurefunc("QuestWatch_Update", function(self)
		local numObjectives;
		local questWatchMaxWidth = 0;
		local tempWidth;
		local watchText;
		local text, type, finished;
		local questTitle
		local watchTextIndex = 1;
		local questIndex;
		local objectivesCompleted;

		for i=1, GetNumQuestWatches() do
			questIndex = GetQuestIndexForWatch(i);
			if ( questIndex ) then
				numObjectives = GetNumQuestLeaderBoards(questIndex);

				--If there are objectives set the title
				if ( numObjectives > 0 ) then
					-- Set title
					watchText = _G["QuestWatchLine"..watchTextIndex];
-- CT_CORE TBC CLASSIC OBJECTIVES TRACKER MODIFICATION STARTS HERE
					-- watchText:SetText(GetQuestLogTitle(questIndex));
					local questLogTitleText, level, questTag = GetQuestLogTitle(questIndex);
					if (displayLevels and questLogTitleText and level and level > 0) then
						if (questTag) then
							questLogTitleText = "[" .. level .. "+] " .. questLogTitleText;
						else
							questLogTitleText = "[" .. level .. "] " .. questLogTitleText;
						end
					end
					watchText:SetText(questLogTitleText);
-- CT_CORE TBC CLASSIC OBJECTIVES TRACKER MODIFICATION ENDS HERE
					tempWidth = watchText:GetWidth();
					-- Set the anchor of the title line a little lower
					if ( watchTextIndex > 1 ) then
						watchText:SetPoint("TOPLEFT", "QuestWatchLine"..(watchTextIndex - 1), "BOTTOMLEFT", 0, -4);
					end
					watchText:Show();
					if ( tempWidth > questWatchMaxWidth ) then
						questWatchMaxWidth = tempWidth;
					end
					watchTextIndex = watchTextIndex + 1;
					objectivesCompleted = 0;
					for j=1, numObjectives do
						text, type, finished = GetQuestLogLeaderBoard(j, questIndex);
						watchText = _G["QuestWatchLine"..watchTextIndex];
						-- Set Objective text
						watchText:SetText(" - "..text);
						-- Color the objectives
						if ( finished ) then
							watchText:SetTextColor(HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b);
							objectivesCompleted = objectivesCompleted + 1;
						else
							watchText:SetTextColor(0.8, 0.8, 0.8);
						end
						tempWidth = watchText:GetWidth();
						if ( tempWidth > questWatchMaxWidth ) then
							questWatchMaxWidth = tempWidth;
						end
						watchText:SetPoint("TOPLEFT", "QuestWatchLine"..(watchTextIndex - 1), "BOTTOMLEFT", 0, 0);
						watchText:Show();
						watchTextIndex = watchTextIndex + 1;
					end
					-- Brighten the quest title if all the quest objectives were met
					watchText = _G["QuestWatchLine"..watchTextIndex-numObjectives-1];
					if ( objectivesCompleted == numObjectives ) then
						watchText:SetTextColor(NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b);
					else
						watchText:SetTextColor(0.75, 0.61, 0);
					end
				end
			end
		end

		-- Set tracking indicator
		if ( GetNumQuestWatches() > 0 ) then
			QuestLogTrackTracking:SetVertexColor(0, 1.0, 0);
		else
			QuestLogTrackTracking:SetVertexColor(1.0, 0, 0);
		end

		-- If no watch lines used then hide the frame and return
		if ( watchTextIndex == 1 ) then
			QuestWatchFrame:Hide();
			return;
		else
			QuestWatchFrame:Show();
			QuestWatchFrame:SetHeight(watchTextIndex * 13);
			QuestWatchFrame:SetWidth(questWatchMaxWidth + 10);
		end

		-- Hide unused watch lines
		for i=watchTextIndex, MAX_QUESTWATCH_LINES do
			_G["QuestWatchLine"..i]:Hide();
		end

		UIParent_ManageFramePositions();
	end); -- end post-hook of QuestWatch_Update()
	
elseif (module:getGameVersion() == 3 or module:getGameVersion() == 4) then

	local dummySetText = CreateFrame("Button").SetText
	for __, btn in pairs(QuestLogListScrollFrame.buttons) do
		hooksecurefunc(btn, "SetText", function(self, text)
			if text:sub(1,1) ~= "[" then
				__, level = GetQuestLogTitle(self:GetID())
				if displayLevels and level and level > 0 then
					dummySetText(self, "[" .. level .. "]" .. text:sub(2))
				end
			else
				dummySetText(self, text)
			end
		end)
	end

elseif module:getGameVersion() == 9 then
	
	local dummySetText = CreateFrame("Frame"):CreateFontString(nil, "ARTWORK").SetText;	-- prevents an infinite loop by the hook below

	-- we want to hook each font string as they are created
	hooksecurefunc(QuestScrollFrame.titleFramePool, "resetterFunc", function(__, obj)
		if obj.ct == nil then
			obj.ct = 1
			hooksecurefunc(obj.Text, "SetText", function(fontString, text)
				local info = C_QuestLog.GetInfo(obj.questLogIndex)
				if (displayLevels and info and info.level and info.level > 0) then
					dummySetText(fontString, "[" .. info.level .. (info.suggestedGroup > 0 and "+] " or "] ") .. text)
				end
			end)
		end
	end)
	
	local info
	hooksecurefunc(QUEST_TRACKER_MODULE, "GetBlock", function(__, id)
		if type(id) == "string" then
			id = string.gsub(id, "%D+","") -- Sometimes the function is passed a string like "12345OFFER"
			id = tonumber(id)
		end
		if id then
			local questLogIndex = C_QuestLog.GetLogIndexForQuestID(id)
			if questLogIndex then
				info = C_QuestLog.GetInfo(questLogIndex)
			end
		end
	end)
	
	hooksecurefunc("QuestObjective_SetupHeader", function(block)
		if block.HeaderText and block.ct == nil then
			block.ct = 1
			hooksecurefunc(block.HeaderText, "SetText", function(fontString, text)
				if (displayLevels and info and info.level and info.level > 0) then
					dummySetText(fontString, "[" .. info.level .. (info.suggestedGroup > 0 and "+] " or "] ") .. text)
				end
				info = nil
			end)
		end
	end)
end

--------------------------------------------
-- Block trades when bank or guild bank is open

do
	local blockOption;
	local blockOriginal;
	local blockcvar = "blockTrades";

	local function restoreBlockState()
		-- Restore blocking to its original state, which could be disabled or enabled.
		if (blockOriginal) then
			SetCVar(blockcvar, blockOriginal);
			blockOriginal = nil;
		end
	end

	local function enableBlockState()
		-- Change blocking state to enabled.
		if (blockOriginal == nil) then
			-- Save the original blocking state before we change it.
			blockOriginal = GetCVar(blockcvar);
		end
		-- Blocking is now enabled.
		SetCVar(blockcvar, "1");
	end

	-- If leaving the world, or the window is being closed, then restore
	-- blocking to its original state.
	module:regEvent("PLAYER_LEAVING_WORLD", restoreBlockState);
	module:regEvent("BANKFRAME_CLOSED", restoreBlockState);
	if (GuildBankFrame_LoadUI) then
		module:regEvent("GUILDBANKFRAME_CLOSED", restoreBlockState);
	end

	-- If the bank frame has just opened, and the user wants to block while
	-- at the bank, then start blocking.
	module:regEvent("BANKFRAME_OPENED", function()
		if (blockOption) then
			enableBlockState();
		end
	end);

	-- If the guild bank frame has just opened, and the user wants to block while
	-- at the guild bank, then start blocking.
	if (GuildBankFrame_LoadUI) then
		module:regEvent("GUILDBANKFRAME_OPENED", function()
			if (blockOption) then
				enableBlockState();
			end
		end);
	end
	
	-- Configure blocking option.
	module.configureBlockTradesBank = function(block)
		blockOption = block; -- Save the option's value in a local variable
		if (blockOption) then
			-- User wants to block trades while at this window.
			-- If the frame is currently shown, then start blocking.
			if ( (BankFrame and BankFrame:IsShown()) or (GuildBankFrame and GuildBankFrame:IsShown()) ) then
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
-- Tooltip Reanchoring

local tooltipFixedAnchor = CreateFrame("Frame", nil, UIParent);
tooltipFixedAnchor:SetSize(10,10);
tooltipFixedAnchor:SetPoint("CENTER", UIParent, "CENTER", 0, 0);
if tooltipFixedAnchor.SetIsUnrestricted then tooltipFixedAnchor:SetIsUnrestricted(true) end
tooltipFixedAnchor.texture = tooltipFixedAnchor:CreateTexture(nil, "BACKGROUND");
tooltipFixedAnchor.texture:SetAllPoints();
tooltipFixedAnchor.texture:SetColorTexture(1,1,0.8,0.5);
tooltipFixedAnchor:RegisterEvent("ADDON_LOADED");
tooltipFixedAnchor:SetScript("OnEvent",
	function (self, event, args)
		if event == "ADDON_LOADED" then
			self:UnregisterEvent("ADDON_LOADED");
			module:registerMovable("TOOLTIPANCHOR", tooltipFixedAnchor, true, 50);
		end
	end
);

tooltipFixedAnchor:SetScript("OnMouseDown",
	function(self, button)
		if (button == "LeftButton") then
			module:moveMovable("TOOLTIPANCHOR");
		elseif (button == "RightButton") then
			local anchorSetting = 1 + (module:getOption("tooltipAnchor") or 5);
			if (anchorSetting > 6) then
				anchorSetting = 1;
			end
			module:setOption("tooltipAnchor", anchorSetting);
			local direction = "NONE";
			if anchorSetting == 1 then
				direction = "TOPLEFT"
			elseif anchorSetting == 2 then
				direction = "TOPRIGHT"
			elseif anchorSetting == 3 then
				direction = "BOTTOMRIGHT"
			elseif anchorSetting == 4 then
				direction = "BOTTOMLEFT"
			elseif anchorSetting == 5 then
				direction = "TOP";
			elseif anchorSetting == 6 then
				direction = "BOTTOM"
			end
			GameTooltip:Hide();
			GameTooltip:SetOwner(tooltipFixedAnchor,"ANCHOR_" .. direction);
			GameTooltip:SetText("Left-click to drag the tooltip");
			GameTooltip:AddLine("Right-click to change the direction");
			GameTooltip:Show();
		end
	end
);
tooltipFixedAnchor:SetScript("OnMouseUp",
	function()
		module:stopMovable("TOOLTIPANCHOR");
	end
);
tooltipFixedAnchor:SetScript("OnEnter",
	function()
		local anchorSetting = module:getOption("tooltipAnchor") or 5;
		local direction = "NONE";
		if anchorSetting == 1 then
			direction = "TOPLEFT"
		elseif anchorSetting == 2 then
			direction = "TOPRIGHT"
		elseif anchorSetting == 3 then
			direction = "BOTTOMRIGHT"
		elseif anchorSetting == 4 then
			direction = "BOTTOMLEFT"
		elseif anchorSetting == 5 then
			direction = "TOP";
		elseif anchorSetting == 6 then
			direction = "BOTTOM"
		end
		GameTooltip:SetOwner(tooltipFixedAnchor,"ANCHOR_" .. direction);
		GameTooltip:SetText("Left-click to drag the tooltip");
		GameTooltip:AddLine("Right-click to change the direction");
		GameTooltip:Show();
	end
);
tooltipFixedAnchor:SetScript("OnLeave",
	function()
		GameTooltip:Hide();
	end
);


-- show the anchor when appropriate
tooltipFixedAnchor:Hide();
local function tooltip_toggleAnchor()
	if (module:getOption("tooltipAnchorUnlock") and module:getOption("tooltipRelocation") == 3) then
		tooltipFixedAnchor:Show();
	else
		tooltipFixedAnchor:Hide();
	end
end

local tooltipMouseAnchor = CreateFrame("Frame", nil, UIParent);
tooltipMouseAnchor:SetSize(0.00001, 0.00001);
tooltipMouseAnchor:SetIgnoreParentScale(true);

local mouseUnitOffset = 0;
local function updateMousePosition()	
	local cx, cy = GetCursorPosition();		
	if (cy) then	
		tooltipMouseAnchor:SetPoint("BOTTOMLEFT", cx, cy + mouseUnitOffset);
	end
end

-- position the tooltip when it is not owned by something else
hooksecurefunc("GameTooltip_SetDefaultAnchor",
	function (tooltip, text, x, y, wrap)
		local option = module:getOption("tooltipRelocation");
		if (option == 2 or option == 4) then
			--on mouse (stationary) and on mouse (following)
			
			-- update the mouse anchor's position, and cause it to keep updating rapidly if option == 4
			updateMousePosition();
			if (option == 4) then
				tooltip.ctTicker = tooltip.ctTicker or C_Timer.NewTicker(0.03, updateMousePosition);
			end
			
			-- where is the mouse cursor, anyways?
			local uiScale, cx, cy = UIParent:GetEffectiveScale(), GetCursorPosition();		
			if (not uiScale or not cx or not cy) then
				return;
			end

			-- adds hooks once to each GameTooltip only (there could be several if addons use their own versions)
			if (not tooltip.ctIsHooked) then
				tooltip.ctIsHooked = true;
				tooltip:HookScript("OnShow",
					function() 
						-- This information isn't known until the tooltip has appeared
						mouseUnitOffset = tooltip:GetUnit() and mouseUnitOffset or 0;
					end
				);
				tooltip:HookScript("OnHide",
					function() 
						if (tooltip.ctTicker) then
							tooltip.ctTicker:Cancel();
							tooltip.ctTicker = nil;
						end
					end
				);
			end
						
			-- anchor the tooltip itself, because it has to be done now and no later to avoid taint (if it is the GameTooltip)
			if (cx/uiScale > UIParent:GetWidth()/2) then
				if (cy/uiScale > UIParent:GetHeight()/2) then			-- mouse is in top-right quadrant
					tooltip:SetOwner(
						tooltipMouseAnchor,
						"ANCHOR_BOTTOMLEFT",
						-(module:getOption("tooltipDistance") or 0),
						-(module:getOption("tooltipDistance") or 0)
					);
					mouseUnitOffset = 0;
				else								-- mouse is in bottom-right quadrant.
					tooltip:SetOwner(
						tooltipMouseAnchor,
						"ANCHOR_TOPRIGHT",
						-(module:getOption("tooltipDistance") or 0),
						(module:getOption("tooltipDistance") or 0) 
					);
					mouseUnitOffset = 10;
				end
			else
				if (cy/uiScale > UIParent:GetHeight()/2) then			-- mouse is in top-left quadrant
					tooltip:SetOwner(
						tooltipMouseAnchor,
						"ANCHOR_BOTTOMRIGHT",
						 20 + (module:getOption("tooltipDistance") or 0),
						-20 - (module:getOption("tooltipDistance") or 0)
					);
					mouseUnitOffset = 0;
				else								-- mouse is in bottom-left quadrant
					tooltip:SetOwner(
						tooltipMouseAnchor,
						"ANCHOR_TOPLEFT",
						(module:getOption("tooltipDistance") or 0),
						(module:getOption("tooltipDistance") or 0)
					);
					mouseUnitOffset = 10;
				end
			end
		elseif (option == 3) then
			--on anchor
			local direction = "NONE";
			local anchorSetting = module:getOption("tooltipAnchor") or 5;
			if (anchorSetting == 1) then
				direction = "TOPLEFT";
			elseif (anchorSetting == 2) then
				direction = "TOPRIGHT";
			elseif (anchorSetting == 3) then
				direction = "BOTTOMRIGHT";
			elseif (anchorSetting == 4) then
				direction = "BOTTOMLEFT";
			elseif (anchorSetting == 5) then
				direction = "TOP";
			elseif (anchorSetting == 6) then
				direction = "BOTTOM";
			end	
			tooltip:SetOwner(tooltipFixedAnchor, "ANCHOR_" .. direction);
		end
	end
);



do
	-- Control whether the tooltip should fade out or disappear immediately
	
	local tooltipFadeTicker;

	local function accelerateFade()
		if (GameTooltip:GetAlpha() < 1) then
			GameTooltip:Hide();
		end
	end

	GameTooltip:HookScript("OnShow", function()
		if (module:getOption("tooltipDisableFade")) then
			tooltipFadeTicker = tooltipFadeTicker or C_Timer.NewTicker(0.1, accelerateFade);
		end
	end);
	GameTooltip:HookScript("OnHide", function()
		if (tooltipFadeTicker) then
			tooltipFadeTicker:Cancel();
			tooltipFadeTicker = nil;
		end
	end);

end
--------------------------------------------
-- Tick Mod

local tickFrame;
local tickDisplayType = 1;

local tickFormatHealth_1 = "Health: %d";
local tickFormatHealth_2 = "HP/Tick: %d";
local tickFormatHealth_3 = "HP: %d";
local tickFormatMana_1 = "Mana: %d";
local tickFormatMana_2 = "MP/Tick: %d";
local tickFormatMana_3 = "MP: %d";

local tickFrameWidth;
local tickFadeFunc, tickFading;
local lastTickHealth, lastTickMana;

local healthString, manaString

local tickFrameLocked, tickFrameLockedMessageSent;

local function fadeObject(self)
	local alpha = self.alpha;
	if ( alpha and alpha > 0.25 ) then
		alpha = alpha - 0.036;
		self.alpha = alpha;
		self:SetAlpha(alpha);
		return true;
	end
end

local fadeTicks;
function fadeTicks()
	local fadedHealth = fadeObject(healthString);
	local fadedMana = fadeObject(manaString);
	if (fadedHealth or fadedMana ) then
		tickFading = true;
		C_Timer.After(0.06, fadeTicks);
	else
		tickFading = false;
	end
end

local function updateTickDisplay(obj, diff)
	obj:SetText(format(obj.strFormat, diff));
	obj:SetAlpha(1);
	obj.alpha = 1;

	if ( tickFrameWidth ) then
		tickFrame:SetWidth(tickFrameWidth);
	end

	if (not tickFading) then
		tickFading = true;
		C_Timer.After(0.06, fadeTicks);
	end
end

local function tickFrameSkeleton()
	return "button#tl:mid:350:-200#s:90:40", {
		"backdrop#tooltip",
		"font#i:health#t:0:-8",
		"font#i:mana#b:0:8",
		["onload"] = function(self)
			self:RegisterEvent("UNIT_HEALTH");
			self:RegisterEvent("UNIT_POWER_UPDATE");
			self:SetBackdropColor(0, 0, 0, 0.75);
			module:registerMovable("TICKMOD", self, true);
		end,
		["onevent"] = function(self, event, unit, arg2)
			if ( unit == "player" ) then
				if ( event == "UNIT_HEALTH" ) then
					local health = UnitHealth("player");
					local diff = health-lastTickHealth;
					if ( diff > 0 ) then
						updateTickDisplay(healthString, diff);
					end
					lastTickHealth = health;
				elseif ( event == "UNIT_POWER_UPDATE" and arg2 == "MANA" ) then
					local mana = UnitPower("player");
					local diff = mana-lastTickMana;
					if ( diff > 0 ) then
						updateTickDisplay(manaString, diff);
					end
					lastTickMana = mana;
				end
			end
		end,
		["onenter"] = function(self)
			if (not tickFrameLocked) then
				module:displayPredefinedTooltip(self, "DRAG");
			end
		end,
		["onmousedown"] = function(self, button)
			if (tickFrameLocked) then
				if (not tickFrameLockedMessageSent) then
					print("Type /ctcore to unlock and configure the regen tracker");
					tickFrameLockedMessageSent = true;
				end
			else
				if ( button == "LeftButton" ) then
					module:moveMovable("TICKMOD");
				end
			end
		end,
		["onmouseup"] = function(self, button)
			if (not tickFrameLocked) then
				if ( button == "LeftButton" ) then
					module:stopMovable("TICKMOD");
				elseif ( button == "RightButton" ) then
					module:resetMovable("TICKMOD");
					self:ClearAllPoints();
					self:SetPoint("CENTER", UIParent);
				end
			end
		end
	};
end

local function updateTickFrameOptions()
	if ( not tickFrame ) then
		return;
	end

	-- Height
	local _, class = UnitClass("player");
	if ( UnitPowerType("player") == 0 or class == "DRUID" ) then
		tickFrame:SetHeight(40);
	else
		tickFrame:SetHeight(30);
	end

	-- Width & Format
	if ( not tickDisplayType or tickDisplayType == 1 ) then
		tickFrameWidth = 90;
		tickFrame.health.strFormat = tickFormatHealth_1;
		tickFrame.mana.strFormat = tickFormatMana_1;
	elseif ( tickDisplayType == 2 ) then
		tickFrameWidth = 100;
		tickFrame.health.strFormat = tickFormatHealth_2;
		tickFrame.mana.strFormat = tickFormatMana_2;
	elseif ( tickDisplayType == 3 ) then
		tickFrameWidth = 80;
		tickFrame.health.strFormat = tickFormatHealth_3;
		tickFrame.mana.strFormat = tickFormatMana_3;
	end
end

local function toggleTick(enable)
	if ( enable ) then
		if ( not tickFrame ) then
			tickFrame = module:getFrame(tickFrameSkeleton);
			healthString = tickFrame["health"]
			manaString = tickFrame["mana"]
		end
		tickFrame:Show();
		updateTickFrameOptions();
		lastTickHealth, lastTickMana = UnitHealth("player"), UnitPower("player");

	elseif ( tickFrame ) then
		tickFrame:Hide();
	end
end

local function setTickDisplayType(mode)
	tickDisplayType = mode;
	updateTickFrameOptions();
end

local function setTickLocked(enable)
	tickFrameLocked = enable;
end

--------------------------------------------
-- Casting Bar Timer

local displayTimers;
local castingBarFrames = { "CastingBarFrame", "PlayerCastingBarFrame", "TargetFrameSpellBar", "FocusFrameSpellBar", "CT_CastingBarFrame" };

local function castingtimer_createFS(castBarFrame)
	local countDownText = castBarFrame:CreateFontString(nil, "ARTWORK", "GameFontHighlight");
	castBarFrame.countDownText = countDownText;
	castBarFrame.ctTickerFunc = castBarFrame.ctTickerFunc or function()
		-- Fetch raw data
		local maxVal = castBarFrame.maxValue or 0;
		local curVal = castBarFrame.value or 0;

		-- We need to update
		if ( castBarFrame.casting ) then
			-- COMBAT SAFEGUARD FOR RETAIL:
			-- Vi flyttar ut matematiken och math.max till en pcall. 
			-- This forces the game engine to perform the calculation on the hidden "secret numbers"
			-- and return the result to us as a clean, sanitized text string.
			local displayTime = "0.0s";
			local success, result = pcall(function()
				local rawTime = tonumber(maxVal) or 0;
				local rawCur = tonumber(curVal) or 0;
				return format("%0.1fs", math.max(rawTime - rawCur, 0));
			end);
			
			if success and result then
				displayTime = result;
			end
			countDownText:SetText(displayTime);

		elseif ( castBarFrame.channeling ) then
			-- Same thing for channeling
			local displayTime = "0.0s";
			local success, result = pcall(function()
				local rawCur = tonumber(curVal) or 0;
				return format("%0.1fs", math.max(rawCur, 0));
			end);
			
			if success and result then
				displayTime = result;
			end
			countDownText:SetText(displayTime);
		else
			countDownText:SetText("");
		end
	end
	castBarFrame:HookScript("OnShow", function()
		if(displayTimers) then
			castBarFrame.ctTickerHandle = castBarFrame.ctTickerHandle or C_Timer.NewTicker(0.1, castBarFrame.ctTickerFunc);
		end
	end);
	castBarFrame:HookScript("OnHide", function()
		if(castBarFrame.ctTickerHandle) then
			castBarFrame.ctTickerHandle:Cancel();
			castBarFrame.ctTickerHandle = nil;
		end
	end);	
end

for i, frameName in ipairs(castingBarFrames) do
	local frame = _G[frameName];
	if (frame) then
		castingtimer_createFS(frame)
	end
end

local function castingtimer_configure(castBarFrame)
	
	local castingBarText = castBarFrame.Text
	local countDownText = castBarFrame.countDownText

	if displayTimers then

		if (not countDownText) then
			castingtimer_createFS(castBarFrame)
			countDownText = castBarFrame.countDownText
		end

		countDownText:ClearAllPoints()
		castingBarText:ClearAllPoints()
		countDownText:SetFontObject(castingBarText:GetFontObject())

		if ((castBarFrame:GetWidth() or 0) > 190) then
			-- CLASSIC look
			countDownText:SetPoint("TOPRIGHT", 0, CastingBarMixin and -12 or 3)
			castingBarText:SetPoint("TOPLEFT", 3, CastingBarMixin and -10 or 5)
			castingBarText:SetPoint("RIGHT", countDownText, "LEFT", 10, 0)
		else
			-- UNITFRAME look
			countDownText:SetPoint("TOPRIGHT", 0, CastingBarMixin and 1 or 2)
			castingBarText:SetPoint("TOPLEFT", 5, CastingBarMixin and 3 or 4)
			castingBarText:SetPoint("RIGHT", countDownText, "LEFT", 10, 0)
		end

		countDownText:Show()
	
	elseif countDownText then
	
		countDownText:Hide()

		-- See CastingBarFrame_SetLook() in CastingBarFrame.lua.
		if ((castBarFrame:GetWidth() or 0) > 190) then
			-- CLASSIC look
			castingBarText:ClearAllPoints()
			castingBarText:SetWidth(185)
			castingBarText:SetHeight(16)
			castingBarText:SetPoint("TOP", 0, CastingBarMixin and -10 or 5)	 -- WoW 10.0 vs Classic
		else
			-- UNITFRAME look
			castingBarText:ClearAllPoints()
			castingBarText:SetWidth(0)
			castingBarText:SetHeight(16)
			castingBarText:SetPoint("TOPLEFT", 0, CastingBarMixin and 3 or 4)
			castingBarText:SetPoint("TOPRIGHT", 0, CastingBarMixin and 3 or 4)
		end
		
	end
end

local function castingtimer_PlayerFrame_DetachCastBar()
	-- hooksecurefunc of PlayerFrame_DetachCastBar in PlayerFrame.lua.
	castingtimer_configure(CastingBarFrame or PlayerCastingBarFrame);
end

local function castingtimer_PlayerFrame_AttachCastBar()
	-- hooksecurefunc of PlayerFrame_AttachCastBar in PlayerFrame.lua.
	castingtimer_configure(CastingBarFrame or PlayerCastingBarFrame);
end

hooksecurefunc("PlayerFrame_DetachCastBar", castingtimer_PlayerFrame_DetachCastBar);
hooksecurefunc("PlayerFrame_AttachCastBar", castingtimer_PlayerFrame_AttachCastBar);

local function toggleCastingTimers(enable)
	displayTimers = enable;

	if enable then
		for i, frameName in ipairs(castingBarFrames) do
			local frame = _G[frameName];
			if (frame) then
				castingtimer_configure(frame);
			end
		end
	end
end

local function addCastingBarFrame(name)
	local frame = _G[name];
	if (frame) then
		tinsert(castingBarFrames,name)
		if displayTimers then
			castingtimer_configure(frame)
		end
	end
end

module.addCastingBarFrame = addCastingBarFrame;

--------------------------------------------
-- Alt+Right-Click to buy full stack

local function CT_Core_MerchantItemButton_OnModifiedClick(self, ...)
	local merchantAltClickItem = module:getOption("merchantAltClickItem") ~= false;  -- if option is nil then default to true
	if (merchantAltClickItem and IsAltKeyDown()) then
		local id = self:GetID();
		local maxStack = GetMerchantItemMaxStack(id);
		local money = GetMoney();
		local _, _, price, quantity = GetMerchantItemInfo(id);

		if ( maxStack == 1 and quantity > 1 ) then
			-- We need to check max stack count
			local _, _, _, _, _, _, _, stackCount = GetItemInfo(GetMerchantItemLink(id));
			if ( stackCount and stackCount > 1 ) then
				if (quantity == 0) then
					maxStack = 0;
				else
					maxStack = floor(stackCount/quantity);
				end
			end
		end

		if ( maxStack*price > money ) then
			if (price == 0) then
				maxStack = 0;
			else
				maxStack = floor(money/price);
			end
		end

		BuyMerchantItem(id, maxStack);
	end
end

hooksecurefunc("MerchantItemButton_OnModifiedClick", CT_Core_MerchantItemButton_OnModifiedClick);

--------------------------------------------
-- Alt Left Click to add item to auctions frame.

local function CT_Core_AddToAuctions(self, button)
	if (button == "LeftButton" and IsAltKeyDown()) then
		if (AuctionFrame:IsShown()) then
			local auctionAltClickItem = module:getOption("auctionAltClickItem");
			if (auctionAltClickItem and
				not CursorHasItem()
			) then
				if (not AuctionFrameAuctions:IsVisible()) then
					-- Switch to the "auctions" tab.
					AuctionFrameTab_OnClick(AuctionFrameTab3, 3);
				end
				-- Pickup and place item in the auction sell button.
				local bag, item = self:GetParent():GetID(), self:GetID()
				if C_Container and C_Container.PickupContainerItem then
					C_Container.PickupContainerItem(bag, item)
				end
				ClickAuctionSellItemButton(AuctionsItemButton, "LeftButton")
				AuctionsFrameAuctions_ValidateAuction()
				return true;
			end
		end
	end
	return false;
end

--------------------------------------------
-- Alt Left Click to initiate trade or add item to trade window.

local CT_Core_AddToTrade;

do
	local prepareTrade;
	local addItemToTrade;

	do
		local prepBag, prepItem, prepPlayer;
		local function clearTrade()
			prepBag, prepItem, prepPlayer = nil;
		end

		prepareTrade = function(bag, item, player) -- Local
			prepBag, prepItem, prepPlayer = bag, item, player;
			C_Timer.After(3, clearTrade);
		end

		addItemToTrade = function(bag, item)
			local slot = TradeFrame_GetAvailableSlot()
			if (slot) then
				if C_Container and C_Container.PickupContainerItem then
					C_Container.PickupContainerItem(bag, item)
				end
				ClickTradeButton(slot)
			end
		end

		module:regEvent("TRADE_SHOW", function()
			if ( prepBag and prepItem and UnitName("target") == prepPlayer ) then
				addItemToTrade(prepBag, prepItem);
			end
			clearTrade();
		end);
	end

	CT_Core_AddToTrade = function(self, button)
		if (button == "LeftButton" and IsAltKeyDown()) then
			if (TradeFrame) then
				if (not TradeFrame:IsShown()) then
					local tradeAltClickOpen = module:getOption("tradeAltClickOpen");
					if (tradeAltClickOpen and
						not CursorHasItem() and
						UnitExists("target") and
						CheckInteractDistance("target", 2) and
						UnitIsFriend("player", "target") and
						UnitIsPlayer("target")
					) then
						-- Initiate a trade and in a few seconds pickup and add the item to the trade window.
						local bag, item = self:GetParent():GetID(), self:GetID();
						InitiateTrade("target");
						prepareTrade(bag, item, UnitName("target"));
						return true;
					end
				else
					local tradeAltClickAdd = module:getOption("tradeAltClickAdd");
					if (tradeAltClickAdd and
						not CursorHasItem()
					) then
						-- Pickup and add an item to the trade window.
						local bag, item = self:GetParent():GetID(), self:GetID();
						addItemToTrade(bag, item);
						return true;
					end
				end
			end
		end
		return false;
	end
end

--------------------------------------------
-- Handle clicks on item in a container frame.
-- Currently used by CT_Core and CT_MailMod.

local cfibomcTable = {};

function CT_Core.ContainerFrameItemButton_OnModifiedClick_Register(func)
	cfibomcTable[func] = true
end

function CT_Core.ContainerFrameItemButton_OnModifiedClick_Unregister(func)
	cfibomcTable[func] = nil
end

local function CT_Core_ContainerFrameItemButton_OnModifiedClick(self, button)
	-- Test registered functions
	for func, value in pairs(cfibomcTable) do
		if func(self, button) then
			return
		end
	end
	-- Test for the Add To Trade function last, since this one
	-- doesn't require a particular frame to be open (unless you're
	-- adding to an open trade frame).
	CT_Core_AddToTrade(self, button)
end

if ContainerFrameItemButtonMixin and hooksecurefunc then
    hooksecurefunc(ContainerFrameItemButtonMixin, "OnModifiedClick", CT_Core_ContainerFrameItemButton_OnModifiedClick)
end

if AuctionFrame then
	-- before WoW 10.x
	CT_Core.ContainerFrameItemButton_OnModifiedClick_Register(CT_Core_AddToAuctions)
end

--------------------------------------------
-- Hides the gryphons if the user does not have CT_BottomBar installed
-- val is true should the gryphons be hidden, or false should they remain visible
local function hide_gryphons(val)
	if (CT_BottomBar) then return; end
	
	-- Safe handling for modern WoW (Retail / Dragonflight / The War Within)
	if MainMenuBar and MainMenuBar.EndCaps then
		if (val) then
			if MainMenuBar.EndCaps.LeftEndCap then MainMenuBar.EndCaps.LeftEndCap:Hide() end
			if MainMenuBar.EndCaps.RightEndCap then MainMenuBar.EndCaps.RightEndCap:Hide() end
		else
			if MainMenuBar.EndCaps.LeftEndCap then MainMenuBar.EndCaps.LeftEndCap:Show() end
			if MainMenuBar.EndCaps.RightEndCap then MainMenuBar.EndCaps.RightEndCap:Show() end
		end
		return;
	end

	-- Fallback for older expansions / Classic clients
	if (val) then
		if _G["MainMenuBarArtFrame"] and _G["MainMenuBarArtFrame"].LeftEndCap then
			_G["MainMenuBarArtFrame"].LeftEndCap:Hide()
			_G["MainMenuBarArtFrame"].RightEndCap:Hide()
		elseif _G["MainMenuBarLeftEndCap"] then
			_G["MainMenuBarLeftEndCap"]:Hide()
			_G["MainMenuBarRightEndCap"]:Hide()
		end
	else
		if _G["MainMenuBarArtFrame"] and _G["MainMenuBarArtFrame"].LeftEndCap then
			_G["MainMenuBarArtFrame"].LeftEndCap:Show()
			_G["MainMenuBarArtFrame"].RightEndCap:Show()
		elseif _G["MainMenuBarLeftEndCap"] then
			_G["MainMenuBarLeftEndCap"]:Show()
			_G["MainMenuBarRightEndCap"]:Show()
		end
	end
end

--------------------------------------------
-- Hide World Map Minimap Button

local function toggleWorldMap(hide)
	if ( hide ) then
		MiniMapWorldMapButton:Hide();
	else
		MiniMapWorldMapButton:Show();
	end
end

--------------------------------------------
-- Movable casting bar

local castingbar_ToggleHelper, castingbar_Update	-- defined within the code block below

if not CastingBarMixin then

	local movableCastingBar, movableCastingBarHelper, enableMovableCastingBar, unlockMovableCastingBar

	-- start by creating a helper that can be moved around
	movableCastingBarHelper = CreateFrame("StatusBar", nil, UIParent, "CastingBarFrameTemplate");
	movableCastingBarHelper:SetWidth(195);
	movableCastingBarHelper:SetHeight(13);
	movableCastingBarHelper:SetPoint("CENTER", UIParent, "CENTER", 0, 0);
	movableCastingBarHelper:SetFrameStrata("BACKGROUND");
	movableCastingBarHelper:SetScript("OnEvent", nil);
	movableCastingBarHelper:SetScript("OnUpdate", nil);
	movableCastingBarHelper:SetScript("OnShow", nil);

	function castingbar_ToggleHelper(showHelper) -- local
		unlockMovableCastingBar = showHelper
		movableCastingBarHelper:SetShown(enableMovableCastingBar and unlockMovableCastingBar)
	end

	castingbar_ToggleHelper(module:getOption("castingbarMovable"));
	-- deferred until ADDON_LOADED -- module:registerMovable("CASTINGBARHELPER",movableCastingBarHelper,true);
	movableCastingBarHelper:SetScript("OnMouseDown",
		function(self, button)
			module:moveMovable("CASTINGBARANCHOR2")
		end
	);
	movableCastingBarHelper:SetScript("OnMouseUp",
		function(self, button)
			module:stopMovable("CASTINGBARANCHOR2")
		end
	);


	-- create the actual bar and attach it to the helper's current position
	local movableCastingBar = CreateFrame("StatusBar", "CT_CastingBarFrame", UIParent, "CastingBarFrameTemplate");
	movableCastingBar:SetPoint("CENTER", movableCastingBarHelper);
	movableCastingBar:SetWidth(195);
	movableCastingBar:SetHeight(13);
	movableCastingBar:Hide();
	movableCastingBar:SetFrameStrata("HIGH");

	local movableCastingBarIsLoaded = nil;

	local frameIsAttached = nil;
	function castingbar_Update(enable)
		if (not movableCastingBarIsLoaded) then
			return;
		end
		if (enable and not frameIsAttached) then
			if CastingBarFrame_OnLoad then
				-- prior to WoW 10.x
				CastingBarFrame_OnLoad(movableCastingBar, "player", true, false)
				CastingBarFrame_OnLoad(CastingBarFrame, nil, true, false)
			else
				-- WoW 10.x
				PlayerCastingBarFrame.OnLoad(movableCastingBar, "player", true, false)
				PlayerCastingBarFrame.showCastbar = false --:OnLoad(nil, true, false)
			end
		else
			if CastingBarFrame_OnLoad then
				-- prior to WoW 10.x
				CastingBarFrame_OnLoad(movableCastingBar, nil, true, false)
				CastingBarFrame_OnLoad(CastingBarFrame, "player", true, false)
			else
				-- WoW 10.x
				movableCastingBar.showCastbar = false
				PlayerCastingBarFrame.showCastbar = true   --:OnLoad("player", true, false)
			end
		end
		enableMovableCastingBar = enable
		movableCastingBarHelper:SetShown(enableMovableCastingBar and unlockMovableCastingBar)
	end

	movableCastingBar:RegisterEvent("ADDON_LOADED")
	movableCastingBar:HookScript("OnEvent",
		function(self, event, ...)
			if (event == "ADDON_LOADED" and not movableCastingBarIsLoaded) then
				module:registerMovable("CASTINGBARANCHOR2",movableCastingBarHelper,true);
				movableCastingBar.Icon:Hide();
				movableCastingBarIsLoaded = true;
				castingbar_Update(module:getOption("castingbarEnabled"))
			end
		end	
	);

	local function castingbar_PlayerFrame_DetachCastBar()
		frameIsAttached = nil;
		castingbar_Update(module:getOption("castingbarEnabled"))  -- use our bar IF APPROPRIATE
	end

	local function castingbar_PlayerFrame_AttachCastBar()
		frameIsAttached = true;
		castingbar_Update(false); -- no matter what, stop using our bar
	end

	hooksecurefunc("PlayerFrame_DetachCastBar", castingbar_PlayerFrame_DetachCastBar);
	hooksecurefunc("PlayerFrame_AttachCastBar", castingbar_PlayerFrame_AttachCastBar);

end

--------------------------------------------
-- Movable LossOfControlFrame

local movableLoC_UpdateVisibility, movableLoC_UpdatePosition, movableLoC_UpdateDragging

if (LossOfControlFrame) then

	-- STEP 1: Create a helper that can be moved around
	-- STEP 2: Create a mock background that will appear only when dragging the frame
	-- STEP 3: Attach the LossOfControlFrame and hook its OnShow/Hide to avoid duplicating the mock background
	-- STEP 4: Configure functions to implement setting changes

	local isMovable;
	local isDragging;

	-- STEP 1:
	
	local movableFrame = CreateFrame("Frame", nil, UIParent)
	movableFrame:SetSize(256, 112)
	movableFrame:SetPoint("CENTER")
	if movableFrame.SetIsUnrestricted then movableFrame:SetIsUnrestricted(true) end	
	movableFrame:SetClampedToScreen(true)
	module:regEvent("PLAYER_LOGIN", function()
		module:registerMovable("movableLossOfControlFrame", movableFrame, true)
	end)
	movableFrame:SetScript("OnMouseDown", function()
		module:moveMovable("movableLossOfControlFrame")
	end)
	movableFrame:SetScript("OnMouseUp", function()
		module:stopMovable("movableLossOfControlFrame")
	end)
	movableFrame:EnableMouse(false)	-- the previous OnMouseDown/OnMouseUp will automatically enable it; but we only want it to respond when necessary
	
	-- STEP 2:
	
	movableFrame:DisableDrawLayer("BACKGROUND")	-- only enabled when required
	
	movableFrame.blackBg = movableFrame:CreateTexture(nil, "BACKGROUND")
	movableFrame.blackBg:SetSize(256, 58)
	movableFrame.blackBg:SetPoint("CENTER")
	movableFrame.blackBg:SetVertexColor(1.0, 1.0, 1.0, 0.6)
	movableFrame.blackBg:SetTexture("Interface\\Cooldown\\LoC-ShadowBG")
	
	movableFrame.RedLineTop = movableFrame:CreateTexture(nil, "BACKGROUND")
	movableFrame.RedLineTop:SetSize(236, 27)
	movableFrame.RedLineTop:SetPoint("TOP")
	movableFrame.RedLineTop:SetTexture("Interface\\Cooldown\\Loc-RedLine")
	
	movableFrame.RedLineBottom = movableFrame:CreateTexture(nil, "BACKGROUND")
	movableFrame.RedLineBottom:SetSize(236, 27)
	movableFrame.RedLineBottom:SetPoint("BOTTOM")
	movableFrame.RedLineBottom:SetTexture("Interface\\Cooldown\\Loc-RedLine")
	movableFrame.RedLineBottom:SetTexCoord(0, 1, 1, 0)
	
	-- STEP 3:
	
	LossOfControlFrame:SetParent(movableFrame)
	LossOfControlFrame:HookScript("OnHide", function()
		if (isMovable and isDragging) then
			movableFrame:EnableDrawLayer("BACKGROUND")
		end
	end)
	LossOfControlFrame:HookScript("OnShow", function()
		movableFrame:DisableDrawLayer("BACKGROUND")
	end)

	-- STEP 4:

	function movableLoC_UpdateVisibility(show)
		movableFrame:SetShown(show ~= false)
	end
	
	function movableLoC_UpdatePosition(enable)
		if (enable) then
			isMovable = true
			LossOfControlFrame:SetPoint("CENTER", movableFrame)
			if (isDragging) then
				movableFrame:EnableMouse(true)
				if (not LossOfControlFrame:IsShown()) then
					movableFrame:EnableDrawLayer("BACKGROUND")
				end
			end
		elseif (isMovable) then
			isMovable = false
			LossOfControlFrame:SetPoint("CENTER", UIParent)
			movableFrame:EnableMouse(false)
			movableFrame:DisableDrawLayer("BACKGROUND")
		end
	end
	
	function movableLoC_UpdateDragging(drag)
		if (drag) then
			isDragging = true
			if (isMovable) then
				movableFrame:EnableMouse(true)
				if (not LossOfControlFrame:IsShown()) then
					movableFrame:EnableDrawLayer("BACKGROUND")
				end
			end
		elseif (isDragging) then
			isDragging = false
			movableFrame:EnableMouse(false)
			movableFrame:DisableDrawLayer("BACKGROUND")
		end
	end
end

--------------------------------------------
-- Open/close bags
do
	-- As of WoW 4.1:
	--
	-- NUM_BAG_FRAMES          4
	-- NUM_CONTAINER_FRAMES   13
	-- NUM_BAG_SLOTS           4
	-- NUM_BANKBAGSLOTS        7
	--
	-- 0 == Backpack
	-- 1 == Bag 1 (1st bag to the left of backpack)
	-- 2 == Bag 2 (2nd bag to the left of backpack)
	-- 3 == Bag 3 (3rd bag to the left of backpack)
	-- 4 == Bag 4 (4th bag to the left of backpack)
	-- 5 == Bank bag 1
	-- 6 == Bank bag 2
	-- 7 == Bank bag 3
	-- 8 == Bank bag 4
	-- 9 == Bank bag 5
	-- 10 == Bank bag 6
	-- 11 == Bank bag 7
	--
	-- FrameXML/ContainerFrame.lua
	--	OpenAllBags(frame)
	--		- If at least one of first 5 bags (bag 0 == backpack, bags 1 to 4) is open, then do nothing. return.
	--		- If frame specified and frame name is not already saved then save frame name.
	--		- Call OpenBackPack()
	--		- Open bags 1 to 4.
	-- 	CloseAllBags(frame)
	--		- If frame specified and frame name == saved frame name then close bags 0 to 4. return.
	--		- If frame specified and frame name != saved frame name then do nothing. return.
	--		- If frame not specified then close bags 0 to 4.
	--
	-- AddOns/Blizzard_AuctionUI
	--	Does not open or close any bags.
	--
	-- AddOns/Blizzard_GuildBankUI
	--	Does not open or close any bags.
	--
	-- FrameXML/BankFrame.lua
	--	BankFrame_OnShow(self)
	--		- Calls OpenAllBags(self)
	--	BankFrame_OnHide(self)
	--		- Calls CloseAllBags(self)
	--		- Calls CloseBankBagFrames()
	--	CloseBankBagFrames()
	--		- Calls CloseBag(i) for each bank bag slot.
	--
	-- FrameXML/MerchantFrame.lua
	--	MerchantFrame_OnShow(self)
	--		- Calls OpenAllBags(self)
	--	MerchantFrame_OnHide(self)
	--		- Calls CloseAllBags(self)
	--
	-- FrameXML/TradeFrame.lua
	--	Does not open or close any bags.

	local events = {
		["BANKFRAME_OPENED"]      = {openAll = "bankOpenBags", backpack = "bankOpenBackpack", nobags = "bankOpenNoBags", bank = "bankOpenBankBags"},
		["BANKFRAME_CLOSED"]      = {close = "bankCloseBags"},

		["GUILDBANKFRAME_OPENED"] = GuildBankFrame_LoadUI and {openAll = "gbankOpenBags", backpack = "gbankOpenBackpack", nobags = "gbankOpenNoBags"},
		["GUILDBANKFRAME_CLOSED"] = GuildBankFrame_LoadUI and {close = "gbankCloseBags"},

		["MERCHANT_SHOW"]         = {openAll = "merchantOpenBags", backpack = "merchantOpenBackpack", nobags = "merchantOpenNoBags"},
		["MERCHANT_CLOSED"]       = {close = "merchantCloseBags"},

		["AUCTION_HOUSE_SHOW"]    = {openAll = "auctionOpenBags", backpack = "auctionOpenBackpack", nobags = "auctionOpenNoBags"},
		["AUCTION_HOUSE_CLOSED"]  = {close = "auctionCloseBags"},

		["TRADE_SHOW"]            = {openAll = "tradeOpenBags", backpack = "tradeOpenBackpack", nobags = "tradeOpenNoBags"},
		["TRADE_CLOSED"]          = {close = "tradeCloseBags"},

		["VOID_STORAGE_OPEN"]     = VoidStorageFrame_LoadUI and {openAll = "voidOpenBags", backpack = "voidOpenBackpack", nobags = "voidOpenNoBags"},
		["VOID_STORAGE_CLOSE"]    = VoidStorageFrame_LoadUI and {close = "voidCloseBags"},

		--["OBLITERUM_FORGE_SHOW"]     = ObliterumForgeFrame_LoadUI and {openAll = "obliterumOpenBags", backpack = "obliterumOpenBackpack", nobags = "obliterumOpenNoBags"},
		--["OBLITERUM_FORGE_CLOSE"]    = ObliterumForgeFrame_LoadUI and {close = "obliterumCloseBags"},
		
		--["SCRAPPING_MACHINE_SHOW"]     = ScrappingMachineFrame_LoadUI and {openAll = "scrappingOpenBags", backpack = "scrappingOpenBackpack", nobags = "scrappingOpenNoBags"},
		--["SCRAPPING_MACHINE_CLOSE"]    = ScrappingMachineFrame_LoadUI and {close = "scrappingCloseBags"},

	};

	local function onEvent(event)
		local data = events[event];

		if (
			module:getOption("disableBagAutomation")
			or C_CVar.GetCVarBool("combinedBags")
			or not data
		) then
			return;
		end
		
		
		if (data.openAll) then
			-- This is an open event.
			local openAllBags = module:getOption(data.openAll) ~= false
			local openBackpack = data.backpack and module:getOption(data.backpack)
			local openNoBags = data.nobags and module:getOption(data.nobags)
			local openBankBags = data.bank and module:getOption(data.bank) ~= false

			if (openAllBags or openBackpack or openNoBags) then
				-- First, close all bags.
				-- This also ensures that no bags are open if we need to call OpenAllBags()
				-- since that function will do nothing if at least one bag is already open.
				CloseAllBags();
				if (openBackpack) then
					-- Open just the backpack
					OpenBackpack();
				elseif (openAllBags) then
					-- Open all bags
					OpenAllBags();
				end
			end

			if (openBankBags) then
				-- Open all bank bags.
				-- The game closes these when the bank closes.
				for i = BACKPACK_CONTAINER+ITEM_INVENTORY_BANK_BAG_OFFSET+1, BACKPACK_CONTAINER+ITEM_INVENTORY_BANK_BAG_OFFSET+NUM_BANKBAGSLOTS, 1 do
				--for i = NUM_BAG_FRAMES + 1, NUM_CONTAINER_FRAMES, 1 do
					OpenBag(i);
				end
			end
		else
			-- This is a close event.
			if (data.close and module:getOption(data.close) ~= false) then
				-- Close all bags.
				CloseAllBags();
			end
		end
	end

	for event, data in pairs(events) do
		-- register all events, or just the ones that are in WoW Classic
		module:regEvent(event, onEvent);
	end
end

local function uncheckBagOption(optName)
	local value = false;
	module:setOption(optName, value, CT_SKIP_UPDATE_FUNC);
	if (type(module.frame) == "table") then
		local cb = module.frame.bagAutomationCollapsible[optName];
		cb:SetChecked(value);
	end
end

local function setBagOption(value, optName)
	if (not value) then
		return;
	end

	-- Bank
	if (optName == "bankOpenNoBags") then
		uncheckBagOption("bankOpenBackpack");
		uncheckBagOption("bankOpenBags");

	elseif (optName == "bankOpenBackpack") then
		uncheckBagOption("bankOpenNoBags");
		uncheckBagOption("bankOpenBags");

	elseif (optName == "bankOpenBags") then
		uncheckBagOption("bankOpenNoBags");
		uncheckBagOption("bankOpenBackpack");

	-- Guild bank
	elseif (optName == "gbankOpenNoBags") then
		uncheckBagOption("gbankOpenBackpack");
		uncheckBagOption("gbankOpenBags");

	elseif (optName == "gbankOpenBackpack") then
		uncheckBagOption("gbankOpenNoBags");
		uncheckBagOption("gbankOpenBags");

	elseif (optName == "gbankOpenBags") then
		uncheckBagOption("gbankOpenNoBags");
		uncheckBagOption("gbankOpenBackpack");

	-- Merchant
	elseif (optName == "merchantOpenNoBags") then
		uncheckBagOption("merchantOpenBackpack");
		uncheckBagOption("merchantOpenBags");

	elseif (optName == "merchantOpenBackpack") then
		uncheckBagOption("merchantOpenNoBags");
		uncheckBagOption("merchantOpenBags");

	elseif (optName == "merchantOpenBags") then
		uncheckBagOption("merchantOpenNoBags");
		uncheckBagOption("merchantOpenBackpack");

	-- Trade
	elseif (optName == "tradeOpenNoBags") then
		uncheckBagOption("tradeOpenBackpack");
		uncheckBagOption("tradeOpenBags");

	elseif (optName == "tradeOpenBackpack") then
		uncheckBagOption("tradeOpenNoBags");
		uncheckBagOption("tradeOpenBags");

	elseif (optName == "tradeOpenBags") then
		uncheckBagOption("tradeOpenNoBags");
		uncheckBagOption("tradeOpenBackpack");

	-- Auction
	elseif (optName == "auctionOpenNoBags") then
		uncheckBagOption("auctionOpenBackpack");
		uncheckBagOption("auctionOpenBags");

	elseif (optName == "auctionOpenBackpack") then
		uncheckBagOption("auctionOpenNoBags");
		uncheckBagOption("auctionOpenBags");

	elseif (optName == "auctionOpenBags") then
		uncheckBagOption("auctionOpenBackpack");
		uncheckBagOption("auctionOpenNoBags");

	-- Void
	elseif (optName == "voidOpenNoBags") then
		uncheckBagOption("voidOpenBackpack");
		uncheckBagOption("voidOpenBags");

	elseif (optName == "voidOpenBackpack") then
		uncheckBagOption("voidOpenNoBags");
		uncheckBagOption("voidOpenBags");

	elseif (optName == "voidOpenBags") then
		uncheckBagOption("voidOpenNoBags");
		uncheckBagOption("voidOpenBackpack");

	-- Obliterum
	elseif (optName == "obliterumOpenNoBags") then
		uncheckBagOption("obliterumOpenBackpack");
		uncheckBagOption("obliterumOpenBags");

	elseif (optName == "obliterumOpenBackpack") then
		uncheckBagOption("obliterumOpenNoBags");
		uncheckBagOption("obliterumOpenBags");

	elseif (optName == "obliterumOpenBags") then
		uncheckBagOption("obliterumOpenNoBags");
		uncheckBagOption("obliterumOpenBackpack");
		
	-- Scrapping Machine
	elseif (optName == "scrappingOpenNoBags") then
		uncheckBagOption("scrappingOpenBackpack");
		uncheckBagOption("scrappingOpenBags");

	elseif (optName == "scrappingOpenBackpack") then
		uncheckBagOption("scrappingOpenNoBags");
		uncheckBagOption("scrappingOpenBags");

	elseif (optName == "scrappingOpenBags") then
		uncheckBagOption("scrappingOpenNoBags");
		uncheckBagOption("scrappingOpenBackpack");
	end
end

--~ if ContainerFrameMixin then
--~ 	-- To prevent taint in WoW 10.0.0
--~ 	
--~ 	-- Remove ContainerFrameItemButtonMixin:SetBagID() before it ever gets called, but only when the user is not combining bags
--~ 	module:regEvent("PLAYER_LOGIN", function()
--~ 		if not (module:getOption("disableBagAutomation") or C_CVar.GetCVarBool("combinedBags")) then
--~ 			for i=1, NUM_CONTAINER_FRAMES do
--~ 				for j=1, 36 do
--~ 					local frame = _G["ContainerFrame"..i.."Item"..j]
--~ 					if frame then
--~ 						frame.SetBagID = nop
--~ 					end
--~ 				end
--~ 			end
--~ 		end
--~ 	end)
--~ 	
--~ 	-- Encouraging the user to reload the UI after turning combined bags on and off.
--~ 	local needButton = true
--~ 	EventRegistry:RegisterFrameEventAndCallback("USE_COMBINED_BAGS_CHANGED", function()
--~ 		if needButton then
--~ 			needButton = false
--~ 			local btn = CreateFrame("Button", nil, SettingsPanel, "SecureActionButtonTemplate, UIPanelButtonTemplate")
--~ 			btn:RegisterForClicks("AnyDown", "AnyUp")
--~ 			btn:SetAttribute("type", "macro")
--~ 			btn:SetAttribute("macrotext", "/reload")
--~ 			btn:SetSize(SettingsPanel.CloseButton:GetSize())
--~ 			btn:SetPoint("RIGHT", SettingsPanel.CloseButton, "LEFT", -5, 0)
--~ 			btn:SetText(RELOADUI)
--~ 			btn.tooltipText = "CT_Core: Reload required for addon compatibility"
--~ 		end
--~ 	end)
--~ end
	
--------------------------------------------
-- Block duel requests

local duelsBlocked;

local function duelRequested(event, player)
	if (duelsBlocked) then
		if (module:getOption("blockDuelsMessage")) then
			print(format("Blocked duel request from %s.", tostring(player or UNKNOWN)));
		end
		CancelDuel();
		StaticPopup_Hide("DUEL_REQUESTED");
	end
end

module:regEvent("DUEL_REQUESTED", duelRequested);

local function configureDuelBlockOption(value)
	if (value) then
		duelsBlocked = true;
		UIParent:UnregisterEvent("DUEL_REQUESTED");
	else
		if (duelsBlocked) then
			duelsBlocked = false;
			UIParent:RegisterEvent("DUEL_REQUESTED");
		end
	end
end

--------------------------------------------
-- Objectives window

if not EditModeManagerFrame then

	-- prior to WoW 10.x

	local initDone;
	local watchFrame;
	local playerLoggedIn;
	local resizedWidth;
	local resizedHeight;
	local hookedFunctions;
	local isResizing;
	local isEnabled;
	local anchorTopLeft;

	local frameSetPoint;
	local frameSetParent;
	local frameClearAllPoints;
	local frameSetAllPoints;

	-- Blizzard values (refer to WatchFrame.lua)
	local blizzard_ExpandedWidth1 = 204;

	local blizzard_ExpandedWidth2 = 306;

	-- Space on left and right sides of the game's WatchFrame (between us and them)
	local spacingLeft1 = 31; -- when showing objectives (need room for objective button)
	local spacingLeft2 = 7;  -- when not showing objectives

	-- Size of our frame when collapsed
	local collapsedHeight = 27;
	local collapsedWidth = 0 + 7;

	-- Local copies of option values
	local opt_watchframeEnabled;
	local opt_watchframeLocked;
	local opt_watchframeShowBorder;
	local opt_watchframeBackground;
	local opt_watchframeClamped;
	local opt_watchframeChangeWidth;
	local opt_watchframeScale;
	local opt_watchframeAddMinimizeButton;

	-- set to true when the player presses a custom minimize button in classic (mimicking retail functionality)
	local classicIsMinimized = false;

	local function getBlizzardExpandedWidth()
		local width;
		if (module:getGameVersion() >= 8) then
			width = 235;
		else
			width = 195.4;
		end
		return width;
	end

	local function getInnerWidth(ignoreChangeOption)
		local width;
		if (not opt_watchframeChangeWidth or ignoreChangeOption) then
			width = getBlizzardExpandedWidth();
		else
			width = resizedWidth;
			if (WatchFrame.showObjectives) then
				width = width - spacingLeft1;
			else
				width = width - spacingLeft2;
			end
		end
		return width;
	end

	local function getOuterWidth()
		local width;
		if (not opt_watchframeChangeWidth) then
			width = getInnerWidth();
			if (WatchFrame.showObjectives) then
				width = width + spacingLeft1;
			else
				width = width + spacingLeft2;
			end
		else
			width = resizedWidth;
		end
		return width;
	end

	local function updateClamping()
		if (opt_watchframeShowBorder) then
			-- Clear the insets so that border can touch edge of screen.
			watchFrame:SetClampRectInsets(0, 0, 0, 0);
		else
			-- Change insets so that borderless window can be dragged right to the edge of the screen.
			watchFrame:SetClampRectInsets(5, -5, -5, 5);
		end
		watchFrame:SetClampedToScreen(opt_watchframeClamped);
		WatchFrame:SetClampedToScreen(false);
	end

	local function updateBorder()
		-- Should call udpateClamping() after calling this.
		local alpha;
		if (opt_watchframeShowBorder) then
			alpha = 1;
		else
			alpha = 0;
		end
		watchFrame:SetBackdropBorderColor(1, 1, 1, alpha);
	end

	local function updateBackground()
		watchFrame:SetBackdropColor(unpack(opt_watchframeBackground));
	end

	local function updateLocked()
		-- Show/hide the resize button
		if (opt_watchframeLocked) then
			watchFrame.resizeBL:Hide();
			watchFrame.resizeBR:Hide();
		else
			if ( WatchFrame.collapsed and WatchFrame.userCollapsed ) then
				watchFrame.resizeBL:Hide();
				watchFrame.resizeBR:Hide();
			else
				watchFrame.resizeBL:Show();
				watchFrame.resizeBR:Show();
			end
		end
		watchFrame:EnableMouse(not opt_watchframeLocked);
	end
	
	local function updateScale()
		-- make the font bigger or smaller
		if (opt_watchframeEnabled and opt_watchframeScale) then
			watchFrame:SetScale(opt_watchframeScale / 100);
		else
			watchFrame:SetScale(1);
		end
	end
		
	local function updateVisibility()
		-- Show our watchFrame if there is at least one thing being tracked (which is the case
		-- when the WatchFrameHeader is shown.
		-- Also show our watchFrame if at least one auto quest pop up frame is shown, even if
		-- there are no objectives being tracked. These pop up frames have a height of 82.
		if ((not opt_watchframeAddMinimizeButton or not classicIsMinimized) and (WatchFrame:IsShown() or ((GetNumAutoQuestPopUps and GetNumAutoQuestPopUps()) or 0) > 0)) then	-- nil check because there are no auto-popups in Classic
			watchFrame:Show();
		else
			-- Blizzard hid their WatchFrame so hide ours also; or the player pressed a custom minimize button on classic (mimicking retail functionality)
			watchFrame:Hide();
		end
	end
				
	local function watchFrame_Update()
		if (opt_watchframeEnabled) then
			local width, height;
			local bwidth;

			frameSetParent(WatchFrame, CT_WatchFrame);
			frameClearAllPoints(WatchFrame);
			frameSetPoint(WatchFrame, "TOPRIGHT", CT_WatchFrame, "TOPRIGHT", 0, 0);
			frameSetPoint(WatchFrame, "BOTTOMRIGHT", CT_WatchFrame, "BOTTOMRIGHT", 0, 0);

			if (WatchFrame.collapsed) then
				if (isResizing) then
					width = resizedWidth;
					height = resizedHeight;
					bwidth = getInnerWidth();
				else
					if ( WatchFrame.collapsed and not WatchFrame.userCollapsed ) then
						width = getOuterWidth();
						height = resizedHeight;
						bwidth = getInnerWidth();
					else
						width = collapsedWidth;
						height = collapsedHeight;
						bwidth = WATCHFRAME_COLLAPSEDWIDTH;
					end
				end
			else
				width = getOuterWidth();
				height = resizedHeight;
				bwidth = getInnerWidth();
			end

			WatchFrame:SetWidth(bwidth);

			watchFrame:SetWidth(width);
			watchFrame:SetHeight(height);

			if (CT_Core_MinimizeWatchFrameButton) then
				if (opt_watchframeAddMinimizeButton) then
					CT_Core_MinimizeWatchFrameButton:Show();	-- adds a custom minimize button on classic only, mimicking retail behaviour
				else
					CT_Core_MinimizeWatchFrameButton:Hide();
				end
			end

			updateVisibility();
			updateBackground();
			updateBorder();
			updateClamping();
			updateLocked();
			updateScale();
		end
	end

	local function resizeUpdate(self, elapsed)
		-- OnUpdate routine called while resizing
		self.time = ( self.time or 0 ) - elapsed;
		if ( self.time > 0 ) then
			return;
		else
			self.time = 0.02;
		end

		local height, width;
		local x, y = GetCursorPosition();

		local xvalue, yvalue;
		if (self.scale == 0) then
			xvalue = 0;
			yvalue = 0;
		else
			xvalue = x / self.scale;
			yvalue = y / self.scale;
		end
		if (anchorTopLeft) then
			width = xvalue - self.left + self.xoff;  -- when using a bottom right resize button
		else
			width = self.right - xvalue + self.xoff;  -- when using a bottom left resize button
		end
		height = self.top - yvalue + self.yoff;

		local minHeight = collapsedHeight;
		local minWidth = collapsedWidth;

		if (WatchFrame.showObjectives) then
			minWidth = minWidth + 20;
		end

		if (opt_watchframeChangeWidth) then
			if (width < minWidth) then
				width = minWidth;
			end
		else
			width = getOuterWidth();
		end

		if ( height < minHeight ) then
			height = minHeight;
		end

		resizedWidth = width;
		resizedHeight = height;

		watchFrame_Update();
	end

	local function startResizing(self)
		-- Begin resizing the frame
		if (isResizing) then
			return;
		end

		local x, y = GetCursorPosition();
		local scale = UIParent:GetScale();

		if (anchorTopLeft) then
			self.left = self.parent:GetLeft();  -- when using a bottom right resize button
		else
			self.right = self.parent:GetRight();  -- when using a bottom left resize button
		end
		self.centerX, self.centerY = self.parent:GetCenter();
		self.top = self.parent:GetTop();
		self.bottom = self.parent:GetBottom();

		local xvalue, yvalue;
		if (scale == 0) then
			xvalue = 0;
			yvalue = 0;
		else
			xvalue = x / scale;
			yvalue = y / scale;
		end
		self.yoff = yvalue - self.parent:GetBottom();
		if (anchorTopLeft) then
			self.xoff = self.parent:GetRight() - xvalue;  -- when using a bottom right resize button
		else
			self.xoff = xvalue - self.parent:GetLeft();  -- when using a bottom left resize button
		end

		self.scale = scale;
		self:SetScript("OnUpdate", resizeUpdate);
		self.background:SetVertexColor(1, 1, 1);

		resizedWidth = self.parent:GetWidth();
		resizedHeight = self.parent:GetHeight();

		isResizing = 1;

		GameTooltip:Hide();
	end

	local function stopResizing(self)
		-- Stop resizing the frame
		if (not isResizing) then
			return;
		end

		resizeUpdate(self, 1);

		local height = self.parent:GetHeight();
		local width = self.parent:GetWidth();

		module:setOption("watchWidth", width);
		module:setOption("watchHeight", height);

		resizedWidth = width;
		resizedHeight = height;

		self.center = nil;
		self.scale = nil;
		self:SetScript("OnUpdate", nil);
		self.background:SetVertexColor(1, 0.82, 0);

		if ( self:IsMouseOver() ) then
			self:GetScript("OnEnter")(self);
		else
			self:GetScript("OnLeave")(self);
		end

		isResizing = nil;

		watchFrame_Update();
	end

	local function hookStuff()
		if (hookedFunctions) then
			return;
		end

		hooksecurefunc(WatchFrame, "SetPoint", function(frame, ...)
			if (opt_watchframeEnabled) then
				watchFrame_Update();
			end
		end);

		hooksecurefunc(WatchFrame, "SetAllPoints", function(frame, ...)
			if (opt_watchframeEnabled) then
				watchFrame_Update();
			end
		end);

		hookedFunctions = true;
	end

	local function updateEnabled()
		if (opt_watchframeEnabled) then
			-- Enable our frame
			isEnabled = true;
			hookStuff();
			watchFrame_Update();
		else
			if (isEnabled) then
				watchFrame:Hide();
				if (CT_Core_MinimizeWatchFrameButton) then
					CT_Core_MinimizeWatchFrameButton:Hide();	-- hides the custom minimize button on classic only
				end
				-- Restore Blizzard's WatchFrame
				if (module:getGameVersion() >= 3) then
					WatchFrame:SetWidth(getBlizzardExpandedWidth());
				else
					QuestWatch_Update();
				end
				frameSetParent(WatchFrame, UIParent);
				WatchFrame:ClearAllPoints();
				WatchFrame:SetPoint("TOPRIGHT", MiniMapCluster, "BOTTOMRIGHT", ((MultiBarRight:IsShown() and -52) and MultiBarLeft:IsShown() and -95) or 0);	-- this is probably not even required because of UIParent_ManageFramePositions()
				WatchFrame:SetClampedToScreen(true);
				UIParent_ManageFramePositions();
			end
		end
	end

	local pointText = {"BOTTOMLEFT", "BOTTOMRIGHT", "TOPLEFT", "TOPRIGHT", "LEFT"};

	local function anchorOurFrame(topLeft, noSave)
	
		-- Set the anchor point of our frame
		local frame = CT_WatchFrame;
		local oldScale = frame:GetScale() or 1;
		local xOffset, yOffset;
		local anchorX, anchorY, anchorP;
		local relativeP;
		local centerX, centerY = UIParent:GetCenter();

		anchorTopLeft = topLeft;

		if (topLeft) then
			-- Anchor the top left corner of our frame to UIParent
			anchorY = frame:GetTop() or 0;
			anchorP = 3;  -- TOPLEFT
			anchorX = frame:GetLeft() or 0;
		else
			-- Anchor the top right corner of our frame to UIParent
			anchorY = frame:GetTop() or 0;
			anchorP = 4;  -- TOPRIGHT
			anchorX = frame:GetRight() or 0;
		end

		local centervalue, uiparentvalue;

		if (oldScale == 0) then
			centervalue = 0;
			uiparentvalue = 0;
		else
			centervalue = centerY / oldScale;
			uiparentvalue = UIParent:GetTop() / oldScale;
		end
		if (anchorY <= centervalue) then
			yOffset = anchorY;
			relativeP = 1;
		else
			yOffset = anchorY - uiparentvalue;
			relativeP = 3;
		end

		if (oldScale == 0) then
			centervalue = 0;
			uiparentvalue = 0;
		else
			centervalue = centerX / oldScale;
			uiparentvalue = UIParent:GetRight() / oldScale;
		end
		if (anchorX <= centervalue) then
			xOffset = anchorX;
		else
			xOffset = anchorX - uiparentvalue;
			relativeP = relativeP + 1;
		end
		
		frame:ClearAllPoints();
		frame:SetPoint(pointText[anchorP], "UIParent", pointText[relativeP], xOffset, yOffset);
		if (not noSave) then
			-- setting the scale to 1 during the save is a hack to change how CT_Library behaves
			frame:SetScale(1);
			module:stopMovable("WATCHFRAME");  -- stops moving and saves the current anchor point; except when noSave flag is set which only happens when starting up the game
			frame:SetScale((module:getOption("CTCore_WatchFrameScale") or 100)/100);
		end
	end

	module.resetWatchFramePosition = function()
		if (not opt_watchframeEnabled) then
			return;
		end
		local width = watchFrame:GetWidth() or frameWidth;
		local height = watchFrame:GetHeight() or frameHeight;
		module:resetMovable("WATCHFRAME");
		watchFrame:ClearAllPoints();
		watchFrame:SetPoint("TOPRIGHT", UIParent, "CENTER", width/2, height/2);
		anchorOurFrame();  -- change the anchor point and save it
	end;

	-- Create the frame
	local function watchFrameSkeleton()
		return "frame#r:0:75#st:LOW", {
			"backdrop#tooltip",

			["button#s:16:16#i:resizeBL#bl"] = {
				"texture#s:18:18#br:0:5#i:background#n:CT_Core_QuestFrame_resizeBL#Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up",
				["onenter"] = function(self)
					if ( isResizing ) then return; end
					if (module:getOption("watchframeShowTooltip") ~= false) then
						module:displayPredefinedTooltip(self, "RESIZE");
					end
					self.background:SetTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight");
					self.background:SetVertexColor(1,1,1);
				end,
				["onleave"] = function(self)
					if ( isResizing ) then return; end
					self.background:SetTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up");
					self.background:SetVertexColor(1,1,1);
				end,
				["onload"] = function(self)
					self:SetFrameLevel(self:GetFrameLevel() + 2);
					SetClampedTextureRotation(self.background, 90);
					self.background:SetVertexColor(1,1,1);
				end,
				["onmousedown"] = function(self)
					anchorOurFrame(false, true);
					startResizing(self);
					self.background:SetTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down");
					self.background:SetVertexColor(1,1,1);
				end,
				["onmouseup"] = function(self)
					stopResizing(self);
					anchorOurFrame(false);
					self.background:SetTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up");
					self.background:SetVertexColor(1,1,1);
				end,
			},

			["button#s:16:16#i:resizeBR#br"] = {
				"texture#s:18:18#br:-5:5#i:background#Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up",
				["onenter"] = function(self)
					if ( isResizing ) then return; end
					if (module:getOption("watchframeShowTooltip") ~= false) then
						module:displayPredefinedTooltip(self, "RESIZE");
					end
					self.background:SetTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight");
					self.background:SetVertexColor(1,1,1);
				end,
				["onleave"] = function(self)
					if ( isResizing ) then return; end
					self.background:SetVertexColor(1, 1, 1);
					self.background:SetTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up");
					self.background:SetVertexColor(1,1,1);
				end,
				["onload"] = function(self)
					self:SetFrameLevel(self:GetFrameLevel() + 2);
					self.background:SetVertexColor(1, 1, 1);
				end,
				["onmousedown"] = function(self)
					anchorOurFrame(true, true);
					startResizing(self);
					self.background:SetVertexColor(1, 1, 1);
					self.background:SetTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down");
				end,
				["onmouseup"] = function(self)
					stopResizing(self);
					anchorOurFrame(false);
					self.background:SetVertexColor(1, 1, 1);
					self.background:SetTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up");
				end,
			},

			["onload"] = function(self)
				if (WatchFrame == QuestWatchFrame) then	-- classic
					module:getFrame(
					{
						["button#s:16:16#n:CT_Core_MinimizeWatchFrameButton#tl:tr:CT_WatchFrame"] = 
						{
							["onload"] = function(button)
								button:SetNormalTexture("Interface\\Buttons\\UI-Panel-QuestHideButton");
								button:GetNormalTexture():SetTexCoord(0.0, 0.5, 0.5, 1.0);
								button:SetPushedTexture("Interface\\Buttons\\UI-Panel-QuestHideButton");
								button:GetPushedTexture():SetTexCoord(0.5, 1.0, 0.5, 1.0);
								button:SetHighlightTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Highlight");
								button:GetHighlightTexture():SetBlendMode("ADD");
								button:SetDisabledTexture("Interface\\Buttons\\UI-Panel-QuestHideButton-disabled");
								button:Hide();
								button.fs = button:CreateFontString(nil, "BACKGROUND", "GameFontNormalSmall");
								button.fs:SetPoint("RIGHT", button, "LEFT", -2, 0);
								button.fs:SetText(OBJECTIVES_TRACKER_LABEL);
								button.fs:Hide();
							end;
							["onclick"] = function(button)
								if (CT_WatchFrame:IsShown()) then
									classicIsMinimized = true;
									button:GetNormalTexture():SetTexCoord(0.0, 0.5, 0.0, 0.5);
									button:GetPushedTexture():SetTexCoord(0.5, 1.0, 0.0, 0.5);
									button.fs:Show();
								else
									classicIsMinimized = false;
									button:GetNormalTexture():SetTexCoord(0.0, 0.5, 0.5, 1.0);
									button:GetPushedTexture():SetTexCoord(0.5, 1.0, 0.5, 1.0);
									button.fs:Hide();
								end
								updateVisibility();
								PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON);
							end
						},
					},
					UIParent);
				end
			end,

			["onenter"] = function(self)
				if ( isResizing ) then return; end
				if (module:getOption("watchframeShowTooltip") ~= false) then
					module:displayTooltip(self, "Left-click to drag.");
				end
			end,

			["onmousedown"] = function(self, button)
				if ( button == "LeftButton" ) then
					module:moveMovable("WATCHFRAME");
					GameTooltip:Hide();
				end
			end,

			["onmouseup"] = function(self, button)
				if ( button == "LeftButton" ) then
					self:StopMovingOrSizing();  -- Stops moving and lets the game assign an anchor point
					anchorOurFrame();  -- Change the anchor point and save it
					if ( self:IsMouseOver() ) then
						self:GetScript("OnEnter")(self);
					else
						self:GetScript("OnLeave")(self);
					end
				end
			end,

			["onevent"] = function(self, event)
				if (event == "PLAYER_ENTERING_WORLD") then
					playerLoggedIn = 1;
					-- We've delayed the enabling of the options until PLAYER_LOGIN time
					-- to allow enough time for the UIParent scale to be set by Blizzard,
					-- since it will be needed in anchorOurFrame(). If the scale isn't set
					-- then we will have problems restoring the saved frame position properly.
					opt_watchframeEnabled = module:getOption("watchframeEnabled");
					if (opt_watchframeEnabled) then
						module.watchframeInit();
					end
					updateEnabled();
				end
			end,
		};
	end

	watchFrame = module:getFrame(watchFrameSkeleton, nil, "CT_WatchFrame");
	module.watchFrame = watchFrame;

	opt_watchframeBackground = {0, 0, 0, 0};
	watchFrame:SetBackdropColor(unpack(opt_watchframeBackground));

	-- Save methods to be used when we position the WatchFrame.
	-- This prevents other addons from trying to block repositioning
	-- of the frame via hooks to :SetPoint().
	frameSetPoint = watchFrame.SetPoint;
	frameSetParent = watchFrame.SetParent;
	frameClearAllPoints = watchFrame.ClearAllPoints;
	frameSetAllPoints = watchFrame.SetAllPoints;

	watchFrame:RegisterEvent("PLAYER_LOGIN");
	watchFrame:RegisterEvent("PLAYER_ENTERING_WORLD");

	-- Initialize
	module.watchframeInit = function()
		if (initDone) then
			return;
		end
		initDone = true;

		local top = WatchFrame:GetTop();
		local bottom = WatchFrame:GetBottom();
		local left = WatchFrame:GetLeft();
		local right = WatchFrame:GetRight();
		local scale = WatchFrame:GetEffectiveScale();

		resizedWidth = module:getOption("watchWidth");
		if (not resizedWidth or not opt_watchframeChangeWidth) then
			resizedWidth = getOuterWidth();
			if (not resizedWidth) then
				if (GetCVar("watchFrameWidth") == "1") then
					resizedWidth = 306;
				else
					resizedWidth = 204;
				end
			end
		end

		resizedHeight = module:getOption("watchHeight");
		if (not resizedHeight) then
			if (top and bot) then
				resizedHeight = top - bot;
			end
			if (not resizedHeight or resizedHeight < 50) then
				resizedHeight = 400;
			end
		end

		-- Position the frame before we make the frame movable.
		watchFrame:ClearAllPoints();
		watchFrame:SetPoint("TOPRIGHT", UIParent, "BOTTOMLEFT", right or UIParent:GetRight(), top or UIParent:GetTop());
		watchFrame:SetWidth(resizedWidth);
		watchFrame:SetHeight(resizedHeight);
		watchFrame:Show();

		-- Make frame movable.
		module:registerMovable("WATCHFRAME", watchFrame, true);
		
		-- Ensure our frame is anchored using a top right anchor point.
		anchorOurFrame(false, true);

		resizedWidth = watchFrame:GetWidth();
		resizedHeight = watchFrame:GetHeight();
	end

	-- Option functions
	module.watchframeEnabled = function(value)
		if (not playerLoggedIn) then
			return;
		else
			-- User clicked checkbox
			opt_watchframeEnabled = value;
			if (opt_watchframeEnabled) then
				module.watchframeInit();
			end
			updateEnabled();
		end
	end

	module.watchframeLocked = function(value)
		-- When unlocked, user can drag and resize the frame.
		opt_watchframeLocked = (value ~= false);
		if (not opt_watchframeEnabled) then
			return;
		end
		updateLocked();
	end

	module.watchframeShowBorder = function(value)
		-- Show/hide the frame's border
		opt_watchframeShowBorder = value;
		if (not opt_watchframeEnabled) then
			return;
		end
		updateBorder();
	end

	module.watchframeClamped = function(value)
		-- Allow or prevent user dragging frame off screen.
		opt_watchframeClamped = (value ~= false);
		if (not opt_watchframeEnabled) then
			return;
		end
		updateClamping();
		updateBorder();
	end

	module.watchframeBackground = function(value)
		if (not value) then
			value = {0, 0, 0, 0};
		end
		opt_watchframeBackground = value;
		if (not opt_watchframeEnabled) then
			return;
		end
		updateBackground();
	end

	module.watchframeChangeWidth = function(value)
		local oldValue = opt_watchframeChangeWidth;
		opt_watchframeChangeWidth = value;
		if (not opt_watchframeEnabled) then
			return;
		end
		watchFrame_Update();
	end
	
	module.watchframeChangeScale = function(value)
		if (not value) then
			value = 100
		end
		opt_watchframeScale = value;
		-- do this even when not enabled!
		updateScale();
	end
	
	module.watchframeAddMinimizeButton = function(value)
		opt_watchframeAddMinimizeButton = (value ~= false);
		if (not opt_watchframeEnabled) then
			return;
		end
		watchFrame_Update();
	end
end

--------------------------------------------
-- Movable alternate power bar

local powerbaraltAnchorFrame;
local powerbaraltEnabled;
local powerbaraltMovable;
local powerbaraltShowAnchor;

local powerbaralt__createAnchorFrame;

local powerbaralt_toggleStatus, powerbaralt_toggleMovable, powerbaralt_toggleAnchor;	-- defined within the conditional chunk below

if PlayerPowerBarAlt and not EncounterBar then
	
	-- this is now essentially permanently disabled; PlayerPowerBarAlt was introduced in WoW 4.0 and then became part of the movable EncounterBar in WoW 10.0
	
	local function powerbaralt_reanchor()
		PlayerPowerBarAlt:ClearAllPoints();
		PlayerPowerBarAlt:SetPoint("CENTER", powerbaraltAnchorFrame, "CENTER", 0, 0);
	end

	local function powerbaralt_resetPosition()
		local self = powerbaraltAnchorFrame;
		self:ClearAllPoints();
		self:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, 150);
	end

	module.powerbaralt_resetPosition = powerbaralt_resetPosition;

	local function powerbaralt_updateAnchorVisibility()
		local self = powerbaraltAnchorFrame;
		if (not self) then
			powerbaralt__createAnchorFrame();
			self = powerbaraltAnchorFrame;
		end
		if (powerbaraltEnabled and powerbaraltMovable) then
			if (PlayerPowerBarAlt:IsShown()) then
				self:Hide();
			else
				if (powerbaraltShowAnchor) then
					self:Show();
				else
					self:Hide();
				end
			end
		else
			self:Hide();
		end
	end

	local function powerbaralt_isModifiedButton()
		local modifier = module:getOption("powerbaraltModifier") or 1;
		local alt = IsAltKeyDown();
		local control = IsControlKeyDown();
		local shift = IsShiftKeyDown();

		if (modifier == 1) then
			return not alt and not control and not shift;
		elseif (modifier == 2 and alt) then
			return not control and not shift;
		elseif (modifier == 3 and control) then
			return not alt and not shift;
		elseif (modifier == 4 and shift) then
			return not alt and not control;
		else
			return false;
		end
	end

	local function powerbaralt_onMouseDown(self, button)
		if (powerbaraltEnabled and powerbaraltMovable) then
			if ( button == "LeftButton" and powerbaralt_isModifiedButton() ) then
				module:moveMovable(self.movable);
			end
		end
	end

	local function powerbaralt_onMouseUp(self, button)
		if (powerbaraltEnabled and powerbaraltMovable) then
			if ( button == "LeftButton" ) then
				module:stopMovable(self.movable);
			elseif ( button == "RightButton" and powerbaralt_isModifiedButton() ) then
				powerbaralt_resetPosition();
				module:stopMovable(self.movable);
			end
		end
	end

	local function powerbaralt_UIParent_ManageFramePositions()
		if (powerbaraltEnabled) then
			powerbaralt_reanchor();
		end
	end

	local function powerbaralt_onEvent(self, event, arg1, ...)
		if (event == "PLAYER_LOGIN") then
			PlayerPowerBarAlt:HookScript("OnMouseDown",
				function(self, button)
					powerbaralt_onMouseDown(powerbaraltAnchorFrame, button);
				end
			);
			PlayerPowerBarAlt:HookScript("OnMouseUp",
				function(self, button)
					powerbaralt_onMouseUp(powerbaraltAnchorFrame, button);
				end
			);
			PlayerPowerBarAlt:HookScript("OnShow",
				function(self)
					powerbaralt_updateAnchorVisibility();
				end
			);
			PlayerPowerBarAlt:HookScript("OnHide",
				function(self)
					powerbaralt_updateAnchorVisibility();
				end
			);

			hooksecurefunc("UIParent_ManageFramePositions", powerbaralt_UIParent_ManageFramePositions);
			-- By now GetCVar("uiScale") has a value, so if Blizzard_CombatLog is already loaded
			-- then it won't cause an error when it tries to multiply by the uiScale.
			UIParent_ManageFramePositions();
		end
	end
	
	local function powerbaralt_onEnter(self)
		module:displayPredefinedTooltip(self, "DRAG")
	end

	local function powerbaralt_createAnchorFrame()
		local movable = "PowerBarAltAnchor";

		local self = CreateFrame("Button", "CT_Core_PlayerPowerBarAltAnchorFrame", UIParent);

		powerbaraltAnchorFrame = self;

		self:SetWidth(110);
		self:SetHeight(32);
		powerbaralt_resetPosition();

		local fs = self:CreateFontString(nil, "OVERLAY", "GameFontHighlight");
		fs:SetWidth(self:GetWidth());
		fs:SetHeight(self:GetHeight());
		fs:SetPoint("TOPLEFT", self, "TOPLEFT", 0, 0);
		fs:Show();
		fs:SetText("Alternate Power\nBar anchor");

		local tex = self:CreateTexture(nil, "ARTWORK");
		self.tex = tex;
		tex:SetPoint("TOPLEFT", self);
		tex:SetPoint("BOTTOMRIGHT", self);
		tex:Show();
		tex:SetTexture("Interface\\Tooltips\\UI-Tooltip-Background");
		tex:SetVertexColor(0.7, 0.7, 0.7, 0.8);

		self:SetScript("OnMouseDown", powerbaralt_onMouseDown)
		self:SetScript("OnMouseUp", powerbaralt_onMouseUp)
		self:SetScript("OnEvent", powerbaralt_onEvent)
		self:SetScript("OnEnter", powerbaralt_onEnter)

		module:registerMovable(movable, self, true);
		self.movable = movable;

		self:RegisterEvent("PLAYER_LOGIN");
		self:Hide();
	end

	powerbaralt__createAnchorFrame = powerbaralt_createAnchorFrame;

	function powerbaralt_toggleStatus(enable)	-- local
		-- Use custom bar position
		powerbaraltEnabled = enable;
		powerbaralt_updateAnchorVisibility();
		if (powerbaraltEnabled) then
			powerbaralt_reanchor();
		else
			-- When entering the world for the FIRST time after starting the game, GetCVar("uiScale")
			-- returns nil when CT_Core loads (ie. at ADDON_LOADED event time). The game hasn't had
			-- time to update the setting yet. This is also the case for GetCVarBool("scriptErrors").
			--
			-- When the Blizzard_CombatLog addon gets loaded, it hooks the FCF_DockUpdate function
			-- which gets called by the UIParent_ManageFramePositions function in UIParent.lua.
			--
			-- If there is an addon that loads before CT_Core and causes the Blizzard_CombatLog addon
			-- to load, then we want to avoid calling UIParent_ManageFramePositions while GetCVar("uiScale")
			-- is nil. If we do call it when the uiScale is nil, then the Blizzard_CombatLog code will cause an error
			-- when it gets to the Blizzard_CombatLog_AdjustCombatLogHeight() function in Blizzard_CombatLog.lua.
			-- That code tries to multiply by GetCVar("uiScale"), and since it is still nil then there will
			-- be an error.
			--
			-- Blizzard's code won't display the error (see BasicControls.xml) because GetCVarBool("scriptErrors")
			-- is still nil when CT_Core loads. The user won't see the error unless they have an addon that loads
			-- before CT_Core and traps and displays errors.
			--
			-- To avoid this error we will only call UIParent_ManageFramePositions() when the uiScale has
			-- a value. This is the place in this addon where UIParent_ManageFramePositions() may get called
			-- at ADDON_LOADED time by CT_Libary (during the "init" options step).

			PlayerPowerBarAlt:ClearAllPoints();
			if (GetCVar("uiScale")) then
				UIParent_ManageFramePositions();
			end
		end
	end

	function powerbaralt_toggleMovable(movable)	-- local
		-- Unlock bar
		powerbaraltMovable = movable;
		powerbaralt_updateAnchorVisibility();
	end

	function powerbaralt_toggleAnchor(show)		-- local
		-- Show anchor when bar is hidden
		powerbaraltShowAnchor = show;
		powerbaralt_updateAnchorVisibility();
	end
end


--------------------------------------------
-- Camera Max Distance (classic only)


if InterfaceOptionsCameraPanelMaxDistanceSlider then
	
	-- bugfix so the CVar doesn't get reduced to 2.0 when the Interface Options initialize
	local slider = InterfaceOptionsCameraPanelMaxDistanceSlider
	if slider then
		oldFunc = slider.SetMinMaxValues
		function slider:SetMinMaxValues(minVal, maxVal)
			oldFunc(slider, minVal, max(maxVal, 2.6)) 
		end
	end

	-- restoring max distance after playing with addons disabled
	local function fixCameraOnAddonLoaded()
		local ctCameraDistance = module:getOption("cameraDistanceMaxZoomFactor")
		local cvarCameraDistance = tonumber(GetCVar("cameraDistanceMaxZoomFactor"))
		if ctCameraDistance and cvarCameraDistance and ctCameraDistance > cvarCameraDistance then
			module:regEvent("PLAYER_LOGIN", function()
				SetCVar("cameraDistanceMaxZoomFactor", ctCameraDistance)
			end)
		elseif cvarCameraDistance and cvarCameraDistance > 2.0 then
			module:setOption("cameraDistanceMaxZoomFactor", cvarCameraDistance)
		end
		module:unregEvent("ADDON_LOADED", fixCameraOnAddonLoaded)
	end
	module:regEvent("ADDON_LOADED", fixCameraOnAddonLoaded)

	-- ensuring this doesn't override behaviour of the original frame
	InterfaceOptionsCameraPanelMaxDistanceSlider:HookScript("OnLeave", function()
		local cvarCameraDistance = tonumber(GetCVar("cameraDistanceMaxZoomFactor"))
		if cvarCameraDistance > 2.0 then
			module:setOption("cameraDistanceMaxZoomFactor", cvarCameraDistance)
		else
			module:setOption("cameraDistanceMaxZoomFactor", nil)
		end
	end)

	-- the rest of the code is inside the options panel, because it just uses a CVar

end


--------------------------------------------
-- WoW 10.x menu and bags bar

local enableCustomBagMenuBars, showCustomBagMenuAnchors

if module:getGameVersionAndPatch() == 10.02 and not CT_BottomBar then
	-- temporary code that was only used in 10.02; replaced by edit mode in 10.05
	
	local ctBagBar = CreateFrame("Frame", nil, MicroButtonAndBagsBar)
	ctBagBar:SetSize(10, 10)
	ctBagBar:SetPoint("TOPRIGHT")
	ctBagBar:SetFrameLevel(54)	-- in front of the bag
	ctBagBar:Hide()
	local tex = ctBagBar:CreateTexture(nil, "ARTWORK")
	tex:SetColorTexture(1,1,0,0.5)
	tex:SetAllPoints()
	
	ctBagBar:EnableMouse(true)
	ctBagBar:RegisterForDrag("LeftButton", "RightButton")
	
	module:regEvent("PLAYER_LOGIN", function()
		module:registerMovable("ctBagBar", ctBagBar, true)
	end)
	
	ctBagBar:SetScript("OnDragStart", function()
		module:moveMovable("ctBagBar")
	end)
	
	ctBagBar:SetScript("OnDragStop", function()
		module:stopMovable("ctBagBar")
	end)
	
	local ctMicroMenuBar = CreateFrame("Frame", nil, MicroButtonAndBagsBar)
	ctMicroMenuBar:SetSize(10, 10)
	ctMicroMenuBar:SetPoint("BOTTOMLEFT")
	ctMicroMenuBar:SetFrameLevel(54)	-- in front of the bag
	ctMicroMenuBar:Hide()
	local tex = ctMicroMenuBar:CreateTexture(nil, "ARTWORK")
	tex:SetColorTexture(1,1,0,0.5)
	tex:SetAllPoints()
	
	ctMicroMenuBar:EnableMouse(true)
	ctMicroMenuBar:RegisterForDrag("LeftButton", "RightButton")
	
	module:regEvent("PLAYER_LOGIN", function()
		module:registerMovable("ctMicroMenuBar", ctMicroMenuBar, true)
	end)
	
	ctMicroMenuBar:SetScript("OnDragStart", function()
		module:moveMovable("ctMicroMenuBar")
	end)
	
	ctMicroMenuBar:SetScript("OnDragStop", function()
		module:stopMovable("ctMicroMenuBar")
	end)
	
	function enableCustomBagMenuBars(enable)
		if ctBagBar.enabled and not enable then
			-- take no action if it was never enabled
			ctBagBar.enabled = false
			MainMenuBarBackpackButton:SetPoint("TOPRIGHT", MicroButtonAndBagsBar, -4, 2)
			CharacterMicroButton:SetPoint("BOTTOMLEFT", MicroButtonAndBagsBar, 7, 2)
		elseif enable then
			ctBagBar.enabled = true
			ctBagBar:SetShown(ctBagBar.shown)
			ctMicroMenuBar:SetShown(ctBagBar.shown)
			MainMenuBarBackpackButton:SetPoint("TOPRIGHT", ctBagBar, -4, 2)
			CharacterMicroButton:SetPoint("BOTTOMLEFT", ctMicroMenuBar, 7, 2)
		end
	end
	
	function showCustomBagMenuAnchors(show)
		ctBagBar.shown = show
		ctBagBar:SetShown(show and ctBagBar.enabled)
		ctMicroMenuBar:SetShown(show and ctBagBar.enabled)
	end
	
end


--------------------------------------------
-- General Initializer

local modInitAndUpdateFuncs =
{
	["castingTimers"] = toggleCastingTimers,
	["questLevels"] = toggleDisplayLevels,
	["blockBankTrades"] = module.configureBlockTradesBank,
	["tickMod"] = toggleTick,
	["tickModFormat"] = setTickDisplayType,
	["tickModLock"] = setTickLocked,
	["tooltipAnchorUnlock"] = tooltip_toggleAnchor,
	["tooltipRelocation"] = tooltip_toggleAnchor,
	["hideWorldMap"] = MiniMapWorldMapButton and toggleWorldMap,	-- removed in WoW 10.x
	["blockDuels"] = configureDuelBlockOption,
	["watchframeEnabled"] = module.watchframeEnabled,
	["watchframeLocked"] = module.watchframeLocked,
	["watchframeShowBorder"] = module.watchframeShowBorder,
	["watchframeClamped"] = module.watchframeClamped,
	["watchframeBackground"] = module.watchframeBackground,
	["watchframeChangeWidth"] = module.watchframeChangeWidth,
	["watchframeAddMinimizeButton"] = module.watchframeAddMinimizeButton,
	["CTCore_WatchFrameScale"] = module.watchframeChangeScale,
	["powerbaraltEnabled"] = powerbaralt_toggleStatus,
	["powerbaraltMovable"] = powerbaralt_toggleMovable,
	["powerbaraltShowAnchor"] = powerbaralt_toggleAnchor,
	["hideGryphons"] = hide_gryphons,
	["castingbarEnabled"] = castingbar_Update,
	["castingbarMovable"] = castingbar_ToggleHelper,
	["showLossOfControlFrame"] = movableLoC_UpdateVisibility,
	["moveLossOfControlFrame"] = movableLoC_UpdatePosition,
	["dragLossOfControlFrame"] = movableLoC_UpdateDragging,
	["enableCustomBagMenuBars"] = enableCustomBagMenuBars,
	["showCustomBagMenuAnchors"] = showCustomBagMenuAnchors,
}

local modUpdateFuncs =
{
	["auctionOpenNoBags"] = setBagOption,
	["auctionOpenBackpack"] = setBagOption,
	["auctionOpenBags"] = setBagOption,
	["bankOpenNoBags"] = setBagOption,
	["bankOpenBackpack"] = setBagOption,
	["bankOpenBags"] = setBagOption,
	["gbankOpenNoBags"] = setBagOption,
	["gbankOpenBackpack"] = setBagOption,
	["gbankOpenBags"] = setBagOption,
	["merchantOpenNoBags"] = setBagOption,
	["merchantOpenBackpack"] = setBagOption,
	["merchantOpenBags"] = setBagOption,
	["tradeOpenNoBags"] = setBagOption,
	["tradeOpenBackpack"] = setBagOption,
	["tradeOpenBags"] = setBagOption,
	["voidOpenNoBags"] = setBagOption,
	["voidOpenBackpack"] = setBagOption,
	["voidOpenBags"] = setBagOption,
	["obliterumOpenNoBags"] = setBagOption,
	["obliterumOpenBackpack"] = setBagOption,
	["obliterumOpenBags"] = setBagOption,
	["scrappingOpenNoBags"] = setBagOption,
	["scrappingOpenBackpack"] = setBagOption,
	["scrappingOpenBags"] = setBagOption,
}

setmetatable(modUpdateFuncs, {__index = modInitAndUpdateFuncs})

function module:modinit()
	-- load all the various settings
	for key, value in pairs(modInitAndUpdateFuncs) do
		value(self:getOption(key), key);
	end
end

function module:modupdate(opt, value)
	local func = modUpdateFuncs[opt];
	if ( func ) then
		func(value, opt);
	end
end