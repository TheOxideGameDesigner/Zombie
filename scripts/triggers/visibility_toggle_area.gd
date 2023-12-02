extends Area3D


func _ready():
	set_collision_mask_value(9, 1)
	connect("body_entered", _on_body_entered)
	connect("body_exited", _on_body_exited)
	visible = 0

func _on_body_entered(b):
	if not b.is_in_group("player"):
		return
	visible = 1

func _on_body_exited(b):
	if not b.is_in_group("player"):
		return
	visible = 0
