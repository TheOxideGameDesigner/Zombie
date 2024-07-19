extends MeshInstance3D

@export var hide_mesh = true
@export var layer = 1
@export var climbable = false

func _ready():
	for i in get_children():
		i.queue_free()
	if hide_mesh:
		visible = 0
	create_trimesh_collision()
	if not climbable:
		get_children()[0].add_to_group("unclimbable")
	var body : StaticBody3D = get_children()[0]
	body.collision_layer = layer
