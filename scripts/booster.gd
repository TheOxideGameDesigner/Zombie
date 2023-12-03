extends Node3D

var player_inside : bool = false
@onready var player = get_tree().get_first_node_in_group("player")
@onready var boost_dir = -transform.basis.z
@export var boost = 20.0

func _ready():
	$visual.set_instance_shader_parameter("texture_scale", Vector2(scale.x, scale.z))
	$area/CollisionShape3D.shape = BoxShape3D.new()
	$area/CollisionShape3D.shape.size = Vector3(scale.x * 2, 2, scale.z * 2)
	$collision/CollisionShape3D.shape = BoxShape3D.new()
	$collision/CollisionShape3D.shape.size = Vector3(scale.x * 2, 0.2, scale.z * 2)
	$visual.scale = scale
	scale = Vector3.ONE
	boost_dir.y = 0
	boost_dir = boost_dir.normalized() * boost


func _physics_process(delta):
	if player_inside:
		var vn = player.velocity.project(boost_dir)
		var opposed : bool = vn.dot(boost_dir) < 0
		if not opposed and vn.length() > boost:
			return
		player.velocity -= vn
		if opposed:
			vn = -vn
		player.velocity += vn.normalized() * boost


func _on_area_body_entered(body):
	if body.is_in_group("player"):
		player_inside = true


func _on_area_body_exited(body):
	if body.is_in_group("player"):
		player_inside = false
