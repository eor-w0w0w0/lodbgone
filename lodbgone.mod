return {
	run = function()
		fassert(rawget(_G, "new_mod"), "`lodbgone` encountered an error loading the Darktide Mod Framework.")

		new_mod("lodbgone", {
			mod_script = "lodbgone/scripts/mods/lodbgone/lodbgone",
			mod_data = "lodbgone/scripts/mods/lodbgone/lodbgone_data",
			mod_localization = "lodbgone/scripts/mods/lodbgone/lodbgone_localization",
		})
	end,
	packages = {},
}

