# Copyright © 2026 CosmonautFrog - MIT License

@tool
extends RefCounted


static func open_save_dialog(
	file_name: String = "",
	file_selected_callback := Callable(),
	current_dir: String = "",
	filter: String = "",
) -> void:
	# avoid "as EditorFileDialog" on purpose,
	# otherwise would fail on an exported game
	var dialog = ClassDB.instantiate(&"EditorFileDialog")

	if not current_dir.is_empty():
		dialog.current_dir = current_dir

	dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	dialog.access = FileDialog.ACCESS_RESOURCES

	if not filter.is_empty():
		dialog.add_filter(filter)

	if not file_name.is_empty():
		dialog.current_file = file_name

	dialog.file_selected.connect(file_selected_callback)
	dialog.visibility_changed.connect(
		func() -> void:
			if not dialog.visible:
				dialog.queue_free()
	)

	var editor = Engine.get_singleton(&"EditorInterface")
	editor.get_base_control().add_child(dialog)
	dialog.popup_centered_ratio(0.5)
