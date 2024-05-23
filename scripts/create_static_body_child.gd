extends MeshInstance3D

@export var hide_mesh = true
@export var layer = 1

func _ready():
	for i in get_children():
		i.queue_free()
	if hide_mesh:
		visible = 0
	create_trimesh_collision()
	var body : StaticBody3D = get_children()[0]
	body.collision_layer = layer
