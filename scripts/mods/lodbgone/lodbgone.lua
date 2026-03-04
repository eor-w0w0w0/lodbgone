local mod = get_mod("lodbgone")

local function force_unit_lod(unit)
    if not unit or not Unit.is_valid(unit) then 
	mod:debug("force_unit_lod: invalid unit, skipping")
        return 
    end

	mod:debug("force_unit_lod: processing unit %s", tostring(unit))

    -- main LOD
    if Unit.has_lod_group(unit, "lod") then
        local lod_group = Unit.lod_group(unit, "lod")
        mod:debug("Setting main LODGroup to 0 for %s", tostring(unit))
        LODGroup.set_static_select(lod_group, 0)
    elseif Unit.has_lod_object(unit, "lod") then
        local lod_obj = Unit.lod_object(unit, "lod")
	mod:debug("Setting main LODObject to 0 for %s", tostring(unit))
        LODObject.set_static_select(lod_obj, 0)
    else 
	mod:debug("No main LOD group/object on %s", tostring(unit))
    end

    --shadow LOD
    if Unit.has_lod_group(unit, "lod_shadow") then
        local lod_group = Unit.lod_group(unit, "lod_shadow")
	mod:debug("Setting shadow LODGroup to 0 for %s", tostring(unit))
        LODGroup.set_static_select(lod_group, 0)
    elseif Unit.has_lod_object(unit, "lod_shadow") then
        local lod_obj = Unit.lod_object(unit, "lod_shadow")
	mod:debug("Setting shadow LODObject to 0 for %s", tostring(unit))
        LODObject.set_static_select(lod_obj, 0)
    else
	mod:debug("No shadow LOD group/object on %s", tostring(unit))
    end
end

--init
mod:hook_safe(CLASS.PlayerUnitVisualLoadoutExtension, "init", function(self, extension_init_context, unit, extension_init_data)
	if not unit or not Unit.is_valid(unit) then
		mod:error("init hook not valid")
		return
	end

	force_unit_lod(unit)

	local equipment = self._equipment
	if equipment then
		for _, slot_data in pairs(equipment) do
			if slot_data and slot_data.item then
				force_unit_lod(slot_data.item)
				local attachments = slot_data.attachments
				if attachments then
					for _, attachment_unit in ipairs(attachments) do
						force_unit_lod(attachment_unit)
					end
				end
			end
		end
	end
end)

-- newly equipped item
mod:hook_safe(CLASS.PlayerUnitVisualLoadoutExtension, "_equip_item_to_slot", function(self, slot_name, item_unit, ...)
    if item_unit and Unit.is_valid(item_unit) then
        force_unit_lod(item_unit)
    end
end)

--weapon is equipped/swapped
mod:hook_safe(CLASS.PlayerUnitWeaponExtension, "on_slot_wielded", function(self, unit)
	if not unit or not Unit.is_valid(unit) then
		mod:warning("Hook: on_slot_wielded not valid")
		return
	end
	mod:debug("Hook: on_slot_wielded successful")
	force_unit_lod(unit)
end)

--inventory background menu
mod:hook_safe(CLASS.InventoryBackgroundView, "update", function(self, dt)
	if self._background_unit and Unit.is_valid(self._background_unit) then
		force_unit_lod(self._background_unit)
	end
end)

--operator select screen
mod:hook_safe(CLASS.MainMenuView, "update", function(self, dt)
	if self._profile_character_unit and Unit.is_valid(self._profile_character_unit) then
		force_unit_lod(self._profile_character_unit)
	end
end)

--mission lobby 
mod:hook_safe(CLASS.LobbyView, "update", function(self, dt)
	if self._player_unit and Unit.is_valid(self._player_unit) then
		force_unit_lod(self._player_unit)
	end
end)
