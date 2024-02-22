extends Area3D


func _ready():
	set_collision_mask_value(9, 1)
	set_collision_mask_value(2, 1)
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	if body.is_in_group("player") or body.is_in_group("lightweight"):
		body.pain("You stepped on a dangerous surface", 9001)
