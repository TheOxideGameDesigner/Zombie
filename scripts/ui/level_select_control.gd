extends VSplitContainer


const CONFIG_PATH = "user://unlocked.cfg"
var config = ConfigFile.new()
var levels = JSON.parse_string(FileAccess.get_file_as_string("res://data/levels.json"))
@onready var panel = $level_select_container/level_select
var ui_level_scene = preload("res://scenes/ui/ui_level.tscn")


func _ready():
	if FileAccess.file_exists(CONFIG_PATH):
		config.load(CONFIG_PATH)
	else:
		for i in levels:
			for j in range(i[1].size()):
				config.set_value(i[0], str(j), false)
		
		config.save(CONFIG_PATH)
	
	#exceptions
	config.set_value("mountainside", "0", true)
	
	var pos = Vector2(90, 50)
	for i in levels:
		pos.x = 90
		var label = Label.new()
		label.position = pos
		pos.y += 200
		pos.x = 120
		var discovered = false
		for j in range(i[1].size()):
			var ui_level = ui_level_scene.instantiate()
			ui_level.position = pos
			if config.get_value(i[0], str(j), false):
				discovered = true
				ui_level.scene_path = "res://scenes/levels/" + i[2][j]
				ui_level.get_node("icon").texture = load("res://textures/icons/" + i[1][j])
			panel.add_child(ui_level)
			if j % 6 == 0 and j != 0:
				pos.x = 120
				pos.y += 300
			else:
				pos.x += 260
		if discovered:
			label.text = i[0]
		else:
			label.text = "???"
		panel.add_child(label)
		pos.y += 200
	
	panel.custom_minimum_size.y = pos.y + 200
