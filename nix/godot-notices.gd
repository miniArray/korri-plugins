extends SceneTree

# The engine itself reports the exact notice inventory of this runtime build.
func _initialize() -> void:
	var destination := OS.get_cmdline_user_args()[0]
	var files := {
		"GODOT-LICENSE.txt": Engine.get_license_text(),
		"GODOT-COPYRIGHT.json": JSON.stringify(Engine.get_copyright_info(), "  "),
		"GODOT-LICENSES.json": JSON.stringify(Engine.get_license_info(), "  "),
	}
	for name in files:
		var file := FileAccess.open(destination.path_join(name), FileAccess.WRITE)
		if file == null:
			push_error("Cannot write engine notice: " + name)
			quit(1)
			return
		file.store_string(files[name] + "\n")
	quit()
