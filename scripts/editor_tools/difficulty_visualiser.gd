@tool
extends MeshInstance3D

var target_diff = 4
@export var radius = 0.5
@export var height = 2.0

const COLORS = [Color(1, 1, 1, 0.1), Color(0, 0.7, 0, 0.2), Color(1.0, 1.0, 0, 0.1), Color(1.0, 0.3, 0.0, 0.2), Color(0.3, 0.0, 0.3, 0.2)]

var prev_pressed_plus = false
var prev_pressed_minus = false

func _ready():
	visible = true
	position.y = height / 2
	if Engine.is_editor_hint():
		mesh = CylinderMesh.new()
		mesh.top_radius = radius
		mesh.bottom_radius = radius
		mesh.height = height
		mesh.radial_segments = 12
		material_override = StandardMaterial3D.new()
		material_override.shading_mode = StandardMaterial3D.SHADING_MODE_UNSHADED
		material_override.transparency = StandardMaterial3D.TRANSPARENCY_ALPHA
	else:
		queue_free()

func _process(_delta):
	if not get_parent().is_in_group("enemy"):
		return
	material_override.albedo_color = COLORS[get_parent().min_dif]
	if not Input.is_key_pressed(KEY_SHIFT):
		return
	var pressed_minus = Input.is_key_pressed(KEY_O)
	var pressed_plus = Input.is_key_pressed(KEY_P)
	if pressed_minus and not prev_pressed_minus:
		target_diff = max(0, target_diff - 1)
		get_parent().visible = get_parent().min_dif <= target_diff
	if pressed_plus and not prev_pressed_plus:
		target_diff = min(4, target_diff + 1)
		get_parent().visible = get_parent().min_dif <= target_diff
	prev_pressed_minus = pressed_minus
	prev_pressed_plus = pressed_plus
