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
-- Mail Action Queue

local getMailAction, popMailAction;
do
	local actionQueue = { };
	local dataQueue = { };

	function module:addMailAction(data, action)
		if ( dataQueue and action ) then
			tinsert(dataQueue, data);
			tinsert(actionQueue, action);
 		end
	end

	function module:clearMailActions()
		if ( #actionQueue > 0 ) then
			module:clearTable(dataQueue);
			module:clearTable(actionQueue);
			return true;
		end
	end

	function module:removeMailAction(data)
		local toValue, found;
		if (module.isProcessing) then
			-- When processing we cannot remove the item being processed,
			-- so stop looping at item 2.
			toValue = 2;
		else
			toValue = 1;
		end
		for i = #dataQueue, toValue, -1 do
			if ( dataQueue[i] == data ) then
				tremove(dataQueue, i);
				tremove(actionQueue, i);
				found = i;
				break;
			end
		end
		return found;
	end

	popMailAction = function() -- Local
		return tremove(dataQueue, 1), tremove(actionQueue, 1);
	end

	getMailAction = function() -- Local
		return dataQueue[1], actionQueue[1];
	end

	function module:currentMailAction()
		return getMailAction();
	end

	function module:getmaq()  -- for debugging purposes
		for i = 1, #dataQueue do
			print(i, dataQueue[i], actionQueue[i]);
		end
		return dataQueue, actionQueue;
	end
end

--------------------------------------------
-- Processing control

function module:beginProcessing(endFunc)
	-- Begin processing.
	-- This function should be called from the function used to begin
	-- processing when a button is clicked, etc.
	--   endFunc == function to be called when processing ends

	if (module.isProcessing) then
		-- Processing already in progess.
		return false;
	end

	module:raiseCustomEvent("PROCESSING_START");

	module.processingEnd = endFunc;
	module.isProcessing = true;

	-- Make sure there is no delay before the mail updater starts.
	module:zeroMailUpdater(module.mailActionHandler);

	return true;
end

local function endProcessing()
	-- End processing.
	-- This is called when processing ends (ie. when processing is cancelled
	-- or the mail action queue becomes empty).

	-- Call the end of processing routine
	local endProc = module.processingEnd;
	if (endProc) then
		endProc(module);
	end

	module.processingEnd = nil;
	module.isProcessing = false;

	module:raiseCustomEvent("PROCESSING_STOP");
end

function module:pauseProcessing()
	-- Pause processing
	module.processingPaused = true;
end

function module:resumeProcessing()
	-- Resume processing
	module.processingPaused = false;
end

function module:cancelProcessing()
	-- Cancel all processing.
	-- This is intended to be called from outside of a mail action function.
	-- This may be called even when module.isProcessing is not true.
	local wasProcessing = module.isProcessing;

	-- Cancel the current action.
	local data, action = module:currentMailAction();
	if (action) then
		if (type(action) == "function") then
			-- Set the cancel flag and then call the action.
			-- The action should do what is necessary to cancel itself.
			data.cancel = true;
			action(module, data);
		end
	end

	-- Clear the mail action queue
	module:clearMailActions();

	-- End processing
	endProcessing();

	if (wasProcessing) then
		print(module.text["CT_MailMod/PROCESSING_CANCELLED"]);
	end
end

function module:getCurrentActionType()
	-- Returns the current action type.
	local data, action = module:currentMailAction();
	if (action) then
		if (type(action) == "function") then
			return data.actionType;
		end
	end
	return nil;	
end

function module:getProcessingReturnValue(ret)
	-- Converts the specified number into a value that can be returned
	-- to the mail action handler.
	--
	-- ret:
	--   0 == Continue with this action after delay 1
	--   1 == Continue with this action after delay 2
	--   2 == Cancel all processing
	--   3 == Proceed to the next action
	--
	-- Returns one of:
	--   a) number: delay 1
	--   b) number: delay 2
	--   c) nil: cancel processing
	--   d) true: proceed with the next action
	--
	if (ret == 0) then
		-- Continue with this action after the specified delay
		return module.processingSpeed1;
	elseif (ret == 1) then
		-- Continue with this action after the specified delay
		return module.processingSpeed2;
	elseif (ret == 2) then
		-- Finished with this action. Cancel processing.
		return nil;
	else
		-- Finished with this action. Proceed with next action.
		return true;
	end
end

--------------------------------------------
-- Mail Action Handler

-- In order for a function to act as a mail action, the following
-- things must be taken into consideration:

-- The return value of the mail action function decides
-- which action to take:

-- nil: Cancel all remaining actions in the queue.
-- x (number, in seconds): Wait x seconds before retrying the action.
-- function: Call this function. If it returns true then remove the action from the queue.
-- true: Remove the action from the queue. Wait before trying the next action.
-- false: Remove the action from the queue. Do not wait before trying the next action.

function module:mailActionHandler(func)
	-- Params:
	--   func == a reference to this function
	-- Returns:
	--   nil == default number of seconds until this function is called again.
	--   number == number of seconds until this function is called again.

	local ret;
	local data, action;
	local delay, wait;

	-- Get the current info from the queue.
	data, action = getMailAction();

	while (action and not module.processingPaused) do
		wait = true;  -- true == Wait for the mail updater's next scheduled time.

		-- Carry out the action.
		if (type(action) == "function") then
			ret = action(module, data);
		else
			-- Old style mail action.
			-- data == a mail object
			-- action == a string action (name of a member function in the mail class)
			ret = data[action](data);
		end

		if (ret == nil) then
			-- Cancel all remaining actions in the queue
			-- The action we just finished executing should have
			-- already done what was needed to cancel itself.
			module:clearMailActions();
			endProcessing();
			print(module.text["CT_MailMod/PROCESSING_CANCELLED"]);
			break;

		elseif (type(ret) == "number") then
			-- Retry the current action after ret seconds.
			delay = ret;

		elseif (type(ret) == "function") then
			-- Call the function.
			if (ret(data)) then
				-- The function returned true.
				-- Remove the current action from the queue.
				popMailAction();
			end
		else
			-- True or false (or some unexpected value).
			-- Remove the current action from the queue.
			popMailAction();
			if (not ret) then
				-- Don't wait for the mail updater's next scheduled time.
				wait = false;
			end
		end

		-- Get the current info from the queue.
		data, action = getMailAction();

		if (not action) then
			-- The mail action queue is now empty.
			endProcessing();
			break;
		end

		if (wait) then
			break;
		end
	end

	return delay;
end

module:registerMailUpdater(module.processingSpeed1, module.mailActionHandler);
