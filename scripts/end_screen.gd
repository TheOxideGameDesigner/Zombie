extends Control

var damage_taken
var time
var next_scene
var current_scene


func ev_name(e):
	if e is InputEventMouseButton:
		return e.as_text()
	elif e is InputEventKey:
		return e.as_text_keycode()
	else:
		return "unknown"


func _ready():
	$instructions.text = "press " + ev_name(InputMap.action_get_events("g_respawn")[0]) + " to go to the next location\n\n" + \
						 "press " + ev_name(InputMap.action_get_events("g_pause")[0]) + " to restart"
	$damage_taken.text = "damage taken   " + str(damage_taken)
	var timei = floori(time)
	var secs = timei % 60
	var secsstr
	if secs < 10:
		secsstr = "0" + str(secs)
	else:
		secsstr = str(secs)
	$time.text = "time           " + str(timei / 60) + "[" + secsstr


func _unhandled_input(event):
	if event.is_action("g_respawn"):
		get_tree().change_scene_to_file(next_scene)
	elif event.is_action("g_pause"):
		get_tree().change_scene_to_file(current_scene)
