@tool
extends MeshInstance3D


func _ready():
	for i in get_children():
		i.queue_free()
	visible = 0
	create_trimesh_collision()
