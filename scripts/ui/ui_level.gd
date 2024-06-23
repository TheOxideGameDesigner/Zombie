extends Control


var enabled = 0

var scene_path = null


func _ready():
	if scene_path == null:
		$play_button.disabled = 1


func _on_play_button_pressed():
	get_tree().change_scene_to_file(scene_path)
