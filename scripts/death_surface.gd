extends Area3D


func _ready() -> void:
	set_collision_mask_value(9, 1)
	set_collision_mask_value(2, 1)
	body_entered.connect(_on_body_entered)

func _on_body_entered(body : PhysicsBody3D) -> void:
	if body.is_in_group("player"):
		body.pain("You stepped on a hot sand", 9001)
	elif body.is_in_group("lightweight"):
		body.pain(9001)
