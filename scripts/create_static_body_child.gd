extends MeshInstance3D

@export var hide_mesh = true

func _ready():
	for i in get_children():
		i.queue_free()
	if hide_mesh:
		visible = 0
	create_trimesh_collision()
