extends Node3D


var map

var wait_time
var i = 0
var timer = 0.0

func _ready():
	var config_file = ConfigFile.new()
	config_file.load("user://settings.cfg")
	if not config_file.get_value("video", "shadows", 0):
		for j in get_tree().get_nodes_in_group("light"):
			j.shadow_enabled = 0
	if config_file.get_value("video", "disable_particles"):
		for j in get_tree().get_nodes_in_group("particles"):
			j.queue_free()
	if ProjectSettings.get_setting("rendering/renderer/rendering_method") == "gl_compatibility":
		for i in get_children():
			if i is MeshInstance3D:
				i.material_override = preload("res://resources/materials/opengl/level_mat_opengl.tres")
