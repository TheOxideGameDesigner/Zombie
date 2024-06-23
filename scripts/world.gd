@tool
extends Node3D


var map

var wait_time
var i = 0
var timer = 0.0


func _ready():
	var config_file = ConfigFile.new()
	config_file.load("user://settings.cfg")
	var shadows_on = config_file.get_value("video", "shadows", 1) and ProjectSettings.get_setting("rendering/renderer/rendering_method") != "gl_compatibility"
	for j in get_tree().get_nodes_in_group("light"):
		j.shadow_enabled = shadows_on
	if Engine.is_editor_hint():
		return
	if config_file.get_value("video", "disable_particles"):
		for j in get_tree().get_nodes_in_group("particles"):
			j.queue_free()
	var id : int = 1
	for p in get_tree().get_nodes_in_group("painting_s1"):
		p.set_image(id)
		id = (id + 1) % 4 + 1
	id = 5
	for p in get_tree().get_nodes_in_group("painting_s2"):
		p.set_image(id)
		id = (id + 1) % 5 + 5

