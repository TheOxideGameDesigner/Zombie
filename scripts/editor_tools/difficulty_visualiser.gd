@tool
extends Node

var target_diff = 2
@export var radius = 0.5
@export var height = 2.0

var mesh
const COLORS = [Color(1, 1, 1, 0.2), Color(0, 0.7, 0, 0.3), Color(1.0, 1.0, 0, 0.5), Color(1.0, 0.3, 0.0, 0.3), Color(0.3, 0.0, 0.3, 0.4)]

var prev_pressed_plus = false
var prev_pressed_minus = false

func _ready():
	if Engine.is_editor_hint():
		mesh = MeshInstance3D.new()
		mesh.add_to_group("diff_vis")
		mesh.mesh = CylinderMesh.new()
		mesh.mesh.top_radius = radius
		mesh.mesh.bottom_radius = radius
		mesh.mesh.height = height
		mesh.mesh.radial_segments = 12
		mesh.material_override = StandardMaterial3D.new()
		mesh.material_override.shading_mode = StandardMaterial3D.SHADING_MODE_UNSHADED
		mesh.material_override.transparency = StandardMaterial3D.TRANSPARENCY_ALPHA
		get_parent().get_node("mesh").add_child(mesh)
	else:
		queue_free()

func _process(delta):
	mesh.material_override.albedo_color = COLORS[get_parent().min_dif]
	if not Input.is_key_pressed(KEY_SHIFT):
		return
	var pressed_minus = Input.is_key_pressed(KEY_O)
	var pressed_plus = Input.is_key_pressed(KEY_P)
	if pressed_minus and not prev_pressed_minus:
		target_diff = max(0, target_diff - 1)
		mesh.get_parent().get_parent().visible = get_parent().min_dif <= target_diff
	if pressed_plus and not prev_pressed_plus:
		target_diff = min(4, target_diff + 1)
		mesh.get_parent().get_parent().visible = get_parent().min_dif <= target_diff
	prev_pressed_minus = pressed_minus
	prev_pressed_plus = pressed_plus
