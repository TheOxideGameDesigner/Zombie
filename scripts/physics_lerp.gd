extends Node3D


@onready var current_pos : Vector3
@onready var prev_pos : Vector3
@onready var current_rot : Vector3
@onready var prev_rot : Vector3

@onready var p = get_parent()

func _ready() -> void:
		current_pos = p.global_position
		current_rot = p.global_rotation
		prev_pos = p.global_position
		prev_rot = p.global_rotation

func _physics_process(_delta : float) -> void:
	var pos : Vector3
	var rot : Vector3
	pos = p.global_position
	rot = p.global_rotation
	
	prev_pos = current_pos
	current_pos = pos
	prev_rot = current_rot
	current_rot = rot


func _process(_delta : float) -> void:
	var frac : float = Engine.get_physics_interpolation_fraction()
	global_position = lerp(prev_pos, current_pos, frac)
	global_rotation.y = lerp_angle(prev_rot.y, current_rot.y, frac)
	global_rotation.x = lerp_angle(prev_rot.x, current_rot.x, frac)
	global_rotation.z = lerp_angle(prev_rot.z, current_rot.z, frac)
