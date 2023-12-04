extends Node3D


var player_inside : bool = false

@export var powerup_type : int
@onready var good_dir = transform.basis.z
@onready var player = get_tree().get_first_node_in_group("player")


func _process(delta):
	if not player_inside:
		return
	


func _on_area_body_entered(body):
	if body.is_in_group("player"):
		player_inside = true


func _on_area_body_exited(body):
	if not body.is_in_group("player"):
		return
	player_inside = false
	
	var good : bool = good_dir.dot(player.position - position) < 0
	match powerup_type:
		0:
			player.damage_mul = 1.0 + 1.0 * int(good)
