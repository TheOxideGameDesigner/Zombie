extends Area3D


func _ready():
	set_collision_mask_value(9, 1)
	connect("body_entered", _on_body_entered)
	connect("body_exited", _on_body_exited)

func _on_body_entered(b):
	if not b.is_in_group("player"):
		return
	for c in get_children():
		if not c.is_in_group("trigger"):
			continue
		c.inside = 1
	
func _on_body_exited(b):
	if not b.is_in_group("player"):
		return
	for c in get_children():
		if not c.is_in_group("trigger"):
			continue
		c.inside = 0
