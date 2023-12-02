extends Area3D


func _ready():
	set_collision_mask_value(9, 1)
	connect("body_entered", _on_body_entered)
	connect("body_exited", _on_body_exited)
	for c in get_children():
		if c.is_in_group("activatable"):
			c.call_deferred("make_inactive")

func _on_body_entered(b):
	if not b.is_in_group("player"):
		return
	for c in get_children():
		if c.is_in_group("activatable"):
			c.in_active_zone = 1

func _on_body_exited(b):
	if not b.is_in_group("player"):
		return
	for c in get_children():
		if c.is_in_group("activatable"):
			c.make_inactive()
