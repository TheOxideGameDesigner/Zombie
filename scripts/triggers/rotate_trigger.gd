extends Node3D


var inside = 0
@export var target : float = 0

@onready var player = get_tree().get_first_node_in_group("player")


var in_group = []

func _process(_delta):
	if inside:
		player.cam.global_rotation.y = deg_to_rad(target)
