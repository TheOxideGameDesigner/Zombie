extends Area3D


@onready var init_height = $mesh.position.y
@onready var init_light_height = $mesh/light.position.y
@onready var player_cam = get_tree().get_nodes_in_group("player")[0].get_node("cam")

@onready var mesh = $mesh
@onready var light = $mesh/light

const BOB_AMPLITUDE = 0.2
const BOB_FREQUENCY = 4
const LIGHT_ROTATION_SPEED = 0.4
var time = 0
var taken = 0

func _process(delta):
	if taken:
		return
	time += delta
	mesh.position.y = init_height + BOB_AMPLITUDE * sin(time * BOB_FREQUENCY)
	var dir = player_cam.global_position - $mesh/light.global_position
	light.global_rotation.y = -atan2(dir.z, dir.x) + PI / 2
	light.global_rotation.x = -atan2(dir.y, Vector2(dir.z, dir.x).length())
	light.global_rotation.z -= LIGHT_ROTATION_SPEED * delta


func _physics_process(_delta):
	var inside = 0
	for b in get_overlapping_bodies():
		if b.is_in_group("player"):
			inside = 1
			break
	for c in get_children():
		if not c.is_in_group("trigger"):
			continue
		c.inside = inside


func _on_body_entered(body):
	if taken or not body.is_in_group("player"):
		return
	body.get_garlic()
	mesh.visible = 0
	taken = 1
