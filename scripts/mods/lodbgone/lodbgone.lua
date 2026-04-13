local mod = get_mod("lodbgone")

local function force_unit_lod(unit)
	if not unit or not Unit.is_valid(unit) then
		mod:info("force_unit_lod: invalid unit, skipping")
		return
	end

	mod:info("force_unit_lod: processing unit %s", tostring(unit))

	-- main LOD
	if Unit.has_lod_group(unit, "lod") then
		local lod_group = Unit.lod_group(unit, "lod")
		mod:info("Setting main LODGroup to 0 for %s", tostring(unit))
		LODGroup.set_static_select(lod_group, 0)
	elseif Unit.has_lod_object(unit, "lod") then
		local lod_obj = Unit.lod_object(unit, "lod")
		mod:info("Setting main LODObject to 0 for %s", tostring(unit))
		LODObject.set_static_select(lod_obj, 0)
	else
		--mod:info("No main LOD group/object on %s", tostring(unit))
	end

	--shadow LOD
	if Unit.has_lod_group(unit, "lod_shadow") then
		local lod_group = Unit.lod_group(unit, "lod_shadow")
		mod:info("Setting shadow LODGroup to 0 for %s", tostring(unit))
		LODGroup.set_static_select(lod_group, 0)
	elseif Unit.has_lod_object(unit, "lod_shadow") then
		local lod_obj = Unit.lod_object(unit, "lod_shadow")
		mod:info("Setting shadow LODObject to 0 for %s", tostring(unit))
		LODObject.set_static_select(lod_obj, 0)
	else
		--mod:info("No shadow LOD group/object on %s", tostring(unit))
	end
end

-- one slot traversal, used by everything else
local function force_lod_for_slot(slot_data)
	if not slot_data then
		return
	end

	if slot_data.unit_1p then
		force_unit_lod(slot_data.unit_1p)
	end
	if slot_data.unit_3p then
		force_unit_lod(slot_data.unit_3p)
	end

	local attachments_by_unit = slot_data.attachments_by_unit_1p or {}
	for attachment_unit, attachment_data in pairs(attachments_by_unit) do
		force_unit_lod(attachment_unit)
		if attachment_data.attachments_by_unit and type(attachment_data.attachments_by_unit) == "table" then
			for nested_unit in pairs(attachment_data.attachments_by_unit) do
				force_unit_lod(nested_unit)
			end
		end
	end

	attachments_by_unit = slot_data.attachments_by_unit_3p or {}
	for attachment_unit, attachment_data in pairs(attachments_by_unit) do
		force_unit_lod(attachment_unit)
		if attachment_data.attachments_by_unit and type(attachment_data.attachments_by_unit) == "table" then
			for nested_unit in pairs(attachment_data.attachments_by_unit) do
				force_unit_lod(nested_unit)
			end
		end
	end
end

--traverse visual_loadout_ext
local function force_lod_for_equipment(visual_loadout_ext)
	if not visual_loadout_ext or not visual_loadout_ext._equipment then
		return
	end

	for slot_name, slot_data in pairs(visual_loadout_ext._equipment) do
		if slot_data.unit_1p then
			force_unit_lod(slot_data.unit_1p)
		end
		if slot_data.unit_3p then
			force_unit_lod(slot_data.unit_3p)
		end

		local attachments_by_unit = slot_data.attachments_by_unit_1p or {}
		for attachment_unit, attachment_data in pairs(attachments_by_unit) do
			force_unit_lod(attachment_unit)
			if attachment_data.attachments_by_unit then
				for nested_unit in pairs(attachment_data.attachments_by_unit) do
					force_unit_lod(nested_unit)
				end
			end
		end

		attachments_by_unit = slot_data.attachments_by_unit_3p or {}
		for attachment_unit, attachment_data in pairs(attachments_by_unit) do
			force_unit_lod(attachment_unit)
			if attachment_data.attachments_by_unit then
				for nested_unit in pairs(attachment_data.attachments_by_unit) do
					force_unit_lod(nested_unit)
				end
			end
		end
	end
end

mod:hook_safe(CLASS.PlayerUnitVisualLoadoutExtension, "init", function(
	self, extension_init_context, unit, extension_init_data, gameobject_data_or_gamesession, unit_spawn_parameter_or_gameobject_id
)
	if not unit or not Unit.is_valid(unit) then
		return
	end

	-- player unit itself 
	force_unit_lod(unit)

	-- all initial equipment and attachments
	force_lod_for_equipment(self)
end)

mod:hook_safe(CLASS.PlayerUnitVisualLoadoutExtension, "_equip_item_to_slot", function(
	self, item, slot_name, t, optional_existing_unit_3p, from_server_correction_occurred
)
	if not item or not slot_name then
		return
	end

	local slot = self.equipment and self.equipment[slot_name]
	if not slot then
		return
	end

	force_lod_for_slot(slot)
end)


-- weapon is equipped/swapped
mod:hook_safe(CLASS.PlayerUnitWeaponExtension, "on_slot_wielded", function(self, slot_name, t, skip_wield_action)
	if not slot_name then
		mod:info("Hook: on_slot_wielded skipped - no slot_name")
		return
	end

	-- retrieve weapon data by slot name
	local weapon = self._weapons[slot_name]
	if not weapon then return end

	-- Force LOD on weapon unit
	local weapon_unit = weapon.weapon_unit
	if weapon_unit and Unit.has_lod_object(weapon_unit, "lod") then
		mod:info("Hook: on_slot_wielded successful for %s", slot_name)
		force_unit_lod(weapon_unit)
	else
		mod:info("Hook: on_slot_wielded - no LOD data on weapon unit for %s", slot_name)
	end
end)

--when spawning
mod:hook_safe(CLASS.PlayerUnitWeaponExtension, "on_player_unit_spawn", function(self, respawn_ammo_percentage)
	local visual_loadout_ext = self.visualloadoutextension
	if not visual_loadout_ext and ScriptUnit.has_extension(self.unit, "visual_loadout_system") then
		visual_loadout_ext = ScriptUnit.extension(self.unit, "visual_loadout_system")
	end

	force_lod_for_equipment(visual_loadout_ext)
end)


--when respawning
mod:hook_safe(CLASS.PlayerUnitWeaponExtension, "on_player_unit_respawn", function(self, respawn_ammo_percentage)
	local visual_loadout_ext = self.visualloadoutextension
	if not visual_loadout_ext and ScriptUnit.has_extension(self.unit, "visual_loadout_system") then
		visual_loadout_ext = ScriptUnit.extension(self.unit, "visual_loadout_system")
	end

	force_lod_for_equipment(visual_loadout_ext)
end)

-- on wielding item
mod:hook_safe(CLASS.PlayerUnitWeaponExtension, "on_wieldable_slot_equipped", function(self, item, slot_name, weapon_unit, fx_sources, t, optional_existing_unit_3p, from_server_correction_occurred)
	local visual_loadout_ext = self.visualloadoutextension
	if not visual_loadout_ext and ScriptUnit.has_extension(self.unit, "visual_loadout_system") then
		visual_loadout_ext = ScriptUnit.extension(self.unit, "visual_loadout_system")
	end

	force_lod_for_equipment(visual_loadout_ext)
end)

--[[
mod:hook_safe(Weapon, "init",  function (self, init_data)
	

end)

how attachement units are spawned 

	if attach_settings.from_script_component then
		spawned_unit = World.spawn_unit_ex(attach_settings.world, base_unit, nil, pose)
	elseif attach_settings.is_minion then
		spawned_unit = attach_settings.unit_spawner:spawn_unit(base_unit, attach_settings.attach_pose)
	else
		spawned_unit = attach_settings.unit_spawner:spawn_unit(base_unit, pose)
	end
	]]--
