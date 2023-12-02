extends MeshInstance3D


func _ready():
	visible = 0
	var collision_shape = CollisionShape3D.new()
	collision_shape.shape = mesh.create_trimesh_shape()
	get_parent().add_child.call_deferred(collision_shape)
