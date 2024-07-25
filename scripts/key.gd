extends Area3D


@export var key_color : Color = Color(0, 0.5, 1)
@export var key_name : String = "blue"
@export_range(0, 31) var key_index : int = 0

@onready var init_height : float = $visual.position.y
@onready var player_cam = get_tree().get_nodes_in_group("player")[0].get_node("cam")

@onready var visual = $visual
@onready var light = $visual/light

const BOB_AMPLITUDE : float = 0.2
const BOB_FREQUENCY : float = 4
const LIGHT_ROTATION_SPEED : float = 0.4
const KEY_ROTATION_SPEED : float = 2
var time : float = 0
var taken : bool = 0

func _ready() -> void:
	var is_opengl : bool = ProjectSettings.get_setting("rendering/renderer/rendering_method") == "gl_compatibility"
	$text_trigger.text = "You got the " + key_name + " key"
	$text_trigger.update_text()
	if is_opengl:
		var material = preload("res://resources/materials/opengl/key_mat_opengl.tres").duplicate()
		material.albedo_color = key_color
		$visual/mesh.set_surface_override_material(0, material)
	else:
		var material = preload("res://resources/materials/key_material.tres")
		$visual/mesh.set_instance_shader_parameter("color", key_color)
		$visual/mesh.set_surface_override_material(0, material)
	$visual/light.modulate = Color(key_color, 0.04)


func _process(delta : float) -> void:
	if taken:
		return
	time += delta
	visual.position.y = init_height + BOB_AMPLITUDE * sin(time * BOB_FREQUENCY)
	var dir : Vector3 = player_cam.global_position - light.global_position
	light.global_rotation.y = -atan2(dir.z, dir.x) + PI / 2
	light.global_rotation.x = -atan2(dir.y, Vector2(dir.z, dir.x).length())
	light.global_rotation.z -= LIGHT_ROTATION_SPEED * delta
	visual.global_rotation.y += KEY_ROTATION_SPEED * delta


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
	body.collected_keys[key_index] = true
	body.add_key(key_color)
	visual.visible = 0
	taken = 1
