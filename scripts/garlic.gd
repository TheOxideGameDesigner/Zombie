extends Area3D


@onready var init_height = $mesh.position.y
@onready var init_light_height = $mesh/light.position.y
@onready var player_cam = get_tree().get_nodes_in_group("player")[0].get_node("cam")

@onready var mesh = $mesh
@onready var light = $mesh/light

const BOB_AMPLITUDE : float = 0.2
const BOB_FREQUENCY : float = 4
const LIGHT_ROTATION_SPEED : float = 0.4
var time : float = 0
var taken : bool = 0

func _process(delta : float) -> void:
	if taken:
		return
	time += delta
	mesh.position.y = init_height + BOB_AMPLITUDE * sin(time * BOB_FREQUENCY)
	var dir : Vector3 = player_cam.global_position - light.global_position
	light.global_rotation.y = -atan2(dir.z, dir.x) + PI / 2
	light.global_rotation.x = -atan2(dir.y, Vector2(dir.z, dir.x).length())
	light.global_rotation.z -= LIGHT_ROTATION_SPEED * delta


func _physics_process(_delta : float) -> void:
	var inside : bool = 0
	for b in get_overlapping_bodies():
		if b.is_in_group("player"):
			inside = 1
			break
	for c in get_children():
		if not c.is_in_group("trigger"):
			continue
		c.inside = inside


func _on_body_entered(body : PhysicsBody3D) -> void:
	if taken or not body.is_in_group("player"):
		return
	body.get_garlic()
	mesh.visible = 0
	taken = 1
