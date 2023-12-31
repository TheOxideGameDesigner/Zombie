extends Node3D


@onready var current_pos
@onready var prev_pos
@onready var current_rot
@onready var prev_rot

@export var enable_rot : bool = 0
@export var global : bool = 0
@export var of_parent : bool = 0

@onready var p = get_parent()

func _ready():
	if of_parent:
		if global:
			current_pos = p.global_position
			current_rot = p.global_rotation
			prev_pos = p.global_position
			prev_rot = p.global_rotation
		else:
			current_pos = p.position
			current_rot = p.rotation
			prev_pos = p.position
			prev_rot = p.rotation
	else:
		if global:
			current_pos = global_position
			current_rot = global_rotation
			prev_pos = global_position
			prev_rot = global_rotation
		else:
			current_pos = position
			current_rot = rotation
			prev_pos = position
			prev_rot = rotation

func _physics_process(_delta):
	var pos
	var rot
	if global:
		if of_parent:
			pos = p.global_position
			rot = p.global_rotation
		else:
			pos = global_position
			rot = global_rotation
	else:
		if of_parent:
			pos = p.global_position
			rot = p.global_rotation
		else:
			pos = position
			rot = rotation
	prev_pos = current_pos
	current_pos = pos
	prev_rot = current_rot
	current_rot = rot


func _process(_delta):
	var frac = Engine.get_physics_interpolation_fraction()
	if global:
		global_position = lerp(prev_pos, current_pos, frac)
		if enable_rot:
			global_rotation.y = lerp_angle(prev_rot.y, current_rot.y, frac)
			global_rotation.x = lerp_angle(prev_rot.x, current_rot.x, frac)
			global_rotation.z = lerp_angle(prev_rot.z, current_rot.z, frac)
	else:
		position = lerp(prev_pos, current_pos, frac)
		if enable_rot:
			rotation.y = lerp_angle(prev_rot.y, current_rot.y, frac)
			rotation.x = lerp_angle(prev_rot.x, current_rot.x, frac)
			rotation.z = lerp_angle(prev_rot.z, current_rot.z, frac)
