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

-- operator select screen - force LOD on spawned character
mod:hook_safe(UIProfileSpawner, "_spawn_character_profile", function(self, profile, profile_loader, position, rotation, scale, state_machine, animation_event, face_state_machine_key, face_animation_event, force_highest_mip, disable_hair_state_machine, optional_unit_3p, optional_ignore_state_machine, companion_data)
	if self._character_spawn_data and self._character_spawn_data.unit_3p and Unit.has_lod_object(self._character_spawn_data.unit_3p, "lod") then
		force_unit_lod(self._character_spawn_data.unit_3p)
	end

	if companion_data.unit_3p and Unit.has_lod_object(companion_data.unit_3p, "lod") then
		force_unit_lod(companion_data.unit_3p)
	end
end)

-- inventory background menu - force LOD on spawned character
mod:hook_safe(UIProfileSpawner, "_spawn_character_profile", function(self, profile, profile_loader, position, rotation, scale, state_machine, animation_event, face_state_machine_key, face_animation_event, force_highest_mip, disable_hair_state_machine, optional_unit_3p, optional_ignore_state_machine, companion_data)
	if self._character_spawn_data and self._character_spawn_data.unit_3p and Unit.has_lod_object(self._character_spawn_data.unit_3p, "lod") then
		force_unit_lod(self._character_spawn_data.unit_3p)
	end

	if companion_data.unit_3p and Unit.has_lod_object(companion_data.unit_3p, "lod") then
		force_unit_lod(companion_data.unit_3p)
	end
end)

-- init
mod:hook_safe(CLASS.PlayerUnitVisualLoadoutExtension, "init", function(self, extension_init_context, unit, extension_init_data)
	if not unit or not Unit.is_valid(unit) then
		mod:debug("init hook not valid")
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
mod:hook_safe(CLASS.PlayerUnitVisualLoadoutExtension, "_equip_item_to_slot", function(self, item, slot_name, t, optional_existing_unit_3p, from_server_correction_occurred)
	if not item or not slot_name then return end

	local equipment = self._equipment[slot_name]
	if not equipment then return end

	-- Force LOD on 1st person weapon unit
	if equipment.unit_1p and Unit.has_lod_object(equipment.unit_1p, "lod") then
		force_unit_lod(equipment.unit_1p)
	end

	-- Force LOD on 3rd person weapon unit
	if equipment.unit_3p and Unit.has_lod_object(equipment.unit_3p, "lod") then
		force_unit_lod(equipment.unit_3p)
	end

	-- Force LOD on any attachments for this slot
	local attachments_by_unit = equipment.attachments_by_unit_1p or {}
	for attachment_unit, attachment_data in pairs(attachments_by_unit) do
		if attachment_unit and Unit.has_lod_object(attachment_unit, "lod") then
			force_unit_lod(attachment_unit)
		end

		-- Also check for nested attachments
		if attachment_data.attachments_by_unit and type(attachment_data.attachments_by_unit) == "table" then
			for nested_attachment_unit in pairs(attachment_data.attachments_by_unit) do
				if nested_attachment_unit and Unit.has_lod_object(nested_attachment_unit, "lod") then
					force_unit_lod(nested_attachment_unit)
				end
			end
		end
	end

	attachments_by_unit = equipment.attachments_by_unit_3p or {}
	for attachment_unit, attachment_data in pairs(attachments_by_unit) do
		if attachment_unit and Unit.has_lod_object(attachment_unit, "lod") then
			force_unit_lod(attachment_unit)
		end

		-- Also check for nested attachments
		if attachment_data.attachments_by_unit and type(attachment_data.attachments_by_unit) == "table" then
			for nested_attachment_unit in pairs(attachment_data.attachments_by_unit) do
				if nested_attachment_unit and Unit.has_lod_object(nested_attachment_unit, "lod") then
					force_unit_lod(nested_attachment_unit)
				end
			end
		end
	end
end)

-- weapon is equipped/swapped
mod:hook_safe(CLASS.PlayerUnitWeaponExtension, "on_slot_wielded", function(self, slot_name, t, skip_wield_action)
	if not slot_name then
		mod:debug("Hook: on_slot_wielded skipped - no slot_name")
		return
	end

	-- retrieve weapon data by slot name
	local weapon = self._weapons[slot_name]
	if not weapon then return end

	-- Force LOD on weapon unit
	local weapon_unit = weapon.weapon_unit
	if weapon_unit and Unit.has_lod_object(weapon_unit, "lod") then
		mod:debug("Hook: on_slot_wielded successful for %s", slot_name)
		force_unit_lod(weapon_unit)
	else
		mod:debug("Hook: on_slot_wielded - no LOD data on weapon unit for %s", slot_name)
	end
end)

-- after attachment spawning in visual_loadout_customization
mod:hook_safe(VisualLoadoutCustomization, "spawn_item_attachments", function(self, item_data, override_lookup, attach_settings, item_unit, optional_map_attachment_name_to_unit, optional_extract_attachment_units_bind_poses, optional_extract_item_names, optional_mission_template, optional_equipment)
	if not item_unit or not Unit.is_valid(item_unit) then return end

	-- Force LOD on spawned attachment units
	local attachment_units_by_unit = override_lookup and override_lookup.attachment_units_by_unit or attachment_units_by_unit or {}
	for attachment_unit, _ in pairs(attachment_units_by_unit) do
		if attachment_unit and Unit.has_lod_object(attachment_unit, "lod") then
			force_unit_lod(attachment_unit)
		end
	end
end)

