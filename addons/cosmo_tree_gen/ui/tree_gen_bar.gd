# Copyright © 2026 CosmonautFrog - MIT License

@tool
extends HBoxContainer

const Exporter := preload("../core/exporter.gd")

const SAVE_PRESET_ID: int = 0

var tree: CosmoTreeGen: set = _set_tree

var _preset_paths := PackedStringArray()

@onready var _preset_menu: MenuButton = %PresetMenu
@onready var _seed_button: Button = %SeedButton
@onready var _stats_label: Label = %StatsLabel
@onready var _export_button: Button = %ExportButton
@onready var _export_dialog: EditorFileDialog = %ExportDialog
@onready var _preset_dialog: EditorFileDialog = %PresetDialog


func _ready() -> void:
	if is_part_of_edited_scene():
		return
	var theme := EditorInterface.get_editor_theme()
	_preset_menu.icon = theme.get_icon(&"Load", &"EditorIcons")
	_seed_button.icon = theme.get_icon(&"RandomNumberGenerator", &"EditorIcons")
	_export_button.icon = theme.get_icon(&"Save", &"EditorIcons")
	_preset_menu.about_to_popup.connect(_on_preset_menu_about_to_popup)
	_preset_menu.get_popup().id_pressed.connect(_on_preset_menu_id_pressed)
	_seed_button.pressed.connect(_on_seed_button_pressed)
	_export_button.pressed.connect(_on_export_button_pressed)
	_export_dialog.file_selected.connect(_on_export_dialog_file_selected)
	_preset_dialog.file_selected.connect(_on_preset_dialog_file_selected)


func _set_tree(value: CosmoTreeGen) -> void:
	if is_instance_valid(tree):
		tree.generated.disconnect(_update_stats)
	tree = value
	if tree != null:
		tree.generated.connect(_update_stats)
		_update_stats()


func _update_stats() -> void:
	var triangles: int = 0
	var surfaces: int = 0  # each surface is a draw call
	for mi in tree.get_meshes():
		var mesh := mi.mesh as ArrayMesh
		for i in mesh.get_surface_count():
			var index_len := mesh.surface_get_array_index_len(i)
			@warning_ignore("integer_division")
			triangles += (index_len if index_len > 0 else mesh.surface_get_array_len(i)) / 3
		surfaces += mesh.get_surface_count()
	_stats_label.text = "%d tris - %d draw calls" % [triangles, surfaces]


func _find_presets(dir: EditorFileSystemDirectory) -> void:
	# TODO: this could be slow on large projects, find another way
	# to get all the CosmoTreePresets
	for i in dir.get_file_count():
		var path := dir.get_file_path(i)
		if dir.get_file_type(i) != &"Resource" or path.get_extension() != "tres":
			continue
		var file := FileAccess.open(path, FileAccess.READ)
		# hacky way of finding if the Resource is CosmoTreePreset
		# read just the first line
		if file != null and file.get_line().contains('script_class="CosmoTreePreset"'):
			_preset_paths.append(path)
	for i in dir.get_subdir_count():
		_find_presets(dir.get_subdir(i))


func _apply_preset(path: String) -> void:
	var preset := load(path) as CosmoTreePreset
	if not preset.is_valid():
		for err in preset.get_errors():
			push_warning("CosmoTreeGen: invalid preset '%s' - %s" % [path, err])
		return

	var undo_redo := EditorInterface.get_editor_undo_redo()
	undo_redo.create_action("Apply Tree Preset")
	undo_redo.add_do_method(tree, &"apply_preset", preset)
	undo_redo.add_undo_method(tree, &"apply_preset", tree.to_preset())
	undo_redo.commit_action()
	print("CosmoTreeGen: applied preset '%s'" % path)


func _on_preset_menu_about_to_popup() -> void:
	_preset_paths.clear()
	_find_presets(EditorInterface.get_resource_filesystem().get_filesystem())

	var popup := _preset_menu.get_popup()
	popup.clear()
	for i in _preset_paths.size():
		var id := i + 1  # increment id by 1 so SAVE_PRESET_ID is always 0
		popup.add_item(_preset_paths[i].get_file().get_basename().capitalize(), id)
		popup.set_item_tooltip(i, _preset_paths[i])
	if not _preset_paths.is_empty():
		popup.add_separator()
	popup.add_item("Save Preset…", SAVE_PRESET_ID)


func _on_preset_menu_id_pressed(id: int) -> void:
	if id == SAVE_PRESET_ID:
		_preset_dialog.current_file = "%s.tres" % String(tree.name).to_snake_case()
		_preset_dialog.popup_file_dialog()
	else:
		_apply_preset(_preset_paths[id - 1])  # - 1 to keep sync with i + 1 in about_to_popup
		# TODO: fix this shit


func _on_preset_dialog_file_selected(path: String) -> void:
	var err := ResourceSaver.save(tree.to_preset(), path)
	if err != OK:
		push_error(
			"CosmoTreeGen: could not save preset to '%s' (%s)" % [path, error_string(err)]
		)
		return

	EditorInterface.get_resource_filesystem().update_file(path)


func _on_seed_button_pressed() -> void:
	var old_seed := tree.noise_seed
	tree.set_random_seed()

	var undo_redo := EditorInterface.get_editor_undo_redo()
	undo_redo.create_action("Randomize Tree Seed")
	undo_redo.add_do_property(tree, &"noise_seed", tree.noise_seed)
	undo_redo.add_undo_property(tree, &"noise_seed", old_seed)
	undo_redo.commit_action(false)


func _on_export_button_pressed() -> void:
	_export_dialog.current_file = "%s.gltf" % String(tree.name).to_snake_case()
	_export_dialog.popup_file_dialog()


func _on_export_dialog_file_selected(path: String) -> void:
	var err := Exporter.export_gltf_instances(path, tree.get_meshes())
	if err != OK:
		push_error(
			"CosmoTreeGen: could not export glTF to '%s' (%s)" % [path, error_string(err)]
		)
	EditorInterface.get_resource_filesystem().scan()
