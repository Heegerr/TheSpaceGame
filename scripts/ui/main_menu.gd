extends Control
## Main menu: New Game / Continue / Load Game across 3 save slots.
## Continue loads the most recently saved slot.

const OptionsMenuScene := preload("res://scenes/ui/options_menu.tscn")

@onready var main_buttons: VBoxContainer = $Center/MainButtons
@onready var continue_button: Button = $Center/MainButtons/ContinueButton
@onready var slot_panel: VBoxContainer = $Center/SlotPanel
@onready var slot_title: Label = $Center/SlotPanel/SlotTitle

var _slot_buttons: Array[Button] = []
var _mode := "new"
var _options_menu: CanvasLayer


func _ready() -> void:
	get_tree().paused = false
	continue_button.disabled = not GameManager.has_any_save()
	continue_button.pressed.connect(func() -> void: GameManager.continue_game())
	$Center/MainButtons/NewButton.pressed.connect(_open_slots.bind("new"))
	$Center/MainButtons/LoadButton.pressed.connect(_open_slots.bind("load"))
	$Center/MainButtons/OptionsButton.pressed.connect(_open_options)
	$Center/MainButtons/QuitButton.pressed.connect(func() -> void: get_tree().quit())
	$Center/SlotPanel/BackButton.pressed.connect(_close_slots)
	for slot in GameManager.SLOT_COUNT:
		var button := Button.new()
		button.add_theme_font_size_override("font_size", 10)
		button.pressed.connect(_on_slot_pressed.bind(slot))
		slot_panel.add_child(button)
		slot_panel.move_child(button, 1 + slot)
		_slot_buttons.append(button)
	slot_panel.visible = false


func _open_slots(mode: String) -> void:
	_mode = mode
	slot_title.text = "Start a new game in..." if mode == "new" else "Load which save?"
	for slot in _slot_buttons.size():
		var meta := GameManager.slot_meta(slot)
		var button := _slot_buttons[slot]
		if meta.get("exists", false):
			button.text = "Slot %d  -  %d colonies  -  %s" % [slot + 1, int(meta.get("colonized", 0)), str(meta.get("timestamp", "?"))]
			button.disabled = false
		else:
			button.text = "Slot %d  -  Empty" % [slot + 1]
			button.disabled = _mode == "load"
	main_buttons.visible = false
	slot_panel.visible = true


func _close_slots() -> void:
	slot_panel.visible = false
	main_buttons.visible = true


func _on_slot_pressed(slot: int) -> void:
	if _mode == "new":
		GameManager.new_game(slot)
	else:
		GameManager.load_slot(slot)


func _open_options() -> void:
	if _options_menu == null:
		_options_menu = OptionsMenuScene.instantiate()
		add_child(_options_menu)
	_options_menu.open()
