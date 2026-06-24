------------------------------------------------
--               CT_BarMod                    --
--                                            --
-- Intuitive yet powerful action bar addon,   --
-- featuring per-button positioning as well   --
-- as scaling while retaining the concept of  --
-- grouped buttons and action bars.           --
--                                            --
-- Please do not modify or otherwise          --
-- redistribute this without the consent of   --
-- the CTMod Team. Thank you.                 --
------------------------------------------------

--------------------------------------------
-- Initialization

local module = select(2, ...);

-- End Initialization
--------------------------------------------

if module:getGameVersion() >= 10 then
	--return
end

--------------------------------------------
-- Local Copies

local ipairs = ipairs;
local pairs = pairs;
local strsub = strsub;
local tostring = tostring;

-- End Local Copies
--------------------------------------------

--------------------------------------------
-- Masque support.

local Masque;
if (LibStub) then
	Masque = LibStub("Masque", true);
end

function module:isMasqueLoaded()
	-- Returns true if Masque is loaded.
	return Masque ~= nil;
end

function module:usingMasque()
	-- Returns true if we are currently using Masque to skin buttons.
	return Masque and module:getOption("skinMasque");
end

function module:getMasqueFrameLevelAdjustment()
	-- Get the amount to adjust the button's level above the group's drag frame
	-- when Masque is loaded and the group's drag frame is below the buttons.
	--
	-- The value is also used when determining what frame level to use for the
	-- group's drag frame when it is shown above the buttons.

	-- Masque changes the frame level of the cooldown (-1), autocast (+1),
	-- and a custom Masque frame (-2) to be relative to the button's frame level (+0).
	--
	-- We want the button's frame level to be high enough so that when
	-- Masque changes the other frame levels they don't end up below the
	-- frame level of the group's drag frame (when the drag frame is below the buttons).
	return 3;
end

function module:addSkinToMasque(name, skin)
	-- Add a skin to Masque
	Masque:AddSkin(skin.__CTBM__MasqueName, skin);
end

function module:createMasqueGroup(group)
	-- Create a button group in Masque for this bar.
	group.MasqueGroup = Masque:Group("CT_BarMod", "Bar " .. strsub(" " .. tostring(group.num), -2));
end

local function addButtonsToMasqueGroup(group)
	-- Add all buttons in this group to this group's Masque group.
	local objects = group.objects;
	for key, object in ipairs(objects) do
		local button = object.button;
		local buttonData = {
			AutoCast = nil,
			AutoCastable = nil,
			Border = button.border,
			Checked = button.checkedTexture,
			Cooldown = button.cooldown,
			Count = button.count,
			Disabled = nil,
			Duration = nil,
			Flash = button.flash,
			FloatingBG = nil,
			Highlight = button.highlightTexture,
			HotKey = button.hotkey,
			Icon = button.icon,
			Name = button.name,
			Normal = button.normalTexture,
			Pushed = button.pushedTexture,
		};

		-- Hide the CT background texture
		button.backdrop:Hide();

		-- Masque will reskin the buttons as they are added to a Masque group.
		-- Masque will hide our normal texture.
		-- Masque will create their own normal texture and show it.
		-- Masque will create their own backdrop and show it if needed.
		-- Masque will create a gloss texture and show it if needed.
		group.MasqueGroup:AddButton(button, buttonData);
		
		-- Masque updates the spell alert textures when a button is reskinned,
		-- but only if the shape of the button has changed.
		-- We need to make sure the correct spell alert textures are assigned
		-- to the buttons that have an active spell alert glow.
		module:skinMasqueSpellAlert(button);
	end
end

local function removeButtonsFromMasqueGroup(group)
	-- Remove all buttons in this group from the Masque group.
	local objects = group.objects;

	-- Since we'll be reskinning the buttons after removing them
	-- from the Masque group, we'll leave the current Masque skin
	-- on the buttons.
	local retainSkin = true; -- false=Reset to default Masque skin, true=Keep current skin

	for key, object in ipairs(objects) do
		local button = object.button;

		-- Masque can either leave the current skin on the button,
		-- or it can re-apply the default Masque skin ("Blizzard").
		group.MasqueGroup:RemoveButton(button, retainSkin);

		-- Hide things that Masque created.
		local backdrop = Masque:GetBackdrop(button);
		if (backdrop) then
			backdrop:Hide();
		end

		local normal = Masque:GetNormal(button);
		if (normal) then
			-- Masque never calls :SetNormalTexture() itself.
			-- It just hides the current normal texture and shows its own texture.
			--
			-- Masque hooks each button's :SetNormalTexture() method but
			-- does not 'disable' the hook when the button is removed from
			-- a Masque group.
			--
			-- To avoid the hook, we'll be calling the :SetNormalTexture
			-- method directly rather than by name.

			-- We want to hide Masque's normal texture.
			normal:Hide();
		end

		local gloss = Masque:GetGloss(button);
		if (gloss) then
			gloss:Hide();
		end

		-- Masque hooks ActionButton_ShowOverlayGlow, but we're not using that
		-- function anymore. Ignore.

		-- Masque hooks the button's :SetFrameLevel. We can ignore this.
		-- We've left enough levels between the group's drag frame and the CT button that
		-- their lowering of the frame levels won't drop anything below our group's
		-- drag frame.

		-- Masque changes the parent of the icon texture. We'll take care
		-- of re-parenting the icon texture when we reskin the button to a CT skin.
		
		-- The spell alert overlay glow textures will be handled when we reskin
		-- the button to a CT skin.
	end
end

function module:reskinMasqueGroups()
	-- Reskin all Masque groups (uses the Masque skins).
	local groupList = module.groupList;
	for groupNum, group in pairs(groupList) do
		if (group.MasqueGroup) then
			-- Reskin the buttons in this Masque group (uses the Masque skin).
			group.MasqueGroup:ReSkin();
			-- For each button in this group, update the spell alert overlay glow textures
			-- (if applicable) since Masque won't do so if the button shape has not changed.
			local objects = group.objects;
			local button;
			for key, object in ipairs(objects) do
				button = object.button;
				module:skinMasqueSpellAlert(button);
			end
		end
	end
end

function module:skinMasqueSpellAlert(button)
	-- Assign the proper spell alert textures based on the Masque skin used on the button.

	-- Problem: The Masque function which changes the textures (UpdateSpellAlert) is not
	-- callable from other addons.
	--
	-- Masque will assign the textures when a button gets skinned, however if we attempt
	-- to reskin a Masque group during combat then we'll get an "action blocked by an addon" 
	-- message and cause WoW to update the taint.log file if logging is enabled. This happens
	-- because Masque tries to change the button's frame level.
	-- Note: This should now be fixed in Masque version 4.3.382. However, it would require
	-- us to reskin the whole button group each time a button in the group needs its
	-- overlay glow updated (there is no Reskin(button) function available).
	--
	-- One alternative is to create an overlay frame for every button, so that when Masque
	-- initially skins the button (when we add our button to a Masque group), its textures
	-- will be changed. However, this creates a lot of frames and textures that may never
	-- get used.
	--
	-- Masque 4.3.382 added a :GetSpellAlert function, however that requires that you know
	-- the shape of the skin that is being applied to the button. Currently that information
	-- is only available via an internal Masque value that is assigned to each button: .__MSQ_Shape

	-- Set default textures (overlay frame keys and texture names are from ActionBarFrame.xml)
	local Glow;
	local Ants;
	if (Masque.GetSpellAlert) then  -- :GetSpellAlert added in Masque 4.3.382
		local shape;
--		if (Masque.GetShape) then  -- Suggested function (not implemented as of Masque 4.3.382)
--			shape = Masque:GetShape(button);
--		else
			shape = button.__MSQ_Shape;  -- Use internal value
--		end
		if (not shape) then
			shape = "Square";
		end
		Glow, Ants = Masque:GetSpellAlert(shape);
	end
	module:skinOverlayGlow(button, Glow, Ants);
end

function module:getMasqueNormalTexture(button)
	-- Masque is loaded.
	-- Get the normal texture from Masque.

	-- If Masque has not yet created its own custom normal texture for the button
	-- (which will be the case if the option to skin using Masque is disabled when
	-- CT_BarMod starts), then Masque will return button:GetNormalTexture() instead.

	if (module:usingMasque()) then
		-- We're using Masque to skin the buttons.
		-- Have Masque tell us what the normal texture is.
		return Masque:GetNormal(button);
	else
		-- We're using CT_BarMod to skin the buttons.
		-- Have the button tell us what the normal texture is.
		return button:GetNormalTexture();
	end
end

function module:setMasqueNormalTexture(button, name)
	-- Masque is loaded.
	-- Set the normal texture of the button.

	-- When a button is added to a Masque button group, Masque hooks the
	-- button's SetNormalTexture method. If the hook function detects that
	-- we are trying to use anything other than Masque's custom normal
	-- texture, then it sets our texture to "" and hides it. It then proceeds
	-- to use its own custom texture. Masque's SkinNormal function contains
	-- similar logic.
	--
	-- Removing a button from a Masque button group does not have any effect on the
	-- hook function. It continues to hide any texture passed to the button's
	-- SetNormalTexture method, and it continues to use Masque's custom normal texture.

	if (module:usingMasque()) then
		-- We're using Masque to skin the buttons.
		-- Call the button's :SetNormalTexture method by name.
		-- Masque's hook of the method will get executed.
		button:SetNormalTexture(name);
	else
		-- We're using CT_BarMod to skin the buttons.
		-- Call the button's :SetNormalTexture method directly.
		-- This prevents Masque's hook of the method from executing.

		-- Since Masque's hook won't get called, we need to update a flag
		-- that Masque's hook maintains on our button. This keeps things
		-- synchronized while we have Masque skinning disabled in CT_BarMod.
		-- Refer to Masque/Core/Button.lua in the Hook_SetNormalTexture function.
		local skinData = module:getSkinData(button.skinNumber);
		if (name == "Interface\\Buttons\\UI-Quickslot" and skinData.EmptyTexture) then
			button.__MSQ_Empty = true;
		elseif (name == "Interface\\Buttons\\UI-Quickslot2") then
			button.__MSQ_Empty = nil;
		end

		-- Call the button's method directly to avoid Masque's hook.
		button:__CTBM__SetNormalTexture(name);
	end
end

function module:enableMasque(enable)
	-- Enable or disable Masque support.
	if (not Masque) then
		-- Masque is not loaded.
		return;
	end
	local groupList = module.groupList;
	for groupNum, group in pairs(groupList) do
		if (group.MasqueGroup) then
			if (enable) then
				-- Enable Masque by adding all buttons to Masque groups.
				-- Note: Once a button has been added to Masque, its :SetNormalTexture()
				-- method gets hooked by Masque, and it becomes impossible to use the original
				-- normal texture. Instead, we will need to use the texture returned from
				-- Masque:GetNormal(button). Removing the button from the Masque group
				-- does not disable the hook of :SetNormalTexture().
				addButtonsToMasqueGroup(group);
			else
				-- Disable Masque by removing all buttons from Masque groups.
				removeButtonsFromMasqueGroup(group);
			end
		end
	end
end
