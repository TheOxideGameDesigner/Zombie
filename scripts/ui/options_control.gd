extends VSplitContainer


const CONFIG_PATH = "user://settings.cfg"
var config = ConfigFile.new()


func _ready():
	if FileAccess.file_exists(CONFIG_PATH):
		config.load(CONFIG_PATH)
	$options/controls/controls_panel/sensitivity.value = config.get_value("controls", "sensitivity", 5)
	$options/video/shadows.button_pressed = config.get_value("video", "shadows", 1)
	_on_shadows_toggled($options/video/shadows.button_pressed)
	
	$options/video/disable_shake.button_pressed = config.get_value("video", "disable_shake", 0)
	_on_disable_shake_toggled($options/video/disable_shake.button_pressed)
	
	$options/video/disable_particles.button_pressed = config.get_value("video", "disable_particles", 0)
	_on_disable_particles_toggled($options/video/disable_particles.button_pressed)
	
	$options/video/disable_gibs.button_pressed = config.get_value("video", "disable_gibs", 0)
	_on_disable_gibs_toggled($options/video/disable_gibs.button_pressed)
	
	$options/video/fov.value = config.get_value("video", "fov", 90)
	_on_fov_value_changed($options/video/fov.value)
	
	$options/video/dynamic_fov.button_pressed = config.get_value("video", "dynamic_fov", true)
	_on_dynamic_fov_toggled($options/video/dynamic_fov.button_pressed)
	
	$options/gameplay/difficulty.value = config.get_value("gameplay", "difficulty", 2)
	_on_difficulty_value_changed($options/gameplay/difficulty.value)
	
	$options/gameplay/god_mode.button_pressed = config.get_value("gameplay", "god_mode", false)
	_on_god_mode_toggled($options/gameplay/god_mode.button_pressed)
	
	config.save(CONFIG_PATH)


func _on_close_options_button_pressed():
	config.save(CONFIG_PATH)

func _on_sensitivity_value_changed(value):
	config.set_value("controls", "sensitivity", value)
	$options/controls/controls_panel/sensitivity/sensitivity_label.text = "sensitivity " + str(value)


func _on_fov_value_changed(value):
	config.set_value("video", "fov", int(value))
	$options/video/fov/fov_label.text = str(int(value))


func _on_dynamic_fov_toggled(button_pressed):
	config.set_value("video", "dynamic_fov", button_pressed)


func _on_shadows_toggled(button_pressed):
	config.set_value("video", "shadows", button_pressed)


func _on_difficulty_value_changed(value):
	config.set_value("gameplay", "difficulty", roundi(value))
	const DIFF_NAMES = ["relaxing", "easy", "normal", "hard", "unfair"]
	$options/gameplay/difficulty/difficulty_label.text = DIFF_NAMES[roundi(value)]


func _on_disable_shake_toggled(button_pressed):
	config.set_value("video", "disable_shake", button_pressed)


func _on_disable_particles_toggled(button_pressed):
	config.set_value("video", "disable_particles", button_pressed)


func _on_disable_gibs_toggled(button_pressed):
	config.set_value("video", "disable_gibs", button_pressed)


func _on_god_mode_toggled(button_pressed):
	config.set_value("gameplay", "god_mode", button_pressed)
