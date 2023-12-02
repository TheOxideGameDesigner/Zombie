extends Button


@export var default_value : int
var input_event


const CONFIG_PATH = "user://settings_buttons.cfg"
var config_file = ConfigFile.new()

var listening : bool = false


func update(value):
	if value > 0:
		input_event = InputEventKey.new()
		input_event.keycode = value
		text = input_event.as_text_keycode()
	else:
		input_event = InputEventMouseButton.new()
		input_event.button_index = -value
		text = input_event.as_text()
	InputMap.action_erase_events(name)
	InputMap.action_add_event(name, input_event)
	config_file.set_value("controls", name, value)
	config_file.save(CONFIG_PATH)


func _ready():
	add_to_group("input_button")
	if not InputMap.has_action(name):
		InputMap.add_action(name)
	if FileAccess.file_exists(CONFIG_PATH):
		config_file.load(CONFIG_PATH)
	update(config_file.get_value("controls", name, default_value))


func _on_pressed():
	for i in get_tree().get_nodes_in_group("input_button"):
		if i.listening:
			return
	listening = true
	text = "..."


func _unhandled_input(event):
	if not ((event is InputEventKey) or (event is InputEventMouseButton)):
		return
	if not listening:
		return
	listening = false
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	if event is InputEventKey:
		update(event.keycode)
	else:
		update(-event.button_index)
