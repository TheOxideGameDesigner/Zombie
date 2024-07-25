extends Node3D

var player_inside : bool = false
@onready var player = get_tree().get_first_node_in_group("player")
@onready var boost_dir : Vector3 = -transform.basis.z
@export var boost : float = 10.0

func _ready() -> void:
	if ProjectSettings.get_setting("rendering/renderer/rendering_method") == "gl_compatibility":
		$visual.material_override = preload("res://resources/materials/opengl/booster_mat_opengl.tres")
	$editor_guide.queue_free()
	$visual.set_instance_shader_parameter("texture_scale", Vector2(scale.x, scale.z))
	$area/CollisionShape3D.shape = BoxShape3D.new()
	$area/CollisionShape3D.shape.size = Vector3(scale.x * 2, 2, scale.z * 2)
	$visual.scale = scale
	scale = Vector3.ONE
	boost_dir.y = 0
	boost_dir = boost_dir.normalized()


func _physics_process(delta : float) -> void:
	if player_inside and player.is_on_floor():
		var vn : Vector3 = player.velocity.project(boost_dir)
		if vn.is_zero_approx():
			player.velocity = boost_dir * (boost + player.SPEED * player.speed_mul)
			return
		var opposed : bool = vn.dot(boost_dir) < 0
		if not opposed and vn.length() > (boost + player.SPEED * player.speed_mul):
			return
		player.velocity -= vn
		if opposed:
			vn = -vn
		player.velocity += vn.normalized() * (boost + player.SPEED * player.speed_mul)


func _on_area_body_entered(body : PhysicsBody3D) -> void:
	if body.is_in_group("player"):
		player_inside = true


func _on_area_body_exited(body : PhysicsBody3D) -> void:
	if body.is_in_group("player"):
		player_inside = false
